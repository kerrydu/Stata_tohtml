function test_all()
%TEST_ALL  Exercise matlab_tohtml under Octave or MATLAB.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
tmp = tempname;
mkdir(tmp);
cleaner = onCleanup(@() rmdir_quiet(tmp)); %#ok<NASGU>

test_stats(tmp);
test_runner(tmp);
test_gather(tmp);
test_example(root);

disp('matlab_tohtml tests passed');
end

function test_stats(tmp)
path = fullfile(tmp, 'summary.html');
price = [1; NaN; 3; 5];
summary = matlab_tohtml.summarize(path, {'价格', price, '油耗', [10; 20; 30; 40]});
check(summary.('价格').n == 3, 'summarize drops NaN');
check(abs(summary.('价格').mean - 3) < 1e-12, 'summarize mean');
html = fileread(path);
check_in(html, '变量', 'summary header');
check_in(html, '价格', 'summary row');
check_in(html, 'class="num"', 'numeric cells');

y = [1; 2; 2; 3; 5];
x = [0; 1; 2; 3; 4];
model = matlab_tohtml.regress(y, {'x', x});
check(abs(model.params.x - 0.9) < 1e-8, 'slope');
check(abs(model.params.('常数项') - 0.8) < 1e-8, 'intercept');
check(abs(model.bse.x - 0.1914854215512676) < 1e-8, 'slope se');
check(abs(model.pvalues.x - 0.018219854743222408) < 1e-8, 'slope p');
check(abs(model.rsquared - 0.8804347826086957) < 1e-8, 'r2');
check(model.nobs == 5, 'nobs');

perfect = matlab_tohtml.regress([1; 2; 3], {'x', [0; 1; 2]});
check(abs(perfect.params.x - 1) < 1e-10, 'perfect slope');
check(abs(perfect.rsquared - 1) < 1e-10, 'perfect r2');

table_path = fullfile(tmp, 'reg.html');
matlab_tohtml.etable(table_path, {model, perfect}, 'titles', {'(1)', '(2)'}, 'note', '因变量为 y。');
table_html = fileread(table_path);
check_in(table_html, '(1)', 'etable title');
check_in(table_html, '常数项', 'etable intercept');
check_in(table_html, 'pytohtml-note', 'etable note');
check_in(table_html, '0.900', 'formatted coef');

fig = fullfile(tmp, 'scatter.svg');
matlab_tohtml.scatter(fig, y, x, 'xlabel', 'x', 'ylabel', 'y', 'fit', true);
svg = fileread(fig);
check_in(svg, '<svg', 'svg root');
check_in(svg, '<circle', 'points');
check_in(svg, 'stroke="#0969da"', 'fit line');
end

function test_runner(tmp)
script = fullfile(tmp, 'analysis.m');
write_script(script, [ ...
    '% 这是说明' newline ...
    'n = 24;' newline ...
    'x = 1; % ishere # 不是标题' newline ...
    '% ishere # 标题' newline ...
    '% ishere ## 小节' newline ...
    'sprintf(''样本量为 %d。'', n)' newline ...
    '% ishere display sprintf(''%.0f'', n)' newline ...
    '%{' newline ...
    '显示为 {ishere display sprintf(''%.0f'', n)}。' newline ...
    '%}' newline ...
    '% /**' newline ...
    '% 第二段' newline ...
    '% **/' newline ...
    'a = [10 20 30];' newline ...
    'b = a(end);' newline ...
    'total = 0;' newline ...
    'for k = 1:3' newline ...
    '    total(end + 1) = k;' newline ...
    'end' newline ...
    'label = ''it''''s'';' newline ...
    'value = 1 + ...' newline ...
    '    2;' newline ...
    'sprintf(''%s %d %d %d'', label, b, numel(total), value)' newline ...
    'disp(n)' newline ...
    '% ishere fig using "figures/a.svg", title("价格, 油耗") zoom(80%)' newline ...
    '% ishere tab using "missing.html", title("回归")' newline ...
    'sprintf(''手写 24。'')' newline]);
mkdir(fullfile(tmp, 'figures'));
write_script(fullfile(tmp, 'figures', 'a.svg'), '<svg xmlns="http://www.w3.org/2000/svg"></svg>');

html_path = fullfile(tmp, 'report.html');
status = matlab_tohtml.run(script, 'html', html_path);
check(status == 0, 'run status');
html = fileread(html_path);
check_in(html, '<h1>标题</h1>', 'h1');
check_in(html, '<h2>小节</h2>', 'h2');
check_in(html, '<p>样本量为 24。</p>', 'sprintf narrative');
check_in(html, '显示为 24。', 'display tag');
check_in(html, '第二段', 'stata comment');
check_in(html, 'it''s 30 4 3', 'transpose, loop, continuation');
check_in(html, '% 这是说明', 'leading comment stays in code');
check_in(html, 'language-matlab', 'matlab fence');
check(~contains_text(html, '<h1>不是标题</h1>'), 'inline comment is not a marker');
check_in(html, '% ishere # 不是标题', 'trailing comment stays on the code line');
check(~contains_text(html, '% ishere # 标题'), 'real markers stay out of the report');
check_in(html, 'tohtml-fig-title', 'figure caption');
check_in(html, 'zoom:80%', 'zoom');
check_in(html, '找不到表', 'missing table');
check_in(html, '手写数字', 'hardcoded warning');
check_in(html, '<pre class="pytohtml-output">', 'displayed output');

tag_script = fullfile(tmp, 'tag.m');
write_script(tag_script, ['n = 24;' newline ...
    '% ishere display n' newline ...
    '''值 {ishere display n}。''' newline]);
matlab_tohtml.run(tag_script, 'html', fullfile(tmp, 'tag.html'));
tag_html = fileread(fullfile(tmp, 'tag.html'));
check_in(tag_html, '值 24。', 'display tag inside a string');
check(~contains_text(tag_html, '{ishere display'), 'string tag is filled');

clean_path = fullfile(tmp, 'clean.html');
matlab_tohtml.run(script, 'html', clean_path, 'clean', true);
clean = fileread(clean_path);
check_in(clean, '样本量为 24。', 'clean keeps prose');
check(~contains_text(clean, 'language-matlab'), 'clean drops code');
check(~contains_text(clean, '<pre class="pytohtml-output">'), 'clean drops output');
check(~contains_text(clean, '手写数字'), 'clean drops the warning');

code_path = fullfile(tmp, 'code.html');
matlab_tohtml.run(script, 'html', code_path, 'cleancode', true);
coded = fileread(code_path);
check_in(coded, 'language-matlab', 'cleancode keeps code');
check_in(coded, 'disp(n)', 'cleancode shows disp');
check(~contains_text(coded, '<pre class="pytohtml-output">'), 'cleancode drops output');
check_in(coded, 'highlight.min.js', 'cleancode loads highlight');

log_path = fullfile(tmp, 'report.log');
matlab_tohtml.build(log_path, 'html', fullfile(tmp, 'built.html'), 'embed', true);
built = fileread(fullfile(tmp, 'built.html'));
check_in(built, 'data:image/svg+xml;base64,', 'embed');

broken = fullfile(tmp, 'broken.m');
write_script(broken, ['sprintf(''之前'')' newline 'not_a_real_function_zz()' newline 'sprintf(''之后'')' newline]);
status = matlab_tohtml.run(broken, 'html', fullfile(tmp, 'broken.html'));
check(status ~= 0, 'failed script status');
broken_html = fileread(fullfile(tmp, 'broken.html'));
check_in(broken_html, '之前', 'partial report');
check(~contains_text(broken_html, '之后'), 'stops at the error');
end

function test_gather(tmp)
tables = fullfile(tmp, 'results');
figures = fullfile(tmp, 'figures2');
nested = fullfile(figures, 'nested');
mkdir(tables);
mkdir(nested);
write_script(fullfile(tables, 'table_summary.html'), '<table class="pytohtml-table"><tr><td>价格</td></tr></table>');
write_script(fullfile(tables, 'table_extra.md'), '| a | b |');
write_script(fullfile(tables, 'notes.txt'), '忽略');
write_script(fullfile(tables, 'Table_upper.html'), '<table></table>');
write_script(fullfile(figures, 'figure_b.svg'), '<svg xmlns="http://www.w3.org/2000/svg"></svg>');
write_script(fullfile(figures, 'figure_a.png'), 'png');
write_script(fullfile(nested, 'figure_hidden.svg'), '<svg></svg>');
report = fullfile(tmp, 'gathered.html');
matlab_tohtml.gather({tables, figures, tables}, 'html', report, 'zoom', '80%');
html = fileread(report);
check_in(html, '<h1>图和表</h1>', 'gather title');
check(strfind(html, 'figure_a.png') < strfind(html, 'figure_b.svg'), 'figure sort');
check(strfind(html, 'figure_b.svg') < strfind(html, 'table_extra.md'), 'figure before table');
check(strfind(html, 'table_extra.md') < strfind(html, 'table_summary.html'), 'table sort');
check(~contains_text(html, 'figure_hidden'), 'no recursion');
check(~contains_text(html, 'Table_upper'), 'case sensitive names');
check(~contains_text(html, 'notes.txt'), 'ignore other files');
check_in(html, 'zoom:80%', 'gather zoom');
check_in(html, '<td>价格</td>', 'inlined table');
md = fileread(fullfile(tmp, 'gathered.md'));
check_in(md, '# 图和表', 'gather markdown');
check_in(md, '### figure_a.png', 'gather markdown figure');
empty = fullfile(tmp, 'empty');
mkdir(empty);
failed = false;
try
    matlab_tohtml.gather(empty, 'html', fullfile(tmp, 'nope.html'));
catch
    failed = true;
end
check(failed, 'empty folder errors');
end

function test_example(root)
script = fullfile(root, 'examples', 'auto_price.m');
status = matlab_tohtml.run(script, 'html', fullfile(root, 'examples', 'auto_price.html'));
check(status == 0, 'example runs');
html = fileread(fullfile(root, 'examples', 'auto_price.html'));
check_in(html, '价格与油耗', 'example title');
check_in(html, '描述统计', 'example table');
check_in(html, '价格与每加仑英里数', 'example figure');
check_in(html, 'pytohtml-math', 'example equation');
check_in(html, 'MathJax', 'example mathjax');
check(~contains_text(html, '{ishere display'), 'example display filled');
end

function write_script(path, text)
fid = fopen(path, 'wb');
if exist('OCTAVE_VERSION', 'builtin')
    fwrite(fid, uint8(text));
else
    fwrite(fid, unicode2native(text, 'UTF-8'));
end
fclose(fid);
end

function check(cond, msg)
if ~cond
    error('matlab_tohtml:Test', '失败：%s', msg);
end
end

function check_in(text, needle, msg)
if isempty(strfind(text, needle))
    error('matlab_tohtml:Test', '失败：%s（找不到 %s）', msg, needle);
end
end

function tf = contains_text(text, needle)
tf = ~isempty(strfind(text, needle));
end

function rmdir_quiet(path)
if exist(path, 'dir')
    rmdir(path, 's');
end
end

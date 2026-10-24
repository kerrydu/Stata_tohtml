function status = run(script, varargin)
%RUN  运行脚本，写出记录、Markdown 和 HTML。
if exist('OCTAVE_VERSION', 'builtin'), addpath(fullfile(fileparts(mfilename('fullpath')), 'private')); end
%   matlab_tohtml.run("analysis.m")
%   matlab_tohtml.run("analysis.m", "html", "report.html", "clean", true)
%
% 名称-值：html、md、log、clean、cleancode、mode、embed、mathjax、tabwidth、tabheight。
opt = apply_mode(take_options(report_options(), varargin));
script = as_char(script);
if exist(script, 'file') ~= 2
    error('matlab_tohtml:Missing', '找不到脚本 %s', script);
end
script = absolutepath(script);
if isempty(opt.html)
    opt.html = with_ext(script, '.html');
else
    opt.html = absolutepath(opt.html);
end
if isempty(opt.log)
    opt.log = with_ext(opt.html, '.log');
else
    opt.log = absolutepath(opt.log);
end
if isempty(opt.md)
    opt.md = with_ext(opt.html, '.md');
else
    opt.md = absolutepath(opt.md);
end
status = execute_script(script, opt.log);
render_log(opt.log, opt.html, opt.md, opt);
print_number_warnings(opt.log);
fprintf('log: %s\n', opt.log);
fprintf('md: %s\n', opt.md);
fprintf('html: %s\n', opt.html);
if status ~= 0
    fprintf(2, '脚本运行失败，已写出停在错误处的报告。\n');
end
end

function build(log_path, varargin)
%BUILD  从已有记录生成 Markdown 和 HTML。
if exist('OCTAVE_VERSION', 'builtin'), addpath(fullfile(fileparts(mfilename('fullpath')), 'private')); end
%   matlab_tohtml.build("report.log", "html", "report.html", "cleancode", true)
opt = apply_mode(take_options(report_options(), varargin));
log_path = as_char(log_path);
if exist(log_path, 'file') ~= 2
    error('matlab_tohtml:Missing', '找不到记录 %s', log_path);
end
log_path = absolutepath(log_path);
if isempty(opt.html)
    opt.html = with_ext(log_path, '.html');
else
    opt.html = absolutepath(opt.html);
end
if isempty(opt.md)
    opt.md = with_ext(opt.html, '.md');
else
    opt.md = absolutepath(opt.md);
end
render_log(log_path, opt.html, opt.md, opt);
print_number_warnings(log_path);
fprintf('md: %s\n', opt.md);
fprintf('html: %s\n', opt.html);
end

function status = mltohtml(cmd, varargin)
%MLTOHTML  run、build 或 gather。
%   mltohtml("run", "analysis.m", "html", "report.html")
%   mltohtml("build", "report.log")
%   mltohtml("gather", {"results", "figures"}, "zoom", "80%")
root = fileparts(mfilename('fullpath'));
addpath(root);
if nargin < 1
    error('matlab_tohtml:Command', '用法：mltohtml run script ...');
end
switch as_char_local(cmd)
    case 'run'
        status = matlab_tohtml.run(varargin{:});
    case 'build'
        matlab_tohtml.build(varargin{:});
        status = 0;
    case 'gather'
        matlab_tohtml.gather(varargin{:});
        status = 0;
    otherwise
        error('matlab_tohtml:Command', '命令要是 run、build 或 gather');
end
end

function text = as_char_local(value)
if ischar(value)
    text = value;
else
    text = char(value);
end
end

function summary = summarize(path, columns, varargin)
%SUMMARIZE  写出描述统计表，并返回未四舍五入的 N、均值、标准差、最小值、最大值。
if exist('OCTAVE_VERSION', 'builtin'), addpath(fullfile(fileparts(mfilename('fullpath')), 'private')); end
%   s = matlab_tohtml.summarize("results/summary.html", {"价格", price, "油耗", mpg})
%   s.('价格').n
%   s.('价格').mean
opt = struct();
opt.digits = 3;
if nargin >= 3
    if numel(varargin) == 1 && isnumeric(varargin{1})
        opt.digits = varargin{1};
    else
        opt = take_options(opt, varargin);
    end
end
columns = normalize_columns(columns);
if isempty(columns)
    error('matlab_tohtml:Summarize', 'summarize 至少要有一个变量');
end
header = {'变量', 'N', '均值', '标准差', '最小值', '最大值'};
rows = {};
summary = struct();
for k = 1:numel(columns)
    clean = numeric_values(columns(k).values);
    stats = column_stats(clean);
    summary.(columns(k).name) = stats;
    if stats.n == 0
        rows{end + 1} = {columns(k).name, '0', '', '', '', ''}; %#ok<AGROW>
    else
        sd = '';
        if ~isnan(stats.sd)
            sd = format_number(stats.sd, opt.digits);
        end
        rows{end + 1} = { ...
            columns(k).name, ...
            sprintf('%.0f', stats.n), ...
            format_number(stats.mean, opt.digits), ...
            sd, ...
            format_number(stats.min, opt.digits), ...
            format_number(stats.max, opt.digits)}; %#ok<AGROW>
    end
end
write_table(path, header, rows, 2, {}, '');
end

function clean = numeric_values(values)
clean = [];
if ~(isnumeric(values) || islogical(values))
    return
end
values = double(values(:));
for k = 1:numel(values)
    if ~isnan(values(k))
        clean(end + 1, 1) = values(k); %#ok<AGROW>
    end
end
end

function stats = column_stats(clean)
stats = struct('n', 0, 'mean', NaN, 'sd', NaN, 'min', NaN, 'max', NaN);
stats.n = numel(clean);
if stats.n == 0
    return
end
stats.mean = sum(clean) / stats.n;
if stats.n > 1
    stats.sd = sqrt(sum((clean - stats.mean) .^ 2) / (stats.n - 1));
else
    stats.sd = NaN;
end
stats.min = min(clean);
stats.max = max(clean);
end

function text = format_number(value, digits)
text = sprintf('%.*f', digits, value);
end

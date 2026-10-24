function path = scatter(path, y, x, varargin)
%SCATTER  把散点写成 SVG。参数顺序是 y 再 x，和 Stata 一样。
if exist('OCTAVE_VERSION', 'builtin'), addpath(fullfile(fileparts(mfilename('fullpath')), 'private')); end
%   matlab_tohtml.scatter("figures/price.svg", price, mpg, ...
%       "xlabel", "油耗", "ylabel", "价格", "fit", true)
opt = struct();
opt.xlabel = '';
opt.ylabel = '';
opt.fit = false;
if nargin >= 4
    opt = take_options(opt, varargin);
end
[xs, ys] = paired_points(x, y);
if isempty(xs)
    error('matlab_tohtml:Scatter', '没有可绘制的观测');
end
width = 680;
height = 440;
xlabel = as_char(opt.xlabel);
ylabel = as_char(opt.ylabel);
if isempty(ylabel)
    left = 56;
else
    left = 78;
end
right = 24;
top = 20;
if isempty(xlabel)
    bottom = 40;
else
    bottom = 58;
end
plot_w = width - left - right;
plot_h = height - top - bottom;
[xmin, xmax] = pad_range(min(xs), max(xs));
[ymin, ymax] = pad_range(min(ys), max(ys));
parts = { ...
    sprintf('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d" role="img">', ...
        width, height, width, height), ...
    '<rect width="100%" height="100%" fill="#ffffff"/>', ...
    sprintf('<clipPath id="pytohtml-plot"><rect x="%d" y="%d" width="%d" height="%d"/></clipPath>', ...
        left, top, plot_w, plot_h), ...
    ['<g font-family="&quot;Source Han Sans SC&quot;, &quot;Noto Sans CJK SC&quot;, ' ...
        '&quot;PingFang SC&quot;, &quot;Microsoft YaHei&quot;, &quot;WenQuanYi Micro Hei&quot;, ' ...
        '&quot;Droid Sans Fallback&quot;, sans-serif" font-size="12" fill="#24292f">']};
yticks = tick_values(ymin, ymax, 5);
for k = 1:numel(yticks)
    y_pos = sy(yticks(k), top, plot_h, ymin, ymax);
    parts{end + 1} = sprintf('<line x1="%d" y1="%.2f" x2="%d" y2="%.2f" stroke="#eaecef" stroke-width="1"/>', ...
        left, y_pos, left + plot_w, y_pos); %#ok<AGROW>
    parts{end + 1} = sprintf('<text x="%d" y="%.2f" text-anchor="end" dominant-baseline="middle">%s</text>', ...
        left - 8, y_pos, html_escape(tick_label(yticks(k)))); %#ok<AGROW>
end
xticks = tick_values(xmin, xmax, 5);
for k = 1:numel(xticks)
    x_pos = sx(xticks(k), left, plot_w, xmin, xmax);
    parts{end + 1} = sprintf('<line x1="%.2f" y1="%d" x2="%.2f" y2="%d" stroke="#eaecef" stroke-width="1"/>', ...
        x_pos, top, x_pos, top + plot_h); %#ok<AGROW>
    parts{end + 1} = sprintf('<text x="%.2f" y="%d" text-anchor="middle">%s</text>', ...
        x_pos, top + plot_h + 18, html_escape(tick_label(xticks(k)))); %#ok<AGROW>
end
parts{end + 1} = sprintf('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#24292f" stroke-width="1"/>', ...
    left, top, left, top + plot_h); %#ok<AGROW>
parts{end + 1} = sprintf('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#24292f" stroke-width="1"/>', ...
    left, top + plot_h, left + plot_w, top + plot_h); %#ok<AGROW>
parts{end + 1} = '<g clip-path="url(#pytohtml-plot)">'; %#ok<AGROW>
if logical(opt.fit) && numel(xs) >= 2
    segment = fit_segment(xs, ys, xmin, xmax);
    if ~isempty(segment)
        parts{end + 1} = sprintf('<line x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f" stroke="#0969da" stroke-width="1.6"/>', ...
            sx(segment(1), left, plot_w, xmin, xmax), sy(segment(2), top, plot_h, ymin, ymax), ...
            sx(segment(3), left, plot_w, xmin, xmax), sy(segment(4), top, plot_h, ymin, ymax)); %#ok<AGROW>
    end
end
for k = 1:numel(xs)
    parts{end + 1} = sprintf('<circle cx="%.2f" cy="%.2f" r="3.6" fill="#1a7f37"/>', ...
        sx(xs(k), left, plot_w, xmin, xmax), sy(ys(k), top, plot_h, ymin, ymax)); %#ok<AGROW>
end
parts{end + 1} = '</g>'; %#ok<AGROW>
if ~isempty(xlabel)
    parts{end + 1} = sprintf('<text x="%.2f" y="%d" text-anchor="middle" font-size="13">%s</text>', ...
        left + plot_w / 2, height - 16, html_escape(xlabel)); %#ok<AGROW>
end
if ~isempty(ylabel)
    parts{end + 1} = sprintf('<text text-anchor="middle" font-size="13" transform="translate(18, %.2f) rotate(-90)">%s</text>', ...
        top + plot_h / 2, html_escape(ylabel)); %#ok<AGROW>
end
parts{end + 1} = '</g></svg>'; %#ok<AGROW>
write_text(path, strjoin(parts, ''));
path = char(path);
end

function [xs, ys] = paired_points(x, y)
if ~(isnumeric(x) || islogical(x)) || ~(isnumeric(y) || islogical(y))
    error('matlab_tohtml:Scatter', 'x 和 y 要是数值');
end
x = double(x(:));
y = double(y(:));
if numel(x) ~= numel(y)
    error('matlab_tohtml:Scatter', 'x 的长度是 %d，y 的长度是 %d', numel(x), numel(y));
end
xs = [];
ys = [];
for k = 1:numel(x)
    if isnan(x(k)) || isnan(y(k))
        continue
    end
    xs(end + 1, 1) = x(k); %#ok<AGROW>
    ys(end + 1, 1) = y(k); %#ok<AGROW>
end
end

function segment = fit_segment(xs, ys, xmin, xmax)
segment = [];
try
    model = ols_fit(ys, normalize_columns({'x', xs}), '常数项', true);
catch
    return
end
slope = model.params.x;
intercept = model.params.('常数项');
segment = [xmin, intercept + slope * xmin, xmax, intercept + slope * xmax];
end

function value = sx(data, left, plot_w, xmin, xmax)
value = left + (data - xmin) / (xmax - xmin) * plot_w;
end

function value = sy(data, top, plot_h, ymin, ymax)
value = top + (ymax - data) / (ymax - ymin) * plot_h;
end

function [lo2, hi2] = pad_range(lo, hi)
if lo == hi
    delta = abs(lo) * 0.05;
    if delta == 0
        delta = 1;
    end
    lo2 = lo - delta;
    hi2 = hi + delta;
    return
end
span = hi - lo;
lo2 = lo - span * 0.06;
hi2 = hi + span * 0.06;
end

function ticks = tick_values(lo, hi, count)
step = nice_step(hi - lo, count);
start = ceil((lo - step * 1e-9) / step) * step;
ticks = [];
value = start;
for guard = 1:24 %#ok<NASGU>
    if value > hi + step * 1e-9
        break
    end
    if value >= lo - step * 1e-9
        ticks(end + 1) = value; %#ok<AGROW>
    end
    value = value + step;
end
if numel(ticks) < 2
    ticks = [lo, hi];
end
end

function step = nice_step(span, count)
if span <= 0
    step = 1;
    return
end
raw = span / max(count, 1);
expn = floor(log10(raw));
frac = raw / (10 ^ expn);
if frac < 1.5
    nice = 1;
elseif frac < 3
    nice = 2;
elseif frac < 7
    nice = 5;
else
    nice = 10;
end
step = nice * (10 ^ expn);
end

function text = tick_label(value)
if value ~= 0 && (abs(value) >= 1e6 || abs(value) < 1e-3)
    text = sprintf('%.4g', value);
    return
end
text = sprintf('%.4f', value);
while ~isempty(text) && text(end) == '0'
    text = text(1:end - 1);
end
if ~isempty(text) && text(end) == '.'
    text = text(1:end - 1);
end
if isempty(text)
    text = '0';
end
end

function path = etable(path, models, varargin)
%ETABLE  把一个或多个回归写成三线表，对应 outreg2e。
if exist('OCTAVE_VERSION', 'builtin'), addpath(fullfile(fileparts(mfilename('fullpath')), 'private')); end
%   matlab_tohtml.etable("results/reg.html", {m1, m2}, "titles", {"(1)", "(2)"}, "note", "因变量为价格。")
opt = struct();
opt.titles = {};
opt.digits = 3;
opt.stars = true;
opt.note = '';
if nargin >= 3
    opt = take_options(opt, varargin);
end
models = model_list(models);
if isempty(models)
    error('matlab_tohtml:Etable', 'etable 至少要有一个模型');
end
specs = cell(1, numel(models));
for k = 1:numel(models)
    specs{k} = coerce_model(models{k});
end
titles = opt.titles;
if ~isempty(titles)
    titles = as_cellstr(titles);
    if numel(titles) ~= numel(specs)
        error('matlab_tohtml:Etable', 'titles 的个数要和模型个数一致');
    end
    for k = 1:numel(specs)
        specs{k}.title = titles{k};
    end
end
for k = 1:numel(specs)
    if isempty(specs{k}.title)
        specs{k}.title = sprintf('(%d)', k);
    end
end
order = coef_order(specs);
stat_names = {};
for k = 1:numel(specs)
    names = fieldnames(specs{k}.stats);
    for s = 1:numel(names)
        if ~any(strcmp(stat_names, names{s}))
            stat_names{end + 1} = names{s}; %#ok<AGROW>
        end
    end
end
header = [{''}, cellfun(@(spec) spec.title, specs, 'UniformOutput', false)];
rows = {};
kinds = {};
for n = 1:numel(order)
    name = order{n};
    coef_cells = {name};
    se_cells = {''};
    any_se = false;
    for k = 1:numel(specs)
        if ~isfield(specs{k}.coef, name)
            coef_cells{end + 1} = ''; %#ok<AGROW>
            se_cells{end + 1} = ''; %#ok<AGROW>
            continue
        end
        star = '';
        if logical(opt.stars)
            star = stars_of(field_or_nan(specs{k}.p, name));
        end
        coef_cells{end + 1} = [format_number(specs{k}.coef.(name), opt.digits) star]; %#ok<AGROW>
        se_value = field_or_nan(specs{k}.se, name);
        if ~isnan(se_value)
            any_se = true;
            se_cells{end + 1} = ['(' format_number(se_value, opt.digits) ')']; %#ok<AGROW>
        else
            se_cells{end + 1} = ''; %#ok<AGROW>
        end
    end
    rows{end + 1} = coef_cells; %#ok<AGROW>
    kinds{end + 1} = ''; %#ok<AGROW>
    if any_se
        rows{end + 1} = se_cells; %#ok<AGROW>
        kinds{end + 1} = ''; %#ok<AGROW>
    end
end
first_stat = true;
for s = 1:numel(stat_names)
    stat = stat_names{s};
    cells = {stat};
    for k = 1:numel(specs)
        if isfield(specs{k}.stats, stat)
            cells{end + 1} = format_stat(specs{k}.stats.(stat), opt.digits); %#ok<AGROW>
        else
            cells{end + 1} = ''; %#ok<AGROW>
        end
    end
    if first_stat
        kinds{end + 1} = 'stat stat-start'; %#ok<AGROW>
        first_stat = false;
    else
        kinds{end + 1} = 'stat'; %#ok<AGROW>
    end
    rows{end + 1} = cells; %#ok<AGROW>
end
footnotes = {};
if logical(opt.stars)
    footnotes{end + 1} = '* p&lt;0.1，** p&lt;0.05，*** p&lt;0.01'; %#ok<AGROW>
end
if ~isempty(as_char(opt.note))
    footnotes{end + 1} = html_escape(as_char(opt.note)); %#ok<AGROW>
end
suffix = '';
for k = 1:numel(footnotes)
    suffix = [suffix '<p class="pytohtml-note">' footnotes{k} '</p>']; %#ok<AGROW>
end
write_table(path, header, rows, 2, kinds, suffix);
path = char(path);
end

function models = model_list(models)
if iscell(models)
    return
end
if isstruct(models)
    converted = cell(1, numel(models));
    for k = 1:numel(models)
        converted{k} = models(k);
    end
    models = converted;
    return
end
error('matlab_tohtml:Etable', '模型要放进元胞数组 {m1, m2}');
end

function spec = coerce_model(model)
if ~isstruct(model)
    error('matlab_tohtml:Etable', '每个模型要是 regress 的返回值，或带 coef 的 struct');
end
if isfield(model, 'params')
    coef = model.params;
elseif isfield(model, 'coef')
    coef = model.coef;
else
    error('matlab_tohtml:Etable', '模型缺少 params 或 coef');
end
if isfield(model, 'bse')
    se = model.bse;
elseif isfield(model, 'se')
    se = model.se;
else
    se = struct();
end
if isfield(model, 'pvalues')
    pvalues = model.pvalues;
elseif isfield(model, 'p')
    pvalues = model.p;
else
    pvalues = struct();
end
stats = struct();
if isfield(model, 'stats') && isstruct(model.stats)
    stats = model.stats;
end
if ~isfield(stats, 'N') && isfield(model, 'nobs')
    stats.N = model.nobs;
end
if ~isfield(stats, 'R²') && isfield(model, 'rsquared')
    stats.('R²') = model.rsquared;
end
const_name = '';
if isfield(model, 'const_name') && ~isempty(model.const_name)
    const_name = as_char(model.const_name);
elseif isfield(model, 'const') && ischar(model.const)
    const_name = model.const;
end
title = '';
if isfield(model, 'title')
    title = as_char(model.title);
end
spec = struct('title', title, 'coef', coef, 'se', se, 'p', pvalues, 'stats', stats, 'const', const_name);
end

function order = coef_order(specs)
const_names = {'常数项', '_cons', 'Intercept', 'const', 'intercept'};
coefs = {};
consts = {};
for k = 1:numel(specs)
    names = fieldnames(specs{k}.coef);
    for n = 1:numel(names)
        name = names{n};
        if any(strcmp(coefs, name)) || any(strcmp(consts, name))
            continue
        end
        if any(strcmp(const_names, name)) || strcmp(name, specs{k}.const)
            consts{end + 1} = name; %#ok<AGROW>
        else
            coefs{end + 1} = name; %#ok<AGROW>
        end
    end
end
order = [coefs, consts];
end

function value = field_or_nan(s, name)
if isstruct(s) && isfield(s, name)
    value = s.(name);
    if isempty(value) || ~isnumeric(value)
        value = NaN;
    end
else
    value = NaN;
end
end

function text = stars_of(p)
text = '';
if isempty(p) || isnan(p)
    return
end
if p < 0.01
    text = '***';
elseif p < 0.05
    text = '**';
elseif p < 0.1
    text = '*';
end
end

function text = format_number(value, digits)
text = sprintf('%.*f', digits, double(value));
end

function text = format_stat(value, digits)
if ischar(value)
    text = value;
    return
end
if (exist('isstring', 'builtin') || exist('isstring', 'file')) && isstring(value)
    text = char(value);
    return
end
if ~isnumeric(value) || isempty(value) || isnan(value)
    text = '';
    return
end
number = double(value);
if isfinite(number) && number == floor(number) && abs(number) < 1e15
    text = sprintf('%.0f', number);
else
    text = format_number(number, digits);
end
end

function gather(folders, varargin)
%GATHER  从目录收集 table* 和 figure*，和 tohtml 的目录模式一样。
if exist('OCTAVE_VERSION', 'builtin'), addpath(fullfile(fileparts(mfilename('fullpath')), 'private')); end
%   matlab_tohtml.gather({"results", "figures"}, "html", "report.html", "zoom", "80%")
% 只看目录本身，不进入子目录。
if ischar(folders) || is_string_scalar(folders)
    folders = {as_char(folders)};
elseif (exist('isstring', 'builtin') || exist('isstring', 'file')) && isstring(folders)
    folders = cellstr(folders);
end
opt = apply_mode(take_options(report_options(), varargin));
items = collect_resources(folders);
if isempty(items)
    error('matlab_tohtml:Folder', '这些目录里没有以 table 开头的表，也没有以 figure 开头的图');
end
if isempty(opt.html)
    if numel(folders) == 1
        folder = absolutepath(as_char(folders{1}));
        [parent, name] = fileparts(folder);
        opt.html = fullfile(parent, [name '.html']);
    else
        opt.html = absolutepath('report.html');
    end
else
    opt.html = absolutepath(opt.html);
end
if isempty(opt.md)
    opt.md = with_ext(opt.html, '.md');
else
    opt.md = absolutepath(opt.md);
end
records = {};
records{end + 1} = struct('kind', 'heading', 'level', 1, 'text', '图和表'); %#ok<AGROW>
for k = 1:numel(items)
    records{end + 1} = struct('kind', 'heading', 'level', 3, 'text', items{k}.name); %#ok<AGROW>
    rec = struct('kind', items{k}.kind, 'src', items{k}.src, 'title', '');
    if strcmp(items{k}.kind, 'fig')
        rec.zoom = as_char(opt.zoom);
        rec.width = as_char(opt.width);
        rec.height = as_char(opt.height);
    end
    records{end + 1} = rec; %#ok<AGROW>
end
bases = {};
for k = 1:numel(folders)
    bases{end + 1} = absolutepath(as_char(folders{k})); %#ok<AGROW>
end
bases{end + 1} = fileparts(opt.html); %#ok<AGROW>
render_records(records, opt.html, opt.md, bases, opt);
fprintf('md: %s\n', opt.md);
fprintf('html: %s\n', opt.html);
end

function items = collect_resources(folders)
items = {};
seen = {};
for index = 1:numel(folders)
    folder = absolutepath(as_char(folders{index}));
    if exist(folder, 'dir') ~= 7
        error('matlab_tohtml:Folder', '不是目录：%s', folder);
    end
    if any(strcmp(seen, folder))
        continue
    end
    seen{end + 1} = folder; %#ok<AGROW>
    listing = dir(folder);
    for k = 1:numel(listing)
        if listing(k).isdir
            continue
        end
        name = listing(k).name;
        kind = resource_kind(name);
        if isempty(kind)
            continue
        end
        item = struct('kind', kind, 'src', fullfile(folder, name), 'name', name);
        items{end + 1} = item; %#ok<AGROW>
    end
end
if isempty(items)
    return
end
keys = cell(1, numel(items));
for k = 1:numel(items)
    keys{k} = [items{k}.name char(1) items{k}.src];
end
[~, order] = sort(keys);
items = items(order);
end

function kind = resource_kind(name)
kind = '';
[~, ~, ext] = fileparts(name);
ext = lower(ext);
if numel(name) >= 5 && strcmp(name(1:5), 'table') && any(strcmp(ext, {'.html', '.md'}))
    kind = 'tab';
elseif numel(name) >= 6 && strcmp(name(1:6), 'figure') && ...
        any(strcmp(ext, {'.png', '.jpg', '.jpeg', '.svg', '.gif', '.bmp', '.webp'}))
    kind = 'fig';
end
end

function tf = is_string_scalar(value)
tf = (exist('isstring', 'builtin') || exist('isstring', 'file')) && isstring(value) && isscalar(value);
end

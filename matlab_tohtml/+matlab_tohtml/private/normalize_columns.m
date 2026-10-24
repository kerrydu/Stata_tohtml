function columns = normalize_columns(columns)
%NORMALIZE_COLUMNS  Name/value pairs, an Nx2 cell, or a struct, to a struct array.
if isempty(columns)
    columns = struct('name', {}, 'values', {});
    return
end
if isstruct(columns) && isfield(columns, 'name') && isfield(columns, 'values')
    return
end
if isstruct(columns)
    names = fieldnames(columns);
    converted = struct('name', {}, 'values', {});
    for k = 1:numel(names)
        converted(k).name = names{k}; %#ok<AGROW>
        converted(k).values = columns.(names{k});
    end
    columns = converted;
    return
end
if ~iscell(columns)
    error('matlab_tohtml:Columns', '变量要写成 {''名称'', 数值} 或 struct');
end
if is_pair_table(columns)
    converted = struct('name', {}, 'values', {});
    for k = 1:size(columns, 1)
        converted(k).name = as_char(columns{k, 1}); %#ok<AGROW>
        converted(k).values = columns{k, 2};
    end
    columns = converted;
    return
end
if mod(numel(columns), 2) ~= 0
    error('matlab_tohtml:Columns', '名称和数值要成对出现');
end
converted = struct('name', {}, 'values', {});
slot = 1;
for k = 1:2:numel(columns)
    if ~is_name(columns{k})
        error('matlab_tohtml:Columns', '第 %d 个名称不是字符串', slot);
    end
    converted(slot).name = as_char(columns{k}); %#ok<AGROW>
    converted(slot).values = columns{k + 1};
    slot = slot + 1;
end
columns = converted;
end

function tf = is_pair_table(columns)
tf = iscell(columns) && size(columns, 2) == 2 && size(columns, 1) >= 1;
if ~tf
    return
end
for k = 1:size(columns, 1)
    if ~is_name(columns{k, 1}) || ~(isnumeric(columns{k, 2}) || islogical(columns{k, 2}))
        tf = false;
        return
    end
end
end

function tf = is_name(value)
tf = ischar(value) || ((exist('isstring', 'builtin') || exist('isstring', 'file')) && isstring(value) && isscalar(value));
end

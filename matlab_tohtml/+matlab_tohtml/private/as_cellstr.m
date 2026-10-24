function cells = as_cellstr(value)
%AS_CELLSTR  Cell array of char rows.
if isempty(value)
    cells = {};
    return
end
if ischar(value)
    cells = {value};
    return
end
if (exist('isstring', 'builtin') || exist('isstring', 'file')) && isstring(value)
    cells = cellstr(value);
    return
end
if iscell(value)
    cells = cell(numel(value), 1);
    for k = 1:numel(value)
        cells{k} = as_char(value{k});
    end
    return
end
cells = {as_char(value)};
end

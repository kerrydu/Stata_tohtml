function rel = rel_path(target, base_dir)
%REL_PATH  Target relative to base_dir, with forward slashes.
target_parts = split_path(target);
base_parts = split_path(base_dir);
if isempty(target_parts)
    rel = as_char(target);
    return
end
if ~isempty(base_parts) && ~isempty(target_parts) && is_drive(base_parts{1}) ...
        && ~strcmpi(base_parts{1}, target_parts{1})
    rel = strrep(strrep(as_char(target), '\', '/'), '//', '/');
    return
end
index = 1;
limit = min(numel(target_parts), numel(base_parts));
while index <= limit && strcmp(target_parts{index}, base_parts{index})
    index = index + 1;
end
up = repmat({'..'}, 1, numel(base_parts) - index + 1);
down = target_parts(index:end);
parts = [up, down];
if isempty(parts)
    rel = '.';
else
    rel = strjoin(parts, '/');
end
end

function parts = split_path(path)
path = strrep(as_char(path), '\', '/');
raw = strsplit(path, '/');
if ischar(raw)
    raw = {raw};
end
parts = {};
for k = 1:numel(raw)
    piece = raw{k};
    if isempty(piece) || strcmp(piece, '.')
        continue
    end
    if strcmp(piece, '..')
        if ~isempty(parts)
            parts(end) = [];
        end
        continue
    end
    parts{end + 1} = piece; %#ok<AGROW>
end
end

function tf = is_drive(part)
tf = numel(part) == 2 && part(2) == ':' && isletter(part(1));
end

function records = parse_transcript(text)
%PARSE_TRANSCRIPT  Read a @@@mltohtml transcript into a cell of structs.
lines = split_lines(text);
records = {};
loose = {};
index = 1;
total = numel(lines);
while index <= total
    tokens = regexp(lines{index}, '^@@@mltohtml\s+(\w+)\s+(\d+)\s*$', 'tokens', 'once');
    if isempty(tokens)
        loose{end + 1} = lines{index}; %#ok<AGROW>
        index = index + 1;
        continue
    end
    [records, loose] = flush_loose(records, loose);
    kind = tokens{1};
    count = str2double(tokens{2});
    start = index + 1;
    stop = index + count;
    if stop > total
        if start <= total
            body = strjoin(lines(start:total), newline);
        else
            body = '';
        end
        records{end + 1} = decode_record(kind, body); %#ok<AGROW>
        records{end + 1} = struct('kind', 'error', 'text', '记录在写出时被截断。'); %#ok<AGROW>
        return
    end
    if count == 0
        body = '';
    else
        body = strjoin(lines(start:stop), newline);
    end
    records{end + 1} = decode_record(kind, body); %#ok<AGROW>
    index = stop + 1;
end
records = flush_loose(records, loose);
end

function [records, loose] = flush_loose(records, loose)
if isempty(loose)
    return
end
body = strjoin(loose, newline);
loose = {};
if isempty(strtrim(body))
    return
end
records{end + 1} = struct('kind', 'output', 'text', body);
end

function rec = decode_record(kind, body)
rec = struct('kind', kind, 'text', '');
if strcmp(kind, 'stmt')
    lines = split_lines(body);
    if isempty(lines)
        rec.source = '';
        rec.hide = false;
        return
    end
    try
        meta = jsondecode(lines{1});
    catch
        rec.source = body;
        rec.hide = false;
        return
    end
    if ~isstruct(meta)
        rec.source = body;
        rec.hide = false;
        return
    end
    if numel(lines) >= 2
        rec.source = strjoin(lines(2:end), newline);
    else
        rec.source = '';
    end
    rec = copy_fields(rec, meta);
    rec.kind = 'stmt';
    if ~isfield(rec, 'hide')
        rec.hide = false;
    end
    return
end
if any(strcmp(kind, {'output', 'error', 'value'}))
    rec.text = body;
    return
end
if isempty(body)
    return
end
try
    data = jsondecode(body);
catch
    rec.kind = 'error';
    rec.text = body;
    return
end
if ~isstruct(data)
    rec.text = body;
    return
end
rec = copy_fields(rec, data);
rec.kind = kind;
end

function rec = copy_fields(rec, data)
names = fieldnames(data);
for k = 1:numel(names)
    rec.(names{k}) = data.(names{k});
end
end

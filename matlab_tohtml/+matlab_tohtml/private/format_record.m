function text = format_record(kind, body, meta)
%FORMAT_RECORD  One transcript record. The body may contain anything.
if nargin < 2 || isempty(body)
    body = '';
else
    body = as_char(body);
end
if nargin >= 3 && ~isempty(meta)
    head = jsonencode(meta);
    if isempty(body)
        content = head;
    else
        content = [head newline body];
    end
else
    content = body;
end
lines = lines_of(content);
text = sprintf('@@@mltohtml %s %d\n', kind, numel(lines));
if ~isempty(lines)
    text = [text strjoin(lines, newline) newline];
end
end

function lines = lines_of(text)
if isempty(text)
    lines = {};
    return
end
text = strrep(text, sprintf('\r\n'), newline);
text = strrep(text, sprintf('\r'), newline);
if text(end) == newline
    text = text(1:end - 1);
end
if isempty(text)
    lines = {};
    return
end
lines = strsplit(text, newline, 'CollapseDelimiters', false);
if ischar(lines)
    lines = {lines};
end
end

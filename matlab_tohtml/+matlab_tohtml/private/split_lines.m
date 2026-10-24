function lines = split_lines(text)
%SPLIT_LINES  Split on newlines. A trailing newline does not add an empty row.
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

function items = split_script(source)
%SPLIT_SCRIPT  Top-level statements and ishere markers.
%
%   % ishere # 标题
%   % ishere fig using "a.svg", title("图")
%   % ishere tab using "a.html", title("表")
%   % ishere display sprintf('%d', n)
%   %{
%   叙述
%   %}
%
% A top-level sprintf, string, or quoted literal is narrative: its value
% enters the report and the statement stays out of the code block.
source = normalize_newlines(source);
items = {};
cursor = 1;
total = numel(source);
while cursor <= total
    cursor = skip_ht(source, cursor);
    if cursor > total
        break
    end
    if source(cursor) == newline
        cursor = cursor + 1;
        continue
    end
    if source(cursor) == '%'
        if line_has_only_ws_before(source, cursor)
            if is_block_open_at(source, cursor)
                [item, cursor] = read_block(source, cursor);
                items{end + 1} = item; %#ok<AGROW>
                continue
            end
            body = comment_body_at(source, cursor);
            line_no = line_number_at(source, cursor);
            if has_prefix(body, '/**')
                [item, cursor] = read_stata(source, cursor);
                items{end + 1} = item; %#ok<AGROW>
                continue
            end
            if has_prefix(body, '**/')
                cursor = after_line(source, cursor);
                continue
            end
            marker = parse_ishere(body, line_no);
            if ~isempty(marker)
                items{end + 1} = marker; %#ok<AGROW>
            end
            cursor = after_line(source, cursor);
            continue
        end
        cursor = after_line(source, cursor);
        continue
    end
    if is_word_at(source, cursor, 'function') && line_has_only_ws_before(source, cursor)
        break
    end
    [item, cursor] = read_statement(source, cursor);
    if ~isempty(strtrim(strrep(item.text, ';', '')))
        items{end + 1} = item; %#ok<AGROW>
    end
end
end

function [item, next] = read_statement(source, start)
total = numel(source);
paren = 0;
bracket = 0;
brace = 0;
block = 0;
in_sq = false;
in_dq = false;
index = start;
while index <= total
    ch = source(index);
    if in_sq
        if ch == ''''
            if index < total && source(index + 1) == ''''
                index = index + 2;
            else
                in_sq = false;
                index = index + 1;
            end
        else
            index = index + 1;
        end
        continue
    end
    if in_dq
        if ch == '"'
            if index < total && source(index + 1) == '"'
                index = index + 2;
            else
                in_dq = false;
                index = index + 1;
            end
        else
            index = index + 1;
        end
        continue
    end
    if ch == '%'
        index = skip_to_eol(source, index);
        continue
    end
    if ch == '.' && index + 2 <= total && source(index + 1) == '.' && source(index + 2) == '.'
        index = skip_to_eol(source, index);
        if index <= total && source(index) == newline
            index = index + 1;
        end
        continue
    end
    if ch == ''''
        if is_transpose_at(source, index)
            index = index + 1;
        else
            in_sq = true;
            index = index + 1;
        end
        continue
    end
    if ch == '"'
        in_dq = true;
        index = index + 1;
        continue
    end
    if ch == '('
        paren = paren + 1;
        index = index + 1;
        continue
    end
    if ch == ')'
        paren = max(paren - 1, 0);
        index = index + 1;
        continue
    end
    if ch == '['
        bracket = bracket + 1;
        index = index + 1;
        continue
    end
    if ch == ']'
        bracket = max(bracket - 1, 0);
        index = index + 1;
        continue
    end
    if ch == '{'
        brace = brace + 1;
        index = index + 1;
        continue
    end
    if ch == '}'
        brace = max(brace - 1, 0);
        index = index + 1;
        continue
    end
    depth = paren + bracket + brace;
    if depth == 0 && block > 0 && is_word_at(source, index, 'end')
        block = block - 1;
        index = index + 3;
        if block == 0
            [item, next] = finish_statement(source, start, index);
            return
        end
        continue
    end
    if depth == 0 && is_open_keyword(source, index)
        word = open_keyword_at(source, index);
        block = block + 1;
        index = index + numel(word);
        continue
    end
    if depth == 0 && block == 0 && (ch == ';' || ch == ',' || ch == newline)
        if ch == newline
            stop = index;
            next = index + 1;
        else
            stop = index + 1;
            next = index + 1;
        end
        item = make_stmt(source, start, stop);
        return
    end
    index = index + 1;
end
item = make_stmt(source, start, total + 1);
next = total + 1;
end

function [item, next] = finish_statement(source, start, index)
total = numel(source);
index = skip_ht(source, index);
if index <= total && source(index) == '%'
    index = skip_to_eol(source, index);
end
stop = index;
if index <= total && (source(index) == ';' || source(index) == ',')
    stop = index + 1;
    index = index + 1;
    index = skip_ht(source, index);
    if index <= total && source(index) == '%'
        index = skip_to_eol(source, index);
    end
end
if index <= total && source(index) == newline
    index = index + 1;
end
item = make_stmt(source, start, stop);
next = index;
end

function [item, next] = read_block(source, start)
start_line = line_number_at(source, start);
eol = skip_to_eol(source, start);
content_start = eol;
if eol <= numel(source) && source(eol) == newline
    content_start = eol + 1;
end
index = content_start;
total = numel(source);
while index <= total
    eol = skip_to_eol(source, index);
    line = source(index:max(eol - 1, index - 1));
    if eol == index
        line = '';
    end
    if ~isempty(regexp(line, '^\s*%\}\s*$', 'once'))
        content = source(content_start:index - 1);
        item = make_md(strip_edge_newlines(content), start_line, line_number_at(source, index));
        next = eol;
        if next <= total && source(next) == newline
            next = next + 1;
        end
        return
    end
    if eol <= total && source(eol) == newline
        index = eol + 1;
    else
        break
    end
end
content = '';
if content_start <= total
    content = source(content_start:total);
end
item = make_md(strip_edge_newlines(content), start_line, line_number_at(source, total));
next = total + 1;
end

function [item, next] = read_stata(source, start)
body = comment_body_at(source, start);
start_line = line_number_at(source, start);
first = '';
if numel(body) > 3
    first = strtrim(body(4:end));
end
if numel(first) >= 3 && strcmp(first(end - 2:end), '**/')
    text = strtrim(first(1:end - 3));
    item = make_md(text, start_line, start_line);
    next = after_line(source, start);
    return
end
chunks = {};
if ~isempty(first)
    chunks{end + 1} = first; %#ok<AGROW>
end
cursor = after_line(source, start);
stop_line = start_line;
total = numel(source);
while cursor <= total
    eol = skip_to_eol(source, cursor);
    if eol == cursor
        line = '';
    else
        line = source(cursor:eol - 1);
    end
    line_no = line_number_at(source, cursor);
    if is_comment_only_line(line)
        piece = comment_body_line(line);
        stop_line = line_no;
        if strcmp(piece, '**/')
            cursor = after_eol(source, eol);
            break
        end
        if numel(piece) >= 3 && strcmp(piece(end - 2:end), '**/')
            rest = '';
            if numel(piece) > 3
                rest = strtrim(piece(1:end - 3));
            end
            if ~isempty(rest)
                chunks{end + 1} = rest; %#ok<AGROW>
            end
            cursor = after_eol(source, eol);
            break
        end
        chunks{end + 1} = piece; %#ok<AGROW>
        cursor = after_eol(source, eol);
        continue
    end
    if isempty(strtrim(line))
        chunks{end + 1} = ''; %#ok<AGROW>
        stop_line = line_no;
        cursor = after_eol(source, eol);
        continue
    end
    break
end
item = make_md(strip_edge_newlines(strjoin(chunks, newline)), start_line, stop_line);
next = cursor;
end

function item = parse_ishere(body, line_no)
item = [];
if ~has_prefix(body, 'ishere')
    return
end
heading = regexp(body, '^ishere\s+(#{1,6})(?:\s+(.*?))?\s*$', 'tokens', 'once');
if ~isempty(heading)
    item = blank_item();
    item.kind = 'heading';
    item.start = line_no;
    item.stop = line_no;
    item.level = numel(heading{1});
    if numel(heading) >= 2
        item.text = char(heading{2});
    end
    return
end
using = regexp(body, '^ishere\s+(fig|figure|tab|table)\s+using\s+(.+)$', 'tokens', 'once', 'ignorecase');
if ~isempty(using)
    word = lower(using{1});
    if any(strcmp(word, {'fig', 'figure'}))
        kind = 'fig';
    else
        kind = 'tab';
    end
    try
        [path, options] = using_tail(strtrim(using{2}));
    catch err
        item = blank_item();
        item.kind = 'error';
        item.start = line_no;
        item.stop = line_no;
        item.text = err.message;
        return
    end
    item = blank_item();
    item.kind = kind;
    item.start = line_no;
    item.stop = line_no;
    item.src = strrep(path, '\', '/');
    item.title = option_value(options, 'title');
    item.zoom = option_value(options, 'zoom');
    item.width = option_value(options, 'width');
    item.height = option_value(options, 'height');
    item.cssfile = option_value(options, 'cssfile');
    return
end
display_mark = regexp(body, '^ishere\s+display\s+(.+)$', 'tokens', 'once', 'ignorecase');
if ~isempty(display_mark)
    item = blank_item();
    item.kind = 'display';
    item.start = line_no;
    item.stop = line_no;
    item.expr = strtrim(display_mark{1});
    return
end
item = blank_item();
item.kind = 'error';
item.start = line_no;
item.stop = line_no;
item.text = ['无法识别的标记：' body];
end

function [path, options] = using_tail(tail)
if isempty(tail) || (tail(1) ~= '''' && tail(1) ~= '"')
    error('matlab_tohtml:Marker', 'using 后面需要引号路径：%s', tail);
end
quote = tail(1);
index = 2;
path = '';
while index <= numel(tail) && tail(index) ~= quote
    path = [path tail(index)]; %#ok<AGROW>
    index = index + 1;
end
if index > numel(tail)
    error('matlab_tohtml:Marker', '路径缺少结束引号：%s', tail);
end
index = index + 1;
rest = strtrim(tail(index:end));
if ~isempty(rest) && rest(1) == ','
    rest = strtrim(rest(2:end));
end
options = parse_options(rest);
end

function options = parse_options(text)
options = struct();
index = 1;
total = numel(text);
while index <= total
    while index <= total && (text(index) == ' ' || text(index) == sprintf('\t') || text(index) == ',')
        index = index + 1;
    end
    if index > total
        break
    end
    tokens = regexp(text(index:end), '^(\w+)\s*\(', 'tokens', 'once');
    if isempty(tokens)
        break
    end
    name = lower(tokens{1});
    index = index + numel(regexp(text(index:end), '^\w+\s*\(', 'match', 'once'));
    if index <= total && (text(index) == '''' || text(index) == '"')
        quote = text(index);
        index = index + 1;
        value = '';
        while index <= total && text(index) ~= quote
            value = [value text(index)]; %#ok<AGROW>
            index = index + 1;
        end
        if index <= total && text(index) == quote
            index = index + 1;
        end
    else
        value = '';
        while index <= total && text(index) ~= ')'
            value = [value text(index)]; %#ok<AGROW>
            index = index + 1;
        end
        value = strtrim(value);
    end
    if index <= total && text(index) == ')'
        index = index + 1;
    end
    options.(name) = value;
end
end

function value = option_value(options, name)
if isfield(options, name)
    value = options.(name);
else
    value = '';
end
end

function item = make_stmt(source, start, stop)
if stop < start
    stop = start;
end
if stop > numel(source) + 1
    stop = numel(source) + 1;
end
text = source(start:stop - 1);
item = blank_item();
item.kind = 'stmt';
item.text = text;
item.start = line_number_at(source, start);
last = max(start, stop - 1);
item.stop = line_number_at(source, last);
item.narrative = is_narrative_source(text);
end

function item = make_md(text, start_line, stop_line)
item = blank_item();
item.kind = 'md';
item.text = text;
item.start = start_line;
item.stop = stop_line;
end

function tf = is_narrative_source(stmt)
text = strtrim(stmt);
tf = false;
if isempty(text)
    return
end
if text(1) == '''' || text(1) == '"'
    tf = true;
    return
end
head = regexp(text, '^[A-Za-z_][A-Za-z0-9_]*', 'match', 'once');
tf = any(strcmp(head, {'sprintf', 'string', 'strcat', 'compose'}));
end

function s = blank_item()
s.kind = '';
s.text = '';
s.start = 0;
s.stop = 0;
s.level = 1;
s.src = '';
s.title = '';
s.zoom = '';
s.width = '';
s.height = '';
s.cssfile = '';
s.expr = '';
s.narrative = false;
end

function text = normalize_newlines(text)
text = strrep(text, sprintf('\r\n'), newline);
text = strrep(text, sprintf('\r'), newline);
end

function index = skip_ht(text, index)
total = numel(text);
while index <= total && (text(index) == ' ' || text(index) == sprintf('\t'))
    index = index + 1;
end
end

function index = skip_to_eol(text, index)
total = numel(text);
while index <= total && text(index) ~= newline
    index = index + 1;
end
end

function index = after_line(text, index)
index = skip_to_eol(text, index);
if index <= numel(text) && text(index) == newline
    index = index + 1;
end
end

function index = after_eol(text, eol)
index = eol;
if index <= numel(text) && text(index) == newline
    index = index + 1;
end
end

function tf = line_has_only_ws_before(text, index)
tf = true;
cursor = index;
while cursor > 1 && text(cursor - 1) ~= newline
    cursor = cursor - 1;
    if text(cursor) ~= ' ' && text(cursor) ~= sprintf('\t')
        tf = false;
        return
    end
end
end

function tf = is_block_open_at(text, index)
tf = false;
total = numel(text);
if index >= total || text(index) ~= '%' || text(index + 1) ~= '{'
    return
end
cursor = index + 2;
while cursor <= total && text(cursor) ~= newline
    if text(cursor) ~= ' ' && text(cursor) ~= sprintf('\t')
        return
    end
    cursor = cursor + 1;
end
tf = true;
end

function body = comment_body_at(text, index)
eol = skip_to_eol(text, index);
body = comment_body_line(text(index:max(eol - 1, index - 1)));
end

function body = comment_body_line(line)
body = line;
if ~isempty(body) && body(1) == '%'
    body = body(2:end);
end
if ~isempty(body) && body(1) == ' '
    body = body(2:end);
end
body = strtrim(body);
end

function tf = is_comment_only_line(line)
stripped = strtrim(line);
tf = ~isempty(stripped) && stripped(1) == '%';
end

function number = line_number_at(text, index)
if index <= 1
    number = 1;
    return
end
index = min(index, numel(text));
number = 1 + numel(strfind(text(1:index - 1), newline));
end

function tf = has_prefix(text, prefix)
tf = numel(text) >= numel(prefix) && strcmp(text(1:numel(prefix)), prefix);
end

function text = strip_edge_newlines(text)
if isempty(text)
    return
end
while ~isempty(text) && (text(1) == newline || text(1) == char(13))
    text = text(2:end);
end
while ~isempty(text) && (text(end) == newline || text(end) == char(13))
    text = text(1:end - 1);
end
end

function tf = is_transpose_at(text, index)
cursor = index - 1;
while cursor >= 1 && (text(cursor) == ' ' || text(cursor) == sprintf('\t'))
    cursor = cursor - 1;
end
if cursor < 1 || text(cursor) == newline
    tf = false;
    return
end
ch = text(cursor);
if ch == ')' || ch == ']' || ch == '}' || ch == '.' || ch == ''''
    tf = true;
    return
end
tf = is_ident_char(ch);
end

function tf = is_open_keyword(text, index)
tf = ~isempty(open_keyword_at(text, index));
end

function word = open_keyword_at(text, index)
words = {'function', 'parfor', 'switch', 'while', 'for', 'try', 'if'};
word = '';
for k = 1:numel(words)
    if is_word_at(text, index, words{k})
        word = words{k};
        return
    end
end
end

function tf = is_word_at(text, index, word)
tf = false;
width = numel(word);
if index + width - 1 > numel(text)
    return
end
if ~strcmp(text(index:index + width - 1), word)
    return
end
if index > 1 && is_ident_char(text(index - 1))
    return
end
if index + width <= numel(text) && is_ident_char(text(index + width))
    return
end
tf = true;
end

function tf = is_ident_char(ch)
value = double(ch);
tf = (value >= 48 && value <= 57) || (value >= 65 && value <= 90) || ...
    (value >= 97 && value <= 122) || value == 95 || value >= 128;
end

function status = execute_script(script_path, log_path)
%EXECUTE_SCRIPT  Run a script and write an @@@mltohtml transcript.
script_path = absolutepath(script_path);
log_path = absolutepath(log_path);
script_dir = fileparts(script_path);
source = read_text(script_path);
items = split_script(source);
ensure_dir(fileparts(log_path));
fid = fopen(log_path, 'wb');
if fid < 0
    error('matlab_tohtml:IO', '无法写入 %s', log_path);
end
cleaner_fid = onCleanup(@() fclose(fid));

meta = struct('version', 1, 'script', script_path, 'cwd', script_dir);
write_piece(fid, format_record('meta', jsonencode(meta)));

previous_dir = pwd;
previous_path = path;
cleaner_dir = onCleanup(@() cd(previous_dir));
cleaner_path = onCleanup(@() path(previous_path));
addpath(package_parent());
addpath(script_dir);
cd(script_dir);

status = 0;
for index = 1:numel(items)
    item = items{index};
    failed = false;
    switch item.kind
        case 'heading'
            payload = struct('level', item.level, 'text', item.text);
            write_piece(fid, format_record('heading', jsonencode(payload)));
        case 'md'
            failed = write_md(fid, item.text, item.start, script_path, item.text);
        case 'display'
            [~, value, err] = capture_value(item.expr);
            if ~isempty(err)
                write_piece(fid, format_record('error', error_text(err)));
                failed = true;
            else
                payload = struct('name', item.expr, 'value', shown_text(value));
                write_piece(fid, format_record('show', jsonencode(payload)));
            end
        case {'fig', 'tab'}
            payload = struct( ...
                'src', item.src, ...
                'title', item.title, ...
                'zoom', item.zoom, ...
                'width', item.width, ...
                'height', item.height, ...
                'cssfile', item.cssfile);
            write_piece(fid, format_record(item.kind, jsonencode(payload)));
        case 'error'
            write_piece(fid, format_record('error', item.text));
            failed = true;
        case 'stmt'
            if item.narrative
                failed = false;
                expr = expr_for_value(item.text);
                [out, value, err] = capture_value(expr);
                write_output(fid, out);
                if ~isempty(err)
                    write_piece(fid, format_record('error', error_text(err)));
                    failed = true;
                elseif ~is_text_value(value)
                    write_piece(fid, format_record('error', '叙述表达式的结果要是字符串'));
                    failed = true;
                else
                    text = as_char(value);
                    [text, err] = fill_display_tags(text);
                    if ~isempty(err)
                        write_piece(fid, format_record('error', error_text(err)));
                        failed = true;
                    else
                        failed = write_md(fid, text, item.start, script_path, item.text);
                    end
                end
            else
                [out, err] = capture_statement(item.text);
                meta = struct('start', item.start, 'stop', item.stop, 'hide', false);
                write_piece(fid, format_record('stmt', item.text, meta));
                write_output(fid, out);
                if ~isempty(err)
                    write_piece(fid, format_record('error', error_text(err)));
                    failed = true;
                end
            end
        otherwise
            write_piece(fid, format_record('error', ['无法识别的标记：' item.kind]));
            failed = true;
    end
    if failed
        status = 1;
        break
    end
end
end

function tf = is_text_value(value)
tf = ischar(value);
if tf
    return
end
tf = (exist('isstring', 'builtin') || exist('isstring', 'file')) && isstring(value);
end

function failed = write_md(fid, text, line_no, script_path, source)
failed = false;
if isempty(strtrim(text))
    return
end
payload = struct('text', text, 'line', line_no, 'file', script_path);
numbers = numbers_in_prose(source);
if ~isempty(numbers)
    payload.hardcoded = numbers;
end
write_piece(fid, format_record('md', jsonencode(payload)));
end

function write_output(fid, out)
out = truncate_text(out);
if isempty(strtrim(out))
    return
end
write_piece(fid, format_record('output', out));
end

function [out, err] = capture_statement(stmt)
err = [];
out = '';
try
    out = evalc('evalin(''caller'', stmt)');
catch err
end
end

function [out, value, err] = capture_value(expr)
err = [];
value = '';
out = '';
stmt = ['mltohtml_narrative_value__ = (' expr newline ');'];
try
    out = evalc('evalin(''caller'', stmt)');
    value = evalin('caller', 'mltohtml_narrative_value__');
catch err
    return
end
try
    evalin('caller', 'clear mltohtml_narrative_value__');
catch
end
end

function [text, err] = fill_display_tags(text)
err = [];
prefix = '{ishere display ';
cursor = 1;
parts = {};
while cursor <= numel(text)
    rest = text(cursor:end);
    found = strfind(rest, prefix);
    if isempty(found)
        parts{end + 1} = text(cursor:end); %#ok<AGROW>
        break
    end
    start = cursor + found(1) - 1;
    if start > cursor
        parts{end + 1} = text(cursor:start - 1); %#ok<AGROW>
    end
    close_at = closing_brace(text, start);
    if isempty(close_at)
        parts{end + 1} = text(start:end); %#ok<AGROW>
        break
    end
    inner = text(start + 1:close_at - 1);
    expr = strtrim(inner(numel('ishere display') + 1:end));
    % evalin('caller') is execute_script, which holds the script workspace.
    stmt = ['mltohtml_narrative_value__ = (' expr newline ');'];
    try
        evalc('evalin(''caller'', stmt)');
        value = evalin('caller', 'mltohtml_narrative_value__');
        evalin('caller', 'clear mltohtml_narrative_value__');
    catch err
        text = '';
        return
    end
    parts{end + 1} = shown_text(value); %#ok<AGROW>
    cursor = close_at + 1;
end
text = strjoin(parts, '');
end

function expr = expr_for_value(stmt)
expr = cut_trailing_comment(stmt);
while ~isempty(expr) && is_trailing_space(expr(end))
    expr = expr(1:end - 1);
end
if ~isempty(expr) && expr(end) == ';'
    expr = expr(1:end - 1);
end
end

function expr = cut_trailing_comment(stmt)
total = numel(stmt);
paren = 0;
bracket = 0;
brace = 0;
in_sq = false;
in_dq = false;
index = 1;
while index <= total
    ch = stmt(index);
    if in_sq
        if ch == ''''
            if index < total && stmt(index + 1) == ''''
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
            if index < total && stmt(index + 1) == '"'
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
    if ch == ''''
        in_sq = true;
        index = index + 1;
        continue
    end
    if ch == '"'
        in_dq = true;
        index = index + 1;
        continue
    end
    if ch == '%' && paren == 0 && bracket == 0 && brace == 0
        stop = index;
        while stop <= total && stmt(stop) ~= newline
            stop = stop + 1;
        end
        if stop > total
            expr = stmt(1:max(index - 1, 0));
            if index == 1
                expr = '';
            end
            return
        end
        index = stop;
        continue
    end
    if ch == '('
        paren = paren + 1;
    elseif ch == ')'
        paren = max(paren - 1, 0);
    elseif ch == '['
        bracket = bracket + 1;
    elseif ch == ']'
        bracket = max(bracket - 1, 0);
    elseif ch == '{'
        brace = brace + 1;
    elseif ch == '}'
        brace = max(brace - 1, 0);
    end
    index = index + 1;
end
expr = stmt;
end

function tf = is_trailing_space(ch)
tf = ch == ' ' || ch == sprintf('\t') || ch == newline || ch == char(13);
end

function text = shown_text(value)
if ischar(value)
    text = value;
    return
end
if (exist('isstring', 'builtin') || exist('isstring', 'file')) && isstring(value)
    text = char(value);
    return
end
if isnumeric(value) && isscalar(value)
    if isfinite(value) && value == floor(value) && abs(value) < 1e15
        text = sprintf('%.0f', value);
    else
        text = sprintf('%.12g', value);
    end
    return
end
text = strtrim(evalc('disp(value)'));
end

function numbers = numbers_in_prose(text)
text = strip_display_tags(text);
text = regexprep(text, '\{[^{}]*\}', '');
text = regexprep(text, '%[-+0 #]*\d*(?:\.\d+)?[A-Za-z]', '');
try
    matches = regexp(text, '(?<![A-Za-z0-9_.^])(\d+\.\d+|\d{2,})(?![A-Za-z0-9_])', 'tokens');
catch
    matches = regexp(text, '(^|[^A-Za-z0-9_.^])(\d+\.\d+|\d{2,})([^A-Za-z0-9_]|$)', 'tokens');
end
numbers = {};
seen = {};
for k = 1:numel(matches)
    token = matches{k};
    if numel(token) == 1
        number = token{1};
    else
        number = token{2};
    end
    if ~any(strcmp(seen, number))
        seen{end + 1} = number; %#ok<AGROW>
        numbers{end + 1} = number; %#ok<AGROW>
    end
end
end

function text = strip_display_tags(text)
prefix = '{ishere display ';
cursor = 1;
parts = {};
while cursor <= numel(text)
    rest = text(cursor:end);
    found = strfind(rest, prefix);
    if isempty(found)
        parts{end + 1} = text(cursor:end); %#ok<AGROW>
        break
    end
    start = cursor + found(1) - 1;
    if start > cursor
        parts{end + 1} = text(cursor:start - 1); %#ok<AGROW>
    end
    close_at = closing_brace(text, start);
    if isempty(close_at)
        parts{end + 1} = text(start:end); %#ok<AGROW>
        break
    end
    cursor = close_at + 1;
end
text = strjoin(parts, '');
end

function pos = closing_brace(text, open_at)
depth = 0;
pos = [];
for index = open_at:numel(text)
    ch = text(index);
    if ch == '{'
        depth = depth + 1;
    elseif ch == '}'
        depth = depth - 1;
        if depth == 0
            pos = index;
            return
        end
    end
end
end

function text = truncate_text(text)
if isempty(text)
    return
end
lines = split_lines(text);
clipped = false;
if numel(lines) > 200
    lines = lines(1:200);
    text = strjoin(lines, newline);
    clipped = true;
end
if numel(text) > 20000
    text = text(1:20000);
    clipped = true;
end
if clipped
    text = [text newline '…（输出已截断）'];
end
end

function text = error_text(err)
text = err.message;
if ~isempty(text) && text(end) ~= newline
    text = [text newline];
end
end

function write_piece(fid, text)
if is_octave()
    fwrite(fid, uint8(text));
else
    fwrite(fid, unicode2native(as_char(text), 'UTF-8'));
end
end

function folder = package_parent()
private_dir = fileparts(mfilename('fullpath'));
package_dir = fileparts(private_dir);
folder = fileparts(package_dir);
end

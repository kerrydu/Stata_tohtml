function render_records(records, html_path, md_path, base_dirs, opt)
%RENDER_RECORDS  Markdown and HTML from already-parsed records.
if nargin < 5
    opt = report_options();
end
opt = apply_mode(opt);
bases = unique_keep(base_dirs);
blocks = build_blocks(records, opt, bases, html_path);
title = document_title(blocks, html_path);
markdown = blocks_to_md(blocks);
body = blocks_to_html(blocks);
use_math = mathjax_on(opt, markdown);
html = document_html(title, body, use_math, strcmp(opt.mode, 'cleancode'), opt.tabwidth, opt.tabheight);
if ~isempty(html_path)
    write_text(html_path, html);
end
if nargin >= 3 && ~isempty(md_path)
    write_text(md_path, markdown);
end
end

function blocks = build_blocks(records, opt, base_dirs, html_path)
shows = cell(0, 2);
blocks = {};
script_text = script_from_records(records);
lines = {};
skip = [];
if ~isempty(script_text)
    lines = split_lines(script_text);
    skip = marker_lines(script_text);
end
for k = 1:numel(records)
    rec = records{k};
    kind = rec.kind;
    if strcmp(kind, 'show')
        name = '';
        value = '';
        if isfield(rec, 'name')
            name = as_char(rec.name);
        end
        if isfield(rec, 'value')
            value = as_char(rec.value);
        end
        shows(end + 1, :) = {name, value}; %#ok<AGROW>
        continue
    end
    if strcmp(kind, 'meta')
        continue
    end
    if strcmp(kind, 'stmt') && isfield(rec, 'hide') && logical(rec.hide)
        continue
    end
    if strcmp(opt.mode, 'clean') && any(strcmp(kind, {'stmt', 'output', 'value', 'error'}))
        continue
    end
    if strcmp(opt.mode, 'cleancode') && any(strcmp(kind, {'output', 'value'}))
        continue
    end
    if strcmp(kind, 'heading')
        level = 1;
        if isfield(rec, 'level') && ~isempty(rec.level)
            level = rec.level;
        end
        text = '';
        if isfield(rec, 'text')
            text = as_char(rec.text);
        end
        blocks{end + 1} = struct('kind', 'h', 'level', level, 'text', text); %#ok<AGROW>
    elseif strcmp(kind, 'md')
        text = '';
        if isfield(rec, 'text')
            text = as_char(rec.text);
        end
        text = substitute_displays(text, shows);
        blocks{end + 1} = struct('kind', 'md', 'text', text); %#ok<AGROW>
        if ~strcmp(opt.mode, 'clean') && isfield(rec, 'hardcoded') && ~isempty(rec.hardcoded)
            numbers = strjoin(as_cellstr(rec.hardcoded), '、');
            where = '';
            if isfield(rec, 'line') && ~isempty(rec.line)
                where = sprintf('（第 %.0f 行）', rec.line);
            end
            warning_text = sprintf(['叙述里有手写数字 %s%s。请写进 sprintf 或字符串，' ...
                '例如 sprintf(''系数是 %%.2f。'', b)。'], numbers, where);
            blocks{end + 1} = struct('kind', 'warn', 'text', warning_text); %#ok<AGROW>
        end
    elseif strcmp(kind, 'stmt')
        info = struct('source', '', 'start', [], 'stop', []);
        if isfield(rec, 'source')
            info.source = as_char(rec.source);
        end
        if isfield(rec, 'start')
            info.start = rec.start;
        end
        if isfield(rec, 'stop')
            info.stop = rec.stop;
        end
        blocks{end + 1} = struct('kind', 'code', 'info', info); %#ok<AGROW>
    elseif any(strcmp(kind, {'output', 'value'}))
        blocks{end + 1} = struct('kind', 'out', 'text', field_text(rec, 'text')); %#ok<AGROW>
    elseif strcmp(kind, 'error')
        blocks{end + 1} = struct('kind', 'err', 'text', field_text(rec, 'text')); %#ok<AGROW>
    elseif strcmp(kind, 'fig')
        blocks{end + 1} = struct('kind', 'html', 'text', figure_html(rec, base_dirs, opt.embed, html_path)); %#ok<AGROW>
    elseif strcmp(kind, 'tab')
        blocks{end + 1} = struct('kind', 'html', 'text', table_html(rec, base_dirs)); %#ok<AGROW>
    elseif strcmp(kind, 'warning') && ~strcmp(opt.mode, 'clean')
        blocks{end + 1} = struct('kind', 'warn', 'text', field_text(rec, 'text')); %#ok<AGROW>
    end
end
blocks = merge_code(blocks, lines, skip);
end

function text = field_text(rec, name)
text = '';
if isfield(rec, name)
    text = as_char(rec.(name));
end
end

function script_text = script_from_records(records)
script_text = '';
for k = 1:numel(records)
    rec = records{k};
    if strcmp(rec.kind, 'meta') && isfield(rec, 'script') && ~isempty(rec.script)
        path = as_char(rec.script);
        if exist(path, 'file') == 2
            try
                script_text = read_text(path);
            catch
                script_text = '';
            end
        end
        return
    end
end
end

function skip = marker_lines(source)
items = split_script(source);
skip = [];
for k = 1:numel(items)
    item = items{k};
    drop = any(strcmp(item.kind, {'md', 'heading', 'fig', 'tab', 'display', 'error'})) ...
        || (strcmp(item.kind, 'stmt') && item.narrative);
    if drop && item.stop >= item.start && item.start > 0
        skip = [skip, item.start:item.stop]; %#ok<AGROW>
    end
end
end

function blocks = merge_code(blocks, lines, skip)
merged = {};
seen_code = false;
for k = 1:numel(blocks)
    block = blocks{k};
    if strcmp(block.kind, 'code') && ~isempty(merged) && strcmp(merged{end}.kind, 'code') ...
            && can_merge(merged{end}.info, block.info, lines, skip)
        merged{end}.info.stop = block.info.stop;
        continue
    end
    if strcmp(block.kind, 'code')
        info = block.info;
        if ~isempty(lines) && ~seen_code && ~isempty(info.start)
            start = info.start;
            while start > 1 && ~ismember(start - 1, skip)
                previous = strtrim(lines{start - 1});
                if ~isempty(previous) && previous(1) ~= '%'
                    break
                end
                start = start - 1;
            end
            info.start = start;
        end
        if strcmp(block.kind, 'code')
            seen_code = true;
        end
        block.info = info;
        merged{end + 1} = block; %#ok<AGROW>
        continue
    end
    merged{end + 1} = block; %#ok<AGROW>
end
blocks = {};
for k = 1:numel(merged)
    block = merged{k};
    if ~strcmp(block.kind, 'code')
        blocks{end + 1} = block; %#ok<AGROW>
        continue
    end
    source = block.info.source;
    start = block.info.start;
    stop = block.info.stop;
    if ~isempty(lines) && ~isempty(start) && ~isempty(stop) && start >= 1 && stop >= start && stop <= numel(lines)
        kept = {};
        for line_no = start:stop
            if ~ismember(line_no, skip)
                kept{end + 1} = lines{line_no}; %#ok<AGROW>
            end
        end
        while ~isempty(kept) && isempty(strtrim(kept{1}))
            kept(1) = [];
        end
        while ~isempty(kept) && isempty(strtrim(kept{end}))
            kept(end) = [];
        end
        source = strjoin(kept, newline);
    end
    if ~isempty(strtrim(source))
        blocks{end + 1} = struct('kind', 'code', 'text', source); %#ok<AGROW>
    end
end
end

function tf = can_merge(prev, cur, lines, skip)
tf = false;
if isempty(lines) || isempty(prev.stop) || isempty(cur.start)
    return
end
if any(ismember((prev.stop + 1):(cur.start - 1), skip))
    return
end
if cur.start <= prev.stop + 1
    tf = true;
    return
end
between = lines(prev.stop + 1:cur.start - 1);
for k = 1:numel(between)
    piece = strtrim(between{k});
    if ~isempty(piece) && piece(1) ~= '%'
        return
    end
end
tf = true;
end

function title = document_title(blocks, html_path)
title = 'report';
for k = 1:numel(blocks)
    if strcmp(blocks{k}.kind, 'h') && ~isempty(strtrim(blocks{k}.text))
        title = strtrim(blocks{k}.text);
        return
    end
end
if ~isempty(html_path)
    [~, name] = fileparts(html_path);
    if ~isempty(name)
        title = name;
    end
end
end

function markdown = blocks_to_md(blocks)
parts = {};
for k = 1:numel(blocks)
    block = blocks{k};
    switch block.kind
        case 'h'
            parts{end + 1} = sprintf('%s %s', repmat('#', 1, block.level), block.text); %#ok<AGROW>
        case 'md'
            parts{end + 1} = strip_edge_newlines(block.text); %#ok<AGROW>
        case 'code'
            parts{end + 1} = fence(block.text, 'matlab'); %#ok<AGROW>
        case {'out', 'err'}
            parts{end + 1} = fence(block.text, 'text'); %#ok<AGROW>
        case 'warn'
            parts{end + 1} = ['> ' block.text]; %#ok<AGROW>
        case 'html'
            parts{end + 1} = block.text; %#ok<AGROW>
    end
end
kept = {};
for k = 1:numel(parts)
    if ~isempty(strtrim(parts{k}))
        kept{end + 1} = parts{k}; %#ok<AGROW>
    end
end
if isempty(kept)
    markdown = newline;
else
    markdown = [strjoin(kept, [newline newline]) newline];
end
end

function body = blocks_to_html(blocks)
parts = {};
for k = 1:numel(blocks)
    block = blocks{k};
    switch block.kind
        case 'h'
            parts{end + 1} = sprintf('<h%d>%s</h%d>', block.level, inline_format(block.text), block.level); %#ok<AGROW>
        case 'md'
            parts{end + 1} = md_to_html(block.text); %#ok<AGROW>
        case 'code'
            parts{end + 1} = sprintf('<pre><code class="language-matlab">%s</code></pre>', html_escape(block.text)); %#ok<AGROW>
        case 'out'
            parts{end + 1} = sprintf('<pre class="pytohtml-output"><code>%s</code></pre>', html_escape(block.text)); %#ok<AGROW>
        case 'err'
            parts{end + 1} = sprintf('<pre class="pytohtml-error"><code>%s</code></pre>', html_escape(block.text)); %#ok<AGROW>
        case 'warn'
            parts{end + 1} = sprintf('<p class="pytohtml-warn">%s</p>', html_escape(block.text)); %#ok<AGROW>
        case 'html'
            parts{end + 1} = block.text; %#ok<AGROW>
    end
end
kept = {};
for k = 1:numel(parts)
    if ~isempty(parts{k})
        kept{end + 1} = parts{k}; %#ok<AGROW>
    end
end
body = strjoin(kept, newline);
end

function html = md_to_html(text)
lines = split_lines(text);
parts = {};
index = 1;
while index <= numel(lines)
    line = lines{index};
    if numel(line) >= 3 && strcmp(line(1:3), '```')
        lang = strtrim(line(4:end));
        index = index + 1;
        buf = {};
        while index <= numel(lines) && ~(numel(lines{index}) >= 3 && strcmp(lines{index}(1:3), '```'))
            buf{end + 1} = lines{index}; %#ok<AGROW>
            index = index + 1;
        end
        if index <= numel(lines)
            index = index + 1;
        end
        klass = '';
        if ~isempty(lang)
            klass = sprintf(' class="language-%s"', html_escape(lang));
        end
        parts{end + 1} = sprintf('<pre><code%s>%s</code></pre>', klass, html_escape(strjoin(buf, newline))); %#ok<AGROW>
        continue
    end
    stripped = strtrim(line);
    if strcmp(stripped, '$$')
        index = index + 1;
        buf = {};
        while index <= numel(lines) && ~strcmp(strtrim(lines{index}), '$$')
            buf{end + 1} = lines{index}; %#ok<AGROW>
            index = index + 1;
        end
        if index <= numel(lines)
            index = index + 1;
        end
        math = ['$$' newline strjoin(buf, newline) newline '$$'];
        parts{end + 1} = sprintf('<div class="pytohtml-math">%s</div>', html_escape(math)); %#ok<AGROW>
        continue
    end
    if numel(stripped) > 4 && strcmp(stripped(1:2), '$$') && strcmp(stripped(end - 1:end), '$$')
        parts{end + 1} = sprintf('<div class="pytohtml-math">%s</div>', html_escape(stripped)); %#ok<AGROW>
        index = index + 1;
        continue
    end
    if isempty(stripped)
        index = index + 1;
        continue
    end
    if ~isempty(regexp(line, '^\s*(?:[-*]|\d+\.)\s+', 'once'))
        ordered = ~isempty(regexp(line, '^\s*\d+\.\s+', 'once'));
        items = {};
        while index <= numel(lines) && ~isempty(regexp(lines{index}, '^\s*(?:[-*]|\d+\.)\s+', 'once'))
            item = regexprep(lines{index}, '^\s*(?:[-*]|\d+\.)\s+', '');
            items{end + 1} = sprintf('<li>%s</li>', inline_format(item)); %#ok<AGROW>
            index = index + 1;
        end
        if ordered
            tag = 'ol';
        else
            tag = 'ul';
        end
        parts{end + 1} = sprintf('<%s>%s</%s>', tag, strjoin(items, ''), tag); %#ok<AGROW>
        continue
    end
    heading = regexp(line, '^(#{1,6})\s+(.*)$', 'tokens', 'once');
    if ~isempty(heading)
        parts{end + 1} = sprintf('<h%d>%s</h%d>', numel(heading{1}), inline_format(heading{2}), numel(heading{1})); %#ok<AGROW>
        index = index + 1;
        continue
    end
    if ~isempty(stripped) && stripped(1) == '<'
        buf = {line};
        index = index + 1;
        while index <= numel(lines) && ~isempty(strtrim(lines{index}))
            nxt = strtrim(lines{index});
            if isempty(nxt) || nxt(1) ~= '<'
                break
            end
            buf{end + 1} = lines{index}; %#ok<AGROW>
            index = index + 1;
        end
        parts{end + 1} = strjoin(buf, newline); %#ok<AGROW>
        continue
    end
    buf = {line};
    index = index + 1;
    while index <= numel(lines) && ~isempty(strtrim(lines{index}))
        nxt = lines{index};
        if numel(nxt) >= 3 && strcmp(nxt(1:3), '```')
            break
        end
        if strcmp(strtrim(nxt), '$$') || ~isempty(regexp(nxt, '^#{1,6}\s+', 'once'))
            break
        end
        if ~isempty(regexp(nxt, '^\s*(?:[-*]|\d+\.)\s+', 'once'))
            break
        end
        buf{end + 1} = nxt; %#ok<AGROW>
        index = index + 1;
    end
    parts{end + 1} = sprintf('<p>%s</p>', inline_format(join_paragraph(buf))); %#ok<AGROW>
end
html = strjoin(parts, newline);
end

function text = join_paragraph(lines)
text = strtrim(lines{1});
for k = 2:numel(lines)
    nxt = strtrim(lines{k});
    if ~isempty(text) && ~isempty(nxt) && double(text(end)) > 127 && double(nxt(1)) > 127
        text = [text nxt]; %#ok<AGROW>
    else
        text = [text ' ' nxt]; %#ok<AGROW>
    end
end
end

function text = inline_format(text)
[text, slots] = protect_spans(text);
text = html_escape(text);
text = regexprep(text, '\*\*([^*]+)\*\*', '<strong>$1</strong>');
text = regexprep(text, '\*([^*<\n]+)\*', '<em>$1</em>');
text = regexprep(text, '\[([^\]\n]+)\]\(([^)\s]+)\)', '<a href="$2">$1</a>');
text = restore_spans(text, slots);
end

function [text, slots] = protect_spans(text)
slots = {};
out = '';
index = 1;
total = numel(text);
while index <= total
    if text(index) == '`'
        stop = index + 1;
        while stop <= total && text(stop) ~= '`' && text(stop) ~= newline
            stop = stop + 1;
        end
        if stop <= total && text(stop) == '`'
            slots{end + 1} = text(index:stop); %#ok<AGROW>
            out = [out char(1) sprintf('%d', numel(slots)) char(2)]; %#ok<AGROW>
            index = stop + 1;
            continue
        end
    end
    if text(index) == '$'
        if index < total && text(index + 1) == '$'
            stop = index + 2;
            found = false;
            while stop < total
                if text(stop) == '$' && text(stop + 1) == '$'
                    found = true;
                    break
                end
                stop = stop + 1;
            end
            if found
                slots{end + 1} = text(index:stop + 1); %#ok<AGROW>
                out = [out char(1) sprintf('%d', numel(slots)) char(2)]; %#ok<AGROW>
                index = stop + 2;
                continue
            end
        else
            stop = index + 1;
            while stop <= total && text(stop) ~= '$' && text(stop) ~= newline
                stop = stop + 1;
            end
            if stop <= total && text(stop) == '$'
                slots{end + 1} = text(index:stop); %#ok<AGROW>
                out = [out char(1) sprintf('%d', numel(slots)) char(2)]; %#ok<AGROW>
                index = stop + 1;
                continue
            end
        end
    end
    out = [out text(index)]; %#ok<AGROW>
    index = index + 1;
end
text = out;
end

function text = restore_spans(text, slots)
out = '';
index = 1;
total = numel(text);
while index <= total
    if text(index) == char(1)
        stop = index + 1;
        while stop <= total && text(stop) >= '0' && text(stop) <= '9'
            stop = stop + 1;
        end
        if stop <= total && text(stop) == char(2)
            slot = str2double(text(index + 1:stop - 1));
            raw = slots{slot};
            if numel(raw) >= 2 && raw(1) == '`' && raw(end) == '`'
                out = [out '<code>' html_escape(raw(2:end - 1)) '</code>']; %#ok<AGROW>
            else
                out = [out html_escape(raw)]; %#ok<AGROW>
            end
            index = stop + 1;
            continue
        end
    end
    out = [out text(index)]; %#ok<AGROW>
    index = index + 1;
end
text = out;
end

function text = substitute_displays(text, shows)
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
    [ok, value] = lookup_show(shows, expr);
    if ok
        parts{end + 1} = value; %#ok<AGROW>
    else
        parts{end + 1} = text(start:close_at); %#ok<AGROW>
    end
    cursor = close_at + 1;
end
text = strjoin(parts, '');
end

function [ok, value] = lookup_show(shows, name)
ok = false;
value = '';
for k = 1:size(shows, 1)
    if strcmp(shows{k, 1}, name)
        ok = true;
        value = shows{k, 2};
        return
    end
end
end

function pos = closing_brace(text, open_at)
depth = 0;
pos = [];
for index = open_at:numel(text)
    if text(index) == '{'
        depth = depth + 1;
    elseif text(index) == '}'
        depth = depth - 1;
        if depth == 0
            pos = index;
            return
        end
    end
end
end

function html = figure_html(rec, base_dirs, embed, html_path)
original = field_text(rec, 'src');
found = find_file(original, base_dirs);
missing = '';
if isempty(found)
    src = original;
    missing = sprintf('<p class="pytohtml-warn">找不到图：%s</p>', html_escape(original));
elseif logical(embed)
    bytes = read_bytes(found);
    src = ['data:' mime_of(found) ';base64,' base64_encode(bytes)];
else
    src = relative_src(found, html_path, original);
end
attrs = {sprintf('src="%s"', html_escape(src, true))};
width = field_text(rec, 'width');
height = field_text(rec, 'height');
zoom = field_text(rec, 'zoom');
if ~isempty(width)
    attrs{end + 1} = sprintf('width="%s"', html_escape(width, true)); %#ok<AGROW>
end
if ~isempty(height)
    attrs{end + 1} = sprintf('height="%s"', html_escape(height, true)); %#ok<AGROW>
end
if isempty(width) && isempty(height)
    if isempty(zoom)
        zoom_text = '100%';
    else
        zoom_text = zoom_css(zoom);
    end
    attrs{end + 1} = sprintf('style="zoom:%s"', html_escape(zoom_text, true)); %#ok<AGROW>
end
title = field_text(rec, 'title');
caption = '';
if ~isempty(title)
    caption = sprintf('<figcaption class="tohtml-fig-title">%s</figcaption>', html_escape(title));
end
html = sprintf('<figure class="tohtml-figure"><img %s>%s%s</figure>', strjoin(attrs, ' '), caption, missing);
end

function html = table_html(rec, base_dirs)
original = field_text(rec, 'src');
found = find_file(original, base_dirs);
title = field_text(rec, 'title');
caption = '';
if ~isempty(title)
    caption = sprintf('<figcaption class="tohtml-table-title">%s</figcaption>', html_escape(title));
end
if isempty(found)
    html = sprintf('<figure class="tohtml-table-block">%s<p class="pytohtml-warn">找不到表：%s</p></figure>', ...
        caption, html_escape(original));
    return
end
raw = read_text(found);
[~, ~, ext] = fileparts(found);
if strcmpi(ext, '.md')
    inner = md_to_html(raw);
    notes = '';
else
    if isempty(regexp(raw, '<html\b|<body\b', 'once', 'ignorecase'))
        fragment = strtrim(raw);
    else
        fragment = extract_document(raw);
    end
    css_bits = {};
    cssfile = field_text(rec, 'cssfile');
    css_path = '';
    if ~isempty(cssfile)
        css_path = find_file(cssfile, base_dirs);
    end
    if isempty(css_path)
        sibling = with_ext(found, '.css');
        if exist(sibling, 'file') == 2
            css_path = sibling;
        end
    end
    if ~isempty(css_path) && isempty(strfind(lower(fragment), '<style'))
        css_bits{end + 1} = sprintf('<style>\n%s\n</style>', read_text(css_path)); %#ok<AGROW>
    end
    notes = strjoin(regexp(fragment, '<p[^>]*pytohtml-note[^>]*>.*?</p>', 'match', 'ignorecase'), newline);
    body = regexprep(fragment, '<p[^>]*pytohtml-note[^>]*>.*?</p>', '', 'ignorecase');
    inner = strjoin([css_bits, {strtrim(body)}], newline);
end
html = sprintf('<figure class="tohtml-table-block">%s<div class="tohtml-embedded-table">%s</div>%s</figure>', ...
    caption, inner, notes);
end

function fragment = extract_document(raw)
styles = regexp(raw, '<style\b[^>]*>.*?</style>', 'match', 'ignorecase');
tables = regexp(raw, '<table\b[^>]*>.*?</table>', 'match', 'ignorecase');
notes = regexp(raw, '<p[^>]*pytohtml-note[^>]*>.*?</p>', 'match', 'ignorecase');
if ~isempty(tables)
    fragment = strjoin([styles, tables, notes], newline);
else
    fragment = raw;
end
end

function found = find_file(src, base_dirs)
found = '';
if isempty(src)
    return
end
src_fs = strrep(strrep(src, '/', filesep), '\', filesep);
if exist(src_fs, 'file') == 2
    found = absolutepath(src_fs);
    return
end
for k = 1:numel(base_dirs)
    candidate = fullfile(base_dirs{k}, src_fs);
    if exist(candidate, 'file') == 2
        found = absolutepath(candidate);
        return
    end
end
end

function rel = relative_src(found, html_path, original)
if isempty(html_path)
    rel = strrep(original, '\', '/');
    return
end
base = fileparts(absolutepath(html_path));
rel = rel_path(found, base);
end

function text = zoom_css(value)
text = strtrim(as_char(value));
if isempty(text)
    text = '100%';
    return
end
if text(end) ~= '%'
    text = [text '%'];
end
end

function mime = mime_of(path)
[~, ~, ext] = fileparts(path);
switch lower(ext)
    case '.png'
        mime = 'image/png';
    case '.jpg'
        mime = 'image/jpeg';
    case '.jpeg'
        mime = 'image/jpeg';
    case '.gif'
        mime = 'image/gif';
    case '.svg'
        mime = 'image/svg+xml';
    case '.webp'
        mime = 'image/webp';
    case '.bmp'
        mime = 'image/bmp';
    otherwise
        mime = 'application/octet-stream';
end
end

function bytes = read_bytes(path)
fid = fopen(path, 'rb');
if fid < 0
    error('matlab_tohtml:IO', '无法读取 %s', path);
end
cleaner = onCleanup(@() fclose(fid));
bytes = fread(fid, Inf, '*uint8');
end

function encoded = base64_encode(bytes)
chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
bytes = uint8(bytes(:));
n = numel(bytes);
remnant = mod(n, 3);
if remnant ~= 0
    bytes = [bytes; zeros(3 - remnant, 1, 'uint8')];
end
triples = reshape(bytes, 3, []).';
values = int32(triples(:, 1)) * 65536 + int32(triples(:, 2)) * 256 + int32(triples(:, 3));
idx = zeros(size(triples, 1), 4);
idx(:, 1) = bitshift(values, -18) + 1;
idx(:, 2) = bitand(bitshift(values, -12), 63) + 1;
idx(:, 3) = bitand(bitshift(values, -6), 63) + 1;
idx(:, 4) = bitand(values, 63) + 1;
encoded = chars(idx.');
encoded = encoded(:).';
if remnant == 1
    encoded(end - 1:end) = '==';
elseif remnant == 2
    encoded(end) = '=';
end
end

function tf = mathjax_on(opt, markdown)
if islogical(opt.mathjax)
    tf = opt.mathjax;
    return
end
if isnumeric(opt.mathjax) && ~isempty(opt.mathjax)
    tf = logical(opt.mathjax);
    return
end
if ischar(opt.mathjax) && ~isempty(opt.mathjax)
    tf = ~any(strcmpi(opt.mathjax, {'0', 'false', 'off', 'no'}));
    return
end
tf = wants_math(markdown);
end

function tf = wants_math(markdown)
if ~isempty(strfind(markdown, '$$')) || ~isempty(strfind(markdown, '\(')) || ~isempty(strfind(markdown, '\['))
    tf = true;
    return
end
tf = ~isempty(regexp(markdown, '\$[^$\n]+\$', 'once'));
end

function html = document_html(title, body, use_math, highlight, tabwidth, tabheight)
css = package_css();
extras = {scroll_css(tabwidth, tabheight)};
if use_math
    extras{end + 1} = ['<script>' newline ...
        'MathJax = { tex: { inlineMath: [[''$'', ''$''], [''\\('', ''\\)'']], displayMath: [[''$$'', ''$$''], [''\\['', ''\\]'']] } };' newline ...
        '</script>' newline ...
        '<script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>']; %#ok<AGROW>
end
if highlight
    extras{end + 1} = ['<link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.11.1/build/styles/github.min.css">' newline ...
        '<script src="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.11.1/build/highlight.min.js"></script>' newline ...
        '<script>hljs.highlightAll();</script>']; %#ok<AGROW>
end
html = ['<!DOCTYPE html>' newline ...
    '<html lang="zh-CN">' newline ...
    '<head>' newline ...
    '<meta charset="utf-8">' newline ...
    '<meta name="viewport" content="width=device-width, initial-scale=1">' newline ...
    '<title>' html_escape(title) '</title>' newline ...
    '<style id="tohtml-inline-css">' newline css newline '</style>' newline ...
    strjoin(extras, newline) newline ...
    '</head>' newline ...
    '<body>' newline ...
    body newline ...
    '</body>' newline ...
    '</html>' newline];
end

function css = package_css()
private_dir = fileparts(mfilename('fullpath'));
css = read_text(fullfile(fileparts(private_dir), 'tohtml.css'));
end

function css = scroll_css(tabwidth, tabheight)
rules = {'overflow:auto;', '-webkit-overflow-scrolling:touch;'};
width = css_size(tabwidth);
height = css_size(tabheight);
if ~isempty(width)
    rules{end + 1} = ['max-width:' width ';']; %#ok<AGROW>
end
if ~isempty(height)
    rules{end + 1} = ['max-height:' height ';']; %#ok<AGROW>
end
css = ['<style id="tohtml-table-scroll">.tohtml-embedded-table{' strjoin(rules, '') '}</style>'];
end

function text = css_size(value)
text = '';
if isempty(value)
    return
end
raw = strtrim(as_char(value));
if any(strcmpi(raw, {'', 'none', 'off', '.'}))
    return
end
if ~isempty(regexp(raw, '^\d+(\.\d+)?$', 'once'))
    text = [raw 'px'];
else
    text = raw;
end
end

function text = fence(source, lang)
tick = '```';
while ~isempty(strfind(source, tick))
    tick = [tick '`']; %#ok<AGROW>
end
text = [tick lang newline source newline tick];
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

function values = unique_keep(values)
if isempty(values)
    values = {};
    return
end
kept = {};
for k = 1:numel(values)
    item = as_char(values{k});
    if isempty(item) || any(strcmp(kept, item))
        continue
    end
    kept{end + 1} = item; %#ok<AGROW>
end
values = kept;
end

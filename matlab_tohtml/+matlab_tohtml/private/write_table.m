function write_table(path, header, rows, numeric_from, row_class, suffix)
%WRITE_TABLE  HTML table fragment. numeric_from is the first numeric column.
if nargin < 4 || isempty(numeric_from)
    numeric_from = 2;
end
if nargin < 5
    row_class = {};
end
if nargin < 6
    suffix = '';
end
parts = {'<table class="pytohtml-table"><thead><tr>'};
for index = 1:numel(header)
    cls = '';
    if index >= numeric_from
        cls = ' class="num"';
    end
    parts{end + 1} = sprintf('<th%s>%s</th>', cls, html_escape(header{index})); %#ok<AGROW>
end
parts{end + 1} = '</tr></thead><tbody>'; %#ok<AGROW>
for rindex = 1:numel(rows)
    kind = '';
    if numel(row_class) >= rindex
        kind = row_class{rindex};
    end
    if isempty(kind)
        parts{end + 1} = '<tr>'; %#ok<AGROW>
    else
        parts{end + 1} = sprintf('<tr class="%s">', kind); %#ok<AGROW>
    end
    row = rows{rindex};
    for index = 1:numel(row)
        cls = '';
        if index >= numeric_from
            cls = ' class="num"';
        end
        parts{end + 1} = sprintf('<td%s>%s</td>', cls, html_escape(row{index})); %#ok<AGROW>
    end
    parts{end + 1} = '</tr>'; %#ok<AGROW>
end
parts{end + 1} = '</tbody></table>'; %#ok<AGROW>
parts{end + 1} = suffix; %#ok<AGROW>
write_text(path, strjoin(parts, ''));
end

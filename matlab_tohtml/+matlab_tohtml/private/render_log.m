function render_log(log_path, html_path, md_path, opt)
%RENDER_LOG  Turn a transcript into Markdown and HTML.
log_path = absolutepath(log_path);
text = read_text(log_path);
records = parse_transcript(text);
bases = {};
for k = 1:numel(records)
    rec = records{k};
    if ~strcmp(rec.kind, 'meta')
        continue
    end
    if isfield(rec, 'cwd') && ~isempty(rec.cwd)
        bases{end + 1} = as_char(rec.cwd); %#ok<AGROW>
    end
    if isfield(rec, 'script') && ~isempty(rec.script)
        bases{end + 1} = fileparts(as_char(rec.script)); %#ok<AGROW>
    end
end
bases{end + 1} = fileparts(log_path); %#ok<AGROW>
if ~isempty(html_path)
    bases{end + 1} = fileparts(absolutepath(html_path)); %#ok<AGROW>
end
render_records(records, html_path, md_path, bases, opt);
end

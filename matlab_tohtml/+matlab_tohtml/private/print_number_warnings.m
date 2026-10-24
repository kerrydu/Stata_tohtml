function print_number_warnings(log_path)
%PRINT_NUMBER_WARNINGS  Stderr note when prose contains a typed-in number.
records = parse_transcript(read_text(log_path));
for k = 1:numel(records)
    rec = records{k};
    if ~strcmp(rec.kind, 'md') || ~isfield(rec, 'hardcoded')
        continue
    end
    numbers = as_cellstr(rec.hardcoded);
    if isempty(numbers)
        continue
    end
    loc = '';
    if isfield(rec, 'file') && ~isempty(rec.file)
        line_no = '';
        if isfield(rec, 'line') && ~isempty(rec.line)
            line_no = sprintf('%.0f', rec.line);
        end
        loc = sprintf('%s:%s: ', as_char(rec.file), line_no);
    end
    fprintf(2, 'matlab_tohtml: %s叙述里有手写数字 %s\n', loc, strjoin(numbers, '、'));
end
end

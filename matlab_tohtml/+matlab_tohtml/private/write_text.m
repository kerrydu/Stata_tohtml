function write_text(path, text)
%WRITE_TEXT  Write UTF-8 text, creating parent directories.
text = as_char(text);
parent = fileparts(path);
if ~isempty(parent)
    ensure_dir(parent);
end
fid = fopen(path, 'wb');
if fid < 0
    error('matlab_tohtml:IO', '无法写入 %s', path);
end
cleaner = onCleanup(@() fclose(fid));
if is_octave()
    fwrite(fid, uint8(text));
else
    fwrite(fid, unicode2native(text, 'UTF-8'));
end
end

function text = read_text(path)
%READ_TEXT  Read a file as UTF-8 text.
fid = fopen(path, 'rb');
if fid < 0
    error('matlab_tohtml:IO', '无法读取 %s', path);
end
cleaner = onCleanup(@() fclose(fid));
bytes = fread(fid, Inf, '*uint8');
bytes = bytes(:).';
if numel(bytes) >= 3 && bytes(1) == 239 && bytes(2) == 187 && bytes(3) == 191
    bytes = bytes(4:end);
end
if is_octave()
    text = char(bytes);
else
    text = native2unicode(bytes, 'UTF-8');
end
if ~isempty(text) && double(text(1)) == 65279
    text = text(2:end);
end
end

function ensure_dir(path)
%ENSURE_DIR  Create a directory and its parents.
if isempty(path) || exist(path, 'dir') == 7
    return
end
parent = fileparts(path);
if ~isempty(parent) && ~strcmp(parent, path)
    ensure_dir(parent);
end
if exist(path, 'dir') == 7
    return
end
[ok, message] = mkdir(path);
if ~ok && exist(path, 'dir') ~= 7
    error('matlab_tohtml:IO', '无法创建目录 %s：%s', path, message);
end
end

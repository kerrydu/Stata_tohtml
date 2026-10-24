function path = absolutepath(path)
%ABSOLUTEPATH  Absolute path. Missing files keep a canonical parent.
path = char(path);
path = strrep(path, '/', filesep);
path = strrep(path, '\', filesep);
if ~is_absolute_path(path)
    path = fullfile(pwd, path);
end
canonical = canonical_path(path);
if ~isempty(canonical)
    path = canonical;
    return
end
[parent, name, ext] = fileparts(path);
canonical = canonical_path(parent);
if ~isempty(canonical)
    path = fullfile(canonical, [name ext]);
end
end

function found = canonical_path(path)
found = '';
if nargin < 1 || isempty(path)
    return
end
if exist('canonicalize_file_name', 'builtin') || exist('canonicalize_file_name', 'file')
    found = canonicalize_file_name(path);
    if ~isempty(found)
        return
    end
    found = '';
end
if exist('usejava', 'builtin') || exist('usejava', 'file')
    try
        if usejava('jvm')
            found = char(java.io.File(path).getCanonicalPath());
        end
    catch
        found = '';
    end
end
end

function tf = is_absolute_path(path)
tf = false;
if isempty(path)
    return
end
if path(1) == '/' || path(1) == '\'
    tf = true;
    return
end
if numel(path) >= 3 && path(2) == ':' && isletter(path(1))
    tf = true;
end
end

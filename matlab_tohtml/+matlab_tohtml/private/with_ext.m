function path = with_ext(path, ext)
%WITH_EXT  Replace the extension, including the dot in ext.
[folder, name] = fileparts(path);
path = fullfile(folder, [name ext]);
end

function tf = is_octave()
%IS_OCTAVE  True when this file is running under Octave.
tf = exist('OCTAVE_VERSION', 'builtin') > 0;
end

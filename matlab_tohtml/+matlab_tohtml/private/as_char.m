function text = as_char(value)
%AS_CHAR  Char row. String scalars become char; other values pass through.
if ischar(value)
    text = value;
    return
end
if (exist('isstring', 'builtin') || exist('isstring', 'file')) && isstring(value)
    text = char(value);
    return
end
text = value;
end

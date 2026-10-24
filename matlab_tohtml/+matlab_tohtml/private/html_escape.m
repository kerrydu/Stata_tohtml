function text = html_escape(text, quote)
%HTML_ESCAPE  Escape &, <, > and, when requested, quotes.
if nargin < 2
    quote = false;
end
text = as_char(text);
text = strrep(text, '&', '&amp;');
text = strrep(text, '<', '&lt;');
text = strrep(text, '>', '&gt;');
if quote
    text = strrep(text, '"', '&quot;');
end
end

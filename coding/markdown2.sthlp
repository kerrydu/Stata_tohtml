{smcl}
{* *! version 1.0.1  16jan2026}{...}
{vieweralsosee "graph2md" "help graph2md"}{...}
{vieweralsosee "outreg3" "help outreg3"}{...}
{vieweralsosee "_textcell" "help _textcell"}{...}
{vieweralsosee "ishere" "help ishere"}{...}
{viewerjumpto "Syntax" "markdown2##syntax"}{...}
{viewerjumpto "Description" "markdown2##description"}{...}
{viewerjumpto "Options" "markdown2##options"}{...}
{viewerjumpto "Examples" "markdown2##examples"}{...}
{title:Title}

{phang}
{bf:markdown2} {hline 2} Convert Stata log files to Markdown and HTML

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:markdown2} {it:filename} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt sav:ing(filename)}}Specify output Markdown filename. If not specified, defaults to input name with suffixes.{p_end}
{synopt:{opt rep:lace}}Overwrite existing output files.{p_end}
{synopt:{opt html(filename)}}Generate an HTML file from the resulting Markdown.{p_end}
{synopt:{opt css(filename|style)}}Specify CSS file for HTML. Special value {bf:githubstyle} uses a built-in style.{p_end}
{synopt:{opt rp:ath(path)}}Local root path for resources (images) found in the log.{p_end}
{synopt:{opt wp:ath(url)}}Web/Relative path to replace {it:rpath} with in the final output.{p_end}
{synopt:{opt clean}}Run in cleaning mode (legacy).{p_end}
{synopt:{opt cleancode(filename)}}Run in code cleanup mode using a reference do-file.{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:markdown2} is the core engine of the Stata_log2html package. It processes a Stata log file (which must be in text format)
and converts it into a clean Markdown document.

{pstd}
It automatically handles:
{break}- Stata code blocks
{break}- Stata output
{break}- Special {help _textcell:_textcell} blocks for narrative text and LaTeX math
{break}- Special {help ishere:ishere} markers for headers, figures and tables

{pstd}
If the {cmd:html()} option is specified, it further compiles the Markdown into HTML.
Using {cmd:css(githubstyle)} is recommended as it includes styling for tables, code, and MathJax support for LaTeX equations.

{marker options}{...}
{title:Options}

{phang}
{opt saving(filename)} specifies the name of the destination Markdown file.
If not specified, {cmd:markdown2} attempts to create a sensible default based on the input filename.

{phang}
{opt replace} permits {cmd:markdown2} to overwrite existing files.

{phang}
{opt html(filename)} specifies the name of the HTML file to be generated.
This requires `markdown` command (or Stata 15+ markdown capabilities) to be available/functioning, although `markdown2` handles the preprocessing.

{phang}
{opt css(filename)} specifies a CSS stylesheet to include in the HTML.
If {bf:css(githubstyle)} is used, the command generates a `github.css` in a `./css/` subfolder and links it.
It also injects MathJax scripts for rendering LaTeX equations (e.g., `$$ y = x^2 $$`).

{phang}
{opt rpath(path)} and {opt wpath(url)} are used for path rewriting, typically for images.
If your log contains local absolute paths (e.g., `C:/Project/fig.png`), you can use these options to rewrite them to relative web paths (e.g., `./images/fig.png`) for proper rendering in the HTML.

{marker remarks}{...}
{title:Remarks}

{pstd}
To ensure figures and tables are rendered correctly (and not displayed as raw code),
commands like {help graph2md} and {help outreg3} should be followed by {cmd:ishere out}.
This explicitly closes the code block relative to the Markdown parser.

{marker examples}{...}

{title:Examples}

{pstd}
Basic conversion to Markdown:

{phang2}{cmd:. markdown2 "mylog.log", saving("output.md") replace}{p_end}

{pstd}
Conversion to Markdown and HTML with GitHub styling and MathJax:

{phang2}{cmd:. markdown2 "mylog.log", replace html("output.html") css(githubstyle)}{p_end}

{pstd}
Using path rewriting for images:

{phang2}{cmd:. markdown2 "mylog.log", replace html("output.html") css(githubstyle) rpath("$results") }{p_end}

{title:Author}

{pstd}
Kerry Du
{break}
kerrydu@example.com
{p_end}

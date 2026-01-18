{smcl}
{* *! version 1.0.1  16jan2026}{...}
{vieweralsosee "logout" "help logout"}{...}
{vieweralsosee "outreg3" "help outreg3"}{...}
{vieweralsosee "markdown2" "help markdown2"}{...}
{vieweralsosee "ishere" "help ishere"}{...}
{viewerjumpto "Syntax" "logout3##syntax"}{...}
{viewerjumpto "Description" "logout3##description"}{...}
{viewerjumpto "Options" "logout3##options"}{...}
{viewerjumpto "Examples" "logout3##examples"}{...}
{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{bf:logout3} {hline 2}}Automated table conversion to HTML and LaTeX{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 4 10 6}
{cmdab:logout3}, [{it:options} : {it:command}]

{marker options}{...}
{title:Options}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt :{opt save(filename)}}name of output file (without extension){p_end}
{synopt :{opt replace}}overwrite existing file{p_end}
{synopt :{opt html}}output in HTML format{p_end}
{synopt :{opt tex}}output in LaTeX format{p_end}
{synopt :{opt excel}}output in Excel (XML) format{p_end}
{synopt :{opt word}}output in Word (RTF) format{p_end}
{synopt :{opt dec(#)}}force distinct decimal places{p_end}
{synopt :{opt fix(#)}}adjust parsing sensitivity (default 5){p_end}
{synopt :{opt clear}}replace data in memory with captured table{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:logout3} is an enhanced version of {cmd:logout}, designed to capture output from Stata commands (like {cmd:tabstat}, {cmd:tabulate}, {cmd:summarize}) and convert it directly into formatting-rich HTML or LaTeX code.

{pstd}
It is particularly useful for generating descriptive statistics tables or simple frequency lists that need to be embedded in web reports or LaTeX documents. Unlike the original {cmd:logout}, {cmd:logout3} is optimized for the {help markdown2} workflow, producing cleaner HTML tables with proper class attributes for styling.

{pstd}
The HTML output from {cmd:logout3} is compatible with {help ishere} for embedding in markdown documents. After generating a table with {cmd:logout3}, use {cmd:ishere tab using "filename.html"} to embed the table in your markdown report.


{marker options_details}{...}
{title:Detailed Options}

{phang}
{opt save(filename)} specifies the name of the output file. Extensions like .html or .tex are automatically appended based on the chosen format options.

{phang}
{opt replace} permits overwriting existing files.

{phang}
{opt html} generates a standard HTML table. This is ideal for inclusion in Markdown reports or websites.

{phang}
{opt tex} generates a LaTeX tabular environment.

{phang}
{opt fix(#)} specifies the sensitivity for the parser when converting plain text output to columns. Lower numbers (e.g., 1) are stricter, while higher numbers are looser. The default usually works well for standard Stata output.


{marker examples}{...}
{title:Examples}

{pstd}
{bf:1. Basic Descriptive Statistics to HTML}

{pstd}
Calculate summary statistics for auto data and save as HTML table:

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. logout3, save("mytable") replace html : tabstat price mpg weight, s(mean sd min max)}{p_end}

{pstd}
{bf:2. Frequency Table to LaTeX}

{pstd}
Export a frequency tabulation of foreign cars to LaTeX:

{phang2}{cmd:. logout3, save("freq_table") replace tex : tabulate foreign}{p_end}

{pstd}
{bf:3. Workflow Integration}

{pstd}
Using {cmd:logout3} as part of a Markdown report generation:

{phang2}{cmd:. log using report.md, replace text}{p_end}
{phang2}{cmd:. logout3, save("descriptives") replace html : tabstat price mpg, s(n mean)}{p_end}
{phang2}{cmd:. ishere tab using "descriptives.html"}{p_end}
{phang2}{cmd:. markdown2 report.md, saving(final_report.md) html(final_report.html)}{p_end}


{title:Author}

{pstd}
Updated for modern workflows. Original concept by local and Roy Wada.

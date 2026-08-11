{smcl}
{* *! version 1.6.0  11aug2026}{...}
{vieweralsosee "tohtml" "help tohtml"}{...}
{vieweralsosee "markdown" "help markdown"}{...}
{viewerjumpto "Syntax" "ishere##syntax"}{...}
{viewerjumpto "Description" "ishere##description"}{...}
{viewerjumpto "Options" "ishere##options"}{...}
{viewerjumpto "Examples" "ishere##examples"}{...}
{title:Title}

{p2colset 5 16 18 2}{...}
{p2col:{cmd:ishere} {hline 2}}Insert markers in log files for report generation{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
{bf:Mode 1: Placeholder (code block or heading)}

{p 8 16 2}
{cmd:ishere}

{p 8 16 2}
{cmd:ishere} {it:# heading text}


{pstd}
{bf:Mode 2: Emit values and figure/table markup}

{pstd}
Emit a value for Markdown tag replacement (same arguments as {help display})

{p 8 16 2}
{cmd:ishere} {cmd:display} {it:display_arguments}


{pstd}
Insert figure

{p 8 16 2}
{cmd:ishere} {cmd:fig}|{cmd:figure} {cmd:using} {it:filename}
[{cmd:,} {opt zoom(string)} {opt height(string)} {opt width(string)}]


{pstd}
Insert table

{p 8 16 2}
{cmd:ishere} {cmd:tab}|{cmd:table} {cmd:using} {it:filename}
[{cmd:,} {opt height(string)} {opt width(string)}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:ishere} works with {help tohtml} to mark structure, emit scalar/macro values for
narrative tags, and insert figures/tables in reports generated from Stata logs.

{pstd}
{bf:Mode 1: Placeholder mode}

{pmore}
Produces no visible output. Leaves markers in the log that {help tohtml} uses later.

{pmore2}
- Code block boundaries: {cmd:ishere}

{pmore2}
- Markdown headings: {cmd:ishere # Main Title} or {cmd:ishere ## Subtitle}

{pstd}
{bf:Mode 2: Emit mode}

{pmore}
Prints content to the log (kept / processed by {help tohtml}):

{pmore2}
- Values: {cmd:ishere display} {it:...} prints the same output as {help display}.
  Place a matching tag {cmd:{c -(}ishere display} {it:...}{cmd:{c )-}} inside a
  {cmd:/**} ... {cmd:**/} narrative block; {help tohtml} replaces that tag with the
  printed value in the first narrative block that follows the command.

{pmore2}
- Figures: {cmd:ishere fig using "figure1.png"} writes an HTML {cmd:<img>} tag

{pmore2}
- HTML tables: {cmd:ishere tab using "table1.html"} writes an HTML {cmd:<iframe>} tag

{pmore2}
- Markdown tables: {cmd:ishere tab using "table1.md"} writes a placeholder for inlining

{pmore}
Image formats: PNG, JPG, JPEG, SVG, GIF, BMP, WEBP.
Table formats: HTML/HTM, MD.


{marker options}{...}
{title:Options}

{pstd}
Options apply only to figure/table emit syntax.

{dlgtab:Figure options}

{phang}
{opt zoom(string)} zoom level for the image; default is 100% when neither
{opt height()} nor {opt width()} is specified (e.g., {cmd:80%} or {cmd:80}).

{phang}
{opt height(string)} image height (CSS units, e.g., {cmd:300px}).

{phang}
{opt width(string)} image width (CSS units).


{dlgtab:Table options}

{phang}
{opt height(string)} iframe height for HTML tables; default {cmd:400px}. Ignored for {cmd:.md}.

{phang}
{opt width(string)} iframe width for HTML tables; default {cmd:100%}. Ignored for {cmd:.md}.


{marker examples}{...}
{title:Examples}

{pstd}{bf:Mode 1: placeholders}{p_end}

{pstd}Code block boundaries{p_end}
{phang2}{cmd:. ishere}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. summarize}{p_end}
{phang2}{cmd:. ishere}{p_end}

{pstd}Headings{p_end}
{phang2}{cmd:. ishere # Data Analysis Report}{p_end}
{phang2}{cmd:. ishere ## Descriptive Statistics}{p_end}

{pstd}{bf:Mode 2: display values into narrative}{p_end}

{phang2}{cmd:. local r2 = e(r2)}{p_end}
{phang2}{cmd:. ishere display %5.3f `r2'}{p_end}
{phang2}{cmd:. /**}{p_end}
{phang2}{cmd:. The R-squared is {c -(}ishere display %5.3f `r2'{c )-}.}{p_end}
{phang2}{cmd:. **/}{p_end}

{pstd}{bf:Mode 2: figures and tables}{p_end}

{phang2}{cmd:. scatter price mpg}{p_end}
{phang2}{cmd:. graph export "figure1.png", replace}{p_end}
{phang2}{cmd:. ishere fig using "figure1.png"}{p_end}

{phang2}{cmd:. ishere fig using "figure1.png", zoom(80%)}{p_end}

{phang2}{cmd:. ishere figure using "figure1.png", height(400px) width(600px)}{p_end}

{phang2}{cmd:. ishere tab using "table1.html"}{p_end}

{phang2}{cmd:. ishere table using "table1.html", height(500px) width(100%)}{p_end}

{phang2}{cmd:. ishere tab using "table1.md"}{p_end}

{pstd}{bf:Minimal workflow}{p_end}
{phang2}{cmd:. log using "analysis.log", replace text}{p_end}
{phang2}{cmd:. ishere # Data Analysis Report}{p_end}
{phang2}{cmd:. ishere}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. summarize price mpg}{p_end}
{phang2}{cmd:. ishere}{p_end}
{phang2}{cmd:. scatter price mpg}{p_end}
{phang2}{cmd:. graph export "scatter.png", replace}{p_end}
{phang2}{cmd:. ishere fig using "scatter.png", zoom(80%)}{p_end}
{phang2}{cmd:. log close}{p_end}
{phang2}{cmd:. tohtml analysis.log, html(analysis.html) replace}{p_end}


{title:Remarks}

{pstd}
Mode 1 leaves silent markers in the log. Mode 2 prints values or markup that become
part of the report. For figures/tables, {cmd:using} {it:filename} is required.
{cmd:ishere /*} / {cmd:ishere */} are not supported; use {cmd:/**} ... {cmd:**/}
for narrative Markdown.

{pstd}
Each {cmd:ishere display} applies only to the first {cmd:/**} ... {cmd:**/} block
that appears after it in the log. To reuse a value in another block, issue another
{cmd:ishere display} before that block.

{pstd}
Backslashes in file paths are converted to forward slashes for cross-platform use.


{title:Author}

{pstd}
Kerry Du{break}
School of Management{break}
Xiamen University{break}
kerrydu@xmu.edu.cn

{pstd}
Huanyu Jia{break}
School of Business{break}
Zhengzhou University{break}
jiahuanyu@zzu.edu.cn

{title:See also}
{psee}

Help:  {help tohtml}, {help markdown}, {help log}

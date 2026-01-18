{smcl}
{* *! version 1.0.0  12jan2026}{...}
{vieweralsosee "markdown2" "help markdown2"}{...}
{viewerjumpto "Syntax" "statacell##syntax"}{...}
{viewerjumpto "Description" "statacell##description"}{...}
{viewerjumpto "Examples" "statacell##examples"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{bf:statacell} {hline 2}}Insert Markdown code block markers in log output{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:statacell} {it:argument}

{marker description}{...}
{title:Description}

{pstd}
{cmd:statacell} is a simple utility command used to inject Markdown code block delimiters into the Stata log file output. It is primarily used in conjunction with the {help markdown2} workflow to manually control how code blocks are structured in the generated Markdown/HTML report.

{pstd}
By effectively "opening" and "closing" code fences ({cmd:```}), it allows users to segment their code and output, or insert Markdown headers, directly from the do-file.

{pstd}
The command behaves differently based on the argument provided:

{p 8 8 2}- {cmd:0}: Outputs {cmd:``` stata} (Opens a Stata code block){p_end}
{p 8 8 2}- {cmd:1}: Outputs {cmd:```} (Closes a code block){p_end}
{p 8 8 2}- {cmd:empty}: Outputs {cmd:```} (Closes a code block){p_end}
{p 8 8 2}- {it:text with #}: Outputs the text as-is (Useful for Markdown headers){p_end}


{marker examples}{...}
{title:Examples}

{pstd}
{bf:1. Creating a code block}

{pstd}
Use {cmd:statacell} to explicitly define a block of code in the output log:

{phang2}{cmd:. statacell 0}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. summarize price}{p_end}
{phang2}{cmd:. statacell 1}{p_end}

{pstd}
In the final Markdown report, this section will be rendered as a syntax-highlighted Stata code block.

{pstd}
{bf:2. Inserting a Header}

{pstd}
Inject a Markdown header into the report:

{phang2}{cmd:. statacell "## Descriptive Analysis"}{p_end}

{pstd}
{bf:3. Workflow Context}

{pstd}
In a typical {cmd:markdown2} automated workflow:

{phang2}{cmd:. log using analysis.md, replace text}{p_end}
{phang2}{cmd:. statacell 0}{p_end}
{phang2}{cmd:. * Code analysis here...}{p_end}
{phang2}{cmd:. statacell 1}{p_end}
{phang2}{cmd:. markdown2 analysis.md, saving(report.md) html(report.html)}{p_end}


{title:Author}

{pstd}
Part of the Stata Markdown reporting suite.

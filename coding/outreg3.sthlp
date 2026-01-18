{smcl}
{* *! version 1.0.0  12jan2026}{...}
{vieweralsosee "outreg2" "help outreg2"}{...}
{vieweralsosee "logout3" "help logout3"}{...}
{vieweralsosee "markdown2" "help markdown2"}{...}
{viewerjumpto "Syntax" "outreg3##syntax"}{...}
{viewerjumpto "Description" "outreg3##description"}{...}
{viewerjumpto "Options" "outreg3##options"}{...}
{viewerjumpto "Examples" "outreg3##examples"}{...}
{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{bf:outreg3} {hline 2}}Enhanced regression tables for global reporting{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmdab:outreg3} [{it:varlist}] [{it:estlist}]
{cmd:using} {it:filename}
[{cmd:,} {it:options}]

{marker options}{...}
{title:Options}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt :{opt replace}}overwrite existing file{p_end}
{synopt :{opt append}}append to existing file{p_end}
{synopt :{opt html}}output in HTML format{p_end}
{synopt :{opt tex}}output in LaTeX format{p_end}
{synopt :{opt word}}output in Word format{p_end}
{synopt :{opt excel}}output in Excel format{p_end}
{synopt :{opt title(text)}}add a title above the table (enhanced for partial HTML/LaTeX){p_end}
{synopt :{opt ctitle(text)}}add column title{p_end}
{synopt :{opt dec(#)}}decimal places for coefficients{p_end}
{synopt :{opt bdec(#)}}decimal places for coefficients (specific){p_end}
{synopt :{opt tdec(#)}}decimal places for t-stats/SE{p_end}
{synopt :{opt rdec(#)}}decimal places for R-squared{p_end}
{synopt :{opt alpha(...)}}significance levels and asterisks{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:outreg3} is a modernized version of the popular {cmd:outreg2}, specifically optimized for integration with the {help markdown2} reproducible research workflow.

{pstd}
While retaining the core functionality of arranging regression outputs into illustrative tables, {cmd:outreg3} introduces improved handling of HTML and LaTeX outputs. A key enhancement is the {opt title()} option implementation: for HTML and LaTeX, the title is now placed visibly *above* the table structure (as a distinct header or paragraph) rather than embedded within the first row of the table. This ensures better semantic structure and easier post-processing.


{marker options_details}{...}
{title:Detailed Options}

{phang}
{opt replace} overwrites the {it:filename} if it exists.

{phang}
{opt append} adds a new column to the existing table in {it:filename}.

{phang}
{opt html}, {opt tex}, {opt word}, {opt excel} specify the output format. {cmd:outreg3} defaults to text if unspecified.

{phang}
{opt title(text)} specifies a title for the table. In HTML output, this is rendered as a centered bold {cmd:<div>} above the {cmd:<table>}. In LaTeX, it is centered text before the {cmd:tabular} environment.

{phang}
{opt dec(#)} and other formatting options behave identically to {cmd:outreg2}.


{marker remarks}{...}
{title:Remarks}

{pstd}
When using {cmd:outreg3} with the {opt html} option for Markdown reporting, it is highly recommended to follow the command with {cmd:cmdcell out}.
This ensures that the table embedding code is placed outside of Stata code blocks, allowing the table to render correctly in the browser.

{marker examples}{...}

{title:Examples}

{pstd}
{bf:1. Basic Regression Table to HTML}

{pstd}
Run detailed regressions and output to an HTML file for a report:

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. regress price mpg weight}{p_end}
{phang2}{cmd:. outreg3 using "regtable", replace html title("OLS Regression Results") sec dec(3)}{p_end}

{pstd}
{bf:2. Multiple Models in LaTeX}

{pstd}
Compare two models in a LaTeX table:

{phang2}{cmd:. regress price mpg}{p_end}
{phang2}{cmd:. outreg3 using "models.tex", replace tex title("Model Comparison") ct("Model 1")}{p_end}

{phang2}{cmd:. regress price mpg weight foreign}{p_end}
{phang2}{cmd:. outreg3 using "models.tex", append tex ct("Model 2")}{p_end}

{pstd}
{bf:3. Workflow with Stored Estimates}

{pstd}
Store models first, then output all at once (efficient):

{phang2}{cmd:. regress price mpg}{p_end}
{phang2}{cmd:. estimates store m1}{p_end}
{phang2}{cmd:. regress price mpg i.foreign}{p_end}
{phang2}{cmd:. estimates store m2}{p_end}
{phang2}{cmd:. outreg3 [m1 m2] using "allmodels.html", replace html title("Combined Results")}{p_end}


{title:Author}

{pstd}
Based on {cmd:outreg2} by Roy Wada. Enhanced for markdown workflows.

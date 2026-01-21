{smcl}
{* *! version 1.0.0  15jan2026}{...}
{vieweralsosee "logoute" "help logoute"}{...}
{vieweralsosee "tohtml" "help tohtml"}{...}
{viewerjumpto "Syntax" "loghtml##syntax"}{...}
{viewerjumpto "Description" "loghtml##description"}{...}
{viewerjumpto "Options" "loghtml##options"}{...}
{viewerjumpto "Examples" "loghtml##examples"}{...}
{title:Title}

{phang}
{bf:loghtml} {hline 2} Capture Stata command's raw log output as HTML iframe (for Markdown reports)

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:loghtml}, {opt save(filename)} [{opt replace} {opt noi:sily}] {cmd::} {it:command}

{marker description}{...}
{title:Description}

{pstd}
{cmd:loghtml} is a minimal log capture tool. Unlike tools that try to format output into beautiful tables (such as {cmd:logoute} or {cmd:outreg2e}), {cmd:loghtml} aims to {bf:preserve} Stata's text output format as-is.

{pstd}
It executes the specified {it:command}, captures its results in a temporary text log, then wraps that text in a simple HTML file (using {it:<pre>} tags). Finally, it outputs a Markdown code block (containing {it:<iframe>}) so that the {cmd:tohtml} command can embed it into the final web report.

{pstd}
This command is particularly suitable for displaying command outputs with complex structures that are difficult to convert into standard tables, such as {cmd:summarize, detail}, {cmd:codebook}, {cmd:pwcorr}, or {cmd:table}.

{marker options}{...}
{title:Options}

{phang}
{opt save(filename)} is required. Specifies the HTML filename to save (without extension). The program will generate {it:filename.html}.

{phang}
{opt replace} allows overwriting existing files.

{phang}
{opt noi:sily} If specified, the command's output will also be displayed in Stata's Results window. By default, output is captured silently.

{marker global_options}{...}
{title:Global Options (Shared with outreg2e/logoute)}

{pstd}
You can control iframe styles by setting global macros:

{phang}
{cmd:global tabwidth} : Set the iframe width percentage (default 100).

{phang}
{cmd:global tabheight} : Set the iframe height in pixels (default 400).

{phang}
{cmd:global table_center} : If set to 1, content will attempt to be centered (though for left-aligned text logs, keeping the default is usually recommended).

{marker examples}{...}
{title:Examples}

{pstd}
{bf:1. Basic Usage (Descriptive Statistics)}

{phang}
{stata sysuse auto, clear}
{p_end}
{phang}
{stata cmdcell #### Detailed Summary}
{p_end}
{phang}
{stata cmdcell 0}
{p_end}
{phang}
{stata loghtml, save("$results/sum_detail") replace : summarize price mpg, detail}
{p_end}
{phang}
{stata cmdcell out}
{p_end}

{pstd}
{bf:2. Correlation Matrix}

{phang}
{stata cmdcell #### Correlation Matrix}
{p_end}
{phang}
{stata cmdcell 0}
{p_end}
{phang}
{stata global tabheight 200}
{p_end}
{phang}
{stata loghtml, save("$results/corr") replace : pwcorr price mpg weight length, star(0.05)}
{p_end}
{phang}
{stata cmdcell out}
{p_end}

{title:Author}

{pstd}
Auto-mini integration team.
{p_end}
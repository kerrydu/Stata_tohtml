{smcl}
{* *! version 1.0.1  16jan2026}{...}
{vieweralsosee "graph export" "help graph_export"}{...}
{vieweralsosee "markdown2" "help markdown2"}{...}
{vieweralsosee "ishere" "help ishere"}{...}
{viewerjumpto "Syntax" "graph2md##syntax"}{...}
{viewerjumpto "Description" "graph2md##description"}{...}
{viewerjumpto "Options" "graph2md##options"}{...}
{viewerjumpto "Examples" "graph2md##examples"}{...}
{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{bf:graph2md} {hline 2}}Export current graph and insert Markdown image link{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:graph2md} {cmd:,}
[{opt save(filename)} {it:options}]

{marker options}{...}
{title:Options}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent :* {opt save(filename)}}filename for the exported graph (png, svg, pdf, etc.){p_end}
{synopt :{opt zoom(string)}}set CSS zoom level (e.g., "50", "80%"){p_end}
{synopt :{opt alt(text)}}specify alt text for the image{p_end}
{synopt :{opt reset}}reset the internal graph counter{p_end}
{synopt :{opt num:ber}}append an auto-incrementing number to the filename{p_end}
{synopt :{it:{help graph display:graph_export_options}}}standard options for {cmd:graph export} (replace, width, etc.){p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
* {opt save(filename)} is technically optional if a global default is set, but recommended.


{marker description}{...}
{title:Description}

{pstd}
{cmd:graph2md} bridges the gap between Stata's graphics and Markdown-based reporting.

{pstd}
It performs two functions simultaneously:
{p 8 8 2}1. Exports the currently displayed graph to a file using Stata's {help graph export}.{p_end}
{p 8 8 2}2. Outputs a properly formatted HTML {cmd:<img>} tag to the log output, enabling {help markdown2} to embed the image in the final report.{p_end}

{pstd}
This command eliminates the need to manually copy image paths into your Markdown or HTML documents. By supporting CSS zoom, it also allows for quick resizing of images in the final report without re-exporting them.


{marker options_details}{...}
{title:Detailed Options}

{phang}
{opt save(filename)} specifies the destination path and name for the image file. You should include the extension (e.g., .png, .svg) to determine the output format.

{phang}
{opt zoom(string)} applies a CSS {cmd:style="zoom:..."} attribute to the generated HTML image tag.
{p 8 8 2}- If a number is provided (e.g., {cmd:50}), it is treated as a percentage ({cmd:50%}).{p_end}
{p 8 8 2}- You can also explicitly specify units ({cmd:50%}, {cmd:0.8}).{p_end}
{p 8 8 2}{it:Note: This affects the display size in the web report, not the resolution of the exported file.}

{phang}
{opt alt(text)} specifies the alternative text for the image. If omitted, the filename is used as default.

{phang}
{opt reset} resets the internal graph counter used by the {opt number} option to zero.

{phang}
{opt number} appends an incremental number to the filename specified in {opt save()}. Useful inside loops.

{phang}
{it:graph_export_options} are passed directly to {cmd:graph export}. Common options include {cmd:replace}, {cmd:width()}, and {cmd:height()}.


{marker remarks}{...}
{title:Remarks}

{pstd}
After using {cmd:graph2md}, it is highly recommended to issue the command {cmd:ishere out} .
This ensures that the inserted image code is placed correctly outside of the Stata code blocks in the final Markdown document.

{marker examples}{...}

{title:Examples}

{pstd}
{bf:1. Basic Usage}

{pstd}
Create a scatter plot and export it to PNG, displaying it at 50% zoom in the report:

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. scatter price mpg}{p_end}
{phang2}{cmd:. graph2md, save("figures/scatter.png") replace zoom(50)}{p_end}

{pstd}
{bf:2. Using inside a workflow}

{pstd}
As part of a larger analysis script:

{phang2}{cmd:. log using analysis.md, replace text}{p_end}
{phang2}{cmd:. histogram price}{p_end}
{phang2}{cmd:. graph2md, save("hist_price.svg") replace alt("Price Distribution")}{p_end}


{title:Author}

{pstd}
Part of the Stata Markdown reporting suite.

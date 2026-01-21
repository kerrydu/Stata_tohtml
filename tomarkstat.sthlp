{smcl}
{* *! version 1.0.0  21jan2026}{...}
{vieweralsosee "markstat" "help markstat"}{...}
{viewerjumpto "Syntax" "tomarkstat##syntax"}{...}
{viewerjumpto "Description" "tomarkstat##description"}{...}
{viewerjumpto "Options" "tomarkstat##options"}{...}
{viewerjumpto "How it converts" "tomarkstat##how"}{...}
{viewerjumpto "Examples" "tomarkstat##examples"}{...}

{title:Title}

{phang}
{bf:tomarkstat} {hline 2} Convert {it:.do} files to {it:.stmd} (Stata-Markdown) format required by {cmd:markstat}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:tomarkstat} {it:filename.do} [{cmd:,} {opt replace}]

{pstd}
{it:filename.do} is a required argument specifying the path to a do file with extension {bf:.do}. 
The filename must be enclosed in double quotes if it contains blanks.


{marker options}{...}
{title:Options}

{phang}
{opt replace} allows overwriting existing output files.


{marker description}{...}
{title:Description}

{pstd}
{cmd:tomarkstat} reads a do file and generates a Stata-Markdown file (with extension {bf:.stmd}) 
with the same name, which can then be processed by {cmd:markstat using} to render dynamic documents 
in HTML, PDF, Word, and other formats.

{pstd}
Output filename rule:

{phang2}
If input is {it:path}\{bf:foo.do}, output will be {it:path}\{bf:foo.stmd}.

{pstd}
This command is designed for workflows that write reproducible reports using do files. 
You use {cmd:ishere} statements in your do file to mark text, headings, code block boundaries, 
figure/table references, etc. that should appear in the report. {cmd:tomarkstat} translates these 
markers into Markdown and code fence syntax that {cmd:markstat} can recognize.


{marker how}{...}
{title:How it converts}

{pstd}
The current implementation (see the embedded Mata code in `tomarkstat.ado`) follows these rules:

{phang2}
1. {bf:Code block fences}: Lines like {cmd:ishere ```} or {cmd:ishere } (empty argument) toggle code blocks, 
converted to {cmd:```s} / {cmd:```}.

{phang2}
2. {bf:Markdown headings}: Lines like {cmd:ishere # ...} / {cmd:ishere ## ...} output the corresponding 
Markdown heading lines directly.

{phang2}
3. {bf:Figure/table references}: Lines like {cmd:ishere fig using ...} / {cmd:ishere tab using ...} 
generate embeddable HTML/Markdown snippets (depending on file type and options).

{phang2}
4. {bf:Text blocks}: Within text regions between {cmd:ishere /*} and {cmd:ishere */}, inline fragments 
like {cmd:{ ishere display ... }} are replaced with their content (for "inline interpolation").

{pstd}
Note: Specific conversion details are subject to the current version's source code. 
If you update the `ishere_translate()` parsing rules, the conversion behavior will change accordingly.


{marker examples}{...}
{title:Examples}

{pstd}
{bf:1. Basic conversion}

{phang2}
{cmd:. tomarkstat myreport.do}

{pstd}
This will generate {bf:myreport.stmd}, which can then be used with:

{phang2}
{cmd:. markstat using myreport, strict}

{pstd}
{bf:2. Overwrite existing output}

{phang2}
{cmd:. tomarkstat myreport.do, replace}

{pstd}
{bf:3. Path with spaces}

{phang2}
{cmd:. tomarkstat "C:\My Project\report.do", replace}


{title:Author}

{pstd}
Auto-mini integration team.
{p_end}


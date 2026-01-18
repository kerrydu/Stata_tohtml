{smcl}
{* *! version 1.0.0  15jan2026}{...}
{vieweralsosee "markdown2" "help markdown2"}{...}
{vieweralsosee "cleancode" "help cleancode"}{...}
{viewerjumpto "Syntax" "_textcell##syntax"}{...}
{viewerjumpto "Description" "_textcell##description"}{...}
{viewerjumpto "Remarks" "_textcell##remarks"}{...}
{viewerjumpto "Example" "_textcell##example"}{...}
{title:Title}

{phang}
{bf:_textcell} {hline 2} Define raw text/markdown blocks in do-files for markdown2 processing


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:_textcell /*}
{it:...text content...}
{it:...text content...}
{it:*/}
{cmd:_textcell */}


{marker description}{...}
{title:Description}

{pstd}
{cmd:_textcell} is a helper command designed to work with {helpb markdown2} and {helpb cleancode}. 
It allows you to embed blocks of raw Markdown text (such as paragraphs, lists, or mathematical formulas) directly within your Stata do-file or log.

{pstd}
When Stata executes the do-file:
{break}1. The opening {cmd:_textcell /*} starts a command followed by a comment block. Stata ignores the content.
{break}2. The closing {cmd:_textcell */} is executed as a command with the argument {cmd:*/}, which is ignored by the program.
{break}Thus, using {cmd:_textcell} does not interrupt your Stata workflow.

{pstd}
When processed by {cmd:markdown2} or {cmd:cleancode}:
{break}These blocks are detected and parsed. The content inside is extracted and placed into the output Markdown file as raw text, ensuring it is correctly separated from Stata code blocks ("fences").
This enables dynamic correction of "text mode" vs "code mode" in the final document.


{marker remarks}{...}
{title:Remarks}

{pstd}
This command effectively solves the problem of "breaking out" of code blocks in generated Markdown. 
Without {cmd:_textcell}, comments in do-files are typically rendered as code comments inside a code fence (e.g., inside {c 96}{c 96}{c 96}stata ... {c 96}{c 96}{c 96}). 

{pstd}
Use {cmd:_textcell} when you want to:
{break}- Write narrative text or explanations.
{break}- Insert LaTeX math equations (e.g., {bf:$$ y = ax + b $$}).
{break}- Insert raw HTML or Markdown tables.

{pstd}
{bf:Note:} 
{break}- The opening tag must be {cmd:_textcell /*} (spaces allowed).
{break}- The closing tag must be {cmd:_textcell */} (spaces allowed).
{break}- Do not nest {cmd:_textcell} blocks inside each other.
{break}- If used inside a {cmd:cmdcell} block, it must be closed before the {cmd:cmdcell} ends to avoid ambiguous state errors.


{marker example}{...}
{title:Example}

    {cmd:sysuse auto, clear}
    
    {cmd:_textcell /*}
    {bf:### Regression Model}
    
    We now estimate the relationship between price and mpg.
    The model is specified as:
    
    $$ Price = \beta_0 + \beta_1 MPG + \epsilon $$
    {it:*/}
    {cmd:_textcell */}
    
    {cmd:regress price mpg}


{title:Author}

{pstd}
Kerry
{break}Email: kerry@example.com

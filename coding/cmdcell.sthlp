{smcl}
{* *! version 1.0.1  16jan2026}{...}
{vieweralsosee "ishere" "help ishere"}{...}
{vieweralsosee "markdown2" "help markdown2"}{...}
{vieweralsosee "_textcell" "help _textcell"}{...}
{viewerjumpto "Syntax" "cmdcell##syntax"}{...}
{viewerjumpto "Description" "cmdcell##description"}{...}
{title:Title}

{phang}
{bf:cmdcell} {hline 2} DEPRECATED - Use {help ishere} instead

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:cmdcell} {it:argument}

{marker description}{...}
{title:Description}

{pstd}
{cmd:cmdcell} is a deprecated command. Please use {help ishere:ishere} instead.

{pstd}
The {cmd:ishere} command provides all the functionality of {cmd:cmdcell} plus additional features for inserting figures, tables, and headers into Stata logs for markdown conversion.

{pstd}
{cmd:ishere} supports the following functionality:
{break}- Headers: {cmd:ishere # Header}, {cmd:ishere ## Subheader}, etc.
{break}- Figures: {cmd:ishere fig using "filename.png"}
{break}- Tables: {cmd:ishere tab using "filename.html"}

{pstd}
For backward compatibility, {cmd:cmdcell} is still available but will be removed in future versions.

{title:Author}

{pstd}
Developed for Stata Markdown conversion workflows.
{p_end}

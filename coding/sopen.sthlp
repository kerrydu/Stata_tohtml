{smcl}
{* Juli 8, 2009 @ 10:42:32 UK}{...}
{cmd:help sopen}

{hline}

{title:Title}

{p2colset 5 14 22 2}{...}
{p2col :{hi: sopen} {hline 2}}Opens directories/documents/applications/urls from inside Stata{p_end}

{marker syntax}{...}
{title:Syntax}

{p 4 10 2}
{cmdab:sopen} [{it:path}]{p_end}
{pstd}
where {it:path} is the directory to be opened. If {it: path} is missing, the current working directory is opened.

{p 4 10 2}
{cmdab:sopen} {it: filename}{p_end}
{pstd}
where {it: filename} is the file to be opened. The path to the spcified {it: filename} might be 
added before the {it: filename}. If the path is not provided, the program would search the file 
in the current working directory and Stata's adopath.

{p 4 10 2}
{cmdab:sopen} {it:application}{p_end}
{pstd}
where {it: application} is the software application to be opened. 

{p 4 10 2}
{cmdab:sopen} {it:url}{p_end}
{pstd}
where {it: url} is the url to be opened. 




{marker s_Description}
{title:Description}

{p 4 4 6}
{cmd:sopen} provides a fast and easy way to open anything from inside Stata for Windows and Mac.


{marker s_0}
{title:Examples}

{pstd}Open the current working directory{p_end}
{phang2}{cmd:.} {bf:{stata "sopen"}}{p_end}

{pstd}Open the Applications directory in Mac{p_end}
{phang2}{cmd:.} {bf:{stata "sopen /Applications"}}{p_end}

{pstd}Open sopen.ado{p_end}
{phang2}{cmd:.} {bf:{stata "sopen sopen.ado"}}{p_end}

{pstd}Open typora.app in Mac{p_end}
{phang2}{cmd:.} {bf:{stata "sopen typora.app"}}{p_end}

{pstd}Open typora.app in Windows{p_end}
{phang2}{cmd:.} {bf:{stata "sopen D:/typora/typora.exe"}}{p_end}

{pstd}Open https://www.github.com{p_end}
{phang2}{cmd:.} {bf:{stata "sopen https://www.github.com"}}{p_end}





{title:Author}

{p 4 4 6}Kerry Du{p_end}
{p 4 4 6}kerrydu@xmu.edu.cn{p_end}


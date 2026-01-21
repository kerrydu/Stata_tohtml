{smcl}
{* *! version 1.0.0  21jan2026}{...}
{vieweralsosee "ishere" "help ishere"}{...}
{viewerjumpto "Syntax" "ishere_translator##syntax"}{...}
{viewerjumpto "Description" "ishere_translator##description"}{...}
{viewerjumpto "Mata Functions" "ishere_translator##mata"}{...}
{viewerjumpto "Examples" "ishere_translator##examples"}{...}
{title:Title}

{phang}
{bf:ishere_translate} {hline 2} Mata function to parse and execute ishere statements


{marker syntax}{...}
{title:Syntax}

{pstd}
{bf:Mata function:}

{p 8 17 2}
{cmd:result = ishere_translate(}{it:command}{cmd:)}

{pstd}
{bf:Stata wrapper command:}

{p 8 17 2}
{cmd:ishere_exec} {it:ishere_statement}


{marker description}{...}
{title:Description}

{pstd}
{cmd:ishere_translate()} is a Mata function that parses and executes {cmd:ishere} statements,
returning their output as a string. This is useful for programmatically capturing the output
of {cmd:ishere} commands, particularly for automated report generation.

{pstd}
The function handles three types of {cmd:ishere} statements:

{phang2}
1. {bf:display commands}: {cmd:ishere display "text"} returns the displayed text

{phang2}
2. {bf:fig/table commands}: {cmd:ishere fig/tab using file} returns the markdown output

{phang2}
3. {bf:placeholder commands}: {cmd:ishere xxx} (where xxx is not a recognized command) returns empty string ""


{marker mata}{...}
{title:Mata Functions}

{phang}
{cmd:string scalar ishere_translate(string scalar cmd)}

{pmore}
Main function that parses and executes an ishere statement.

{pmore}
{it:Arguments:}

{pmore2}
{cmd:cmd} - The ishere command string to execute

{pmore}
{it:Returns:}

{pmore2}
String containing the command output, or empty string "" if no output


{phang}
{cmd:string scalar execute_display(string scalar args)}

{pmore}
Helper function to execute display commands and capture their output.


{phang}
{cmd:string scalar execute_ishere_markdown(string scalar subcmd, string scalar args)}

{pmore}
Helper function to execute fig/table ishere commands and capture their markdown output.


{marker examples}{...}
{title:Examples}

{pstd}
{bf:1. Using Mata function directly}

{phang2}
{cmd:. mata:}
{p_end}
{phang2}
{cmd:: result = ishere_translate("ishere display " + char(34) + "Hello" + char(34))}
{p_end}
{phang2}
{cmd:: result}
{p_end}
{phang2}
{cmd:Hello}
{p_end}
{phang2}
{cmd:: end}
{p_end}

{pstd}
{bf:2. Using Stata wrapper command}

{phang2}
{cmd:. ishere_exec ishere display "Hello World"}
{p_end}
{phang2}
{cmd:Hello World}
{p_end}
{phang2}
{cmd:. return list}
{p_end}

{pstd}
{bf:3. Placeholder returns empty}

{phang2}
{cmd:. mata:}
{p_end}
{phang2}
{cmd:: result = ishere_translate("ishere xxx")}
{p_end}
{phang2}
{cmd:: result}
{p_end}
{phang2}
{cmd:}
{p_end}
{phang2}
{cmd:: end}
{p_end}

{pstd}
{bf:4. Display with expression}

{phang2}
{cmd:. mata:}
{p_end}
{phang2}
{cmd:: result = ishere_translate("display 2+2")}
{p_end}
{phang2}
{cmd:: result}
{p_end}
{phang2}
{cmd:4}
{p_end}
{phang2}
{cmd:: end}
{p_end}

{pstd}
{bf:5. Programmatic usage in a loop}

{phang2}
{cmd:. mata:}
{p_end}
{phang2}
{cmd:: for (i=1; i<=3; i++) \{}
{p_end}
{phang2}
{cmd::     cmd = "display " + char(34) + "Item " + char(34) + " + strofreal(i)}
{p_end}
{phang2}
{cmd::     result = ishere_translate(cmd)}
{p_end}
{phang2}
{cmd::     printf("Result %f: %s\n", i, result)}
{p_end}
{phang2}
{cmd:: \}}
{p_end}
{phang2}
{cmd:: end}
{p_end}


{title:Loading the Function}

{pstd}
To use the Mata functions, first load the file:

{phang2}
{cmd:. do ishere_translator.mata}
{p_end}

{pstd}
The {cmd:ishere_exec} command automatically loads the Mata functions if needed.


{title:Author}

{pstd}
Stata to HTML integration team.
{p_end}

{smcl}
{* *! version 1.0.0  15jan2026}{...}
{vieweralsosee "logout3" "help logout3"}{...}
{vieweralsosee "markdown2" "help markdown2"}{...}
{viewerjumpto "Syntax" "logout4##syntax"}{...}
{viewerjumpto "Description" "logout4##description"}{...}
{viewerjumpto "Options" "logout4##options"}{...}
{viewerjumpto "Examples" "logout4##examples"}{...}
{title:Title}

{phang}
{bf:logout4} {hline 2} 将 Stata 命令的原始日志输出捕获为 HTML iframe（用于 Markdown 报告）

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:logout4}, {opt save(filename)} [{opt replace} {opt noi:sily}] {cmd::} {it:command}

{marker description}{...}
{title:Description}

{pstd}
{cmd:logout4} 是一个极简的日志捕获工具。与试图将输出格式化为美观表格（如 {cmd:logout3} 或 {cmd:outreg3}）不同，{cmd:logout4} 旨在{bf:原样保留} Stata 的文本输出格式。

{pstd}
它执行指定的 {it:command}，将其结果捕获到一个临时的文本日志中，然后将该文本包裹在一个简单的 HTML 文件（使用 {it:<pre>} 标签）中。最后，它会输出一段 Markdown 代码块（包含 {it:<iframe>}），以便 {cmd:markdown2} 命令可以将其嵌入到最终的网页报告中。

{pstd}
此命令非常适合展示那些结构复杂、难以转化为标准表格的命令输出，例如 {cmd:summarize, detail}，{cmd:codebook}，{cmd:pwcorr} 或 {cmd:table}。

{marker options}{...}
{title:Options}

{phang}
{opt save(filename)} 是必须的。指定要保存的 HTML 文件名（无需扩展名）。程序将生成 {it:filename.html}。

{phang}
{opt replace} 允许覆盖已存在的文件。

{phang}
{opt noi:sily} 如果指定，命令的输出也会显示在 Stata 的结果窗口中。默认情况下是静默捕获。

{marker global_options}{...}
{title:Global Options (Shared with outreg3/logout3)}

{pstd}
你可以通过设置全局宏来控制 iframe 的样式：

{phang}
{cmd:global tabwidth} : 设置 iframe 的宽度百分比（默认 100）。

{phang}
{cmd:global tabheight} : 设置 iframe 的高度（像素，默认 400）。

{phang}
{cmd:global table_center} : 如果设置为 1，内容将尝试居中显示（虽然对于左对齐的文本日志，通常建议保留默认值）。

{marker examples}{...}
{title:Examples}

{pstd}
{bf:1. 基本用法 (描述性统计)}

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
{stata logout4, save("$results/sum_detail") replace : summarize price mpg, detail}
{p_end}
{phang}
{stata cmdcell out}
{p_end}

{pstd}
{bf:2. 相关系数矩阵}

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
{stata logout4, save("$results/corr") replace : pwcorr price mpg weight length, star(0.05)}
{p_end}
{phang}
{stata cmdcell out}
{p_end}

{title:Author}

{pstd}
Auto-mini integration team.
{p_end}
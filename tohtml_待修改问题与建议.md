# `tohtml` 待修改问题与建议

## 1. `cleancode` 模式无法正确替换 `ishere display` 动态值

### 1.1 问题状态

- 影响范围：发生在 `cleancode` 模式；默认 detail 模式和 `clean` 模式下，同一写法可以正常替换。
- 相关源码：`code_test/tohtml.ado` 中的 `rewrite_md_cleancode()`、`keep_stata_code_lines()` 和 `subisheredintxt()`。
- 复现材料：`examples/second/example_cleancode.do` 及其生成的 log、Markdown 和 HTML。

### 1.2 复现写法

```stata
regress price mpg weight
local r2 = e(r2)
ishere display %5.3f `r2'
/**
The R-squared is {ishere display %5.3f `r2'}.
**/
```

预期生成：

```text
The R-squared is 0.293.
```

`cleancode` 模式实际生成的 Markdown 为：

```text
The R-squared is _ishere_/* .
```

其中 `_ishere_` 被 Markdown 解释为斜体，最终 HTML 显示为：

```text
The R-squared is ishere/* .
```

对照结果：

- `examples/second/results/logs/example_detail.html` 正确显示 `0.293`；
- `examples/second/results/logs/example_clean.html` 正确显示 `0.293`；
- `examples/second/results/logs/example_cleancode.html` 错误显示 `ishere/*`。

### 1.3 原因分析

`cleancode` 当前按以下顺序处理日志：

1. `rewrite_md_cleancode()` 读取原始 log；
2. `keep_stata_code_lines()` 只保留以 `.` 或 `>` 开头的命令行，以及图形和表格标签；
3. `ishere display` 产生的数值行 `0.293` 不以 `.` 或 `>` 开头，因此在这一步被删除；
4. 过滤后的内容再交给 `rewrite_md()`；
5. `subisheredintxt()` 仍假定 `. ishere display ...` 的下一行就是需要填入叙事块的数值；
6. 由于真正的数值已经被删除，此时下一行变成叙事块起点 `_ishere_/*`，程序便把它错误地写入 `{ishere display ...}` 占位符。

因此，这不是示例语法错误，而是 `cleancode` 在“先删除输出、后替换动态值”这一执行顺序上的冲突。

### 1.4 建议修改思路

建议优先采用以下思路：

1. 在 `rewrite_md_cleancode()` 删除命令输出之前，从原始 log 中提取每条 `. ishere display ...` 及其紧随的显示值；
2. 保存“display 参数—显示值—后续第一个叙事块”的对应关系；
3. 再执行 code-only 过滤，删除普通 Stata 输出；
4. 使用此前保存的显示值替换叙事块中的 `{ishere display ...}`；
5. 最终输出中保留 Stata 命令和替换后的叙事文本，但不保留单独的原始数值输出行。

另一种改动较小的方案是：让 `keep_stata_code_lines()` 临时保留每条 `. ishere display ...` 后面的第一行，等 `subisheredintxt()` 完成替换后再删除这些临时保留的值。该方案需要避免数值行意外残留在最终的 code-only 报告中。

不建议通过修改示例、手工填写 R 方或直接编辑生成的 Markdown/HTML 绕过问题，因为这样会破坏动态值与回归结果之间的可复现关系。

## 2. `.md` 输入与默认 Markdown 输出同名时会删除输入

### 2.1 问题状态

- 影响范围：输入文件扩展名为 `.md`，程序推导出的默认 Markdown 输出路径又与输入路径相同，同时指定 `replace`。
- 相关源码：`code_test/tohtml.ado` 主程序中的输出路径解析、`replace` 删除逻辑和 `rewrite_md()` 调用；重点涉及 `tohtml_resolve_md()`。
- 复现材料：`agent_tasks/reviewer_audit_2026190808/stata_tests/run_all.do` 中的 CORE-06，以及同目录的 `audit_body.log` 和 `runtime_results.md`。

### 2.2 复现写法

以下代码只能使用专门创建的测试文件，不能替换为需要保留的真实 `.md` 文件：

```stata
tempname fh
file open `fh' using "collision.md", write text replace
file write `fh' ". display 1" _n
file write `fh' "1" _n
file close `fh'

tohtml "collision.md", replace
```

预期行为：

- 程序发现输入路径与输出路径相同后，在删除任何文件之前停止运行；
- `collision.md` 原文件保持不变；
- 错误消息明确提示输入文件与 Markdown 输出文件不能同名。

实际行为：

```text
file collision.md not found
r(601)
```

命令执行后，输入文件 `collision.md` 已被删除。

类似风险也可能出现在以下写法中：

```stata
tohtml "report.md", html("report.html") replace
```

因为没有显式指定 `md()`，程序会根据 `html("report.html")` 推导出默认 Markdown 输出 `report.md`，仍与输入文件相同。

### 2.3 原因分析

程序当前按以下顺序处理：

1. 将输入路径保存为 `report.md` 或 `collision.md`；
2. `tohtml_resolve_md()` 根据输入文件或 `html()` 推导 Markdown 输出路径；
3. 输入本身已经是 `.md` 时，推导出的输出路径可能与输入路径完全相同；
4. 指定 `replace` 后，程序先执行 `erase` 删除 Markdown 输出文件；
5. 由于输入和输出是同一个文件，这一步同时删除了输入；
6. `rewrite_md()` 随后读取输入文件，发现文件已经不存在，于是返回 `r(601)`。

因此，问题不在 Markdown 内容，而在程序没有在删除输出前比较输入路径和输出路径。

### 2.4 建议修改思路

建议按以下顺序修复：

1. 完成 `md()` 和 `html()` 默认路径推导后，先把输入路径和 Markdown 输出路径转换为规范化的绝对路径；
2. 在 Windows 下比较路径时，应同时处理正反斜杠、相对路径、大小写和 `.`、`..` 等写法；
3. 如果两个路径相同，应在执行任何 `erase` 或写文件操作之前停止，并返回明确错误；
4. 建议错误消息写为：`input file and Markdown output file must be different`；
5. 只有确认输入与输出不同后，才能执行 `replace`；
6. 帮助文件和示例中如使用 `.md` 输入，应显式指定不同的 `md()` 输出文件名，不能再给出可能覆盖输入的写法。

更稳妥的实现还可以先把结果写入临时文件，全部处理成功后再替换目标输出。这样即使转换中途失败，也不会破坏已有文件。

## 3. 审稿意见 #22：text log 文件头在 Markdown 中渲染错误

### 3.1 问题状态

- 审稿人的问题：`tohtml` 把 Stata text log 开头的日志元数据原样写入 Markdown，没有将其作为一个完整的等宽文本块保护起来。Markdown 随后会把其中的短横线、缩进和换行解释为自身语法，导致页面结构与原始日志不一致。
- 当前影响：默认 detail 输出仍有该问题。例如，`examples/second/results/logs/example_detail.md` 的开头仍是未加围栏的日志头。SMCL 自动转换后的输出也应纳入复测，因为转换后的文本仍可能带有同类日志头。
- 相关源码：`code_test/tohtml.ado` 中的 `rewrite_md()` 及代码围栏处理逻辑；`rewrite_md2()`、`rewrite_md_cleancode()` 也需要做回归检查，确认 `clean` 和 `cleancode` 模式对日志头的处理符合各自定义。
- 审稿意见原文位置：`submission/一审意见/2026.06.10.du_review_author.pdf` 第 4 页，第 22 条。

### 3.2 复现写法

一个典型的 Stata text log 文件头如下：

```text
------------------------------------------------------------------------
      name:  <unnamed>
       log:  filename.log
  log type:  text
 opened on:  1 June 2026, 14:12:32
```

当前程序会把这些行直接写入 Markdown。渲染时可能出现以下结果：

- 第一行连续短横线被解释为水平分隔线，而不是日志内容；
- 带有缩进的 `name:` 和 `log:` 行被解释为代码块；
- `log type:` 和 `opened on:` 被合并为普通段落，原有的逐行结构丢失。

审稿人建议的预期 Markdown 结构是：

````text
```text
------------------------------------------------------------------------
      name:  <unnamed>
       log:  filename.log
  log type:  text
 opened on:  1 June 2026, 14:12:32
```
````

这样生成 HTML 后，整个日志头会作为一个预格式化代码块原样显示，不会再触发水平分隔线或普通段落规则。

### 3.3 原因分析

`rewrite_md()` 当前读取并清理日志后，会处理 `ishere` 标记、Markdown 标题和 Stata 代码围栏，但没有先识别 Stata 日志头，也没有给这一块内容加上专用围栏。因此，日志头中的字符进入 Markdown 后会按通用语法解释。

修复时不能简单地把“文件前五行”包起来。审稿人展示的是五条日志头记录，但在实际 text log 中，较长的文件路径可能被 Stata 折成多行，续行通常以 `>` 开头。命名日志、不同路径长度以及 SMCL 转换结果也会改变实际行数。如果只按物理行数截取，可能漏掉日志头的续行，或者误把第一条 Stata 命令包进日志头。

因此，应根据日志头的整体结构识别边界：开头的短横线分隔符，以及后续的 `name:`、`log:`、`log type:` 和 `opened on:` 记录。只有该结构完整匹配时，程序才应将其作为日志头处理，不能把回归表或其他由短横线组成的内容误判为日志头。

### 3.4 建议修改思路

建议新增一个专门处理日志头的 Mata 函数，并按以下顺序接入现有流程：

1. 在通用 Markdown 结构和代码围栏处理之前，检查文件开头是否符合 Stata 日志头的完整结构；
2. 识别四条元数据记录，并把长路径产生的 `>` 续行归入对应的 `log:` 记录，不能固定读取前五个物理行；
3. 在日志头之前插入 `` ```text ``，在 `opened on:` 记录及其续行之后插入 `` ``` ``；
4. 再执行现有的前缀清理、标题转换和代码块处理，确保新增围栏不会被删除、移动或重复插入；
5. 如果输入没有标准日志头，或日志头结构不完整，则保持原内容不变，不能仅凭一行短横线触发处理；
6. 最终检查围栏总数和开闭顺序，避免修复 #22 时引入审稿意见 #23 所指出的奇数围栏问题。

最低复测应包括：未命名 log、命名 log、短路径、会折行的长路径、text log、SMCL 自动转换结果，以及默认、`clean`、`cleancode` 三种模式。默认输出保留日志头时，应确认 Markdown 使用成对的 `text` 代码围栏，生成的 HTML 中对应内容位于 `<pre><code>` 块内且不产生额外 `<hr>`。如果 `clean` 或 `cleancode` 的既定规则是删除日志元数据，也应明确测试日志头被完整删除，而不是只残留其中几行。

不建议直接删除默认 detail 输出中的日志头来规避问题，因为审稿人的明确建议是保留这部分信息并正确围住。也不应只修改现有 `.md` 或 `.html` 生成物；应修复 `tohtml.ado` 的转换逻辑后重新生成示例。

## 4. 行内公式无法触发 MathJax

### 4.1 问题状态

- 影响范围：目前已在默认 detail 模式下复现。使用 `mathjax` 选项并输入行内公式 `$x^2$` 时，`tohtml` 返回 `r(0)`，生成的 Markdown 也保留了公式，但 HTML 中没有注入 MathJax 脚本，页面仍直接显示 `$x^2$`。
- 对照结果：把公式改为独立公式 `$$x^2$$` 后，MathJax 脚本可以正常注入。因此，问题不在 `mathjax` 选项本身，而在行内公式检测环节。
- 相关源码：`code_test/tohtml.ado` 中的 `tohtml_style()`、`content_has_math()` 和 `inject_mathjax()`。
- 已有复现材料：`submission/temp/tohtml_runtime_checks/tohtml_runtime_math_check.do` 及其输入、Markdown、HTML 和结果日志。
- 简化复测文件：`submission/temp/tohtml_inline_mathjax_test_20260819/test_inline_mathjax.do`。该文件把行内公式和独立公式分别写入两个 HTML，避免独立公式触发 MathJax 后掩盖行内公式的问题。

### 4.2 复现写法

行内公式测试：

```stata
log using "inline_mathjax_demo.log", text replace

ishere # Inline MathJax test
ishere
sysuse auto, clear
regress price mpg weight

/**
回归已经完成。下面这个行内公式应该显示为数学公式：$x^2$。
**/
ishere

log close
tohtml "inline_mathjax_demo.log", ///
    md("inline_mathjax_demo.md") ///
    html("inline_mathjax_demo.html") ///
    mathjax replace
```

预期结果：

- `tohtml` 识别 `$x^2$` 为行内公式；
- `inline_mathjax_demo.html` 中包含 `MathJax-script`；
- 浏览器把 `$x^2$` 渲染为数学公式。

实际结果：

- `tohtml` 返回 `r(0)`；
- `inline_mathjax_demo.md` 中仍有 `$x^2$`，说明公式没有在前面的日志清理过程中丢失；
- 运行日志显示 `% mathjax skipped (no equations detected in inline_mathjax_demo.md)`；
- HTML 中没有 `MathJax-script`，浏览器直接显示 `$x^2$`。

独立公式可以作为阳性对照，但必须生成另一份 HTML：

```markdown
$$x^2$$
```

不能把 `$x^2$` 和 `$$x^2$$` 放在同一份测试报告中。独立公式一旦触发 MathJax，页面中的行内公式也会被 MathJax 顺带渲染，导致测试者误以为行内公式检测已经正常。

### 4.3 原因分析

`tohtml_style()` 在用户指定 `mathjax` 后，调用 `content_has_math()` 检查清理后的 Markdown。只有该函数返回 1，程序才会调用 `inject_mathjax()`；否则便显示 `mathjax skipped`，并继续以 `r(0)` 结束。

`content_has_math()` 当前采用以下判断：

```mata
if (ustrpos(s, "$$") > 0) return(1)
if (ustrpos(s, "\\(") > 0) return(1)
if (ustrpos(s, "\\[") > 0) return(1)
if (ustrregexm(s, "\$[^$\n]+\$")) return(1)
```

其中，独立公式 `$$...$$` 使用简单字符串查找，因此能够被识别；行内公式 `$...$` 依赖最后一条正则表达式。现有运行结果表明，该正则表达式没有在实际 Mata 运行中匹配 `$x^2$`。具体问题可能涉及正则表达式本身或字符串转义方式，修复前应通过独立的 Mata 最小测试确认，不能只根据源码意图判断它已经支持 `$...$`。

生成的 Markdown 已保留 `$x^2$`，说明问题发生在公式检测阶段，而不是日志转 Markdown 的阶段。`inject_mathjax()` 中也已经配置 `inlineMath: [['$', '$'], ['\\(', '\\)']]`；只要脚本被正确注入，MathJax 本身应能处理 `$...$`。因此，当前首要修复对象是 `content_has_math()`。

`tohtml` 返回 `r(0)` 是因为“未检测到公式时跳过 MathJax”在当前设计中属于正常分支。无公式报告即使指定 `mathjax`，也应允许正常完成。因此，不宜简单地把所有 `mathjax skipped` 都改成非零返回码；应先修复行内公式的误判，并在测试中同时检查返回码和 HTML 是否实际注入脚本。

### 4.4 建议修改思路

建议按以下顺序处理：

1. 为 `content_has_math()` 建立独立的 Mata 最小测试，先确认当前正则表达式在 `$x^2$`、`$x+y$` 和中文段落中的实际返回值；
2. 修正行内公式匹配。若 Mata 正则表达式的转义容易出错，可改为扫描未转义的单个 `$` 定界符：找到起始 `$` 后，再寻找后续非空的结束 `$`，同时排除 `$$...$$`；
3. 分别测试 `$...$`、`$$...$$`、`\(...\)`、`\[...\]`，每种定界符都使用独立 HTML；
4. 增加无公式、普通金额如 `$100`、转义美元符号 `\$`、空定界符和只有一个 `$` 的反例，避免修复后误加载 MathJax；
5. 测试不能只看 `tohtml` 是否返回 `r(0)`，还要检查 Markdown 是否保留公式、HTML 是否包含 `MathJax-script`，并在联网环境中确认浏览器渲染结果；
6. 在默认、`clean` 和 `cleancode` 三种模式下分别复测，因为三条路径最终都会调用 `tohtml_style()`；
7. 修复并通过测试后，再同步更新帮助文件、示例和审稿修改总结。修复前不能把审稿意见 #42 标记为已经完整通过运行验证。

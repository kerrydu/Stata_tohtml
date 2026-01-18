# Stata 自动化可重复研究报告生成工作流

这个 `.do` 文件展示了一个基于 Stata 的高效自动化报告生成工作流。该工作流的核心思想是利用 Stata 的日志功能捕捉分析过程，并通过一系列专门的命令（ado-packages）将统计表格、图形和代码注释无缝转换为排版精美的 Markdown 和 HTML 报告。

## 核心组件与流程

该工作流将传统的 Stata 分析与动态文档生成相结合，只需运行一次 `.do` 文件，即可从原始数据生成包含代码、表格、图形和解释性文字的完整网页报告。

### 1. 初始化与日志增强 (Log Capture & Statacell)

*   **日志记录**：不同于传统的 `.log` 或 `.smcl` 格式，该工作流直接将日志保存为 `.md` (Markdown) 格式。这为后续转换为 HTML 奠定了基础。
    ```stata
    capture log close
    log using "$logs/auto-mini.md", replace text
    ```
*   **结构化标记 (Statacell)**：
    *   使用 `statacell` 命令（通常配合编辑器插件或手动注释）在 do-file 中插入特定的单元格标记（如 `/*--- ... ---*/`）。
    *   这些标记将长代码分割为逻辑上的“单元格”（Cell），类似于 Jupyter Notebook 的代码块。这有助于 `markdown2` 在后期处理时正确识别代码段落和输出结果的边界，实现更好的排版布局。

### 2. 表格输出 (Logout3 & Outreg3)

在分析过程中，该工作流摒弃了手动复制粘贴表格的方式，利用以下命令直接生成 Web 友好的表格代码：

*   **Logout3**：主要用于描述性统计或简单列表。
    *   它将 `tabstat` 或其他命令的输出直接转换为 LaTeX 和 HTML 格式。生成的表格代码会被直接嵌入到日志或保存为独立文件引用。
    *   示例中用于输出 `price`, `weight`, `mpg` 等变量的描述统计量。
*   **Outreg3**：主要用于回归结果的输出。
    *   它是著名的 `outreg2` 的现代化版本，增强了对 HTML/LaTeX 的支持。
    *   支持 `title()` 选项，正如我们刚才修复的，它可以将标题正确地放置在表格上方。
    *   示例中展示了如何将多个回归模型（`model1` 至 `model6`）合并输出到一个格式化的表格中。

### 3. 图形集成 (Graph2md)

*   **Graph2md**：这是一个连接 Stata 图形与 Markdown文档的关键工具。
    *   当在 Stata 中生成图形（如直方图、散点图）后，紧接着运行 `graph2md`。
    *   它不仅会将当前图形保存为文件（如 `.png` 或 `.svg`），还会自动在日志中插入标准的 Markdown 图片引用语法（例如 `![](/path/to/image.png)`）。
    *   这确保了最终生成的 HTML 报告中能直接显示高质量的图片，而无需手动插入链接。

### 4. 最终报告生成 (Markdown2)

*   **Markdown2**：这是整个工作流的“渲染引擎”。
    *   **清理与转换**：在 `.do` 文件的末尾，`markdown2` 命令读取原始的、包含大量 Stata 运行杂音的日志文件（`auto-mini.md`）。
    *   **智能解析**：它利用 `statacell` 留下的标记和自身的解析逻辑，清理无关的系统输出，保留代码、用户注释、`logout3`/`outreg3` 生成的表格以及 `graph2md` 插入的图片链接。
    *   **输出 HTML**：最终将清理后的内容渲染为样式美观的 HTML 网页。

## 总结

这个工作流实现了一个**“代码即报告” (Code-as-Report)** 的理念：

1.  **写代码** (`statacell` 标记结构)
2.  **做分析** (常规 Stata 命令)
3.  **出结果** (`logout3`/`outreg3` 出表, `graph2md` 出图)
4.  **一键发布** (`markdown2` 生成最终 HTML)

这种方式极大地提高了科研和数据分析工作的透明度与可重复性，同时也大幅降低了撰写分析报告的排版时间成本。


----


----
# more instructions step by step
## 从最简单例子出发

```
* 1. Start a log
log using "report.md", replace text
* 2. Add one ishere to the log
ishere
* 3. do as you normally would
    sysuse auto, clear
    summarize price mpg
    scatter price mpg
    regress price mpg
* 4. Close log and convert
capture log close
markdown2 "report.md", replace html("report.html") css(githubstyle)
```

## do some more: add title and text

```
* 1. Start a log
    log using "report.md", replace text
* 2 add title
     ishere # A Simple Report
* 3. Add one ishere to the log
     ishere
* 4. do as you normally would
    sysuse auto, clear
*  5. add title for next section
    ishere ## Data Summary
    summarize price mpg
*  6. add title for next section
    ishere ## Scatter Plot
    scatter price mpg
*  7. add title for next section
    ishere ## Regression Analysis
    regress price mpg
*  8. add text
    _textcell /*
    Price is the dependent variable. MPG is the independent variable.

    The regression model is:
    $$ \text{price} = \beta_0 + \beta_1 \text{mpg} + \epsilon $$

    The regression analysis shows that the coefficient for MPG is -0.01, which means that for every one unit increase in MPG, the price decreases by .01.

    Regression results show that the relationship between price and MPG is positive, but not very strong.
    _textcell */
*   9. Close log and convert
capture log close
markdown2 "report.md", replace html("report.html") css(githubstyle)
```

## do some more: enbodied tables and figures
```
* 1. Start a log
    log using "report.md", replace text
* 2 add title
     ishere # A Simple Report
* 3. Add one ishere to the log
     ishere
* 4. do as you normally would
    sysuse auto, clear
*  5. add title for next section
    ishere ## Data Summary
    logout4, save(./summary) html replace: summarize price mpg
*  6. add title for next section
    ishere ## Scatter Plot
    scatter price mpg
    graph2md, save("./scatter.png")
*  7. add title for next section
    ishere ## Regression Analysis
    regress price mpg
    outreg3 using "./reg_table.tex", replace html
    ishere out
*  8. add text
    _textcell /*
    Price is the dependent variable. MPG is the independent variable.

    The regression model is:
    $$ \text{price} = \beta_0 + \beta_1 \text{mpg} + \epsilon $$

    The regression analysis shows that the coefficient for MPG is -0.01, which means that for every one unit increase in MPG, the price decreases by .01.

    Regression results show that the relationship between price and MPG is positive, but not very strong.
    _textcell */
*   9. Close log and convert
capture log close
markdown2 "report.md", replace html("report.html") css(githubstyle)
```

## use clean mode

```
* 1. Start a log
    log using "report.md", replace text
* 2 add title
     ishere # A Simple Report
* 3. Add one ishere to the log
     ishere
* 4. do as you normally would
    sysuse auto, clear
*  5. add title for next section
    ishere ## Data Summary
    logout4, save(./summary) html replace: summarize price mpg
*  6. add title for next section
    ishere ## Scatter Plot
    scatter price mpg
    graph2md, save("./scatter.png")
*  7. add title for next section
    ishere ## Regression Analysis
    regress price mpg
    outreg3 using "./reg_table.tex", replace html
    ishere out
*  8. add text
    _textcell /*
    Price is the dependent variable. MPG is the independent variable.

    The regression model is:
    $$ \text{price} = \beta_0 + \beta_1 \text{mpg} + \epsilon $$

    The regression analysis shows that the coefficient for MPG is -0.01, which means that for every one unit increase in MPG, the price decreases by .01.

    Regression results show that the relationship between price and MPG is positive, but not very strong.
    _textcell */
*   9. Close log and convert
capture log close
markdown2 "report.md", clean replace html("report.html") css(githubstyle)
```
## use cleancode mode

```
* 1. Start a log
    log using "report.md", replace text
* 2 add title
     ishere # A Simple Report
* 3. Add one ishere to the log
     ishere 0
* 4. do as you normally would
    sysuse auto, clear
    ishere ## Data Summary
    logout4, save(./summary) html replace: summarize price mpg
    * ishere out to insert logout4 output
    ishere out
*  6. add title for next section
    ishere ## Scatter Plot
    ishere
    scatter price mpg
    graph2md, save("./scatter.png")
    * ishere out to insert scatter.png
    ishere out
*  7. add title for next section
    ishere ## Regression Analysis
    ishere
    regress price mpg
    outreg3 using "./reg_table.tex", replace html
    * ishere out to insert reg_table.html
    ishere out
*  8. add text
    _textcell /*
    Price is the dependent variable. MPG is the independent variable.

    The regression model is:
    $$ \text{price} = \beta_0 + \beta_1 \text{mpg} + \epsilon $$

    The regression analysis shows that the coefficient for MPG is -0.01, which means that for every one unit increase in MPG, the price decreases by .01.

    Regression results show that the relationship between price and MPG is positive, but not very strong.
    _textcell */
*   9. Close log and convert
capture log close
markdown2 "report.md", cleancode(./example.do) replace html("report.html") css(githubstyle)
```

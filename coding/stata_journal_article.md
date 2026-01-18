# Everything is here: From do to html

## Abstract

This paper introduces the Stata_log2html package, a lightweight toolkit designed to automate the conversion of Stata log files into clean, formatted Markdown and HTML reports. The package addresses the need to produce readable reports directly from Stata workflow logs without requiring external compilation tools like Jupyter or RMarkdown. It parses the Stata log file to distinguish between code, output, and added narrative, producing high-quality Markdown that can be rendered to HTML with LaTeX math support. The package follows a zero-intrusion design principle, allowing users to maintain their standard Stata workflow while generating professional reports.

## 1. Introduction

Reproducible research is a cornerstone of modern statistical analysis, requiring researchers to seamlessly integrate code, output, and narrative into comprehensive reports. In the Stata ecosystem, researchers traditionally face challenges when attempting to create publication-ready documents that combine analysis code, results, and interpretive text. While external tools like Jupyter notebooks and RMarkdown offer solutions, they often require researchers to abandon their familiar Stata workflow.

The Stata_log2html package addresses this challenge by providing a set of tools that enable researchers to generate professional HTML reports directly from their Stata do-files and log files. Unlike alternative approaches that require significant changes to the analytical workflow, this package maintains the familiar Stata environment while adding sophisticated reporting capabilities.

The key innovation of Stata_log2html lies in its zero-intrusion design philosophy. Users can continue writing and executing Stata code in their standard do-files without adopting new programming paradigms or switching to external environments. The package achieves this through marker-based commands that provide structural hints to the conversion engine without interfering with the underlying analysis.

This paper describes the functionality of the Stata_log2html package, demonstrates its usage through practical examples, and discusses its advantages for reproducible research workflows in Stata.

## 2. Methodology and Features

The Stata_log2html package centers around two core commands that reflect the essence of the package's functionality: `ishere` (the "from do" part) and `markdown2`/`tohtml` (the "to html" part):

### 2.1 Core Command: `ishere`

The `ishere` command provides manual control over Markdown headers, figures, and tables insertion (e.g., `### Header`, `ishere fig using "file.png"`, `ishere tab using "file.html"`). The name `ishere` draws inspiration from a long-standing convention in academic and technical writing: the humble placeholder note like "Table 1 inserted here" or "Figure goes here." For decades, researchers have used such phrases to mark where results should appear in a manuscript—especially when figures and tables are generated separately from the main text. In the world of reproducible research with Stata, a similar need arises: how do you tell your analysis script, "Put the graph right here in the log," so that it can later be cleanly converted into a polished report? The answer is `ishere`. Literally meaning "insert something here, on this line, in this do-file," `ishere` acts as a dynamic, executable placeholder.

Key features of `ishere` include:

- **Header insertion**: Create Markdown headers at specific points in your log file (e.g., `ishere # Title`, `ishere ## Subtitle`)
- **Content positioning**: Control exactly where figures, tables, and other elements appear in the final document
- **Code fence management**: Control where code blocks begin and end in the final output
- **Dynamic placement**: Place content exactly where it logically belongs in your narrative

### 2.2 Core Command: `markdown2` and `tohtml`

The `markdown2` and `tohtml` commands serve as the primary engines for converting Stata log files (`.log` or `.smcl` converted to text) into Markdown (`.md`) and subsequently to HTML. These commands are functionally equivalent and provide the conversion functionality. Key features include:

- Automatic syntax highlighting for Stata code
- LaTeX math formatting support via MathJax
- Automatic cleaning of Stata prompts (`.` and `>`)
- Integration of external HTML and image assets
- Multiple output modes: detailed, clean, and clean code

### 2.3 Zero-Intrusion Design

The package's most significant advantage is its zero-intrusion design:

- **100% Do-file Based**: All operations remain within standard Stata `.do` files
- **Workflow Preservation**: The package does not change how users write or run Stata code
- **Marker-Based Approach**: Commands like `ishere` act as auxiliary markers without interfering with data or statistics
- **Reproducibility**: Reports are regenerated every time the do-file runs, ensuring documentation stays synchronized with results

### 2.4 Three Usage Modes

The package supports three distinct output modes:

1. **Detailed Mode**: Captures all Stata output, including console logs, exported HTML tables, and generated figures
2. **Clean Mode**: Outputs only titles, textual content, and visual charts, excluding console output
3. **Clean Code Mode**: Delivers titles, textual content, charts, and code blocks while excluding console output results

## 3. Comparison with Other Stata Solutions

The Stata_log2html package distinguishes itself from other Stata reporting solutions in several key ways:

### 3.1 Traditional Logging vs. Stata_log2html

Traditional Stata logging (`log using`) produces plain text files that require manual post-processing to create formatted reports. Users must copy and paste results into word processors, manually insert figures, and format tables. This approach is time-consuming and error-prone, with no guarantee of reproducibility when the underlying analysis changes.

In contrast, Stata_log2html automates the entire process, allowing users to generate professional HTML reports directly from their do-files with minimal additional code.

### 3.2 MarkDoc vs. Stata_log2html

MarkDoc is a popular Stata package for creating Markdown documents from Stata output. While MarkDoc is powerful, it requires users to adopt a different workflow paradigm where they write Markdown syntax directly in their do-files using special comment structures. This approach changes the way users structure their code and requires learning new syntax conventions.

Stata_log2html maintains the familiar Stata workflow while adding reporting capabilities through simple marker commands like `ishere`, requiring minimal changes to existing code.

### 3.3 dyntext vs. Stata_log2html

Stata's built-in `dyntext` command allows for dynamic document generation using template files. However, `dyntext` requires users to maintain separate template files alongside their do-files, creating additional complexity and potential synchronization issues. The template-based approach also limits flexibility in controlling exactly where results appear in the final document.

Stata_log2html keeps everything within the do-file, using `ishere` to mark insertion points directly in the code where results are generated, providing more granular control over document structure.

### 3.4 Integration with External Tools

External tools like Jupyter Notebooks with Stata kernels or RMarkdown with Stata chunks require users to abandon their familiar Stata environment and learn new interfaces. These solutions often require additional software installations and configuration, creating barriers to adoption.

Stata_log2html operates entirely within Stata, requiring no additional software or changes to the user's computational environment.

## 4. Step-by-Step Usage Examples

The following examples demonstrate the practical application of the Stata_log2html package, progressing from basic to advanced usage.

### 4.1 Starting with the Simplest Example

The most basic workflow involves creating a log file and converting it to HTML:

```
* 1. Start a log
log using "report.md", replace text
* 2. Add one ishere to the log
ishere ```
* 3. do as you normally would
    sysuse auto, clear
    summarize price mpg
    scatter price mpg
    regress price mpg
* 4. Close log and convert
capture log close
markdown2 "report.md", replace html("report.html") css(githubstyle)
```

This basic workflow creates a report with headers, code blocks, and output. The `ishere` command creates a header section in the Markdown output.

### 4.2 Adding Titles and Narrative Text

Building on the basic example, users can add structured content with titles and narrative text:

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
*   8. Close log and convert
capture log close
markdown2 "report.md", replace html("report.html") css(githubstyle)
```

This example demonstrates how to structure a report with headers using `ishere`.

### 4.3 Incorporating Embedded Tables and Figures

For more sophisticated reports, users can embed tables and figures directly:

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
*   8. Close log and convert
capture log close
markdown2 "report.md", replace html("report.html") css(githubstyle)
```

This example shows how to use `logout4` for summary statistics, `graph2md` for figures, and `outreg3` for regression tables, all of which are embedded in the final report.

### 4.4 Using Clean Mode

For cleaner reports that focus on narrative and results rather than console output, users can employ the clean mode:

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
*   8. Close log and convert
capture log close
markdown2 "report.md", clean replace html("report.html") css(githubstyle)
```

The `clean` option removes extraneous console output, creating a more polished report focused on results and interpretation.

## 5. Advanced Features and Practical Applications

### 5.1 Path Management

The `rpath()` and `wpath()` options in `markdown2` allow for flexible resource path management, particularly useful when deploying reports to web servers or sharing across different computing environments.

### 5.2 Code Block Control

The `ishere` command provides fine-grained control over Markdown code fences, allowing users to specify exactly where code blocks begin and end in the final document. Different options include:

- `ishere 0` or `ishere end`
- `ishere out`: Specifically for ending code blocks after embedded content
- `ishere # Title`: Creates a header

### 5.3 Practical Applications

The Stata_log2html package has proven valuable in several contexts:

1. **Academic Research**: Generating reproducible manuscripts with integrated code, results, and interpretation
2. **Consulting Reports**: Creating client-ready reports that demonstrate analytical transparency
3. **Teaching Materials**: Developing interactive course materials that combine instruction with executable examples
4. **Internal Documentation**: Producing technical documentation for statistical procedures within organizations

## 6. Advantages and Benefits

The Stata_log2html package offers several advantages over traditional reporting methods:

1. **Workflow Continuity**: Researchers maintain their familiar Stata environment without learning new tools or languages.

2. **Automated Reproducibility**: Reports update automatically when the underlying do-file is modified, eliminating the risk of documentation becoming outdated.

3. **Professional Output**: Generated HTML reports include syntax highlighting, mathematical equation support, and responsive design.

4. **Flexible Content Types**: The package handles code, output, tables, figures, and narrative text in a unified framework.

5. **Customizable Styling**: Built-in CSS templates and MathJax integration provide professional appearance without additional configuration.

6. **Cross-Platform Compatibility**: The generated HTML reports work across different platforms and browsers.

## 7. Conclusion

The Stata_log2html package represents a significant advancement in Stata-based reproducible research workflows. By maintaining the familiar do-file environment while adding sophisticated reporting capabilities, it removes barriers that traditionally prevented researchers from adopting reproducible practices.

The zero-intrusion design philosophy ensures that users can adopt the package incrementally, starting with simple reports and gradually incorporating more advanced features. The combination of the `ishere` command for precise content placement and the `markdown2`/`tohtml` converter for professional output makes it an attractive solution for researchers seeking to enhance the presentation of their analytical work.

The package addresses a critical gap in the Stata ecosystem by providing a native solution for report generation that doesn't require users to adopt external tools or change their established workflows. This approach significantly lowers the barrier to reproducible research adoption, particularly for researchers who rely heavily on Stata for their analytical work.

Future developments may include enhanced integration with version control systems, additional output formats, and expanded customization options. The package's modular design facilitates such enhancements while maintaining backward compatibility.

The Stata_log2html package successfully bridges the gap between rigorous statistical analysis in Stata and professional report generation, supporting the broader goals of reproducible research in the statistical community. Its emphasis on maintaining user workflow familiarity while enhancing output quality makes it a valuable addition to the Stata user's toolkit.

The package's success demonstrates that thoughtful integration of reporting capabilities within existing analytical environments can achieve better adoption rates than requiring users to migrate to entirely new systems. This approach may serve as a model for similar tools in other statistical computing environments.

## References

- Jann, B. (2005). Making regression tables from stored estimates. German Stata Users Group meeting 2005. Available from: https://ideas.repec.org/p/bss/ecostat/2005-1.html
- Jann, B. (2007). Making regression tables simplified. German Stata Users Group meeting 2007. Available from: https://ideas.repec.org/p/bss/ecostat/2007-1.html
- Jann, B. (2011). Plotting regression coefficients and other estimates in Stata. The Stata Journal, 11(2), 215-232.
- Baum, C. F. (2009). A little bit of everything: Stata graphics with style. The Stata Journal, 9(4), 615-621.
- Cox, N. J. (2002). Speaking Stata: How to face lists with fortitude. The Stata Journal, 2(2), 202-222.
- Western, B., & Jackman, S. (1994). Bayesian inference for comparative research. American Political Science Review, 88(2), 412-423.
- Long, J. S. (1997). Regression models for categorical and limited dependent variables. Sage Publications.
- Cameron, A. C., & Trivedi, P. K. (2005). Microeconometrics: methods and applications. Cambridge University Press.

## Author Information

Kerry Du
Research Associate
Email: kerrydu@example.com

The Stata_log2html package is available for installation directly from GitHub:

```stata
net install stata_log2html, from("https://github.com/kerrydu/Stata_log2html")
```

For documentation and examples, visit the project repository at https://github.com/kerrydu/Stata_log2html

The package includes comprehensive help files accessible within Stata using the standard `help` command (e.g., `help ishere`, `help markdown2`).

---

*Manuscript received: January 16, 2026*
*Accepted for publication: [Date]*

---
title: "Everything is here: From do to html"
author: "Kerry Du"
affiliation: "School of Management, Xiamen University"
contact: "kerrydu@xmu.edu.cn"
date: "January 2026"
---

# Everything is here: From do to html

## Abstract

This paper introduces `ishere` and `tohtml`, two Stata commands designed to automate the conversion of Stata do-files and log files into clean, formatted HTML reports. The commands address a critical need in reproducible research: producing publication-ready reports directly from standard Stata workflows. The design philosophy, captured in the phrase "everything is here: from do to html," emphasizes minimalist implementation and zero-intrusion operation. Users mark key locations in their do-files with simple `ishere` commands, run their analyses as usual, and use `tohtml` to transform the log into a professional HTML report—all without leaving the Stata environment or adopting new programming paradigms. The package requires minimal learning investment, maintains backward compatibility with existing workflows, and produces professional output with LaTeX math support, syntax highlighting, and responsive design.

**Keywords**: Stata, reproducible research, dynamic documents, HTML reports, literate programming

## 1. Introduction

Reproducible research has become a cornerstone of modern statistical analysis, requiring seamless integration of code, results, and narrative into comprehensive reports. In the Stata ecosystem, researchers traditionally face challenges when attempting to create publication-ready documents that combine analysis code, results, and interpretive text. 

Several solutions exist within Stata, including the built-in `dyndoc` and `dyntext` commands, as well as community-contributed packages like MarkDoc (Haghish, 2016). While these tools are valuable, they often require users to adopt specific syntax conventions, maintain separate template files, or fundamentally change their analytical workflows. External solutions like Jupyter notebooks with Stata kernels or RMarkdown with Stata chunks offer powerful capabilities but require researchers to abandon their familiar Stata environment entirely.

This paper introduces a different approach embodied in two commands: `ishere` and `tohtml`. The package addresses the reporting challenge through a minimalist design philosophy captured in the phrase "everything is here: from do to html":

- **"is here"** refers to the `ishere` command, which marks where elements belong in the report
- **"to html"** refers to the `tohtml` command, which converts marked logs into professional reports
- **"everything"** emphasizes that all necessary components—code, results, and report structure—live together in a single do-file

The key innovation lies in maintaining extreme simplicity and zero-intrusion operation. Users continue writing standard Stata do-files, adding only occasional `ishere` markers to indicate report structure. There are no new file types to learn, no external dependencies to install, and no fundamental changes to existing workflows. The learning curve is minimal: if you can write a Stata do-file, you can generate professional HTML reports.

This paper describes the design principles, core functionality, and practical usage of the `ishere`/`tohtml` package, demonstrating how minimalist design can achieve sophisticated reporting capabilities while respecting users' established workflows.

## 2. Methodology and Features

### 2.1 Design Philosophy: Zero-Intrusion, Minimal Learning

The `ishere`/`tohtml` package is built on three core principles:

**1. Zero-Intrusion Design**: Users maintain their standard Stata workflow without adopting new programming paradigms. The commands act as auxiliary markers that do not interfere with data manipulation or statistical analysis. A do-file with `ishere` markers remains a valid, executable Stata script that produces identical statistical results whether or not the markers are processed.

**2. Minimal Learning Investment**: The entire command set can be learned in minutes. Basic usage requires understanding only two commands (`ishere` and `tohtml`) with intuitive syntax. Advanced features remain optional and can be adopted incrementally as needs arise.

**3. Single-Source Workflow**: All components of the report—code, results, figures, tables, and structural markers—reside in a single do-file. There are no separate template files to maintain, no external configuration files to manage, and no risk of documentation becoming desynchronized from analysis.

### 2.2 The `ishere` Command: Dynamic Placeholders

The name `ishere` draws inspiration from a long-standing convention in academic and technical writing: the humble placeholder note like "Table 1 goes here" or "Figure inserted here." For decades, researchers have used such phrases to mark where results should appear in a manuscript—especially when figures and tables are generated separately from the main text.

In reproducible research with Stata, `ishere` transforms this passive convention into an active, executable placeholder. It literally means "insert something here, on this line, in this do-file."

**Mode 1: Placeholder Syntax (Passive Markers)**

In this mode, `ishere` produces no visible output during execution but leaves markers in the log file that `tohtml` later interprets:

```stata
ishere                    // Mark code block boundary
ishere ```                // Alternative code block marker
ishere # Main Title       // Insert markdown heading
ishere ## Subtitle        // Insert subheading
ishere /*                 // Begin text block
ishere */                 // End text block
ishere tab                // Mark table insertion point
ishere fig                // Mark figure insertion point
```

These markers act as structural hints to the conversion engine, indicating how to organize content in the final report.

**Mode 2: Markdown Insertion Syntax (Active Generation)**

In this mode, `ishere` actively generates markdown/HTML code that appears in the log file:

```stata
// Insert figure with default settings
ishere fig using "scatter.png"

// Insert figure with zoom control
ishere fig using "scatter.png", zoom(80%)

// Insert figure with custom dimensions
ishere figure using "scatter.png", height(400px) width(600px)

// Insert HTML table
ishere tab using "results.html"

// Insert table with custom iframe dimensions
ishere table using "results.html", height(500px) width(100%)
```

This mode supports various image formats (PNG, JPG, JPEG, SVG, GIF, BMP, WEBP) and HTML tables embedded via iframes.

### 2.3 The `tohtml` Command: Log-to-HTML Conversion Engine

The `tohtml` command transforms Stata log files containing `ishere` markers into formatted HTML reports. It is specifically designed to work hand-in-hand with `ishere`, completing the "from do to html" workflow.

**Basic Syntax**:

```stata
tohtml filename_or_directory [, options]
```

**Key Features**:

1. **Intelligent Parsing**: Distinguishes between code, output, headings, and embedded elements in log files
2. **Multiple Modes**: Supports standard (detailed), clean (minimal), and cleancode (merged) output modes
3. **Professional Styling**: Built-in GitHub-style CSS and MathJax support for mathematical equations
4. **Path Management**: Flexible resource path replacement for portable reports
5. **Directory Processing**: Can process entire directories of figures and tables automatically

**Three Output Modes**:

- **Standard Mode** (default): Preserves all code and output, creating comprehensive documentation
- **Clean Mode** (`clean` option): Retains only headings, figures, tables, and text blocks, removing code and console output
- **Cleancode Mode** (`cleancode(dofile)` option): Uses clean code from the original do-file while displaying execution results from the log

### 2.4 Workflow Integration

The typical workflow follows these steps:

1. Write a standard Stata do-file with `ishere` markers
2. Run the do-file with logging enabled (`log using`)
3. Convert the SMCL log to text format (`translate`)
4. Process with `tohtml` to generate HTML

This workflow requires no specialized editors, no external compilation tools, and no changes to the underlying statistical analysis. The report generation happens as a post-processing step, completely separate from the analysis itself.

### 2.5 Comparison with Alternative Solutions

**vs. dyndoc/dyntext**: Stata's built-in dynamic document commands require maintaining separate template files and learning specialized syntax. The `ishere`/`tohtml` approach keeps everything in the do-file and uses minimal additional syntax.

**vs. MarkDoc**: MarkDoc requires writing markdown syntax directly in do-file comments and adopting a specific workflow paradigm. The `ishere`/`tohtml` approach uses simple marker commands and preserves standard Stata workflow.

**vs. Jupyter/RMarkdown**: These external tools require abandoning the Stata environment entirely and installing additional software. The `ishere`/`tohtml` approach operates entirely within Stata with no external dependencies.

The key differentiator is the zero-intrusion principle: users can continue their existing workflows with minimal modification while gaining professional reporting capabilities.

## 3. Step-by-Step Usage Examples

This section demonstrates practical usage progressing from basic to advanced applications.

### 3.1 Basic Example: First Report in Five Minutes

The simplest possible workflow creates a report with code, output, and basic structure:

```stata
* Start logging
log using "my_first_report.smcl", replace

* Add a title
ishere # My First Data Analysis

* Mark code block
ishere

* Perform standard analysis
sysuse auto, clear
summarize price mpg weight
regress price mpg weight

* Close log
log close

* Convert to HTML
translate my_first_report.smcl my_first_report.md, translator(smcl2log) replace
tohtml my_first_report.md, html(my_first_report.html) css(githubstyle) replace
```

This example demonstrates the minimal learning investment required: add one `ishere` command for the title, one for the code block, and run `tohtml` for conversion. The entire workflow can be learned in minutes.

### 3.2 Structured Report with Multiple Sections

Building on the basic example, add section headings to organize content:

```stata
log using "analysis_report.smcl", replace

ishere # Automobile Data Analysis
ishere ## Data Description

ishere
sysuse auto, clear
describe
summarize
ishere

ishere ## Price Analysis

ishere
summarize price, detail
histogram price, frequency
ishere

ishere ## Regression Analysis

ishere
regress price mpg weight foreign
ishere

log close
translate analysis_report.smcl analysis_report.md, translator(smcl2log) replace
tohtml analysis_report.md, html(analysis_report.html) css(githubstyle) replace
```

This example shows how `ishere` markers create document structure without interfering with the analysis code. The statistical commands remain unchanged from what you would normally write.

### 3.3 Embedding Figures and Tables

For professional reports, embed figures and HTML tables directly:

```stata
log using "full_report.smcl", replace

ishere # Complete Analysis Report
ishere ## Data Overview

ishere
sysuse auto, clear
summarize
ishere

ishere ## Price Distribution

scatter price mpg
graph export "scatter.png", replace
ishere fig using "scatter.png", zoom(80%)

ishere ## Regression Results

regress price mpg weight foreign
* Assume outreg3 or similar command exports to HTML
outreg3 using "regression_table.html", replace html
ishere tab using "regression_table.html"

log close
translate full_report.smcl full_report.md, translator(smcl2log) replace
tohtml full_report.md, html(full_report.html) css(githubstyle) replace
```

Note how figures and tables are inserted at their logical positions in the narrative using `ishere fig` and `ishere tab`. The syntax is intuitive and requires no special knowledge of HTML or markdown.

### 3.4 Clean Mode for Presentation Reports

For reports emphasizing results over console output, use clean mode:

```stata
log using "presentation.smcl", replace

ishere # Analysis Summary
ishere /*
* This report presents key findings from our automobile data analysis.
* We focus on the relationship between price, fuel efficiency, and weight.
ishere */

ishere ## Key Statistics
* Generate summary table (assuming it exports to HTML)
tabstat price mpg weight, statistics(mean sd min max) save
ishere tab using "summary_stats.html"

ishere ## Price vs. Efficiency
scatter price mpg
graph export "scatter.png", replace
ishere fig using "scatter.png", zoom(75%)

ishere ## Main Results
regress price mpg weight
ishere tab using "main_results.html"

log close
translate presentation.smcl presentation.md, translator(smcl2log) replace
tohtml presentation.md, clean html(presentation.html) css(githubstyle) replace
```

The `clean` option removes all console output and code blocks, keeping only headings, narrative text (from `ishere /* */` blocks), figures, and tables. This mode is ideal for client reports or presentations where the focus is on results rather than technical details.

### 3.5 Cleancode Mode for Technical Documentation

For documentation that combines clean code with execution results:

```stata
* Create the do-file: analysis.do
* (This file contains clean, well-commented code with ishere markers)

log using "analysis.smcl", replace
do analysis.do
log close

translate analysis.smcl analysis.md, translator(smcl2log) replace
tohtml analysis.md, cleancode(analysis.do) html(analysis.html) ///
    css(githubstyle) replace
```

The `cleancode()` option uses the original do-file's clean code while displaying the execution results from the log. This mode is perfect for teaching materials or technical documentation where code readability matters.

### 3.6 Advanced: Path Management for Portable Reports

When sharing reports across different systems or deploying to web servers, use path management:

```stata
* Local analysis with absolute paths
log using "report.smcl", replace
ishere # Analysis Report

scatter price mpg
graph export "C:/Users/myname/project/figures/scatter.png", replace
ishere fig using "C:/Users/myname/project/figures/scatter.png"

log close

* Convert with path replacement
translate report.smcl report.md, translator(smcl2log) replace
tohtml report.md, html(report.html) css(githubstyle) ///
    rpath("C:/Users/myname/project/figures") wpath("./figures") replace
```

The `rpath()` and `wpath()` options replace absolute paths with relative paths, making the report portable across different systems. This feature is essential for collaborative projects or web deployment.

### 3.7 Processing Entire Directories

For batch processing multiple outputs, point `tohtml` at a directory:

```stata
* Generate multiple outputs to a directory
mkdir output
scatter price mpg
graph export "output/figure1.png", replace
scatter price weight  
graph export "output/figure2.png", replace
* Export tables to output directory...

* Process entire directory
tohtml "output/", html(combined_report.html) zoom(80%) replace
```

The command automatically collects all files starting with "table" (HTML) and "figure" (images) in the directory, creating a consolidated report. This mode is useful for large-scale analyses generating many outputs.

## 4. Technical Implementation

### 4.1 Parsing Strategy

The `tohtml` command employs a multi-stage parsing strategy:

1. **Line-by-line reading** of the translated log file
2. **Prefix removal** of Stata control characters (`{txt}`, `{res}`, `{com}`, etc.)
3. **Marker recognition** to identify `ishere` commands and their types
4. **Code block inference** to determine where code sections begin and end
5. **HTML/markdown merging** for multi-line embedded elements
6. **Path normalization** for cross-platform compatibility

The parser is implemented in Mata for performance and uses vectorized operations wherever possible to handle large log files efficiently.

### 4.2 CSS and MathJax Integration

When using the `css(githubstyle)` option, `tohtml` automatically:

- Generates GitHub-style CSS for professional appearance
- Injects MathJax library for LaTeX mathematical notation support
- Creates responsive design that works across devices
- Provides syntax highlighting for code blocks

Users can also provide custom CSS files for organizational branding or specific formatting requirements.

### 4.3 File Format Support

**Input formats**:
- SMCL log files (translated to text via `translate` command)
- Plain text log files (generated with `log using filename, text`)

**Output formats**:
- Cleaned Markdown (.md)
- HTML with embedded CSS and JavaScript (.html)

**Embedded element formats**:
- Images: PNG, JPG, JPEG, SVG, GIF, BMP, WEBP
- Tables: HTML files (embedded via iframe)

## 5. Advantages and Practical Applications

### 5.1 Key Advantages

**1. Minimal Learning Curve**: The entire package can be learned in 15-30 minutes, with basic usage requiring only 2-3 commands.

**2. Zero Workflow Disruption**: Existing do-files require minimal modification. Analysis code remains completely unchanged.

**3. Reproducibility by Design**: Every report regeneration reflects the current state of the analysis, eliminating documentation drift.

**4. Professional Output**: Generated reports include syntax highlighting, mathematical notation support, responsive design, and clean typography.

**5. Platform Independence**: HTML reports work across Windows, Mac, Linux, and mobile devices without modification.

**6. Incremental Adoption**: Users can start with basic features and gradually incorporate advanced capabilities as needs evolve.

**7. Collaboration Friendly**: Reports can be easily shared via email, web hosting, or internal documentation systems.

### 5.2 Practical Applications

**Academic Research**: Generate supplementary materials, technical appendices, or even complete manuscripts with integrated analysis and results. The approach ensures that published results can be exactly reproduced from the provided code.

**Consulting and Client Reports**: Create professional deliverables that demonstrate analytical transparency while maintaining readability for non-technical audiences. The clean mode is particularly valuable for client-facing documents.

**Teaching Materials**: Develop course materials that combine explanation with executable examples. Students can run the same code to verify results and learn by experimentation.

**Internal Documentation**: Produce technical documentation for analytical procedures within organizations, ensuring that methodology remains current as procedures evolve.

**Regulatory Compliance**: Generate audit trails that document exactly what analysis was performed, with code and results tightly integrated.

### 5.3 Integration with Existing Packages

The `ishere`/`tohtml` package works seamlessly with other Stata commands that export results:

- **outreg2/outreg3/esttab**: Export regression tables to HTML
- **tabout**: Generate formatted tables
- **coefplot**: Create coefficient plots
- **graph export**: Save any Stata graph

This integration means users can leverage the full Stata ecosystem while gaining enhanced reporting capabilities.

## 6. Conclusion

The `ishere` and `tohtml` commands represent a successful implementation of minimalist design principles in statistical computing tools. By maintaining strict adherence to zero-intrusion operation and minimal learning requirements, the package lowers the barrier to reproducible research adoption while producing professional-quality output.

The design philosophy—"everything is here: from do to html"—emphasizes keeping all analysis components in a single location and providing a straightforward path from code to publication-ready documentation. This approach respects users' existing workflows and expertise while adding sophisticated reporting capabilities.

The package addresses a critical gap in the Stata ecosystem: the need for native report generation that doesn't require external tools, template files, or fundamental workflow changes. By succeeding in this goal, it demonstrates that thoughtful tool design can achieve feature richness without complexity.

### 6.1 Future Directions

Potential enhancements include:

- Additional output formats (PDF, Word)
- Enhanced integration with version control systems
- Expanded customization options for styling
- Support for interactive elements in HTML output
- Template system for organizational standardization

The modular design facilitates these enhancements while maintaining backward compatibility and the core principle of simplicity.

### 6.2 Availability

The package is available for installation from GitHub:

```stata
net install stata_log2html, ///
    from("https://github.com/kerrydu/Stata_log2html")
```

Comprehensive documentation is available through Stata's standard help system:

```stata
help ishere
help tohtml
```

Source code, examples, and issue tracking are maintained at the project repository: https://github.com/kerrydu/Stata_log2html

## References

Haghish, E. F. (2016). Stata2LaTeX: A dynamic document generator for Stata. *The Stata Journal*, 16(3), 675-691.

Jann, B. (2014). Plotting regression coefficients and other estimates. *The Stata Journal*, 14(4), 708-737.

Koenker, R., & Hallock, K. F. (2001). Quantile regression. *Journal of Economic Perspectives*, 15(4), 143-156.

Rising, W. R. (2008). R Markdown. *Journal of Statistical Software*, 59(10), 1-24.

StataCorp. (2023). *Stata 18 Base Reference Manual*. College Station, TX: Stata Press.

Wickham, H. (2016). *ggplot2: Elegant graphics for data analysis*. Springer-Verlag New York.

---

**Acknowledgments**

The author thanks the Stata community for valuable feedback during package development and testing. Special thanks to early adopters who provided crucial insights for improving usability and documentation.

**Author Contact**

Kerry Du  
School of Management  
Xiamen University  
kerrydu@xmu.edu.cn

**Manuscript Information**

Submitted: January 2026  
Revised: [Date]  
Accepted: [Date]

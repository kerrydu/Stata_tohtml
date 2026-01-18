---
title: "Everything is here: From do to html"
author: "Kerry Du"
affiliation: "School of Management, Xiamen University"
contact: "kerrydu@xmu.edu.cn"
date: "January 2026"
---

# Everything is here: From do to html

## Abstract

This paper introduces `ishere` and `tohtml`, two Stata commands designed to automate the conversion of Stata do-files and log files into clean Markdown and HTML reports. Unlike existing comprehensive solutions that offer extensive features and polished output, this package deliberately prioritizes simplicity and ease of adoption. The design philosophy, captured in the phrase "everything is here: from do to html," emphasizes minimalist implementation with the lowest possible learning curve. The package generates clean Markdown as a semi-finished product containing all essential elements that Stata can provide—code, results, figures, and tables—which users can further refine using powerful Markdown editors like Typora, VS Code, or Obsidian. This two-stage workflow (Stata-to-Markdown, then Markdown-to-final-document) offers flexibility and leverages the strengths of specialized editing tools while maintaining simplicity in the Stata component. Users mark key locations in their do-files with simple `ishere` commands, run their analyses as usual, and use `tohtml` to transform the log into clean Markdown—all without leaving the Stata environment or adopting new programming paradigms.

**Keywords**: Stata, reproducible research, dynamic documents, Markdown generation, literate programming, workflow integration

## 1. Introduction

Reproducible research has become a cornerstone of modern statistical analysis, requiring seamless integration of code, results, and narrative into comprehensive reports. In the Stata ecosystem, researchers traditionally face challenges when attempting to create publication-ready documents that combine analysis code, results, and interpretive text. 

Several excellent solutions exist within Stata. The built-in `dyndoc` and `dyntext` commands provide sophisticated dynamic document generation with extensive formatting options. Community-contributed packages like MarkDoc (Haghish, 2016) offer powerful features including multiple output formats (PDF, Word, HTML), advanced styling capabilities, and comprehensive markup support. These tools are mature, feature-rich, and capable of producing highly polished, publication-ready documents directly from Stata.

However, these comprehensive solutions necessarily involve learning curves proportional to their feature sets. Users must master specific syntax conventions, understand template systems, or adopt new workflow paradigms. For researchers who need professional output and have time to invest in learning these tools, they represent excellent choices. External solutions like Jupyter notebooks with Stata kernels or RMarkdown with Stata chunks offer even more powerful capabilities but require researchers to work outside their familiar Stata environment entirely.

This paper introduces a different approach embodied in two commands: `ishere` and `tohtml`. Rather than attempting to replicate the comprehensive feature sets of existing solutions, this package deliberately occupies a different niche: **maximum simplicity with minimum learning investment**. The design philosophy is captured in the phrase "everything is here: from do to html":

- **"is here"** refers to the `ishere` command, which marks where elements belong in the report
- **"to html"** refers to the `tohtml` command, which converts marked logs into clean Markdown
- **"everything"** emphasizes that all components Stata can provide—code, results, figures, tables—live together in a single do-file

**The Strategic Trade-off**: We consciously sacrifice feature comprehensiveness for ease of adoption. The package does not attempt to match the polished output or extensive formatting options of MarkDoc or dyndoc. Instead, it focuses on generating clean Markdown as a **semi-finished product** that contains all essential elements extracted from Stata. 

**The Two-Stage Workflow**: Users can then leverage powerful, user-friendly Markdown editors—such as Typora, VS Code, Obsidian, or Notion—to refine the Markdown into their final document. These editors offer intuitive interfaces, real-time preview, extensive formatting options, and often require no coding knowledge. This division of labor plays to the strengths of each tool: Stata extracts analytical content, specialized editors handle document polishing.

The key innovation lies in maintaining extreme simplicity in the Stata component. Users continue writing standard Stata do-files, adding only occasional `ishere` markers to indicate report structure. There are no new file types to learn, no external dependencies to install, and no fundamental changes to existing workflows. The learning curve is minimal: if you can write a Stata do-file, you can generate clean Markdown in minutes.

This paper describes the design principles, core functionality, and practical usage of the `ishere`/`tohtml` package, demonstrating how deliberate simplicity can serve as an entry point to reproducible research workflows while maintaining flexibility through integration with external editing tools.

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

This section acknowledges the strengths of existing solutions while clarifying our package's distinct positioning.

**vs. dyndoc/dyntext**: Stata's built-in dynamic document commands are powerful, mature solutions offering sophisticated templating, conditional content, and direct generation of multiple output formats. They produce polished documents with professional styling out-of-the-box. However, they require maintaining separate template files (`.dyndoc`, `.dyntext`) and learning specialized syntax including tag structures and template logic. 

The `ishere`/`tohtml` approach keeps everything in the do-file using minimal marker syntax, trading the comprehensive features of dyndoc/dyntext for simplicity and faster adoption. Our output (clean Markdown) is deliberately a semi-finished product, suitable for users who prefer to do final formatting in more intuitive Markdown editors.

**vs. MarkDoc**: MarkDoc is an excellent, feature-rich package offering multiple output formats (HTML, PDF, LaTeX, Word, EPUB), extensive styling options, Markdown dialect support, and sophisticated document structure control. It can produce publication-ready documents with beautiful typography and complex layouts. These capabilities make it ideal for users seeking comprehensive, end-to-end solutions.

However, MarkDoc requires writing Markdown syntax directly in do-file comments using special comment delimiters (`/***`, `//`, etc.) and adopting a specific workflow paradigm where the do-file becomes a literate programming document. The `ishere`/`tohtml` approach uses simple marker commands (`ishere # Title`, `ishere fig using...`) that feel more like standard Stata commands, preserving the do-file's primary identity as analysis code rather than document source. We intentionally provide fewer features but dramatically reduce the learning curve.

**vs. Jupyter/RMarkdown**: These external tools are extremely powerful, offering interactive notebooks, multiple language support, extensive visualization libraries, and integration with modern development environments. They represent the gold standard for literate programming and reproducible research in data science.

However, they require abandoning the Stata environment entirely, installing additional software (Python/R, Jupyter/RStudio), learning new interfaces, and managing kernel connections. The `ishere`/`tohtml` approach operates entirely within Stata with no external dependencies, no new software to install, and no context switching between environments.

**Positioning and Philosophy**

We explicitly acknowledge that our package is **less comprehensive** than these established solutions. We do not aim to replace them for users who need their advanced features. Instead, we occupy a deliberate niche:

1. **Simplest possible entry point**: Users can generate useful Markdown reports within 5-10 minutes of learning the package

2. **Semi-finished product strategy**: We extract all elements Stata can provide (code, results, figures, tables) into clean Markdown, then rely on specialized Markdown editors for final document polishing

3. **Tool integration philosophy**: Rather than replicating features that Markdown editors do better (WYSIWYG editing, advanced formatting, document structuring), we produce clean output that leverages these tools' strengths

4. **Incremental adoption**: Users can start with basic Markdown generation and gradually adopt advanced features (clean mode, path management) as needs evolve

The key differentiator is our conscious prioritization of **simplicity over comprehensiveness**, recognizing that for many users, a simple tool they actually use beats a powerful tool they never master.

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

**1. Minimal Learning Curve**: The entire package can be learned in 5-15 minutes, with basic usage requiring only 2-3 commands. This is the primary advantage—users can become productive immediately without substantial time investment in learning documentation or syntax.

**2. Zero Workflow Disruption**: Existing do-files require minimal modification. Analysis code remains completely unchanged. The package respects users' established practices rather than requiring workflow adaptation.

**3. Semi-Finished Product Flexibility**: The generated Markdown contains all essential Stata-derived elements (code, output, figures, tables) but remains editable in intuitive Markdown editors. Users can apply final polish using tools like:
   - **Typora**: WYSIWYG Markdown editing with beautiful real-time rendering
   - **VS Code**: Powerful editing with extensions and version control integration
   - **Obsidian**: Knowledge management features with Markdown support
   - **Notion/Craft**: Modern document editors with Markdown import
   - **Pandoc**: Command-line conversion to Word, PDF, LaTeX, etc.

**4. Tool Integration Philosophy**: Rather than attempting to replicate features that specialized editors do better (WYSIWYG formatting, advanced styling, document structuring), the package produces clean Markdown that leverages these tools' strengths. This division of labor maximizes efficiency.

**5. Reproducibility by Design**: Every report regeneration reflects the current state of the analysis, eliminating documentation drift. The Markdown output remains traceable to the exact code that produced it.

**6. Platform Independence**: Markdown is universally supported. Generated files work across Windows, Mac, Linux, and mobile devices. Users can choose their preferred editing environment.

**7. Incremental Adoption**: Users can start with the simplest workflow (basic Markdown generation) and gradually adopt advanced features (clean mode, cleancode mode, path management) as needs evolve. There's no requirement to master all features upfront.

**8. Lower Barrier to Reproducible Research**: By focusing on simplicity rather than comprehensiveness, the package makes reproducible research more accessible to users who might be intimidated by more complex solutions. Getting started is more important than having every feature.

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

The `ishere` and `tohtml` commands represent a deliberate exercise in minimalist design for statistical computing tools. Rather than competing with comprehensive solutions like MarkDoc, dyndoc, or external notebook systems on feature counts, this package occupies a distinct niche: **the simplest possible entry point to reproducible research workflows in Stata**.

### 6.1 Design Philosophy and Trade-offs

We acknowledge that existing solutions (MarkDoc, dyndoc, dyntext) are more feature-complete and can produce more polished output directly. These are excellent tools for users who need their advanced capabilities and have time to master them. Our package makes a conscious trade-off: we sacrifice feature comprehensiveness for radical simplicity.

The design philosophy—"everything is here: from do to html"—emphasizes three principles:

1. **Extraction over production**: Extract all Stata-derivable elements (code, results, figures, tables) rather than attempting to produce final documents

2. **Delegation to specialists**: Generate clean Markdown as a semi-finished product, delegating final polishing to tools designed for document editing (Typora, VS Code, Obsidian, etc.)

3. **Minimal intrusion**: Maintain standard Stata workflows with the smallest possible syntax addition

This approach respects a fundamental reality: many users find comprehensive tools overwhelming and never adopt them, while simple tools that solve 80% of needs see widespread use. We target the "quick start, iterate later" segment of users.

### 6.2 The Two-Stage Workflow Advantage

By positioning Markdown generation as an intermediate step rather than final output, we achieve flexibility:

- **Separation of concerns**: Stata handles data analysis and result extraction; specialized editors handle document formatting
- **Tool selection**: Users choose their preferred editing environment rather than being locked into one formatting system
- **Incremental refinement**: Generated Markdown can be progressively enhanced across multiple editing sessions
- **Version control friendly**: Markdown is plain text, facilitating Git integration and collaborative editing

This strategy acknowledges that while we cannot match specialized document production tools in their domain, we can provide clean, structured input that maximizes their effectiveness.

### 6.3 Success Metrics: Adoption Over Features

The package's success should be measured not by feature parity with comprehensive solutions, but by:

1. **Time to first useful output**: Can users generate helpful reports within 10 minutes of learning the package?
2. **Adoption rate among non-experts**: Do users who found other solutions too complex successfully use this one?
3. **Sustained usage**: Do users continue generating reports regularly, or abandon the tool after initial enthusiasm?
4. **Gateway effect**: Does this package serve as an entry point, with users eventually graduating to more sophisticated tools when needs grow?

By these metrics, we believe deliberate simplicity serves users better than feature proliferation.

### 6.4 Relationship to Existing Ecosystem

This package is not intended to replace MarkDoc, dyndoc, or other comprehensive solutions. Instead, it serves complementary purposes:

- **Entry point**: Users start here, graduate to more powerful tools as needs grow
- **Quick prototyping**: Rapid Markdown generation for exploratory analysis documentation
- **Integration component**: Clean Markdown output feeds into existing documentation pipelines
- **Teaching tool**: Simplicity makes it suitable for introducing reproducible research concepts

We view the Stata documentation ecosystem as offering a spectrum of tools, from simple (this package) to comprehensive (MarkDoc) to external (Jupyter), each serving different use cases and user preferences.

### 6.5 Future Directions

Potential enhancements will maintain the simplicity-first principle:

- **Improved Markdown cleaning**: Better handling of edge cases in log parsing
- **Enhanced path management**: More flexible resource file handling
- **Integration helpers**: Utilities for common Markdown editor workflows
- **Documentation expansion**: More examples of two-stage workflow (Stata → Markdown → Final Document)

Notably absent from this list: feature additions that would significantly increase complexity. The modular design facilitates targeted improvements while maintaining the core principle of simplicity.

### 6.6 Final Thoughts

The package succeeds if it enables users to take their first steps toward reproducible research workflows without overwhelming them. By acknowledging that we're not trying to do everything—just the Stata-specific parts well—we create space for users to leverage the broader ecosystem of excellent Markdown tools. This humility in scope is a feature, not a limitation.

### 6.7 Availability and Recommended Complementary Tools

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

**Recommended Markdown Editors for Second-Stage Refinement**:

- **Typora** (https://typora.io): Seamless WYSIWYG Markdown editing, excellent for non-technical users
- **VS Code** (https://code.visualstudio.com): Powerful editing with preview, version control, and extensions
- **Obsidian** (https://obsidian.md): Knowledge base features with excellent Markdown support
- **Pandoc** (https://pandoc.org): Command-line tool for converting Markdown to Word, PDF, LaTeX, etc.

The two-stage workflow (Stata → Markdown → Final Document) allows users to choose the editing environment that best fits their preferences and requirements.

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

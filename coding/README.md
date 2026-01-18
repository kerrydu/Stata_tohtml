# Stata_log2html Package

**Stata_log2html** is a lightweight toolkit for automating the conversion of Stata log files into clean, formatted Markdown and HTML reports. It streamlines the reproducible research workflow by integrating code, output, tables, and figures into a single document.

## Description

This package specifically addresses the need to produce readable reports directly from Stata workflow logs without requiring external compilation tools like Jupyter or RMarkdown. It parses the Stata log file to distinguish between code, output, and added narrative, producing high-quality Markdown that can be rendered to HTML with LaTeX math support.

## Demo Video

Watch a demonstration of the stata_log2html workflow:

[![Demo Video](https://img.shields.io/badge/▶-Watch%20Demo%20Video-blue)](https://github.com/kerrydu/Stata_log2html/raw/main/Stata_log2html.mp4)

Or view the video directly: [Stata_log2html.mp4](Stata_log2html.mp4)

*Note: Click the link above to view the video, or download it from the repository root.*

![Demo Video](https://github.com/kerrydu/Stata_log2html/raw/main/Stata_log2html.gif)

👉 [minido.do例子运行结果](https://kerrydu.github.io/Stata_log2html/)




## Key Advantage

The biggest strength of **stata_log2html** is its **Zero-Intrusion** design.

*   **100% Do-file Based**: All operations remain within your standard Stata `.do` files. You don't need to switch to notebooks or external text editors.
*   **Preserves Workflow**: It does not change how you write or run Stata code. Your analysis logic remains untouched.
*   **Marker-Based**: Commands like `_textcell` and `cmdcell` act merely as auxiliary markers. They leave structural hints in the log file without interfering with your data or statistics.
*   **Reproducible**: Since the report is generated every time you run your do-file, your documentation never falls out of sync with your results.

## Installation

You can install the package directly from the repository or by copying the files to your ADO path.

```stata
net install stata_log2html, from("https://github.com/kerrydu/Stata_log2html")
```

## Workflow Guide

For a detailed guide on how to structure your project and use these tools together, please see [**WORKFLOW.md**](WORKFLOW.md).

## Included Commands

The package consists of the following tools:

### Core Converter
* **`markdown2`**: The primary engine that converts a Stata log file (`.log` or `.smcl` converted to text) into Markdown (`.md`) and HTML. It supports:
    * Code syntax highlighting.
    * LaTeX math formatting (via MathJax).
    * Automatic cleaning of Stata prompts (`.` and `>`).
    * Integration of external HTML/Image assets.

### Output Helpers
* **`graph2md`**: Exports the current graph to PNG and automatically inserts the Markdown image syntax into the log.
* **`outreg3`** **`logout3`**: Enhances regression table exports for direct compatibility with the Markdown output.
* **`logout4`**: logout results and converts it to html.
* **`_textcell`**: Allows insertion of blocks of raw text, Markdown, or LaTeX math (e.g., `$$ y = mx + b $$`) directly from the do-file into the final report.
* **`ishere`**: Provides manual control over Markdown headers, figures, and tables insertion (e.g., `### Header`, `ishere fig using "image.png"`, `ishere tab using "table.html"`). Use `ishere out` after `outreg3` or `graph2md` to ensure correct rendering. (Note: `cmdcell` is now deprecated in favor of `ishere`)

### Utilities
* **`sopen`**: Convenience command to open the generated HTML or Markdown files in the system's default viewer.

### Three Usage Modes
1. Detailed Mode: Captures all Stata output, including console logs, exported HTML tables, and generated figures. (example_detailed.do)
2. Clean Mode: Outputs only titles, textual content, and visual charts. (example_clean.do)
3. Clean Code Mode: Delivers titles, textual content, charts and code blocks, while excluding console output results. (example_clean_code.do)


## Minimal Example

A complete example is available in `minido.do`.

```stata
* 1. Start a log
capture log close
log using "report.md", replace text

* 2. Add narrative text
_textcell /*
## Introduction
This is a study using the auto dataset.
$$ y = \beta x + \epsilon $$
*/ _textcell */

* 3. Run analysis
sysuse auto, clear
regress price mpg

* 4. Export table
outreg3 using "reg_table.tex", replace html
ishere out

* 5. Export figure
histogram price
graph2md, save("hist.png")
ishere out

* 6. Close log and convert
capture log close
markdown2 "report.md", replace html("report.html") css(githubstyle)

* 7. View output
sopen "report.html"
```

## Documentation

Each command includes a help file. Type `help command_name` in Stata for details (e.g., `help markdown2`).


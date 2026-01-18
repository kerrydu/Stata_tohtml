# Stata Markdown Workflow

This document outlines the standard workflow for using the **stata_log2html** package to generate reproducible reports. This workflow allows you to write your analysis in a standard Stata do-file while producing a publication-ready HTML or Markdown document as a byproduct.

## 1. Directory Structure

It is recommended to set up your project with a structure similar to this:

```
project/
├── analysis.do          # Your main do-file
├── results/             # Output folder
│   ├── figures/         # Saved PNG/SVG graphs
│   ├── logs/            # Raw Stata logs
└── report.html          # Final output
```

## 2. Setup (In Stata Do-file)

Initialize your paths and start a text log file. The log file must be in text format (`text` option), not SMCL.

```stata
version 17.0
global results "./results"
capture mkdir "$results"

capture log close
log using "$results/report.log", replace text
```

## 3. Writing Content

### A. Narrative and Headers
Use `_textcell` to inject paragraphs, lists, mathematical equations (LaTeX), or external images that are not produced by Stata.
Use `ishere` to insert headers or manage code blocks manually.

```stata
ishere ### 1. Data Cleaning

_textcell /*
We drop observations with missing values to ensure consistency.
The model is defined as:
$$ y_i = \alpha + \beta x_i + \epsilon_i $$
*/ _textcell */
```

### B. Standard Output
Regular Stata commands will appear as code blocks with their output.

```stata
sysuse auto, clear
summarize price mpg
```

### C. Tables (`outreg3`)
Use `outreg3` to generate regression or summary tables that render correctly in the HTML output.

```stata
regress price mpg weight
outreg3 using "$results/table1.tex", replace html
ishere out
```

### D. Figures (`graph2md`)
After generating a graph, use `graph2md` immediately. This exports the graph to an image file and inserts the request Markdown link into the log.

```stata
scatter price mpg
graph2md, replace save("$results/figures/scatter.png") zoom(60)
ishere out
```

## 4. Compilation

At the end of your do-file, close the log and run `markdown2` to generate the report.

```stata
capture log close

markdown2 "$results/report.log", replace ///
    saving("$results/report_clean.md") ///
    html("$results/report.html") ///
    css(githubstyle)
```

## 5. View Result

Open the resulting HTML file.

```stata
sopen "$results/report.html"
```

## Key Commands Summary

| Command | Function |
| :--- | :--- |
| `markdown2` | Converts log to MD/HTML |
| `_textcell` | Block for text/LaTeX/Markdown entry |
| `ishere` | Inserts headers (`#`), figures (`fig using "file.png"`), tables (`tab using "file.html"`) or fences (`0`/`1`) |
| `graph2md` | Exports graph and links it in MD |
| `outreg3` | Formats tables for MD/HTML |
| `sopen` | Opens file in default viewer |

---
name: stata-tohtml
description: >-
  Writes Stata do-files that use ishere markers and converts the log to an HTML
  report with tohtml. Use when the user wants a Stata analysis report, do-file
  plus HTML, ishere/tohtml workflow, figures/tables in a reproducible log, or
  to run a do-file and open the generated HTML.
---

# Stata tohtml reports

One do-file is the source of truth. Mark structure with `ishere`, run the do
under a text log, then call `tohtml` on that log. Do not invent another
markup language. Do not silently `ssc install`.

Need moremata (`mm_outsheet`). `markdown` is built into Stata 16+; it is not
a package. Full template: [examples.md](examples.md).

## Write the do-file

- Paths: forward slashes. `adopath ++` to the folder that contains `tohtml.ado`.
  Use `global` for output dirs and `capture mkdir`.
- Because `profile.do` may `cd` away, use **absolute** paths in the do-file
  (or `cd` to the project at the top).
- Log: `capture log close` → `log using "....log", replace text` → analysis →
  `capture log close` → `tohtml`.
- Headings: `ishere # Title` and `ishere ## Section`. Do not use a bare `#`
  heading in the do-file unless it is inside `/** ... **/`.
- Code blocks: default `tohtml` auto-fences command lines as ` ```stata `.
  Do not wrap code with a lone `ishere`.
- Figures: `graph export "file.png", replace` then immediately
  `ishere fig using "file.png"`. Do not hand-write `<img>`.
- Tables: export HTML first (`table ..., export()` / `collect export` /
  `outreg2e ..., html`), then `ishere tab using "file.html"`.
  Do not hand-write `<iframe>`.
- Narrative: `/**` … `**/` for paragraphs, `$...$` / `$$...$$`, and Markdown images.
- In-text numbers: emit with `ishere display %5.3f \`r2'`, then in the next
  `/**` block write the tag `{ishere display %5.3f \`r2'}` as a **literal**
  (same format string and argument; not a regex).
- Finish with:

```stata
tohtml "report.log", html("report.html") replace
```

Add `mathjax` if the narrative has equations; `zip(.)` to pack css/figures/tables;
`embed` only for a single self-contained HTML file.

Skeleton:

```stata
adopath ++ "PATH/TO/tohtml"
capture log close
log using "report.log", replace text
ishere # Title
* commands
ishere fig using "fig.png"
ishere tab using "tab.html"
capture log close
tohtml "report.log", html("report.html") replace
```

## Run Stata and produce HTML

1. Find the executable: `$STATA_EXE` if set; else search common names
   (`StataMP-64.exe`, `StataNow*`, `stata-mp`, `stata`). If none, stop and
   ask the user for the path.
2. Windows: `"<STATA_EXE>" /e do "ABS/path/file.do"`.
   macOS/Linux: `stata-mp -b do "ABS/path/file.do"` (or that install’s batch flag).
3. Read the `.log`. On `r(` or `error occurred`, fix the do-file and rerun
   (a few times, not endlessly).
4. Confirm the `html()` file exists. If `zip(.)` was used, confirm the zip
   next to the HTML.
5. Open the HTML with the OS handler: Windows `start`, macOS `open`,
   Linux `xdg-open`. Do not depend on an IDE browser.

## Do not

- Change `tohtml.ado` / `ishere.ado` unless the user asked to fix the package.
- `ssc install` without asking.

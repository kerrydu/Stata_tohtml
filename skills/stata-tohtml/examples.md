# Minimal tohtml do-file

Default `tohtml` **auto-fences** Stata commands (lines echoed with `.`) as
` ```stata ` blocks. Do **not** wrap code with a lone `ishere`.
Use `ishere` only for headings, figures, tables, and in-text values.

Copy this, set `root` to the folder that contains `tohtml.ado`, and run it
under Stata 16+ (19+ if you use `table (var) (result)`). Requires moremata
and, for the regression table, `outreg2e` from the same package.

```stata
version 16
clear
set more off

* Folder that contains tohtml.ado (edit this)
local root "C:/path/to/Stata_tohtml"
adopath ++ "`root'"

local out "`root'/report_demo"
capture mkdir "`out'"

capture log close
log using "`out'/report.log", replace text

ishere # Data Preparation
sysuse auto, clear
disp "Observations: `c(N)'"
gen lprice = ln(price)
label var lprice "Log of price"

ishere # Figures
ishere ## Figure 1
histogram price, normal title("Price distribution")
graph export "`out'/price_hist.png", replace
ishere fig using "`out'/price_hist.png"

ishere # Regression
ishere ## Table 1
regress price mpg weight
ishere display %5.3f e(r2)
/**
The R-squared is {ishere display %5.3f e(r2)}.
**/

qui regress price mpg weight i.foreign, vce(robust)
estimates store model1
qui regress price mpg, vce(robust)
estimates store model2
outreg2e [model1 model2] using "`out'/model.html", replace html
ishere tab using "`out'/model.html"

capture log close
tohtml "`out'/report.log", html("`out'/report.html") replace

di as result "DONE"
```

Batch run (absolute path to the do-file):

```text
Windows:  "C:/Program Files/StataNow19/StataMP-64.exe" /e do "C:/path/report_demo.do"
macOS:    stata-mp -b do "/path/report_demo.do"
```

Then open `report.html` with the system browser.

## Optional

- Equations in `/** ... **/`: add `mathjax` to `tohtml`.
- Shareable folder: add `zip(.)` (implies bundle).
- One HTML file only: add `embed`.
- Collect summary table (Stata 17+ / 19):

```stata
table (var) (result), ///
    statistic(mean price mpg) statistic(sd price mpg) nototals ///
    export("`out'/summary.html", replace)
ishere tab using "`out'/summary.html"
```

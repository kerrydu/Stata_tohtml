capture log close
log using "example5.log", text replace

ishere # Output Variant Comparison
sysuse auto, clear

/**
This report summarizes automobile prices and fuel efficiency.
**/

summarize price mpg
regress price mpg weight
estimates store model1
outreg2e [model1] using "table_regression", replace md
ishere tab using "table_regression.md"
log close

tohtml "example5.log", ///
    md("example5_clean.md") ///
    html("example5_clean.html") clean replace
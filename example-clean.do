cd "C:/Users/kerry/Desktop/tohtml/Stata_tohtml"
adopath ++ "C:/Users/kerry/Desktop/tohtml/Stata_tohtml"
clear all
set more off

capture log close
log using "example5.log", text replace

ishere # Output Variant Comparison
sysuse auto, clear

/**
This report summarizes automobile prices and fuel efficiency.
**/

summarize price mpg
scatter price mpg
graph export "scatter.png", replace
ishere fig using "scatter.png", title("Price versus fuel efficiency")

local len 20 
forv i=1/20{
    gen mpg`i' = price
}
regress price mpg* weight
estimates store model1
outreg2e [model1] using "table_regression", replace html
ishere tab using "table_regression.html", title("Regression of price on mpg and weight")
log close

tohtml "example5.log", ///
    md("example5_clean.md") ///
    html("example5_clean.html") ///
    replace
version 19.5
clear
set more off
set linesize 120

adopath ++ "D:/code_test"

// Project paths
global project "D:/code_test"
global results "$project/results"
global figures "$results/figures"
global logs    "$results/logs"

// Create output directories
foreach dir in "$results" "$figures" "$logs" {
    capture mkdir `dir'
}

capture log close
log using "$logs/example_standard.log", replace text

ishere # Data Preparation
sysuse auto, clear
disp "Loaded auto.dta. Observations: `c(N)', Variables: `c(k)'"
drop if missing(price, mpg, weight, foreign)
disp "Dropped missing. Remaining observations: `c(N)'"

// Generate analysis variables
gen lprice   = ln(price)
gen weightkg = weight*0.453592
label var lprice   "Log of price"
label var weightkg "Weight (kg)"
disp "Variables created: lprice, weightkg"


ishere # Descriptive Statistics
ishere ## Table 1
summarize price mpg weight lprice
table (var) (result), ///
      statistic(mean price mpg weight) ///
      statistic(sd   price mpg weight) ///
      nototals ///
      export("$results/summary.html", replace)
ishere tab using "$results/summary.html",title("Descriptive analysis")


ishere # Figures
ishere ## Figure 1
histogram price, normal
graph export "$figures/price_hist.png", replace
ishere fig using "$figures/price_hist.png", title("Price distribution")


ishere ## Figure 2
twoway (scatter price mpg) (lfit price mpg), legend(order(1 "Actual" 2 "Fitted"))
graph export "$figures/price_mpg.png", replace
ishere fig using "$figures/price_mpg.png", title("Price vs MPG with linear fit")


/**
this is a paragraph of text

this is another paragraph of text

this is a third paragraph of text

this is a mathematical expression

$$y = \beta_0 + \beta_1 x_1 + \beta_2 x_2 + \epsilon$$

**/


ishere # Regression
ishere ## Narrative Example
regress price mpg weight
ishere display %5.3f e(r2)
/**
The R-squared is {ishere display %5.3f e(r2)}.
**/


qui regress price mpg weight i.foreign, vce(robust)
estimates store model1

qui regress price mpg , vce(robust)
estimates store model2

qui regress price i.foreign, vce(robust)
estimates store model3

qui regress price mpg weight i.foreign, vce(robust)
estimates store model4

qui regress price mpg weight i.foreign, vce(robust)
estimates store model5

qui regress price mpg weight i.foreign, vce(robust)
estimates store model6

qui regress price mpg weight i.foreign, vce(robust)
estimates store model7

qui regress price mpg weight i.foreign, vce(robust)
estimates store model8

qui regress price mpg weight i.foreign, vce(robust)
estimates store model9

qui regress price mpg weight i.foreign, vce(robust)
estimates store model10

qui regress price mpg weight i.foreign, vce(robust)
estimates store model11

qui regress price mpg weight i.foreign, vce(robust)
estimates store model12

qui regress price mpg weight i.foreign, vce(robust)
estimates store model13


ishere ## Table 2
outreg2e [model1 model2 model3 model4 model5] using "$results/model.html", replace html
ishere tab using "$results/model.html",title("Regression results")


ishere ## Table 3
outreg2e [model*] using "$results/model2.html", replace html
ishere tab using "$results/model2.html",title("Regression analysis")


capture log close
tohtml "$logs/example_standard.log", ///
    md("$logs/example_standard.md") ///
    html("$logs/example_standard.html") ///
    embed mathjax replace

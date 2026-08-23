version 19.5
clear
set more off
set linesize 120

local root "C:/Users/kerry/Desktop/tohtml/Stata_tohtml"
adopath ++ "`root'"

global project "`root'/tests/example_detail"
global results "$project/results"
global figures "$results/figures"
global logs    "$results/logs"

foreach dir in "$project" "$results" "$figures" "$logs" {
    capture mkdir `dir'
}

capture log close
log using "$logs/example_detail.log", replace text

ishere # Data Preparation
ishere
sysuse auto, clear
disp "Loaded auto.dta. Observations: `c(N)', Variables: `c(k)'"

drop if missing(price, mpg, weight, foreign)
disp "Dropped missing. Remaining observations: `c(N)'"

gen lprice   = ln(price)
gen weightkg = weight*0.453592
label var lprice   "Log of price"
label var weightkg "Weight (kg)"
disp "Variables created: lprice, weightkg"

ishere # Descriptive Statistics
ishere ## Table 1
ishere
table (var) (result), ///
    statistic(mean  price mpg weight rep78 lprice) ///
    statistic(sd    price mpg weight rep78 lprice) ///
    statistic(min   price mpg weight rep78 lprice) ///
    statistic(max   price mpg weight rep78 lprice) ///
    nototals ///
    export($results/summary.html, replace)
ishere tab using "$results/summary.html"

ishere
ishere # Figures
ishere ## Figure 1
ishere
histogram price, normal title("Price distribution")
graph export "$figures/price_hist.png", replace
ishere fig using "$figures/price_hist.png"

ishere ## Figure 2
ishere
twoway (scatter price mpg) (lfit price mpg), ///
    title("Price vs MPG with linear fit") legend(order(1 "Actual" 2 "Fitted"))
graph export "$figures/price_mpg.png", replace

ishere fig using "$figures/price_mpg.png"
ishere

/**
this is a paragraph of text

this is another paragraph of text

this is a third paragraph of text

this is a mathematical expression

$$y = \beta_0 + \beta_1 x_1 + \beta_2 x_2 + \epsilon$$

the picture is pretty

![](https://tu.duoduocdn.com/uploads/day_260115/202601150909474420.jpg)

**/

ishere # Regression
ishere ## Narrative Example
ishere
regress price mpg weight
local r2 = e(r2)
display %5.3f `r2'
ishere display %5.3f `r2'
/**
The R-squared is {ishere display %5.3f `r2'}.
**/

ishere
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
ishere

ishere ## Table 2
ishere
outreg2e [model1 model2 model3 model4 model5] using "$results/model.html", replace html
ishere tab using "$results/model.html"

ishere ## Table 3
ishere
outreg2e [model*] using "$results/model2.html", replace html
ishere tab using "$results/model2.html"

capture log close
tohtml "$logs/example_detail.log", ///
    md("$logs/example_detail.md") ///
    html("$logs/example_detail.html") ///
    zip(.) mathjax replace

di as result "DONE"
which tohtml
which ishere
which outreg2e

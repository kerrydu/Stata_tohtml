/* Mini Example: auto.dta
   - Loads auto.dta
   - Cleans minimal
   - Descriptive stats
   - Simple regression
   - Figures export
   - Markdown report
*/


version 17.0
clear 
set more off
set linesize 120


// Project paths
global project "C:/Users/kerry/Desktop/auto-mini"
global results "$project/results"
global figures "$results/figures"
global logs    "$results/logs"

// Create output directories
foreach dir in "$results" "$figures" "$logs" {
    capture mkdir `dir'
}
capture log close
log using "$logs/auto-mini.md", replace text 

ishere ### Data Preparation
ishere 0
/*---------------------------------
Data: sysuse auto
-----------------------------------*/
* "=== Load and Clean ==="
sysuse auto, clear
disp "Loaded auto.dta. Observations: `c(N)', Variables: `c(k)'"

// Minimal cleaning
drop if missing(price, mpg, weight, foreign)
disp "Dropped missing. Remaining observations: `c(N)'"

// Generate analysis variables
gen lprice   = ln(price)
gen weightkg = weight*0.453592
label var lprice   "Log of price"
label var weightkg "Weight (kg)"
disp "Variables created: lprice, weightkg"
ishere 1


ishere ### Descriptive Statistics
ishere #### Table 1

ishere 
summarize price mpg weight lprice

tabstat price mpg weight, by(foreign) statistics(mean sd min max n) columns(statistics)

outreg3  using "$results/summary.tex", replace html sum(log)
ishere out





ishere ### Figures
ishere #### Figure 1
ishere 0
/*--------------------------------
Figures
----------------------------------*/
histogram price, normal title("Price distribution")
graph2md,  replace save( "$figures/price_hist.png")   zoom(30)
ishere out

ishere #### Figure 2
ishere 0
twoway (scatter price mpg) (lfit price mpg), ///
    title("Price vs MPG with linear fit") legend(order(1 "Actual" 2 "Fitted"))
graph2md,  replace save( "$figures/price_mpg.png")   zoom(30)
ishere out

ishere 0
_textcell /*
this is a paragraph of text

this is another paragraph of text

this is a third paragraph of text

this is a mathematical expression

$$y = \beta_0 + \beta_1 x_1 + \beta_2 x_2 + \epsilon$$

the picture is pretty

![](https://tu.duoduocdn.com/uploads/day_260115/202601150909474420.jpg)

_textcell */
ishere 1

ishere ### Regression
ishere 0
/*--------------------------------
Regression
----------------------------------*/

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
ishere 1

ishere #### Table 2
ishere 0
tabhtml: esttab model1 model2 model3 model4 model5 model6 model7 model8 model9 model10 model11 model12 model13 using "$results/model.html", replace
ishere out

ishere #### Table 3
ishere 
outreg3 [model*] using "$results/model2.tex", replace html
ishere out
// ishere 1



// ishere 0
// Optional: predicted values
ishere #### Figure 3
ishere 0
predict price_hat, xb
twoway (scatter price price_hat), ///
    title("Actual vs Predicted (xb)") ///
    xtitle("Actual") ytitle("Predicted")
graph2md,  replace save( "$figures/actual_vs_pred.png") zoom(30)
ishere out


capture log close


ishere ### Report Generation
ishere 0
markdown2  "$logs/auto-mini.md",  replace ///
    html("$results/auto-mini.html") rpath("$results") ///
    css(githubstyle) sav("$results/auto-mini-clean.md")

// markdown2  "$logs/auto-mini.md",  replace ///
//     html("$results/auto-mini.html") rpath("$results") ///
//     cleancode(C:\Users\kerry\Desktop\auto-mini\Stata_log2html\minido.do) ///
//     css(githubstyle) sav("$results/auto-mini-clean.md")
// disp "HTML report generated: $results/auto-mini.html"
// Open HTML in default browser (Windows)
sopen  "$results/auto-mini.html"
ishere 1

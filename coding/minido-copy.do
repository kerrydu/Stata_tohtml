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

// adopath ++ C:\Users\kerry\Desktop\auto-mini\ado
// Project paths
global project "C:/Users/kerry/Desktop/auto-mini"
global results "$project/results"
global figures "$results/figures"
global logs    "$results"

// Create output directories
foreach dir in "$results" "$figures" "$logs" {
    capture mkdir `dir'
}
capture log close
log using "$logs/auto-mini.md", replace text

statacell 

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

/*------------------------------------
Descriptive Statistics
--------------------------------------*/
summarize price mpg weight lprice

//logout, save("$results/descriptives") replace tex : tabstat price weight mpg headroom, statistics(n mean sd min max) columns(statistics)

logout3, save("$results/descriptives") replace excel html : tabstat price weight mpg headroom, statistics(n mean sd min max) columns(statistics) 


/*--------------------------------
Figures
----------------------------------*/
histogram price, normal title("Price distribution")
graph2md,  replace save( "$figures/price_hist.png") zoom(30)

twoway (scatter price mpg) (lfit price mpg), ///
    title("Price vs MPG with linear fit") legend(order(1 "Actual" 2 "Fitted"))
graph2md,  replace save( "$figures/price_mpg.png")  zoom(30)


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

tabhtml: esttab model1 model2 model3 model4 model5 model6 model7 model8 model9 model10 model11 model12 model13 using "$results/model.html", replace

outreg3 [model1 model2 model3 model4 model5 model6] using "$results/model2.doc", replace html title(tab2)

// di `"<iframe src='$results/model.html' width='100%' height='500px' frameBorder='0'></iframe>"'

// Optional: predicted values
predict price_hat, xb
twoway (scatter price price_hat), ///
    title("Actual vs Predicted (xb)") ///
    xtitle("Actual") ytitle("Predicted")
graph2md,  replace save( "$figures/actual_vs_pred.png") zoom(30)
capture log close

/*--------------------------------
Report Generation
----------------------------------*/

// clean rpath in html links
markdown2  "$logs/auto-mini.md", saving("$results/auto-mini2.md") replace html($results/auto-mini.html) rpath($results)
// Open HTML in default browser (Windows)
sopen  "$results/auto-mini.html"

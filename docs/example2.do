capture log close
log using "example2.log", replace text 

ishere # Data Preparation
ishere
sysuse auto, clear
disp "Loaded auto.dta. Observations: `c(N)', Variables: `c(k)'"

// Generate analysis variables
gen lprice   = ln(price)
gen weightkg = weight*0.453592
label var lprice   "Log of price"
label var weightkg "Weight (kg)"
disp "Variables created: lprice, weightkg"

ishere
ishere # Figures
ishere ## Figure 1
ishere
histogram price, normal title("Price distribution")
graph export "price_hist.png", replace
ishere fig using "price_hist.png"

ishere ## Figure 2
ishere 
twoway (scatter price mpg) (lfit price mpg), ///
    title("Price vs MPG with linear fit") legend(order(1 "Actual" 2 "Fitted"))
graph export "price_mpg.png", replace  
ishere fig using "price_mpg.png"

ishere # Regression
ishere ## Table 1
ishere
regress price mpg weight
local r2 = e(r2)
display %5.3f `r2'
* emit the value
ishere display %5.3f `r2'

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

outreg2e [model*] using "model.html", replace html
ishere tab using "model.html"

tohtml "example2.log", clean html("example2.html") css(githubstyle) replace

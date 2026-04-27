capture log close
log using "example3.log", replace text 

# Data Preparation
```
sysuse auto, clear
disp "Loaded auto.dta. Observations: `c(N)', Variables: `c(k)'"

// Generate analysis variables
gen lprice   = ln(price)
gen weightkg = weight*0.453592
label var lprice   "Log of price"
label var weightkg "Weight (kg)"
disp "Variables created: lprice, weightkg"

```
# Figures
## Figure 1
```
histogram price, normal title("Price distribution")
graph export "price_hist.png", replace
```
<img src="price_hist.png" style="zoom:100%;">

## Figure 2
```
twoway (scatter price mpg) (lfit price mpg), ///
    title("Price vs MPG with linear fit") legend(order(1 "Actual" 2 "Fitted"))
graph export "price_mpg.png", replace  
```
<img src="price_mpg.png" style="zoom:100%;">

# Regression
## Table 1
```
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
```
<iframe src='model.html' width='100%' height='400px' frameBorder='0'></iframe>

tohtml "example3.log", cleancode("example3.do")  html("example3.html") css(githubstyle) replace

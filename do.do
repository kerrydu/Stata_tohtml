*****************************例3.3*************************** 
cap log close

log using "example3.log", replace

ishere # Narrative Example
ishere
sysuse auto, clear
regress price mpg weight
local r2 = e(r2)

* emit the value
ishere display %5.3f `r2'

* narrative text 
ishere /*
* The model R-squared is {ishere display %5.3f `r2'}.
ishere */

ishere 
ishere display %5.3f `r2'


ishere /*
* The model R-squared is {ishere display %5.3f `r2'}.
ishere */


log close
tohtml example3.log, html(example3.html) css(githubstyle) replace


*****************************例3.4*************************** 
cap log close 

log using "example4.log", replace

ishere # Complete Analysis Report
ishere ## Data Overview

ishere
sysuse auto, clear
summarize

ishere ## Price Distribution
ishere
scatter price mpg
graph export "scatter.jpg", replace
ishere fig using "scatter.jpg", height(600px) width(900px) // ?

ishere ## Regression Results
ishere
regress price mpg weight foreign
* Assume outreg2e or similar command exports to HTML
outreg2e using "regression_table.html", replace html
ishere tab using "regression_table.html", zoom(30%)

log close
tohtml example4.log, html(example4.html) css(githubstyle) replace

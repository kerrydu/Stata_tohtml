clear all
set more off
capture log close _all
local root "C:/Users/kerry/Desktop/tohtml/Stata_tohtml"
adopath ++ "`root'"
cd "`root'/tests/reviewer27"

sysuse auto, clear
collect clear
table (var) (result), ///
    statistic(mean  price mpg weight rep78) ///
    statistic(sd    price mpg weight rep78) ///
    statistic(min   price mpg weight rep78) ///
    statistic(max   price mpg weight rep78) ///
    nototals ///
    export("summary_full.html", replace)

copy "summary_full.html" "summary_full.raw.html", replace
if fileexists("summary_full.css") {
    copy "summary_full.css" "summary_full.raw.css", replace
}

log using "style_test.log", text replace
ishere # style test
ishere
ishere tab using "summary_full.html"
log close
ishere

copy "summary_full.html" "summary_after_ishere.html", replace

tohtml "style_test.log", md("style_test.md") html("style_test.html") replace
copy "summary_full.html" "summary_after_tohtml.html", replace

tohtml "style_test.log", md("style_embed.md") html("style_embed.html") embed replace
di as result "DONE"

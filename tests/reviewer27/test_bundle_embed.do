clear all
set more off
capture log close _all
local root "C:/Users/kerry/Desktop/tohtml/Stata_tohtml"
adopath ++ "`root'"
cd "`root'/tests/reviewer27"

sysuse auto, clear
collect clear
table foreign, statistic(mean price) statistic(sd price)
collect export "table_fragment.html", tableonly replace
collect export "table_fragment_custom.html", tableonly ///
    cssfile("chosen_fragment.css") replace

capture erase "bundle_test.log"
capture erase "bundle_test.md"
capture erase "bundle_test.html"
capture erase "bundle_test.zip"
capture erase "embed_test.md"
capture erase "embed_test.html"

log using "bundle_test.log", text replace
ishere # Bundle and embed CSS
ishere
ishere tab using "table_fragment.html"
ishere
ishere tab using "table_fragment_custom.html", cssfile("chosen_fragment.css")
log close
ishere

tohtml "bundle_test.log", ///
    md("bundle_test.md") ///
    html("bundle_test.html") zip(.) replace

tohtml "bundle_test.log", ///
    md("embed_test.md") ///
    html("embed_test.html") embed replace

di as result "DONE"

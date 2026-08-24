clear all
set more off
capture log close _all
local root "C:/Users/kerry/Desktop/tohtml/Stata_tohtml"
adopath ++ "`root'"
cd "`root'/tests/from_html"
log using "test_fence_run.log", text replace

ishere ### table 1

ishere table 1 using C:\Users\kerry\Desktop\tohtml\Stata_tohtml\tests\from_html\summary.html

tohtml "example_from_html.log", md("example_from_html.md") html("example_from_html.html") replace
di as result "DONE"
log close

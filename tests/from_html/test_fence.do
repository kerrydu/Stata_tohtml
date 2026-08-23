clear all
set more off
capture log close _all
local root "C:/Users/kerry/Desktop/tohtml/Stata_tohtml"
adopath ++ "`root'"
cd "`root'/tests/from_html"
log using "test_fence_run.log", text replace

capture which pathutil
if _rc {
    di as error "pathutil not found"
    exit 111
}

ishere ### table 1

ishere table 1 using C:\Users\kerry\Desktop\tohtml\Stata_tohtml\tests\from_html\summary.html

capture which pathutil
if _rc {
    di as error "pathutil not found"
    exit 111
}

tohtml "example_from_html.log", md("example_from_html.md") html("example_from_html.html") replace
di as result "DONE"
log close

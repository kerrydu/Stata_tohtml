clear all
set more off
local root "C:/Users/kerry/Desktop/tohtml/Stata_tohtml"
adopath ++ "`root'"
cd "`root'/tests/from_html"

capture which pathutil
if _rc {
    di as error "pathutil not found"
    exit 111
}

tohtml "example_from_html.log", md("example_from_html.md") html("example_from_html.html") replace
di as result "DONE"

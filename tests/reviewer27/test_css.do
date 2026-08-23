clear all
set more off
capture log close _all
local root "C:/Users/kerry/Desktop/tohtml/Stata_tohtml"
adopath ++ "`root'"
cd "`root'/tests/reviewer27"

foreach f in table_fragment.html table_fragment.css ///
    table_fragment.raw.html table_fragment.raw.css ///
    table_fragment_custom.html table_fragment_custom.raw.html ///
    table_fragment_custom_nocss.html ///
    chosen_fragment.css chosen_fragment.raw.css ///
    reviewer27.log reviewer27.md reviewer27.html {
    capture erase "`f'"
}

sysuse auto, clear
collect clear
table foreign, statistic(mean price) statistic(sd price)

collect export "table_fragment.html", tableonly replace
copy "table_fragment.html" "table_fragment.raw.html", replace

collect export "table_fragment_custom.html", tableonly ///
    cssfile("chosen_fragment.css") replace
copy "table_fragment_custom.html" "table_fragment_custom.raw.html", replace
copy "table_fragment_custom.html" "table_fragment_custom_nocss.html", replace

log using "reviewer27.log", text replace
ishere # Reviewer 27 CSS test
ishere
ishere tab using "table_fragment.html"
ishere ## custom cssfile()
ishere
ishere tab using "table_fragment_custom.html", cssfile("chosen_fragment.css")
ishere ## custom CSS without cssfile()
ishere
ishere tab using "table_fragment_custom_nocss.html"
log close
ishere

tohtml "reviewer27.log", ///
    md("reviewer27.md") ///
    html("reviewer27.html") replace
di as result "DONE"

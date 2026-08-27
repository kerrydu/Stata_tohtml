clear all
set more off
capture log close _all

local root "C:/Users/kerry/Desktop/tohtml/Stata_tohtml"
adopath ++ "`root'"
local here "`root'/tests/ishere_md_tab"
capture mkdir "`here'"
cd "`here'"

* Sample Markdown table (GFM pipe table)
tempname fh
file open `fh' using "`here'/table1.md", write text replace
file write `fh' "| Variable | Mean | SD |" _n
file write `fh' "| --- | --- | --- |" _n
file write `fh' "| price | 6165.3 | 2949.5 |" _n
file write `fh' "| mpg | 21.3 | 5.8 |" _n
file write `fh' "| weight | 3019.5 | 777.2 |" _n
file close `fh'

capture erase "`here'/mdtab.log"
capture erase "`here'/mdtab.md"
capture erase "`here'/mdtab.html"
capture erase "`here'/mdtab_embed.md"
capture erase "`here'/mdtab_embed.html"

log using "`here'/mdtab.log", text replace

ishere # Markdown table via ishere tab
sysuse auto, clear
summarize price mpg weight
/**
A pipe table from `table1.md` should appear below (inlined, not an iframe).
**/
ishere tab using "`here'/table1.md"
/**
End of table test.
**/

log close

di as result "=== default tohtml ==="
tohtml "`here'/mdtab.log", md("`here'/mdtab.md") html("`here'/mdtab.html") replace

di as result "=== embed tohtml ==="
tohtml "`here'/mdtab.log", md("`here'/mdtab_embed.md") html("`here'/mdtab_embed.html") embed replace

di as result "DONE"

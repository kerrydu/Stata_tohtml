clear all
set more off
capture log close _all

local root = subinstr(`"`c(pwd)'"', "\", "/", .)
adopath ++ "`root'"

local scratch `"`root'/tests/path_spaces/tmp path with spaces"'
capture mkdir "`root'/tests/path_spaces"
capture mkdir "`scratch'"

local src `"`root'/tests/from_html/example_from_html.log"'
local log `"`scratch'/example standard.log"'
local md `"`scratch'/example standard.md"'
local html `"`scratch'/example standard.html"'
local dir `"`root'/tests/path_spaces/tmp bundle with spaces"'
local dir_md `"`scratch'/directory mode.md"'
local dir_html `"`scratch'/directory mode.html"'

copy `"`src'"' `"`log'"', replace
capture erase `"`md'"'
capture erase `"`html'"'
capture mkdir "`dir'"
copy `"`root'/tests/from_html/model.html"' `"`dir'/table1.html"', replace
copy `"`root'/docs/price_hist.png"' `"`dir'/figure1.png"', replace
capture erase `"`dir_md'"'
capture erase `"`dir_html'"'

tohtml `"`log'"', md(`"`md'"') html(`"`html'"') replace
tohtml `"`dir'"', md(`"`dir_md'"') html(`"`dir_html'"') replace

confirm file `"`md'"'
confirm file `"`html'"'
confirm file `"`dir_md'"'
confirm file `"`dir_html'"'
di as result "DONE"

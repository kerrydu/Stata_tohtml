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

copy `"`src'"' `"`log'"', replace
capture erase `"`md'"'
capture erase `"`html'"'

tohtml `"`log'"', md(`"`md'"') html(`"`html'"') replace

confirm file `"`md'"'
confirm file `"`html'"'
di as result "DONE"

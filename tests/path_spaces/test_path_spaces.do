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
local dir_zoom_md `"`scratch'/directory mode zoom.md"'
local dir_zoom_html `"`scratch'/directory mode zoom.html"'

copy `"`src'"' `"`log'"', replace
capture erase `"`md'"'
capture erase `"`html'"'
capture mkdir "`dir'"
copy `"`root'/tests/from_html/model.html"' `"`dir'/table1.html"', replace
copy `"`root'/docs/price_hist.png"' `"`dir'/figure1.png"', replace
capture erase `"`dir_md'"'
capture erase `"`dir_html'"'
capture erase `"`dir_zoom_md'"'
capture erase `"`dir_zoom_html'"'

tohtml `"`log'"', md(`"`md'"') html(`"`html'"') replace
tohtml `"`dir'"', md(`"`dir_md'"') html(`"`dir_html'"') width(500px) height(100px) replace
tohtml `"`dir'"', md(`"`dir_zoom_md'"') html(`"`dir_zoom_html'"') width(500px) height(100px) zoom(80%) replace
 
confirm file `"`md'"'
confirm file `"`html'"'
confirm file `"`dir_md'"'
confirm file `"`dir_html'"'
confirm file `"`dir_zoom_md'"'
confirm file `"`dir_zoom_html'"'
 
tempname fh
local saw_dims 0
file open `fh' using `"`dir_md'"', read text
file read `fh' line
while r(eof)==0 {
    if strpos(`"`line'"', `"<img src="' ) & ///
        strpos(`"`line'"', `"`"width="500px" height="100px""'"') {
        local saw_dims 1
    }
    file read `fh' line
}
file close `fh'
assert `saw_dims'

tempname fh2
local saw_zoom_dims 0
file open `fh2' using `"`dir_zoom_md'"', read text
file read `fh2' line
while r(eof)==0 {
    if strpos(`"`line'"', `"<img src="' ) & ///
        strpos(`"`line'"', `"`"width="500px" height="100px""'"') & ///
        strpos(`"`line'"', `"`"style="zoom:80%;""'"') {
        local saw_zoom_dims 1
    }
    file read `fh2' line
}
file close `fh2'
assert `saw_zoom_dims'
di as result "DONE"

*! version 1.8, 2026-08-21
*! version 1.7, 2026-08-21
*! version 1.6, 2026-08-11
program define ishere
    version 14

    gettoken subcmd : 0
    local subl = lower("`subcmd'")
    local isfig = inlist("`subl'", "fig", "figure")
    local istab = inlist("`subl'", "tab", "table")
    local isdisp = ("`subl'" == "display")

    // ---------------------------------------------------------------
    // Mode 2b: emit display value for MD tag replacement
    // ---------------------------------------------------------------
    if `isdisp' {
        gettoken junk 0 : 0
        display `0'
        exit 0
    }

    // ---------------------------------------------------------------
    // Mode 2: emit markdown/HTML insertion for figures and tables
    // ---------------------------------------------------------------
    if `isfig' | `istab' {
        syntax anything using/ [, Height(string) Width(string) Zoom(string)]

        removequotes, t(`using')
        local using `r(s)'
        local using = subinstr("`using'", "\", "/", .)

        local filepath `using'
        if "`filepath'" == "" {
            di as error "ishere `subcmd': using(filename) is required"
            exit 198
        }
        if strpos("`filepath'", ".") == 0 {
            di as error "filename must have an extension"
            exit 198
        }
        mata: st_local("filepath", ishere_project_rel(st_local("filepath")))
        mata: st_local("extension", pathsuffix("`filepath'"))
        local extension = lower("`extension'")

        if `isfig' {
            if "`zoom'" == "" & "`height'" == "" & "`width'" == "" local zoom "100%"
            if !inlist("`extension'", ".png", ".jpg", ".jpeg", ".svg", ".gif", ".bmp", ".webp") {
                di as error "unsupported image format: `extension'"
                exit 198
            }
            if "`zoom'" != "" {
                if strpos("`zoom'", "%") == 0 local zoom "`zoom'%"
                di
                display `"<img src="`filepath'" style="zoom:`zoom';">"'
            }
            else {
                if "`width'" == "" local width "auto"
                if "`height'" == "" local height "auto"
                di
                display `"<img src="`filepath'" width="`width'" height="`height'">"'
            }
            exit
        }

        // table
        if inlist("`extension'", ".html", ".htm") {
            if "`height'" == "" local height "400px"
            if "`width'" == "" local width "100%"
            di
            display `"<iframe src='`filepath'' width='`width'' height='`height'' frameBorder='0'></iframe>"'
        }
        else if "`extension'" == ".md" {
            di
            display `"<iframe `filepath' ></iframe>"'
        }
        else {
            di as error "unsupported table format: `extension'"
            di as error "allowed: .html, .htm, .md"
            exit 198
        }
        exit
    }

    // ---------------------------------------------------------------
    // Mode 1: placeholder — code block or markdown header only
    // ---------------------------------------------------------------
    syntax [anything(everything)]
    local a = strtrim(`"`anything'"')

    // code block marker: ishere  or  ishere ```
    if `"`a'"' == "" | `"`a'"' == "```" {
        exit
    }

    // header: ishere # ...
    if usubstr(`"`a'"', 1, 1) == "#" {
        exit
    }

    di as error `"ishere: unsupported argument `a'"'
    di as error "placeholder mode: ishere  |  ishere # heading"
    di as error "emit mode: ishere display ..."
    di as error "           ishere fig|figure using filename [, zoom() height() width()]"
    di as error "           ishere tab|table using filename [, height() width()]"
    exit 198
end


capture program drop removequotes
program define removequotes, rclass
    version 14
    syntax, [t(string)]
    return local s `t'
end

mata:
string scalar ishere_project_rel(string scalar src)
{
    // Paths under c(pwd) are written with forward slashes, relative to the project.
    src = strtrim(src)
    if (src == "") return(src)
    if (pathisurl(src)) return(src)

    pw = pwd()
    resolved = src
    if (!fileexists(resolved)) {
        cand = pathjoin(pw, src)
        if (fileexists(cand)) resolved = cand
    }
    if (!pathisabs(resolved)) resolved = pathresolve(pw, resolved)

    a = subinstr(resolved, "\", "/", .)
    b = subinstr(pw, "\", "/", .)
    while (strlen(b) > 1 & substr(b, strlen(b), 1) == "/") {
        b = substr(b, 1, strlen(b) - 1)
    }
    pref = ustrlower(b) + "/"
    if (ustrpos(ustrlower(a), pref) == 1) {
        return(substr(a, strlen(b) + 2, .))
    }
    return(subinstr(src, "\", "/", .))
}
end

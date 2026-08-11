*! version 1.4, 2026-08-11
*! version 1.3, 2026-08-11
*! version 1.2, 2026-08-11
*! version 1.1, 2026-08-11
*! version 1.0, 2026-04-28
program define tohtml
cap which pathutil
if _rc ssc install pathutil, replace
version 16
    syntax anything ,  [ cleanmd(string) REPlace HTML(string) ///
                         CSS(string) ///
                         CLEAN CLEANCODE ///
                         BUNDLE ZIP(string) ///
                         width(string) height(string) zoom(string)]

    if "`clean'" != "" & "`cleancode'" != "" {
        di as error "options clean and cleancode may not be combined"
        exit 198
    }

    removequotes , t(`anything')
    local anything  `r(s)'
    local anything = subinstr(`"`anything'"', "\", "/", .)


    // 判断anything is a file or a folder
    local nf : word count `anything'
    if `nf' > 1 { // multiple file path specified
        alltohtml `anything', width(`width') height(`height') zoom(`zoom') 
        mclean2 `0'
        exit
    }
    else if `nf' == 1 { //single file path specified
        mata: st_numscalar("flag",direxists("`anything'"))
        if flag==1 { // anything is a path crteate a tempfile
            alltohtml `anything', width(`width') height(`height') zoom(`zoom') 
            mclean2 `0'
            exit
        }
    }

   // log file specified
    confirm file `"`anything'"'
	local saving `cleanmd'
    local saving = subinstr(`"`saving'"', "\", "/", .)
    if "`clean'" != "" {
        mclean `0'
        exit
    }
    if "`cleancode'" != "" {
        cleancode `0' 
        exit
    }
    if `"`saving'"' == "" {
        //在anything扩展名之前加clean，思路找到最后一个.的位置，然后把扩展名之前的部分替换成clean.md
        local saving = usubstr("`anything'", 1, ustrpos("`anything'", ".")-1) + "_clean.md"
    }
    local using `anything'
    // Resolve paths
    local infile `using'
    local outfile `saving'

    // If outfile exists and no replace, stop
    capture confirm new file `"`outfile'"'
    if _rc  & "`replace'" == "" {
        di as error "output file exists; use replace"
        exit 602
    }

    if `"`html'"' != "" {
        if ustrright(ustrlower(`"`html'"'), 5) != ".html" {
            local html `"`html'.html"'
        }
        capture confirm new file "`html'"
        if _rc  & "`replace'" == "" {
            di as error "output file exists; use replace"
            exit 602
        }
   }

    // If replace is specified, erase existing outfile
    if "`replace'" != "" {
        capture erase `"`outfile'"'
        capture erase `"`html'"'
    }



    local repl = ("`replace'" != "")
    mata: rewrite_md(`"`infile'"', `"`outfile'"', `repl')

    di as text "% cleaned markdown written to " "`outfile'"

    // Optional: regenerate HTML from cleaned markdown
    if "`html'" != "" {
        if "`css'" == "" local css "githubstyle"

        markdown `outfile', saving(`"`html'"') replace
        if "`css'" == "githubstyle" {
            mata: st_local("html_dir", path_dir(`"`html'"'))
            if "`html_dir'" == "" local html_dir "."
            cap mkdir "`html_dir'/css"
            local css_dest "`html_dir'/css/github.css"
            mata: write_github_css(`"`css_dest'"')
            mata: inject_css(`"`html'"', "./css/github.css")
            mata: inject_mathjax(`"`html'"')
            copy "`html_dir'/css/github.css" "`html_dir'/css/table-override.css", replace
        }
        else if "`css'" != "" {
            mata: st_local("css_base", pathbasename(`"`css'"'))
            mata: st_local("html_dir", path_dir(`"`html'"'))
            if "`html_dir'" == "" local html_dir "."
            cap mkdir "`html_dir'/css"
            local css_dest "`html_dir'/css/`css_base'"
            mata: st_local("css_norm", normalize_path(`"`css'"'))
            mata: st_local("css_dest_norm", normalize_path(`"`css_dest'"'))
            if `"`css_norm'"' != `"`css_dest_norm'"' {
                copy `"`css_norm'"' `"`css_dest'"', replace
                copy `"`css_norm'"' "`html_dir'/css/table-override.css", replace
            }
            mata: inject_css(`"`html'"', "./css/`css_base'")
        }
        if "`zip'" != "" | "`bundle'" != "" {
            tohtml_bundle, html(`"`html'"') md(`"`outfile'"') zip(`"`zip'"') `replace'
        }
        // di as text "% html regenerated to `html'"
    }
    else if "`css'" != "" | "`bundle'" != "" | "`zip'" != "" {
        di as error "css()/bundle/zip require html()"
        exit 198
    }
end


program define cleancode
    syntax anything , CLEANCODE [cleanmd(string) REPlace HTML(string) ///
                                         CSS(string) ///
                                         BUNDLE ZIP(string) ///
                                         width(string) height(string) zoom(string)]

    local saving `cleanmd'
    removequotes , t(`anything')
    local anything  `r(s)'

    if `"`saving'"' == "" {
        local saving = usubstr(`"`anything'"', 1, ustrpos(`"`anything'"', ".")-1) + "_code.md"

    }

    capture confirm new file `"`saving'"'
    if _rc  & "`replace'" == "" {
        di as error "output file exists; use replace"
        exit 602
    }

    if `"`html'"' != "" {
        if ustrright(ustrlower(`"`html'"'), 5) != ".html" {
            local html `"`html'.html"'
        }
        capture confirm new file "`html'"
        if _rc  & "`replace'" == "" {
            di as error "output file exists; use replace"
            exit 602
        }
   }

    // If replace is specified, erase existing outfile
    if "`replace'" != "" {
        capture erase `"`saving'"'
        capture erase `"`html'"'
    }


    local using `anything'
    local infile `using'
    local outfile `saving'

    capture confirm file `"`outfile'"'
    if _rc == 0 & "`replace'" == "" {
        di as error "output file exists; use replace"
        exit 602
    }


    local replout = ("`replace'" != "")
    // Keep Stata commands (and img/iframe embeds) from the log; drop output
    mata: rewrite_md_cleancode(`"`infile'"', `"`outfile'"', `replout')

    di as text `"% cleancode markdown written to `outfile'"'

    // Optional: regenerate HTML from code markdown
    if "`html'" != "" {
        if "`css'" == "" local css "githubstyle"
        markdown `outfile', saving(`"`html'"') replace
        if "`css'" == "githubstyle" {
            mata: st_local("html_dir", path_dir(`"`html'"'))
            if "`html_dir'" == "" local html_dir "."
            cap mkdir "`html_dir'/css"
            local css_dest "`html_dir'/css/github.css"
            mata: write_github_css(`"`css_dest'"')
            mata: inject_css(`"`html'"', "./css/github.css")
            mata: inject_mathjax(`"`html'"')
            copy "`html_dir'/css/github.css" "`html_dir'/css/table-override.css", replace
        }
        else if "`css'" != "" {
            mata: st_local("css_base", pathbasename(`"`css'"'))
            mata: st_local("html_dir", path_dir(`"`html'"'))
            if "`html_dir'" == "" local html_dir "."
            cap mkdir "`html_dir'/css"
            local css_dest "`html_dir'/css/`css_base'"
            mata: st_local("css_norm", normalize_path(`"`css'"'))
            mata: st_local("css_dest_norm", normalize_path(`"`css_dest'"'))
            if `"`css_norm'"' != `"`css_dest_norm'"' {
                copy `"`css_norm'"' `"`css_dest'"', replace
                copy `"`css_norm'"' "`html_dir'/css/override.css", replace
            }
            mata: inject_css(`"`html'"', "./css/`css_base'")
        }
        if "`zip'" != "" | "`bundle'" != "" {
            tohtml_bundle, html(`"`html'"') md(`"`outfile'"') zip(`"`zip'"') `replace'
        }
        // di as text "% html regenerated to `html'"
    }
    else if "`css'" != "" | "`bundle'" != "" | "`zip'" != "" {
        di as error "css()/bundle/zip require html()"
        exit 198
    }
end

cap program drop removequotes
program define removequotes,rclass
	version 16
	syntax, t(string)
	return local s `t'
end


program define mclean
    syntax anything , [cleanmd(string)  REPlace HTML(string) CSS(string) ///
                       CLEAN CLEANCODE ///
                       BUNDLE ZIP(string) ///
                       width(string) height(string) zoom(string)]
    // only keep lines that start with #, <iframe, <img

    removequotes , t(`anything')
    local anything  `r(s)'
   local saving `cleanmd'
    if `"`saving'"' == "" {
        //在anything扩展名之前加clean，思路找到最后一个.的位置，然后把扩展名之前的部分替换成clean.md
        local saving = usubstr("`anything'", 1, ustrpos("`anything'", ".")-1) + ".clean.md"
    }
    local using `anything'
    local infile `using'
    local outfile `saving'

    // If outfile exists and no replace, stop
    capture confirm file `"`outfile'"'
    if _rc == 0 & "`replace'" == "" {
        di as error "output file exists; use replace"
        exit 602
    }

    if `"`html'"' != "" {
        if ustrright(ustrlower(`"`html'"'), 5) != ".html" {
            local html `"`html'.html"'
        }
        capture confirm new file "`html'"
        if _rc  & "`replace'" == "" {
            di as error "output file exists; use replace"
            exit 602
        }
   }

    // If replace is specified, erase existing outfile
    if "`replace'" != "" {
        capture erase `"`outfile'"'
        capture erase `"`html'"'
    }


    local repl = ("`replace'" != "")
    mata: rewrite_md2(`"`infile'"', `"`outfile'"', `repl')
    di as text "% cleaned markdown written to " `"`outfile'"'

        // Optional: regenerate HTML from cleaned markdown
    if "`html'" != "" {
        if "`css'" == "" local css "githubstyle"
        markdown `outfile', saving(`"`html'"') replace
        if "`css'" == "githubstyle" {
            mata: st_local("html_dir", path_dir(`"`html'"'))
            if "`html_dir'" == "" local html_dir "."
            cap mkdir "`html_dir'/css"
            local css_dest "`html_dir'/css/github.css"
            mata: write_github_css(`"`css_dest'"')
            mata: inject_css(`"`html'"', "./css/github.css")
            mata: inject_mathjax(`"`html'"')
            copy "`html_dir'/css/github.css" "`html_dir'/css/table-override.css", replace
        }
        else if "`css'" != "" {
            mata: st_local("css_base", pathbasename(`"`css'"'))
            mata: st_local("html_dir", path_dir(`"`html'"'))
            if "`html_dir'" == "" local html_dir "."
            cap mkdir "`html_dir'/css"
            local css_dest "`html_dir'/css/`css_base'"
            mata: st_local("css_norm", normalize_path(`"`css'"'))
            mata: st_local("css_dest_norm", normalize_path(`"`css_dest'"'))
            if `"`css_norm'"' != `"`css_dest_norm'"' {
                copy `"`css_norm'"' `"`css_dest'"', replace
                copy `"`css_norm'"' "`html_dir'/css/override.css", replace
            }
            mata: inject_css(`"`html'"', "./css/`css_base'")
        }
        if "`zip'" != "" | "`bundle'" != "" {
            tohtml_bundle, html(`"`html'"') md(`"`outfile'"') zip(`"`zip'"') `replace'
        }
        // di as text "% html regenerated to `html'"
    }
    else if "`css'" != "" | "`bundle'" != "" | "`zip'" != "" {
        di as error "css()/bundle/zip require html()"
        exit 198
    }
end



program define mclean2
    syntax [anything] , [cleanmd(string)  REPlace HTML(string) CSS(string) ///
                       CLEAN CLEANCODE ///
                       BUNDLE ZIP(string) ///
                       width(string) height(string) zoom(string)]
    // only keep lines that start with #, <iframe, <img

    // removequotes , t(`anything')
    // local anything  `r(s)'
    local anything `c(pwd)'/_tempfile_log_.md
    local saving `cleanmd'
    if `"`saving'"' == "" {
        //在anything扩展名之前加clean，思路找到最后一个.的位置，然后把扩展名之前的部分替换成clean.md
        local saving = usubstr("`anything'", 1, ustrpos("`anything'", ".")-1) + ".clean.md"
    }
    local using `anything'
    local infile `using'
    local outfile `saving'

    // If outfile exists and no replace, stop

    capture confirm new file `"`saving'"'
    if _rc  & "`replace'" == "" {
        di as error "output file exists; use replace"
        exit 602
    }

    if `"`html'"' != "" {
        if ustrright(ustrlower(`"`html'"'), 5) != ".html" {
            local html `"`html'.html"'
        }
        capture confirm new file "`html'"
        if _rc  & "`replace'" == "" {
            di as error "output file exists; use replace"
            exit 602
        }
   }

    // If replace is specified, erase existing outfile
    if "`replace'" != "" {
        capture erase `"`saving'"'
        capture erase `"`html'"'
    }
  


    local repl = ("`replace'" != "")
    mata: rewrite_md2(`"`infile'"', `"`outfile'"', `repl')
    di as text "% cleaned markdown written to " `"`outfile'"'

        // Optional: regenerate HTML from cleaned markdown
    if "`html'" != "" {
        if "`css'" == "" local css "githubstyle"
        markdown `outfile', saving(`"`html'"') replace
        if "`css'" == "githubstyle" {
            mata: st_local("html_dir", path_dir(`"`html'"'))
            if "`html_dir'" == "" local html_dir "."
            cap mkdir "`html_dir'/css"
            local css_dest "`html_dir'/css/github.css"
            mata: write_github_css(`"`css_dest'"')
            mata: inject_css(`"`html'"', "./css/github.css")
            mata: inject_mathjax(`"`html'"')
            copy "`html_dir'/css/github.css" "`html_dir'/css/table-override.css", replace
        }
        else if "`css'" != "" {
            mata: st_local("css_base", pathbasename(`"`css'"'))
            mata: st_local("html_dir", path_dir(`"`html'"'))
            if "`html_dir'" == "" local html_dir "."
            cap mkdir "`html_dir'/css"
            local css_dest "`html_dir'/css/`css_base'"
            mata: st_local("css_norm", normalize_path(`"`css'"'))
            mata: st_local("css_dest_norm", normalize_path(`"`css_dest'"'))
            if `"`css_norm'"' != `"`css_dest_norm'"' {
                copy `"`css_norm'"' `"`css_dest'"', replace
                copy `"`css_norm'"' "`html_dir'/css/override.css", replace
            }
            mata: inject_css(`"`html'"', "./css/`css_base'")
        }
        if "`zip'" != "" | "`bundle'" != "" {
            tohtml_bundle, html(`"`html'"') md(`"`outfile'"') zip(`"`zip'"') `replace'
        }
        // di as text "% html regenerated to `html'"
    }
    else if "`css'" != "" | "`bundle'" != "" | "`zip'" != "" {
        di as error "css()/bundle/zip require html()"
        exit 198
    }
end



capture program drop tohtml_bundle
program define tohtml_bundle
    version 16
    syntax , HTML(string) [MD(string) ZIP(string) REPlace]

    mata: st_local("html_dir", path_dir(`"`html'"'))
    if "`html_dir'" == "" local html_dir "."

    cap mkdir "`html_dir'/css"
    cap mkdir "`html_dir'/figures"
    cap mkdir "`html_dir'/tables"

    mata: bundle_report(`"`html'"', `"`md'"')
    di as text "% resources bundled under `html_dir'/{css,figures,tables}"

    if `"`zip'"' == "" exit

    // resolve zip archive path
    if `"`zip'"' == "." | lower(`"`zip'"') == "auto" {
        mata: st_local("html_base", path_base(`"`html'"'))
        local stub = ustrregexra("`html_base'", "\.[^.]+$", "")
        local zipfile "`html_dir'/`stub'.zip"
    }
    else {
        local zipfile `zip'
        local zipfile = subinstr(`"`zipfile'"', "\", "/", .)
        mata: st_local("zip_suf", pathsuffix(`"`zipfile'"'))
        if "`zip_suf'" == "" local zipfile `"`zipfile'.zip"'
        // bare filename -> place next to HTML
        mata: st_local("zip_dir", path_dir(`"`zipfile'"'))
        if "`zip_dir'" == "" local zipfile "`html_dir'/`zipfile'"
    }

    if "`replace'" != "" {
        capture erase `"`zipfile'"'
    }
    else {
        capture confirm new file `"`zipfile'"'
        if _rc {
            di as error "zip file exists; use replace"
            exit 602
        }
    }

    // build relative file list from package root, then zipfile
    mata: st_local("html_base", path_base(`"`html'"'))
    mata: st_local("html_dir_abs", normalize_path(`"`html_dir'"'))
    mata: st_local("zipfile_abs", normalize_path(`"`zipfile'"'))
    mata: st_local("zip_base", path_base(st_local("zipfile_abs")))
    mata: st_local("zip_parent", path_dir(st_local("zipfile_abs")))
    if "`zip_parent'" == "" local zip_parent "."
    mata: st_local("zip_parent", normalize_path(st_local("zip_parent")))

    local pwd0 `"`c(pwd)'"'
    quietly cd `"`html_dir_abs'"'

    local zlist `"`html_base'"'
    foreach sub in css figures tables {
        capture local fs : dir "`sub'" files "*"
        if _rc == 0 {
            foreach f of local fs {
                local zlist `"`zlist' "`sub'/`f'""'
            }
        }
    }
    // include cleaned markdown when it lives in the package root
    if `"`md'"' != "" {
        mata: st_local("md_norm", normalize_path(`"`md'"'))
        mata: st_local("md_dir", path_dir(st_local("md_norm")))
        if "`md_dir'" == "" local md_dir "."
        mata: st_local("md_dir_norm", normalize_path(`"`md_dir'"'))
        if `"`md_dir_norm'"' == `"`html_dir_abs'"' {
            mata: st_local("md_base", path_base(`"`md_norm'"'))
            confirm file `"`md_base'"'
            local zlist `"`zlist' "`md_base'""'
        }
    }

    if `"`zip_parent'"' == `"`html_dir_abs'"' {
        local zsave `"`zip_base'"'
    }
    else {
        local zsave `"`zipfile_abs'"'
    }

    capture noi zipfile `zlist', saving(`"`zsave'"', replace)
    local rc = _rc
    quietly cd `"`pwd0'"'
    if `rc' {
        di as error "zipfile failed"
        exit `rc'
    }
    di as text "% archive written to " `"`zipfile_abs'"'
end



mata:




string scalar path_dir(string scalar p)
{
    p = normalize_path(p)
    i = lastpos(p, "/")
    if (i <= 1) return("")
    return(substr(p, 1, i - 1))
}

string scalar path_base(string scalar p)
{
    p = normalize_path(p)
    i = lastpos(p, "/")
    if (i == 0) return(p)
    return(substr(p, i + 1, .))
}



void function inject_css(string scalar htmlfile, string scalar css_rel)
{
    lines = cat(htmlfile)
    if (rows(lines) == 0) return

    // avoid duplicate injection
    if (sum(ustrpos(lines, css_rel) :> 0) > 0) return

    link = "<link rel=" + char(34) + "stylesheet" + char(34) + " href=" + char(34) + css_rel + char(34) + ">"
    idx = selectindex(ustrpos(lines, "</head>") :> 0)
    if (rows(idx) > 0) {
        i = idx[1]
        if (i > 1) {
            lines = lines[|1 \ i-1|] \ link \ lines[|i \ rows(lines)|]
        }
        else {
            lines = link \ lines
        }
    }
    else {
        lines = link \ lines
    }

    mm_outsheet(htmlfile, lines, "replace")
}

// ---------- bundle / zip helpers ----------

real scalar path_is_abs(string scalar p)
{
    p = normalize_path(p)
    if (p == "") return(0)
    if (substr(p, 1, 1) == "/") return(1)
    if (strlen(p) >= 2 & substr(p, 2, 1) == ":") return(1)
    return(0)
}

string scalar path_suffix_lower(string scalar p)
{
    b = path_base(p)
    i = lastpos(b, ".")
    if (i == 0) return("")
    return(ustrlower(substr(b, i, .)))
}

string scalar embed_kind(string scalar path)
{
    ext = path_suffix_lower(path)
    if (ext == ".png" | ext == ".jpg" | ext == ".jpeg" | ext == ".svg" |
        ext == ".gif" | ext == ".bmp" | ext == ".webp") return("fig")
    if (ext == ".html" | ext == ".htm" | ext == ".md") return("tab")
    return("")
}

real scalar path_is_remote(string scalar p)
{
    pl = ustrlower(strtrim(p))
    if (pl == "") return(1)
    if (ustrpos(pl, "http://") == 1) return(1)
    if (ustrpos(pl, "https://") == 1) return(1)
    if (ustrpos(pl, "data:") == 1) return(1)
    if (pathisurl(pl)) return(1)
    return(0)
}

string scalar resolve_local_file(string scalar src, string scalar root)
{
    src0 = strtrim(src)
    if (path_is_remote(src0)) return("")
    srcn = normalize_path(src0)

    cands = J(0, 1, "")
    cands = cands \ srcn
    if (!path_is_abs(srcn)) {
        cands = cands \ normalize_path(pwd() + "/" + srcn)
        cands = cands \ normalize_path(root + "/" + srcn)
    }
    for (i = 1; i <= rows(cands); i++) {
        if (fileexists(cands[i])) return(cands[i])
    }
    return("")
}

string scalar unique_bundle_name(string scalar destdir, string scalar base, string colvector used)
{
    if (sum(used :== base) == 0 & !fileexists(destdir + "/" + base)) return(base)

    suf = path_suffix_lower(base)
    if (suf == "") {
        stem = base
    }
    else {
        stem = substr(base, 1, strlen(base) - strlen(suf))
    }
    for (k = 2; k <= 9999; k++) {
        cand = stem + "_" + strofreal(k) + suf
        if (sum(used :== cand) == 0 & !fileexists(destdir + "/" + cand)) return(cand)
    }
    return(stem + "_x" + suf)
}

string colvector extract_src_attrs(string scalar s)
{
    out = J(0, 1, "")
    s2 = s
    for (k = 1; k <= 30; k++) {
        if (ustrregexm(s2, `"src *= *"([^"]+)""')) {
            out = out \ ustrregexs(1)
            s2 = usubinstr(s2, ustrregexs(0), "", 1)
        }
        else if (ustrregexm(s2, `"src *= *'([^']+)'"')) {
            out = out \ ustrregexs(1)
            s2 = usubinstr(s2, ustrregexs(0), "", 1)
        }
        else break
    }
    return(out)
}

string colvector extract_embed_srcs(string colvector lines)
{
    out = J(0, 1, "")
    for (i = 1; i <= rows(lines); i++) {
        out = out \ extract_src_attrs(lines[i])
    }
    return(out)
}

string colvector extract_md_images(string colvector lines)
{
    out = J(0, 1, "")
    for (i = 1; i <= rows(lines); i++) {
        s2 = lines[i]
        for (k = 1; k <= 30; k++) {
            if (ustrregexm(s2, `"!\[[^\]]*\]\(([^)]+)\)"')) {
                out = out \ ustrregexs(1)
                s2 = usubinstr(s2, ustrregexs(0), "", 1)
            }
            else break
        }
    }
    return(out)
}

string colvector replace_path_refs(string colvector lines, string scalar oldp, string scalar newref)
{
    if (oldp == "" | newref == "") return(lines)
    old1 = normalize_path(oldp)
    old2 = subinstr(old1, "/", "\", .)
    lines = subinstr(lines, oldp, newref, .)
    if (old1 != oldp) lines = subinstr(lines, old1, newref, .)
    if (old2 != oldp & old2 != old1) lines = subinstr(lines, old2, newref, .)
    return(lines)
}

void function fix_table_override_css(string scalar tabfile)
{
    if (!fileexists(tabfile)) return
    lines = cat(tabfile)
    if (rows(lines) == 0) return
    // Only rewrite rooted or same-folder refs; avoid touching "../css/..."
    lines = subinstr(lines, "='/css/table-override.css'", "='../css/table-override.css'", .)
    lines = subinstr(lines, `"="/css/table-override.css""', `"="../css/table-override.css""', .)
    lines = subinstr(lines, "='./css/table-override.css'", "='../css/table-override.css'", .)
    lines = subinstr(lines, `"="./css/table-override.css""', `"="../css/table-override.css""', .)
    lines = subinstr(lines, "href = '/css/table-override.css'", "href = '../css/table-override.css'", .)
    lines = subinstr(lines, `"href = "/css/table-override.css""', `"href = "../css/table-override.css""', .)
    mm_outsheet(tabfile, lines, "replace")
}

void function stata_copy_file(string scalar src, string scalar dest)
{
    cmd = "copy " + char(34) + src + char(34) + " " + char(34) + dest + char(34) + ", replace"
    stata(cmd, 1)
}

void function bundle_report(string scalar htmlfile, string scalar mdfile)
{
    htmlfile = normalize_path(htmlfile)
    root = path_dir(htmlfile)
    if (root == "") root = "."

    figdir = root + "/figures"
    tabdir = root + "/tables"
    stata("cap mkdir " + char(34) + figdir + char(34), 1)
    stata("cap mkdir " + char(34) + tabdir + char(34), 1)

    html = cat(htmlfile)
    md = J(0, 1, "")
    hasmd = 0
    if (mdfile != "") {
        mdfile = normalize_path(mdfile)
        if (fileexists(mdfile)) {
            md = cat(mdfile)
            hasmd = 1
        }
    }

    srcs = extract_embed_srcs(html)
    if (hasmd) srcs = srcs \ extract_embed_srcs(md) \ extract_md_images(md)
    srcs = select(srcs, srcs :!= "")
    if (rows(srcs) > 0) srcs = uniqrows(srcs)

    used_fig = J(0, 1, "")
    used_tab = J(0, 1, "")

    for (i = 1; i <= rows(srcs); i++) {
        src = strtrim(srcs[i])
        if (path_is_remote(src)) continue

        sn = normalize_path(src)
        already_fig = (ustrpos(sn, "figures/") == 1) | (ustrpos(sn, "./figures/") == 1)
        already_tab = (ustrpos(sn, "tables/") == 1) | (ustrpos(sn, "./tables/") == 1)
        if (already_fig) continue
        if (already_tab) {
            resolved0 = resolve_local_file(src, root)
            if (resolved0 != "" & (path_suffix_lower(resolved0) == ".html" |
                path_suffix_lower(resolved0) == ".htm")) {
                fix_table_override_css(resolved0)
            }
            continue
        }

        resolved = resolve_local_file(src, root)
        if (resolved == "") {
            printf("{txt}note: resource not found, skipped: %s\n", src)
            continue
        }
        kind = embed_kind(resolved)
        if (kind == "") {
            printf("{txt}note: unsupported resource type, skipped: %s\n", src)
            continue
        }

        resolved_n = normalize_path(resolved)
        figdir_n = normalize_path(figdir)
        tabdir_n = normalize_path(tabdir)
        if (ustrpos(resolved_n, figdir_n + "/") == 1) {
            newref = "./figures/" + path_base(resolved_n)
            html = replace_path_refs(html, src, newref)
            if (hasmd) md = replace_path_refs(md, src, newref)
            continue
        }
        if (ustrpos(resolved_n, tabdir_n + "/") == 1) {
            newref = "./tables/" + path_base(resolved_n)
            html = replace_path_refs(html, src, newref)
            if (hasmd) md = replace_path_refs(md, src, newref)
            if (path_suffix_lower(resolved_n) == ".html" | path_suffix_lower(resolved_n) == ".htm") {
                fix_table_override_css(resolved_n)
            }
            continue
        }

        base = path_base(resolved)
        if (kind == "fig") {
            dest_dir = figdir
            relprefix = "./figures/"
            base = unique_bundle_name(dest_dir, base, used_fig)
            used_fig = used_fig \ base
        }
        else {
            dest_dir = tabdir
            relprefix = "./tables/"
            base = unique_bundle_name(dest_dir, base, used_tab)
            used_tab = used_tab \ base
        }
        dest = normalize_path(dest_dir + "/" + base)
        if (normalize_path(resolved) != dest) {
            stata_copy_file(resolved, dest)
        }
        newref = relprefix + base
        html = replace_path_refs(html, src, newref)
        if (hasmd) md = replace_path_refs(md, src, newref)
        if (normalize_path(resolved) != normalize_path(src)) {
            html = replace_path_refs(html, resolved, newref)
            if (hasmd) md = replace_path_refs(md, resolved, newref)
        }
        if (kind == "tab" & (path_suffix_lower(dest) == ".html" |
            path_suffix_lower(dest) == ".htm")) {
            fix_table_override_css(dest)
        }
    }

    mm_outsheet(htmlfile, html, "replace")
    if (hasmd) mm_outsheet(mdfile, md, "replace")
}

string colvector function keep_stata_code_lines(string colvector lines)
{
    // Keep Stata echoed commands (lines starting with . or >) and embed tags.
    // Drop command output and other non-command lines.
    n = rows(lines)
    if (n == 0) return(lines)

    work = J(n, 1, "")
    for (i = 1; i <= n; i++) {
        s = ustrltrim(lines[i])
        changed = 1
        while (changed) {
            changed = 0
            if (ustrpos(s, "{com}") == 1) {
                s = ustrltrim(usubstr(s, 6, .))
                changed = 1
            }
            else if (ustrpos(s, "{res}") == 1) {
                s = ustrltrim(usubstr(s, 6, .))
                changed = 1
            }
            else if (ustrpos(s, "{txt}") == 1) {
                s = ustrltrim(usubstr(s, 6, .))
                changed = 1
            }
        }
        work[i] = s
    }

    keep = (usubstr(work, 1, 1) :== ".") :| (usubstr(work, 1, 1) :== ">")
    keep = keep :| (ustrpos(work, "<iframe") :== 1) :| (ustrpos(work, "<img") :== 1)
    return(select(lines, keep))
}

void function rewrite_md_cleancode(string scalar ofi, string scalar tfi, real scalar replace)
{
    // cleancode mode: derive code from the log itself (no separate do-file)
    fcon = cat(ofi)
    fcon = keep_stata_code_lines(fcon)
    tmp = st_tempfilename()
    mm_outsheet(tmp, fcon, "replace")
    rewrite_md(tmp, tfi, replace)
}

void function rewrite_md(string scalar ofi, string scalar tfi, real scalar replace)
{
    // 1. 读取文件
    fcon = cat(ofi)
    fcon = ishererep(fcon)

    // 2. 合并 HTML 行
    fcon = merge_html_vectorized(fcon)
    fcon = clean_textcell_content(fcon)
    
    // 2b. 替换文本块中的 ishere display 占位符
    fcon = subisheredintxt(fcon)
    
    // 3. 移除前缀
    prefixes = (">", "{com}", "{res}", "{txt}")
    fcon = remove_prefix_and_trim(fcon, prefixes)

    flag = strpos(strtrim(substr(fcon, 2, .)), "ishere"):==1
    rem = strtrim(substr(fcon, strpos(fcon, "ishere"):+strlen("ishere")+1, .))
    flag2 = (rem:== "") + (rem:=="```")
    flag = flag:* flag2

    if (sum(flag) > 0) {
        idx = selectindex(flag)
        fcon[idx] = J(length(idx),1,"```")
    }
   
    // 5. 去除空行
    fcon = select(fcon, strtrim(fcon) :!= ".")
    // fcon = select(fcon, strtrim(fcon) :!= "")

    // 5b. 删除特定行
    bad1 = subinstr((substr(fcon,2,.))," ","",.) :== "capturelogclose"
    bad2 = strtrim(fcon) :== "{smcl}"
    bad3 = subinstr((substr(fcon,2,.))," ","",.) :== "{sf}{uloff}"
    fcon = select(fcon, !(bad1 :| bad2 :| bad3))
    
    // . ishere # hearder -> # header
    fcon = get_dot_header(fcon)
    
    // fcon= remove_img_iframe(fcon)
    // 6. 【核心】动态修复：直到所有 # 行都在代码块外
    fcon = insert_backtick_before_hash(fcon)
    fcon = add_two_blank_lines(fcon)
    
    // 7. （可选）过滤短代码块
    fconlen = char_lengths_including_backticks(fcon)
    fcon = select(fcon, !(fconlen :< 2*(strlen("```")+2)))
    
    // 将md源代码插入到<iframe ></iframe>位置
    // 首先使用正则表达式找到 任意空格<iframe任意空格*.md任意空格></iframe>任意空格 的行
    regex = `"(\s*<iframe\s*.*\.md\s*></iframe>\s*)"'
    flag = selectindex(regexm(fcon, regex))
    fconnew = fcon
    if (sum(flag) > 0) {
        if (flag[i]<length(fcon)){
            fconnew = fcon[1::(flag[1]-1)]
        }
        else{
            fconnew = J(0,1,"")
        }
        for(i=1; i<=length(flag); i++) {
            mdtext = extractmdtable(fcon[flag[i]])
            fconnew = fconnew \ mdtext 
            if((flag[i]<length(fcon)) & (i<length(flag))) {
              fconnew = fconnew \ fcon[(flag[i]+1)::(flag[i+1]-1)]
             }
             else if(((flag[i]<length(fcon)) & (i==length(flag)))) {
                fconnew = fconnew \ fcon[(flag[i]+1)::length(fcon)]
             }
        }
    }
    fcon = fconnew

    // 8. 输出
    //printf(strofreal(replace))
    if (replace == 0) {
        mm_outsheet(tfi, fcon)
    } else {
        mm_outsheet(tfi, fcon, "replace")
    }
}




void function rewrite_md2(string scalar ofi, string scalar tfi, real scalar replace)
{
    // 1. 读取文件
    fcon = cat(ofi)
    fcon = ishererep(fcon)
    // 2. 合并 HTML 行
    fcon = merge_html_vectorized(fcon)

    fcon = clean_textcell_content(fcon)
    
    // 2b. 替换文本块中的 ishere display 占位符
    fcon = subisheredintxt(fcon)
    
    // 3. 移除前缀
    prefixes = (">", "{com}", "{res}", "{txt}")
    fcon = remove_prefix_and_trim(fcon, prefixes)
    // . ishere # hearder -> # header
    fcon = get_dot_header(fcon)
    // 4. 
    fcon_trim = ustrltrim(fcon)
    flag = (ustrpos(fcon_trim, "#") :== 1)
    flag = flag :| (ustrpos(fcon_trim, "<img") :== 1)
    flag = flag :| (ustrpos(fcon_trim, "<iframe") :== 1)
    flag = flag :| get_textcell_index(fcon_trim)
    // 增加 textcell 块的识别

    fcon = select(fcon, flag)
    fcon_trim = ustrltrim(fcon)
    
    flag = (strpos(fcon_trim, "_ishere_"):== 1)
    if (sum(flag) > 0) {
        idx = selectindex(flag)
        fcon[idx] = J(length(idx),1,"") 
    }

    // 将md源代码插入到<iframe ></iframe>位置
    // 首先使用正则表达式找到 任意空格<iframe任意空格*.md任意空格></iframe>任意空格 的行
    regex = `"(\s*<iframe\s*.*\.md\s*></iframe>\s*)"'
    flag = selectindex(regexm(fcon, regex))
    fconnew = fcon
    if (sum(flag) > 0) {
        if (flag[1]<length(fcon)){
            fconnew = fcon[1::(flag[1]-1)]
        }
        else{
            fconnew = J(0,1,"")
        }
        for(i=1; i<=length(flag); i++) {
            mdtext = extractmdtable(fcon[flag[i]])
            fconnew = fconnew \ mdtext 
            if((flag[i]<length(fcon)) & (i<length(flag))) {
              if (flag[i]+1 !=flag[i+1]){
                fconnew = fconnew \ fcon[(flag[i]+1)::(flag[i+1]-1)]
              }
              else{
                fconnew = fconnew \ " "
              }
             }
             else if(((flag[i]<length(fcon)) & (i==length(flag)))) {
                fconnew = fconnew \ fcon[(flag[i]+1)::length(fcon)]
             }
        }
    }
    fcon = fconnew
    
    
    // 8. 输出
    if (replace == 0) {
        mm_outsheet(tfi, fcon)
    } else {
        mm_outsheet(tfi, fcon, "replace")
    }
}

string colvector extractmdtable(string scalar line){
    line2 = usubinstr(line, "<iframe", "", 1)
    line2 = usubinstr(line2, "</iframe>", "", 1)
    line2 = strtrim(line2)
    // 去掉 iframe 开标签的关闭符 ">"，格式为 <iframe filepath >
    if (substr(line2, strlen(line2), 1) == ">") {
        line2 = strtrim(substr(line2, 1, strlen(line2)-1))
    }
    if (!fileexists(line2)) {
        printf("{err}extractmdtable: file not exist: %s\n", line2)
        return(J(0, 1, ""))
    }
    mdtext = cat(line2)
    flag = 1
    pos = 1
    maxn = length(mdtext)
    while(flag & pos < maxn ){
        line3 = ustrtrim(mdtext[1])
        if(strlen(line3) == 0){
            if(length(mdtext) > 1){
                mdtext = mdtext[2::length(mdtext)]
            }
            else{
                mdtext = J(0,1,"")
            }
        }
        else{
            flag = 0
        }
        pos = pos + 1
    }
    return(mdtext)
}


real colvector char_lengths_including_backticks(string colvector lines)
{
    n = rows(lines)
    if (n == 0) return(J(0, 1, .))
    is_bt_start = (strtrim(lines) :== "```") 
    idx_bt = selectindex(is_bt_start)
	if (sum(idx_bt)==0) result = J(n, 1, .)
    n_bt = rows(idx_bt)
    // 2. 初始化结果向量（全为缺失值）
    lens = strlen(lines)
    result = J(n, 1, .)
    if (n_bt <= 1) return(J(n, 1, .))
    npair = floor(n_bt / 2)
    i1 = rangen(1, npair*2-1, npair)
    i2 = rangen(2, npair*2, npair)
    // inpair = J(n,1,0)
    for (i = 1; i <= npair; i++) { 
// 		idx_bt[i2[i]],idx_bt[i1[i]]
         flag =selectindex(((1::n):<= idx_bt[i2[i]]) - ((1::n):< idx_bt[i1[i]]))
        //  inpair[flag] = J(length(flag),1,1)
         result[flag] = J(length(flag),1,sum(lens[flag]))
    }

    
    return(result)
}



string colvector merge_html_vectorized(string colvector f)
{
    n = rows(f)
    if (n == 0) return(f)
    
        // 1. flag1: 当前行是否以 <iframe src= 或 <img src= 开头
    len_iframe = strlen("<iframe src=")
    len_img    = strlen("<img src=")
        f_trim = ustrltrim(f)
    
        flag1 = J(n, 1, 0)
        flag1 = (substr(f_trim, 1, len_iframe) :== "<iframe src=") :| ///
            (substr(f_trim, 1, len_img)    :== "<img src=")
    
        // 2. flag2: 当前行是否以 ">" 开头（用于下一行判断）
        flag2 = (substr(f_trim, 1, 1) :== ">")
    
    // 3. 合并标志：第 i 行要合并下一行 iff flag1[i]==1 且 flag2[i+1]==1 （i=1..n-1）
    flag_merge = J(n, 1, 0)
    if (n > 1) {
        flag_merge[|1 \ n-1|] = flag1[|1 \ n-1|] :& flag2[|2 \ n|]
    }
    
    // 4. 构造新内容：对要合并的行，拼接处理后的下一行
    new_f = f  // 先复制
    to_merge_idx = selectindex(flag_merge)
    if (rows(to_merge_idx) > 0) {
        next_lines = f[to_merge_idx :+ 1]               // 下一行内容
        stripped   = strtrim(substr(next_lines, 2, .))   // 去掉首字符 ">"
        new_f[to_merge_idx] = f[to_merge_idx] :+ stripped
    }
    
    // 5. 标记哪些行应保留：所有行都保留，除了那些是"被合并的下一行"
    is_next_of_merge = J(n, 1, 0)
    if (rows(to_merge_idx) > 0) {
        is_next_of_merge[to_merge_idx :+ 1] = J(length(to_merge_idx), 1, 1)
    }
    keep = (is_next_of_merge :== 0)
    
    // 6. 返回保留的行
    result = select(new_f, keep)
    return(result)
}

string colvector remove_prefix_and_trim(string colvector lines,string rowvector prefixes)   
{
    // 定义要移除的前缀列表（按优先级或任意顺序）
    //prefixes = ("< >", "{txt}", "{com}", "{res}")  // 注意：">" 单独处理更安全

    // 先单独处理 ">"（因为它不是花括号结构，且可能与其他混淆）
    // 只有当行首是 ">" 时才去掉（注意：可能有空格？根据需求决定是否先 trim）
    // 这里假设前缀是严格在最开头（无前导空格），若需忽略前导空格，请先 strtrim
    
    n = rows(lines)
    result = lines

    // 1. 处理行首的 ">"
    // idx_gt = selectindex(substr(result, 1, 1) :== ">")
    // if (rows(idx_gt) > 0) {
    //     result[idx_gt] = ustrtrim(substr(result[idx_gt], 2, .))
    // }

    // 2. 处理 {txt}, {com}, {res}
    for (i = 2; i <= cols(prefixes); i++) {  // 跳过第1个（">" 已处理）
        pre = prefixes[i]
        len_pre = strlen(pre)
        // 找出以 pre 开头的行
        matches = (substr(result, 1, len_pre) :== pre)
        idx = selectindex(matches)
        if (rows(idx) > 0) {
            result[idx] = ustrtrim(substr(result[idx], len_pre + 1, .))
        }
    }

    return(result)
}

real colvector cumcount_backtick3(string colvector lines)
{
    n = rows(lines)
    if (n == 0) return(J(0, 1, .))
    
    is_bt = (strtrim(lines) :== "```") 
    
    // 累积和：到当前行为止（含）的 ``` 行数
    cumsum = runningsum(is_bt)
    
    // 当前行"之前"的数量 = 上一行的 cumsum
    count_before = J(n, 1, 0)
    if (n > 1) count_before[|2 \ n|] = cumsum[|1 \ n-1|]
    
    return(count_before)
}

string colvector insert_backtick_before_hash(string colvector fcon)
{
    n = rows(fcon)
    if (n == 0) return(J(0, 1, ""))
    
    // Estimate max iterations based on potential markers
    fcon_trim_init = ustrltrim(fcon)
    is_hash_init = (substr(fcon_trim_init, 1, 1) :== "#")
    is_hash_init = is_hash_init :| (substr(fcon_trim_init, 1, strlen("<iframe")) :== "<iframe") 
    is_hash_init = is_hash_init :| (substr(fcon_trim_init, 1, strlen("<img")) :== "<img")
    lens = strlen("_ishere_")
    is_hash_init = is_hash_init :| (usubstr(fcon_trim_init, 1, lens) :== "_ishere_")
    //is_hash_init = is_hash_init :| (usubstr(fcon_trim_init, 1, lens) :== "ishere/*")

    // 动态修复：每次插入后重新计算 count_before
    max_iter = sum(is_hash_init) + 50
    if (max_iter < 100) max_iter = 100
    
    iter = 0
    changed = 1

    while (changed & iter < max_iter) {
        iter = iter + 1

        count_before = cumcount_backtick3(fcon)

        fcon_trim = ustrltrim(fcon)
        
        // Base checks
        is_hash = (substr(fcon_trim, 1, 1) :== "#")
        is_hash = is_hash :| (substr(fcon_trim, 1, strlen("<iframe")) :== "<iframe") 
        is_hash = is_hash :| (substr(fcon_trim, 1, strlen("<img")) :== "<img")
        is_hash = is_hash :| (usubstr(fcon_trim, 1, lens) :== "_ishere_")
        // Robust textcell checks
        is_tc_start_vec = J(rows(fcon), 1, 0)
        is_tc_end_vec   = J(rows(fcon), 1, 0)
        
        // Check for lines starting with _ishere_
        cand_idx = selectindex(usubstr(fcon_trim, 1, lens) :== "_ishere_")
        if (rows(cand_idx) > 0) {
            for (k=1; k<=rows(cand_idx); k++) {
                 idx = cand_idx[k]
                 rem = ustrltrim(usubstr(fcon_trim[idx], lens+1, .))
                 if (usubstr(rem, 1, 2) == "/*") {
                     is_tc_start_vec[idx] = 1
                 }
                 if (usubstr(rem, 1, 2) == "*/") {
                     is_tc_end_vec[idx] = 1
                 }
            }
        }
        
        is_hash = is_hash :| is_tc_start_vec
               
        // 条件：是 # 行 且 count_before 为奇数 => 插入 BEFORE (Close code block)
        need_insert_before = is_hash :& (mod(count_before, 2) :== 1)
        
        // 条件：是 _textcell */ 且 count_before 为奇数 => 插入 AFTER (Re-open code block)
        // 注意：只有当 textcell 确实嵌在代码块里时（count=odd）才需要操作。
        // 如果 textcell 本就在外（count=even），则不需要任何操作（User Case）。
        need_insert_after = is_tc_end_vec :& (mod(count_before, 2) :== 1)

        changed = (sum(need_insert_before) + sum(need_insert_after) > 0)

        if (!changed) break

        result = J(0, 1, "")
        n_current = rows(fcon)

        for (i = 1; i <= n_current; i++) {
            if (need_insert_before[i]) {
                result = result \ "```"   // 插入关闭代码块
            }
            result = result \ fcon[i]
            if (need_insert_after[i]) {
                result = result \ "```"   // 插入（重新）打开代码块
            }
        }

        fcon = result
    }

    if (iter >= max_iter) {
        printf("{err}Warning: reached max iterations (%g) in insert_backtick_before_hash\n", max_iter)
    }

    // 清理 textcell 标记 (Robust removal)
    // We already know how to identify them, let's just strip them
    r1 = selectindex(is_tc_start_vec:| is_tc_end_vec )
    if (sum(r1) > 0) {
        fcon[r1] = J(rows(r1), 1, "")
    }
    
    return(fcon)
}


string colvector add_two_blank_lines(string colvector lines)
{
    n = rows(lines)
    if (n == 0) return(lines)

    out = J(0, 1, "")
    code_block_count = 0
    
    for (i = 1; i <= n; i++) {
        line = lines[i]
        
        // 检查当前行是否是代码块标记
        if (ustrpos(ustrtrim(line), "```") == 1) {
            code_block_count = code_block_count + 1
            
            // 如果是奇数个代码块，在它前面加两个空行
            if (mod(code_block_count, 2) == 1) {
                out = out \ "" \ ""
                // 添加当前代码块标记行
                out = out \ line
            }
    
            // 如果是偶数个代码块，在它后面加两个空行
            if (mod(code_block_count, 2) == 0) {
                out = out \ line \ "" \ ""
            }
        }
        else {
            // 非代码块标记行直接添加
            out = out \ line
        }
    }
    
    return(out)
}

void function merge_cmdlog_blocks(string scalar clean_md, string scalar cmdlog_md, string scalar out_md, real scalar replace)
{
 
    clean = cat(clean_md)
    clean = ishererep(clean)
    clean = merge_html_vectorized(clean)
    clean = subisheredintxt(clean)
    clean_trim = ustrltrim(clean)
    is_embed = (substr(clean_trim, 1, strlen("<iframe")) :== "<iframe") :| ///
        (substr(clean_trim, 1, strlen("<img")) :== "<img")
    embeds = select(clean, is_embed)
    n_embed = rows(embeds)

    // 2. 读取 cmdlog
    cmd = cat(cmdlog_md)
    // 删除 log using 开始的行
    flag = ustrpos(cmd, "log") :* ustrpos(cmd, "using")
    flag = flag :* ustrpos(cmd, "text") 
    flag = flag :* ustrpos(cmd, "replace") 
    //flag
    if (sum(flag) > 0) {
        flag1 = selectindex(flag)
        cmd = select(cmd, (1::length(cmd)) :!=flag1[1])
    }
    flag = ustrpos(cmd, "log") :* ustrpos(cmd, "close")
    if (sum(flag) > 0) {
        flag1 = selectindex(flag)
        if (length(flag1) ==1 ) {
            cmd = select(cmd, (1::length(cmd)) :!=flag1[1])
         }
         else{
            //cmd = select(cmd, (1::length(cmd)) :!=flag1[length(flag1)])
            cmd[flag1[length(flag1)]] = "ishere ```"
            cmd = select(cmd, (1::length(cmd)) :!=flag1[1])
         }
    }
        

    cmd = ishererep2(cmd)
    n_cmd = rows(cmd)

    // Handle initial comment block 
    first_non_empty = 0
    for (k = 1; k <= n_cmd; k++) {
        if (ustrtrim(cmd[k]) != "") {
             first_non_empty = k
             break
        }
    }

    if (first_non_empty > 0) {
         line_first = ustrtrim(cmd[first_non_empty])
         is_comment = 0
         end_comment = 0
         
         if (usubstr(line_first, 1, 2) == "/*") {
             is_comment = 1
             for (k = first_non_empty; k <= n_cmd; k++) {
                 if (ustrpos(cmd[k], "*/") > 0) {
                     end_comment = k
                     break
                 }
             }
         }
         else if (usubstr(line_first, 1, 1) == "*") {
             is_comment = 1
             end_comment = first_non_empty
             for (k = first_non_empty + 1; k <= n_cmd; k++) {
                 if (usubstr(ustrtrim(cmd[k]), 1, 1) == "*") {
                     end_comment = k
                 } 
                 else {
                     break
                 }
             }
         }
         
         if (is_comment & end_comment > 0) {
             pre = J(0, 1, "")
             if (first_non_empty > 1) pre = cmd[|1 \ first_non_empty-1|]
             
             mid = cmd[|first_non_empty \ end_comment|]
             
             post = J(0, 1, "")
             if (end_comment < n_cmd) post = cmd[|end_comment+1 \ n_cmd|]
             
             cmd = pre \ "```" \ mid \ "```" \ post
             n_cmd = rows(cmd)
         }
    }

    // 3. 检查 ishere /* */  闭合
      cmd = check_isheretxt_closed(cmd)

    // 4. 统计 ishere fig/tab 数量
    count_markers = 0
    for (i = 1; i <= n_cmd; i++) {
        line = ustrltrim(cmd[i])
        if (ustrpos(line, "ishere fig") == 1 | ustrpos(line, "ishere tab") == 1) {
            count_markers = count_markers + 1
        }
    }
    
    if (n_embed > 0 & count_markers != n_embed) {
        errprintf("ishere fig/tab count (%g) does not match embed count (%g)\n", count_markers, n_embed)
        _error(498)
    }

    // 5. 合并输出
    result = J(0, 1, "")
    embed_i = 1
    i = 1

    while (i <= n_cmd) {
        line = cmd[i]
        line_trim = ustrtrim(line)

        // (1) 处理 ishere fig/tab (含 smart /// 判断)
        is_target = 0
        if (ustrpos(line_trim, "ishere") == 1) {
             suffix = ustrtrim(substr(line_trim, 7, .)) 
             suffix = ustrlower(suffix)
             if (substr(suffix, 1, 3) == "fig" | substr(suffix, 1, 3) == "tab") {
                 is_target = 1
             }
        }
        
        if (is_target) {
             // 替换为图表
             if (embed_i <= n_embed) {
                result = result \ embeds[embed_i]
                embed_i = embed_i + 1
             }
             
             // 智能跳过 /// 分行
             while (i <= n_cmd) {
                 curr = ustrtrim(cmd[i]) 
                 len = strlen(curr)
                 if (len >= 3) {
                     if (substr(curr, len-2, 3) == "///") {
                         i = i + 1 // consume current line and check next
                         continue
                     }
                 }
                 break 
             }
             i = i + 1
             continue
        }

        // (2) ishere # -> #
        if (ustrpos(line_trim, "ishere ") == 1) {
            islen = strlen("ishere")
             rem = ustrltrim(substr(line_trim, islen+1, .))
             if (substr(rem, 1, 1) == "#") {
                 result = result \ rem
                 i = i + 1
                 continue
             }
        }


        // (4) ishere [0|1] -> ```
        if (ustrpos(line_trim, "ishere") == 1) {
            islen = strlen("ishere")
            rem = ustrtrim(substr(line_trim, islen+1, .))
            if (rem == "" | rem == "```") {
                result = result \ "```"
                i = i + 1
                continue
            }
        }
        
        // 保留其他行
        result = result \ line
        i = i + 1
    }

    // 5b. 替换文本块中的 ishere display 占位符
    //result = subisheredintxt(result)

    // 6. 【核心】动态修复：直到所有 # 行都在代码块外
    result = insert_backtick_before_hash(result)
    
    // 7. （可选）过滤短代码块
    fconlen = char_lengths_including_backticks(result)
    result = select(result, !(fconlen :< 2*(strlen("```")+2)))   
    
    fcon = result
    // 将md源代码插入到<iframe ></iframe>位置
    // 首先使用正则表达式找到 任意空格<iframe任意空格*.md任意空格></iframe>任意空格 的行
    regex = `"(\s*<iframe\s*.*\.md\s*></iframe>\s*)"'
    flag = selectindex(regexm(fcon, regex))
    fconnew = fcon
    if (sum(flag) > 0) {
        if (flag[i]<length(fcon)){
            fconnew = fcon[1::(flag[1]-1)]
        }
        else{
            fconnew = J(0,1,"")
        }
        for(i=1; i<=length(flag); i++) {
            mdtext = extractmdtable(fcon[flag[i]])
            fconnew = fconnew \ mdtext 
            if((flag[i]<length(fcon)) & (i<length(flag))) {
              fconnew = fconnew \ fcon[(flag[i]+1)::(flag[i+1]-1)]
             }
             else if(((flag[i]<length(fcon)) & (i==length(flag)))) {
                fconnew = fconnew \ fcon[(flag[i]+1)::length(fcon)]
             }
        }
    }
    result = fconnew
    

    // 8b. 在代码块之间插入两个空行
    //result = add_two_blank_lines(result)

    // 9. 输出
    if (replace == 0) {
        mm_outsheet(out_md, result)
    }
    if (replace == 1) {
        mm_outsheet(out_md, result, "replace")
    }

}

void function write_github_css(string scalar filepath)
{
    css = J(0, 1, "")
    css = css \ ":root {"
    css = css \ "    --side-bar-bg-color: #fafafa;"
    css = css \ "    --control-text-color: #777;"
    css = css \ "    --font-sans-serif: " + char(34) + "Open Sans" + char(34) + ", " + char(34) + "Clear Sans" + char(34) + ", " + char(34) + "Helvetica Neue" + char(34) + ", Helvetica, Arial, sans-serif;"
    css = css \ "    --font-monospace: " + char(34) + "Consolas" + char(34) + ", " + char(34) + "Monaco" + char(34) + ", " + char(34) + "Bitstream Vera Sans Mono" + char(34) + ", " + char(34) + "Courier New" + char(34) + ", monospace;"
    css = css \ "}"
    css = css \ ""
    css = css \ "body {"
    css = css \ "    font-family: var(--font-sans-serif);"
    css = css \ "    font-size: 16px;"
    css = css \ "    line-height: 1.6;"
    css = css \ "    color: #333;"
    css = css \ "    background-color: white;"
    css = css \ "    margin: 0 auto;"
    css = css \ "    padding: 2rem;"
    css = css \ "    max-width: 900px;"
    css = css \ "}"
    css = css \ ""
    css = css \ "/* Headings */"
    css = css \ "h1, h2, h3, h4, h5, h6 {"
    css = css \ "    color: #333;"
    css = css \ "    line-height: 1.25;"
    css = css \ "    margin-top: 24px;"
    css = css \ "    margin-bottom: 16px;"
    css = css \ "    font-weight: bold;"
    css = css \ "}"
    css = css \ ""
    css = css \ "h1 { font-size: 2.25em; padding-bottom: 0.3em; border-bottom: 1px solid #eaecef; }"
    css = css \ "h2 { font-size: 1.75em; padding-bottom: 0.3em; border-bottom: 1px solid #eaecef; }"
    css = css \ "h3 { font-size: 1.5em; }"
    css = css \ "h4 { font-size: 1.25em; }"
    css = css \ "h5 { font-size: 1em; }"
    css = css \ "h6 { font-size: 0.875em; color: #777; }"
    css = css \ ""
    css = css \ "/* Links */"
    css = css \ "a {"
    css = css \ "    color: #4183C4;"
    css = css \ "    text-decoration: none;"
    css = css \ "}"
    css = css \ "a:hover {"
    css = css \ "    text-decoration: underline;"
    css = css \ "}"
    css = css \ ""
    css = css \ "/* Paragraphs & Lists */"
    css = css \ "p, blockquote, ul, ol, dl, table, pre {"
    css = css \ "    margin-top: 0;"
    css = css \ "    margin-bottom: 16px;"
    css = css \ "}"
    css = css \ ""
    css = css \ "ul, ol {"
    css = css \ "    padding-left: 2em;"
    css = css \ "}"
    css = css \ ""
    css = css \ "/* Blockquotes */"
    css = css \ "blockquote {"
    css = css \ "    padding: 0 1em;"
    css = css \ "    color: #777;"
    css = css \ "    border-left: 0.25em solid #dfe2e5;"
    css = css \ "    background: transparent;"
    css = css \ "}"
    css = css \ ""
    css = css \ "/* Tables - GitHub Style */"
    css = css \ "table {"
    css = css \ "    border-collapse: collapse;"
    css = css \ "    border-spacing: 0;"
    css = css \ "    width: 100%;"
    css = css \ "    margin-bottom: 16px;"
    css = css \ "    display: block;"
    css = css \ "    overflow: auto;"
    css = css \ "}"
    css = css \ ""
    css = css \ "table tr {"
    css = css \ "    background-color: #fff;"
    css = css \ "    border-top: 1px solid #c6cbd1;"
    css = css \ "}"
    css = css \ ""
    css = css \ "table tr:nth-child(2n) {"
    css = css \ "    background-color: #f6f8fa;"
    css = css \ "}"
    css = css \ ""
    css = css \ "table th, table td {"
    css = css \ "    border: 1px solid #dfe2e5;"
    css = css \ "    padding: 6px 13px;"
    css = css \ "    margin: 0;"
    css = css \ "}"
    css = css \ ""
    css = css \ "table th {"
    css = css \ "    font-weight: 600;"
    css = css \ "    background-color: #f6f8fa; /* Header background usually distinct */"
    css = css \ "}"
    css = css \ ""
    css = css \ "/* Code Blocks & Inline Code */"
    css = css \ "code, kbd, pre, samp {"
    css = css \ "    font-family: var(--font-monospace);"
    css = css \ "}"
    css = css \ ""
    css = css \ "/* Inline code */"
    css = css \ "code {"
    css = css \ "    background-color: #f3f4f4;"
    css = css \ "    padding: 2px 4px;"
    css = css \ "    border-radius: 3px;"
    css = css \ "    font-size: 0.9em;"
    css = css \ "    margin: 0 2px;"
    css = css \ "}"
    css = css \ ""
    css = css \ "/* Block code (pre) */"
    css = css \ "pre {"
    css = css \ "    background-color: #f8f8f8;"
    css = css \ "    border: 1px solid #e7eaed;"
    css = css \ "    border-radius: 3px;"
    css = css \ "    padding: 16px;"
    css = css \ "    overflow: auto;"
    css = css \ "    line-height: 1.45;"
    css = css \ "}"
    css = css \ ""
    css = css \ "pre code {"
    css = css \ "    background-color: transparent;"
    css = css \ "    padding: 0;"
    css = css \ "    margin: 0;"
    css = css \ "    border: none;"
    css = css \ "    font-size: 100%; /* Reset from inline code size */"
    css = css \ "}"
    css = css \ ""
    css = css \ "/* Specific Stata classes if used */"
    css = css \ ".stlog, .stcmd {"
    css = css \ "    font-family: var(--font-monospace);"
    css = css \ "    white-space: pre-wrap;"
    css = css \ "}"
    css = css \ ""
    css = css \ "/* Horizontal Rule */"
    css = css \ "hr {"
    css = css \ "    height: 0.25em;"
    css = css \ "    padding: 0;"
    css = css \ "    margin: 24px 0;"
    css = css \ "    background-color: #e7e7e7;"
    css = css \ "    border: 0;"
    css = css \ "}"
    css = css \ ""
    css = css \ "/* Images */"
    css = css \ "img {"
    css = css \ "    max-width: 100%;"
    css = css \ "    box-sizing: border-box;"
    css = css \ "}"
    css = css \ ""
    css = css \ "/* MathJax */"
    css = css \ "mjx-container {"
    css = css \ "    overflow-x: auto;"
    css = css \ "    overflow-y: hidden;"
    css = css \ "}"

    mm_outsheet(filepath, css, "replace")
}

void function inject_mathjax(string scalar htmlfile)
{
    lines = cat(htmlfile)
    if (rows(lines) == 0) return

    // avoid duplicate injection
    if (sum(ustrpos(lines, "MathJax-script") :> 0) > 0) return

    script =      "<script>" 
    script = script + "MathJax = {"
    script = script + "  tex: {"
    script = script + "    inlineMath: [['$', '$'], ['\\(', '\\)']],"
    script = script + "    displayMath: [['$$', '$$'], ['\\[', '\\]']]"
    script = script + "  }"
    script = script + "};"
    script = script + "</script>"
    script = script + "<script id=" + char(34) + "MathJax-script" + char(34) + " async src=" + char(34) + "https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js" + char(34) + "></script>"
    
    idx = selectindex(ustrpos(lines, "</head>") :> 0)
    if (rows(idx) > 0) {
        i = idx[1]
        if (i > 1) {
            lines = lines[|1 \ i-1|] \ script \ lines[|i \ rows(lines)|]
        }
        else {
            lines = script \ lines
        }
    }
    else {
        lines = script \ lines
    }

    mm_outsheet(htmlfile, lines, "replace")
}






string colvector function normalize_mdblock_markers(string colvector content)
{
    // /** ... **/  <=>  ishere /* ... ishere */
    lines = content
    for (i = 1; i <= rows(lines); i++) {
        s = ustrltrim(lines[i])
        prefix = ""
        rest = s
        // strip common SMCL / log control prefixes
        changed = 1
        while (changed) {
            changed = 0
            if (ustrpos(rest, "{com}") == 1) {
                rest = ustrltrim(usubstr(rest, 6, .))
                changed = 1
            }
            else if (ustrpos(rest, "{res}") == 1) {
                rest = ustrltrim(usubstr(rest, 6, .))
                changed = 1
            }
            else if (ustrpos(rest, "{txt}") == 1) {
                rest = ustrltrim(usubstr(rest, 6, .))
                changed = 1
            }
        }
        // optional Stata prompt
        if (usubstr(rest, 1, 1) == "." | usubstr(rest, 1, 1) == ">") {
            prefix = usubstr(rest, 1, 1) + " "
            rest = ustrltrim(usubstr(rest, 2, .))
        }
        token = usubinstr(rest, " ", "", .)
        if (token == "/**") {
            lines[i] = prefix + "ishere /*"
        }
        else if (token == "**/") {
            lines[i] = prefix + "ishere */"
        }
    }
    return(lines)
}

string colvector clean_textcell_content(string colvector lines)
{
  // 必须放在开始处理
  lines = normalize_mdblock_markers(lines)
  lines2 = strltrim(lines)
  lines2 = strltrim(substr(lines2,2,.))
  r1 = ustrpos(lines2, "ishere") :== 1
  
  lines2 = strltrim(substr(lines2, ustrlen("ishere")+1, .))
  r12 = ustrpos(lines2,"/*") :== 1
  r22 = ustrpos(lines2,"*/") :== 1
  r12 = r1 :& r12
  
  r22 = r1 :& r22
  
  if (sum(r12)!=sum(r22)){
       errprintf("Error: unmatched ishere /* and */ (/**) (**/)\n")
       _error(199)
   }
  if (sum(r12)==0){ 
    return(lines)
  }
  idx12 = select(1::rows(lines), r12)
  idx22 = select(1::rows(lines), r22)

   if (length(idx12)!=length(idx22)){
       errprintf("Error: unmatched ishere /* and */ (/**) (**/)\n")
       _error(199)
   }
   if (length(idx12)>0){
       for (i=1;i<=length(idx12);i++){
           if (idx12[i]>=idx22[i]) {
                errprintf("Error: unmatched ishere /* and */ (/**) (**/)\n")
               _error(199)
           }
           if ((i+1) < length(idx12)) {
		   	 if (idx12[i]<length(lines) & idx12[i+1] < idx22[i]) {
                errprintf("Error: overlapping ishere /* and */ (/**) (**/)\n")
                _error(199)    
               }
		   	
		   }
           
        lines[idx12[i]..idx22[i]] = substr(lines[idx12[i]..idx22[i]],2,.)
        lines[idx12[i]] = "_ishere_/*"
        lines[idx22[i]] = "_ishere_*/"
      }
   }
   return(lines)

}




// a new function moving lines starting with <img or <iframe to the next line if the next line starts with . ishere tab or fig
real colvector get_textcell_index(string colvector lines)
{
   text_start = selectindex(lines:=="_ishere_/*")
   text_end = selectindex(lines:=="_ishere_*/")
   text_idx = J(rows(lines),1,0)
   for (i=1;i<=length(text_start);i++){ 
       text_idx[text_start[i]::text_end[i]] = J(length(text_start[i]::text_end[i]),1,i)
   }
    return(text_idx)
}



string colvector function get_dot_header(string colvector lines)
{
    lines2 = strltrim(lines)
    flag = (ustrpos(lines2, ".") :== 1)
    lines3 = strltrim(substr(lines2, 2, .))
    flag2 = (ustrpos(lines3, "ishere") :== 1)
    lines3 = strltrim(substr(lines3,strlen("ishere")+1,.))
    flag3 = (ustrpos(lines3, "#") :== 1)
    flag = flag :& flag2 :& flag3
    if (sum(flag) > 0) {
        idx = selectindex(flag)
        lines[idx] = lines3[idx]
    }
    return(lines)
}


string colvector function get_header(string colvector lines)
{
    lines2 = strltrim(lines)
    flag = (ustrpos(lines2, "ishere") :== 1)
    lines2 = strltrim(substr(lines2,strlen("ishere")+1,.))
    flag2 = (ustrpos(lines2, "#") :== 1)
    flag = flag :& flag2 
    if (sum(flag) > 0) {
        idx = selectindex(flag)
        lines[idx] = lines2[idx]
    }
    return(lines)
}


string colvector function check_isheretxt_closed(string colvector lines)
{ 
  lines = normalize_mdblock_markers(lines)
  lines2 = usubinstr(lines, " ", "", .)
  flag1 = (ustrpos(lines2, "ishere/*") :== 1)
  flag2 = (ustrpos(lines2, "ishere*/") :== 1)
  if (sum(flag1)!=sum(flag2)){
       errprintf("Error: unmatched ishere /* and */ (/**) (**/)\n")
       _error(199)
   }
   if (sum(flag1)==0){ 
        return(lines)
   }
   idx1 = selectindex(flag1)
   idx2 = selectindex(flag2)

   for (i=1;i<=length(idx1);i++){
      if (idx2[i]<=idx1[i]) {
        errprintf("Error: unmatched ishere /* and */ (/**) (**/)\n")
        _error(199)
       }
       if ((i+1) < length(idx1)) {
         if (idx1[i]<length(lines) & idx1[i+1] < idx2[i]) {
            errprintf("Error: overlapping ishere /* and */ (/**) (**/)\n")
            _error(199)    
          }
        }
        lines[idx1[i]] = "_ishere_/*"
        lines[idx2[i]] = "_ishere_*/"

   }

   return(lines)


}

real scalar lastpos(string scalar s, string scalar ch)
{
    i = strlen(s)
    while (i >= 1) {
        if (substr(s, i, 1) == ch) return(i)
        i = i - 1
    }
    return(0)
}
string scalar normalize_path(string scalar p)
{
    // handle Windows backslashes (single or doubled)
    p = subinstr(p, "\\", "/", .)
    p = subinstr(p, "\", "/", .)
    // remove trailing slash
    while (strlen(p) > 1 & substr(p, strlen(p), 1) == "/") {
        p = substr(p, 1, strlen(p) - 1)
    }
    return(p)
}

string colvector function subisheredintxt(string colvector lines)
{
    n = rows(lines)
    if (n == 0) return(lines)
    
    lines2 = strltrim(lines)
    textflag = get_textcell_index(lines2)
    
    // Step 1: 找到所有 . ishere display 命令行及其输出值
    flag = (ustrpos(lines2, ".") :== 1)
    lines3 = strltrim(substr(lines2, 2, .))
    flag = flag :& (ustrpos(lines3, "ishere") :== 1)
    lines4 = strtrim(substr(lines3, strlen("ishere")+1, .))
    flag = flag :& (ustrpos(lines4, "display") :== 1)
    
    if (sum(flag) == 0 | sum(textflag) == 0) {
        return(lines)
    }
    
    // Step 2: 提取 display 参数（去除多余空格）
    lines5 = substr(lines4, strlen("display")+1, .)
    lines5 = strtrim(lines5)
    dispcmd = select(lines5, flag)
    
    // Step 3: 获取显示值（下一行的内容）
    idx = selectindex(flag)
    n_displays = rows(idx)
    //n_displays
    
    // inshere display only act in the following one textcell.
    
    for (i = 1; i <= n_displays; i++) {
        //dispcmd[i]
        pattern = "\{\s*ishere\s+display\s*" + dispcmd[i] + "\s*\}"
        if (idx[i] + 1 <= n) {
            textrow =select(textflag, ((1::n):>idx[i]+1):*textflag)
            if (length(textrow)){
                text_j =selectindex(textflag:==textrow[1])
                lines[text_j] =ustrregexra(lines[text_j], pattern, " "+strtrim(lines[idx[i]+1])+" ")
            }
        }
    }
    
    
    
    return(lines)
}


end


///////////////////////////
capture program drop alltohtml
program define alltohtml,rclass
    version 16
    syntax anything, [width(string) height(string) zoom(string)]
    
    // check directory exists
    if "`zoom'"=="" local zoom "100%"
    else{
        if strpos("`zoom'", "%") == 0 local zoom "`zoom'%"
    }
    
    if "`height'" == "" local height "400px"
    if "`width'" == "" local width "100%"    
    local zoomstyle  style="zoom:`zoom';"
    mata: ifig = `"<img src="_filepath_" `zoomstyle' />"'

    mata: tables = J(0,1,"")
    mata: tabletitles = J(0,1,"")

    // normalize path
    foreach folder in `anything' {

        local folder = subinstr(`"`folder'"', "\", "/", .)
        // if ends with / remove
        if substr(`"`folder'"', -1, 1) == "/" local folder = substr(`"`folder'"', 1, strlen(`"`folder'"')-1)
    
        // check directory exists
        mata: st_numscalar("pathexists",direxists(st_local("folder")))
        if pathexists == 0 {
            display as error "Directory `folder' does not exist."
            exit 198
        }
        mata: itab = "<iframe src='_filepath_' width='`width'' height='`height'' frameBorder='0'></iframe>"
        quietly fs "`folder'/table*.html"

        foreach file in `r(files)' {
           local file `file'
           mata: tabletitles = tabletitles \ `"`file'"'
           local file `folder'/`file'
           mata: tables = tables \ usubinstr(itab,"_filepath_",`"`file'"',1)
        }

        mata: itab = "<iframe _filepath_ ></iframe>"
        quietly fs "`folder'/table*.md"
        foreach file in `r(files)' {
            local file `file'
            mata: tabletitles = tabletitles \ `"`file'"'
            local file `folder'/`file'
            mata: tables = tables \ usubinstr(itab,"_filepath_",`"`file'"',1)
        }
    
        // common image extensions for files starting with 'figure'
        foreach ext in png jpg jpeg svg gif bmp webp {
            quietly fs "`folder'/figure*.`ext'"
            foreach file in `r(files)' {
              local file `file'
              mata: tabletitles = tabletitles \ `"`file'"'
              local file `folder'/`file'
              mata: tables = tables \ usubinstr(ifig,"_filepath_",`"`file'"',1)
            }
        }



    }     


    // use fs (assumed present) to list files in the folder
    // Collect HTML tables and figure-prefixed images
 

    // html files

    mata: st_numscalar("ntables", length(tables))

    if ntables == 0 {
        display  `"No tables or figures found in `folder'"'
        //exit 
    }
    

    mata: tables = tables, ("### " :+ tabletitles)
    local templog `"`c(pwd)'/_tempfile_log_.md"'
    mata: write_log(tables)
    cap confirm file `"`templog'"'
    if _rc == 0 {
        display `"`templog' created"'
        return local templog `templog'
    }
    

end

mata:
void write_log(string matrix tables)
{
   n = rows(tables)
   if (n==0) exit
   tables = sort(tables, 2)   // 按第二列排序后再写出
   fh ="# Figures and Tables"
   for(i=1; i<=n; i++) {
    fh = fh \ "" \ ""
    fh = fh \ tables[i,2] \ tables[i,1]
   }
   mm_outsheet(st_local("templog"), fh, "replace")

}

string colvector function ishererep(string colvector content)
{
    lines =content
    lines2 = usubinstr(lines," ","",.)
    flag = selectindex(ustrpos(lines2, ".**#") :== 1)
    if (length(flag) > 0) {
       lines[flag] = ustrltrim(lines[flag])
       lines[flag] = ustrregexra(lines[flag], "^\.\s*\*\*\s*", ". ishere ")
    }
    flag = selectindex(ustrpos(lines2, ".**/*") :== 1)
    if (length(flag) > 0) {
       lines[flag] = ustrltrim(lines[flag])
       lines[flag] = ustrregexra(lines[flag], "^\.\s*\*\*\s*", ". ishere ")
    }
    flag = selectindex(ustrpos(lines2, ">***/") :== 1)
    if (length(flag) > 0) {
       lines[flag] = ustrltrim(lines[flag])
       lines[flag] = ustrregexra(lines[flag], "^\>\s*\*\*\s*", "> ishere ")
    }

    flag = selectindex(ustrpos(lines2, ".**```") :== 1)
    if (length(flag) > 0) {
       lines[flag] = ustrltrim(lines[flag])
       lines[flag] = ustrregexra(lines[flag], "^\.\s*\*\*\s*", ". ishere ")
    }
    return(lines)
}


string colvector function ishererep2(string colvector content)
{
    lines =content
    lines2 = usubinstr(lines," ","",.)
    flag = selectindex(ustrpos(lines2, "**#") :== 1)
    if (length(flag) > 0) {
       lines[flag] = ustrltrim(lines[flag])
       lines[flag] = ustrregexra(lines[flag], "^\s*\*\*\s*", "ishere ")
    }
    flag = selectindex(ustrpos(lines2, "**/*") :== 1)
    if (length(flag) > 0) {
       lines[flag] = ustrltrim(lines[flag])
       lines[flag] = ustrregexra(lines[flag], "^\s*\*\*\s*", "ishere ")
    }
    flag = selectindex(ustrpos(lines2, "***/") :== 1)
    if (length(flag) > 0) {
       lines[flag] = ustrltrim(lines[flag])
       lines[flag] = ustrregexra(lines[flag], "^\s*\*\*\s*", "ishere ")
    }

    flag = selectindex(ustrpos(lines2, "**```") :== 1)
    if (length(flag) > 0) {
       lines[flag] = ustrltrim(lines[flag])
       lines[flag] = ustrregexra(lines[flag], "^\s*\*\*\s*", "ishere ")
    }
    return(lines)
}

end

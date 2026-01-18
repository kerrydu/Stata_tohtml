capture program drop graph2md
program define graph2md
    // Simplified single SAVE() option
    syntax , [ SAVE(string) RESet NUMber ALT(string) LABel(string) HT(real 3) ZOOM(string) * IShere ISHEREtext(string) ]

    // 目标文件名
    if "`save'" == "" {
        if "$graph2md_savefile" != "" {
            local savefile $graph2md_savefile
        }
        else {
            local savefile defaultgraphname
        }
    }
    else {
        local savefile `save'
    }

    // 重置计数
    if "`reset'" != "" global graph2md_graphnum = 0

    // 自动编号
    if "`number'" != "" {
        global graph2md_graphnum = $graph2md_graphnum + 1
        local savefile `savefile'$graph2md_graphnum
    }

    quietly graph export `savefile', `options'
    
    noisily display "% exported graph to `savefile'"
    mata: st_local("filename", pathbasename("`savefile'"))
    // Markdown 图片行
    // 默认 alt 使用文件名（不含路径），而非完整路径
    local p1 = strrpos("`savefile'", "/")
    local p2 = strrpos("`savefile'", "\")
    local lastslash = max(`p1', `p2')
    if `lastslash' > 0 local shortfile = substr("`savefile'", `lastslash' + 1, .)
    else                local shortfile "`savefile'"
    local alttext = cond("`alt'" == "", "`shortfile'", "`alt'")
    local zoomstyle ""
    local zoomval "`zoom'"
    if "`zoomval'" != "" {
        if regexm("`zoomval'","^[0-9]+(\\.[0-9]+)?$") {
            local zoomval "`zoomval'%"
        }
        local zoomstyle `" style="zoom:`zoomval';""'
    }
    local htmlimg = `"<img src="`savefile'"`zoomstyle' />"'
    if `"`isheretext'"'!="" local ishere ishere 

    if "`ishere'" != "" {

    noisily display "                       "
    // 输出 HTML 代码
    noisily display `"`htmlimg'"'
    // noisily display "ishere Figure `filename'"
    noisily display   
     if "`isheretext'" != "" {
        noisily display "`isheretext'"
      }
   }
end
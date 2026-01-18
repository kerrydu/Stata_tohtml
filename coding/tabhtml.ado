capture program drop tabhtml
program define tabhtml
    version 14

    // Allow colon syntax: tabhtml ... : <command>
    _on_colon_parse `0'
    local command `"`s(after)'"'
    local 0 `"`s(before)'"'

    // Options: iframe width (%), height (px), optional direct src()
    syntax , [ WIDTH(real 100) HEIGHT(real 500) SRC(string) ]

    if `width' <= 0 local width = 100
    if `height' <= 0 local height = 500

    // Execute the user command
    capture noisily `command'
    local rc = _rc
    if `rc' {
        di as error "tabhtml: command failed with return code `rc'"
        exit `rc'
    }



    // Determine HTML file path
    local htmlfile `"`src'"'
    if "`htmlfile'" == "" {
        gethtml `command'

        local htmlfile `r(html)'
    }

    if "`htmlfile'" == "" {
        di as error "tabhtml: unable to detect HTML file. Specify src()."
        exit 198
    }

    // Build iframe snippet
    local percent "%"
    local widthstr = string(`width', "%9.0g")
    local heightstr = string(`height', "%9.0g")
    local iframe "<iframe src='`htmlfile'' width='`widthstr'`percent'' height='`heightstr'px' frameBorder='0'></iframe>"

    // Emit Markdown-friendly fenced block
    noisily display "```"
    noisily display `"`iframe'"'
    noisily display "```"
end


program define gethtml,rclass
    version 14

    syntax [anything] [using/] , [* saving(string) save(string)]

    // Return the HTML file path

    if `"`using'"' == "" { 
           local htmlfile = ustrpos(`"`using'"', ".html")
            if _rc local htmlfile = ustrpos("`using'", ".html")
            if `htmlfile' == 0 {
                if ustrpos(`"`anything'"', "outreg2e") {
                    local htmlfie 1
                    local using `using'.html
             }
            }
            if `htmlfile' == 0 {
                di as error "tabhtml: unable to detect HTML file. Specify src()."
                exit 198
            }
    }

    if `"`saving'"' != "" {
        local htmlfile = ustrpos(`"`saving'"', ".html")
        if _rc local htmlfile = ustrpos("`saving'", ".html")
        if `htmlfile' == 0 {
            di as error "tabhtml: unable to detect HTML file. Specify src()."
            exit 198
        }
    }

    if `"`save'"' != "" {
        local htmlfile = ustrpos(`"`save'"', ".html")
        if _rc local htmlfile = ustrpos("`save'", ".html")
        if `htmlfile' == 0 {
            di as error "tabhtml: unable to detect HTML file. Specify src()."
            exit 198
        }
    }
    
    return local html `using'
end

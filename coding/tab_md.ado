program define tab_md
    version 14
    syntax anything(name=filename id="filename") [, Height(string) Width(string) Zoom(string)]

    // Remove quotes from filename if present
    local filename `filename'
    
    // Extract Extension
    if strpos("`filename'", ".") == 0 {
        display as error "Filename must have an extension."
        exit 198
    }
    mata: st_local("extension", pathsuffix("`filename'"))
    local extension = lower("`extension'")
    
    // HTML Logic (iframe)
    if inlist("`extension'", ".html", ".htm") {
        if "`height'" == "" local height "500px"
        if "`width'" == "" local width "100%"
        display `"<iframe src='`filename'' width='`width'' height='`height'' frameBorder='0'></iframe>"'
    }
    // Image Logic
    else if inlist("`extension'", ".png", ".jpg", ".jpeg", ".svg", ".gif", ".bmp") {
        if "`zoom'" != "" {
            if strpos("`zoom'", "%") == 0 local zoom "`zoom'%"
            display `"<img src="`filename'" style="zoom:`zoom';">"'
        }
        else {
            display "![](`filename')"
        }
    }
    // Other files (Link)
    else {
        display "[`filename'](`filename')"
    }
end

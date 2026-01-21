*! version 1.0.1  Fixed describe error and log logic
*! Captures raw Stata output to HTML <pre> block
program define logout4
    version 7.0

    // --- 1. Parsing Options & Command ---
    // Syntax: logout4 [options] : command
    
    local original `"`0'"'
    
    // Split 0 into options (left) and command (right) using colon as delimiter
    gettoken first second : 0, parse(":") 
    
    local 0 `"`first'"'

    // Check if colon exists
    local colon_pos = strpos(`"`original'"', ":")
    if `colon_pos' == 0 {
        di as err "Error: Syntax is logout4 [options] : command"
        exit 198
    }

    // Clean up the command part (remove leading colon)
    gettoken colon command : second, parse(":")
    if `"`colon'"' != ":" {
        // Handle case where colon was part of standard token parsing but not first char
        local command `"`second'"' 
    }
    
    // Parse options
    syntax, save(string) [replace NOIsily IShere ISHEREtext(string)]

    // Validate Save Path
    local htmlFile `"`save'.html"'
    
    if "`replace'" == "" {
        capture confirm file `"`htmlFile'"'
        if _rc == 0 {
            di as err "File `htmlFile' already exists. Use Replace option."
            exit 602
        }
    }

    // --- 2. Log Switching Logic (The Core) ---
    // capture current log filename directly
    qui log query
    local current_log  `r(log)'

    // Temporary log file
    tempfile tmplog
    
    quietly {
        // A. Suspend Logic: Close current log output to file
        if `"`current_log'"' != "" {
            log close
        }

        // B. Capture Logic: Open temp log, run command, close temp log
        log using `"`tmplog'"', text replace
            
        // Run the command
        noisily {
            if "`noisily'" != "" {
                di as txt "> `command'"
            }
            capture noisily `command'
        }
        local rc = _rc
        
        log close

        // C. Restore Logic: Re-open original log in append mode
        if `"`current_log'"' != "" {
            log using `"`current_log'"', append
        }
    }

    // Error handling for the captured command
    if `rc' != 0 {
        di as err "The captured command failed with error `rc'."
        exit `rc'
    }

    // --- 3. HTML Wrapping (Raw Text -> HTML <pre>) ---
    
    tempname fh_in fh_out
    file open `fh_in' using `"`tmplog'"', read
    file open `fh_out' using `"`htmlFile'"', write  replace

    // CSS for raw output
    local table_center = ("$table_center"=="1")
    local body_align = cond(`table_center', "display:flex;justify-content:center;", "")

    file write `fh_out' "<!DOCTYPE html>" _n
    file write `fh_out' "<html><head><meta charset='utf-8'>" _n
    file write `fh_out' "<style>" _n
    file write `fh_out' "body { `body_align' margin:0; padding:10px; font-family: 'Consolas', 'Monaco', 'Courier New', monospace; font-size: 13px; background-color: white; }" _n
    file write `fh_out' "pre { margin: 0; white-space: pre-wrap; word-wrap: break-word; }" _n
    file write `fh_out' "</style></head><body>" _n
    file write `fh_out' "<pre>" _n

    // Initialize line counter for height calculation
    local line_count = 0

    file read `fh_in' line
    while r(eof) == 0 {
        local line_count = `line_count' + 1
        
        // Escape HTML special chars to prevent rendering issues
        local line : subinstr local line "&" "&amp;", all
        local line : subinstr local line "<" "&lt;", all
        local line : subinstr local line ">" "&gt;", all
        
        // Remove Stata log headers/footers if detected (simple heuristic)
        if substr(trim(`"`line'"'), 1, 5) != ". log" & substr(trim(`"`line'"'), 1, 8) != "name:  <" {
             file write `fh_out' `"`macval(line)'"' _n
        }
        
        file read `fh_in' line
    }

    file write `fh_out' "</pre>" _n
    file write `fh_out' "</body></html>" _n

    file close `fh_out'
    file close `fh_in'

    // --- 4. Markdown Iframe Output ---
    
    // Globals for dimension control (consistent with outreg3/logout3)
    local width = 100
    capture confirm global tabwidth
    if !_rc {
        local width = $tabwidth
    }
    
    // Auto-calculate height based on counted lines
    local height = 400
    capture confirm global tabheight
    if !_rc {
        local height = $tabheight
    }
    else {
        // Adaptive height: ~40px padding + 16px per line
        local height = 40 + `line_count' * 16
    }

    local percent "%"
    local widthstr = string(`width', "%9.0g")
    
    // Generate Iframe Code for Markdown2
    di as txt _n "Output saved to `htmlFile'"
    if `"`isheretext'"'!="" local ishere ishere 
    if "`ishere'"!="" {
        di 
        di `"<iframe src='`htmlFile'' width='`widthstr'`percent'' height='`height'px' frameBorder='0'></iframe>"'
        di 
        if `"`isheretext'"'!="" {
            di `"`isheretext'"'
        }

    }
                       "

end
*! version 2.0.0  21jan2026
* ishere_exec - Execute and capture ishere statement output
* Wrapper command for the ishere_translate_line Mata function

program define ishere_exec, rclass
    version 14
    
    // Get the full command line
    local 0 `0'
    
    // Load Mata function if not already loaded
    quietly {
        capture mata: mata which ishere_translate_line
        if _rc {
            do ishere_translator.mata
        }
    }
    
    // Call the Mata function for single line processing
    mata: st_local("result", ishere_translate_line(`"`0'"'))
    
    // Return the result
    return local result `"`result'"'
    
    // Display the result if not empty
    if `"`result'"' != "" {
        display `"`result'"'
    }
end

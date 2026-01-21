// Mata function to parse and execute ishere statements using regex
// Returns the output string of ishere commands without using Stata log output

mata:
mata clear

// Main function to translate ishere statements from file lines
string colvector ishere_translate(string colvector lines)
{
    results = J(rows(lines), 1, "")
    textflag = get_textcell_index(lines)
    
    for (i=1; i<=rows(lines); i++) {
        line = strtrim(lines[i])
        
        // Check if line starts with "ishere"
        if (regexm(line, "^ishere\s+") | line == "ishere") {
            // Parse and translate the ishere statement
            result = parse_ishere_statement(line)
            results[i] = result
        }
        else if (textflag[i] > 0) {
            results[i] = replace_ishere_display_blocks(lines[i])
        }
        else{
            results[i] = line
        }
    }
    
    return(results)
}

// Parse a single ishere statement and return its value
string scalar parse_ishere_statement(string scalar line)
{
    
    // Remove "ishere" prefix
    cmd = regexr(line, "^ishere\s*", "")
    cmd = strtrim(cmd)
    
    // If empty after removing "ishere", return empty
    if (cmd == "") return("```")
    if (ustrpos(cmd,"#")==1) return(cmd)
    
    // Extract the first word (subcmd)
    if (regexm(cmd, "^(\w+)(.*)")) {
        subcmd = strlower(regexs(1))
        rest = strtrim(regexs(2))
    }
    else {
        return("")
    }
    
    // Check command type
    if (subcmd == "display") {
        return("")
    }
    else if (subcmd == "fig" | subcmd == "figure") {
        return(parse_figure_command(rest))
    }
    else if (subcmd == "tab" | subcmd == "table") {
        return(parse_table_command(rest))
    }
    else {
        // Placeholder command - return empty
        return("")
    }
}

// Parse display command and return the displayed text
string colvector replace_ishere_display_blocks(string colvector lines)
{
    string scalar line, pattern, replacement
    real scalar i
    
    // Pattern: {任意空格+ishere+display+任意字符+任意空格+}
    // 支持多种空格组合
    pattern = "\{\s*ishere\s+display\s+(.*?)\s*\}"
    
    for (i=1; i<=rows(lines); i++) {
        line = lines[i]
        
        // 循环替换，因为一行可能有多个匹配
        while (regexm(line, pattern)) {
            replacement = regexs(1)
			replacement
            line = regexr(line, pattern, "'"+ replacement + "'")
        }
        
        lines[i] = line
    }
    
    return(lines)
}

// Parse figure command and return markdown
string scalar parse_figure_command(string scalar args)
{
    
    // Extract using clause: using "file" or using file
    if (regexm(args, "using\s+" + char(34) + "([^" + char(34) + "]+)" + char(34))) {
        filepath = regexs(1)
    }
    else if (regexm(args, "using\s+`" + char(34) + "([^" + char(34) + "]+)" + char(34) + "'")) {
        filepath = regexs(1)
    }
    else if (regexm(args, "using\s+([^\s,]+)")) {
        filepath = regexs(1)
    }
    else {
        return("") // No file specified
    }
    
    // Normalize path separators
    filepath = subinstr(filepath, "\", "/", .)
    
    // Extract options
    zoom = regexm(args, "zoom\(([^\)]+)\)") ? regexs(1) : ""
    width = regexm(args, "width\(([^\)]+)\)") ? regexs(1) : ""
    height = regexm(args, "height\(([^\)]+)\)") ? regexs(1) : ""
    
    // Get file extension
    extension = pathsuffix(filepath)
    extension = strlower(extension)
    
    // Generate markdown based on options
    if (zoom != "") {
        if (!regexm(zoom, "%$")) zoom = zoom + "%"
        result = "<img src=" + char(34) + filepath + char(34) + " style=" + char(34) + "zoom:" + zoom + ";" + char(34) + ">"
    }
    else if (width != "" | height != "") {
        if (width == "") width = "auto"
        if (height == "") height = "auto"
        result = "<img src=" + char(34) + filepath + char(34) + " width=" + char(34) + width + char(34) + " height=" + char(34) + height + char(34) + ">"
    }
    else {
        // Default markdown image syntax
        result = "![](" + filepath + ")"
    }
    
    return(result)
}

// Parse table command and return iframe HTML
string scalar parse_table_command(string scalar args)
{
    
    // Extract using clause
    if (regexm(args, "using\s+" + char(34) + "([^" + char(34) + "]+)" + char(34))) {
        filepath = regexs(1)
    }
    else if (regexm(args, "using\s+`" + char(34) + "([^" + char(34) + "]+)" + char(34) + "'")) {
        filepath = regexs(1)
    }
    else if (regexm(args, "using\s+([^\s,]+)")) {
        filepath = regexs(1)
    }
    else {
        return("") // No file specified
    }
    
    // Normalize path separators
    filepath = subinstr(filepath, "\", "/", .)
    
    // Extract options
    width = regexm(args, "width\(([^\)]+)\)") ? regexs(1) : "100%"
    height = regexm(args, "height\(([^\)]+)\)") ? regexs(1) : "400px"
    
    // Get file extension
    extension = pathsuffix(filepath)
    extension = strlower(extension)
    
    // Generate HTML iframe for HTML tables
    if (extension == ".html" | extension == ".htm") {
        result = "<iframe src='" + filepath + "' width='" + width + "' height='" + height + "' frameBorder='0'></iframe>"
    }
    else {
        // Default: just a link
        //result = "[Table](" + filepath + ")"
        result = ""
    }
    
    return(result)
}

// Helper function to read file and process all lines
string colvector process_file(string scalar filename)
{
    
    lines = read_file_lines(filename)
    return(ishere_translate(lines))
}

// Read all lines from a file
string colvector read_file_lines(string scalar filename)
{
   
    return(cat(filename))
}

// Wrapper function for single line processing
string scalar ishere_translate_line(string scalar line)
{
    
    input = line
    output = ishere_translate(input)
    
    return(output[1])
}

real colvector get_textcell_index(string colvector lines)
{
   lines2 = strtrim(lines)
   flag = (ustrpos(lines2,"ishere") :== 1)
   lines3 = substr(lines2,strlen("ishere")+1,.)
   flag_start =flag:*(ustrpos(lines3,"/*") :== 1)
   text_start = selectindex(flag_start)
   flag_end =flag:*(ustrpos(lines3,"*/") :== 1)
   text_end = selectindex(flag_end)
   text_idx = J(rows(lines),1,0)
   if (length(text_start)!=length(text_end)) {
    errprintf("Error: unmatched ishere /* and */\n")
    _error(199)
   }
   for (i=1;i<=length(text_start);i++){ 
       if(text_start[i]>=text_end[i]) {
        errprintf("Error: unmatched ishere /* and */\n")
        _error(199)
       }
       if((i+1) < length(text_start)) {
            if(text_start[i]<length(lines) & text_start[i+1] < text_end[i]) {
                errprintf("Error: overlapping ishere /* and */\n")
                _error(199)
        }
       }
       text_idx[text_start[i]::text_end[i]] = J(length(text_start[i]::text_end[i]),1,i)
   }
    return(text_idx)
}


end

program define cmdcell 
version 8
syntax [anything]
local x `anything'
if ustrltrim("`x'") == "0" {
    disp "```"
}
if ustrltrim("`x'") == "1" {
    disp "```"
}
if ustrltrim("`x'") == "" {
    disp "```"
}
if ustrltrim("`x'") == "begin" {
    disp "```"
}

if ustrltrim("`x'") == "end" {
    disp "```"
}

if ustrpos(ustrltrim("`x'"),"#")==1 {
    disp "`x'"
}

end
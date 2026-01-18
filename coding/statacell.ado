
program define statacell 
args x
if "`x'" == "0" {
    disp "``` stata"
}
if "`x'" == "1" {
    disp "```"
}
if strpos("`x'","#")==1 {
    disp "`x'"
}
if "`x'" == ""{
    disp "```"
}
end
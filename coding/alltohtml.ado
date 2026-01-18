capture program drop alltohtml
program define alltohtml,rclass
    version 16
    syntax anything, [width(string) height(string) zoom(string)]
    
    // normalize path
    local folder `anything'
    local folder = subinstr(`"`folder'"', "\", "/", .)
    // if ends with / remove
    if substr(`"`folder'"', -1, 1) == "/" local folder = substr(`"`folder'"', 1, strlen(`"`folder'"')-1)
    if "`zoom'"=="" local zoom "100%"
    else{
        if strpos("`zoom'", "%") == 0 local zoom "`zoom'%"
    }
    
    if "`height'" == "" local height "400px"
    if "`width'" == "" local width "100%"    

    // check directory exists
    mata: st_numscalar("pathexists",direxists(st_local("folder")))
    if pathexists == 0 {
        display as error "Directory `folder' does not exist."
        exit 198
    }

    // use fs (assumed present) to list files in the folder
    // Collect HTML tables and figure-prefixed images
 
    mata: tables = J(0,1,"")
    mata: tabletitles = J(0,1,"")
    mata: itab = "<iframe src='_filepath_' width='`width'' height='`height'' frameBorder='0'></iframe>"
    // html files

    quietly fs "`folder'/table*.html"

    foreach file in `r(files)' {
       local file `file'
       mata: tabletitles = tabletitles \ `"`file'"'
       local file `folder'/`file'
       mata: tables = tables \ usubinstr(itab,"_filepath_",`"`file'"',1)
    }

    local zoomstyle `" style="zoom:`zoom';""'
    mata: itab = `"<img src="_filepath_" "`zoomstyle' />"'
    // common image extensions for files starting with 'figure'
    foreach ext in png jpg jpeg svg gif bmp webp {
        quietly fs "`folder'/figure*.`ext'"
        foreach file in `r(files)' {
          local file `file'
          mata: tabletitles = tabletitles \ `"`file'"'
          local file `folder'/`file'
          mata: tables = tables \ usubinstr(itab,"_filepath_",`"`file'"',1)
        }
    }

    mata: st_numscalar("ntables", length(tables))

    if ntables == 0 {
        display  `"No tables or figures found in `folder'"'
        exit 
    }
    mata: tables = tables, ("### " :+ tabletitles)
    local templog `"`folder'/_tempfile_log_.md"'
    mata: write_log(tables)
    cap confirm file `"`folder'/_tempfile_log_.md"'
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
   fh ="# Tables and Figures"
   for(i=1; i<=n; i++) {
    fh = fh \ "" \ ""
    fh = fh \ tables[i,2] \ tables[i,1]
   }
   mm_outsheet(st_local("templog"), fh, "replace")

}
end

// Usage:
//   markdown2 logfile.md, clean saving(out.clean.md) [replace]
//   markdown2 logfile.md, cleancode(cmdlog.md) saving(out.code.md) [replace]
//   cleancode logfile.md, cmdlog(cmdlog.md) saving(out.code.md) [replace]
capture program drop markdown2
program define markdown2
    // Clean markdown log: remove 'cmdcell' lines, strip leading '>'
    syntax anything ,  [ SAVing(string) REPlace HTML(string) CSS(string) RPath(string) WPath(string) CLEAN CLEANCODE(string)]

    removequotes , t(`anything')
    local anything  `r(s)'

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
    local llp ./
    if "`wpath'" != "" {
        // check if wpath is a url
        mata: st_numscalar("wflag",isurl("`wpath'"))
        if wflag==0 {
            di as error "`wpath' is not a valid url"
            exit 601
        }
        local llp `wpath'
      
    }

    if "`rpath'"!=""{
        // check if the directory path exist
        mata: st_numscalar("rflag",direxists("`rpath'")) 
        if rflag==0 {
            di as error "directory `rpath' does not exist"
            exit 601
        }
        // convert \ in rpath to /
        local rpath = usubinstr(`"`rpath'"', "\", "/", .)
        // if the last character is not /, add it
        if ustrpos(`"`rpath'"', "/") != ustrlen(`"`rpath'"') {
            local rpath = `"`rpath'/"' 
        }
    }
    // Resolve paths
    local infile `using'
    local outfile `saving'

    // If outfile exists and no replace, stop
    capture confirm file `"`outfile'"'
    if _rc == 0 & "`replace'" == "" {
        di as error "output file exists; use replace"
        exit 602
    }

    // If replace is specified, erase existing outfile
    if "`replace'" != "" {
        capture erase `"`outfile'"'
    }


    local repl = ("`replace'" != "")
    mata: rewrite_md(`"`infile'"', `"`outfile'"', `repl', `"`rpath'"', `"`llp'"')

    di as text "% cleaned markdown written to" "`outfile'"

    // Optional: regenerate HTML from cleaned markdown
    if "`html'" != "" {
        markdown `outfile', saving(`"`html'"') replace
        if "`css'" == "githubstyle" {
            mata: st_local("html_dir", path_dir(`"`html'"'))
            if "`html_dir'" == "" local html_dir "."
            cap mkdir "`html_dir'/css"
            local css_dest "`html_dir'/css/github.css"
            mata: write_github_css(`"`css_dest'"')
            mata: inject_css(`"`html'"', "./css/github.css")
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
            }
            mata: inject_css(`"`html'"', "./css/`css_base'")
        }
        di as text "% html regenerated to `html'"
    }
    else if "`css'" != "" {
        di as error "css() requires html()"
        exit 198
    }
end


program define cleancode
    syntax anything , CLEANCODE(string) [SAVing(string) REPlace HTML(string) CSS(string) RPath(string) WPath(string)]


    // Use the do-file provided in cleancode() as the code source
    local cmdlog `"`cleancode'"'
    if `"`cmdlog'"' == "" {
        di as error "cleancode() requires a do-file with cmdcell markers"
        exit 198
    }
    capture confirm file `"`cmdlog'"'
    if _rc != 0 {
        di as error "do file `cmdlog' does not exist"
        exit 601
    }

    removequotes , t(`anything')
    local anything  `r(s)'

    if `"`saving'"' == "" {
        local saving = usubstr(`"`anything'"', 1, ustrpos(`"`anything'"', ".")-1) + "_code.md"

    }

    local using `anything'
    local llp ./
    if "`wpath'" != "" {
        mata: st_numscalar("wflag",isurl("`wpath'"))
        if wflag==0 {
            di as error "`wpath' is not a valid url"
            exit 601
        }
        local llp `wpath'
    }

    if "`rpath'"!=""{
        mata: st_numscalar("rflag",direxists("`rpath'")) 
        if rflag==0 {
            di as error "directory `rpath' does not exist"
            exit 601
        }
        local rpath = usubinstr(`"`rpath'"', "\\", "/", .)
        if ustrpos(`"`rpath'"', "/") != ustrlen(`"`rpath'"') {
            local rpath = `"`rpath'/"' 
        }
    }

    local infile `using'
    local outfile `saving'

    capture confirm file `"`outfile'"'
    if _rc == 0 & "`replace'" == "" {
        di as error "output file exists; use replace"
        exit 602
    }


    local replout = ("`replace'" != "")
    mata: merge_cmdlog_blocks(`"`infile'"', `"`cmdlog'"', `"`outfile'"', `replout', `"`rpath'"', `"`llp'"')

    di as text `"% cleancode markdown written to `outfile'"'

    // Optional: regenerate HTML from code markdown
    if "`html'" != "" {
        markdown `outfile', saving(`"`html'"') replace
        if "`css'" == "githubstyle" {
            mata: st_local("html_dir", path_dir(`"`html'"'))
            if "`html_dir'" == "" local html_dir "."
            cap mkdir "`html_dir'/css"
            local css_dest "`html_dir'/css/github.css"
            mata: write_github_css(`"`css_dest'"')
            mata: inject_css(`"`html'"', "./css/github.css")
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
            }
            mata: inject_css(`"`html'"', "./css/`css_base'")
        }
        di as text "% html regenerated to `html'"
    }
    else if "`css'" != "" {
        di as error "css() requires html()"
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
    syntax anything , [SAVing(string)  REPlace HTML(string) CSS(string) RPath(string) WPath(string) CLEAN cleancode(string)]
    // only keep lines that start with #, <iframe, <img

    removequotes , t(`anything')
    local anything  `r(s)'

    if `"`saving'"' == "" {
        //在anything扩展名之前加clean，思路找到最后一个.的位置，然后把扩展名之前的部分替换成clean.md
        local saving = usubstr("`anything'", 1, ustrpos("`anything'", ".")-1) + ".clean.md"
    }
    local using `anything'
    local llp ./
    if "`wpath'" != "" {
        // check if wpath is a url
        mata: st_numscalar("wflag",isurl("`wpath'"))
        if wflag==0 {
            di as error "`wpath' is not a valid url"
            exit 601
        }
        local llp `wpath'
    }

    if "`rpath'"!=""{
        // check if the directory path exist
        mata: st_numscalar("rflag",direxists("`rpath'")) 
        if rflag==0 {
            di as error "directory `rpath' does not exist"
            exit 601
        }
        // convert \ in rpath to /
        local rpath = usubinstr(`"`rpath'"', "\", "/", .)
        // if the last character is not /, add it
        if ustrpos(`"`rpath'"', "/") != ustrlen(`"`rpath'"') {
            local rpath = `"`rpath'/"' 
        }
    }

    local infile `using'
    local outfile `saving'

    // If outfile exists and no replace, stop
    capture confirm file `"`outfile'"'
    if _rc == 0 & "`replace'" == "" {
        di as error "output file exists; use replace"
        exit 602
    }

    local repl = ("`replace'" != "")
    mata: rewrite_md2(`"`infile'"', `"`outfile'"', `repl', `"`rpath'"', `"`llp'"')
    di as text "% cleaned markdown written to" `"`outfile'"'

        // Optional: regenerate HTML from cleaned markdown
    if "`html'" != "" {
        markdown `outfile', saving(`"`html'"') replace
        if "`css'" == "githubstyle" {
            mata: st_local("html_dir", path_dir(`"`html'"'))
            if "`html_dir'" == "" local html_dir "."
            cap mkdir "`html_dir'/css"
            local css_dest "`html_dir'/css/github.css"
            mata: write_github_css(`"`css_dest'"')
            mata: inject_css(`"`html'"', "./css/github.css")
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
            }
            mata: inject_css(`"`html'"', "./css/`css_base'")
        }
        di as text "% html regenerated to `html'"
    }
    else if "`css'" != "" {
        di as error "css() requires html()"
        exit 198
    }
end


mata:

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

string scalar ensure_trailing_slash(string scalar p)
{
    if (strlen(p) == 0) return(p)
    if (substr(p, strlen(p), 1) != "/") return(p + "/")
    return(p)
}

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

void function ensure_dir(string scalar dir)
{
    dir = normalize_path(dir)
    if (strlen(dir) == 0) return
    // build path iteratively
    parts = tokens(dir, "/")
    if (rows(parts) == 0) return
    start = 1
    if (ustrpos(parts[1], ":") == strlen(parts[1])) {
        cur = parts[1]
        start = 2
    }
    else {
        cur = parts[1]
        if (substr(dir, 1, 1) == "/") cur = "/" + cur
        start = 2
    }
    for (i = start; i <= rows(parts); i++) {
        cur = cur + "/" + parts[i]
        stata("cap mkdir " + cur + "")
    }
}

string scalar extract_src(string scalar line)
{
    p = ustrpos(line, "src=")
    if (p == 0) return("")
    q = substr(line, p + 4, 1)
    if (q != "'" & q != `"""') return("")
    rest = substr(line, p + 5, .)
    e = ustrpos(rest, q)
    if (e == 0) return("")
    return(substr(rest, 1, e - 1))
}

void function copy_embed_assets(string colvector lines, string scalar rpath, string scalar llp, string scalar assets_dir)
{
    rpath = ensure_trailing_slash(normalize_path(rpath))
    llp = ensure_trailing_slash(normalize_path(llp))
    assets_dir = normalize_path(assets_dir)
    ensure_dir(assets_dir)

    n = rows(lines)
    if (n == 0) return

    for (i = 1; i <= n; i++) {
        line = lines[i]
        line_trim = ustrltrim(line)
        if (!(substr(line_trim, 1, strlen("<iframe")) == "<iframe" | substr(line_trim, 1, strlen("<img")) == "<img")) {
            continue
        }
        src = extract_src(line)
        if (strlen(src) == 0) continue
        srcn = normalize_path(src)
        if (substr(srcn, 1, strlen(rpath)) == rpath) {
            rel = substr(srcn, strlen(rpath) + 1, .)
        }
        else if (substr(srcn, 1, strlen(llp)) == llp) {
            rel = substr(srcn, strlen(llp) + 1, .)
        }
        else {
            continue
        }
        dest = assets_dir + "/" + rel
        ensure_dir(path_dir(dest))
        if (substr(srcn, 1, strlen(llp)) == llp) {
            srcfile = rpath + rel
        }
        else {
            srcfile = srcn
        }
        stata("cap copy " + srcfile + " " + dest + ", replace")
    }
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

void function rewrite_md(string scalar ofi, string scalar tfi, real scalar replace, string scalar rpath, string scalar llp)
{
    // 1. 读取文件
    fcon = cat(ofi)
    
    // 2. 合并 HTML 行
    fcon = merge_html_vectorized(fcon)
    
    // 3. 移除前缀
    prefixes = (">", "{com}", "{res}", "{txt}")
    fcon = remove_prefix_and_trim(fcon, prefixes)
    
    // 4. 过滤掉包含 "cmdcell" 的行
    fcon = select(fcon, ustrpos(fcon, ". cmdcell") :!= 1)
    
    // 5. 去除空行
    fcon = select(fcon, strtrim(fcon) :!= ".")

    // 5b. 删除特定行
    bad1 = strtrim(fcon) :== ". capture log close"
    bad2 = strtrim(fcon) :== "{smcl}"
    bad3 = strtrim(fcon) :== "{sf}{ul off}"
    fcon = select(fcon, !(bad1 :| bad2 :| bad3))
    
    // 5c. 路径替换（仅对 <iframe / <img 行）
    if (strlen(rpath) > 0) {
        fcon_trim = ustrltrim(fcon)
        is_embed = (substr(fcon_trim, 1, strlen("<iframe")) :== "<iframe") :| ///
                   (substr(fcon_trim, 1, strlen("<img")) :== "<img")
        if (sum(is_embed) > 0) {
            fcon[selectindex(is_embed)] = subinstr(fcon[selectindex(is_embed)], "\\", "/", .)
            fcon[selectindex(is_embed)] = subinstr(fcon[selectindex(is_embed)], rpath, llp, .)
        }
    }

    // 6. 【核心】动态修复：直到所有 # 行都在代码块外
    fcon = insert_backtick_before_hash(fcon)
    
    // 7. （可选）过滤短代码块
    fconlen = char_lengths_including_backticks(fcon)
    fcon = select(fcon, !(fconlen :< 2))
    
    // 8. 输出
    //printf(strofreal(replace))
    if (replace == 0) {
        mm_outsheet(tfi, fcon)
    } else {
        mm_outsheet(tfi, fcon, "replace")
    }
}




void function rewrite_md2(string scalar ofi, string scalar tfi, real scalar replace, string scalar rpath, string scalar llp)
{
    // 1. 读取文件
    fcon = cat(ofi)
    
    // 2. 合并 HTML 行
    fcon = merge_html_vectorized(fcon)
    
    // 3. 移除前缀
    prefixes = (">", "{com}", "{res}", "{txt}")
    fcon = remove_prefix_and_trim(fcon, prefixes)
    
    // 4. 
    fcon_trim = ustrltrim(fcon)
    flag = (ustrpos(fcon_trim, "#") :== 1)
    flag = flag :| (ustrpos(fcon_trim, "<img") :== 1)
    flag = flag :| (ustrpos(fcon_trim, "<iframe") :== 1)
    fcon = select(fcon, flag)

    // 4b. 路径替换（仅对 <iframe / <img 行）
    if (strlen(rpath) > 0) {
        fcon_trim = ustrltrim(fcon)
        is_embed = (substr(fcon_trim, 1, strlen("<iframe")) :== "<iframe") :| ///
                   (substr(fcon_trim, 1, strlen("<img")) :== "<img")
        if (sum(is_embed) > 0) {
            fcon[selectindex(is_embed)] = subinstr(fcon[selectindex(is_embed)], "\\", "/", .)
            fcon[selectindex(is_embed)] = subinstr(fcon[selectindex(is_embed)], rpath, llp, .)
        }
    }
    
    // 8. 输出
    if (replace == 0) {
        mm_outsheet(tfi, fcon)
    } else {
        mm_outsheet(tfi, fcon, "replace")
    }
}

real colvector char_lengths_including_backticks(string colvector lines)
{
    n = rows(lines)
    if (n == 0) return(J(0, 1, .))
    
    // 1. 找出所有以 "```" 开头的行索引
    is_bt_start = (substr(lines, 1, 3) :== "```")
    idx_bt = selectindex(is_bt_start)
    n_bt = rows(idx_bt)
    
    // 2. 初始化结果向量（全为缺失值）
    result = J(n, 1, .)
    
    // 3. 处理完整配对
    n_pairs = floor(n_bt / 2)
    if (n_pairs == 0) return(result)
    
    for (p = 1; p <= n_pairs; p++) {
        i1 = idx_bt[2*p - 1]   // 第一个 ```
        i2 = idx_bt[2*p]       // 第二个 ```
        
        // 计算中间内容总长度（i1+1 到 i2-1）
        total_len = 0
        if (i2 > i1 + 1) {
            mid_lines = lines[| (i1+1) \ (i2-1) |]
            total_len = sum(strlen(mid_lines))
        }
        // 如果 i2 == i1+1（空代码块），total_len = 0
        
        // 填充：从 i1 到 i2（包含两个 ``` 行）
        block_len = i2 - i1 + 1
        result[| i1 \ i2 |] = J(block_len, 1, total_len)
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
    
    // 5. 标记哪些行应保留：所有行都保留，除了那些是“被合并的下一行”
    is_next_of_merge = J(n, 1, 0)
    if (rows(to_merge_idx) > 0) {
        is_next_of_merge[to_merge_idx :+ 1] = 1
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
    
    is_bt = (substr(lines, 1, 3) :== "```")
    
    // 累积和：到当前行为止（含）的 ``` 行数
    cumsum = runningsum(is_bt)
    
    // 当前行“之前”的数量 = 上一行的 cumsum
    count_before = J(n, 1, 0)
    if (n > 1) count_before[|2 \ n|] = cumsum[|1 \ n-1|]
    
    return(count_before)
}

string colvector insert_backtick_before_hash(string colvector fcon)
{
    n = rows(fcon)
    if (n == 0) return(J(0, 1, ""))

    fcon_trim = ustrltrim(fcon)
    is_hash = (substr(fcon_trim, 1, 1) :== "#")
    is_hash = is_hash :+ (substr(fcon_trim, 1, strlen("<iframe")) :== "<iframe") 
    is_hash = is_hash :+ (substr(fcon_trim, 1, strlen("<img")) :== "<img")

    // 动态修复：每次插入后重新计算 count_before
    max_iter = 500*(500>sum(is_hash)) + sum(is_hash)*(500<=sum(is_hash))
    iter = 0
    changed = 1

    while (changed & iter < max_iter) {
        iter = iter + 1

        count_before = cumcount_backtick3(fcon)

        // 判断每行是否以 "#" / <iframe / <img 开头（忽略前导空格）
        fcon_trim = ustrltrim(fcon)
        is_hash = (substr(fcon_trim, 1, 1) :== "#")
        is_hash = is_hash :+ (substr(fcon_trim, 1, strlen("<iframe")) :== "<iframe") 
        is_hash = is_hash :+ (substr(fcon_trim, 1, strlen("<img")) :== "<img")

        // 条件：是 # 行 且 count_before 为奇数
        need_insert = is_hash :& (mod(count_before, 2) :== 1)
        changed = (sum(need_insert) > 0)

        if (!changed) break

        // 预分配足够空间（最坏情况：每行都插入，总长 ≤ 2*n）
        result = J(0, 1, "")

        for (i = 1; i <= n; i++) {
            if (need_insert[i]) {
                result = result \ "```"   // 插入关闭代码块
            }
            result = result \ fcon[i]
        }

        fcon = result
        n = rows(fcon)
    }

    if (iter >= max_iter) {
        printf("{err}Warning: reached max iterations (%g) in insert_backtick_before_hash\n", max_iter)
    }

    return(fcon)
}


string colvector add_two_blank_lines(string colvector lines)
{
    n = rows(lines)
    if (n == 0) return(lines)

    out = J(0, 1, "")
    for (i = 1; i <= n; i++) {
        out = out \ lines[i]

        if (ustrpos(lines[i], "```") == 1) {
            // count existing blank lines after this line
            blanks = 0
            j = i + 1
            while (j <= n) {
                if (ustrtrim(lines[j]) != "") break
                blanks = blanks + 1
                j = j + 1
            }
            if (j <= n) {
                if (ustrpos(lines[j], "```") == 1) {
                    need = 4 - blanks
                    if (need > 0) {
                        out = out \ J(need, 1, "")
                    }
                }
            }
        }
    }
    return(out)
}

void function merge_cmdlog_blocks(string scalar clean_md, string scalar cmdlog_md, string scalar out_md, real scalar replace, string scalar rpath, string scalar llp)
{
    // 1. 读取 clean md（用于获取表/图）
    // printf(clean_md)
    // printf(cmdlog_md)
    // printf(clean_md)
    clean = cat(clean_md)
    clean = merge_html_vectorized(clean)
    clean_trim = ustrltrim(clean)
    is_embed = (substr(clean_trim, 1, strlen("<iframe")) :== "<iframe") :| ///
        (substr(clean_trim, 1, strlen("<img")) :== "<img")
    embeds = select(clean, is_embed)
    n_embed = rows(embeds)
    embed_i = 1

    // 2. 读取 cmdlog
     
    cmd = cat(cmdlog_md)
   
    n_cmd = rows(cmd)

    // 2b. 统计 cmdcell out 数量
    cmd_trim = ustrtrim(cmd)
    is_cmdcell = (substr(cmd_trim, 1, strlen("cmdcell")) :== "cmdcell")
    is_out = is_cmdcell :& (ustrpos(cmd_trim, "cmdcell out") :== 1)
    n_cmdcell = sum(is_cmdcell)
    n_out = sum(is_out)
    if (n_cmdcell == 0) {
        errprintf("cmdlog must contain cmdcell markers\n")
        _error(498)
    }
    if (n_out == 0 & n_embed > 0) {
        errprintf("cmdcell out missing but embeds exist (%g)\n", n_embed)
        _error(498)
    }
    if (n_out > 0 & n_out != n_embed) {
        errprintf("cmdcell out count (%g) does not match embed count (%g)\n", n_out, n_embed)
        _error(498)
    }

    // 3. 合并输出
    result = J(0, 1, "")
    in_block = 0

    for (i = 1; i <= n_cmd; i++) {
        line = cmd[i]
        line_trim = ustrtrim(line)

        // // 去掉可能的 Stata 提示符 "."
        // if (substr(line_trim, 1, 1) :== ".") {
        //     line_trim = ustrtrim(substr(line_trim, 2, .))
        // }

        // 处理 cmdcell 标题（cmdcell + # 标题）
        if (substr(line_trim, 1, 7) == "cmdcell") {
            title = ustrtrim(substr(line_trim, 8, .))
            if (substr(title, 1, 1) == "#") {
                result = result \ title
                continue
            }
        }

        // 处理 cmdcell 分块（仅 0/1/空/out 有效）
        if (substr(line_trim, 1, strlen("cmdcell")) :== "cmdcell") {
            if (ustrpos(line_trim, "cmdcell out") :== 1) {
                if (in_block) {
                    result = result \ "```"
                    in_block = 0
                }
                if (embed_i <= n_embed) {
                    result = result \ embeds[embed_i]
                    embed_i = embed_i + 1
                }
            }
            else if (line_trim == "cmdcell" | line_trim == "cmdcell 0" | line_trim == "cmdcell 1") {
                if (in_block == 0) {
                    result = result \ "```"
                    in_block = 1
                }
                else {
                    result = result \ "```"
                    in_block = 0
                }
            }
            continue
        }

        // 块内保留命令
        if (in_block) {
            result = result \ line
        }
    }

    // 若末尾未闭合，补上 ```
    if (in_block) {
        result = result \ "```"
    }

    // 6. 【核心】动态修复：直到所有 # 行都在代码块外
    result = insert_backtick_before_hash(result)
    
    // 7. （可选）过滤短代码块
    fconlen = char_lengths_including_backticks(result)
    result = select(result, !(fconlen :< 3))    

    // 8. 路径替换（仅对 <iframe / <img 行）
    if (strlen(rpath) > 0) {
        rtrim = ustrltrim(result)
        is_embed2 = (substr(rtrim, 1, strlen("<iframe")) :== "<iframe") :| ///
                    (substr(rtrim, 1, strlen("<img")) :== "<img")
        if (sum(is_embed2) > 0) {
            result[selectindex(is_embed2)] = subinstr(result[selectindex(is_embed2)], "\\", "/", .)
            result[selectindex(is_embed2)] = subinstr(result[selectindex(is_embed2)], rpath, llp, .)
        }
    }

    // 8b. 在代码块之间插入两个空行
    result = add_two_blank_lines(result)

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

    mm_outsheet(filepath, css, "replace")
}

end

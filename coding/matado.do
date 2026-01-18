mata mata clear

mata:

void function rewrite_md(string scalar ofi, string scalar tfi, real scalar replace)
{
    // 1. 读取文件
    fcon = cat(ofi)
    
    // 2. 合并 HTML 行
    fcon = merge_html_vectorized(fcon)
    
    // 3. 移除前缀
    prefixes = (">", "{com}", "{res}", "{txt}")
    fcon = remove_prefix_and_trim(fcon, prefixes)
    
    // 4. 过滤掉包含 "statacell" 的行
    fcon = select(fcon, ustrpos(fcon, ". statacell") :!= 1)
    
    // 5. 去除空行
    fcon = select(fcon, strtrim(fcon) :!= ".")

    // 5b. 删除特定行
    bad1 = strtrim(fcon) :== ". capture log close"
    bad2 = strtrim(fcon) :== "{smcl}"
    bad3 = strtrim(fcon) :== "{sf}{ul off}"
    fcon = select(fcon, !(bad1 :| bad2 :| bad3))
    
    // 6. 【核心】动态修复：直到所有 # 行都在代码块外
    fcon = insert_backtick_before_hash(fcon)
    
    // 7. （可选）过滤短代码块
    fconlen = char_lengths_including_backticks(fcon)
    fcon = select(fcon, !(fconlen :< 5))
    
    // 8. 输出
    if (replace == 0) {
        mm_outsheet(tfi, fcon)
    } else {
        mm_outsheet(tfi, fcon, "replace")
    }
}




void function rewrite_md2(string scalar ofi, string scalar tfi, real scalar replace)
{
    // 1. 读取文件
    fcon = cat(ofi)
    
    // 2. 合并 HTML 行
    fcon = merge_html_vectorized(fcon)
    
    // 3. 移除前缀
    prefixes = (">", "{com}", "{res}", "{txt}")
    fcon = remove_prefix_and_trim(fcon, prefixes)
    
    // 4. 
    flag = (ustrpos(fcon, "#"):==1)
    flag = flag :| (ustrpos(fcon, "<img") :== 1)
    flag = flag :| (ustrpos(fcon, "<iframe") :== 1)
    fcon = select(fcon, flag)
    
    // 8. 输出
    if (replace == 0) {
        mm_outsheet(tfi, fcon)
    } else {
        mm_outsheet(tfi, fcon, "replace")
    }
}

void function merge_cmdlog_blocks(string scalar clean_md, string scalar cmdlog_md, string scalar out_md, real scalar replace)
{
    // 1. 读取 clean md（用于获取表/图）
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

    // 3. 合并输出
    result = J(0, 1, "")
    in_block = 0

    for (i = 1; i <= n_cmd; i++) {
        line = cmd[i]
        line_trim = ustrltrim(line)

        // 去掉可能的 Stata 提示符 "."
        if (substr(line_trim, 1, 1) :== ".") {
            line_trim = ustrltrim(substr(line_trim, 2, .))
        }

        // 处理 statacell 标题
        if (substr(line_trim, 1, strlen("statacell")) :== "statacell") {
            title = ustrtrim(substr(line_trim, strlen("statacell") + 1, .))
            if (strlen(title) > 0) {
                result = result \ title
            }
            continue
        }

        // 处理 cmdcell 分块
        if (substr(line_trim, 1, strlen("cmdcell")) :== "cmdcell") {
            if (in_block == 0) {
                result = result \ "```"
                in_block = 1
            }
            else {
                result = result \ "```"
                in_block = 0
                if (embed_i <= n_embed) {
                    result = result \ embeds[embed_i]
                    embed_i = embed_i + 1
                }
            }
            continue
        }

        // 块内保留命令
        if (in_block) {
            result = result \ line
        }
    }

    // 若末尾未闭合，补上 ``` 并插入下一张表/图
    if (in_block) {
        result = result \ "```"
        if (embed_i <= n_embed) {
            result = result \ embeds[embed_i]
            embed_i = embed_i + 1
        }
    }

    // 6. 【核心】动态修复：直到所有 # 行都在代码块外
    result = insert_backtick_before_hash(result)
    
    // 7. （可选）过滤短代码块
    fconlen = char_lengths_including_backticks(result)
    result = select(result, !(fconlen :< 3))    
    // 4. 输出
    if (replace == 0) {
        mm_outsheet(out_md, result)
    } else {
        mm_outsheet(out_md, result, "replace")
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
    idx_gt = selectindex(substr(result, 1, 1) :== ">")
    if (rows(idx_gt) > 0) {
        result[idx_gt] = ustrtrim(substr(result[idx_gt], 2, .))
    }

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

    // 动态修复：每次插入后重新计算 count_before
    max_iter = 100
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



end


mata: rewrite_md("C:/Users/kerry/Desktop/auto-mini/results/logs/auto-mini.md", "C:/Users/kerry/Desktop/auto-mini/results/logs/auto-mini2.md", 1)

mata: rewrite_md2("C:/Users/kerry/Desktop/auto-mini/results/logs/auto-mini.md", "C:/Users/kerry/Desktop/auto-mini/results/logs/auto-mini3.md", 1)

// 合并 cmdlog 与 clean md：每个 cmdcell 块后插入一张表/图
mata: merge_cmdlog_blocks("C:/Users/kerry/Desktop/auto-mini/results/logs/auto-mini3.md", "C:/Users/kerry/Desktop/auto-mini/results/logs/auto-mini.md", "C:/Users/kerry/Desktop/auto-mini/results/logs/auto-mini4.md", 1)


cmdlog using "C:/Users/kerry/Desktop/auto-mini/results/logs/auto-mini.md", replace text

statacell # Demo
statacell ## begin


cmdcell
clear
cmdcell

cmdcell 
sysuse auto, clear
summarize
outreg3 using "C:/Users/kerry/Desktop/auto-mini/results/tables/regression_results.doc", replace ctitle("Regression Results") html
cmdcell out

cmdcell
* figure 
scatter price mpg, title("Price vs. MPG")
graph2md, save("C:/Users/kerry/Desktop/auto-mini/results/figures/figure1.png")
cmdcell out



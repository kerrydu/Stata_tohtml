// 测试 get_textcell_index 函数
mata mata clear
mata:
real colvector get_textcell_index(string colvector lines)
{
   text_start = selectindex(lines:=="_ishere_/*")
   text_end = selectindex(lines:=="_ishere_*/")
   text_idx = J(rows(lines),1,0)
   for (i=1;i<=length(text_start);i++){ 
       text_idx[text_start[i]::text_end[i]] = J(length(text_start[i]::text_end[i]),1,1)
   }
    return(text_idx)
}

void test_get_textcell_index()
{
    // 创建测试数据：包含 textcell 块的行
    string colvector lines
    lines = ("line1", ///
             "_ishere_/*", ///
             "content1", ///
             "content2", ///
             "_ishere_*/", ///
             "line2", ///
             "_ishere_/*", ///
             "content3", ///
             "_ishere_*/")
    
    // 调用函数
    real colvector result
    result = get_textcell_index(lines')
    
    // 显示输入和结果
    printf("输入行:\n")
    for (i=1; i<=rows(lines); i++) {
        printf("%2.0f: %s\n", i, lines[i])
    }
    printf("\n结果 (textcell 索引):\n")
    for (i=1; i<=rows(result); i++) {
        printf("%2.0f: %g\n", i, result[i])
    }
    
    // 预期结果：第2-5行和第7-9行应为1
    printf("\n预期结果: 第2-5行和第7-9行应为1，其他为0\n")
}

// 运行测试
test_get_textcell_index()
end


mata mata clear 
// ...existing code...

// Add this test code at the end of the file, before "end"
mata:

string colvector function get_dot_header(string colvector lines)
{
    lines2 = strltrim(lines)
    flag = (ustrpos(lines2, ".") :== 1)
    lines3 = strltrim(substr(lines2, 2, .))
    flag2 = (ustrpos(lines3, "ishere") :== 1)
    lines3 = strltrim(substr(lines3,strlen("ishere")+1,.))
    flag3 = (ustrpos(lines3, "#") :== 1)
    flag = flag :& flag2 :& flag3
    if (sum(flag) > 0) {
        idx = selectindex(flag)
        lines[idx] = lines3[idx]
    }
    return(lines)
}
void test_get_dot_header()
{
    // Create test data: a string column vector with some lines including dot ishere # patterns
    string colvector lines
    lines = ("# Normal Header", ///
             ". ishere # Converted Header", ///
             "Some text", ///
             ". ishere # Another Header", ///
             ". ishere something else", ///
             "# Another Normal", ///
             "")
    
    // Display input
    printf("Input lines:\n")
    for (i=1; i<=rows(lines); i++) {
        printf("%2.0f: %s\n", i, lines[i])
    }
    
    // Call the function
    string colvector result
    result = get_dot_header(lines')
    
    // Display output
    printf("\nOutput lines after get_dot_header:\n")
    for (i=1; i<=rows(result); i++) {
        printf("%2.0f: %s\n", i, result[i])
    }
}

// Run the test
test_get_dot_header()
end



mata mata clear

// ...existing code...

// Add this test code at the end of the file, before "end"
mata:

string colvector function get_header(string colvector lines)
{
    lines2 = strltrim(lines)
    flag = (ustrpos(lines2, "ishere") :== 1)
    lines2 = strltrim(substr(lines2,strlen("ishere")+1,.))
    flag2 = (ustrpos(lines2, "#") :== 1)
    flag = flag :& flag2 
    if (sum(flag) > 0) {
        idx = selectindex(flag)
        lines[idx] = lines2[idx]
    }
    return(lines)
}
void test_get_header()
{
    // Create test data: a string column vector with some lines including ishere # patterns
    string colvector lines
    lines = ("# Normal Header", ///
             "ishere # Converted Header", ///
             "Some text", ///
             "ishere # Another Header", ///
             "ishere something else", ///
             "# Another Normal", ///
             "")
    
    // Display input
    printf("Input lines:\n")
    for (i=1; i<=rows(lines); i++) {
        printf("%2.0f: %s\n", i, lines[i])
    }
    
    // Call the function
    string colvector result
    result = get_header(lines')
    
    // Display output
    printf("\nOutput lines after get_header:\n")
    for (i=1; i<=rows(result); i++) {
        printf("%2.0f: %s\n", i, result[i])
    }
}

// Run the test
test_get_header()
end
/////////////////////////////
mata mata clear

mata :


string colvector function check_isheretxt_closed(string colvector lines)
{ 
  lines2 = usubinstr(lines, " ", "", .)
  flag1 = (ustrpos(lines2, "ishere/*") :== 1)
  flag2 = (ustrpos(lines2, "ishere*/") :== 1)
  if (sum(flag1)!=sum(flag2)){
       errprintf("Error: unmatched ishere /* and */\n")
       _error(199)
   }
   if (sum(flag1)==0){ 
        return(lines)
   }
   idx1 = selectindex(flag1)
   idx2 = selectindex(flag2)

   for (i=1;i<=length(idx1);i++){
      if (idx2[i]<=idx1[i]) {
        errprintf("Error: unmatched ishere /* and */\n")
        _error(199)
       }
       if ((i+1) < length(idx1)) {
         if (idx1[i]<length(lines) & idx1[i+1] < idx2[i]) {
            errprintf("Error: overlapping ishere /* and */\n")
            _error(199)    
          }
        }
        lines[idx1[i]] = "_ishere_/*"
        lines[idx2[i]] = "_ishere_*/"

   }

   return(lines)


}

end 

mata mata clear 

mata:


string colvector clean_textcell_content(string colvector lines)
{
  // 必须放在开始处理
  lines = strltrim(lines)
  lines2 = strltrim(substr(lines,2,.))
  r1 = ustrpos(lines2, "ishere") :== 1
  
  lines2 = strltrim(substr(lines2, ustrlen("ishere")+1, .))
  r12 = ustrpos(lines2,"/*") :== 1
  r22 = ustrpos(lines2,"*/") :== 1
  r12 = r1 :& r12
  
  r22 = r1 :& r22
  
  if (sum(r12)!=sum(r22)){
       errprintf("Error: unmatched ishere /* and */\n")
       _error(199)
   }
  if (sum(r12)==0){ 
    return(lines)
  }
  idx12 = select(1::rows(lines), r12)
  idx22 = select(1::rows(lines), r22)

   if (length(idx12)!=length(idx22)){
       errprintf("Error: unmatched ishere /* and */\n")
       _error(199)
   }
   if (length(idx12)>0){
       for (i=1;i<=length(idx12);i++){
           if (idx12[i]>=idx22[i]) {
                errprintf("Error: unmatched ishere /* and */\n")
               _error(199)
           }
           if ((i+1) < length(idx12)) {
		   	 if (idx12[i]<length(lines) & idx12[i+1] < idx22[i]) {
                errprintf("Error: overlapping ishere /* and */\n")
                _error(199)    
               }
		   	
		   }
           
      lines[idx12[i]..idx22[i]] = substr(lines[idx12[i]..idx22[i]],2,.)
      lines[idx12[i]] = "_ishere_/*"
      lines[idx22[i]] = "_ishere_*/"
      }
   }
   return(lines)

}
end 



/////////////

mata mata clear 

mata:
string colvector add_two_blank_lines(string colvector lines)
{
    n = rows(lines)
    if (n == 0) return(lines)

    out = J(0, 1, "")
    code_block_count = 0
    
    for (i = 1; i <= n; i++) {
        line = lines[i]
        
        // 检查当前行是否是代码块标记
        if (ustrpos(ustrtrim(line), "```") == 1) {
            code_block_count = code_block_count + 1
            
            // 如果是奇数个代码块，在它前面加两个空行
            if (mod(code_block_count, 2) == 1) {
                out = out \ "" \ ""
                // 添加当前代码块标记行
                out = out \ line
            }
    
            // 如果是偶数个代码块，在它后面加两个空行
            if (mod(code_block_count, 2) == 0) {
                out = out \ line \ "" \ ""
            }
        }
        else {
            // 非代码块标记行直接添加
            out = out \ line
        }
    }
    
    return(out)
}

end 


mata:
void test_add_two_blank_lines()
{
    string colvector lines
    lines = ("Start", ///
             "```", ///
             "code line1", ///
             "code line2", ///
             "```", ///
             "Between", ///
             "```", ///
             "more code", ///
             "```", ///
             "End")
    
    printf("Input:\n")
    for (i = 1; i <= rows(lines); i++) printf("%2.0f: %s\n", i, lines[i])
    
    string colvector out
    out = add_two_blank_lines(lines')
    
    printf("\nOutput:\n")
    for (i = 1; i <= rows(out); i++) printf("%2.0f: %s\n", i, out[i])
    printf("\n")
}

test_add_two_blank_lines()
end

//////////////


mata mata clear

mata:
real colvector cumcount_backtick3(string colvector lines)
{
    n = rows(lines)
    if (n == 0) return(J(0, 1, .))
    
    is_bt = (strtrim(lines) :== "```") 
    
    // 累积和：到当前行为止（含）的 ``` 行数
    cumsum = runningsum(is_bt)
    
    // 当前行"之前"的数量 = 上一行的 cumsum
    count_before = J(n, 1, 0)
    if (n > 1) count_before[|2 \ n|] = cumsum[|1 \ n-1|]
    
    return(count_before)
}

string colvector insert_backtick_before_hash(string colvector fcon)
{
    n = rows(fcon)
    if (n == 0) return(J(0, 1, ""))
    
    // Estimate max iterations based on potential markers
    fcon_trim_init = ustrltrim(fcon)
    is_hash_init = (substr(fcon_trim_init, 1, 1) :== "#")
    is_hash_init = is_hash_init :| (substr(fcon_trim_init, 1, strlen("<iframe")) :== "<iframe") 
    is_hash_init = is_hash_init :| (substr(fcon_trim_init, 1, strlen("<img")) :== "<img")
    lens = strlen("_ishere_")
    is_hash_init = is_hash_init :| (usubstr(fcon_trim_init, 1, lens) :== "_ishere_")
    //is_hash_init = is_hash_init :| (usubstr(fcon_trim_init, 1, lens) :== "ishere/*")

    // 动态修复：每次插入后重新计算 count_before
    max_iter = sum(is_hash_init) + 50
    if (max_iter < 100) max_iter = 100
    
    iter = 0
    changed = 1

    while (changed & iter < max_iter) {
        iter = iter + 1

        count_before = cumcount_backtick3(fcon)

        fcon_trim = ustrltrim(fcon)
        
        // Base checks
        is_hash = (substr(fcon_trim, 1, 1) :== "#")
        is_hash = is_hash :| (substr(fcon_trim, 1, strlen("<iframe")) :== "<iframe") 
        is_hash = is_hash :| (substr(fcon_trim, 1, strlen("<img")) :== "<img")
        is_hash = is_hash :| (usubstr(fcon_trim, 1, lens) :== "_ishere_")
        // Robust textcell checks
        is_tc_start_vec = J(rows(fcon), 1, 0)
        is_tc_end_vec   = J(rows(fcon), 1, 0)
        
        // Check for lines starting with _ishere_
        cand_idx = selectindex(usubstr(fcon_trim, 1, lens) :== "_ishere_")
        if (rows(cand_idx) > 0) {
            for (k=1; k<=rows(cand_idx); k++) {
                 idx = cand_idx[k]
                 rem = ustrltrim(usubstr(fcon_trim[idx], lens+1, .))
                 if (usubstr(rem, 1, 2) == "/*") {
                     is_tc_start_vec[idx] = 1
                 }
                 if (usubstr(rem, 1, 2) == "*/") {
                     is_tc_end_vec[idx] = 1
                 }
            }
        }
        
        is_hash = is_hash :| is_tc_start_vec
               
        // 条件：是 # 行 且 count_before 为奇数 => 插入 BEFORE (Close code block)
        need_insert_before = is_hash :& (mod(count_before, 2) :== 1)
        
        // 条件：是 _textcell */ 且 count_before 为奇数 => 插入 AFTER (Re-open code block)
        // 注意：只有当 textcell 确实嵌在代码块里时（count=odd）才需要操作。
        // 如果 textcell 本就在外（count=even），则不需要任何操作（User Case）。
        need_insert_after = is_tc_end_vec :& (mod(count_before, 2) :== 1)

        changed = (sum(need_insert_before) + sum(need_insert_after) > 0)

        if (!changed) break

        result = J(0, 1, "")
        n_current = rows(fcon)

        for (i = 1; i <= n_current; i++) {
            if (need_insert_before[i]) {
                result = result \ "```"   // 插入关闭代码块
            }
            result = result \ fcon[i]
            if (need_insert_after[i]) {
                result = result \ "```"   // 插入（重新）打开代码块
            }
        }

        fcon = result
    }

    if (iter >= max_iter) {
        printf("{err}Warning: reached max iterations (%g) in insert_backtick_before_hash\n", max_iter)
    }

    // 清理 textcell 标记 (Robust removal)
    // We already know how to identify them, let's just strip them
    r1 = selectindex(is_tc_start_vec:| is_tc_end_vec )
    if (sum(r1) > 0) {
        fcon[r1] = J(rows(r1), 1, "")
    }
    
    return(fcon)
}
end



mata:

void print_vec(string colvector v, string title)
{
    printf("%s\n", title)
    for (i=1; i<=rows(v); i++) printf("%2.0f: %s\n", i, v[i])
    printf("\n")
}

void test_insert_before_hash_simple()
{
    string colvector lines
    lines = ("Start" \
             "```" \
             "code line" \
             "# Heading inside code" \
             "another code" \
             "```" \
             "End")
    print_vec(lines, "Input: simple (hash inside code block)")
    string colvector out
    out = insert_backtick_before_hash(lines)
    print_vec(out, "Output:")
    printf("Expected: a ``` inserted before the '# Heading inside code' line.\n\n")
}

void test_insert_multiple_occurrences()
{
    string colvector lines
    lines = ("Intro" \
             "```" \
             "line1" \
             "# First" \
             "```" \
             "Middle" \
             "```" \
             "# Second" \
             "content" \
             "```" \
             "End")
    print_vec(lines, "Input: multiple occurrences")
    string colvector out
    out = insert_backtick_before_hash(lines)
    print_vec(out, "Output:")
    printf("Expected: ``` inserted before '# First' and before '# Second' as needed.\n\n")
}

void test_insert_iframe_and_img()
{
    string colvector lines
    lines = ("Before" \
             "```" \
             "<iframe src content</iframe>" \
             "<img src=>" \
             "```" \
             "# OutsideHeading" \
             "After")
    print_vec(lines, "Input: iframe/img inside code block")
    string colvector out
    out = insert_backtick_before_hash(lines)
    print_vec(out, "Output:")
    printf("Expected: ``` inserted before iframe/img lines if they are treated as block markers.\n\n")
}

/* run tests */
test_insert_before_hash_simple()
test_insert_multiple_occurrences()
test_insert_iframe_and_img()

end


mata mata clear
mata:


real colvector char_lengths_including_backticks(string colvector lines)
{
    n = rows(lines)
    if (n == 0) return(J(0, 1, .))
    is_bt_start = (strtrim(lines) :== "```") 
    idx_bt = selectindex(is_bt_start)
	if (sum(idx_bt)==0) result = J(n, 1, .)
    n_bt = rows(idx_bt)
    // 2. 初始化结果向量（全为缺失值）
    lens = strlen(lines)
    result = J(n, 1, .)
    if (n_bt <= 1) return(J(n, 1, .))
    npair = floor(n_bt / 2)
    i1 = rangen(1, npair*2-1, npair)
    i2 = rangen(2, npair*2, npair)
    // inpair = J(n,1,0)
    for (i = 1; i <= npair; i++) { 
// 		idx_bt[i2[i]],idx_bt[i1[i]]
         flag =selectindex(((1::n):<= idx_bt[i2[i]]) - ((1::n):< idx_bt[i1[i]]))
        //  inpair[flag] = J(length(flag),1,1)
         result[flag] = J(length(flag),1,sum(lens[flag]))
    }

    
    return(result)
}

end
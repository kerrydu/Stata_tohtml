mata:

string colvector function ishererep(string colvector content)
{
    lines =content
    lines2 = usubinstr(lines," ","",.)
    flag = selectindex(ustrpos(lines2, ".**#") :== 1)
    if (length(flag) > 0) {
       lines[flag] = ustrltrim(lines[flag])
       lines[flag] = ustrregexra(lines[flag], "^\.\s*\*\*\s*", "ishere ")
    }
    flag = selectindex(ustrpos(lines2, ".**/*") :== 1)
    if (length(flag) > 0) {
       lines[flag] = ustrltrim(lines[flag])
       lines[flag] = ustrregexra(lines[flag], "^\.\s*\*\*\s*", "ishere ")
    }
    flag = selectindex(ustrpos(lines2, ".***/") :== 1)
    if (length(flag) > 0) {
       lines[flag] = ustrltrim(lines[flag])
       lines[flag] = ustrregexra(lines[flag], "^\.\s*\*\*\s*", "ishere ")
    }

    flag = selectindex(ustrpos(lines2, ".**`") :== 1)
    if (length(flag) > 0) {
       lines[flag] = ustrltrim(lines[flag])
       lines[flag] = ustrregexra(lines[flag], "^\.\s*\*\*\s*", "ishere ")
    }
    return(lines)
}

// ── 测试 ──────────────────────────────────────────────────────────────────
void function test_ishererep()
{
    string colvector input, output, expected
    real scalar i, pass, total

    // 构造测试用例：(输入, 期望输出)
    input = (
        //  标准单空格
        ". **# 一级标题"      \
        //  点与**之间多空格
        ".   **# 标题A"       \
        //  **与#之间多空格
        ". **   # 标题B"      \
        //  两侧都是多空格
        ".  **  # 标题C"      \
        //  零空格（.**#）
        ".**# 标题D"          \
        //  行首有缩进（应先 ltrim）
        "   . **# 缩进标题"   \
        //  /* 注释开
        ". **/* 注释开始"     \
        ".  ** /* 注释开始"   \
        //  */ 注释关
        ". ***/ 注释结束"     \
        ".  **  */ 注释结束"  \
        //  ``` 代码块
        ". **` ` ` 代码块"    \
        //  普通行，不应改动
        "普通内容行"          \
        ". 非目标行"
    )

    expected = (
        "ishere # 一级标题"   \
        "ishere # 标题A"      \
        "ishere # 标题B"      \
        "ishere # 标题C"      \
        "ishere # 标题D"      \
        "ishere # 缩进标题"   \
        "ishere /* 注释开始"  \
        "ishere /* 注释开始"  \
        "ishere */ 注释结束"  \
        "ishere */ 注释结束"  \
        "ishere ` ` ` 代码块" \
        "普通内容行"          \
        ". 非目标行"
    )

    output = ishererep(input)

    pass  = 0
    total = length(input)

    printf("\n")
    for (i = 1; i <= total; i++) {
        string scalar res
        res = (output[i] == expected[i] ? "PASS" : "FAIL")
        if (output[i] == expected[i]) pass++
        printf("[%g] %s\n", i, res)
        printf("    输入: %s\n", input[i])
        printf("    输出: %s\n", output[i])
        if (output[i] != expected[i]) {
            printf("    期望: %s\n", expected[i])
        }
        printf("\n")
    }
    printf("通过 %g / %g\n\n", pass, total)
}

test_ishererep()
end

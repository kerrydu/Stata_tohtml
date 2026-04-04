// 测试 tohtml.ado 679-680 的正则表达式逻辑
// regex = `"(\s*<iframe\s*.*\.md\s*></iframe>\s*)"'
// flag = selectindex(regexm(fcon, regex))

mata:

void test_iframe_regex() {
    string colvector fcon
    string scalar regex
    real colvector flag

    // 构造测试数据
    fcon = (
        "<iframe c:/table1.md ></iframe>",          // 1: 应匹配
        "<iframe c:/table1.md></iframe>",            // 2: 应匹配（无空格）
        "  <iframe c:/path/to/file.md ></iframe>  ", // 3: 应匹配（前后有空格）
        "<iframe c:/sub/dir/report.md></iframe>",    // 4: 应匹配（子目录）
        "<iframe c:/table1.html ></iframe>",         // 5: 不应匹配（.html）
        "<iframe src='test.html'></iframe>",         // 6: 不应匹配（src= 形式）
        "普通文本行",                                 // 7: 不应匹配
        "<img src='figure.png'>",                    // 8: 不应匹配
        "<iframe ></iframe>",                        // 9: 不应匹配（无文件名）
        "  <iframe   c:/a b/t.md  ></iframe>"        // 10: 应匹配（路径含空格）
    )

    regex = `"(\s*<iframe\s*.*\.md\s*></iframe>\s*)"'

    printf("\n%s\n", "=== 测试 iframe .md 正则 ===")
    printf("%-5s  %-45s  %-8s  %-8s\n", "编号", "输入行", "期望", "实际")
    printf("%s\n", "-"*75)

    // 期望结果：1=匹配，0=不匹配
    real rowvector expected
    expected = (1, 1, 1, 1, 0, 0, 0, 0, 0, 1)

    real scalar i, result, pass
    real scalar total_pass
    total_pass = 0

    for (i = 1; i <= rows(fcon); i++) {
        result = regexm(fcon[i], regex)
        pass   = (result == expected[i])
        if (pass) total_pass++
        printf("%-5.0f  %-45s  %-8.0f  %-8.0f  %s\n",
               i, fcon[i], expected[i], result,
               (pass ? "PASS" : "*** FAIL ***"))
    }

    printf("%s\n", "-"*75)
    printf("通过 %g / %g\n\n", total_pass, rows(fcon))

    // 对匹配行打印 selectindex 结果
    flag = selectindex(regexm(fcon, regex))
    printf("selectindex 结果（应为 1,2,3,4,10）: ")
    flag'
}

test_iframe_regex()

end

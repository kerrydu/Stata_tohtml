// 测试 tohtml.ado 721-745 的 extractmdtable 函数
// 依赖：需要先运行 tohtml.ado 使 Mata 函数可用

// 准备测试用 md 文件
tempfile mdfile
local mdpath = subinstr(`"`mdfile'"', "\", "/", .)

// 写入测试内容（含前置空行，用于验证去除前置空行逻辑）
file open fh using `"`mdfile'"', write replace
file write fh ""                          _n  // 空行1
file write fh ""                          _n  // 空行2
file write fh "| A | B |"                 _n
file write fh "|---|---|"                 _n
file write fh "| 1 | 2 |"                _n
file write fh "| 3 | 4 |"                _n
file close fh

// 加载 tohtml（使 Mata 中的 extractmdtable 可用）
// qui do "E:/Stata_tohtml/tohtml.ado"
cap mata mata drop extractmdtable()
mata:

string colvector extractmdtable(string scalar line){
    line2 = usubinstr(line, "<iframe", "", 1)
    line2 = usubinstr(line2, "</iframe>", "", 1)
    line2 = strtrim(line2)
    // 去掉 iframe 开标签的关闭符 ">"，格式为 <iframe filepath >
    if (substr(line2, strlen(line2), 1) == ">") {
        line2 = strtrim(substr(line2, 1, strlen(line2)-1))
    }
    if (!fileexists(line2)) {
        printf("{err}extractmdtable: 文件不存在: %s\n", line2)
        return(J(0, 1, ""))
    }
    mdtext = cat(line2)
    flag = 1
    pos = 1
    maxn = length(mdtext)
    while(flag & pos < maxn ){
        line3 = ustrtrim(mdtext[1])
        if(strlen(line3) == 0){
            if(length(mdtext) > 1){
                mdtext = mdtext[2::length(mdtext)]
            }
            else{
                mdtext = J(0,1,"")
            }
        }
        else{
            flag = 0
        }
        pos = pos + 1
    }
    return(mdtext)
}


end
mata:

// ── 工具：打印分隔线 ────────────────────────────────────────
void sep(string scalar title) {
    printf("\n%s\n", "=== " + title + " ===")
}

// ── 从 Stata 宏取路径 ───────────────────────────────────────
mdpath = st_local("mdpath")

// ──────────────────────────────────────────────────────────
// 测试1: 路径提取逻辑（extractmdtable 内部前两行）
// ──────────────────────────────────────────────────────────
sep("测试1: 路径提取")

lines = (
    "<iframe " + mdpath + " ></iframe>",      // 标准格式（有空格）
    "<iframe " + mdpath + "></iframe>",       // 无尾部空格
    "  <iframe " + mdpath + " ></iframe>  "  // 前后有空白
)

for (i = 1; i <= rows(lines); i++) {
    line2 = usubinstr(lines[i], "<iframe", "", 1)
    line2 = usubinstr(line2, "</iframe>", "", 1)
    line2 = strtrim(line2)
    printf("输入: %-55s\n提取: [%s]\n\n", lines[i], line2)
}

// ──────────────────────────────────────────────────────────
// 测试2: 完整 extractmdtable 调用
// ──────────────────────────────────────────────────────────
sep("测试2: extractmdtable 完整调用（含前置空行剥离）")

input_line = "<iframe " + mdpath + " ></iframe>"
printf("输入行: %s\n\n", input_line)

result = extractmdtable(input_line)

printf("返回行数: %g（预期: 4，原文件6行含2空行）\n", rows(result))
printf("--- 返回内容 ---\n")
for (i = 1; i <= rows(result); i++) {
    printf("  行%g: [%s]\n", i, result[i])
}

// 断言：第一行不为空
assert(ustrtrim(result[1]) != "")
printf("\nPASS: 前置空行已剥除，首行非空\n")

// 断言：内容包含 markdown 表格标记
assert(strpos(result[1], "|") > 0)
printf("PASS: 首行含 '|'，符合 markdown 表格格式\n")

// ──────────────────────────────────────────────────────────
// 测试3: 文件不存在时的行为
// ──────────────────────────────────────────────────────────
sep("测试3: 不存在的文件")

input_bad = "<iframe c:/nonexistent/table999.md ></iframe>"
printf("输入行: %s\n", input_bad)
printf("（cat() 读取不存在文件将返回空向量，下方显示行数）\n")

result_bad = extractmdtable(input_bad)
printf("返回行数: %g\n", rows(result_bad))

end

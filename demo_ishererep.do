*! demo_ishererep.do
*! 演示并测试 tohtml.ado 中的 Mata 函数 ishererep()（约 1764–1790 行）
*! 用法：在仓库根目录下执行  do demo_ishererep.do

version 16
clear all
set more off

* 加载 tohtml.ado（末尾 mata 块会注册 ishererep）
capture confirm file `"`c(pwd)'/tohtml.ado"'
if _rc {
    display as error "未找到 tohtml.ado，请先 cd 到 Stata_tohtml 仓库根目录"
    exit 601
}
quietly do `"`c(pwd)'/tohtml.ado"'

mata:
void function _print_vec(string scalar title, string colvector v)
{
	real scalar i
	printf("\n%s\n", title)
	for (i = 1; i <= rows(v); i++) {
		printf("  [%2.0f] %s\n", i, v[i])
	}
}

void function demo_ishererep()
{
	string colvector in, out

	// 覆盖四种前缀：**#、**/*、***/、**```
	// 含一行前导空格（lines2 去空格后仍以 **# 开头）
	// 含一行不应被改写的普通文本
	in = "" \
	     "  **# 标题" \
	     "**/* 注释起头" \
	     "  ***/ 块结束" \
	     "**```stata 代码围栏" \
	     "普通行 ** 不动" \
	     "## 不是 **# 开头（去空格后）"

	out = ishererep(in)
	_print_vec("输入 (content)", in)
	_print_vec("输出 ishererep(content)", out)

	printf("\n--- 逐行对照（便于肉眼看差异）---\n")
	printf("%-6s | %-28s | %s\n", "行", "输入", "输出")
	printf("%-6s-+-%-28s-+-%-28s\n", "------", "----------------------------", "----------------------------")
	for (i = 1; i <= rows(in); i++) {
		printf("%6.0f | %-28s | %s\n", i, in[i], out[i])
	}
}
demo_ishererep()
end

display as text _n "demo_ishererep.do 执行完毕。"

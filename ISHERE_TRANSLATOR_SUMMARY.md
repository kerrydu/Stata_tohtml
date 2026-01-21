# ishere_translate 函数 - 完整总结

## 📋 概述

这是一个**基于正则表达式**的 Mata 函数，用于解析和转换 `ishere` 语句。不依赖 Stata 的 log 输出，使用纯文本匹配实现。

## 🎯 核心功能

### 主函数签名

```mata
string colvector ishere_translate(string colvector lines)
```

**工作原理:**
1. 输入: 字符串向量（文件的多行）
2. 对每一行检查:
   - **如果以 `ishere` 开头**: 按照 ishere.ado 规则解析，返回解析后的值
   - **如果不以 `ishere` 开头**: 返回原始行内容
3. 输出: 处理后的字符串向量

## 📁 文件清单

| 文件 | 说明 |
|------|------|
| `ishere_translator.mata` | 核心 Mata 函数库（已重写） |
| `ishere_exec.ado` | Stata 命令包装器（已更新） |
| `test_ishere_new.do` | 完整测试套件（7个测试场景） |
| `example_usage.do` | 实用示例（8个使用场景） |
| `ishere_translator_README_v2.md` | 详细文档 |
| `ISHERE_TRANSLATOR_SUMMARY.md` | 本文档 |

## 🚀 快速开始示例

### 示例 1: 简单使用

```stata
do ishere_translator.mata

mata:
// 单行处理
line = "ishere display " + char(34) + "Hello World" + char(34)
result = ishere_translate_line(line)
result  // 输出: Hello World

// 占位符返回空字符串
line2 = "ishere checkpoint1"
result2 = ishere_translate_line(line2)
result2  // 输出: (空字符串)
end
```

### 示例 2: 批量处理

```mata
// 多行处理
lines = (
    "sysuse auto, clear" \
    "ishere display " + char(34) + "Data loaded" + char(34) \
    "summarize price" \
    "ishere marker1" \
    "ishere fig using plot.png"
)

results = ishere_translate(lines)

// 查看结果
for (i=1; i<=rows(results); i++) {
    printf("[%f] %s\n", i, results[i])
}
```

### 示例 3: 文件处理

```mata
// 直接处理文件
results = process_file("myanalysis.do")

// 保存转换结果
fh = fopen("output.md", "w")
for (i=1; i<=rows(results); i++) {
    fput(fh, results[i])
}
fclose(fh)
```

## ✅ 支持的命令类型

### 1. display 命令 ✅

| 输入 | 输出 |
|------|------|
| `ishere display "xxx"` | `xxx` |
| `ishere display 123` | `123` |
| `ishere display "A" " " "B"` | `A B` |

### 2. figure/fig 命令 ✅

| 输入 | 输出 |
|------|------|
| `ishere fig using plot.png` | `![](plot.png)` |
| `ishere fig using plot.png, zoom(80%)` | `<img src="plot.png" style="zoom:80%;">` |
| `ishere fig using plot.png, width(500) height(300)` | `<img src="plot.png" width="500" height="300">` |

### 3. table/tab 命令 ✅

| 输入 | 输出 |
|------|------|
| `ishere tab using table.html` | `<iframe src='table.html' width='100%' height='400px' frameBorder='0'></iframe>` |
| `ishere tab using table.html, width(80%) height(300px)` | `<iframe src='table.html' width='80%' height='300px' frameBorder='0'></iframe>` |

### 4. 占位符命令 ✅

| 输入 | 输出 |
|------|------|
| `ishere xxx` | `""` (空字符串) |
| `ishere checkpoint1` | `""` (空字符串) |
| `ishere marker` | `""` (空字符串) |

## 🔧 可用函数

### 主要函数

```mata
// 1. 批量处理多行
string colvector ishere_translate(string colvector lines)

// 2. 处理单行
string scalar ishere_translate_line(string scalar line)

// 3. 直接处理文件
string colvector process_file(string scalar filename)

// 4. 读取文件行
string colvector read_file_lines(string scalar filename)
```

### 内部解析函数

```mata
// 5. 解析 ishere 语句
string scalar parse_ishere_statement(string scalar line)

// 6. 解析 display 命令
string scalar parse_display_command(string scalar args)

// 7. 解析 figure 命令
string scalar parse_figure_command(string scalar args)

// 8. 解析 table 命令
string scalar parse_table_command(string scalar args)

// 9. 计算简单表达式
string scalar evaluate_simple_expression(string scalar expr)
```

## 🧪 运行测试

```stata
// 运行完整测试套件
do test_ishere_new.do

// 运行实用示例
do example_usage.do
```

## 💡 实际应用场景

### 场景 1: 转换 do 文件为 Markdown

```mata
void convert_to_markdown(string scalar input, string scalar output) {
    string colvector lines, results
    real scalar fh, i
    
    lines = read_file_lines(input)
    results = ishere_translate(lines)
    
    fh = fopen(output, "w")
    for (i=1; i<=rows(results); i++) {
        fput(fh, results[i])
    }
    fclose(fh)
}

convert_to_markdown("analysis.do", "report.md")
```

### 场景 2: 提取所有 ishere 输出

```mata
string colvector extract_ishere_outputs(string scalar filename) {
    string colvector lines, results, outputs
    string scalar line
    real scalar i, n
    
    lines = read_file_lines(filename)
    results = ishere_translate(lines)
    
    outputs = J(0, 1, "")
    for (i=1; i<=rows(lines); i++) {
        line = strtrim(lines[i])
        if (substr(line, 1, 6) == "ishere") {
            if (results[i] != "") {
                outputs = outputs \ results[i]
            }
        }
    }
    
    return(outputs)
}
```

### 场景 3: 选择性保留内容

```mata
// 只保留非空行
string colvector filter_empty_lines(string colvector lines) {
    string colvector filtered
    real scalar i
    
    filtered = J(0, 1, "")
    for (i=1; i<=rows(lines); i++) {
        if (strtrim(lines[i]) != "") {
            filtered = filtered \ lines[i]
        }
    }
    return(filtered)
}

results = ishere_translate(lines)
final = filter_empty_lines(results)
```

## 📊 性能对比

| 特性 | 旧版本 (v1.0) | 新版本 (v2.0) |
|------|---------------|---------------|
| 实现方式 | Stata log 捕获 | 正则表达式 |
| 临时文件 | 需要 | 不需要 |
| 处理速度 | 慢 | 快 |
| 批量处理 | 不支持 | 支持 |
| 依赖性 | 依赖 Stata | 纯 Mata |
| 错误处理 | 可能中断 | 稳健 |

## ⚙️ 技术细节

### 正则表达式模式

```mata
// 检测 ishere 开头
"^ishere\s+"

// 提取命令名
"^(\w+)(.*)"

// 提取引号内容
char(34) + "([^" + char(34) + "]*)" + char(34)

// 提取 using 子句
"using\s+" + char(34) + "([^" + char(34) + "]+)" + char(34)

// 提取选项
"zoom\(([^\)]+)\)"
"width\(([^\)]+)\)"
"height\(([^\)]+)\)"
```

### 字符编码

- 使用 `char(34)` 表示双引号 `"`
- 使用 `char(10)` 表示换行符 `\n`
- 自动转换路径分隔符 `\` 为 `/`

## ⚠️ 注意事项

1. **复杂表达式**: display 命令中的复杂数学表达式可能不会被完全计算
2. **嵌套引号**: 当前版本对深度嵌套的引号支持有限
3. **宏变量**: 不会展开 Stata 宏（如 `$global` 或 `` `local' ``）
4. **文件存在性**: figure/table 命令不检查文件是否实际存在

## 📝 最佳实践

1. **批量处理优先**: 使用 `ishere_translate()` 处理多行比多次调用 `ishere_translate_line()` 更高效
2. **错误检查**: 处理文件前检查文件是否存在
3. **路径规范**: 使用相对路径，避免硬编码绝对路径
4. **备份原文件**: 转换前备份原始 do 文件

## 🔗 相关命令

- `ishere.ado` - 原始 ishere 命令
- `tohtml.ado` - HTML 报告生成器
- `loghtml.ado` - 日志捕获工具
- `logoute.ado` - 表格输出工具

## 👥 作者

Stata to HTML integration team, 2026

## 📄 许可

与 Stata_tohtml 项目相同

---

**快速参考卡片**

```stata
// 加载函数
do ishere_translator.mata

// 单行转换
mata: result = ishere_translate_line("ishere display " + char(34) + "text" + char(34))

// 多行转换
mata: results = ishere_translate(lines)

// 文件转换
mata: results = process_file("file.do")
```

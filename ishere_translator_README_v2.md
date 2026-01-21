# ishere_translate - 基于正则表达式的 ishere 语句解析器

## 版本 2.0 - 重大更新

这个新版本使用**纯正则表达式**解析 ishere 语句，不依赖 Stata 的 log 输出功能，性能更高，更加可靠。

## 核心概念

### 函数签名变化

**新版本 (v2.0):**
```mata
string colvector ishere_translate(string colvector lines)
```
- **输入**: 字符串向量（文件的多行）
- **输出**: 字符串向量（处理后的多行）
- **规则**: 
  - 如果行以 `ishere` 开头，按照 ishere.ado 规则解析，返回解析值
  - 如果不是 ishere 开头，返回原行内容

**单行处理函数:**
```mata
string scalar ishere_translate_line(string scalar line)
```
- **输入**: 单行字符串
- **输出**: 处理后的字符串

## 文件列表

1. **ishere_translator.mata** - 核心 Mata 函数（已重写）
2. **ishere_exec.ado** - Stata 命令包装器（已更新）
3. **test_ishere_new.do** - 新的测试脚本
4. **ishere_translator_README_v2.md** - 本文档

## 快速开始

### 方法 1: 从文件读取并处理

```stata
do ishere_translator.mata

mata:
// 读取并处理整个文件
results = process_file("myfile.do")

// 显示结果
for (i=1; i<=rows(results); i++) {
    printf("%s\n", results[i])
}
end
```

### 方法 2: 处理单行

```stata
do ishere_translator.mata

mata:
line = "ishere display " + char(34) + "Hello" + char(34)
result = ishere_translate_line(line)
printf("Output: %s\n", result)  // 输出: Hello
end
```

### 方法 3: 处理多行数组

```stata
do ishere_translator.mata

mata:
lines = (
    "sysuse auto, clear" \
    "ishere display " + char(34) + "Data loaded" + char(34) \
    "summarize price" \
    "ishere checkpoint1" \
    "ishere fig using plot.png"
)

results = ishere_translate(lines)

for (i=1; i<=rows(results); i++) {
    printf("%s\n", results[i])
}
end
```

## 支持的 ishere 命令

### 1. display 命令

**输入:**
```stata
ishere display "Hello World"
```

**输出:**
```
Hello World
```

**复杂示例:**
```stata
ishere display "Part 1" " and " "Part 2"
// 输出: Part 1 and Part 2

ishere display 123
// 输出: 123

ishere display `"Compound quote"'
// 输出: Compound quote
```

### 2. figure/fig 命令

**基本语法:**
```stata
ishere fig using plot.png
// 输出: ![](plot.png)
```

**带选项:**
```stata
ishere fig using plot.png, zoom(80%)
// 输出: <img src="plot.png" style="zoom:80%;">

ishere fig using plot.png, width(500) height(300)
// 输出: <img src="plot.png" width="500" height="300">
```

### 3. table/tab 命令

**基本语法:**
```stata
ishere tab using table.html
// 输出: <iframe src='table.html' width='100%' height='400px' frameBorder='0'></iframe>
```

**带选项:**
```stata
ishere tab using table.html, width(80%) height(300px)
// 输出: <iframe src='table.html' width='80%' height='300px' frameBorder='0'></iframe>
```

### 4. 占位符命令

任何不是 display/fig/figure/tab/table 的命令都被视为占位符，返回空字符串：

```stata
ishere checkpoint1
// 输出: ""

ishere marker
// 输出: ""
```

## 主要函数说明

### 1. `ishere_translate(lines)`
处理字符串向量，自动识别 ishere 语句

```mata
string colvector lines = ("line1" \ "ishere display " + char(34) + "text" + char(34))
string colvector results = ishere_translate(lines)
// results[1] = "line1"
// results[2] = "text"
```

### 2. `ishere_translate_line(line)`
处理单个字符串

```mata
string scalar line = "ishere display " + char(34) + "Hello" + char(34)
string scalar result = ishere_translate_line(line)
// result = "Hello"
```

### 3. `process_file(filename)`
直接读取并处理文件

```mata
string colvector results = process_file("script.do")
```

### 4. `read_file_lines(filename)`
从文件读取所有行

```mata
string colvector lines = read_file_lines("script.do")
```

### 5. `parse_ishere_statement(line)`
解析单个 ishere 语句（内部函数）

### 6. `parse_display_command(args)`
解析 display 命令参数（内部函数）

### 7. `parse_figure_command(args)`
解析 figure 命令参数（内部函数）

### 8. `parse_table_command(args)`
解析 table 命令参数（内部函数）

## 使用示例

### 示例 1: 处理 do 文件并生成报告

```stata
do ishere_translator.mata

mata:
// 读取 do 文件
lines = read_file_lines("analysis.do")

// 处理所有 ishere 语句
results = ishere_translate(lines)

// 写入输出文件
fh = fopen("output.md", "w")
for (i=1; i<=rows(results); i++) {
    fput(fh, results[i])
}
fclose(fh)
end
```

### 示例 2: 选择性处理

```stata
do ishere_translator.mata

mata:
lines = read_file_lines("script.do")
results = ishere_translate(lines)

// 只保留有内容的行
for (i=1; i<=rows(results); i++) {
    if (strtrim(results[i]) != "") {
        printf("%s\n", results[i])
    }
}
end
```

### 示例 3: 实时转换

```stata
do ishere_translator.mata

mata:
void convert_ishere(string scalar input, string scalar output) {
    string colvector lines, results
    real scalar fh, i
    
    // 读取输入
    lines = read_file_lines(input)
    
    // 转换
    results = ishere_translate(lines)
    
    // 写入输出
    fh = fopen(output, "w")
    for (i=1; i<=rows(results); i++) {
        fput(fh, results[i])
    }
    fclose(fh)
    
    printf("Converted %f lines\n", rows(results))
}

// 使用
convert_ishere("input.do", "output.md")
end
```

## 测试

运行完整的测试套件：

```stata
do test_ishere_new.do
```

测试包括：
1. 完整文件处理
2. 单行处理
3. display 命令解析
4. figure 命令解析
5. table 命令解析
6. 占位符命令
7. 混合内容处理

## 性能优势

与旧版本相比，新版本的优势：

- ✅ **不需要 log 文件**: 不创建临时文件，速度更快
- ✅ **纯正则表达式**: 解析更可靠，不依赖 Stata 输出格式
- ✅ **批量处理**: 可以一次处理整个文件
- ✅ **更好的错误处理**: 解析错误不会中断程序
- ✅ **可预测性**: 完全基于文本匹配，结果一致

## 注意事项

1. **复杂的 display 表达式**: 当前版本对复杂的数学表达式支持有限，会返回原始表达式
2. **引号处理**: 支持 `"..."` 和 `` `"..."' `` 两种引号风格
3. **路径分隔符**: 自动将 `\` 转换为 `/`
4. **大小写**: 命令名（display, fig, tab）不区分大小写

## 兼容性

- Stata 14 或更高版本
- 不需要 ishere.ado（但如果有的话会更完整）
- 纯 Mata 实现，跨平台兼容

## 作者

Stata to HTML integration team, 2026

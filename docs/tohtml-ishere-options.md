# tohtml / ishere 选项说明

`ishere` 在 do-file / log 里做标记；`tohtml` 把 log 转成 Markdown 和 HTML 报告。  
本文汇总两个命令的现行选项（`tohtml` 1.43，`ishere` 1.19）。

---

## 1. 工作流（选项从哪来）

```stata
log using "analysis.log", replace text
ishere # 标题
ishere fig using "fig.png", title("图题")
ishere tab using "tab.html", title("表题")
log close

tohtml "analysis.log", html("report.html") replace
```

- **图/表标题、缩放、表格 CSS**：写在 `ishere` 上，由 `tohtml` 排版。
- **报告样式、表格滚动、打包/内嵌**：写在 `tohtml` 上。

---

## 2. ishere

语法分两种：占位（无输出）和发出内容（写入 log，供 `tohtml` 保留）。

### 2.1 占位：标题与代码块

| 写法 | 作用 |
|------|------|
| `ishere # 标题` / `ishere ## 小节` | Markdown 标题 |
| `ishere` 或 `ishere ```` ` 或 `**```` ` | 代码块边界（默认可省略，`tohtml` 会自动给命令加围栏） |

叙述段落用 `/**` … `**/`，不要用 `ishere /*`。

### 2.2 发出数值：`display`

```stata
ishere display %5.3f e(r2)
/**
R-squared 为 {ishere display %5.3f e(r2)}。
**/
```

`{ishere display ...}` 必须与前面那条 `ishere display` **字面一致**，只替换**其后第一个**叙述块。

### 2.3 插图：`fig` / `figure`

```stata
ishere fig using "scatter.png" [, zoom() height() width() title()]
```

| 选项 | 默认 | 说明 |
|------|------|------|
| `using` | 必填 | 图片路径；`\` 会改成 `/` |
| `zoom()` | `100%`（未指定高/宽时） | 缩放，如 `80%` 或 `80` |
| `height()` | — | CSS 高度，如 `300px`；与 `zoom()` 互斥用法：指定高/宽则不用 zoom |
| `width()` | — | CSS 宽度 |
| `title()` | 无 | 图题；**图下方居中**。有空格/逗号请加引号 |

支持：PNG, JPG, JPEG, SVG, GIF, BMP, WEBP。

```stata
ishere fig using "scatter.png", zoom(80%) title("Price versus MPG")
ishere figure using "scatter.png", height(400px) width(600px)
```

### 2.4 插表：`tab` / `table`

```stata
ishere tab using "table1.html" [, height() width() cssfile() title()]
```

| 选项 | 默认 | 说明 |
|------|------|------|
| `using` | 必填 | `.html` / `.htm` 或 `.md` |
| `width()` | `100%` | 仅 HTML 表（标记用 iframe 宽度）；`.md` 忽略 |
| `height()` | — | HTML 表忽略（`tohtml` 会把表内嵌进报告）；`.md` 忽略 |
| `cssfile()` | 同名 `.css`，或该目录里唯一未配对的 collect CSS | `collect export, tableonly` 的样式文件；文件必须存在。`.md` 忽略 |
| `title()` | 无 | 表题；**表上方**（在滚动框外面，表滚动时标题仍可见） |

```stata
ishere tab using "table1.html", title("Regression results")
ishere tab using "table1.html", cssfile("mystyle.css")
ishere tab using "table1.md"
```

`tohtml` 会把 `ishere tab` 的 iframe **一律换成表的 HTML**（默认 / `clean` / `cleancode` / `embed` 都一样）。

---

## 3. tohtml

```stata
tohtml filename|directory [, options]
```

输入可以是单个 log（推荐 `text`；`.smcl` 会自动 `translate`），或一个目录（收集 `table*.html` 与 `figure*.png` 等）。

### 3.1 输出

| 选项 | 默认 | 说明 |
|------|------|------|
| `md(filename)` | 与 HTML 同名、扩展名 `.md` | 输出 Markdown；不能与输入文件同路径 |
| `html(filename)` | 输入主名 + `.html` | 再转成 HTML；缺扩展名会补 `.html` |
| `replace` | 关 | 覆盖已有文件；不写且文件已存在会报错 |

```stata
tohtml "analysis.log", replace
tohtml "analysis.log", md("report.md") html("report.html") replace
```

### 3.2 样式

| 选项 | 默认 | 说明 |
|------|------|------|
| `css(filename)` | 包内 `tohtml.css`（GitHub 风） | 自定义 CSS，会复制到 HTML 旁的 `css/`。collect / outreg2e 三线表用自己的样式，不受 `tohtml.css` 改写 |
| `mathjax` | 关 | 检测到 `$...$` / `$$...$$` / `\(...\)` / `\[...\]` 时注入 MathJax CDN；与 CSS 独立，看公式需要联网 |

```stata
tohtml "analysis.log", html("report.html") css("mystyle.css") mathjax replace
```

### 3.3 内嵌表滚动（所有报告模式）

表格都会内嵌进 `.tohtml-embedded-table`。过宽/过长出现滚动条。需要 `html()`。

| 选项 | 默认 | 说明 |
|------|------|------|
| `tabwidth(size)` | `100%` | 表框随表格变宽，直到该上限；再宽才出现横向滚动。大于 `100%`（如 `1000%`）可让表超出正文栏而不出现表内滚动条。纯数字当像素：`800` → `800px`。`none` / `off` / `.` 取消上限 |
| `tabheight(size)` | `80vh` | 表框最大高度；超出纵向滚动。`none` / `off` / `.` 让表随内容变长 |

含 `%` 时建议加引号：`tabwidth("100%")`。  
与目录模式的 `width()` / `height()` **不是同一套**。

```stata
tohtml "analysis.log", html("report.html") tabwidth("100%") tabheight("80vh") replace
tohtml "analysis.log", html("report.html") tabheight(400) replace
tohtml "analysis.log", html("report.html") tabheight(none) replace
```

`css()` / `mathjax` / `embed` / `bundle` / `zip()` / `tabwidth()` / `tabheight()` 都要求同时写 `html()`。

### 3.4 便携包

| 选项 | 说明 |
|------|------|
| `embed` | 单文件 HTML：报告 CSS 内联；图片 Base64；表始终内嵌（不只 embed） |
| `bundle` | 把图/表/CSS 收到 HTML 目录下的 `css/`、`figures/`、`tables/`，并改成相对路径 |
| `zip(filename\|.)` | 先 `bundle` 再打包。`zip(.)` 按 HTML 主名命名，如 `report.html` → `report.zip` |

`embed` 成功后不必再 bundle 图和报告 CSS；MathJax / highlight.js 仍走 CDN。

```stata
tohtml "analysis.log", html("report.html") embed replace
tohtml "analysis.log", html("report/report.html") bundle replace
tohtml "analysis.log", html("report/report.html") zip(.) replace
```

### 3.5 清洗模式（不可同时开）

| 选项 | 保留 | 丢掉 |
|------|------|------|
| （默认） | 命令、输出、标题、图、表、叙述 | log 控制符等 |
| `clean` | `#` 标题、图、表、`/**` 叙述 | 全部代码与结果 |
| `cleancode` | 命令行（`.` / `>`）、图、表、叙述 | 命令输出。配合 `html()` 会注入 highlight.js |

```stata
tohtml "analysis.log", clean html("clean.html") replace
tohtml "analysis.log", cleancode html("code.html") replace
```

### 3.6 目录模式专用（输入是文件夹时）

| 选项 | 默认 | 说明 |
|------|------|------|
| `width()` | `100%` | 该目录下图/表的默认宽度 |
| `height()` | `400px` | 默认高度 |
| `zoom()` | `100%` | 图片默认缩放 |

```stata
tohtml "output/", html("report.html") zoom(80%) replace
```

---

## 4. 两边如何配合

| 需求 | 写在 | `tohtml` 做什么 |
|------|------|-----------------|
| 图题（下、居中） | `ishere fig ..., title()` | 包成 `<figure class="tohtml-figure">` |
| 表题（上、表滚动时仍可见） | `ishere tab ..., title()` | 包成 `<figure class="tohtml-table-block">` |
| 图缩放/尺寸 | `ishere fig ..., zoom()/width()/height()` | 保留 `<img>` 上的样式 |
| collect 表样式 | `ishere tab ..., cssfile()` | 内联 companion CSS |
| 宽/长表滚动 | `tohtml ..., tabwidth() tabheight()` | 给内嵌表加 `overflow` |
| 单文件分享 | `tohtml ..., embed` 或 `zip()` | Base64 / 打包相对路径 |

`ishere` 把 `title()` 写在 log 标记的 `data-tohtml-title` 上；log 折行由 `tohtml` 拼回后再排版。

---

## 5. 常用组合

```stata
* 完整报告
tohtml "analysis.log", html("report.html") replace

* 只要标题和图/表
tohtml "analysis.log", clean html("slides.html") replace

* 教材：命令 + 图/表，不要大段输出
tohtml "analysis.log", cleancode html("lab.html") replace

* 发给别人一个 HTML（图已内嵌，表已内嵌）
tohtml "analysis.log", html("report.html") embed ///
    tabwidth("100%") tabheight("80vh") replace
```

对应 do 里：

```stata
scatter price mpg
graph export "scatter.png", replace
ishere fig using "scatter.png", title("Price versus MPG")

outreg2e [model1] using "table_regression", replace html
ishere tab using "table_regression.html", title("Regression results")
```

`outreg2e` 的 `html` 只写 `.html`，`md` 只写 `.md`；两份都要就同时写 `html md`。

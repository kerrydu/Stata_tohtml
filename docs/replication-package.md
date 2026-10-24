# 经济学实证研究复制包组织指南

复制包要让别人从原始数据走到论文里的每一张表、每一幅图，以及正文里的每一个数字。组织上只抓两件事。

数据和脚本各有固定位置。脚本跑完之后，表、图和叙述一起写成 Markdown 与 HTML，正文里的数字来自这次运行，不另抄一份。

Stata、Python、MATLAB、R 用同一套目录。分析脚本保持该语言的普通脚本。报告在脚本结束时生成。Stata 用 `ishere` 与 `tohtml`，Python 用 `python_tohtml`，MATLAB 用 `matlab_tohtml`，R 用 R 脚本写出表和图，再用 R Markdown 汇编。

## 目录

在项目根目录运行主脚本。主脚本先确认当前目录里有 `README.md`，再建立下面这些目录。子脚本里的路径都相对项目根，不再改工作目录。

```text
project/
  README.md
  data/
    raw/                 下载或数据提供方给的文件
    derived/             清洗之后、回归之前的分析数据
  code/
    00_config.*          路径、种子、样本定义
    01_build.*           raw → derived，并写出样本构建报告
    02_describe.*        描述统计和图
    03_estimate.*        估计和主表
    04_report.Rmd        仅 R 需要：把已写好的文件汇编成报告
    master.*             按编号调用上面的脚本
  output/
    tables/              table_01_summary.html 这类文件
    figures/             figure_01_trend.png 这类文件
    logs/                运行记录，以及正文要引用的标量
    reports/             生成的 .md 与 .html
```

一种语言就够用时，`code/` 里直接放脚本。一个项目里有多种语言时，改成 `code/stata`、`code/python`、`code/matlab`、`code/r`，`data/` 和 `output/` 仍然共用。

文件名决定目录收集能不能看见它们。表以小写 `table` 开头，扩展名为 `.html` 或 `.md`。图以小写 `figure` 开头，扩展名为 `.png`、`.jpg`、`.jpeg`、`.svg`、`.gif`、`.bmp`、`.webp`。扩展名用小写。编号写在前缀后面，例如 `table_02_main.html`、`figure_01_trend.png`，排序后即论文顺序。

`tohtml`、`python -m python_tohtml gather`、`matlab_tohtml.gather` 只看目录本身，不进入子目录。给论文用的表和图放在 `output/tables` 和 `output/figures` 这一层。中间文件放在 `output/logs` 或其他单独目录。

## 数据

`data/raw` 保持拿到时的样子。清洗、合并、样本筛选写入 `data/derived`。回归脚本读取 `derived`，这样描述统计和回归用的是同一份分析数据。

可以重新生成的中间文件放在 `output/`。删掉 `data/derived` 和 `output/` 之后，从主脚本重跑，应得到同一套表、图和报告。

随机数在 `00_config` 里设一次种子，并把种子写进 `README.md`。

外部数据在 `README.md` 写明来源、版本、下载日期和许可。许可允许再分发时，原始文件放在 `data/raw`。许可不允许再分发时，`data/raw` 只留获取脚本和变量说明，分析脚本在缺文件时直接停下来。

样本从原始观测数到回归观测数的每一步筛选，写在 `01_build` 的叙述里，并随该脚本生成 `output/reports/01_build.html`。后文引用的样本量来自这份分析数据，而不是另算一遍。

## 脚本

一个脚本做一件事，文件名用两位编号。主脚本只做三件事：确认项目根、准备目录、按编号调用。估计写在对应编号的脚本里。

每个分析脚本可以单独重跑。它从 `data/derived` 读数据，把表和图写到 `output/`，再写出自己的报告。它不依赖上一个脚本留在内存里的数据。

论文里的一件结果对应脚本里的一处导出：

| 论文里的东西 | 脚本里做什么 |
| --- | --- |
| 一张表 | 用该语言的制表命令写成 `output/tables/table_*.html` |
| 一幅图 | 导出为 `output/figures/figure_*.png`（或 `.svg`） |
| 一段解释 | 写在产生这些数字的同一脚本里 |
| 正文中的一个数 | 从估计结果填进叙述 |

`README.md` 用一张表把三者连起来。读者按这张表找到脚本，重跑之后对照 `output/`。

| 论文 | 脚本 | 产出 |
| --- | --- | --- |
| 表 1 描述统计 | `code/02_describe` | `output/tables/table_01_summary.html` |
| 图 1 | `code/02_describe` | `output/figures/figure_01_trend.png` |
| 表 2 主回归 | `code/03_estimate` | `output/tables/table_02_main.html` |
| 正文中的系数与 R² | `code/03_estimate` 的叙述 | `output/reports/03_main.html` |

生成的 HTML 和 Markdown 可以提交，方便别人先阅读再重跑。它们是运行结果。要改标题、解释或数字，就改脚本，再运行主脚本。

## 跑完即出报告

四种语言共用一个顺序。

1. 脚本照常做分析。
2. 表和图写成文件。
3. 叙述写在脚本里，和计算挨在一起。
4. 标记说明哪一张表、哪一幅图出现在哪一节。
5. 脚本结束时写出 Markdown 和 HTML。

报告给三种读者。同一份脚本，换一个开关再生成一次即可。

| 模式 | 留给读者的内容 | 适合 |
| --- | --- | --- |
| 默认 | 代码、命令输出、叙述、图、表 | 自己核对某一步 |
| clean | 标题、叙述、图、表 | 合作者读结果，或作为论文附录的底稿 |
| cleancode | 代码、叙述、图、表 | 想看命令、但不看长日志 |

Markdown 是可继续编辑的底稿，HTML 用来阅读。公式用 `$...$` 或 `$$...$$`。Stata 在 `tohtml` 上加 `mathjax`；Python 和 MATLAB 在检测到公式时加载 MathJax。

### Stata

分析写在 do 文件里。文本日志打开之后，`ishere` 标出结构，估计结果先导出成文件，再由 `ishere` 收进日志。日志关闭之后调用 `tohtml`。

```stata
capture log close
log using "output/logs/03_main.log", replace text

ishere # 主结果

regress y treat x1 x2, vce(robust)
estimates store main
ishere display %5.3f _b[treat]
/**
处理效应为 {ishere display %5.3f _b[treat]}。
**/

outreg2e [main] using "output/tables/table_02_main.html", replace html
ishere tab using "output/tables/table_02_main.html", title("主回归")

twoway (scatter y x1) (lfit y x1)
graph export "output/figures/figure_02_fit.png", replace
ishere fig using "output/figures/figure_02_fit.png", title("拟合")

capture log close
tohtml "output/logs/03_main.log", ///
    md("output/reports/03_main.md") ///
    html("output/reports/03_main.html") ///
    mathjax replace
```

给合作者的版本在 `tohtml` 上加 `clean`。留下命令、去掉屏幕输出时用 `cleancode`。单文件传递时加 `embed`。连同图和表打成一个压缩包时用 `zip(.)`。

`{ishere display ...}` 与前面的 `ishere display` 使用同一格式和同一表达式，按字面写在 `/** ... **/` 里。

许多小程序各自只导出文件、叙述集中在别的地方时，用目录模式收成一册：

```stata
tohtml "output/tables" "output/figures", ///
    html("output/reports/exhibits.html") replace
```

### Python

脚本是普通 `.py` 文件。顶层三引号字符串（含 f 字符串）成为叙述。`# ishere` 标出标题、图和表。

```python
from python_tohtml import summarize, scatter, regress, etable

# ishere # 主结果

s = summarize("output/tables/table_01_summary.html", {"价格": price, "油耗": mpg})
# ishere tab using "output/tables/table_01_summary.html", title("描述统计")

f"""
样本量为 {s['价格'].n}。
"""

m = regress(price, {"油耗": mpg})
etable("output/tables/table_02_main.html", [m], note="因变量为价格。")
# ishere tab using "output/tables/table_02_main.html", title("主回归")

scatter("output/figures/figure_01_fit.svg", price, mpg, xlabel="油耗", ylabel="价格", fit=True)
# ishere fig using "output/figures/figure_01_fit.svg", title("价格与油耗")
```

先 `pip install -e python_tohtml`，或把该目录加入 `PYTHONPATH`。在项目根目录运行：

```bash
python -m python_tohtml run code/03_estimate.py \
    --html output/reports/03_main.html \
    --md output/reports/03_main.md \
    --log output/logs/03_main.log
```

`--clean` 与 `--cleancode` 对应上面两种精简报告。叙述里出现没有放进 `{}` 的手写数字时，程序会警告，提醒把该数写进 f 字符串。

目录收集：

```bash
python -m python_tohtml gather output/tables output/figures \
    --html output/reports/exhibits.html --zoom 80%
```

### MATLAB

脚本是普通 `.m` 文件。顶层 `sprintf`、`string`、`strcat`、`compose`，以及单独成行的字符串，进入叙述。块注释 `%{ ... %}` 和 `% /** ... % **/` 也是叙述。公式放在块注释里，避免 `sprintf` 把 `\beta` 当成转义。

```matlab
% ishere # 主结果

s = matlab_tohtml.summarize('output/tables/table_01_summary.html', {'价格', price, '油耗', mpg});
% ishere tab using "output/tables/table_01_summary.html", title("描述统计")

sprintf('样本量为 %d。', s.('价格').n)

m = matlab_tohtml.regress(price, {'油耗', mpg});
matlab_tohtml.etable('output/tables/table_02_main.html', {m}, 'note', '因变量为价格。');
% ishere tab using "output/tables/table_02_main.html", title("主回归")

matlab_tohtml.scatter('output/figures/figure_01_fit.svg', price, mpg, ...
    'xlabel', '油耗', 'ylabel', '价格', 'fit', true);
% ishere fig using "output/figures/figure_01_fit.svg", title("价格与油耗")
```

中文名称用元胞成对写出，读取时用 `s.('价格').mean`。脚本末尾的局部函数不会被执行；要复用的函数放在单独的 `.m` 文件里。

把 `matlab_tohtml` 加入路径后再运行。

```matlab
addpath('matlab_tohtml')
matlab_tohtml.run('code/03_estimate.m', ...
    'html', 'output/reports/03_main.html', ...
    'md', 'output/reports/03_main.md', ...
    'log', 'output/logs/03_main.log')
```

`'clean', true` 与 `'cleancode', true` 对应两种精简报告。块注释里的数字用 `% ishere display ...` 先算出，再在注释中写 `{ishere display ...}`。

```matlab
matlab_tohtml.gather({'output/tables', 'output/figures'}, ...
    'html', 'output/reports/exhibits.html', 'zoom', '80%')
```

### R 与 R Markdown

R 分成两层，目录约定与上面三种语言相同。

分析放在 `.R` 里，用 `Rscript` 运行。`modelsummary`、`gt` 或 `knitr::kable` 把表写成 `output/tables/table_*.html`。`ggplot2` 把图写成 `output/figures/figure_*.png` 或 `.svg`。正文要用的标量写成 `output/logs/*.rds`。

R Markdown 负责汇编。它读取已经写好的表、图和标量，自己不再估计一遍。这样改一句解释只需重新渲染，改一个系数才重跑估计脚本。渲染时把 `knit_root_dir` 设为项目根，R Markdown 里的路径就和 `.R` 脚本一样。

`code/03_estimate.R` 把同一张表存两份：HTML 文件供目录收集和论文对照，对象供 R Markdown 嵌进报告，这样渲染时不再估计。

```r
m <- lm(y ~ treat + x1 + x2, data = analysis)
tab <- modelsummary(
  list("(1)" = m),
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  notes = "因变量为 y。"
)
saveRDS(tab, "output/logs/table_02_main.rds")
modelsummary(
  list("(1)" = m),
  output = "output/tables/table_02_main.html",
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  notes = "因变量为 y。"
)
ggplot(analysis, aes(x1, y)) + geom_point() + geom_smooth(method = "lm")
ggsave("output/figures/figure_02_fit.png", width = 6, height = 4)
saveRDS(
  list(n = nobs(m), beta = coef(m)[["treat"]], r2 = summary(m)$r.squared),
  "output/logs/main_scalars.rds"
)
```

`code/03_report.Rmd` 只读这些文件。图用相对 `output/reports` 的路径，因为图片由 knitr 复制；表用已经算好的对象打印，避免把一整页 HTML 再嵌进另一页。

````markdown
---
title: "主结果"
params:
  mode: clean
output:
  html_document:
    self_contained: true
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(
  echo = params$mode != "clean",
  message = FALSE,
  warning = FALSE
)
scalars <- readRDS("output/logs/main_scalars.rds")
```

# 主结果

样本量为 `r scalars$n`。处理效应为 `r sprintf("%.3f", scalars$beta)`。

```{r table, echo=params$mode == "cleancode"}
readRDS("output/logs/table_02_main.rds")
```

```{r fig, echo=params$mode == "cleancode"}
knitr::include_graphics("output/figures/figure_02_fit.png")
```
````

`params$mode` 取 `full`、`clean` 或 `cleancode`。`clean` 隐藏代码，留下叙述、图和表。`cleancode` 显示这两段代码，估计过程的长输出留在 `Rscript` 的记录里。

主脚本在估计之后渲染，工作目录仍是项目根：

```r
rmarkdown::render(
  "code/03_report.Rmd",
  output_file = "03_main.html",
  output_dir = "output/reports",
  knit_root_dir = getwd(),
  params = list(mode = "clean")
)
```

短笔记可以把分析和叙述写进同一个 R Markdown，仍由主脚本调用 `rmarkdown::render`。样本构建和估计一长，就拆回 `.R`，让 R Markdown 只做汇编。表和图的文件名仍用 `table*` 与 `figure*`，以便和 Stata、Python、MATLAB 的目录收集放在一起。

## 主脚本

主脚本自己不估计。下面四段都假定从项目根运行。

Stata：`stata-mp -b do code/master.do`

```stata
* adopath ++ 指向含 tohtml.ado 的目录
capture confirm file "README.md"
if _rc {
    display as error "请在项目根目录运行 code/master.do"
    exit 601
}
foreach d in "data/derived" "output/tables" "output/figures" "output/logs" "output/reports" {
    capture mkdir "`d'"
}
do "code/01_build.do"
do "code/02_describe.do"
do "code/03_estimate.do"
```

Python：`python code/master.py`

```python
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
if not (root / "README.md").is_file():
    sys.exit("请在项目根目录放置 README.md，并从 code/master.py 运行")
for folder in ("data/derived", "output/tables", "output/figures", "output/logs", "output/reports"):
    (root / folder).mkdir(parents=True, exist_ok=True)
for script in ("01_build.py", "02_describe.py", "03_estimate.py"):
    subprocess.run(
        [sys.executable, "-m", "python_tohtml", "run", f"code/{script}",
         "--html", f"output/reports/{Path(script).stem}.html"],
        cwd=root,
        check=True,
    )
```

MATLAB 或 Octave：在项目根执行 `run('code/master.m')`。

```matlab
addpath('matlab_tohtml')
if exist('README.md', 'file') ~= 2
    error('请在项目根目录运行 code/master.m');
end
folders = {'data/derived', 'output/tables', 'output/figures', 'output/logs', 'output/reports'};
for k = 1:numel(folders)
    if exist(folders{k}, 'dir') ~= 7
        mkdir(folders{k});
    end
end
scripts = {'code/01_build.m', 'code/02_describe.m', 'code/03_estimate.m'};
for k = 1:numel(scripts)
    [~, name] = fileparts(scripts{k});
    matlab_tohtml.run(scripts{k}, 'html', fullfile('output', 'reports', [name '.html']));
end
```

R：`Rscript code/master.R`

```r
if (!file.exists("README.md")) stop("请在项目根目录运行 Rscript code/master.R")
for (d in c("data/derived", "output/tables", "output/figures", "output/logs", "output/reports")) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
}
source("code/01_build.R")
source("code/02_describe.R")
source("code/03_estimate.R")
rmarkdown::render(
  "code/03_report.Rmd",
  output_file = "03_main.html",
  output_dir = "output/reports",
  knit_root_dir = getwd(),
  params = list(mode = "clean")
)
```

## README 里写清的事

`README.md` 放在项目根，读者不打开脚本也能开始。

- 论文题目、作者，以及本包对应的表和图。
- 上一节那张「论文 → 脚本 → 产出」对照表。
- 软件版本：Stata 版本，Python 及 `python_tohtml`，MATLAB 或 Octave，R 版本。依赖用 `requirements.txt`、`renv.lock` 或一份包列表固定下来。
- 从项目根运行主脚本的命令。随机数种子。
- 数据来源、版本、下载日期、许可。原始文件已包含，还是需要先运行获取脚本。
- 哪些目录是生成的。删掉 `data/derived` 和 `output/` 后重跑主脚本，即完整复制。

## 四种语言怎么对齐

| | Stata | Python | MATLAB | R |
| --- | --- | --- | --- | --- |
| 分析文件 | `.do` | `.py` | `.m` | `.R`，报告为 `.Rmd` |
| 标题 | `ishere #` | `# ishere #` | `% ishere #` | Markdown 标题 |
| 叙述 | `/** ... **/` | 顶层三引号字符串 | `sprintf(...)` 或 `%{ ... %}` | 正文与 `` `r ...` `` |
| 正文中的数 | `ishere display` 与 `{ishere display ...}` | f 字符串的 `{}` | `sprintf` 或 `{ishere display ...}` | `` `r scalars$beta` `` |
| 表 | `outreg2e`、`table, export()`，再 `ishere tab using` | `summarize`、`etable`，再 `# ishere tab using` | `summarize`、`etable`，再 `% ishere tab using` | `modelsummary` 等写成 HTML，Rmd 用 `includeHTML` |
| 图 | `graph export`，再 `ishere fig using` | `scatter`，再 `# ishere fig using` | `scatter`，再 `% ishere fig using` | `ggsave`，Rmd 用 `include_graphics` |
| 跑完出报告 | `tohtml` 日志 | `python -m python_tohtml run` | `matlab_tohtml.run` | `rmarkdown::render` |
| 只收集表和图 | `tohtml` 后接目录 | `python -m python_tohtml gather` | `matlab_tohtml.gather` | 文件名用 `table*`、`figure*`，可与前三列的收集放在同一目录 |

`scatter` 与回归的变量顺序是 y 在前、x 在后，与 Stata 一致。

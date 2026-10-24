# python_tohtml

一份 Python 脚本是分析本身。脚本里用标记写标题、叙述、图和表；运行器从头执行，把命令、输出和标记写成一份文本记录；再由这份记录生成 Markdown 和 HTML。

这是 Stata 里 `ishere` / `tohtml` 的 Python 版本，给应用计量和 AI agent 用。Agent 改的是普通 `.py`，读的是记录里的系数和报错，正文里的数字由这一次运行填进去。

## 运行

在本目录下：

```bash
python -m python_tohtml run examples/auto_price.py --html examples/auto_price.html
```

会写出三份文件：

- `auto_price.log`：可搜索的运行记录
- `auto_price.md`：给人读的 Markdown
- `auto_price.html`：报告

脚本中途失败时，记录和报告停在错误那一行，进程返回非 0。改完脚本再整份重跑。

## 在脚本里写什么

```python
from python_tohtml.ishere import h1, h2, md, fig, tab, show
from python_tohtml.tables import summ, etable

h1("价格")
print(f"N = {len(df)}")          # 完整报告里能看到

summ("results/summary.html", {"价格": price, "油耗": mpg})
tab("results/summary.html", title="描述统计")

fig("figures/price.svg", title="价格与油耗")   # 先把图写到磁盘

etable("results/reg.html", [model1, model2], titles=["(1)", "(2)"])
tab("results/reg.html", title="回归结果")

show("r2", f"{r2:.3f}")
md("拟合优度为 {r2}。")           # 名字在渲染时替换
md(f"系数是 {beta:.2f}。")        # 或者直接写 f-string
```

单独的字符串语句也会当成叙述。图先保存再 `fig`，表先写成 HTML 再 `tab`。路径留在记录里，agent 可以直接打开那份表。

`etable` 接受字典，也接受带 `params`、`bse`、`pvalues`、`nobs`、`rsquared` 的结果对象。`summ` 写 N、均值、标准差、最小和最大值，标准差用样本标准差。

叙述里如果写死了小数或至少两位的整数，完整报告会标出来。年份这类必须手写的数字用 `md("1990 年", allow_numbers=True)`。一位数字（例如 `$R^2$`）不会标。

## 三种报告

| 命令 | 留下 |
| --- | --- |
| （默认） | 代码、输出、叙述、图、表 |
| `--clean` | 标题、叙述、图、表 |
| `--cleancode` | 代码、叙述、图、表，不留命令输出 |

```bash
python -m python_tohtml run analysis.py --html report.html --clean
python -m python_tohtml run analysis.py --html report.html --embed
python -m python_tohtml build analysis.log --html report.html --cleancode
```

`--embed` 把图片嵌进 HTML。公式默认在发现 `$...$` 或 `$$...$$` 时加载 MathJax。宽表在 `100%` × `80vh` 的框里滚动，表题留在框外；用 `--tabwidth` 和 `--tabheight` 改，`none` 表示不限制。

只跑 `python analysis.py` 时，标记会打到标准输出，但没有代码回显。要实验记录，用上面的 `run`。

## 和 Stata 版的对应

| Stata | Python |
| --- | --- |
| `ishere # 标题` | `h1("标题")` |
| `ishere ## 小节` | `h2("小节")` |
| `/** ... **/` | `md("...")`，或单独一个字符串 |
| `ishere fig using` | `fig(path, title=...)` |
| `ishere tab using` | `tab(path, title=...)` |
| `ishere display` | `show("名字", f"{值:.3f}")`，叙述里写 `{名字}` |
| `tohtml ..., clean` | `--clean` / `--cleancode` / `--embed` |

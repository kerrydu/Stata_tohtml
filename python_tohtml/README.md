# python_tohtml

脚本照常写。报告结构只用注释标记，和 Stata 的 `ishere` / `/** **/` 一样。表和图不在脚本里拼 HTML：先调用命令把文件写出来，再用标记收进报告。

```bash
python -m python_tohtml run examples/auto_price.py --html examples/auto_price.html
```

在 `python_tohtml` 目录里运行，或先 `pip install -e .`。直接执行脚本也会把表和图写到磁盘；HTML 报告由上面的命令生成。

## 标记和导出

```python
from python_tohtml import summarize, scatter, regress, etable

# ishere # 标题
# ishere ## 小节

s = summarize("results/summary.html", {"价格": price, "油耗": mpg})
# ishere tab using "results/summary.html", title("描述统计")

# ishere display f"{s['价格'].n}"
# /**
# 样本量为 {ishere display f"{s['价格'].n}"}。
# **/

scatter("figures/price.svg", price, mpg, xlabel="油耗", ylabel="价格", fit=True)
# ishere fig using "figures/price.svg", title("价格与油耗")

m1 = regress(price, {"油耗": mpg})
etable("results/reg.html", [m1], note="因变量为价格。")
# ishere tab using "results/reg.html", title("回归")
```

`{ishere display ...}` 必须和前面那一行 `# ishere display ...` 字面一致。数字在运行时填进叙述。

`summarize` 写描述统计（N、均值、标准差、最小值、最大值），并返回同一套未四舍五入的数，供叙述引用。`scatter` 的参数顺序是 `y` 再 `x`，和 Stata 一样；`fit=True` 加上同一套 OLS 拟合线。`regress` 做带常数项的最小二乘。`etable` 把一个或多个结果写成三线表：系数、括号里的标准误、星号、N 和 R²。标记只把已经写好的文件收进报告。

## 三种报告

| 命令 | 留下 |
| --- | --- |
| （默认） | 代码、输出、叙述、图、表 |
| `--clean` | 标题、叙述、图、表 |
| `--cleancode` | 代码、叙述、图、表，不留命令输出 |

```bash
python -m python_tohtml run analysis.py --html report.html --clean
python -m python_tohtml build analysis.log --html report.html --embed
```

## 和 Stata 的对应

| Stata | Python |
| --- | --- |
| `ishere # 标题` | `# ishere # 标题` |
| `ishere ## 小节` | `# ishere ## 小节` |
| `/** ... **/` | `# /**` … `# **/` |
| `summarize` 再把表导出 | `summarize("a.html", {"价格": price})` |
| `scatter` / `graph export` | `scatter("a.svg", y, x)` |
| `regress` | `regress(y, {"油耗": x})` |
| `outreg2e ... html` | `etable("a.html", [m1, m2])` |
| `ishere fig using "a.png", title("图题")` | `# ishere fig using "a.svg", title("图题")` |
| `ishere tab using "a.html", title("表题")` | `# ishere tab using "a.html", title("表题")` |
| `ishere display %5.3f e(r2)` | `# ishere display f"{m1.rsquared:.3f}"` |
| `{ishere display %5.3f e(r2)}` | `{ishere display f"{m1.rsquared:.3f}"}` |

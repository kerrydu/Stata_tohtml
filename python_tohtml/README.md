# python_tohtml

脚本照常写。只在需要出现在报告里的地方加注释标记，和 Stata 的 `ishere` / `/** **/` 一样。

```bash
python -m python_tohtml run examples/auto_price.py --html examples/auto_price.html
```

不需要 `import python_tohtml`。直接用 `python examples/auto_price.py` 跑，标记只是注释，图和表仍会写到磁盘；报告要由上面的命令生成。

## 标记

```python
# ishere # 标题
# ishere ## 小节

print(f"N = {n}")
# ishere display f"{n}"
# /**
# 样本量为 {ishere display f"{n}"}。
# **/

df.to_html("results/summary.html")
# ishere tab using "results/summary.html", title("描述统计")

plt.savefig("figures/price.png")
# ishere fig using "figures/price.png", title("价格分布")
```

`{ishere display ...}` 必须和前面那一行 `# ishere display ...` 字面一致。数字在运行时填进叙述。

图和表仍由脚本自己导出。标记只负责把已经写好的文件收进报告。

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

| Stata | Python 注释 |
| --- | --- |
| `ishere # 标题` | `# ishere # 标题` |
| `ishere ## 小节` | `# ishere ## 小节` |
| `/** ... **/` | `# /**` … `# **/` |
| `ishere fig using "a.png", title("图题")` | `# ishere fig using "a.png", title("图题")` |
| `ishere tab using "a.html", title("表题")` | `# ishere tab using "a.html", title("表题")` |
| `ishere display %5.3f e(r2)` | `# ishere display f"{r2:.3f}"` |
| `{ishere display %5.3f e(r2)}` | `{ishere display f"{r2:.3f}"}` |

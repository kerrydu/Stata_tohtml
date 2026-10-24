# 一份脚本就是分析本身。运行：
#   python -m python_tohtml run examples/auto_price.py --html examples/auto_price.html

import math
import os
import random
from pathlib import Path

from python_tohtml.ishere import fig, h1, h2, md, show, tab
from python_tohtml.tables import etable, summ

os.chdir(Path(__file__).resolve().parent)

h1("汽车价格")
md("""
下面用一份合成数据走完应用计量里常见的几步：筛样本、描述统计、散点图，以及两列回归。正文里的数字都在运行时填入。
""")

h2("样本")
rng = random.Random(1)
raw = []
for i in range(48):
    mpg = rng.uniform(12, 40)
    weight = rng.uniform(1800, 4500)
    noise = rng.gauss(0, 400)
    price = None if i % 17 == 0 else 8000 - 180 * mpg + 1.8 * weight + noise
    raw.append((price, mpg, weight))
print(f"原始观测 N = {len(raw)}")
sample = [row for row in raw if row[0] is not None]
print(f"去掉价格缺失后 N = {len(sample)}")
show("n", str(len(sample)))
md("去掉价格缺失后剩余 {n} 个观测。价格由油耗、车重和一个扰动项生成。")

price = [row[0] for row in sample]
mpg = [row[1] for row in sample]
weight = [row[2] for row in sample]

h2("描述统计")
summ("results/summary.html", {"价格": price, "每加仑英里数": mpg, "车重": weight})
tab("results/summary.html", title="描述统计")

h2("价格与油耗")


def scatter_svg(path, xs, ys, xlabel, ylabel):
    width, height = 640, 420
    pad_l, pad_r, pad_t, pad_b = 64, 24, 24, 48
    xmin, xmax = min(xs), max(xs)
    ymin, ymax = min(ys), max(ys)

    def sx(x):
        return pad_l + (x - xmin) / (xmax - xmin) * (width - pad_l - pad_r)

    def sy(y):
        return pad_t + (ymax - y) / (ymax - ymin) * (height - pad_t - pad_b)

    dots = "".join(
        f'<circle cx="{sx(x):.1f}" cy="{sy(y):.1f}" r="3.5" fill="#1a7f37" fill-opacity="0.85"/>'
        for x, y in zip(xs, ys)
    )
    y_mid = (pad_t + sy(ymin)) / 2
    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">
<rect width="100%" height="100%" fill="#ffffff"/>
<line x1="{pad_l}" y1="{sy(ymin):.1f}" x2="{width - pad_r}" y2="{sy(ymin):.1f}" stroke="#24292f"/>
<line x1="{pad_l}" y1="{pad_t}" x2="{pad_l}" y2="{sy(ymin):.1f}" stroke="#24292f"/>
{dots}
<text x="{(pad_l + width - pad_r) / 2:.0f}" y="{height - 14}" text-anchor="middle" font-family="sans-serif" font-size="14">{xlabel}</text>
<text x="16" y="{y_mid:.0f}" text-anchor="middle" font-family="sans-serif" font-size="14" transform="rotate(-90 16 {y_mid:.0f})">{ylabel}</text>
</svg>
"""
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_text(svg, encoding="utf-8")


scatter_svg("figures/price.svg", mpg, price, "每加仑英里数", "价格")
fig("figures/price.svg", title="价格与每加仑英里数")

h2("回归")
md(r"""
两个设定都用普通最小二乘。标准误是独立同分布下的普通标准误，p 值用正态近似。价格对油耗和车重的线性投影写成

$$
price = \beta_0 + \beta_1 mpg + \beta_2 weight + \varepsilon
$$
""")


def ols(y, columns):
    n = len(y)
    k = len(columns)
    xtx = [[0.0] * k for _ in range(k)]
    xty = [0.0] * k
    for i in range(n):
        row = [columns[j][1][i] for j in range(k)]
        for a in range(k):
            xty[a] += row[a] * y[i]
            for b in range(k):
                xtx[a][b] += row[a] * row[b]
    beta = _solve(xtx, xty)
    sse = 0.0
    mean = sum(y) / n
    sst = 0.0
    for i in range(n):
        fitted = sum(columns[j][1][i] * beta[j] for j in range(k))
        sse += (y[i] - fitted) ** 2
        sst += (y[i] - mean) ** 2
    sigma2 = sse / (n - k)
    inv = _invert(xtx)
    se = [math.sqrt(sigma2 * inv[j][j]) for j in range(k)]
    pvalues = [2 * _norm_sf(abs(beta[j] / se[j])) for j in range(k)]
    return {
        "coef": {columns[j][0]: beta[j] for j in range(k)},
        "se": {columns[j][0]: se[j] for j in range(k)},
        "p": {columns[j][0]: pvalues[j] for j in range(k)},
        "stats": {"N": n, "R²": 0.0 if sst == 0 else 1 - sse / sst},
    }


def _solve(matrix, target):
    size = len(target)
    rows = [matrix[i][:] + [target[i]] for i in range(size)]
    for col in range(size):
        pivot = max(range(col, size), key=lambda r: abs(rows[r][col]))
        if abs(rows[pivot][col]) < 1e-12:
            raise ZeroDivisionError("设计矩阵奇异")
        rows[col], rows[pivot] = rows[pivot], rows[col]
        scale = rows[col][col]
        for j in range(col, size + 1):
            rows[col][j] /= scale
        for r in range(size):
            if r == col:
                continue
            factor = rows[r][col]
            for j in range(col, size + 1):
                rows[r][j] -= factor * rows[col][j]
    return [rows[i][size] for i in range(size)]


def _invert(matrix):
    size = len(matrix)
    return [_solve(matrix, [1.0 if i == col else 0.0 for i in range(size)]) for col in range(size)]


def _norm_sf(z):
    return 0.5 * math.erfc(z / math.sqrt(2))


const = [1.0] * len(price)
model_mpg = ols(price, [("常数", const), ("每加仑英里数", mpg)])
model_both = ols(price, [("常数", const), ("每加仑英里数", mpg), ("车重", weight)])
etable(
    "results/regression.html",
    [model_mpg, model_both],
    titles=["(1)", "(2)"],
    note="因变量为价格。列 (2) 同时控制车重。",
)
tab("results/regression.html", title="价格回归")

b_mpg = model_both["coef"]["每加仑英里数"]
se_mpg = model_both["se"]["每加仑英里数"]
show("b_mpg", f"{b_mpg:.2f}")
show("se_mpg", f"{se_mpg:.2f}")
md(
    f"在控制车重之后，每加仑英里数的系数为 {b_mpg:.2f}（标准误 {se_mpg:.2f}）。"
    "油耗越高，价格越低，这和生成数据时用的负号一致。"
)
md("同一系数也可以写成 {b_mpg}，标准误 {se_mpg}。两次出现的都是这一次运行的结果。")

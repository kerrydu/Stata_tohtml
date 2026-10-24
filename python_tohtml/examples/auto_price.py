import random

from python_tohtml import etable, regress, scatter, summarize

# ishere # 价格与油耗
# /**
# 这份报告汇总汽车价格和油耗。
# **/

rng = random.Random(1)
mpg = [rng.uniform(15, 40) for _ in range(24)]
weight = [rng.uniform(1800, 4000) for _ in range(24)]
price = [8000 - 180 * x + 1.5 * w + rng.gauss(0, 400) for x, w in zip(mpg, weight)]

# ishere ## 描述统计
s = summarize("results/summary.html", {"价格": price, "每加仑英里数": mpg, "车重": weight})
# ishere tab using "results/summary.html", title("描述统计")
# ishere display f"{s['价格'].n}"
# ishere display f"{s['价格'].mean:.0f}"
# /**
# 共 {ishere display f"{s['价格'].n}"} 个观测，价格均值约为 {ishere display f"{s['价格'].mean:.0f}"}。
# **/

# ishere ## 价格与油耗
scatter("figures/price.svg", price, mpg, xlabel="每加仑英里数", ylabel="价格", fit=True)
# ishere fig using "figures/price.svg", title("价格与每加仑英里数")

# ishere ## 回归
m1 = regress(price, {"每加仑英里数": mpg})
m2 = regress(price, {"每加仑英里数": mpg, "车重": weight})
etable("results/regression.html", [m1, m2], titles=["(1)", "(2)"], note="因变量为价格。")
# ishere tab using "results/regression.html", title("价格回归")
# ishere display f"{m1.params['每加仑英里数']:.1f}"
# /**
# 只控制油耗时，每加仑英里数的系数为 {ishere display f"{m1.params['每加仑英里数']:.1f}"}。
#
# $$
# price = \beta_0 + \beta_1 mpg + \varepsilon
# $$
# **/

```python
import random

from python_tohtml import etable, regress, scatter, summarize
```

# 价格与油耗

这份报告汇总汽车价格和油耗。

```python
rng = random.Random(1)
mpg = [rng.uniform(15, 40) for _ in range(24)]
weight = [rng.uniform(1800, 4000) for _ in range(24)]
price = [8000 - 180 * x + 1.5 * w + rng.gauss(0, 400) for x, w in zip(mpg, weight)]
```

## 描述统计

```python
s = summarize("results/summary.html", {"价格": price, "每加仑英里数": mpg, "车重": weight})
```

<figure class="tohtml-table-block"><figcaption class="tohtml-table-title">描述统计</figcaption><div class="tohtml-embedded-table"><table class="pytohtml-table"><thead><tr><th>变量</th><th class="num">N</th><th class="num">均值</th><th class="num">标准差</th><th class="num">最小值</th><th class="num">最大值</th></tr></thead><tbody><tr><td>价格</td><td class="num">24</td><td class="num">7193.805</td><td class="num">1888.094</td><td class="num">3649.034</td><td class="num">10273.563</td></tr><tr><td>每加仑英里数</td><td class="num">24</td><td class="num">27.189</td><td class="num">8.159</td><td class="num">15.053</td><td class="num">38.632</td></tr><tr><td>车重</td><td class="num">24</td><td class="num">2771.326</td><td class="num">628.161</td><td class="num">1847.277</td><td class="num">3983.596</td></tr></tbody></table></div></figure>

共 24 个观测，价格均值约为 7194。

## 价格与油耗

```python
scatter("figures/price.svg", price, mpg, xlabel="每加仑英里数", ylabel="价格", fit=True)
```

<figure class="tohtml-figure"><img src="figures/price.svg" style="zoom:100%"><figcaption class="tohtml-fig-title">价格与每加仑英里数</figcaption></figure>

## 回归

```python
m1 = regress(price, {"每加仑英里数": mpg})
m2 = regress(price, {"每加仑英里数": mpg, "车重": weight})
etable("results/regression.html", [m1, m2], titles=["(1)", "(2)"], note="因变量为价格。")
```

<figure class="tohtml-table-block"><figcaption class="tohtml-table-title">价格回归</figcaption><div class="tohtml-embedded-table"><table class="pytohtml-table"><thead><tr><th></th><th class="num">(1)</th><th class="num">(2)</th></tr></thead><tbody><tr><td>每加仑英里数</td><td class="num">-191.925***</td><td class="num">-193.113***</td></tr><tr><td></td><td class="num">(27.565)</td><td class="num">(9.318)</td></tr><tr><td>车重</td><td class="num"></td><td class="num">1.585***</td></tr><tr><td></td><td class="num"></td><td class="num">(0.121)</td></tr><tr><td>常数项</td><td class="num">12411.992***</td><td class="num">8051.237***</td></tr><tr><td></td><td class="num">(781.122)</td><td class="num">(424.921)</td></tr><tr class="stat stat-start"><td>N</td><td class="num">24</td><td class="num">24</td></tr><tr class="stat"><td>R²</td><td class="num">0.688</td><td class="num">0.966</td></tr></tbody></table></div><p class="pytohtml-note">* p&lt;0.1，** p&lt;0.05，*** p&lt;0.01</p>
<p class="pytohtml-note">因变量为价格。</p></figure>

只控制油耗时，每加仑英里数的系数为 -191.9。

$$
price = \beta_0 + \beta_1 mpg + \varepsilon
$$

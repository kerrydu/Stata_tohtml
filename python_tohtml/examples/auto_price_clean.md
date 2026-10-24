# 汽车价格

下面用一份合成数据走完应用计量里常见的几步：筛样本、描述统计、散点图，以及两列回归。正文里的数字都在运行时填入。

## 样本

去掉价格缺失后剩余 45 个观测。价格由油耗、车重和一个扰动项生成。

## 描述统计

<figure class="tohtml-table-block"><figcaption class="tohtml-table-title">描述统计</figcaption><div class="tohtml-embedded-table"><table class="pytohtml-table"><thead><tr><th>变量</th><th class="num">N</th><th class="num">均值</th><th class="num">标准差</th><th class="num">最小值</th><th class="num">最大值</th></tr></thead><tbody><tr><td>价格</td><td class="num">45</td><td class="num">8751.398</td><td class="num">2112.379</td><td class="num">4439.482</td><td class="num">12866.873</td></tr><tr><td>每加仑英里数</td><td class="num">45</td><td class="num">26.145</td><td class="num">8.351</td><td class="num">12.467</td><td class="num">39.791</td></tr><tr><td>车重</td><td class="num">45</td><td class="num">3059.024</td><td class="num">768.508</td><td class="num">1805.686</td><td class="num">4451.607</td></tr></tbody></table></div></figure>

## 价格与油耗

<figure class="tohtml-figure"><img src="figures/price.svg" style="zoom:100%"><figcaption class="tohtml-fig-title">价格与每加仑英里数</figcaption></figure>

## 回归

两个设定都用普通最小二乘。标准误是独立同分布下的普通标准误，p 值用正态近似。价格对油耗和车重的线性投影写成

$$
price = \beta_0 + \beta_1 mpg + \beta_2 weight + \varepsilon
$$

<figure class="tohtml-table-block"><figcaption class="tohtml-table-title">价格回归</figcaption><div class="tohtml-embedded-table"><table class="pytohtml-table"><thead><tr><th></th><th class="num">(1)</th><th class="num">(2)</th></tr></thead><tbody><tr><td>常数</td><td class="num">13825.143***</td><td class="num">8491.288***</td></tr><tr><td></td><td class="num">(678.368)</td><td class="num">(250.391)</td></tr><tr><td>每加仑英里数</td><td class="num">-194.063***</td><td class="num">-190.847***</td></tr><tr><td></td><td class="num">(24.742)</td><td class="num">(5.756)</td></tr><tr><td>车重</td><td class="num"></td><td class="num">1.716***</td></tr><tr><td></td><td class="num"></td><td class="num">(0.063)</td></tr><tr class="stat stat-start"><td>N</td><td class="num">45</td><td class="num">45</td></tr><tr class="stat"><td>R²</td><td class="num">0.589</td><td class="num">0.978</td></tr></tbody></table></div><p class="pytohtml-note">* p&lt;0.1，** p&lt;0.05，*** p&lt;0.01</p>
<p class="pytohtml-note">因变量为价格。列 (2) 同时控制车重。</p></figure>

在控制车重之后，每加仑英里数的系数为 -190.85（标准误 5.76）。油耗越高，价格越低，这和生成数据时用的负号一致。

同一系数也可以写成 -190.85，标准误 5.76。两次出现的都是这一次运行的结果。

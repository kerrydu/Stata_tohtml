% ishere # 价格与油耗
%{
这份报告汇总汽车价格和油耗。
%}

rng(1);
mpg = 15 + 25 * rand(24, 1);
weight = 1800 + 2200 * rand(24, 1);
price = 8000 - 180 * mpg + 1.5 * weight + 400 * randn(24, 1);

% ishere ## 描述统计
s = matlab_tohtml.summarize('results/summary.html', {'价格', price, '每加仑英里数', mpg, '车重', weight});
% ishere tab using "results/summary.html", title("描述统计")
sprintf('共 %d 个观测，价格均值约为 %.0f。', s.('价格').n, s.('价格').mean)

% ishere ## 价格与油耗
matlab_tohtml.scatter('figures/price.svg', price, mpg, 'xlabel', '每加仑英里数', 'ylabel', '价格', 'fit', true);
% ishere fig using "figures/price.svg", title("价格与每加仑英里数")

% ishere ## 回归
m1 = matlab_tohtml.regress(price, {'每加仑英里数', mpg});
m2 = matlab_tohtml.regress(price, {'每加仑英里数', mpg, '车重', weight});
matlab_tohtml.etable('results/regression.html', {m1, m2}, 'titles', {'(1)', '(2)'}, 'note', '因变量为价格。');
% ishere tab using "results/regression.html", title("价格回归")
% ishere display sprintf('%.1f', m1.params.('每加仑英里数'))
%{
只控制油耗时，每加仑英里数的系数为 {ishere display sprintf('%.1f', m1.params.('每加仑英里数'))}。

$$
price = \beta_0 + \beta_1 mpg + \varepsilon
$$
%}

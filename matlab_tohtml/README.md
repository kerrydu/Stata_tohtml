# matlab_tohtml

脚本照常写。叙述用块注释，或者一行会得到字符串的表达式。标题、图、表用注释标记。表和图不在脚本里拼 HTML：先调用命令把文件写出来，再用标记收进报告。

在 MATLAB 或 Octave 里把本目录加进路径：

```matlab
addpath('matlab_tohtml')
matlab_tohtml.run('examples/auto_price.m', 'html', 'examples/auto_price.html')
```

也可以：

```matlab
mltohtml('run', 'examples/auto_price.m')
```

直接执行脚本也会把表和图写到磁盘；HTML 报告由上面的命令生成。

## 标记和导出

```matlab
% ishere # 标题
% ishere ## 小节

s = matlab_tohtml.summarize('results/summary.html', {'价格', price, '油耗', mpg});
% ishere tab using "results/summary.html", title("描述统计")

sprintf('样本量为 %d。', s.('价格').n)

matlab_tohtml.scatter('figures/price.svg', price, mpg, 'xlabel', '油耗', 'ylabel', '价格', 'fit', true);
% ishere fig using "figures/price.svg", title("价格与油耗")

m = matlab_tohtml.regress(price, {'油耗', mpg});
matlab_tohtml.etable('results/reg.html', {m}, 'note', '因变量为价格。');
% ishere tab using "results/reg.html", title("回归")
```

`sprintf(...)`、`string(...)`、`strcat(...)`，以及单独一行的字符向量，结果进入报告，不进入代码块。块注释 `%{ ... %}` 和 Stata 写法 `% /** ... % **/` 是不执行的叙述。公式可以直接写在块注释里。数字若先算好再引用，用：

```matlab
% ishere display sprintf('%.3f', m.rsquared)
%{
R² 为 {ishere display sprintf('%.3f', m.rsquared)}。
%}
```

`summarize` 写描述统计（N、均值、标准差、最小值、最大值），并返回同一套未四舍五入的数。`scatter` 的参数顺序是 y 再 x；`fit` 为 true 时加上同一套 OLS 拟合线。`regress` 做带常数项的最小二乘。`etable` 把一个或多个结果写成三线表：系数、括号里的标准误、星号、N 和 R²。变量名用元胞成对写出，这样中文名称不用做成合法的字段名：`{'价格', price}`。返回值用 `s.('价格').mean` 来取。

## 三种报告

| 选项 | 留下 |
| --- | --- |
| （默认） | 代码、输出、叙述、图、表 |
| `'clean', true` | 标题、叙述、图、表 |
| `'cleancode', true` | 代码、叙述、图、表，不留命令输出 |

```matlab
matlab_tohtml.run('analysis.m', 'html', 'report.html', 'clean', true)
matlab_tohtml.build('analysis.log', 'html', 'report.html', 'embed', true)
```

没有分号的命令，屏幕上会显示的内容进入「输出」。叙述表达式本身不进入输出。

## 从目录收集

和 `tohtml "results" "figures"` 一样。只看目录本身，不进入子目录。表必须叫 `table*.html` 或 `table*.md`，图必须叫 `figure*.png`、`jpg`、`jpeg`、`svg`、`gif`、`bmp`、`webp`。按文件名排序后合成一份报告。

```matlab
matlab_tohtml.gather({'results', 'figures'}, 'html', 'report.html', 'zoom', '80%')
```

`width`、`height`、`zoom` 只改这次收集进来的图。

## 和 Stata、Python 的对应

| Stata | Python | MATLAB |
| --- | --- | --- |
| `ishere # 标题` | `# ishere # 标题` | `% ishere # 标题` |
| `/** ... **/` | `f""" ... """` | `%{ ... %}`，或 `sprintf(...)` |
| `summarize` 再把表导出 | `summarize("a.html", {"价格": price})` | `summarize('a.html', {'价格', price})` |
| `scatter` / `graph export` | `scatter("a.svg", y, x)` | `scatter('a.svg', y, x)` |
| `regress` | `regress(y, {"油耗": x})` | `regress(y, {'油耗', x})` |
| `outreg2e ... html` | `etable("a.html", [m1, m2])` | `etable('a.html', {m1, m2})` |
| `ishere fig using "a.png"` | `# ishere fig using "a.svg"` | `% ishere fig using "a.svg"` |
| `ishere tab using "a.html"` | `# ishere tab using "a.html"` | `% ishere tab using "a.html"` |
| `tohtml "results" "figures"` | `python -m python_tohtml gather results figures` | `gather({'results', 'figures'})` |

脚本末尾的局部函数不会被执行。分析脚本若要调用自己的函数，把函数放在单独的 `.m` 文件里。



```text
------------------------------------------------------------------------------------------------------------------------
      name:  <unnamed>
       log:  D:/code_test/results/logs/example_standard.log
  log type:  text
 opened on:  31 Aug 2026, 11:29:53
```






# Data Preparation


```stata

. sysuse auto, clear
(1978 automobile data)

. disp "Loaded auto.dta. Observations: `c(N)', Variables: `c(k)'"
Loaded auto.dta. Observations: 74, Variables: 12

. drop if missing(price, mpg, weight, foreign)
(0 observations deleted)

. disp "Dropped missing. Remaining observations: `c(N)'"
Dropped missing. Remaining observations: 74

. // Generate analysis variables
. gen lprice   = ln(price)

. gen weightkg = weight*0.453592

. label var lprice   "Log of price"

. label var weightkg "Weight (kg)"

. disp "Variables created: lprice, weightkg"
Variables created: lprice, weightkg

```


# Descriptive Statistics




## Table 1


```stata

. summarize price mpg weight lprice

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
       price |         74    6165.257    2949.496       3291      15906
         mpg |         74     21.2973    5.785503         12         41
      weight |         74    3019.459    777.1936       1760       4840
      lprice |         74    8.640633    .3921059   8.098947   9.674452

. table (var) (result), ///
>       statistic(mean price mpg weight) ///
>       statistic(sd   price mpg weight) ///
>       nototals ///
>       export("$results/summary.html", replace)

----------------------------------------------
              |      Mean   Standard deviation
--------------+-------------------------------
Price         |  6165.257             2949.496
Mileage (mpg) |   21.2973             5.785503
Weight (lbs.) |  3019.459             777.1936
----------------------------------------------
(collection Table exported to file D:/code_test/results/summary.html)

. ishere tab using "$results/summary.html",title("Descriptive analysis")

```



<figure class="tohtml-table-block">
<figcaption class="tohtml-table-title">Descriptive analysis</figcaption>
<div class="tohtml-embedded-table">
<table class="Table1">
  <tr class="Table1_1_x">
    <td class="Table1_x_1 Table1_1_1">
      <span class="Table1_1_1_span">
      &nbsp;
      </span>
    </td>
    <td class="Table1_x_2 Table1_1_2">
      <span class="Table1_1_2_span">
      Mean
      </span>
    </td>
    <td class="Table1_x_3 Table1_1_3">
      <span class="Table1_1_3_span">
      Standard deviation
      </span>
    </td>
  </tr>
  <tr class="Table1_2_x">
    <td class="Table1_x_1 Table1_2_1">
      <span class="Table1_2_1_span">
      Price
      </span>
    </td>
    <td class="Table1_x_2 Table1_2_2">
      <span class="Table1_2_2_span">
      6165.257
      </span>
    </td>
    <td class="Table1_x_3 Table1_2_3">
      <span class="Table1_2_3_span">
      2949.496
      </span>
    </td>
  </tr>
  <tr class="Table1_3_x">
    <td class="Table1_x_1 Table1_3_1">
      <span class="Table1_3_1_span">
      Mileage (mpg)
      </span>
    </td>
    <td class="Table1_x_2 Table1_3_2">
      <span class="Table1_3_2_span">
      21.2973
      </span>
    </td>
    <td class="Table1_x_3 Table1_3_3">
      <span class="Table1_3_3_span">
      5.785503
      </span>
    </td>
  </tr>
  <tr class="Table1_4_x">
    <td class="Table1_x_1 Table1_4_1">
      <span class="Table1_4_1_span">
      Weight (lbs.)
      </span>
    </td>
    <td class="Table1_x_2 Table1_4_2">
      <span class="Table1_4_2_span">
      3019.459
      </span>
    </td>
    <td class="Table1_x_3 Table1_4_3">
      <span class="Table1_4_3_span">
      777.1936
      </span>
    </td>
  </tr>
</table>
</div>
</figure>





# Figures




## Figure 1


```stata

. histogram price, normal
(bin=8, start=3291, width=1576.875)

. graph export "$figures/price_hist.png", replace
file D:/code_test/results/figures/price_hist.png saved as PNG format

. ishere fig using "$figures/price_hist.png", title("Price distribution")

```


<figure class="tohtml-figure">

![](D:/code_test/results/figures/price_hist.png)

<figcaption class="tohtml-fig-title">Price distribution</figcaption>
</figure>




## Figure 2


```stata

. twoway (scatter price mpg) (lfit price mpg), legend(order(1 "Actual" 2 "Fitted"))

. graph export "$figures/price_mpg.png", replace
file D:/code_test/results/figures/price_mpg.png saved as PNG format

. ishere fig using "$figures/price_mpg.png", title("Price vs MPG with linear fit")

```


<figure class="tohtml-figure">

![](D:/code_test/results/figures/price_mpg.png)

<figcaption class="tohtml-fig-title">Price vs MPG with linear fit</figcaption>
</figure>





this is a paragraph of text

this is another paragraph of text

this is a third paragraph of text

this is a mathematical expression

$$y = \beta_0 + \beta_1 x_1 + \beta_2 x_2 + \epsilon$$






# Regression




## Narrative Example


```stata

. regress price mpg weight

      Source |       SS           df       MS      Number of obs   =        74
-------------+----------------------------------   F(2, 71)        =     14.74
       Model |   186321280         2  93160639.9   Prob > F        =    0.0000
    Residual |   448744116        71  6320339.67   R-squared       =    0.2934
-------------+----------------------------------   Adj R-squared   =    0.2735
       Total |   635065396        73  8699525.97   Root MSE        =      2514

------------------------------------------------------------------------------
       price | Coefficient  Std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
         mpg |  -49.51222   86.15604    -0.57   0.567    -221.3025     122.278
      weight |   1.746559   .6413538     2.72   0.008      .467736    3.025382
       _cons |   1946.069    3597.05     0.54   0.590    -5226.245    9118.382
------------------------------------------------------------------------------

. ishere display %5.3f e(r2)
0.293

```



The R-squared is  0.293 .



```stata
. qui regress price mpg weight i.foreign, vce(robust)

. estimates store model1

. qui regress price mpg , vce(robust)

. estimates store model2

. qui regress price i.foreign, vce(robust)

. estimates store model3

. qui regress price mpg weight i.foreign, vce(robust)

. estimates store model4

. qui regress price mpg weight i.foreign, vce(robust)

. estimates store model5

. qui regress price mpg weight i.foreign, vce(robust)

. estimates store model6

. qui regress price mpg weight i.foreign, vce(robust)

. estimates store model7

. qui regress price mpg weight i.foreign, vce(robust)

. estimates store model8

. qui regress price mpg weight i.foreign, vce(robust)

. estimates store model9

. qui regress price mpg weight i.foreign, vce(robust)

. estimates store model10

. qui regress price mpg weight i.foreign, vce(robust)

. estimates store model11

. qui regress price mpg weight i.foreign, vce(robust)

. estimates store model12

. qui regress price mpg weight i.foreign, vce(robust)

. estimates store model13

```


## Table 2


```stata

. outreg2e [model1 model2 model3 model4 model5] using "$results/model.html", replace html
D:/code_test/results/model.html
dir : seeout

. ishere tab using "$results/model.html",title("Regression results")

```



<figure class="tohtml-table-block">
<figcaption class="tohtml-table-title">Regression results</figcaption>
<div class="tohtml-embedded-table">
<div class='texout-table-wrap'>
<table class='texout-table'>
<thead>
<tr>
<th>&nbsp;</th>
<th>(1)</th>
<th>(2)</th>
<th>(3)</th>
<th>(4)</th>
<th>(5)</th>
</tr>
<tr>
<th>&nbsp;</th>
<th>model1</th>
<th>model2</th>
<th>model3</th>
<th>model4</th>
<th>model5</th>
</tr>
<tr class='texout-headline'>
<th>VARIABLES</th>
<th>price</th>
<th>price</th>
<th>price</th>
<th>price</th>
<th>price</th>
</tr>
</thead>
<tbody>
<tr>
<td>mpg</td>
<td class='texout-mono'>21.85</td>
<td class='texout-mono'>-238.9***</td>
<td class='texout-mono'>&nbsp;</td>
<td class='texout-mono'>21.85</td>
<td class='texout-mono'>21.85</td>
</tr>
<tr>
<td>&nbsp;</td>
<td class='texout-mono'>(80.75)</td>
<td class='texout-mono'>(57.48)</td>
<td class='texout-mono'>&nbsp;</td>
<td class='texout-mono'>(80.75)</td>
<td class='texout-mono'>(80.75)</td>
</tr>
<tr>
<td>weight</td>
<td class='texout-mono'>3.465***</td>
<td class='texout-mono'>&nbsp;</td>
<td class='texout-mono'>&nbsp;</td>
<td class='texout-mono'>3.465***</td>
<td class='texout-mono'>3.465***</td>
</tr>
<tr>
<td>&nbsp;</td>
<td class='texout-mono'>(0.778)</td>
<td class='texout-mono'>&nbsp;</td>
<td class='texout-mono'>&nbsp;</td>
<td class='texout-mono'>(0.778)</td>
<td class='texout-mono'>(0.778)</td>
</tr>
<tr>
<td>1.foreign</td>
<td class='texout-mono'>3,673***</td>
<td class='texout-mono'>&nbsp;</td>
<td class='texout-mono'>312.3</td>
<td class='texout-mono'>3,673***</td>
<td class='texout-mono'>3,673***</td>
</tr>
<tr>
<td>&nbsp;</td>
<td class='texout-mono'>(664.9)</td>
<td class='texout-mono'>&nbsp;</td>
<td class='texout-mono'>(701.8)</td>
<td class='texout-mono'>(664.9)</td>
<td class='texout-mono'>(664.9)</td>
</tr>
<tr>
<td>Constant</td>
<td class='texout-mono'>-5,854</td>
<td class='texout-mono'>11,253***</td>
<td class='texout-mono'>6,072***</td>
<td class='texout-mono'>-5,854</td>
<td class='texout-mono'>-5,854</td>
</tr>
<tr>
<td>&nbsp;</td>
<td class='texout-mono'>(3,874)</td>
<td class='texout-mono'>(1,376)</td>
<td class='texout-mono'>(431.2)</td>
<td class='texout-mono'>(3,874)</td>
<td class='texout-mono'>(3,874)</td>
</tr>
<tr>
<td>Observations</td>
<td class='texout-mono'>74</td>
<td class='texout-mono'>74</td>
<td class='texout-mono'>74</td>
<td class='texout-mono'>74</td>
<td class='texout-mono'>74</td>
</tr>
<tr class='texout-bottomline'>
<td>R-squared</td>
<td class='texout-mono'>0.500</td>
<td class='texout-mono'>0.220</td>
<td class='texout-mono'>0.002</td>
<td class='texout-mono'>0.500</td>
<td class='texout-mono'>0.500</td>
</tr>
<tr class='texout-notes'><td colspan='6'>Robust standard errors in parentheses</td></tr>
<tr class='texout-notes'><td colspan='6'>*** p&lt;0.01, ** p&lt;0.05, * p&lt;0.1</td></tr>
</tbody>
</table>
</div>
</div>
</figure>





## Table 3


```stata

. outreg2e [model*] using "$results/model2.html", replace html
D:/code_test/results/model2.html
dir : seeout

. ishere tab using "$results/model2.html",title("Regression analysis")

```



<figure class="tohtml-table-block">
<figcaption class="tohtml-table-title">Regression analysis</figcaption>
<div class="tohtml-embedded-table">
<div class='texout-table-wrap'>
<table class='texout-table'>
<thead>
<tr>
<th>&nbsp;</th>
<th>(1)</th>
<th>(2)</th>
<th>(3)</th>
<th>(4)</th>
<th>(5)</th>
<th>(6)</th>
<th>(7)</th>
<th>(8)</th>
<th>(9)</th>
<th>(10)</th>
<th>(11)</th>
<th>(12)</th>
<th>(13)</th>
</tr>
<tr>
<th>&nbsp;</th>
<th>model2</th>
<th>model3</th>
<th>model4</th>
<th>model5</th>
<th>model6</th>
<th>model7</th>
<th>model8</th>
<th>model9</th>
<th>model10</th>
<th>model11</th>
<th>model12</th>
<th>model13</th>
<th>model1</th>
</tr>
<tr class='texout-headline'>
<th>VARIABLES</th>
<th>price</th>
<th>price</th>
<th>price</th>
<th>price</th>
<th>price</th>
<th>price</th>
<th>price</th>
<th>price</th>
<th>price</th>
<th>price</th>
<th>price</th>
<th>price</th>
<th>price</th>
</tr>
</thead>
<tbody>
<tr>
<td>mpg</td>
<td class='texout-mono'>-238.9***</td>
<td class='texout-mono'>&nbsp;</td>
<td class='texout-mono'>21.85</td>
<td class='texout-mono'>21.85</td>
<td class='texout-mono'>21.85</td>
<td class='texout-mono'>21.85</td>
<td class='texout-mono'>21.85</td>
<td class='texout-mono'>21.85</td>
<td class='texout-mono'>21.85</td>
<td class='texout-mono'>21.85</td>
<td class='texout-mono'>21.85</td>
<td class='texout-mono'>21.85</td>
<td class='texout-mono'>21.85</td>
</tr>
<tr>
<td>&nbsp;</td>
<td class='texout-mono'>(57.48)</td>
<td class='texout-mono'>&nbsp;</td>
<td class='texout-mono'>(80.75)</td>
<td class='texout-mono'>(80.75)</td>
<td class='texout-mono'>(80.75)</td>
<td class='texout-mono'>(80.75)</td>
<td class='texout-mono'>(80.75)</td>
<td class='texout-mono'>(80.75)</td>
<td class='texout-mono'>(80.75)</td>
<td class='texout-mono'>(80.75)</td>
<td class='texout-mono'>(80.75)</td>
<td class='texout-mono'>(80.75)</td>
<td class='texout-mono'>(80.75)</td>
</tr>
<tr>
<td>weight</td>
<td class='texout-mono'>&nbsp;</td>
<td class='texout-mono'>&nbsp;</td>
<td class='texout-mono'>3.465***</td>
<td class='texout-mono'>3.465***</td>
<td class='texout-mono'>3.465***</td>
<td class='texout-mono'>3.465***</td>
<td class='texout-mono'>3.465***</td>
<td class='texout-mono'>3.465***</td>
<td class='texout-mono'>3.465***</td>
<td class='texout-mono'>3.465***</td>
<td class='texout-mono'>3.465***</td>
<td class='texout-mono'>3.465***</td>
<td class='texout-mono'>3.465***</td>
</tr>
<tr>
<td>&nbsp;</td>
<td class='texout-mono'>&nbsp;</td>
<td class='texout-mono'>&nbsp;</td>
<td class='texout-mono'>(0.778)</td>
<td class='texout-mono'>(0.778)</td>
<td class='texout-mono'>(0.778)</td>
<td class='texout-mono'>(0.778)</td>
<td class='texout-mono'>(0.778)</td>
<td class='texout-mono'>(0.778)</td>
<td class='texout-mono'>(0.778)</td>
<td class='texout-mono'>(0.778)</td>
<td class='texout-mono'>(0.778)</td>
<td class='texout-mono'>(0.778)</td>
<td class='texout-mono'>(0.778)</td>
</tr>
<tr>
<td>1.foreign</td>
<td class='texout-mono'>&nbsp;</td>
<td class='texout-mono'>312.3</td>
<td class='texout-mono'>3,673***</td>
<td class='texout-mono'>3,673***</td>
<td class='texout-mono'>3,673***</td>
<td class='texout-mono'>3,673***</td>
<td class='texout-mono'>3,673***</td>
<td class='texout-mono'>3,673***</td>
<td class='texout-mono'>3,673***</td>
<td class='texout-mono'>3,673***</td>
<td class='texout-mono'>3,673***</td>
<td class='texout-mono'>3,673***</td>
<td class='texout-mono'>3,673***</td>
</tr>
<tr>
<td>&nbsp;</td>
<td class='texout-mono'>&nbsp;</td>
<td class='texout-mono'>(701.8)</td>
<td class='texout-mono'>(664.9)</td>
<td class='texout-mono'>(664.9)</td>
<td class='texout-mono'>(664.9)</td>
<td class='texout-mono'>(664.9)</td>
<td class='texout-mono'>(664.9)</td>
<td class='texout-mono'>(664.9)</td>
<td class='texout-mono'>(664.9)</td>
<td class='texout-mono'>(664.9)</td>
<td class='texout-mono'>(664.9)</td>
<td class='texout-mono'>(664.9)</td>
<td class='texout-mono'>(664.9)</td>
</tr>
<tr>
<td>Constant</td>
<td class='texout-mono'>11,253***</td>
<td class='texout-mono'>6,072***</td>
<td class='texout-mono'>-5,854</td>
<td class='texout-mono'>-5,854</td>
<td class='texout-mono'>-5,854</td>
<td class='texout-mono'>-5,854</td>
<td class='texout-mono'>-5,854</td>
<td class='texout-mono'>-5,854</td>
<td class='texout-mono'>-5,854</td>
<td class='texout-mono'>-5,854</td>
<td class='texout-mono'>-5,854</td>
<td class='texout-mono'>-5,854</td>
<td class='texout-mono'>-5,854</td>
</tr>
<tr>
<td>&nbsp;</td>
<td class='texout-mono'>(1,376)</td>
<td class='texout-mono'>(431.2)</td>
<td class='texout-mono'>(3,874)</td>
<td class='texout-mono'>(3,874)</td>
<td class='texout-mono'>(3,874)</td>
<td class='texout-mono'>(3,874)</td>
<td class='texout-mono'>(3,874)</td>
<td class='texout-mono'>(3,874)</td>
<td class='texout-mono'>(3,874)</td>
<td class='texout-mono'>(3,874)</td>
<td class='texout-mono'>(3,874)</td>
<td class='texout-mono'>(3,874)</td>
<td class='texout-mono'>(3,874)</td>
</tr>
<tr>
<td>Observations</td>
<td class='texout-mono'>74</td>
<td class='texout-mono'>74</td>
<td class='texout-mono'>74</td>
<td class='texout-mono'>74</td>
<td class='texout-mono'>74</td>
<td class='texout-mono'>74</td>
<td class='texout-mono'>74</td>
<td class='texout-mono'>74</td>
<td class='texout-mono'>74</td>
<td class='texout-mono'>74</td>
<td class='texout-mono'>74</td>
<td class='texout-mono'>74</td>
<td class='texout-mono'>74</td>
</tr>
<tr class='texout-bottomline'>
<td>R-squared</td>
<td class='texout-mono'>0.220</td>
<td class='texout-mono'>0.002</td>
<td class='texout-mono'>0.500</td>
<td class='texout-mono'>0.500</td>
<td class='texout-mono'>0.500</td>
<td class='texout-mono'>0.500</td>
<td class='texout-mono'>0.500</td>
<td class='texout-mono'>0.500</td>
<td class='texout-mono'>0.500</td>
<td class='texout-mono'>0.500</td>
<td class='texout-mono'>0.500</td>
<td class='texout-mono'>0.500</td>
<td class='texout-mono'>0.500</td>
</tr>
<tr class='texout-notes'><td colspan='14'>Robust standard errors in parentheses</td></tr>
<tr class='texout-notes'><td colspan='14'>*** p&lt;0.01, ** p&lt;0.05, * p&lt;0.1</td></tr>
</tbody>
</table>
</div>
</div>
</figure>






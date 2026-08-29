

```text
--------------------------------------------------------------------------------
      name:  <unnamed>
       log:  C:\Users\kerry\Desktop\tohtml\Stata_tohtml\example5.log
  log type:  text
 opened on:  29 Aug 2026, 17:25:40
```






# Output Variant Comparison


```stata

. sysuse auto, clear
(1978 automobile data)

```



This report summarizes automobile prices and fuel efficiency.



```stata
. summarize price mpg

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
       price |         74    6165.257    2949.496       3291      15906
         mpg |         74     21.2973    5.785503         12         41

. scatter price mpg

. graph export "scatter.png", replace
file scatter.png saved as PNG format

. ishere fig using "scatter.png", title("Price versus fuel efficiency")

```


<figure class="tohtml-figure">
<img src="scatter.png" style="zoom:100%;">
<figcaption class="tohtml-fig-title">Price versus fuel efficiency</figcaption>
</figure>


```stata

. local len 20 

. forv i=1/20{
  2.     gen mpg`i' = price
  3. }

. regress price mpg* weight
note: mpg2 omitted because of collinearity.
note: mpg3 omitted because of collinearity.
note: mpg4 omitted because of collinearity.
note: mpg5 omitted because of collinearity.
note: mpg6 omitted because of collinearity.
note: mpg7 omitted because of collinearity.
note: mpg8 omitted because of collinearity.
note: mpg9 omitted because of collinearity.
note: mpg10 omitted because of collinearity.
note: mpg11 omitted because of collinearity.
note: mpg12 omitted because of collinearity.
note: mpg13 omitted because of collinearity.
note: mpg14 omitted because of collinearity.
note: mpg15 omitted because of collinearity.
note: mpg16 omitted because of collinearity.
note: mpg17 omitted because of collinearity.
note: mpg18 omitted because of collinearity.
note: mpg19 omitted because of collinearity.
note: mpg20 omitted because of collinearity.

      Source |       SS           df       MS      Number of obs   =        74
-------------+----------------------------------   F(3, 70)        =         .
       Model |   635065396         3   211688465   Prob > F        =         .
    Residual |           0        70           0   R-squared       =    1.0000
-------------+----------------------------------   Adj R-squared   =    1.0000
       Total |   635065396        73  8699525.97   Root MSE        =         0

------------------------------------------------------------------------------
       price | Coefficient  Std. err.      t    P>|t|     [95% conf. interval]
-------------+----------------------------------------------------------------
         mpg |  -1.33e-14          .        .       .            .           .
        mpg1 |          1          .        .       .            .           .
        mpg2 |          0  (omitted)
        mpg3 |          0  (omitted)
        mpg4 |          0  (omitted)
        mpg5 |          0  (omitted)
        mpg6 |          0  (omitted)
        mpg7 |          0  (omitted)
        mpg8 |          0  (omitted)
        mpg9 |          0  (omitted)
       mpg10 |          0  (omitted)
       mpg11 |          0  (omitted)
       mpg12 |          0  (omitted)
       mpg13 |          0  (omitted)
       mpg14 |          0  (omitted)
       mpg15 |          0  (omitted)
       mpg16 |          0  (omitted)
       mpg17 |          0  (omitted)
       mpg18 |          0  (omitted)
       mpg19 |          0  (omitted)
       mpg20 |          0  (omitted)
      weight |   2.17e-16          .        .       .            .           .
       _cons |   9.09e-13          .        .       .            .           .
------------------------------------------------------------------------------

. estimates store model1

. outreg2e [model1] using "table_regression", replace html
table_regression.html
dir : seeout

. ishere tab using "table_regression.html", title("Regression of price on mpg an
> d weight")

```



<figure class="tohtml-table-block">
<figcaption class="tohtml-table-title">Regression of price on mpg and weight</figcaption>
<div class="tohtml-embedded-table">
<div class='texout-table-wrap'>
<table class='texout-table'>
<thead>
<tr>
<th>&nbsp;</th>
<th>(1)</th>
</tr>
<tr>
<th>&nbsp;</th>
<th>model1</th>
</tr>
<tr class='texout-headline'>
<th>VARIABLES</th>
<th>price</th>
</tr>
</thead>
<tbody>
<tr>
<td>mpg</td>
<td class='texout-mono'>-0</td>
</tr>
<tr>
<td>&nbsp;</td>
<td class='texout-mono'>(0)</td>
</tr>
<tr>
<td>mpg1</td>
<td class='texout-mono'>1</td>
</tr>
<tr>
<td>&nbsp;</td>
<td class='texout-mono'>(0)</td>
</tr>
<tr>
<td>o.mpg2</td>
<td class='texout-mono'>-</td>
</tr>
<tr>
<td>o.mpg3</td>
<td class='texout-mono'>-</td>
</tr>
<tr>
<td>o.mpg4</td>
<td class='texout-mono'>-</td>
</tr>
<tr>
<td>o.mpg5</td>
<td class='texout-mono'>-</td>
</tr>
<tr>
<td>o.mpg6</td>
<td class='texout-mono'>-</td>
</tr>
<tr>
<td>o.mpg7</td>
<td class='texout-mono'>-</td>
</tr>
<tr>
<td>o.mpg8</td>
<td class='texout-mono'>-</td>
</tr>
<tr>
<td>o.mpg9</td>
<td class='texout-mono'>-</td>
</tr>
<tr>
<td>o.mpg10</td>
<td class='texout-mono'>-</td>
</tr>
<tr>
<td>o.mpg11</td>
<td class='texout-mono'>-</td>
</tr>
<tr>
<td>o.mpg12</td>
<td class='texout-mono'>-</td>
</tr>
<tr>
<td>o.mpg13</td>
<td class='texout-mono'>-</td>
</tr>
<tr>
<td>o.mpg14</td>
<td class='texout-mono'>-</td>
</tr>
<tr>
<td>o.mpg15</td>
<td class='texout-mono'>-</td>
</tr>
<tr>
<td>o.mpg16</td>
<td class='texout-mono'>-</td>
</tr>
<tr>
<td>o.mpg17</td>
<td class='texout-mono'>-</td>
</tr>
<tr>
<td>o.mpg18</td>
<td class='texout-mono'>-</td>
</tr>
<tr>
<td>o.mpg19</td>
<td class='texout-mono'>-</td>
</tr>
<tr>
<td>o.mpg20</td>
<td class='texout-mono'>-</td>
</tr>
<tr>
<td>weight</td>
<td class='texout-mono'>0</td>
</tr>
<tr>
<td>&nbsp;</td>
<td class='texout-mono'>(0)</td>
</tr>
<tr>
<td>Constant</td>
<td class='texout-mono'>0</td>
</tr>
<tr>
<td>&nbsp;</td>
<td class='texout-mono'>(0)</td>
</tr>
<tr>
<td>Observations</td>
<td class='texout-mono'>74</td>
</tr>
<tr class='texout-bottomline'>
<td>R-squared</td>
<td class='texout-mono'>1.000</td>
</tr>
<tr class='texout-notes'><td colspan='2'>Standard errors in parentheses</td></tr>
<tr class='texout-notes'><td colspan='2'>*** p&lt;0.01, ** p&lt;0.05, * p&lt;0.1</td></tr>
</tbody>
</table>
</div>
</div>
</figure>



```stata

. log close
      name:  <unnamed>
       log:  C:\Users\kerry\Desktop\tohtml\Stata_tohtml\example5.log
  log type:  text
 closed on:  29 Aug 2026, 17:25:42
--------------------------------------------------------------------------------
```



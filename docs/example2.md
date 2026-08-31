# Data Preparation
# Descriptive Statistics
## Table 1

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
<figure class="tohtml-figure">

![](D:/code_test/results/figures/price_hist.png)

<figcaption class="tohtml-fig-title">Price distribution</figcaption>
</figure>
## Figure 2
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

The R-squared is  0.293 .

## Table 2

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


--------------------------------------------------------------------------------
      name:  <unnamed>
       log:  E:\Stata_tohtml\example3.log
  log type:  text
 opened on:  27 Mar 2026, 19:52:52

# Narrative Example



```

. sysuse auto, clear
(1978 automobile data)

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

. local r2 = e(r2)

. * emit the value
. ishere display %5.3f `r2'
0.293

. * narrative text 
```



 * The model R-squared is  0.293 .












```

. ishere display %5.3f `r2'
0.293

```








 * The model R-squared is  0.293 .










. log close
      name:  <unnamed>
       log:  E:\Stata_tohtml\example3.log
  log type:  text
 closed on:  27 Mar 2026, 19:52:52
--------------------------------------------------------------------------------

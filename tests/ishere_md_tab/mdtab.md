

```text
-------------------------------------------------------------------------------
      name:  <unnamed>
       log:  C:/Users/kerry/Desktop/tohtml/Stata_tohtml/tests/ishere_md_tab/mdtab.log
  log type:  text
 opened on:  24 Aug 2026, 14:38:13
```






# Markdown table via ishere tab


```stata

. sysuse auto, clear
(1978 automobile data)

. summarize price mpg weight

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
       price |         74    6165.257    2949.496       3291      15906
         mpg |         74     21.2973    5.785503         12         41
      weight |         74    3019.459    777.1936       1760       4840

```



A pipe table from `table1.md` should appear below (inlined, not an iframe).



```stata
. ishere tab using "`here'/table1.md"

```


| Variable | Mean | SD |
| --- | --- | --- |
| price | 6165.3 | 2949.5 |
| mpg | 21.3 | 5.8 |
| weight | 3019.5 | 777.2 |





End of table test.



```stata
. log close
      name:  <unnamed>
       log:  C:/Users/kerry/Desktop/tohtml/Stata_tohtml/tests/ishere_md_tab/mdtab.log
  log type:  text
 closed on:  24 Aug 2026, 14:38:13
-------------------------------------------------------------------------------
```



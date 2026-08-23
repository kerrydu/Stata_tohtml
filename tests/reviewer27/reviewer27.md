

```text
-------------------------------------------------------------------------------
      name:  <unnamed>
       log:  C:\Users\kerry\Desktop\tohtml\Stata_tohtml\tests\reviewer27\review
> er27.log
  log type:  text
 opened on:  23 Aug 2026, 09:51:21
```






# Reviewer 27 CSS test



```stata

. ishere tab using "table_fragment.html"

```


<iframe src='table_fragment.html' width='100%' height='222px' frameBorder='0'></iframe>




## custom cssfile()



```stata

. ishere tab using "table_fragment_custom.html", cssfile("chosen_fragment.css")

```


<iframe src='table_fragment_custom.html' width='100%' height='222px' frameBorder='0'></iframe>




## custom CSS without cssfile()



```stata

. ishere tab using "table_fragment_custom_nocss.html"

```


<iframe src='table_fragment_custom_nocss.html' width='100%' height='222px' frameBorder='0'></iframe>


```stata

. log close
      name:  <unnamed>
       log:  C:\Users\kerry\Desktop\tohtml\Stata_tohtml\tests\reviewer27\review
> er27.log
  log type:  text
 closed on:  23 Aug 2026, 09:51:21
-------------------------------------------------------------------------------
```





```text
-------------------------------------------------------------------------------
      name:  <unnamed>
       log:  C:\Users\kerry\Desktop\tohtml\Stata_tohtml\tests\reviewer27\bundle
> _test.log
  log type:  text
 opened on:  23 Aug 2026, 09:59:01
```






# Bundle and embed CSS



```stata

. ishere tab using "table_fragment.html"

```


<iframe src='./tables/table_fragment.html' width='100%' height='222px' frameBorder='0' scrolling='no' onload="this.style.height=this.contentDocument.documentElement.scrollHeight+'px';"></iframe>



```stata

. ishere tab using "table_fragment_custom.html", cssfile("chosen_fragment.css")

```


<iframe src='./tables/table_fragment_custom.html' width='100%' height='222px' frameBorder='0' scrolling='no' onload="this.style.height=this.contentDocument.documentElement.scrollHeight+'px';"></iframe>


```stata

. log close
      name:  <unnamed>
       log:  C:\Users\kerry\Desktop\tohtml\Stata_tohtml\tests\reviewer27\bundle
> _test.log
  log type:  text
 closed on:  23 Aug 2026, 09:59:01
-------------------------------------------------------------------------------
```



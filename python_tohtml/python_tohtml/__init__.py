"""Run a Python script into an HTML report.

The script stays ordinary Python. Markers are comments, as in Stata::

    # ishere # 标题
    # ishere fig using "fig.png", title("图题")
    # ishere tab using "tab.html", title("表题")
    # ishere display f"{n}"
    # /**
    # 样本量为 {ishere display f"{n}"}。
    # **/
"""

__version__ = "0.2.0"

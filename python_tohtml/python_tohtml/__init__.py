"""Run a Python script into an HTML report.

The script stays ordinary Python. Narrative is a triple-quoted string.
Markers for headings, figures and tables are comments::

    # ishere # 标题
    f'''
    样本量为 {n}。
    '''
    # ishere fig using "fig.svg", title("图题")
    # ishere tab using "tab.html", title("表题")

Tables and figures are written by commands, the way ``summarize`` /
``graph export`` / ``outreg2e`` write files before ``ishere tab`` and
``ishere fig``::

    from python_tohtml import summarize, scatter, regress, etable
"""

from python_tohtml.graphs import scatter
from python_tohtml.regress import regress
from python_tohtml.tables import etable, summarize

__all__ = ["etable", "regress", "scatter", "summarize"]

__version__ = "0.3.1"

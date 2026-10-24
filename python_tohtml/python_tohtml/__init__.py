"""Script-first reports for applied analysis.

Write ordinary Python. Mark headings, prose, figures and tables.
``python -m python_tohtml run analysis.py`` executes the file from the top
and writes an HTML report.
"""

from python_tohtml.ishere import display, fig, finish, h1, h2, h3, heading, md, show, tab
from python_tohtml.tables import etable, summ

__version__ = "0.1.0"

__all__ = [
    "display",
    "etable",
    "fig",
    "finish",
    "h1",
    "h2",
    "h3",
    "heading",
    "md",
    "show",
    "summ",
    "tab",
]

"""Markers an analysis script prints into the transcript.

Import them and call them between ordinary Python statements::

    from python_tohtml.ishere import h1, md, fig, tab, show

    h1("回归")
    show("r2", f"{model.rsquared:.3f}")
    md("拟合优度为 {r2}。")
    fig("figures/price.svg", title="价格与油耗")
    tab("results/model.html", title="回归结果")
"""

from __future__ import annotations

import ast
import inspect
import os
import re
from pathlib import Path
from typing import Any

from python_tohtml.session import emit

MARKER_NAMES = frozenset({
    "h1", "h2", "h3", "heading", "md", "fig", "tab", "show", "display", "finish",
})

_NUM = re.compile(r"(?<![A-Za-z0-9_.^])(\d+\.\d+|\d{2,})(?![A-Za-z0-9_])")
_IDENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
_AST_CACHE: dict[tuple[str, int, int], ast.AST] = {}


def h1(text: str) -> None:
    heading(text, level=1)


def h2(text: str) -> None:
    heading(text, level=2)


def h3(text: str) -> None:
    heading(text, level=3)


def heading(text: str, level: int = 1) -> None:
    level = min(6, max(1, int(level)))
    emit("heading", level=level, text=str(text))


def md(text: str, allow_numbers: bool = False) -> None:
    """Narrative. Format numbers in an f-string, or insert a ``show`` name as ``{name}``."""
    payload: dict[str, Any] = {"text": str(text)}
    if not allow_numbers:
        try:
            found, filename, lineno = _hardcoded_at_caller()
        except Exception:
            found, filename, lineno = [], "", 0
        if found:
            payload["hardcoded"] = found
            if filename:
                payload["file"] = filename
            if lineno:
                payload["line"] = lineno
    emit("md", **payload)


def show(name: str, value: Any) -> Any:
    """Remember a formatted value. Later ``md`` text can insert it with ``{name}``."""
    if not _IDENT.match(str(name)):
        raise ValueError(f"show 的名字必须是标识符，收到 {name!r}")
    emit("show", name=str(name), value="" if value is None else str(value))
    return value


display = show


def fig(
    path: str,
    title: str = "",
    zoom: str | None = None,
    width: str | None = None,
    height: str | None = None,
) -> None:
    emit(
        "fig",
        src=_norm_path(path),
        title=title or "",
        zoom=zoom,
        width=width,
        height=height,
    )


def tab(path: str, title: str = "", cssfile: str | None = None) -> None:
    emit(
        "tab",
        src=_norm_path(path),
        title=title or "",
        cssfile=_norm_path(cssfile) if cssfile else None,
    )


def finish(html: str, md: str | None = None, **options: Any) -> str | None:
    """Write a marker-only report. Under ``pytohtml run`` this does nothing.

    ``print`` output and code echo are not included. Use the runner for those.
    """
    if os.environ.get("PYTOHTML_RUNNER"):
        return None
    from python_tohtml.render import render_records
    from python_tohtml.session import session_records

    html_path = Path(html)
    md_path = Path(md) if md else html_path.with_suffix(".md")
    records = session_records()
    base = [str(Path.cwd()), str(html_path.parent)]
    render_records(
        records,
        html_path=html_path,
        md_path=md_path,
        base_dirs=base,
        mode=options.get("mode", "clean"),
        embed=bool(options.get("embed", False)),
        mathjax=options.get("mathjax"),
        tabwidth=options.get("tabwidth", "100%"),
        tabheight=options.get("tabheight", "80vh"),
    )
    return str(html_path)


def numbers_in_prose(text: str) -> list[str]:
    """Decimals and integers of two or more digits outside ``{placeholders}``."""
    stripped = re.sub(r"\{[^{}]*\}", "", text)
    found: list[str] = []
    seen: set[str] = set()
    for number in _NUM.findall(stripped):
        if number not in seen:
            seen.add(number)
            found.append(number)
    return found


def _norm_path(path: str) -> str:
    return str(path).replace("\\", "/")


def _hardcoded_at_caller() -> tuple[list[str], str, int]:
    frame = inspect.currentframe()
    if frame is not None:
        frame = frame.f_back  # md
    if frame is not None:
        frame = frame.f_back  # user
    while frame is not None and frame.f_code.co_filename.startswith("<"):
        frame = frame.f_back
    if frame is None:
        return [], "", 0
    filename = frame.f_code.co_filename
    lineno = frame.f_lineno
    node = _md_call_at(filename, lineno)
    if node is None:
        return [], filename, lineno
    return _literals_in_md_call(node), filename, lineno


def _md_call_at(filename: str, lineno: int) -> ast.Call | None:
    tree = _parsed(filename)
    if tree is None:
        return None
    found: ast.Call | None = None
    for node in ast.walk(tree):
        if isinstance(node, ast.Call) and getattr(node, "lineno", None) == lineno and _is_md_call(node):
            found = node
    return found


def _parsed(filename: str) -> ast.AST | None:
    try:
        stat = os.stat(filename)
    except OSError:
        return None
    key = (filename, stat.st_mtime_ns, stat.st_size)
    cached = _AST_CACHE.get(key)
    if cached is not None:
        return cached
    try:
        tree = ast.parse(Path(filename).read_text(encoding="utf-8-sig"))
    except (OSError, SyntaxError):
        return None
    _AST_CACHE.clear()
    _AST_CACHE[key] = tree
    return tree


def _is_md_call(node: ast.Call) -> bool:
    func = node.func
    if isinstance(func, ast.Name):
        return func.id == "md"
    if isinstance(func, ast.Attribute):
        return func.attr == "md"
    return False


def _literals_in_md_call(call: ast.Call) -> list[str]:
    for keyword in call.keywords:
        if (
            keyword.arg == "allow_numbers"
            and isinstance(keyword.value, ast.Constant)
            and keyword.value.value
        ):
            return []
    arg = None
    for keyword in call.keywords:
        if keyword.arg == "text":
            arg = keyword.value
    if arg is None and call.args:
        arg = call.args[0]
    if arg is None:
        return []
    parts: list[str] = []
    if isinstance(arg, ast.Constant) and isinstance(arg.value, str):
        parts.append(arg.value)
    elif isinstance(arg, ast.JoinedStr):
        for piece in arg.values:
            if isinstance(piece, ast.Constant) and isinstance(piece.value, str):
                parts.append(piece.value)
    else:
        return []
    found: list[str] = []
    seen: set[str] = set()
    for part in parts:
        for number in numbers_in_prose(part):
            if number not in seen:
                seen.add(number)
                found.append(number)
    return found

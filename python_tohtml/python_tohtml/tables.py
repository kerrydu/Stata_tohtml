"""Small HTML tables for a descriptive panel and a regression grid.

These write a fragment. Pass the path to ``tab`` so the report inlines it.
"""

from __future__ import annotations

import math
from html import escape
from pathlib import Path
from typing import Any, Mapping, Sequence


def summ(
    path: str,
    columns: Mapping[str, Sequence[Any]],
    digits: int = 3,
) -> str:
    """Write N / mean / sd / min / max with variables down the rows."""
    header = ["变量", "N", "均值", "标准差", "最小值", "最大值"]
    body: list[list[str]] = []
    for name, values in columns.items():
        clean = _numbers(values)
        n = len(clean)
        if n == 0:
            body.append([str(name), "0", "", "", "", ""])
            continue
        mean = sum(clean) / n
        if n > 1:
            var = sum((x - mean) ** 2 for x in clean) / (n - 1)
            sd = math.sqrt(var)
        else:
            sd = float("nan")
        body.append([
            str(name),
            str(n),
            _fmt(mean, digits),
            "" if math.isnan(sd) else _fmt(sd, digits),
            _fmt(min(clean), digits),
            _fmt(max(clean), digits),
        ])
    _write_table(path, header, body, numeric_from=1)
    return str(path)


def etable(
    path: str,
    models: Sequence[Any],
    titles: Sequence[str] | None = None,
    digits: int = 3,
    stars: bool = True,
    note: str = "",
) -> str:
    """Write a three-line regression table.

    Each model is a mapping, or an object with ``params``, ``bse``, ``pvalues``,
    ``nobs`` and optionally ``rsquared`` (a statsmodels result works).
    """
    specs = [_coerce_model(model) for model in models]
    if titles is not None:
        if len(titles) != len(specs):
            raise ValueError("titles 的个数要和模型个数一致")
        for spec, title in zip(specs, titles):
            spec["title"] = str(title)
    for i, spec in enumerate(specs, start=1):
        if not spec["title"]:
            spec["title"] = f"({i})"

    order: list[str] = []
    seen: set[str] = set()
    for spec in specs:
        for name in spec["coef"]:
            if name not in seen:
                seen.add(name)
                order.append(name)

    stat_names: list[str] = []
    stat_seen: set[str] = set()
    for spec in specs:
        for name in spec["stats"]:
            if name not in stat_seen:
                stat_seen.add(name)
                stat_names.append(name)

    header = [""] + [spec["title"] for spec in specs]
    rows: list[tuple[list[str], str]] = []
    for name in order:
        coef_cells = [name]
        se_cells = [""]
        any_se = False
        for spec in specs:
            if name not in spec["coef"]:
                coef_cells.append("")
                se_cells.append("")
                continue
            coef = spec["coef"][name]
            star = _stars(spec["p"].get(name)) if stars else ""
            coef_cells.append(_fmt(coef, digits) + star)
            if name in spec["se"] and spec["se"][name] is not None:
                any_se = True
                se_cells.append("(" + _fmt(spec["se"][name], digits) + ")")
            else:
                se_cells.append("")
        rows.append((coef_cells, ""))
        if any_se:
            rows.append((se_cells, ""))
    first_stat = True
    for stat in stat_names:
        cells = [stat]
        for spec in specs:
            value = spec["stats"].get(stat, "")
            cells.append("" if value is None else _fmt_stat(value, digits))
        kind = "stat stat-start" if first_stat else "stat"
        first_stat = False
        rows.append((cells, kind))

    footnotes = []
    if stars:
        footnotes.append("* p&lt;0.1，** p&lt;0.05，*** p&lt;0.01")
    if note:
        footnotes.append(escape(note))
    note_html = "".join(f'<p class="pytohtml-note">{item}</p>' for item in footnotes)
    _write_table(path, header, [row for row, _kind in rows], numeric_from=1, row_class=[kind for _row, kind in rows])
    path_obj = Path(path)
    path_obj.write_text(path_obj.read_text(encoding="utf-8") + note_html, encoding="utf-8")
    return str(path)


def _coerce_model(model: Any) -> dict[str, Any]:
    if isinstance(model, Mapping):
        coef = _as_float_map(model.get("coef", model.get("params")))
        se = _as_float_map(model.get("se", model.get("bse")))
        pvalues = _as_float_map(model.get("p", model.get("pvalues")))
        stats = dict(model.get("stats") or {})
        if "N" not in stats and model.get("nobs") is not None:
            stats["N"] = model.get("nobs")
        if "R²" not in stats and model.get("rsquared") is not None:
            stats["R²"] = model.get("rsquared")
        title = str(model.get("title") or "")
        return {"title": title, "coef": coef, "se": se, "p": pvalues, "stats": stats}

    coef = _as_float_map(getattr(model, "params", None))
    se = _as_float_map(getattr(model, "bse", None))
    pvalues = _as_float_map(getattr(model, "pvalues", None))
    stats: dict[str, Any] = {}
    nobs = getattr(model, "nobs", None)
    if nobs is not None:
        stats["N"] = nobs
    r2 = getattr(model, "rsquared", None)
    if r2 is not None:
        stats["R²"] = r2
    title = str(getattr(model, "model_name", "") or "")
    return {"title": title, "coef": coef, "se": se, "p": pvalues, "stats": stats}


def _as_float_map(obj: Any) -> dict[str, float]:
    if obj is None:
        return {}
    if isinstance(obj, Mapping):
        items = obj.items()
    elif hasattr(obj, "items"):
        items = obj.items()
    else:
        return {}
    out: dict[str, float] = {}
    for key, value in items:
        if value is None:
            continue
        out[str(key)] = float(value)
    return out


def _numbers(values: Sequence[Any]) -> list[float]:
    clean: list[float] = []
    for value in values:
        if value is None:
            continue
        try:
            number = float(value)
        except (TypeError, ValueError):
            continue
        if math.isnan(number):
            continue
        clean.append(number)
    return clean


def _fmt(value: float, digits: int) -> str:
    return f"{float(value):.{digits}f}"


def _fmt_stat(value: Any, digits: int) -> str:
    if isinstance(value, str):
        return value
    try:
        number = float(value)
    except (TypeError, ValueError):
        return str(value)
    if math.isnan(number):
        return ""
    if number.is_integer():
        return str(int(number))
    return _fmt(number, digits)


def _stars(p: float | None) -> str:
    if p is None:
        return ""
    if p < 0.01:
        return "***"
    if p < 0.05:
        return "**"
    if p < 0.1:
        return "*"
    return ""


def _write_table(
    path: str,
    header: Sequence[str],
    rows: Sequence[Sequence[str]],
    numeric_from: int = 1,
    row_class: Sequence[str] | None = None,
) -> None:
    path_obj = Path(path)
    path_obj.parent.mkdir(parents=True, exist_ok=True)
    parts = ['<table class="pytohtml-table">', "<thead><tr>"]
    for index, cell in enumerate(header):
        cls = ' class="num"' if index >= numeric_from else ""
        parts.append(f"<th{cls}>{escape(str(cell))}</th>")
    parts.append("</tr></thead><tbody>")
    for rindex, row in enumerate(rows):
        kind = row_class[rindex] if row_class else ""
        attr = f' class="{kind}"' if kind else ""
        parts.append(f"<tr{attr}>")
        for index, cell in enumerate(row):
            cls = ' class="num"' if index >= numeric_from else ""
            parts.append(f"<td{cls}>{escape(str(cell))}</td>")
        parts.append("</tr>")
    parts.append("</tbody></table>")
    path_obj.write_text("".join(parts), encoding="utf-8")

"""Write HTML tables the way Stata exports ``summarize`` and ``outreg2e``.

The script calls one of these functions. ``# ishere tab using`` only points at
the file that was written. Nothing in the analysis script assembles ``<table>``.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from html import escape
from pathlib import Path
from typing import Any, Mapping, Sequence


_CONST_NAMES = {"常数项", "_cons", "Intercept", "const", "intercept"}


@dataclass
class ColumnStats:
    n: int
    mean: float
    sd: float
    min: float
    max: float


@dataclass
class Summary:
    """What ``summarize`` returns. Index it by variable name."""

    columns: dict[str, ColumnStats]
    path: str

    def __getitem__(self, name: str) -> ColumnStats:
        return self.columns[name]


def summarize(
    path: str,
    columns: Mapping[str, Sequence[Any]],
    digits: int = 3,
) -> Summary:
    """Write N / mean / sd / min / max, one variable per row.

    Missing values (``None``, NaN, non-numeric) are dropped per variable.
    The returned object keeps the unrounded numbers for ``# ishere display``.
    """
    if not columns:
        raise ValueError("summarize 至少要有一个变量")
    header = ["变量", "N", "均值", "标准差", "最小值", "最大值"]
    body: list[list[str]] = []
    stats: dict[str, ColumnStats] = {}
    for name, values in columns.items():
        clean = _numbers(values)
        column = _column_stats(clean)
        stats[str(name)] = column
        if column.n == 0:
            body.append([str(name), "0", "", "", "", ""])
            continue
        body.append([
            str(name),
            str(column.n),
            _fmt(column.mean, digits),
            "" if math.isnan(column.sd) else _fmt(column.sd, digits),
            _fmt(column.min, digits),
            _fmt(column.max, digits),
        ])
    _write_table(path, header, body, numeric_from=1)
    return Summary(stats, str(path))


def etable(
    path: str,
    models: Sequence[Any],
    titles: Sequence[str] | None = None,
    digits: int = 3,
    stars: bool = True,
    note: str = "",
) -> str:
    """Write a three-line regression table, the role of ``outreg2e``.

    Each model is a mapping, or an object with ``params``, ``bse``, ``pvalues``,
    ``nobs`` and optionally ``rsquared`` (a ``regress`` result, or statsmodels).
    Coefficients are shown with standard errors in parentheses. ``常数项`` and
    ``_cons`` are placed last.
    """
    if not models:
        raise ValueError("etable 至少要有一个模型")
    specs = [_coerce_model(model) for model in models]
    if titles is not None:
        if len(titles) != len(specs):
            raise ValueError("titles 的个数要和模型个数一致")
        for spec, title in zip(specs, titles):
            spec["title"] = str(title)
    for index, spec in enumerate(specs, start=1):
        if not spec["title"]:
            spec["title"] = f"({index})"

    order = _coef_order(specs)
    stat_names: list[str] = []
    stat_seen: set[str] = set()
    for spec in specs:
        for name in spec["stats"]:
            if name not in stat_seen:
                stat_seen.add(name)
                stat_names.append(name)

    header = [""] + [spec["title"] for spec in specs]
    rows: list[list[str]] = []
    kinds: list[str] = []
    for name in order:
        coef_cells = [name]
        se_cells = [""]
        any_se = False
        for spec in specs:
            if name not in spec["coef"]:
                coef_cells.append("")
                se_cells.append("")
                continue
            star = _stars(spec["p"].get(name)) if stars else ""
            coef_cells.append(_fmt(spec["coef"][name], digits) + star)
            se_value = spec["se"].get(name)
            if se_value is not None and not math.isnan(se_value):
                any_se = True
                se_cells.append("(" + _fmt(se_value, digits) + ")")
            else:
                se_cells.append("")
        rows.append(coef_cells)
        kinds.append("")
        if any_se:
            rows.append(se_cells)
            kinds.append("")
    first_stat = True
    for stat in stat_names:
        cells = [stat]
        for spec in specs:
            value = spec["stats"].get(stat, "")
            cells.append("" if value is None else _fmt_stat(value, digits))
        kinds.append("stat stat-start" if first_stat else "stat")
        first_stat = False
        rows.append(cells)

    footnotes: list[str] = []
    if stars:
        footnotes.append("* p&lt;0.1，** p&lt;0.05，*** p&lt;0.01")
    if note:
        footnotes.append(escape(note))
    suffix = "".join(f'<p class="pytohtml-note">{item}</p>' for item in footnotes)
    _write_table(path, header, rows, numeric_from=1, row_class=kinds, suffix=suffix)
    return str(path)


def _coef_order(specs: Sequence[Mapping[str, Any]]) -> list[str]:
    coefs: list[str] = []
    consts: list[str] = []
    seen: set[str] = set()
    for spec in specs:
        const_name = spec.get("const")
        for name in spec["coef"]:
            if name in seen:
                continue
            seen.add(name)
            if name in _CONST_NAMES or name == const_name:
                consts.append(name)
            else:
                coefs.append(name)
    return coefs + consts


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
        const = model.get("const_name") or model.get("const")
        return {
            "title": str(model.get("title") or ""),
            "coef": coef,
            "se": se,
            "p": pvalues,
            "stats": stats,
            "const": None if const is None else str(const),
        }

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
    const = getattr(model, "const_name", None)
    title = str(getattr(model, "model_name", "") or "")
    return {
        "title": title,
        "coef": coef,
        "se": se,
        "p": pvalues,
        "stats": stats,
        "const": None if const is None else str(const),
    }


def _as_float_map(obj: Any) -> dict[str, float]:
    if obj is None:
        return {}
    items = obj.items() if isinstance(obj, Mapping) or hasattr(obj, "items") else None
    if items is None:
        return {}
    out: dict[str, float] = {}
    for key, value in items:
        if value is None:
            continue
        number = float(value)
        if math.isnan(number):
            continue
        out[str(key)] = number
    return out


def _numbers(values: Sequence[Any]) -> list[float]:
    clean: list[float] = []
    for value in values:
        if value is None or isinstance(value, bool):
            continue
        try:
            number = float(value)
        except (TypeError, ValueError):
            continue
        if math.isnan(number):
            continue
        clean.append(number)
    return clean


def _column_stats(clean: Sequence[float]) -> ColumnStats:
    n = len(clean)
    if n == 0:
        nan = float("nan")
        return ColumnStats(0, nan, nan, nan, nan)
    mean = sum(clean) / n
    if n > 1:
        var = sum((x - mean) ** 2 for x in clean) / (n - 1)
        sd = math.sqrt(var)
    else:
        sd = float("nan")
    return ColumnStats(n, mean, sd, min(clean), max(clean))


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
    if p is None or math.isnan(p):
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
    suffix: str = "",
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
    parts.append(suffix)
    path_obj.write_text("".join(parts), encoding="utf-8")

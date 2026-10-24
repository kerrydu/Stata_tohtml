"""Write figures the way Stata ``graph export`` does.

``scatter`` writes an SVG. ``# ishere fig using`` only points at that file.
The analysis script does not assemble ``<svg>`` or ``<img>``.
"""

from __future__ import annotations

import math
from html import escape
from pathlib import Path
from typing import Any, Sequence

from python_tohtml.regress import regress


def scatter(
    path: str,
    y: Sequence[Any],
    x: Sequence[Any],
    *,
    xlabel: str = "",
    ylabel: str = "",
    fit: bool = False,
) -> str:
    """Write a scatter plot. Argument order is ``y`` then ``x``, as in Stata.

    ``fit=True`` draws the OLS line from ``regress``. Pairs with a missing
    value are skipped.
    """
    if len(x) != len(y):
        raise ValueError(f"x 的长度是 {len(x)}，y 的长度是 {len(y)}")
    xs: list[float] = []
    ys: list[float] = []
    for raw_x, raw_y in zip(x, y):
        if raw_x is None or raw_y is None or isinstance(raw_x, bool) or isinstance(raw_y, bool):
            continue
        try:
            vx = float(raw_x)
            vy = float(raw_y)
        except (TypeError, ValueError):
            continue
        if math.isnan(vx) or math.isnan(vy):
            continue
        xs.append(vx)
        ys.append(vy)
    if not xs:
        raise ValueError("没有可绘制的观测")

    width, height = 680, 440
    left = 78 if ylabel else 56
    right, top, bottom = 24, 20, 58 if xlabel else 40
    plot_w = width - left - right
    plot_h = height - top - bottom
    xmin, xmax = _pad(min(xs), max(xs))
    ymin, ymax = _pad(min(ys), max(ys))

    def sx(value: float) -> float:
        return left + (value - xmin) / (xmax - xmin) * plot_w

    def sy(value: float) -> float:
        return top + (ymax - value) / (ymax - ymin) * plot_h

    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}" role="img">',
        '<rect width="100%" height="100%" fill="#ffffff"/>',
        (
            '<clipPath id="pytohtml-plot">'
            f'<rect x="{left}" y="{top}" width="{plot_w}" height="{plot_h}"/>'
            "</clipPath>"
        ),
        '<g font-family="&quot;Source Han Sans SC&quot;, &quot;Noto Sans CJK SC&quot;, '
        '&quot;PingFang SC&quot;, &quot;Microsoft YaHei&quot;, &quot;WenQuanYi Micro Hei&quot;, '
        '&quot;Droid Sans Fallback&quot;, sans-serif" '
        'font-size="12" fill="#24292f">',
    ]
    for tick in _ticks(ymin, ymax):
        y_pos = sy(tick)
        parts.append(
            f'<line x1="{left}" y1="{y_pos:.2f}" x2="{left + plot_w}" y2="{y_pos:.2f}" '
            'stroke="#eaecef" stroke-width="1"/>'
        )
        parts.append(
            f'<text x="{left - 8}" y="{y_pos:.2f}" text-anchor="end" '
            f'dominant-baseline="middle">{escape(_tick_label(tick))}</text>'
        )
    for tick in _ticks(xmin, xmax):
        x_pos = sx(tick)
        parts.append(
            f'<line x1="{x_pos:.2f}" y1="{top}" x2="{x_pos:.2f}" y2="{top + plot_h}" '
            'stroke="#eaecef" stroke-width="1"/>'
        )
        parts.append(
            f'<text x="{x_pos:.2f}" y="{top + plot_h + 18}" text-anchor="middle">'
            f"{escape(_tick_label(tick))}</text>"
        )
    parts.append(
        f'<line x1="{left}" y1="{top}" x2="{left}" y2="{top + plot_h}" '
        'stroke="#24292f" stroke-width="1"/>'
    )
    parts.append(
        f'<line x1="{left}" y1="{top + plot_h}" x2="{left + plot_w}" y2="{top + plot_h}" '
        'stroke="#24292f" stroke-width="1"/>'
    )
    parts.append('<g clip-path="url(#pytohtml-plot)">')
    if fit and len(xs) >= 2:
        line = _fit_segment(xs, ys, xmin, xmax)
        if line is not None:
            x0, y0, x1, y1 = line
            parts.append(
                f'<line x1="{sx(x0):.2f}" y1="{sy(y0):.2f}" x2="{sx(x1):.2f}" y2="{sy(y1):.2f}" '
                'stroke="#0969da" stroke-width="1.6"/>'
            )
    for vx, vy in zip(xs, ys):
        parts.append(
            f'<circle cx="{sx(vx):.2f}" cy="{sy(vy):.2f}" r="3.6" fill="#1a7f37"/>'
        )
    parts.append("</g>")
    if xlabel:
        parts.append(
            f'<text x="{left + plot_w / 2:.2f}" y="{height - 16}" text-anchor="middle" '
            f'font-size="13">{escape(xlabel)}</text>'
        )
    if ylabel:
        parts.append(
            f'<text text-anchor="middle" font-size="13" '
            f'transform="translate(18, {top + plot_h / 2:.2f}) rotate(-90)">'
            f"{escape(ylabel)}</text>"
        )
    parts.append("</g></svg>")
    path_obj = Path(path)
    path_obj.parent.mkdir(parents=True, exist_ok=True)
    path_obj.write_text("".join(parts), encoding="utf-8")
    return str(path)


def _fit_segment(
    xs: Sequence[float],
    ys: Sequence[float],
    xmin: float,
    xmax: float,
) -> tuple[float, float, float, float] | None:
    try:
        model = regress(ys, {"x": xs})
    except ValueError:
        return None
    slope = model.params["x"]
    intercept = model.params["常数项"]
    return xmin, intercept + slope * xmin, xmax, intercept + slope * xmax


def _pad(lo: float, hi: float) -> tuple[float, float]:
    if lo == hi:
        delta = abs(lo) * 0.05 or 1.0
        return lo - delta, hi + delta
    span = hi - lo
    return lo - span * 0.06, hi + span * 0.06


def _ticks(lo: float, hi: float, count: int = 5) -> list[float]:
    step = _nice_step(hi - lo, count)
    start = math.ceil((lo - step * 1e-9) / step) * step
    ticks: list[float] = []
    value = start
    for _ in range(24):
        if value > hi + step * 1e-9:
            break
        if value >= lo - step * 1e-9:
            ticks.append(value)
        value += step
    if len(ticks) < 2:
        return [lo, hi]
    return ticks


def _nice_step(span: float, count: int) -> float:
    if span <= 0:
        return 1.0
    raw = span / max(count, 1)
    exp = math.floor(math.log10(raw))
    frac = raw / (10 ** exp)
    if frac < 1.5:
        nice = 1.0
    elif frac < 3:
        nice = 2.0
    elif frac < 7:
        nice = 5.0
    else:
        nice = 10.0
    return nice * (10 ** exp)


def _tick_label(value: float) -> str:
    if value != 0 and (abs(value) >= 1e6 or abs(value) < 1e-3):
        return f"{value:.4g}"
    text = f"{value:.4f}".rstrip("0").rstrip(".")
    return text or "0"

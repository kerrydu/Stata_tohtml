"""OLS with an intercept, the role of Stata ``regress``.

No extra packages. The result carries ``params``, ``bse``, ``pvalues``,
``nobs`` and ``rsquared``, which ``etable`` already knows how to read.
"""

from __future__ import annotations

import math
from typing import Any, Mapping, Sequence


class Result:
    def __init__(
        self,
        params: dict[str, float],
        bse: dict[str, float],
        pvalues: dict[str, float],
        tvalues: dict[str, float],
        nobs: int,
        rsquared: float,
        df_resid: int,
        const_name: str | None,
    ) -> None:
        self.params = params
        self.bse = bse
        self.pvalues = pvalues
        self.tvalues = tvalues
        self.nobs = nobs
        self.rsquared = rsquared
        self.df_resid = df_resid
        self.const_name = const_name

    def __repr__(self) -> str:
        lines = [f"nobs={self.nobs}  R²={self.rsquared:.4f}"]
        for name, coef in self.params.items():
            lines.append(f"{name}: {coef:.4f}  ({self.bse[name]:.4f})")
        return "\n".join(lines)


def regress(
    y: Sequence[Any],
    x: Mapping[str, Sequence[Any]] | None = None,
    *,
    const: str = "常数项",
    add_const: bool = True,
) -> Result:
    """Fit OLS. ``x`` maps regressor names to columns. Rows with a missing
    value on ``y`` or any regressor are dropped together.

    ``scatter(..., fit=True)`` uses this same fit.
    """
    if x is None:
        x = {}
    if not isinstance(x, Mapping):
        raise TypeError("regress 的 x 要是 {名称: 数列}")
    names = [str(name) for name in x]
    if add_const and const in names:
        raise ValueError(f"自变量里已经有 {const!r}，和常数项重名")
    columns = [(name, x[name]) for name in x]
    rows = _align(y, columns)
    k_slopes = len(columns)
    k = k_slopes + (1 if add_const else 0)
    if k == 0:
        raise ValueError("没有可估计的系数")
    n = len(rows)
    if n <= k:
        raise ValueError(f"有效观测只有 {n} 个，估计 {k} 个系数不够")

    xtx = [[0.0] * k for _ in range(k)]
    xty = [0.0] * k
    for yi, xi in rows:
        design = xi + ([1.0] if add_const else [])
        for a in range(k):
            xty[a] += design[a] * yi
            for b in range(k):
                xtx[a][b] += design[a] * design[b]
    try:
        inverse = _invert(xtx)
    except ValueError as exc:
        raise ValueError("回归设计矩阵不满秩") from exc
    beta = [sum(inverse[i][j] * xty[j] for j in range(k)) for i in range(k)]

    fitted = []
    sse = 0.0
    sum_y = 0.0
    for yi, xi in rows:
        design = xi + ([1.0] if add_const else [])
        yh = sum(b * z for b, z in zip(beta, design))
        fitted.append(yh)
        sse += (yi - yh) ** 2
        sum_y += yi
    mean_y = sum_y / n
    sst = sum((yi - mean_y) ** 2 for yi, _xi in rows)
    if sst <= 1e-15:
        r2 = 1.0 if sse <= 1e-15 else 0.0
    else:
        r2 = 1.0 - sse / sst
    df = n - k
    sigma2 = sse / df
    order = names + ([const] if add_const else [])
    params: dict[str, float] = {}
    bse: dict[str, float] = {}
    pvalues: dict[str, float] = {}
    tvalues: dict[str, float] = {}
    for index, name in enumerate(order):
        coef = beta[index]
        variance = sigma2 * inverse[index][index]
        se = math.sqrt(variance) if variance > 0 else 0.0
        if se == 0:
            tstat = 0.0 if coef == 0 else math.inf
            pvalue = 1.0 if coef == 0 else 0.0
        else:
            tstat = coef / se
            pvalue = _t_pvalue(tstat, df)
        params[name] = coef
        bse[name] = se
        tvalues[name] = tstat
        pvalues[name] = pvalue
    return Result(
        params=params,
        bse=bse,
        pvalues=pvalues,
        tvalues=tvalues,
        nobs=n,
        rsquared=r2,
        df_resid=df,
        const_name=const if add_const else None,
    )


def _align(
    y: Sequence[Any],
    columns: Sequence[tuple[str, Sequence[Any]]],
) -> list[tuple[float, list[float]]]:
    n = len(y)
    for name, values in columns:
        if len(values) != n:
            raise ValueError(f"{name} 的长度是 {len(values)}，因变量长度是 {n}")
    rows: list[tuple[float, list[float]]] = []
    for index in range(n):
        try:
            yi = float(y[index])
            xi = [float(values[index]) for _name, values in columns]
        except (TypeError, ValueError):
            continue
        if isinstance(y[index], bool) or any(isinstance(values[index], bool) for _name, values in columns):
            continue
        if math.isnan(yi) or any(math.isnan(item) for item in xi):
            continue
        rows.append((yi, xi))
    return rows


def _invert(matrix: list[list[float]]) -> list[list[float]]:
    n = len(matrix)
    work = [row[:] + [1.0 if i == j else 0.0 for j in range(n)] for i, row in enumerate(matrix)]
    for col in range(n):
        pivot = max(range(col, n), key=lambda row: abs(work[row][col]))
        if abs(work[pivot][col]) < 1e-12:
            raise ValueError("singular")
        work[col], work[pivot] = work[pivot], work[col]
        scale = work[col][col]
        for j in range(col, 2 * n):
            work[col][j] /= scale
        for row in range(n):
            if row == col:
                continue
            factor = work[row][col]
            if factor == 0:
                continue
            for j in range(col, 2 * n):
                work[row][j] -= factor * work[col][j]
    return [row[n:] for row in work]


def _t_pvalue(tstat: float, df: int) -> float:
    """Two-tailed p-value from Student's t."""
    if df <= 0:
        return float("nan")
    if math.isinf(tstat):
        return 0.0
    x = df / (df + tstat * tstat)
    return _regularized_beta(df / 2.0, 0.5, x)


def _regularized_beta(a: float, b: float, x: float) -> float:
    if x <= 0:
        return 0.0
    if x >= 1:
        return 1.0
    log_bt = (
        math.lgamma(a + b) - math.lgamma(a) - math.lgamma(b)
        + a * math.log(x) + b * math.log(1 - x)
    )
    bt = math.exp(log_bt)
    if x < (a + 1) / (a + b + 2):
        return bt * _betacf(a, b, x) / a
    return 1.0 - bt * _betacf(b, a, 1 - x) / b


def _betacf(a: float, b: float, x: float) -> float:
    """Continued fraction for the incomplete beta (Numerical Recipes)."""
    fpmin = 1e-30
    qab = a + b
    qap = a + 1.0
    qam = a - 1.0
    c = 1.0
    d = 1.0 - qab * x / qap
    if abs(d) < fpmin:
        d = fpmin
    d = 1.0 / d
    h = d
    for m in range(1, 201):
        m2 = 2 * m
        aa = m * (b - m) * x / ((qam + m2) * (a + m2))
        d = 1.0 + aa * d
        if abs(d) < fpmin:
            d = fpmin
        c = 1.0 + aa / c
        if abs(c) < fpmin:
            c = fpmin
        d = 1.0 / d
        h *= d * c
        aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2))
        d = 1.0 + aa * d
        if abs(d) < fpmin:
            d = fpmin
        c = 1.0 + aa / c
        if abs(c) < fpmin:
            c = fpmin
        d = 1.0 / d
        delta = d * c
        h *= delta
        if abs(delta - 1.0) < 1e-12:
            break
    return h

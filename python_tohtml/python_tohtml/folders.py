"""Directory input, the same idea as ``tohtml`` on a folder.

One or more directories are scanned, not walked. Files named ``table*.html``,
``table*.md``, and ``figure*.png|jpg|jpeg|svg|gif|bmp|webp`` are collected,
sorted by filename, and turned into one report.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

from python_tohtml.render import render_records

_TABLE_SUFFIXES = {".html", ".md"}
_FIGURE_SUFFIXES = {".png", ".jpg", ".jpeg", ".svg", ".gif", ".bmp", ".webp"}


def collect_resources(folders: list[str | Path]) -> list[dict[str, str]]:
    """Return table and figure files from each directory, sorted by name."""
    found: list[dict[str, str]] = []
    seen: set[Path] = set()
    for raw in folders:
        folder = Path(raw)
        if not folder.is_dir():
            raise ValueError(f"不是目录：{folder}")
        resolved = folder.resolve()
        if resolved in seen:
            continue
        seen.add(resolved)
        for path in folder.iterdir():
            if not path.is_file():
                continue
            kind = _kind(path)
            if kind is None:
                continue
            found.append({
                "kind": kind,
                "src": str(path),
                "name": path.name,
            })
    found.sort(key=lambda item: (item["name"], item["src"]))
    return found


def render_folders(
    folders: list[str | Path],
    html_path: str | Path | None,
    md_path: str | Path | None = None,
    *,
    zoom: str | None = None,
    width: str | None = None,
    height: str | None = None,
    embed: bool = False,
    mathjax: bool | None = None,
    tabwidth: str = "100%",
    tabheight: str = "80vh",
) -> tuple[str, str]:
    """Build one report from the tables and figures in ``folders``."""
    items = collect_resources(folders)
    if not items:
        raise ValueError("这些目录里没有以 table 开头的表，也没有以 figure 开头的图")
    records: list[dict[str, Any]] = [
        {"kind": "heading", "level": 1, "text": "图和表"},
    ]
    for item in items:
        records.append({"kind": "heading", "level": 3, "text": item["name"]})
        payload: dict[str, Any] = {"kind": item["kind"], "src": item["src"], "title": ""}
        if item["kind"] == "fig":
            if zoom:
                payload["zoom"] = zoom
            if width:
                payload["width"] = width
            if height:
                payload["height"] = height
        records.append(payload)
    bases = [str(Path(folder)) for folder in folders]
    html_file = Path(html_path) if html_path is not None else None
    if html_file is not None:
        bases.append(str(html_file.parent))
    return render_records(
        records,
        html_path=html_file,
        md_path=Path(md_path) if md_path is not None else None,
        base_dirs=bases,
        embed=embed,
        mathjax=mathjax,
        tabwidth=tabwidth,
        tabheight=tabheight,
    )


def _kind(path: Path) -> str | None:
    name = path.name
    suffix = path.suffix.lower()
    if name.startswith("table") and suffix in _TABLE_SUFFIXES:
        return "tab"
    if name.startswith("figure") and suffix in _FIGURE_SUFFIXES:
        return "fig"
    return None

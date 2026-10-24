"""Turn a transcript into Markdown and a self-contained HTML report."""

from __future__ import annotations

import base64
import mimetypes
import os
import re
from html import escape
from pathlib import Path
from typing import Any

from python_tohtml.markers import marker_line_set, substitute_displays
from python_tohtml.transcript import parse_transcript

_NOTE_RE = re.compile(
    r"<p\b[^>]*class=[\"'][^\"']*pytohtml-note[^\"']*[\"'][^>]*>.*?</p>",
    re.IGNORECASE | re.DOTALL,
)
_STYLE_RE = re.compile(r"<style\b[^>]*>.*?</style>", re.IGNORECASE | re.DOTALL)
_TABLE_RE = re.compile(r"<table\b[^>]*>.*?</table>", re.IGNORECASE | re.DOTALL)

_MIME = {
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".gif": "image/gif",
    ".svg": "image/svg+xml",
    ".webp": "image/webp",
    ".bmp": "image/bmp",
}

_MATHJAX = """<script>
MathJax = { tex: { inlineMath: [['$', '$'], ['\\\\(', '\\\\)']], displayMath: [['$$', '$$'], ['\\\\[', '\\\\]']] } };
</script>
<script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>"""

_HIGHLIGHT = """<link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.11.1/build/styles/github.min.css">
<script src="https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.11.1/build/highlight.min.js"></script>
<script>hljs.highlightAll();</script>"""


def render_log(
    log_path: str | Path,
    html_path: str | Path | None,
    md_path: str | Path | None = None,
    **options: Any,
) -> tuple[str, str]:
    log_file = Path(log_path)
    text = log_file.read_text(encoding="utf-8")
    records = parse_transcript(text)
    bases: list[str] = []
    for record in records:
        if record.get("kind") == "meta":
            if record.get("cwd"):
                bases.append(str(record["cwd"]))
            script = record.get("script")
            if script:
                bases.append(str(Path(script).parent))
    bases.append(str(log_file.parent))
    if html_path is not None:
        bases.append(str(Path(html_path).parent))
    return render_records(
        records,
        html_path=Path(html_path) if html_path else None,
        md_path=Path(md_path) if md_path else None,
        base_dirs=bases,
        **options,
    )


def render_records(
    records: list[dict[str, Any]],
    *,
    html_path: Path | None,
    md_path: Path | None,
    base_dirs: list[str],
    mode: str = "full",
    embed: bool = False,
    mathjax: bool | None = None,
    tabwidth: str = "100%",
    tabheight: str = "80vh",
) -> tuple[str, str]:
    if mode not in {"full", "clean", "cleancode"}:
        raise ValueError(f"未知报告模式 {mode!r}")
    bases = _unique(base_dirs)
    blocks = _blocks(records, mode=mode, base_dirs=bases, embed=embed, html_path=html_path)
    title = _title(blocks, html_path)
    markdown = _blocks_to_md(blocks)
    body = _blocks_to_html(blocks)
    use_math = _wants_math(markdown, mathjax)
    html = _document(
        title=title,
        body=body,
        mathjax=use_math,
        highlight=mode == "cleancode",
        tabwidth=tabwidth,
        tabheight=tabheight,
    )
    if html_path is not None:
        html_path.parent.mkdir(parents=True, exist_ok=True)
        html_path.write_text(html, encoding="utf-8")
    if md_path is not None:
        md_path.parent.mkdir(parents=True, exist_ok=True)
        md_path.write_text(markdown, encoding="utf-8")
    return html, markdown


def _blocks(
    records: list[dict[str, Any]],
    *,
    mode: str,
    base_dirs: list[str],
    embed: bool,
    html_path: Path | None,
) -> list[tuple]:
    shows: dict[str, str] = {}
    blocks: list[tuple] = []
    script_text = _script_text(records)
    for record in records:
        kind = record.get("kind")
        if kind == "show":
            shows[str(record.get("name", ""))] = str(record.get("value", ""))
            continue
        if kind in {"meta"}:
            continue
        if kind == "stmt" and record.get("hide"):
            continue
        if mode == "clean" and kind in {"stmt", "output", "value", "error"}:
            continue
        if mode == "cleancode" and kind in {"output", "value"}:
            continue
        if kind == "heading":
            blocks.append(("h", (int(record.get("level", 1)), str(record.get("text", "")))))
        elif kind == "md":
            text = substitute_displays(str(record.get("text", "")), shows)
            blocks.append(("md", text))
            if mode != "clean" and record.get("hardcoded"):
                numbers = "、".join(str(item) for item in record["hardcoded"])
                where = f"（第 {record['line']} 行）" if record.get("line") else ""
                blocks.append((
                    "warn",
                    f"叙述里有手写数字 {numbers}{where}。请先写一行同样的 # ishere display，再在叙述里用 {{ishere display ...}}。",
                ))
        elif kind == "stmt":
            blocks.append(("code", {
                "source": str(record.get("source", "")),
                "start": record.get("start"),
                "end": record.get("end"),
            }))
        elif kind == "output":
            blocks.append(("out", str(record.get("text", ""))))
        elif kind == "value":
            blocks.append(("out", str(record.get("text", ""))))
        elif kind == "error":
            blocks.append(("err", str(record.get("text", ""))))
        elif kind == "fig":
            blocks.append(("html", _figure(record, base_dirs, embed, html_path)))
        elif kind == "tab":
            blocks.append(("html", _table(record, base_dirs)))
        elif kind == "warning":
            if mode != "clean":
                blocks.append(("warn", str(record.get("text", ""))))
    return _merge_code(blocks, script_text)


def _script_text(records: list[dict[str, Any]]) -> str | None:
    for record in records:
        script = record.get("script") if record.get("kind") == "meta" else None
        if not script:
            continue
        path = Path(str(script))
        if path.is_file():
            try:
                return path.read_text(encoding="utf-8-sig")
            except OSError:
                return None
    return None


def _merge_code(blocks: list[tuple], script_text: str | None) -> list[tuple]:
    """Join neighboring statements. Marker comments stay out of the code."""
    lines = script_text.splitlines() if script_text is not None else None
    skip = marker_line_set(script_text) if script_text is not None else set()
    merged: list[tuple] = []
    for kind, data in blocks:
        if kind == "code" and merged and merged[-1][0] == "code" and _can_merge(merged[-1][1], data, lines, skip):
            merged[-1][1]["end"] = data.get("end") or merged[-1][1].get("end")
            continue
        if kind == "code":
            info = dict(data)
            if lines and not any(block[0] == "code" for block in merged):
                start = info.get("start")
                while isinstance(start, int) and start > 1 and (start - 1) not in skip:
                    previous = lines[start - 2].strip()
                    if previous and not previous.startswith("#"):
                        break
                    start -= 1
                info["start"] = start
            merged.append(("code", info))
        else:
            merged.append((kind, data))
    result: list[tuple] = []
    for kind, data in merged:
        if kind != "code":
            result.append((kind, data))
            continue
        source = str(data.get("source") or "")
        start, end = data.get("start"), data.get("end")
        if lines and isinstance(start, int) and isinstance(end, int) and 1 <= start <= end <= len(lines):
            kept = [lines[i - 1] for i in range(start, end + 1) if i not in skip]
            while kept and not kept[0].strip():
                kept.pop(0)
            while kept and not kept[-1].strip():
                kept.pop()
            source = "\n".join(kept)
        if source.strip():
            result.append(("code", source))
    return result


def _can_merge(prev: dict, cur: dict, lines: list[str] | None, skip: set[int]) -> bool:
    if not lines:
        return False
    prev_end = prev.get("end")
    cur_start = cur.get("start")
    if not isinstance(prev_end, int) or not isinstance(cur_start, int):
        return False
    if any(line in skip for line in range(prev_end + 1, cur_start)):
        return False
    if cur_start <= prev_end + 1:
        return True
    between = lines[prev_end:cur_start - 1]
    return all(not line.strip() or line.strip().startswith("#") for line in between)


def _title(blocks: list[tuple], html_path: Path | None) -> str:
    for kind, data in blocks:
        if kind == "h":
            text = str(data[1]).strip()
            if text:
                return text
    if html_path is not None:
        return html_path.stem
    return "report"


def _blocks_to_md(blocks: list[tuple]) -> str:
    parts: list[str] = []
    for kind, data in blocks:
        if kind == "h":
            level, text = data
            parts.append(f"{'#' * level} {text}")
        elif kind == "md":
            parts.append(str(data).strip("\n"))
        elif kind == "code":
            parts.append(_fence(str(data), "python"))
        elif kind == "out":
            parts.append(_fence(str(data), "text"))
        elif kind == "err":
            parts.append(_fence(str(data), "text"))
        elif kind == "warn":
            parts.append("> " + str(data))
        elif kind == "html":
            parts.append(str(data))
    return "\n\n".join(part for part in parts if part.strip()) + "\n"


def _blocks_to_html(blocks: list[tuple]) -> str:
    parts: list[str] = []
    for kind, data in blocks:
        if kind == "h":
            level, text = data
            parts.append(f"<h{level}>{_inline(str(text))}</h{level}>")
        elif kind == "md":
            parts.append(md_to_html(str(data)))
        elif kind == "code":
            parts.append(f'<pre><code class="language-python">{escape(str(data))}</code></pre>')
        elif kind == "out":
            parts.append(f'<pre class="pytohtml-output"><code>{escape(str(data))}</code></pre>')
        elif kind == "err":
            parts.append(f'<pre class="pytohtml-error"><code>{escape(str(data))}</code></pre>')
        elif kind == "warn":
            parts.append(f'<p class="pytohtml-warn">{escape(str(data))}</p>')
        elif kind == "html":
            parts.append(str(data))
    return "\n".join(part for part in parts if part)


def md_to_html(text: str) -> str:
    lines = text.replace("\r\n", "\n").replace("\r", "\n").split("\n")
    parts: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("```"):
            lang = line[3:].strip()
            i += 1
            buf: list[str] = []
            while i < len(lines) and not lines[i].startswith("```"):
                buf.append(lines[i])
                i += 1
            if i < len(lines):
                i += 1
            klass = f' class="language-{escape(lang)}"' if lang else ""
            parts.append(f"<pre><code{klass}>{escape(chr(10).join(buf))}</code></pre>")
            continue
        stripped = line.strip()
        if stripped == "$$":
            i += 1
            buf = []
            while i < len(lines) and lines[i].strip() != "$$":
                buf.append(lines[i])
                i += 1
            if i < len(lines):
                i += 1
            math = "$$\n" + "\n".join(buf) + "\n$$"
            parts.append(f'<div class="pytohtml-math">{escape(math)}</div>')
            continue
        if stripped.startswith("$$") and stripped.endswith("$$") and len(stripped) > 4:
            parts.append(f'<div class="pytohtml-math">{escape(stripped)}</div>')
            i += 1
            continue
        if not stripped:
            i += 1
            continue
        if re.match(r"\s*(?:[-*]|\d+\.)\s+", line):
            ordered = bool(re.match(r"\s*\d+\.\s+", line))
            items: list[str] = []
            while i < len(lines) and re.match(r"\s*(?:[-*]|\d+\.)\s+", lines[i]):
                item = re.sub(r"^\s*(?:[-*]|\d+\.)\s+", "", lines[i])
                items.append(f"<li>{_inline(item)}</li>")
                i += 1
            tag = "ol" if ordered else "ul"
            parts.append(f"<{tag}>{''.join(items)}</{tag}>")
            continue
        heading = re.match(r"(#{1,6})\s+(.*)", line)
        if heading:
            level = len(heading.group(1))
            parts.append(f"<h{level}>{_inline(heading.group(2))}</h{level}>")
            i += 1
            continue
        if stripped.startswith("<"):
            buf = [line]
            i += 1
            while i < len(lines) and lines[i].strip() and lines[i].lstrip().startswith("<"):
                buf.append(lines[i])
                i += 1
            parts.append("\n".join(buf))
            continue
        buf = [line]
        i += 1
        while i < len(lines) and lines[i].strip():
            nxt = lines[i]
            if nxt.startswith("```") or nxt.strip() == "$$" or re.match(r"(#{1,6})\s+", nxt):
                break
            if re.match(r"\s*(?:[-*]|\d+\.)\s+", nxt):
                break
            buf.append(nxt)
            i += 1
        parts.append(f"<p>{_inline(_join_para(buf))}</p>")
    return "\n".join(parts)


def _join_para(lines: list[str]) -> str:
    text = lines[0].strip()
    for line in lines[1:]:
        nxt = line.strip()
        if text and nxt and ord(text[-1]) > 127 and ord(nxt[0]) > 127:
            text += nxt
        else:
            text += " " + nxt
    return text


def _inline(text: str) -> str:
    slots: list[str] = []

    def stash(match: re.Match[str]) -> str:
        slots.append(match.group(0))
        return f"\ue000{len(slots) - 1}\ue001"

    protected = re.sub(r"\$\$[\s\S]+?\$\$|\$[^$\n]+?\$|`[^`\n]+`", stash, text)
    escaped = escape(protected)
    escaped = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", escaped)
    escaped = re.sub(r"(?<!\*)\*([^*]+)\*(?!\*)", r"<em>\1</em>", escaped)
    escaped = re.sub(
        r"\[([^\]\n]+)\]\(([^)\s]+)\)",
        lambda match: f'<a href="{match.group(2)}">{match.group(1)}</a>',
        escaped,
    )

    def restore(match: re.Match[str]) -> str:
        raw = slots[int(match.group(1))]
        if raw.startswith("`") and raw.endswith("`") and len(raw) >= 2:
            return f"<code>{escape(raw[1:-1])}</code>"
        return escape(raw)

    return re.sub(r"\ue000(\d+)\ue001", restore, escaped)


def _figure(record: dict[str, Any], base_dirs: list[str], embed: bool, html_path: Path | None) -> str:
    original = str(record.get("src", ""))
    found = _find(original, base_dirs)
    missing = ""
    if found is None:
        src = original
        missing = f'<p class="pytohtml-warn">找不到图：{escape(original)}</p>'
    elif embed:
        mime = _MIME.get(found.suffix.lower()) or mimetypes.guess_type(found.name)[0] or "application/octet-stream"
        encoded = base64.b64encode(found.read_bytes()).decode("ascii")
        src = f"data:{mime};base64,{encoded}"
    else:
        src = _relative(found, html_path, original)
    attrs = [f'src="{escape(src, quote=True)}"']
    width = record.get("width")
    height = record.get("height")
    zoom = record.get("zoom")
    if width:
        attrs.append(f'width="{escape(str(width), quote=True)}"')
    if height:
        attrs.append(f'height="{escape(str(height), quote=True)}"')
    if not width and not height:
        zoom_text = _zoom(zoom) if zoom else "100%"
        attrs.append(f'style="zoom:{escape(zoom_text, quote=True)}"')
    title = str(record.get("title") or "")
    caption = f'<figcaption class="tohtml-fig-title">{escape(title)}</figcaption>' if title else ""
    return f'<figure class="tohtml-figure"><img {" ".join(attrs)}>{caption}{missing}</figure>'


def _table(record: dict[str, Any], base_dirs: list[str]) -> str:
    original = str(record.get("src", ""))
    found = _find(original, base_dirs)
    title = str(record.get("title") or "")
    caption = f'<figcaption class="tohtml-table-title">{escape(title)}</figcaption>' if title else ""
    if found is None:
        return (
            f'<figure class="tohtml-table-block">{caption}'
            f'<p class="pytohtml-warn">找不到表：{escape(original)}</p></figure>'
        )
    raw = _read_text(found)
    if found.suffix.lower() == ".md":
        inner = md_to_html(raw)
        notes = ""
    else:
        fragment = raw.strip() if not re.search(r"<html\b|<body\b", raw, re.I) else _extract_document(raw)
        css_bits = []
        cssfile = record.get("cssfile")
        css_path = _find(str(cssfile), base_dirs) if cssfile else None
        if css_path is None:
            sibling = found.with_suffix(".css")
            if sibling.is_file():
                css_path = sibling
        if css_path is not None and "<style" not in fragment.lower():
            css_bits.append(f"<style>\n{css_path.read_text(encoding='utf-8')}\n</style>")
        notes = "\n".join(_NOTE_RE.findall(fragment))
        body = _NOTE_RE.sub("", fragment).strip()
        inner = "\n".join(css_bits + [body])
    return (
        f'<figure class="tohtml-table-block">{caption}'
        f'<div class="tohtml-embedded-table">{inner}</div>{notes}</figure>'
    )


def _extract_document(raw: str) -> str:
    styles = _STYLE_RE.findall(raw)
    tables = _TABLE_RE.findall(raw)
    notes = _NOTE_RE.findall(raw)
    if tables:
        return "\n".join(styles + tables + notes)
    return raw


def _find(src: str, base_dirs: list[str]) -> Path | None:
    if not src:
        return None
    direct = Path(src)
    if direct.is_file():
        return direct
    for base in base_dirs:
        candidate = Path(base) / src
        if candidate.is_file():
            return candidate
    return None


def _relative(found: Path, html_path: Path | None, original: str) -> str:
    if html_path is None:
        return original.replace("\\", "/")
    try:
        rel = os.path.relpath(found.resolve(), html_path.resolve().parent)
    except ValueError:
        return original.replace("\\", "/")
    return rel.replace("\\", "/")


def _zoom(value: Any) -> str:
    text = str(value).strip()
    if text.endswith("%"):
        return text
    return text + "%"


def _wants_math(markdown: str, mathjax: bool | None) -> bool:
    if mathjax is not None:
        return mathjax
    return bool(re.search(r"\$\$[\s\S]+?\$\$|\$[^$\n]+?\$|\\\(|\\\[", markdown))


def _document(*, title: str, body: str, mathjax: bool, highlight: bool, tabwidth: str, tabheight: str) -> str:
    css = Path(__file__).with_name("tohtml.css").read_text(encoding="utf-8")
    extras = [_scroll_css(tabwidth, tabheight)]
    if mathjax:
        extras.append(_MATHJAX)
    if highlight:
        extras.append(_HIGHLIGHT)
    extra = "\n".join(extras)
    return (
        "<!DOCTYPE html>\n"
        '<html lang="zh-CN">\n'
        "<head>\n"
        '<meta charset="utf-8">\n'
        '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
        f"<title>{escape(title)}</title>\n"
        f'<style id="tohtml-inline-css">\n{css}\n</style>\n'
        f"{extra}\n"
        "</head>\n"
        "<body>\n"
        f"{body}\n"
        "</body>\n"
        "</html>\n"
    )


def _scroll_css(tabwidth: str, tabheight: str) -> str:
    rules = ["overflow:auto;", "-webkit-overflow-scrolling:touch;"]
    width = _css_size(tabwidth)
    height = _css_size(tabheight)
    if width:
        rules.append(f"max-width:{width};")
    if height:
        rules.append(f"max-height:{height};")
    return f'<style id="tohtml-table-scroll">.tohtml-embedded-table{{{"".join(rules)}}}</style>'


def _css_size(value: str | None) -> str | None:
    if value is None:
        return None
    text = str(value).strip()
    if text.lower() in {"", "none", "off", "."}:
        return None
    if re.fullmatch(r"\d+(\.\d+)?", text):
        return text + "px"
    return text


def _fence(source: str, lang: str) -> str:
    tick = "```"
    while tick in source:
        tick += "`"
    return f"{tick}{lang}\n{source}\n{tick}"


def _read_text(path: Path) -> str:
    data = path.read_bytes()
    for encoding in ("utf-8-sig", "utf-8", "gb18030"):
        try:
            return data.decode(encoding)
        except UnicodeDecodeError:
            continue
    return data.decode("utf-8", errors="replace")


def _unique(items: list[str]) -> list[str]:
    out: list[str] = []
    seen: set[str] = set()
    for item in items:
        if item and item not in seen:
            seen.add(item)
            out.append(item)
    return out

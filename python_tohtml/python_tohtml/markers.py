"""Comment markers, same role as Stata ``ishere`` and ``/** **/``.

A script stays ordinary Python. The runner notices these comments:

    # ishere # 标题
    # ishere ## 小节
    # ishere fig using "fig.png", title("图题")
    # ishere tab using "tab.html", title("表题")
    # ishere display f"{n}"
    # /**
    # 样本量为 {ishere display f"{n}"}。
    # **/
"""

from __future__ import annotations

import io
import re
import tokenize
from dataclasses import dataclass


@dataclass
class Marker:
    kind: str
    start: int
    end: int
    text: str = ""
    level: int = 1
    src: str = ""
    title: str = ""
    zoom: str | None = None
    width: str | None = None
    height: str | None = None
    cssfile: str | None = None
    expr: str = ""


_HEAD = re.compile(r"^ishere\s+(#{1,6})(?:\s+(.*?))?\s*$")
_USING = re.compile(r"^ishere\s+(fig|figure|tab|table)\s+using\s+(.+)$", re.IGNORECASE)
_DISPLAY = re.compile(r"^ishere\s+display\s+(.+)$", re.IGNORECASE)
_NUM = re.compile(r"(?<![A-Za-z0-9_.^])(\d+\.\d+|\d{2,})(?![A-Za-z0-9_])")
_DISPLAY_PREFIX = "{ishere display "


def parse_markers(source: str) -> list[Marker]:
    comment_at = _comment_only_lines(source)
    lines = source.splitlines()
    markers: list[Marker] = []
    index = 0
    while index < len(lines):
        line_no = index + 1
        if line_no not in comment_at:
            index += 1
            continue
        body = _comment_body(comment_at[line_no])
        if body.startswith("/**"):
            marker, index = _narrative(lines, comment_at, index, body)
            markers.append(marker)
            continue
        if body.startswith("**/"):
            index += 1
            continue
        parsed = _ishere(body, line_no)
        if parsed is not None:
            markers.append(parsed)
        index += 1
    return markers


def marker_line_set(source: str) -> set[int]:
    lines: set[int] = set()
    for marker in parse_markers(source):
        lines.update(range(marker.start, marker.end + 1))
    return lines


def numbers_in_prose(text: str) -> list[str]:
    stripped = strip_display_tags(text)
    stripped = re.sub(r"\{[^{}]*\}", "", stripped)
    found: list[str] = []
    seen: set[str] = set()
    for number in _NUM.findall(stripped):
        if number not in seen:
            seen.add(number)
            found.append(number)
    return found


def substitute_displays(text: str, values: dict[str, str]) -> str:
    parts: list[str] = []
    cursor = 0
    while True:
        start = text.find(_DISPLAY_PREFIX, cursor)
        if start < 0:
            parts.append(text[cursor:])
            break
        end = _closing_brace(text, start)
        if end is None:
            parts.append(text[cursor:])
            break
        parts.append(text[cursor:start])
        inner = text[start + 1:end]
        expr = inner[len("ishere display"):].strip()
        if expr in values:
            parts.append(values[expr])
        else:
            parts.append(text[start:end + 1])
        cursor = end + 1
    return "".join(parts)


def strip_display_tags(text: str) -> str:
    parts: list[str] = []
    cursor = 0
    while True:
        start = text.find(_DISPLAY_PREFIX, cursor)
        if start < 0:
            parts.append(text[cursor:])
            break
        end = _closing_brace(text, start)
        if end is None:
            parts.append(text[cursor:])
            break
        parts.append(text[cursor:start])
        cursor = end + 1
    return "".join(parts)


def _closing_brace(text: str, open_at: int) -> int | None:
    depth = 0
    for index in range(open_at, len(text)):
        char = text[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return index
    return None


def _comment_only_lines(source: str) -> dict[int, str]:
    code_lines: set[int] = set()
    comments: dict[int, str] = {}
    ignored = {
        tokenize.COMMENT,
        tokenize.NL,
        tokenize.NEWLINE,
        tokenize.ENCODING,
        tokenize.ENDMARKER,
        tokenize.INDENT,
        tokenize.DEDENT,
    }
    try:
        tokens = tokenize.generate_tokens(io.StringIO(source).readline)
        for tok in tokens:
            if tok.type == tokenize.COMMENT:
                comments[tok.start[0]] = tok.string
            elif tok.type not in ignored:
                code_lines.add(tok.start[0])
    except tokenize.TokenError:
        return {}
    return {line: text for line, text in comments.items() if line not in code_lines}


def _comment_body(raw: str) -> str:
    body = raw[1:] if raw.startswith("#") else raw
    if body.startswith(" "):
        body = body[1:]
    return body.strip()


def _narrative(lines: list[str], comment_at: dict[int, str], index: int, body: str) -> tuple[Marker, int]:
    start = index + 1
    first = body[3:].strip()
    if first.endswith("**/"):
        text = first[:-3].strip()
        return Marker("md", start, start, text=text), index + 1
    chunks: list[str] = []
    if first:
        chunks.append(first)
    index += 1
    end = start
    while index < len(lines):
        line_no = index + 1
        if line_no in comment_at:
            piece = _comment_body(comment_at[line_no])
            end = line_no
            if piece == "**/":
                index += 1
                break
            if piece.endswith("**/"):
                rest = piece[:-3].rstrip()
                if rest:
                    chunks.append(rest)
                index += 1
                break
            chunks.append(piece)
            index += 1
            continue
        if lines[index].strip() == "":
            chunks.append("")
            end = line_no
            index += 1
            continue
        break
    text = "\n".join(chunks).strip("\n")
    return Marker("md", start, end, text=text), index


def _ishere(body: str, line_no: int) -> Marker | None:
    if not body.startswith("ishere"):
        return None
    heading = _HEAD.match(body)
    if heading:
        level = len(heading.group(1))
        return Marker("heading", line_no, line_no, text=(heading.group(2) or "").strip(), level=level)
    using = _USING.match(body)
    if using:
        kind_word = using.group(1).lower()
        kind = "fig" if kind_word in {"fig", "figure"} else "tab"
        try:
            path, options = _using_tail(using.group(2).strip())
        except ValueError as exc:
            return Marker("error", line_no, line_no, text=str(exc))
        return Marker(
            kind,
            line_no,
            line_no,
            src=path.replace("\\", "/"),
            title=options.get("title", ""),
            zoom=options.get("zoom"),
            width=options.get("width"),
            height=options.get("height"),
            cssfile=options.get("cssfile"),
        )
    display = _DISPLAY.match(body)
    if display:
        return Marker("display", line_no, line_no, expr=display.group(1).strip())
    return Marker(
        "error",
        line_no,
        line_no,
        text=f"无法识别的标记：{body}",
    )


def _using_tail(tail: str) -> tuple[str, dict[str, str]]:
    if not tail or tail[0] not in "\"'":
        raise ValueError(f"using 后面需要引号路径：{tail}")
    quote = tail[0]
    path_chars: list[str] = []
    index = 1
    while index < len(tail) and tail[index] != quote:
        path_chars.append(tail[index])
        index += 1
    if index >= len(tail):
        raise ValueError(f"路径缺少结束引号：{tail}")
    index += 1
    rest = tail[index:].strip()
    if rest.startswith(","):
        rest = rest[1:].strip()
    return "".join(path_chars), _options(rest)


def _options(text: str) -> dict[str, str]:
    options: dict[str, str] = {}
    index = 0
    while index < len(text):
        while index < len(text) and text[index] in " \t,":
            index += 1
        if index >= len(text):
            break
        match = re.match(r"(\w+)\s*\(", text[index:])
        if not match:
            break
        name = match.group(1).lower()
        index += match.end()
        if index < len(text) and text[index] in "\"'":
            quote = text[index]
            index += 1
            buf: list[str] = []
            while index < len(text) and text[index] != quote:
                buf.append(text[index])
                index += 1
            value = "".join(buf)
            index += 1
        else:
            buf = []
            while index < len(text) and text[index] != ")":
                buf.append(text[index])
                index += 1
            value = "".join(buf).strip()
        if index < len(text) and text[index] == ")":
            index += 1
        options[name] = value
    return options

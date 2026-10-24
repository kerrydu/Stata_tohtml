"""Line-counted transcript. Body text may contain anything, including markers."""

from __future__ import annotations

import json
import re
from typing import Any

BEGIN_RE = re.compile(r"^@@@pytohtml\s+(\w+)\s+(\d+)\s*$")

JSON_KINDS = {"meta", "heading", "md", "fig", "tab", "show", "warning"}


def _lines_of(text: str) -> list[str]:
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    if text.endswith("\n"):
        text = text[:-1]
    if text == "":
        return []
    return text.split("\n")


def format_record(kind: str, body: str = "", meta: dict[str, Any] | None = None) -> str:
    if meta is not None:
        head = json.dumps(meta, ensure_ascii=False)
        content = f"{head}\n{body}" if body else head
    else:
        content = body
    lines = _lines_of(content)
    out = f"@@@pytohtml {kind} {len(lines)}\n"
    if lines:
        out += "\n".join(lines) + "\n"
    return out


def parse_transcript(text: str) -> list[dict[str, Any]]:
    lines = text.replace("\r\n", "\n").replace("\r", "\n").split("\n")
    if lines and lines[-1] == "":
        lines = lines[:-1]
    records: list[dict[str, Any]] = []
    loose: list[str] = []

    def flush_loose() -> None:
        body = "\n".join(loose).strip("\n")
        loose.clear()
        if body.strip():
            records.append({"kind": "output", "text": body})

    i = 0
    while i < len(lines):
        match = BEGIN_RE.match(lines[i])
        if not match:
            loose.append(lines[i])
            i += 1
            continue
        flush_loose()
        kind = match.group(1)
        count = int(match.group(2))
        start = i + 1
        end = start + count
        if end > len(lines):
            body = "\n".join(lines[start:])
            records.append(_decode(kind, body))
            records.append({"kind": "error", "text": "记录在写出时被截断。"})
            return records
        body = "\n".join(lines[start:end])
        records.append(_decode(kind, body))
        i = end
    flush_loose()
    return records


def _decode(kind: str, body: str) -> dict[str, Any]:
    if kind == "stmt":
        lines = body.split("\n") if body else [""]
        try:
            meta = json.loads(lines[0]) if lines[0] else {}
        except json.JSONDecodeError:
            return {"kind": "stmt", "source": body, "hide": False}
        if not isinstance(meta, dict):
            meta = {}
        source = "\n".join(lines[1:])
        record = {"kind": "stmt", "source": source}
        record.update(meta)
        return record
    if kind in {"output", "error", "value"}:
        return {"kind": kind, "text": body}
    if kind in JSON_KINDS or (body.startswith("{") and body.endswith("}")):
        try:
            data = json.loads(body) if body else {}
        except json.JSONDecodeError:
            return {"kind": "error", "text": body}
        if not isinstance(data, dict):
            return {"kind": kind, "text": body}
        data["kind"] = kind
        return data
    return {"kind": kind, "text": body}

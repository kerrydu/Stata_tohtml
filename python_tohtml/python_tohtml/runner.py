"""Run a script from top to bottom and write a transcript.

Statements run in one namespace. Comment markers are not code: they become
headings, narrative, figures, tables, or display values.
"""

from __future__ import annotations

import ast
import json
import os
import sys
import traceback
from pathlib import Path
from typing import Any

from python_tohtml.markers import (
    Marker,
    fill_display_tags,
    is_narrative_stmt,
    numbers_in_prose,
    parse_markers,
)
from python_tohtml.transcript import format_record

_MAX_LINES = 200
_MAX_CHARS = 20_000


def run_script(script: str | Path, log_path: str | Path) -> int:
    path = Path(script).resolve()
    destination = Path(log_path)
    destination.parent.mkdir(parents=True, exist_ok=True)
    source = path.read_text(encoding="utf-8-sig")
    with destination.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write(format_record("meta", json.dumps({
            "version": 1,
            "script": str(path),
            "cwd": str(path.parent),
        }, ensure_ascii=False)))
        try:
            tree = ast.parse(source, filename=str(path))
        except SyntaxError:
            handle.write(format_record("error", traceback.format_exc()))
            return 1
        return _execute(tree, source, path, handle)


def _execute(tree: ast.AST, source: str, path: Path, handle: Any) -> int:
    namespace: dict[str, Any] = {
        "__name__": "__main__",
        "__file__": str(path),
        "__package__": None,
    }
    previous_cwd = Path.cwd()
    previous_path = sys.path[:]
    previous_argv = sys.argv[:]
    previous_out, previous_err = sys.stdout, sys.stderr
    capture = _Capture()
    status = 0
    os.chdir(path.parent)
    try:
        sys.path.insert(0, str(path.parent))
        sys.argv = [str(path)]
        sys.stdout = _Stream(capture.write_out)
        sys.stderr = _Stream(capture.write_err)
        items: list[tuple[int, int, str, Any]] = [
            (stmt.lineno, 1, "stmt", stmt) for stmt in tree.body
        ]
        items.extend((marker.start, 0, "mark", marker) for marker in parse_markers(source))
        items.sort(key=lambda item: (item[0], item[1]))
        for _line, _order, kind, obj in items:
            if kind == "mark":
                failed = _apply_marker(handle, obj, namespace, path)
                handle.flush()
                if failed:
                    status = 1
                    break
                continue
            stmt = obj
            src = _source_of(source, stmt)
            if is_narrative_stmt(stmt, source):
                failed = _write_narrative(handle, stmt, src, namespace, path, capture)
                handle.flush()
                if failed:
                    status = 1
                    break
                continue
            try:
                _exec_stmt(stmt, namespace, path)
                events = capture.finish()
            except SystemExit as exc:
                events = capture.finish()
                _write_statement(handle, stmt, src, events)
                code = exc.code
                if code not in (None, 0):
                    handle.write(format_record("error", f"SystemExit: {code!r}\n"))
                    status = code if isinstance(code, int) else 1
                break
            except Exception:
                events = capture.finish()
                _write_statement(handle, stmt, src, events)
                handle.write(format_record("error", traceback.format_exc()))
                handle.flush()
                status = 1
                break
            _write_statement(handle, stmt, src, events)
            handle.flush()
    finally:
        sys.stdout = previous_out
        sys.stderr = previous_err
        sys.argv = previous_argv
        sys.path[:] = previous_path
        os.chdir(previous_cwd)
    return status


def _apply_marker(handle, marker: Marker, namespace: dict[str, Any], path: Path) -> bool:
    if marker.kind == "heading":
        handle.write(format_record("heading", json.dumps({
            "level": marker.level,
            "text": marker.text,
        }, ensure_ascii=False)))
        return False
    if marker.kind == "md":
        payload: dict[str, Any] = {
            "text": marker.text,
            "line": marker.start,
            "file": str(path),
        }
        hardcoded = numbers_in_prose(marker.text)
        if hardcoded:
            payload["hardcoded"] = hardcoded
        handle.write(format_record("md", json.dumps(payload, ensure_ascii=False)))
        return False
    if marker.kind == "display":
        try:
            value = eval(marker.expr, namespace, namespace)
        except Exception:
            handle.write(format_record("error", traceback.format_exc()))
            return True
        text = value if isinstance(value, str) else str(value)
        handle.write(format_record("show", json.dumps({
            "name": marker.expr,
            "value": text,
        }, ensure_ascii=False)))
        return False
    if marker.kind in {"fig", "tab"}:
        handle.write(format_record(marker.kind, json.dumps({
            "src": marker.src,
            "title": marker.title,
            "zoom": marker.zoom,
            "width": marker.width,
            "height": marker.height,
            "cssfile": marker.cssfile,
        }, ensure_ascii=False)))
        return False
    handle.write(format_record("error", marker.text or "无法识别的标记"))
    return True


def _write_narrative(handle, stmt, src, namespace, path, capture) -> bool:
    """A top-level triple-quoted string is prose, not a code block.

    An f-string is evaluated. A plain string may still contain
    ``{ishere display ...}``, which is filled from the live namespace.
    """
    try:
        value = _eval_expr(stmt, namespace, path)
        events = capture.finish()
    except Exception:
        events = capture.finish()
        _write_output(handle, events)
        handle.write(format_record("error", traceback.format_exc()))
        return True
    _write_output(handle, events)
    if not isinstance(value, str):
        value = str(value)
    text = value
    if not isinstance(stmt.value, ast.JoinedStr) and _DISPLAY_TAG in value:
        try:
            text = fill_display_tags(value, lambda expr: eval(expr, namespace, namespace))
        except Exception:
            handle.write(format_record("error", traceback.format_exc()))
            return True
    if not text.strip():
        return False
    payload: dict[str, Any] = {
        "text": text,
        "line": stmt.lineno,
        "file": str(path),
    }
    hardcoded = numbers_in_prose(src)
    if hardcoded:
        payload["hardcoded"] = hardcoded
    handle.write(format_record("md", json.dumps(payload, ensure_ascii=False)))
    return False


_DISPLAY_TAG = "{ishere display "


def _write_output(handle, events) -> None:
    for event in events:
        kind = event[0]
        if kind == "out":
            if str(event[1]).strip("\n"):
                handle.write(format_record("output", _truncate(event[1])))
        elif kind == "err":
            if str(event[1]).strip("\n"):
                handle.write(format_record("error", _truncate(event[1])))


def _write_statement(handle, stmt, src, events) -> None:
    meta = {
        "start": getattr(stmt, "lineno", None),
        "end": getattr(stmt, "end_lineno", getattr(stmt, "lineno", None)),
        "hide": False,
    }
    handle.write(format_record("stmt", src, meta=meta))
    _write_output(handle, events)


def _eval_expr(stmt: ast.Expr, namespace: dict[str, Any], path: Path) -> Any:
    expression = ast.Expression(body=stmt.value)
    ast.fix_missing_locations(expression)
    code = compile(expression, str(path), "eval")
    return eval(code, namespace, namespace)


def _exec_stmt(stmt: ast.stmt, namespace: dict[str, Any], path: Path) -> None:
    filename = str(path)
    if isinstance(stmt, ast.Expr):
        _eval_expr(stmt, namespace, path)
        return
    module = ast.Module(body=[stmt], type_ignores=[])
    ast.fix_missing_locations(module)
    code = compile(module, filename, "exec")
    exec(code, namespace, namespace)


def _source_of(source: str, stmt: ast.stmt) -> str:
    segment = ast.get_source_segment(source, stmt)
    if segment is None:
        lines = source.splitlines()
        end = getattr(stmt, "end_lineno", stmt.lineno)
        segment = "\n".join(lines[stmt.lineno - 1:end])
    if segment.endswith("\n"):
        segment = segment[:-1]
    return segment


def _truncate(text: str) -> str:
    lines = str(text).splitlines()
    clipped = False
    if len(lines) > _MAX_LINES:
        lines = lines[:_MAX_LINES]
        clipped = True
    body = "\n".join(lines)
    if len(body) > _MAX_CHARS:
        body = body[:_MAX_CHARS]
        clipped = True
    if clipped:
        body += "\n…（输出已截断）"
    return body


class _Capture:
    def __init__(self) -> None:
        self.events: list[tuple] = []
        self._out: list[str] = []
        self._err: list[str] = []

    def write_out(self, text: str) -> None:
        if self._err:
            self._flush_err()
        self._out.append(text)

    def write_err(self, text: str) -> None:
        if self._out:
            self._flush_out()
        self._err.append(text)

    def finish(self) -> list[tuple]:
        self._flush_out()
        self._flush_err()
        events = self.events
        self.events = []
        return events

    def _flush_out(self) -> None:
        if self._out:
            self.events.append(("out", "".join(self._out)))
            self._out.clear()

    def _flush_err(self) -> None:
        if self._err:
            self.events.append(("err", "".join(self._err)))
            self._err.clear()


class _Stream:
    def __init__(self, write) -> None:
        self._write = write
        self.encoding = "utf-8"

    def write(self, text: str) -> int:
        if text:
            self._write(text)
        return len(text or "")

    def flush(self) -> None:
        return None

    def isatty(self) -> bool:
        return False

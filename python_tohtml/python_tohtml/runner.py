"""Run a script from top to bottom and write a transcript.

Each top-level statement is echoed, then executed in one shared namespace.
Expression values are recorded the way a REPL would display them. Marker
calls stay in the order they ran, interleaved with stdout.
"""

from __future__ import annotations

import ast
import json
import os
import sys
import traceback
from pathlib import Path
from typing import Any

from python_tohtml.ishere import MARKER_NAMES, numbers_in_prose
from python_tohtml.session import set_sink
from python_tohtml.transcript import format_record

_MISSING = object()
_MAX_LINES = 200
_MAX_CHARS = 20_000


def run_script(script: str | Path, log_path: str | Path) -> int:
    path = Path(script).resolve()
    destination = Path(log_path)
    destination.parent.mkdir(parents=True, exist_ok=True)
    source = path.read_text(encoding="utf-8-sig")
    status = 0
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
        status = _execute(tree, source, path, handle)
    return status


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
    previous_sink = None
    os.chdir(path.parent)
    try:
        sys.path.insert(0, str(path.parent))
        sys.argv = [str(path)]
        os.environ["PYTOHTML_RUNNER"] = "1"
        previous_sink = set_sink(capture.mark)
        sys.stdout = _Stream(capture.write_out)
        sys.stderr = _Stream(capture.write_err)
        for stmt in tree.body:
            src = _source_of(source, stmt)
            try:
                if _string_statement(stmt):
                    text = stmt.value.value
                    assert isinstance(text, str)
                    events = [("mark", "md", {
                        "text": text,
                        "hardcoded": numbers_in_prose(text),
                        "file": str(path),
                        "line": stmt.lineno,
                    })]
                    value: Any = None
                else:
                    value = _exec_stmt(stmt, namespace, path)
                    events = capture.finish()
            except SystemExit as exc:
                events = capture.finish()
                _write_statement(handle, stmt, src, events, _MISSING, force_hide=False)
                code = exc.code
                if code not in (None, 0):
                    handle.write(format_record("error", f"SystemExit: {code!r}\n"))
                    status = code if isinstance(code, int) else 1
                break
            except Exception:
                events = capture.finish()
                _write_statement(handle, stmt, src, events, _MISSING, force_hide=False)
                handle.write(format_record("error", traceback.format_exc()))
                handle.flush()
                status = 1
                break
            _write_statement(handle, stmt, src, events, value, force_hide=None)
            handle.flush()
    finally:
        set_sink(previous_sink)
        sys.stdout = previous_out
        sys.stderr = previous_err
        os.environ.pop("PYTOHTML_RUNNER", None)
        sys.argv = previous_argv
        sys.path[:] = previous_path
        os.chdir(previous_cwd)
    return status


def _write_statement(handle, stmt, src, events, value, force_hide) -> None:
    text_output = _has_text(events)
    if force_hide is None:
        hide = _marker_only(stmt) and not text_output
        if _string_statement(stmt):
            hide = True
    else:
        hide = force_hide
    meta = {
        "start": getattr(stmt, "lineno", None),
        "end": getattr(stmt, "end_lineno", getattr(stmt, "lineno", None)),
        "hide": hide,
    }
    handle.write(format_record("stmt", src, meta=meta))
    for event in events:
        kind = event[0]
        if kind == "out":
            if str(event[1]).strip("\n"):
                handle.write(format_record("output", _truncate(event[1])))
        elif kind == "err":
            if str(event[1]).strip("\n"):
                handle.write(format_record("error", _truncate(event[1])))
        else:
            handle.write(format_record(event[1], json.dumps(event[2], ensure_ascii=False)))
    if not hide and value is not _MISSING and value is not None and not _quiet_call_result(stmt, value):
        shown = format_value(value)
        if shown:
            handle.write(format_record("value", shown))


def _exec_stmt(stmt: ast.stmt, namespace: dict[str, Any], path: Path) -> Any:
    filename = str(path)
    if isinstance(stmt, ast.Expr):
        expression = ast.Expression(body=stmt.value)
        ast.fix_missing_locations(expression)
        code = compile(expression, filename, "eval")
        return eval(code, namespace, namespace)
    module = ast.Module(body=[stmt], type_ignores=[])
    ast.fix_missing_locations(module)
    code = compile(module, filename, "exec")
    exec(code, namespace, namespace)
    return _MISSING


def _source_of(source: str, stmt: ast.stmt) -> str:
    segment = ast.get_source_segment(source, stmt)
    if segment is None:
        lines = source.splitlines()
        end = getattr(stmt, "end_lineno", stmt.lineno)
        segment = "\n".join(lines[stmt.lineno - 1:end])
    if segment.endswith("\n"):
        segment = segment[:-1]
    return segment


def _string_statement(stmt: ast.stmt) -> bool:
    return (
        isinstance(stmt, ast.Expr)
        and isinstance(stmt.value, ast.Constant)
        and isinstance(stmt.value.value, str)
    )


def _marker_only(stmt: ast.stmt) -> bool:
    value = None
    if isinstance(stmt, ast.Expr):
        value = stmt.value
    elif isinstance(stmt, (ast.Assign, ast.AnnAssign)):
        value = stmt.value
    if not isinstance(value, ast.Call):
        return False
    func = value.func
    if isinstance(func, ast.Name):
        return func.id in MARKER_NAMES
    if isinstance(func, ast.Attribute):
        return func.attr in MARKER_NAMES
    return False


def _quiet_call_result(stmt: ast.stmt, value: Any) -> bool:
    """A bare call that only hands back a path should not echo that path."""
    if not (isinstance(stmt, ast.Expr) and isinstance(stmt.value, ast.Call)):
        return False
    return isinstance(value, (str, Path))


def _has_text(events: list[tuple]) -> bool:
    for event in events:
        if event[0] in {"out", "err"} and str(event[1]).strip("\n"):
            return True
    return False


def format_value(value: Any) -> str | None:
    module = type(value).__module__
    name = type(value).__name__
    if module.startswith("matplotlib") or name in {"Figure", "Axes", "AxesSubplot"}:
        return None
    if hasattr(value, "to_string") and hasattr(value, "shape"):
        try:
            text = value.to_string(max_rows=30, max_cols=12)
        except TypeError:
            try:
                text = value.to_string()
            except Exception:
                text = repr(value)
    else:
        try:
            text = repr(value)
        except Exception as exc:
            text = f"<repr 失败: {exc}>"
    if text == "":
        return None
    return _truncate(text)


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

    def mark(self, kind: str, payload: dict) -> None:
        self._flush_out()
        self._flush_err()
        self.events.append(("mark", kind, payload))

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

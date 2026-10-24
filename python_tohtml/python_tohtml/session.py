"""In-process marker bus.

The runner installs a sink so markers stay in order with stdout.
A plain ``python analysis.py`` prints the same records to stdout.
"""

from __future__ import annotations

import json
import sys
from typing import Any, Callable

BEGIN = "@@@pytohtml"

Sink = Callable[[str, dict[str, Any]], None]

_sink: Sink | None = None
_session: list[dict[str, Any]] = []


def set_sink(sink: Sink | None) -> Sink | None:
    global _sink
    previous = _sink
    _sink = sink
    return previous


def emit(kind: str, **payload: Any) -> None:
    if _sink is not None:
        _sink(kind, payload)
        return
    _session.append({"kind": kind, **payload})
    line = json.dumps(payload, ensure_ascii=False)
    sys.stdout.write(f"{BEGIN} {kind} 1\n{line}\n")
    sys.stdout.flush()


def session_records() -> list[dict[str, Any]]:
    return list(_session)


def clear_session() -> None:
    _session.clear()

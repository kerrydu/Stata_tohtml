"""Command line: run a script, or rebuild a report from a transcript."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from python_tohtml.runner import run_script
from python_tohtml.transcript import parse_transcript


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="pytohtml",
        description="把一份 Python 分析脚本跑成可阅读的 HTML 报告。",
    )
    sub = parser.add_subparsers(dest="cmd", required=True)

    run = sub.add_parser("run", help="从头运行脚本，写出记录、Markdown 和 HTML")
    run.add_argument("script", help="分析脚本")
    run.add_argument("--log", help="记录文件，默认为 HTML 同名 .log")
    _add_report_args(run)
    run.set_defaults(func=_cmd_run)

    build = sub.add_parser("build", help="从已有记录生成报告")
    build.add_argument("log", help="pytohtml 记录")
    _add_report_args(build)
    build.set_defaults(func=_cmd_build)

    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except ValueError as exc:
        print(f"pytohtml: {exc}", file=sys.stderr)
        return 2


def _add_report_args(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--html", help="HTML 报告路径")
    parser.add_argument("--md", help="Markdown 路径")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--clean", action="store_true", help="只留标题、叙述、图和表")
    group.add_argument("--cleancode", action="store_true", help="留下代码、叙述、图和表，去掉命令输出")
    parser.add_argument("--embed", action="store_true", help="把图片嵌进 HTML")
    parser.add_argument("--mathjax", action="store_true", help="总是加载 MathJax")
    parser.add_argument("--no-mathjax", action="store_true", help="不加载 MathJax")
    parser.add_argument("--tabwidth", default="100%", help="表格滚动框最大宽度，默认 100%")
    parser.add_argument("--tabheight", default="80vh", help="表格滚动框最大高度，默认 80vh")


def _cmd_run(args: argparse.Namespace) -> int:
    script = Path(args.script)
    if not script.is_file():
        print(f"pytohtml: 找不到脚本 {script}", file=sys.stderr)
        return 2
    html = Path(args.html) if args.html else script.with_suffix(".html")
    log = Path(args.log) if args.log else html.with_suffix(".log")
    md = Path(args.md) if args.md else html.with_suffix(".md")
    status = run_script(script, log)
    _render_and_report(log, html, md, args)
    if status != 0:
        print("脚本运行失败，已写出停在错误处的报告。", file=sys.stderr)
    return status


def _cmd_build(args: argparse.Namespace) -> int:
    log = Path(args.log)
    if not log.is_file():
        print(f"pytohtml: 找不到记录 {log}", file=sys.stderr)
        return 2
    html = Path(args.html) if args.html else log.with_suffix(".html")
    md = Path(args.md) if args.md else html.with_suffix(".md")
    _render_and_report(log, html, md, args)
    return 0


def _render_and_report(log: Path, html: Path, md: Path, args: argparse.Namespace) -> None:
    from python_tohtml.render import render_log

    mode = "clean" if args.clean else "cleancode" if args.cleancode else "full"
    mathjax: bool | None
    if args.mathjax:
        mathjax = True
    elif args.no_mathjax:
        mathjax = False
    else:
        mathjax = None
    render_log(
        log,
        html,
        md,
        mode=mode,
        embed=args.embed,
        mathjax=mathjax,
        tabwidth=args.tabwidth,
        tabheight=args.tabheight,
    )
    _print_number_warnings(log)
    print(f"log: {log}")
    print(f"md: {md}")
    print(f"html: {html}")


def _print_number_warnings(log: Path) -> None:
    records = parse_transcript(log.read_text(encoding="utf-8"))
    for record in records:
        if record.get("kind") != "md" or not record.get("hardcoded"):
            continue
        loc = ""
        if record.get("file"):
            loc = f"{record['file']}:{record.get('line', '')}: "
        numbers = "、".join(str(item) for item in record["hardcoded"])
        print(f"pytohtml: {loc}叙述里有手写数字 {numbers}", file=sys.stderr)

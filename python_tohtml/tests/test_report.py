import shutil
import tempfile
import unittest
from pathlib import Path

from python_tohtml.markers import parse_markers, substitute_displays
from python_tohtml.render import render_log
from python_tohtml.runner import run_script
from python_tohtml.transcript import format_record, parse_transcript


ROOT = Path(__file__).resolve().parents[1]


def _run(source: str):
    tmp = Path(tempfile.mkdtemp())
    script = tmp / "analysis.py"
    script.write_text(source, encoding="utf-8")
    log = tmp / "analysis.log"
    status = run_script(script, log)
    return tmp, status, log.read_text(encoding="utf-8")


class MarkerParseTests(unittest.TestCase):
    def test_comments_match_the_stata_forms(self):
        source = '''
x = 1  # ishere # 行内注释不是标记
# ishere # 标题
# ishere ## 表 1
# ishere display f"{n}"
# /**
# 样本量为 {ishere display f"{n}"}。
#
# 第二段
# **/
# ishere fig using "figures/a.png", title("价格, 油耗") zoom(80%)
# ishere tab using "results/a.html", title("回归")
'''
        markers = parse_markers(source)
        kinds = [marker.kind for marker in markers]
        self.assertEqual(kinds, ["heading", "heading", "display", "md", "fig", "tab"])
        self.assertEqual(markers[0].text, "标题")
        self.assertEqual(markers[1].level, 2)
        self.assertEqual(markers[2].expr, 'f"{n}"')
        self.assertIn("第二段", markers[3].text)
        self.assertEqual(markers[4].src, "figures/a.png")
        self.assertEqual(markers[4].title, "价格, 油耗")
        self.assertEqual(markers[4].zoom, "80%")
        self.assertEqual(markers[5].title, "回归")

    def test_display_tag_keeps_nested_braces(self):
        text = '共 {ishere display f"{n}"} 个，系数 {ishere display f"{b:.2f}"}。'
        got = substitute_displays(text, {'f"{n}"': "24", 'f"{b:.2f}"': "-1.20"})
        self.assertEqual(got, "共 24 个，系数 -1.20。")


class TranscriptTests(unittest.TestCase):
    def test_roundtrip_keeps_marker_looking_output(self):
        body = "@@@pytohtml output 1\nSTILL"
        blob = format_record("output", body) + format_record("heading", '{"level": 1, "text": "后"}')
        records = parse_transcript(blob)
        self.assertEqual(records[0]["text"], body)
        self.assertEqual(records[1]["text"], "后")

    def test_truncated_record_is_reported(self):
        records = parse_transcript("@@@pytohtml output 5\nonly-one\n")
        self.assertEqual(records[-1]["kind"], "error")


class RunnerTests(unittest.TestCase):
    def test_markers_are_comments_and_display_fills_the_prose(self):
        tmp, status, log = _run(
            'n = 24\n'
            'print(n)\n'
            '# ishere # 样本\n'
            '# ishere display f"{n}"\n'
            '# /**\n'
            '# 样本量为 {ishere display f"{n}"}。\n'
            '# **/\n'
            'price = n * 2\n'
        )
        self.addCleanup(shutil.rmtree, tmp)
        self.assertEqual(status, 0)
        html, _md = render_log(tmp / "analysis.log", tmp / "report.html", None)
        body = html.split("<body>", 1)[1]
        self.assertIn("<h1>样本</h1>", body)
        self.assertIn("样本量为 24。", body)
        self.assertNotIn("# ishere", body)
        self.assertNotIn("{ishere display", body)
        self.assertIn("print(n)", body)
        self.assertIn("24", log)
        shows = [r for r in parse_transcript(log) if r["kind"] == "show"]
        self.assertEqual(shows[0]["value"], "24")

    def test_triple_quoted_string_is_narrative(self):
        tmp, status, _log = _run(
            'n = 24\n'
            'f"""\n'
            '样本量为 {n}。\n'
            '"""\n'
            'print(n)\n'
        )
        self.addCleanup(shutil.rmtree, tmp)
        self.assertEqual(status, 0)
        html, _md = render_log(tmp / "analysis.log", tmp / "report.html", None)
        body = html.split("<body>", 1)[1]
        self.assertIn("<p>样本量为 24。</p>", body)
        self.assertNotIn("{n}", body)
        self.assertNotIn('f"""', body)
        self.assertIn("print(n)", body)
        self.assertNotIn("手写数字", body)

    def test_display_tag_inside_a_triple_quoted_string(self):
        tmp, status, _log = _run(
            'n = 24\n'
            '"""\n'
            '样本量为 {ishere display f"{n}"}。\n'
            '"""\n'
        )
        self.addCleanup(shutil.rmtree, tmp)
        self.assertEqual(status, 0)
        html, _md = render_log(tmp / "analysis.log", tmp / "report.html", None)
        body = html.split("<body>", 1)[1]
        self.assertIn("样本量为 24。", body)
        self.assertNotIn("{ishere display", body)

    def test_raw_string_keeps_latex(self):
        tmp, status, _log = _run(
            'r"""\n'
            '$$\n'
            'price = \\beta_0\n'
            '$$\n'
            '"""\n'
        )
        self.addCleanup(shutil.rmtree, tmp)
        self.assertEqual(status, 0)
        html, _md = render_log(tmp / "analysis.log", tmp / "report.html", None)
        self.assertIn("\\beta_0", html)
        self.assertNotIn("\x08eta", html)

    def test_number_typed_in_an_fstring_is_flagged(self):
        tmp, status, _log = _run('f"""\n系数是 0.84。\n"""\n')
        self.addCleanup(shutil.rmtree, tmp)
        self.assertEqual(status, 0)
        html, _md = render_log(tmp / "analysis.log", tmp / "report.html", None)
        self.assertIn("手写数字", html)
        self.assertIn("0.84", html)

    def test_assigned_triple_quote_stays_code(self):
        tmp, status, _log = _run('note = """\n不是叙述\n"""\n')
        self.addCleanup(shutil.rmtree, tmp)
        self.assertEqual(status, 0)
        html, _md = render_log(tmp / "analysis.log", tmp / "report.html", None)
        body = html.split("<body>", 1)[1]
        self.assertIn("不是叙述", body)
        self.assertNotIn("<p>不是叙述</p>", body)

    def test_a_string_statement_is_not_narrative(self):
        tmp, status, _log = _run('"这不是叙述"\n')
        self.addCleanup(shutil.rmtree, tmp)
        self.assertEqual(status, 0)
        html, _md = render_log(tmp / "analysis.log", tmp / "report.html", None)
        body = html.split("<body>", 1)[1]
        self.assertIn("这不是叙述", body)
        self.assertNotIn("<p>这不是叙述</p>", body)
        self.assertNotIn("pytohtml-output", body)

    def test_adjacent_statements_share_one_block(self):
        tmp, status, _log = _run("a = 1\nb = 2\nprint(a + b)\n")
        self.addCleanup(shutil.rmtree, tmp)
        self.assertEqual(status, 0)
        html, _md = render_log(tmp / "analysis.log", tmp / "report.html", None)
        body = html.split("<body>", 1)[1]
        self.assertEqual(body.count("language-python"), 1)
        self.assertIn("a = 1\nb = 2\nprint(a + b)", body)

    def test_printed_sentinel_does_not_break_the_log(self):
        tmp, status, log = _run(
            'print("@@@pytohtml output 1")\n'
            'print("STILL")\n'
            '# ishere # 后\n'
        )
        self.addCleanup(shutil.rmtree, tmp)
        self.assertEqual(status, 0)
        records = parse_transcript(log)
        text = "\n".join(r.get("text", "") for r in records)
        self.assertIn("STILL", text)
        self.assertTrue(any(r.get("kind") == "heading" and r.get("text") == "后" for r in records))

    def test_failure_keeps_the_partial_transcript(self):
        tmp, status, log = _run('print("before-error")\nraise RuntimeError("boom-marker")\n')
        self.addCleanup(shutil.rmtree, tmp)
        self.assertEqual(status, 1)
        self.assertIn("before-error", log)
        self.assertIn("boom-marker", log)
        html, _md = render_log(tmp / "analysis.log", tmp / "report.html", None)
        self.assertIn("before-error", html)
        self.assertIn("boom-marker", html)

    def test_clean_drops_code_and_output(self):
        tmp, status, _log = _run(
            '# ishere # 标题\n'
            'print("只在完整记录里")\n'
            '# /**\n'
            '# 正文留下。\n'
            '# **/\n'
            'x = 1 + 2\n'
        )
        self.addCleanup(shutil.rmtree, tmp)
        self.assertEqual(status, 0)
        clean, _ = render_log(tmp / "analysis.log", tmp / "clean.html", None, mode="clean")
        code, _ = render_log(tmp / "analysis.log", tmp / "code.html", None, mode="cleancode")
        clean_body = clean.split("<body>", 1)[1]
        code_body = code.split("<body>", 1)[1]
        self.assertIn("正文留下。", clean_body)
        self.assertNotIn("只在完整记录里", clean_body)
        self.assertNotIn("language-python", clean_body)
        self.assertIn("正文留下。", code_body)
        self.assertIn("print(", code_body)
        self.assertNotIn("pytohtml-output", code_body)

    def test_figure_and_table_markers(self):
        tmp, status, _log = _run(
            'from pathlib import Path\n'
            'Path("fig.svg").write_text("<svg xmlns=\\"http://www.w3.org/2000/svg\\"></svg>", encoding="utf-8")\n'
            '# ishere fig using "fig.svg", title("散点")\n'
            '# ishere tab using "missing.html", title("不存在")\n'
        )
        self.addCleanup(shutil.rmtree, tmp)
        self.assertEqual(status, 0)
        html, _md = render_log(tmp / "analysis.log", tmp / "report.html", None, embed=True)
        body = html.split("<body>", 1)[1]
        self.assertIn("data:image/svg+xml;base64,", body)
        self.assertIn("散点", body)
        self.assertIn("找不到表", body)
        self.assertNotIn("# ishere", body)

    def test_bad_display_stops_and_is_visible(self):
        tmp, status, log = _run('# ishere display missing_name\nprint("after")\n')
        self.addCleanup(shutil.rmtree, tmp)
        self.assertEqual(status, 1)
        self.assertIn("NameError", log)
        self.assertNotIn("after", log)

    def test_handwritten_number_is_flagged(self):
        tmp, status, _log = _run(
            '# /**\n'
            '# 系数是 0.84。\n'
            '# **/\n'
        )
        self.addCleanup(shutil.rmtree, tmp)
        self.assertEqual(status, 0)
        html, _md = render_log(tmp / "analysis.log", tmp / "report.html", None)
        self.assertIn("手写数字", html)
        self.assertIn("0.84", html)


class ExampleTests(unittest.TestCase):
    def test_auto_price_exports_tables_and_figures(self):
        script = ROOT / "examples" / "auto_price.py"
        source = script.read_text(encoding="utf-8")
        self.assertIn("from python_tohtml import", source)
        self.assertNotIn("# /**", source)
        self.assertIn('f"""', source)
        self.assertIn("summarize(", source)
        self.assertIn("scatter(", source)
        self.assertIn("regress(", source)
        self.assertIn("etable(", source)
        self.assertNotIn("<table", source)
        self.assertNotIn("<svg", source)
        self.assertNotIn("pytohtml-table", source)
        html_path = ROOT / "examples" / "auto_price.html"
        log_path = ROOT / "examples" / "auto_price.log"
        md_path = ROOT / "examples" / "auto_price.md"
        status = run_script(script, log_path)
        self.assertEqual(status, 0)
        html, markdown = render_log(log_path, html_path, md_path)
        body = html.split("<body>", 1)[1]
        self.assertNotIn("# ishere", body)
        self.assertNotIn("{ishere display", body)
        self.assertNotIn('f"""', body)
        self.assertNotIn("s['价格'].n", body)
        self.assertIn("共 24 个观测", body)
        self.assertIn("价格均值约为", body)
        self.assertIn("标准差", body)
        self.assertIn("描述统计", body)
        self.assertIn("价格回归", body)
        self.assertIn("因变量为价格。", body)
        self.assertRegex(body, r"系数为 -\d+\.\d")
        self.assertIn("***", body)
        self.assertIn('src="figures/price.svg"', body)
        self.assertIn("MathJax", html)
        self.assertNotIn("手写数字", body)
        clean, clean_md = render_log(
            log_path,
            ROOT / "examples" / "auto_price_clean.html",
            ROOT / "examples" / "auto_price_clean.md",
            mode="clean",
        )
        clean_body = clean.split("<body>", 1)[1]
        self.assertIn("共 24 个观测", clean_body)
        self.assertIn("pytohtml-table", clean_body)
        self.assertNotIn("random.Random", clean_body)
        self.assertIn("# 价格与油耗", markdown)
        self.assertIn("描述统计", clean_md)


if __name__ == "__main__":
    unittest.main()

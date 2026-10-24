import io
import shutil
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

from python_tohtml.ishere import md
from python_tohtml.render import render_log
from python_tohtml.runner import run_script
from python_tohtml.session import clear_session
from python_tohtml.tables import etable, summ
from python_tohtml.transcript import format_record, parse_transcript


ROOT = Path(__file__).resolve().parents[1]


def _run(source: str, name: str = "analysis.py"):
    tmp = Path(tempfile.mkdtemp())
    script = tmp / name
    script.write_text(source, encoding="utf-8")
    log = tmp / "analysis.log"
    status = run_script(script, log)
    return tmp, status, log.read_text(encoding="utf-8")


class TranscriptTests(unittest.TestCase):
    def test_roundtrip_keeps_marker_looking_output(self):
        body = "@@@pytohtml output 1\nSTILL"
        blob = format_record("output", body) + format_record("heading", '{"level": 1, "text": "后"}')
        records = parse_transcript(blob)
        self.assertEqual(records[0]["text"], body)
        self.assertEqual(records[1]["kind"], "heading")
        self.assertEqual(records[1]["text"], "后")

    def test_truncated_record_is_reported(self):
        records = parse_transcript("@@@pytohtml output 5\nonly-one\n")
        self.assertEqual(records[-1]["kind"], "error")


class MarkerTests(unittest.TestCase):
    def tearDown(self):
        clear_session()

    def test_hardcoded_number_is_flagged_from_the_call(self):
        buf = io.StringIO()
        with redirect_stdout(buf):
            md("系数是 0.84")
        log = buf.getvalue()
        self.assertIn("0.84", log)
        self.assertIn("hardcoded", log)

    def test_fstring_and_show_names_are_not_flagged(self):
        buf = io.StringIO()
        x = 0.84
        with redirect_stdout(buf):
            md(f"系数是 {x:.2f}")
            md("系数是 {b_mpg}。")
            md(r"写成 $R^2$。")
            md("年份 1990", allow_numbers=True)
        log = buf.getvalue()
        self.assertNotIn("hardcoded", log)

    def test_two_digit_literal_inside_an_fstring_is_flagged(self):
        buf = io.StringIO()
        x = 1
        with redirect_stdout(buf):
            md(f"见表 12，系数 {x}")
        self.assertIn("hardcoded", buf.getvalue())
        self.assertIn("12", buf.getvalue())


class TableTests(unittest.TestCase):
    def test_summ_uses_sample_sd(self):
        tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, tmp)
        path = tmp / "sum.html"
        summ(path, {"x": [1, 2, 3]})
        text = path.read_text(encoding="utf-8")
        self.assertIn(">3<", text)
        self.assertIn(">2.000<", text)
        self.assertIn(">1.000<", text)

    def test_etable_stars_and_standard_errors(self):
        tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, tmp)
        path = tmp / "reg.html"
        etable(path, [{
            "title": "(1)",
            "coef": {"mpg": 1.5},
            "se": {"mpg": 0.4},
            "p": {"mpg": 0.04},
            "stats": {"N": 40, "R²": 0.2},
        }])
        text = path.read_text(encoding="utf-8")
        self.assertIn("1.500**", text)
        self.assertIn("(0.400)", text)
        self.assertIn(">40<", text)
        self.assertIn("pytohtml-note", text)


class RunnerTests(unittest.TestCase):
    def test_echoes_code_output_and_expression_value(self):
        tmp, status, log = _run(
            "print('观测', 3)\n"
            "1 + 2\n"
        )
        self.addCleanup(shutil.rmtree, tmp)
        self.assertEqual(status, 0)
        records = parse_transcript(log)
        outputs = [r["text"] for r in records if r["kind"] == "output"]
        values = [r["text"] for r in records if r["kind"] == "value"]
        sources = [r["source"] for r in records if r["kind"] == "stmt"]
        self.assertIn("观测 3", "\n".join(outputs))
        self.assertIn("3", values)
        self.assertTrue(any("1 + 2" in src for src in sources))

    def test_adjacent_statements_share_one_block_without_path_echo(self):
        tmp, status, _log = _run(
            "from python_tohtml.tables import summ\n"
            "a = 1\n"
            "b = 2\n"
            "print(a + b)\n"
            "summ('t.html', {'x': [1, 2, 3]})\n"
        )
        self.addCleanup(shutil.rmtree, tmp)
        self.assertEqual(status, 0)
        html, _md = render_log(tmp / "analysis.log", tmp / "report.html", None)
        body = html.split("<body>", 1)[1]
        self.assertEqual(body.count("language-python"), 2)
        self.assertIn("a = 1\nb = 2\nprint(a + b)", body)
        self.assertNotIn("<code>'t.html'</code>", body)

    def test_marker_calls_are_hidden_and_show_substitutes_in_order(self):
        tmp, status, log = _run(
            "from python_tohtml.ishere import h1, md, show\n"
            "h1('回归')\n"
            "show('b', '1.23')\n"
            "md('系数是 {b}。')\n"
            "show('b', '9.99')\n"
            "md('后来是 {b}。')\n"
        )
        self.addCleanup(shutil.rmtree, tmp)
        self.assertEqual(status, 0)
        html, _md = render_log(tmp / "analysis.log", tmp / "report.html", tmp / "report.md")
        self.assertIn("<h1>回归</h1>", html)
        self.assertIn("系数是 1.23。", html)
        self.assertIn("后来是 9.99。", html)
        self.assertNotIn("{b}", html)
        self.assertNotIn(">h1(", html)
        self.assertNotIn("show(", html)

    def test_printed_sentinel_does_not_break_the_log(self):
        tmp, status, log = _run(
            "print('@@@pytohtml output 1')\n"
            "print('STILL')\n"
            "from python_tohtml.ishere import h1\n"
            "h1('后')\n"
        )
        self.addCleanup(shutil.rmtree, tmp)
        self.assertEqual(status, 0)
        records = parse_transcript(log)
        text = "\n".join(r.get("text", "") for r in records)
        self.assertIn("STILL", text)
        self.assertTrue(any(r.get("kind") == "heading" and r.get("text") == "后" for r in records))

    def test_failure_keeps_the_partial_transcript_and_line(self):
        tmp, status, log = _run(
            "print('before-error')\n"
            "raise RuntimeError('boom-marker')\n"
        )
        self.addCleanup(shutil.rmtree, tmp)
        self.assertEqual(status, 1)
        self.assertIn("before-error", log)
        self.assertIn("boom-marker", log)
        self.assertIn("analysis.py", log)
        html, _md = render_log(tmp / "analysis.log", tmp / "report.html", None)
        self.assertIn("before-error", html)
        self.assertIn("boom-marker", html)
        self.assertIn("language-python", html)

    def test_clean_and_cleancode_drop_different_pieces(self):
        tmp, status, _log = _run(
            "from python_tohtml.ishere import h1, md\n"
            "h1('标题')\n"
            "print('只在完整记录里')\n"
            "md('正文留下。')\n"
            "x = 1 + 2\n"
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
        self.assertIn("language-python", code_body)
        self.assertIn("print(", code_body)
        self.assertNotIn("pytohtml-output", code_body)
        self.assertIn("highlight.min.js", code)

    def test_figure_is_embedded_and_missing_table_is_visible(self):
        tmp, status, _log = _run(
            "from pathlib import Path\n"
            "from python_tohtml.ishere import fig, tab\n"
            "Path('fig.svg').write_text('<svg xmlns=\"http://www.w3.org/2000/svg\"></svg>', encoding='utf-8')\n"
            "fig('fig.svg', title='散点')\n"
            "tab('missing.html', title='不存在')\n"
        )
        self.addCleanup(shutil.rmtree, tmp)
        self.assertEqual(status, 0)
        html, _md = render_log(
            tmp / "analysis.log",
            tmp / "report.html",
            None,
            embed=True,
        )
        self.assertIn("data:image/svg+xml;base64,", html)
        self.assertIn("散点", html)
        self.assertIn("找不到表", html)
        self.assertIn("tohtml-fig-title", html)
        self.assertIn("tohtml-table-title", html)


class ExampleTests(unittest.TestCase):
    def test_auto_price_report_ties_prose_to_the_estimate(self):
        script = ROOT / "examples" / "auto_price.py"
        html_path = ROOT / "examples" / "auto_price.html"
        log_path = ROOT / "examples" / "auto_price.log"
        md_path = ROOT / "examples" / "auto_price.md"
        status = run_script(script, log_path)
        self.assertEqual(status, 0)
        html, markdown = render_log(log_path, html_path, md_path)
        self.assertIn("剩余 45 个观测", html)
        self.assertIn(">45<", html)
        self.assertIn("价格回归", html)
        self.assertIn("pytohtml-table", html)
        self.assertIn("tohtml-embedded-table", html)
        self.assertIn('src="figures/price.svg"', html)
        self.assertNotIn("'results/regression.html'", html)
        self.assertIn("import math\nimport os\nimport random", html)
        self.assertIn("MathJax", html)
        self.assertNotIn("手写数字", html)
        self.assertIn("language-python", html)
        self.assertIn("原始观测 N = 48", html)
        self.assertRegex(html, r"每加仑英里数的系数为 -\d+\.\d+")
        first = _between(html, "每加仑英里数的系数为 ", "（标准误")
        second = _between(html, "同一系数也可以写成 ", "，标准误")
        self.assertEqual(first, second)

        clean, _ = render_log(log_path, ROOT / "examples" / "auto_price_clean.html", None, mode="clean")
        self.assertIn("剩余 45 个观测", clean)
        self.assertNotIn("def ols", clean)
        self.assertNotIn("原始观测", clean)
        self.assertIn(first, clean)
        self.assertIn("# 汽车价格", markdown)


def _between(text: str, start: str, end: str) -> str:
    i = text.index(start) + len(start)
    j = text.index(end, i)
    return text[i:j]


if __name__ == "__main__":
    unittest.main()

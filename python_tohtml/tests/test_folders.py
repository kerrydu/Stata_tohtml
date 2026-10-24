import tempfile
import unittest
from pathlib import Path

from python_tohtml.cli import main
from python_tohtml.folders import collect_resources, render_folders


class FolderCollectTests(unittest.TestCase):
    def test_several_directories_are_sorted_by_filename(self):
        root = Path(tempfile.mkdtemp())
        tables = root / "results"
        figures = root / "figures"
        nested = figures / "nested"
        tables.mkdir()
        figures.mkdir()
        nested.mkdir()
        (tables / "table_summary.html").write_text(
            '<table class="pytohtml-table"><tr><td>价格</td></tr></table>',
            encoding="utf-8",
        )
        (tables / "table_extra.md").write_text("| a | b |\n", encoding="utf-8")
        (tables / "notes.txt").write_text("忽略", encoding="utf-8")
        (tables / "Table_upper.html").write_text("<table></table>", encoding="utf-8")
        (figures / "figure_b.svg").write_text(
            '<svg xmlns="http://www.w3.org/2000/svg"></svg>',
            encoding="utf-8",
        )
        (figures / "figure_a.png").write_bytes(b"\x89PNG")
        (nested / "figure_hidden.svg").write_text("<svg></svg>", encoding="utf-8")
        (root / "other" ).mkdir()
        names = [item["name"] for item in collect_resources([tables, figures, tables])]
        self.assertEqual(
            names,
            ["figure_a.png", "figure_b.svg", "table_extra.md", "table_summary.html"],
        )

    def test_report_inlines_tables_and_zooms_figures(self):
        root = Path(tempfile.mkdtemp())
        folder = root / "output"
        folder.mkdir()
        (folder / "table_means.html").write_text(
            "<table><tr><td>价格</td></tr></table>",
            encoding="utf-8",
        )
        (folder / "figure_price.svg").write_text(
            '<svg xmlns="http://www.w3.org/2000/svg"></svg>',
            encoding="utf-8",
        )
        html, markdown = render_folders(
            [folder],
            root / "report.html",
            root / "report.md",
            zoom="80%",
        )
        body = html.split("<body>", 1)[1]
        self.assertIn("<h1>图和表</h1>", body)
        self.assertLess(body.index("figure_price.svg"), body.index("table_means.html"))
        self.assertIn('style="zoom:80%"', body)
        self.assertIn("<td>价格</td>", body)
        self.assertIn("### figure_price.svg", markdown)
        self.assertIn("# 图和表", markdown)

    def test_empty_directory_is_an_error(self):
        root = Path(tempfile.mkdtemp())
        folder = root / "empty"
        folder.mkdir()
        with self.assertRaises(ValueError):
            render_folders([folder], root / "report.html")

    def test_cli_accepts_paths_side_by_side(self):
        root = Path(tempfile.mkdtemp())
        one = root / "one"
        two = root / "two"
        one.mkdir()
        two.mkdir()
        (one / "table_one.html").write_text("<table><tr><td>甲</td></tr></table>", encoding="utf-8")
        (two / "figure_two.svg").write_text(
            '<svg xmlns="http://www.w3.org/2000/svg"></svg>',
            encoding="utf-8",
        )
        html = root / "out.html"
        status = main([
            "gather",
            str(one),
            str(two),
            "--html",
            str(html),
            "--width",
            "400px",
        ])
        self.assertEqual(status, 0)
        text = html.read_text(encoding="utf-8")
        self.assertIn("甲", text)
        self.assertIn('width="400px"', text)
        self.assertIn("figure_two.svg", text)
        self.assertTrue(html.with_suffix(".md").is_file())


if __name__ == "__main__":
    unittest.main()

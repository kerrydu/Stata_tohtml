import math
import tempfile
import unittest
from pathlib import Path

from python_tohtml.graphs import scatter
from python_tohtml.regress import _t_pvalue, regress
from python_tohtml.tables import etable, summarize


class SummarizeTests(unittest.TestCase):
    def test_writes_a_table_and_returns_the_same_numbers(self):
        folder = Path(tempfile.mkdtemp())
        path = folder / "summary.html"
        summary = summarize(str(path), {"价格": [1, None, 3, float("nan"), "x"]})
        text = path.read_text(encoding="utf-8")
        self.assertIn('class="pytohtml-table"', text)
        self.assertIn(">价格<", text)
        self.assertIn(">2<", text)
        self.assertEqual(summary["价格"].n, 2)
        self.assertAlmostEqual(summary["价格"].mean, 2.0)
        self.assertIn("2.000", text)

    def test_sample_sd_uses_n_minus_one(self):
        folder = Path(tempfile.mkdtemp())
        summary = summarize(str(folder / "s.html"), {"a": [1, 2, 3]})
        self.assertAlmostEqual(summary["a"].sd, 1.0)


class RegressTests(unittest.TestCase):
    def test_exact_line(self):
        y = [2 + 3 * x for x in range(6)]
        model = regress(y, {"x": list(range(6))})
        self.assertAlmostEqual(model.params["x"], 3.0)
        self.assertAlmostEqual(model.params["常数项"], 2.0)
        self.assertAlmostEqual(model.rsquared, 1.0)
        self.assertAlmostEqual(model.bse["x"], 0.0)
        self.assertLess(model.pvalues["x"], 1e-8)
        self.assertEqual(model.nobs, 6)

    def test_known_three_point_fit(self):
        model = regress([1, 2, 2], {"x": [1, 2, 3]})
        self.assertAlmostEqual(model.params["x"], 0.5)
        self.assertAlmostEqual(model.params["常数项"], 2 / 3)
        self.assertAlmostEqual(model.rsquared, 0.75)
        self.assertAlmostEqual(model.bse["x"], math.sqrt(1 / 12))
        self.assertAlmostEqual(model.pvalues["x"], 1 / 3, places=6)

    def test_listwise_deletion(self):
        model = regress([1, None, 3, 4], {"x": [1, 2, 3, 4]})
        self.assertEqual(model.nobs, 3)
        self.assertAlmostEqual(model.params["x"], 1.0)
        self.assertAlmostEqual(model.params["常数项"], 0.0)

    def test_t_critical_values(self):
        self.assertAlmostEqual(_t_pvalue(2.228, 10), 0.05, delta=0.001)
        self.assertAlmostEqual(_t_pvalue(1.96, 1000), 0.05, delta=0.002)
        self.assertAlmostEqual(_t_pvalue(math.sqrt(3), 1), 1 / 3, places=6)


class EtableTests(unittest.TestCase):
    def test_constant_is_last_and_stars_use_pvalues(self):
        folder = Path(tempfile.mkdtemp())
        path = folder / "reg.html"
        model = regress([2 + 3 * x for x in range(8)], {"油耗": list(range(8))})
        etable(str(path), [model], titles=["(1)"], note="因变量为价格。")
        text = path.read_text(encoding="utf-8")
        self.assertLess(text.index(">油耗<"), text.index(">常数项<"))
        self.assertIn("3.000***", text)
        self.assertIn("(0.000)", text)
        self.assertIn(">8<", text)
        self.assertIn("因变量为价格。", text)
        self.assertIn("pytohtml-note", text)
        self.assertIn("stat-start", text)

    def test_two_models_keep_new_regressors_above_the_constant(self):
        folder = Path(tempfile.mkdtemp())
        path = folder / "reg.html"
        x = list(range(6))
        z = [1, 4, 2, 5, 3, 0]
        y = [1 + xi + 2 * zi for xi, zi in zip(x, z)]
        m1 = regress(y, {"x": x})
        m2 = regress(y, {"x": x, "z": z})
        etable(str(path), [m1, m2], titles=["(1)", "(2)"])
        text = path.read_text(encoding="utf-8")
        self.assertLess(text.index(">x<"), text.index(">z<"))
        self.assertLess(text.index(">z<"), text.index(">常数项<"))


class ScatterTests(unittest.TestCase):
    def test_writes_axes_points_and_a_fit_line(self):
        folder = Path(tempfile.mkdtemp())
        path = folder / "price.svg"
        scatter(str(path), [1, 2, 3, None], [1, 2, 4, 9], xlabel="油耗", ylabel="价格", fit=True)
        text = path.read_text(encoding="utf-8")
        self.assertTrue(text.startswith("<svg"))
        self.assertEqual(text.count("<circle "), 3)
        self.assertIn(">油耗<", text)
        self.assertIn(">价格<", text)
        self.assertIn("<line ", text)
        self.assertIn("clip-path", text)

    def test_skips_the_line_when_x_does_not_vary(self):
        folder = Path(tempfile.mkdtemp())
        path = folder / "flat.svg"
        scatter(str(path), [1, 2, 3], [5, 5, 5], fit=True)
        text = path.read_text(encoding="utf-8")
        self.assertEqual(text.count("<circle "), 3)
        self.assertNotIn('stroke="#0969da"', text)


if __name__ == "__main__":
    unittest.main()

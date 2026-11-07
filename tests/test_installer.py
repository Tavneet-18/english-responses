import contextlib
import io
from pathlib import Path
import tempfile
import unittest

import english_responses as app


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name)

    def run_cli(self, *args):
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            return app.run([args[0], str(self.repo), *args[1:]])

    def test_preserves_chinese_bom_crlf_and_no_trailing_newline(self):
        for original in [b"", "# 中文要求\r\n运行测试".encode(), b"\xef\xbb\xbf# Original\r\n"]:
            with self.subTest(original=original):
                path = self.repo / "AGENTS.md"
                path.write_bytes(original)
                self.assertEqual(self.run_cli("install"), 0)
                installed = path.read_bytes()
                self.assertTrue(installed.startswith(original))
                self.assertEqual(self.run_cli("install"), 0)
                self.assertEqual(path.read_bytes(), installed)
                self.assertEqual(self.run_cli("remove"), 0)
                self.assertEqual(path.read_bytes(), original)

    def test_preserves_later_user_edits(self):
        path = self.repo / "AGENTS.md"
        self.run_cli("install")
        path.write_bytes(path.read_bytes() + b"\n# Added by user\n")
        self.assertEqual(self.run_cli("remove"), 0)
        self.assertEqual(path.read_bytes(), b"\n# Added by user\n")

    def test_preview_and_status_do_not_write(self):
        self.assertEqual(self.run_cli("install", "--dry-run"), 0)
        self.assertEqual(self.run_cli("status"), 0)
        self.assertEqual(list(self.repo.iterdir()), [])

    def test_bad_markers_and_non_utf8_are_not_overwritten(self):
        path = self.repo / "AGENTS.md"
        for data in [app.START, app.END, app.BLOCK * 2, b"\xff\xfe", app.END + app.START]:
            path.write_bytes(data)
            self.assertEqual(self.run_cli("install"), 1)
            self.assertEqual(self.run_cli("remove"), 1)
            self.assertEqual(path.read_bytes(), data)

    def test_alternate_file_and_missing_repo(self):
        self.assertEqual(self.run_cli("install", "--file", "CLAUDE.md"), 0)
        self.assertTrue((self.repo / "CLAUDE.md").exists())
        self.assertFalse((self.repo / "AGENTS.md").exists())
        with contextlib.redirect_stderr(io.StringIO()):
            self.assertEqual(app.run(["install", str(self.repo / "missing")]), 1)


if __name__ == "__main__":
    unittest.main()

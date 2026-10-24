import importlib.util
from pathlib import Path
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'tools' / 'WrapPrivateerBeta.py'
spec = importlib.util.spec_from_file_location('beta_wrapper', SCRIPT)
wrapper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(wrapper)


class BetaExportTest(unittest.TestCase):
    def test_export_is_windowed_with_independent_ad_and_feedback(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'index.html'
            path.write_text('''<head></head><body><canvas id="canvas"></canvas>
<script>function displayFailureNotice(err) {console.log(err)}
function ready() {setStatusMode('hidden');}</script></body>''')
            wrapper.wrap(path, 'abc123')
            html = path.read_text()
            game = (path.parent / 'game.html').read_text()
            self.assertIn('data-build="abc123"', html)
            self.assertIn('id="ad-support-strip"', html)
            self.assertIn('id="feedback-form"', html)
            self.assertIn("fullscreen 'none'", html)
            self.assertIn('window.location.replace', game)
            self.assertIn('privateer-ready', game)
            self.assertIn('privateer-failed', game)
            self.assertIn('id="canvas"', game)
            self.assertTrue((path.parent / 'feedback.mjs').is_file())
            with self.assertRaises(ValueError):
                wrapper.wrap(path, 'abc123')

    def test_incompatible_export_fails_before_publishing(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'index.html'
            path.write_text('<head></head>missing canvas')
            with self.assertRaises(AssertionError):
                wrapper.wrap(path, 'abc123')


if __name__ == '__main__':
    unittest.main()

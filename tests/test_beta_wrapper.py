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
            self.assertIn('dmc-game-ready', game)
            self.assertIn('dmc-game-failed', game)
            self.assertIn('id="canvas"', game)
            self.assertTrue((path.parent / 'feedback.mjs').is_file())
            with self.assertRaises(ValueError):
                wrapper.wrap(path, 'abc123')

    def test_classic_and_breach_have_complete_independent_pages(self):
        fixtures = {
            'classic': '<head></head><canvas id="canvas"></canvas><script>function displayFailureNotice(err) {} function ready() {setStatusMode(\'hidden\');}</script>',
            'breach': '<head></head><canvas id="game"></canvas><script type="module">requestAnimationFrame(frame);</script>',
        }
        for key, original in fixtures.items():
            with self.subTest(game=key), tempfile.TemporaryDirectory() as directory:
                path = Path(directory) / 'index.html'
                path.write_text(original)
                wrapper.wrap(path, 'build789', key)
                html = path.read_text()
                game = (path.parent / 'game.html').read_text()
                self.assertIn(f'data-game-name="{wrapper.PROFILES[key]["GAME_NAME"]}"', html)
                self.assertIn('src="../ad-support/?layout=20261027"', html)
                self.assertIn('id="feedback-form"', html)
                self.assertIn('id="download-report"', html)
                self.assertIn("fullscreen 'none'", html)
                self.assertIn('href="../"', html)
                self.assertNotIn('qGWZf', html)
                self.assertNotIn('APK', html)
                self.assertNotRegex(html, r'__[A-Z_]+__')
                self.assertIn('dmc-game-ready', game)
                self.assertIn('window.top===window.self', game)
                self.assertTrue((path.parent / 'beta.js').is_file())
                if key == 'classic':
                    self.assertEqual((path.parent / 'play.html').read_text(), game)
                else:
                    self.assertGreater(game.rfind('dmc-game-ready'), game.rfind('requestAnimationFrame(frame);'))

    def test_breach_rejects_missing_game_module_without_overwriting(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'index.html'
            original = '<head></head><canvas id="game"></canvas>'
            path.write_text(original)
            with self.assertRaises(AssertionError):
                wrapper.wrap(path, 'test', 'breach')
            self.assertEqual(path.read_text(), original)
            self.assertFalse((path.parent / 'game.html').exists())

    def test_incompatible_export_fails_before_publishing(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'index.html'
            path.write_text('<head></head>missing canvas')
            with self.assertRaises(AssertionError):
                wrapper.wrap(path, 'abc123')


if __name__ == '__main__':
    unittest.main()

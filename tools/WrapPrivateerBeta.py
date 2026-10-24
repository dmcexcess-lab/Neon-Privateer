"""Install the public beta shell around a Godot export, preserving its assets."""
from pathlib import Path
import shutil
import sys

def wrap(path: Path, build: str):
    original = path.read_text()
    if 'id="flight-deck"' in original:
        raise ValueError('Privateer beta wrapper already present')
    assert 'id="canvas"' in original and '</head>' in original
    guard = '''<script>
if(window.top===window.self){window.location.replace('./')}
document.addEventListener('fullscreenchange',()=>{if(document.fullscreenElement)document.exitFullscreen().catch(()=>{})});
</script>'''
    original = original.replace('</head>', guard + '\n</head>', 1)
    # Announce actual engine startup, not just the iframe's HTML load event.
    marker = "setStatusMode('hidden');"
    assert marker in original
    original = original.replace(marker, marker + "\nwindow.parent.postMessage('privateer-ready', window.location.origin);", 1)
    failure = 'function displayFailureNotice(err) {'
    assert failure in original
    original = original.replace(failure, failure + "\nwindow.parent.postMessage('privateer-failed', window.location.origin);", 1)
    (path.parent / 'game.html').write_text(original)
    source = Path(__file__).resolve().parents[1] / 'web' / 'beta'
    for item in source.iterdir():
        if item.is_file():
            if item.name == 'index.html':
                path.write_text(item.read_text().replace('__BUILD__', build))
            else:
                shutil.copy2(item, path.parent / item.name)
    print('Neon Privateer windowed public beta, ad strip and copyable feedback installed')

if __name__ == '__main__':
    wrap(Path(sys.argv[1]), sys.argv[2])

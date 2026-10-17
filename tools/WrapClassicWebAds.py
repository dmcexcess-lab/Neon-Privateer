"""Frame the free Classic export with a persistent, separate advertising strip."""
from pathlib import Path
import sys
path = Path(sys.argv[1])
original = path.read_text()
if 'id="ad-support-strip"' in original:
    raise SystemExit('Classic advertising wrapper already present')
assert 'id="canvas"' in original and '</head>' in original
# The engine keeps its native canvas resize behavior inside the smaller game frame.
# A direct visit to this unlisted engine page returns to the advertising wrapper.
guard = "<script>if(window.top===window.self){window.location.replace('./')}document.addEventListener('fullscreenchange',function(){if(document.fullscreenElement){document.exitFullscreen().catch(function(){})}});</script>"
(path.parent/'play.html').write_text(original.replace('</head>',guard+'\n</head>',1))
path.write_text('''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover"><title>Neon Driftline Classic</title><style>html,body{margin:0;padding:0;width:100%;height:100%;overflow:hidden;background:#080b14}body{display:grid;grid-template-rows:128px minmax(0,1fr)}iframe{display:block;width:100%;height:100%;border:0;min-height:0}#ad-support-strip{background:#101324}</style></head><body><iframe id="ad-support-strip" src="../ad-support/?layout=20261017" title="Advertising supports the free game" sandbox="allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox"></iframe><iframe id="classic-game" src="./play.html" title="Neon Driftline Classic game" allow="autoplay; fullscreen 'none'"></iframe></body></html>''')
print('Classic free Web build includes persistent advertising strip')

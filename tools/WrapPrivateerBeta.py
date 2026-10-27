"""Install the same windowed beta page around each game's unmodified export."""
from pathlib import Path
import re
import json
import shutil
import sys

PROFILES = {
 'privateer': {
  'GAME_NAME': 'Neon Privateer', 'GAME_SLUG': 'neon-privateer',
  'DESCRIPTION': 'Play the Neon Privateer public beta. Trade across 32 generated worlds, survive the flight, and tell DMC Oddworks what breaks.',
  'HEADING': '<h1>NEON <span>PRIVATEER</span></h1>',
  'LEDE': 'Thirty-two worlds. A hold full of cargo.<br>One more flight before you bank the money.',
  'OVERVIEW': 'Trade, take contracts, upgrade the ship and pick your route. Lose the ship and everything aboard goes with it. The bank survives.',
  'LAUNCH_EYEBROW': 'THE PORT IS OPEN',
  'READY_TEXT': 'Port online. Tap inside the game for sound.',
  'CLOSED_TEXT': 'Game closed. Your last saved career stays in this browser.',
  'GUIDE_HEADING': 'Get paid.<br>Get back.',
  'GUIDE': '<li><b>Start a career.</b> Pick a save slot, then tap PORT / OPERATIONS on the planet portrait for walking contacts, field gear and the objective journal. Progress stays in this browser; clearing saved data can erase it.</li><li><b>Follow a lead.</b> Track a bounty through rumors, eavesdropping and safehouse hacking, or choose a direct combat sweep. Extract field intel to advance the contract. Getting caught starts a prison escape; recover your gear or pay a release fine.</li><li><b>Check the route.</b> Buy cargo or take a contract, choose a reachable destination and check your fuel.</li><li><b>Fly the ship.</b> Use the on-screen LEFT, DASH and RIGHT buttons. Toggle WEAPONS ON/OFF in flight, or press H. Equipped weapons fire automatically while enabled. Pause before stepping away.</li><li><b>Protect the money.</b> Banked money and investments survive ship loss. Cash, cargo, passengers, upgrades and weapons aboard do not.</li>',
  'MUSIC_HEADING': 'A soundtrack for the waiting.<br>A soundtrack for the run.',
  'MUSIC': '<div><dt>SPACEPORT + MENUS</dt><dd>Do Androids Dream</dd></div><div><dt>SPACEFLIGHT</dt><dd>Nineteen Steps</dd></div>',
 },
 'firewall': {
  'GAME_NAME': 'Neon Firewall', 'GAME_SLUG': 'neon-firewall',
  'DESCRIPTION': 'Neon Firewall: procedural neon brick-breaking, persistent research, run upgrades and three save profiles. Keep your credits on death.',
  'HEADING': '<h1>NEON <span>FIREWALL</span></h1>',
  'LEDE': 'Break the wall.<br>Keep the credits.',
  'OVERVIEW': 'Procedural security grids grow denser and tougher. Break armored caches, unlock relays and survive bonus drops that can help or hurt. Research permanent upgrades or spend in the store between levels.',
  'LAUNCH_EYEBROW': 'PACKET BREAKER / PROCEDURAL ARCADE',
  'READY_TEXT': 'Firewall online. Three profiles, permanent research and run upgrades. Tap inside for sound.',
  'CLOSED_TEXT': 'Connection closed. Your last saved profile, credits and active run stay in this browser.',
  'GUIDE_HEADING': 'Break in.<br>Build up.',
  'GUIDE': '<li><b>Move the paddle.</b> Mouse, touch drag, A/D or arrow keys. Click, tap or Space launches the balls. P or Escape pauses.</li><li><b>Read the grid.</b> Numbers are armor. Green relays unlock red # nodes. Gold ? caches hide cash and drops. Steel X blocks cannot break; phased bricks turn intangible. Later grids move and fire back.</li><li><b>Catch carefully.</b> Green + capsules help; red ! capsules shrink the paddle, reverse controls, accelerate balls or increase trace. Lasers fire with Space, click or the LASER button; magnets catch balls for relaunch.</li><li><b>Keep your earnings.</b> Credits survive death. Permanent research applies to new runs. Between-level purchases last for the current run. Save/load profiles separately; pause or background to save an active run. The same game is also in Privateer at NETWORK / NEON FIREWALL.</li>',
  'MUSIC_HEADING': 'One soundtrack.<br>Every security layer.',
  'MUSIC': '<div><dt>MENUS + GAMEPLAY</dt><dd>Nineteen Steps</dd></div>',
 },
 'classic': {
  'GAME_NAME': 'Neon Driftline Classic', 'GAME_SLUG': 'neon-driftline-classic',
  'DESCRIPTION': 'Play Neon Driftline Classic free in a window, with Nineteen Steps on the soundtrack and a downloadable playtest report.',
  'HEADING': '<h1>NEON <span>DRIFTLINE</span></h1>',
  'LEDE': 'Pick a loadout. Dodge the next wave.<br>See how far one more run takes you.',
  'OVERVIEW': 'The original arcade game: steer, dash, unlock weapons and improve your ship. Free browser play, with Nineteen Steps looping through the run.',
  'LAUNCH_EYEBROW': 'CLASSIC / ARCADE FLIGHT',
  'READY_TEXT': 'Classic online. Tap inside the game for sound.',
  'CLOSED_TEXT': 'Game closed. Saved Classic progress stays in this browser; resume through the game menu when available.',
  'GUIDE_HEADING': 'Dodge.<br>Dash. Repeat.',
  'GUIDE': '<li><b>Choose a loadout.</b> Start at the title screen. Research and weapon choices carry between runs when saved.</li><li><b>Steer and dash.</b> Use the on-screen LEFT, DASH and RIGHT controls. Equipped weapons fire automatically.</li><li><b>Use the shop.</b> Spend run earnings on repairs and upgrades between stages. Read the prices before buying.</li><li><b>Pause in the game.</b> Use its pause control before stepping away. Closing the window stops the game; clearing browser data can erase saved progress.</li>',
  'MUSIC_HEADING': 'One track.<br>Keep the run moving.',
  'MUSIC': '<div><dt>MENUS + GAMEPLAY</dt><dd>Nineteen Steps</dd></div>',
 },
 'breach': {
  'GAME_NAME': 'Neon Breach', 'GAME_SLUG': 'neon-breach',
  'DESCRIPTION': 'Play Neon Breach, a free twin-stick stealth survivor. Deploy from Resistance HQ, climb through procedural floors and send a downloadable playtest report.',
  'HEADING': '<h1>NEON <span>BREACH</span></h1>',
  'LEDE': 'The credits are safe.<br>The gear you took underground is not.',
  'OVERVIEW': 'Deploy from Resistance HQ into sewer tunnels and a guarded archaeological dig. Sneak, fight, find credits and decide when to extract.',
  'LAUNCH_EYEBROW': 'THE ASCENT / TACTICAL SURVIVAL',
  'READY_TEXT': 'Breach v1.3.0 online. Save/load and Sound Settings are in the game menu.',
  'CLOSED_TEXT': 'Game closed. Saved credits, HQ storage and best floor stay in this browser. Use Save Game in the in-game menu to keep an active sortie.',
  'GUIDE_HEADING': 'Bring gear.<br>Bring it back.',
  'GUIDE': '<li><b>Enter HQ.</b> Move with WASD or arrows and press E at a station. On touch, use the movement stick and INTERACT.</li><li><b>Choose a route through the floor.</b> Move with WASD, aim with the mouse and click to attack. On touch, use the two sticks, with STEALTH beside movement and DRAW/HOLSTER beside aiming. H toggles drawing on desktop. Holstered weapons and hands cannot attack. Hold right-click or Shift to sneak; C toggles sneak; F uses a carried repair kit. The menu has Save, Load and Sound Settings.</li><li><b>Read the radar.</b> M enlarges the map when radar is equipped. Sight lines and cover matter; enemies keep moving outside your view.</li><li><b>Extract or keep climbing.</b> Enter the EXFIL marker, then hold its larger ring for 8 seconds. Every hostile converges; leaving cancels the timer. Stairs continue the sortie. Death loses deployed equipment but keeps credits and HQ storage. Escape pauses.</li>',
  'MUSIC_HEADING': 'From the safe room<br>to the next floor.',
  'MUSIC': '<div><dt>RESISTANCE HQ + THE ASCENT</dt><dd>Nineteen Steps</dd></div>',
 },
}

def wrap(path: Path, build: str, game: str = 'privateer'):
    profile = PROFILES[game]
    original = path.read_text()
    if 'id="flight-deck"' in original:
        raise ValueError('Beta wrapper already present')
    assert '</head>' in original
    if game == 'breach':
        assert '<canvas id="game"' in original and 'requestAnimationFrame(frame);' in original
    else:
        assert 'id="canvas"' in original
        assert "setStatusMode('hidden');" in original
        assert 'function displayFailureNotice(err) {' in original
    guard = '''<script>
if(window.top===window.self){window.location.replace('./')}
window.addEventListener('error',()=>window.parent.postMessage('dmc-game-failed',window.location.origin));
</script>'''
    original = original.replace('</head>', guard + '\n</head>', 1)
    ready = "\nwindow.parent.postMessage('dmc-game-ready', window.location.origin);"
    if game == 'breach':
        end = original.rfind('</script>')
        original = original[:end] + ready + '\n' + original[end:]
    else:
        original = original.replace("setStatusMode('hidden');", "setStatusMode('hidden');" + ready, 1)
        original = original.replace('function displayFailureNotice(err) {', 'function displayFailureNotice(err) {\nwindow.parent.postMessage(\'dmc-game-failed\', window.location.origin);', 1)
    source = Path(__file__).resolve().parents[1] / 'web' / 'beta'
    values = dict(profile, BUILD=build, AD_PATH='./ad-support/' if game == 'privateer' else '../ad-support/')
    destinations = {'privateer': './' if game == 'privateer' else '../', 'classic': './classic/' if game == 'privateer' else '../classic/', 'breach': './breach/' if game == 'privateer' else '../breach/', 'firewall': './firewall/' if game == 'privateer' else '../firewall/'}
    values['GAME_LINKS'] = ''.join(f'<a href="{destinations[key]}">{PROFILES[key]["GAME_NAME"]} ↗</a>' for key in PROFILES if key != game)
    page = (source / 'index.html').read_text()
    for key, value in values.items():
        page = page.replace('__' + key + '__', value)
    assert not re.search(r'__[A-Z_]+__', page), 'Unresolved page template field'
    (path.parent / 'game.html').write_text(original)
    if game == 'classic':
        # Existing embedded play.html URLs and save origin continue to work.
        (path.parent / 'play.html').write_text(original)
    path.write_text(page)
    for name in ('beta.css', 'beta.js', 'feedback.mjs', 'fullscreen.mjs', 'touch-icon.png'):
        shutil.copy2(source / name, path.parent / name)
    (path.parent / 'manifest.webmanifest').write_text(json.dumps({
        'name': profile['GAME_NAME'], 'short_name': profile['GAME_NAME'],
        'id': './', 'start_url': './?homescreen=1#flight-deck', 'scope': './',
        'display': 'standalone', 'orientation': 'landscape' if game == 'breach' else 'any',
        'background_color': '#050a13', 'theme_color': '#0a1019',
        'icons': [{'src': 'touch-icon.png', 'sizes': '180x180', 'type': 'image/png'}]
    }, indent=2))
    print(f'{profile["GAME_NAME"]}: windowed beta, ad strip and copy/download feedback installed')

if __name__ == '__main__':
    wrap(Path(sys.argv[1]), sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else 'privateer')

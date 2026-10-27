# Neon Breach v1.3.0 — recovered features and mobile play

Play: https://dmcexcess-lab.github.io/Neon-Privateer/breach/

The downloaded `Neon_Breach_Manual_Shotgun_v1.0.zip` contained features that
had never reached this repository. This version merges that source with the
subsequent full-floor AI, rotating posts, stronger zombie awareness, doubled
shop prices (knife unchanged), and eight-second alarm extraction. Source now
lives in `src/`; `index.html` is a reproducible self-contained build. CI rebuilds
it and rejects a stale generated file before deployment.

## Recovered and corrected

- New Game, Continue, Load Save and Sound Settings on the title screen. The
  HQ/pause menu has Save Game, Load Save, separate Music/SFX switches and
  volume controls. New Game asks before clearing a career.
- HQ purchases and loadout autosave together. Manual mission saves retain
  enemies, opened chests, destroyed cover, magazines/reloads, bullets and
  extraction progress. Navigation caches are rebuilt, not serialized with a
  circular world reference. Backgrounding pauses and saves the game.
- Magazines and automatic reloads: six-round revolver (individual rounds),
  16-round auto pistol and 30-round AR (magazine change). No manual R reload
  and no reserve-ammunition pickups. Reloads have sounds, HUD progress and
  character animation.
- Shotgun: click to fire five randomly spread pellets; release/click to pump.
  Five shells per magazine; when empty, five separate insertions followed by
  the final rack. Holding fire does not perform the pump for you.
- Player/enemy footsteps, occasional creature sounds, gun and mechanism SFX.
  One looping Nineteen Steps player continues across game states. The embedded
  MP3 also supports older iPhone Safari versions that cannot play Ogg Vorbis.
- HQ checkpoint insertion at floors 1/11/21/31 for 0/100/1,000/10,000 credits.
  Reach each checkpoint before it becomes selectable; fares apply each time.
- Floors 1–10: sewers; 11–20: maintenance; 21–30: lower archaeology (no
  zombies, more cover); 31+: upper archaeology (sparse cover, more chests).
  Size and enemy budgets increase, with explicit deep-floor caps.
- First guard appears on a career's randomly chosen floor 7 or 8: posted
  knife-equipped diamond. Floor 10 adds two melee patrollers and one ranged
  patroller alongside the post. Later guards get progressively stronger guns,
  and ranged guards can shelter behind cover and peek to fire.
- Three base hit points, at most six with the best vest. Repair kits restore
  one hit point, including vest capacity; five-kit carry limit. Creatures
  award credits only. Destroyed furniture has a 0.5% supply/cache chance.
- Lower completion cash, a smaller one-time all-hostiles-clear reward, and
  a larger no-alerts completion bonus. Enemy placement uses one global floor pass with wide spacing, rather than room quotas.

## Awareness and cash bonuses (v1.2.1)

- Red zombies recognize stationary targets up to 420 units ahead (previously
  760), or moving targets up to about 496 (previously 897). Their forward cone
  is 129.6 degrees, down from 172.8. Hearing, chase speed and other enemies'
  awareness are unchanged; sneaking still shortens recognition range.
- A `?` (suspicion/investigation) does **not** forfeit the large bonus. Any `!`
  does, including an alert that immediately ends or an alerted enemy killed
  before the next AI update. This history persists across save/load and resets
  only on entering a new floor. Extraction's intentional alarm also counts.
- Kill-all cash is paid immediately once per floor: 35% of the normal sector
  completion award, rounded, with a minimum of 3 credits. No-alerts cash is
  paid on taking the stairs: three times the completion award (`8 + 3 × floor`).
  At sectors 1 / 10 / 30, kill-all pays 4 / 13 / 34 credits and no-alerts pays
  33 / 114 / 294 credits, in addition to normal completion cash. Both bonuses
  can be earned together if kills never trigger a full alert.

## Fullscreen and iPhone

All three game pages offer Full screen. Native Element fullscreen is used
when allowed; unsupported/denied requests expand the existing iframe to the
viewport. Neither path creates a new game instance. Exit remains accessible.
The existing ad panel and consent choices remain on the regular page.

On iPhone: Safari → Share → Add to Home Screen → enable Open as Web App
if offered. Open that icon, launch the game, tap Full screen and turn the
phone sideways. Disable Portrait Orientation Lock in Control Center.
The manifest requests landscape, and the button tries orientation lock where
available; Safari/OS restrictions may still require manual rotation. No
claim of a forced iPhone orientation lock or physical-device verification.
Home Screen storage can be separate from Safari tab storage; use the same
launch mode consistently. No offline service worker is installed.

## Build and test

```sh
node neon-breach/src/build-standalone.mjs
node --test tests/neon_breach.test.mjs tests/breach_dungeon.test.mjs tests/fullscreen.test.mjs tests/beta_feedback.test.mjs
python3 -m unittest discover -s tests -p test_beta_wrapper.py
```

The geometry suite checks 1,520 seeded floors; runtime tests cover restored
features plus the full-map AI and eight-second extraction regressions. Node
AI timings do not establish physical iPhone frame rates. The Pages workflow
also runs the existing Privateer/Classic Godot smoke, soundtrack and Classic
balance tests, then exports all three Web pages. Privateer and Classic
Godot gameplay/audio and Android advertising are unchanged.

## Whole-floor population and patrol correction (v1.2)

Earlier randomization still assigned spawn quotas to rooms. That system has
been removed. A single population is placed over the union of walkable floor
space, repeatedly filling the largest uncovered gaps. Only a 180-unit arrival
bubble and small exit/exfil marker pads are protected; the whole starting
architectural room is no longer excluded. Splitting the same terrain into one
room or many produces the same placements. Spawn count and credits are unchanged.

Patrollers use a predictable circuit covering the floor, with initial phases
chosen near their dispersed positions and opposite travel directions. Random
wander destinations are distant floor-wide points. The posted guard remains
stationary. Transient local paths steer around cover; no distance sleeping or
room-entry spawning is used. A room is not announced safe merely because its
original spawns have been killed elsewhere.

Older active saves retain enemy positions, health, loot and combat state, while
old patrols are migrated to the global circuit. New placement applies on newly
generated floors: reload the page and enter a new floor/sortie to see it.

Additional checks:

```sh
node --test tests/breach_spawns.test.mjs
```

These compare room decomposition invariance and check 144 seeded floors for
full population, clear body placement, spacing, near-entry presence, uncovered
areas and exit concentration. Runtime regressions include actual traversal of
all lower-floor and upper-archaeology regions, not just route membership.

## Desktop stealth input (v1.2.2)

Hold the right mouse button over the game to sneak; release it to stop. Left
click still attacks and can be held independently while sneaking. The canvas
suppresses the browser context menu. Shift remains a hold alternative and C
remains a toggle; the phone SNEAK toggle and gamepad L3 also remain available.
Losing focus, hiding the tab, pointer cancellation or pausing releases mouse
buttons so stealth/attacks cannot remain stuck after an interrupted gesture.


## Draw / holster (v1.3.0)

Touch controls have separate STEALTH and DRAW/HOLSTER buttons beside their respective sticks in landscape; portrait stacks them above the sticks. Targets are at least 44px high and account for the iPhone safe area. H toggles drawing on desktop. The right stick can aim while holstered, but it cannot fire, swing fists/knife, or pump a shotgun. Drawing clears buffered attack presses. Holster state is saved with the mission; legacy saves keep their existing drawn behavior. Right mouse / Shift still hold stealth; C toggles it.

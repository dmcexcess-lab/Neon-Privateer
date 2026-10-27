# Neon Firewall

A standalone neon brick-breaker and the actual native hacking arcade inside Neon Privateer.

Play: https://dmcexcess-lab.github.io/Neon-Privateer/firewall/

Privateer: dock, then choose **NETWORK / NEON FIREWALL**. The same Godot view and simulation run in-process, using that career's carried cash and saved hacking research. There is no external link, iframe between games, or second Privateer currency. The standalone Web export has its own three profiles. Standalone Breach and Classic remain independent.

## Progression and saves

- Credits from destroyed nodes, armored caches and level clears enter the persistent wallet. Death keeps all credits and research.
- Permanent research applies to **new runs**. Six tracks: paddle width, ball damage, starting multiball, extra starting lives, a replenishing per-level floor shield, and per-level laser ammunition.
- Clearing a level opens a store. Cheaper versions of those six upgrades stack with research for the remainder of the current run. Buying a retry grants one life immediately; other purchases activate on the following level. A new run resets all run upgrades and keeps the remaining wallet and research.
- Research has escalating prices and explicit caps. Runs start with one ball, 3 lives, 1 damage, a 76-unit paddle and no shields/lasers before upgrades.
- Three standalone profiles each retain credits, research, best level, clears, deaths and the exact active run. No existing profile is erased when selecting another. New Run asks for a second confirmation when replacing an active run.
- Autosave every five seconds while playing, plus purchases, new runs, level clears, death, pause and focus loss. Pause also has a manual Save Game button. Continue restores the board, damaged nodes, balls, RNG, drops, projectiles, timers, credits already counted and temporary upgrades. A restored run waits for deliberate Continue.
- Standalone profile saves write to a temporary file before replacement; packed Variant data retains full floating-point/RNG precision. Credits already credited are saved alongside run progress, so resuming cannot pay the same nodes again.
- Privateer stores research/run ledger and its cash in the same career meta ConfigFile. Terminal failure preserves cash; ordinary Privateer **ship destruction still loses carried cash** under the existing rules. Protected bank money is never spent by this game, and hacking research survives ship loss.

## Procedural security grids

Seeded mirrored patterns and cutouts vary every new run. Boards expand from 7 columns / 4 rows toward 10 columns / 12 rows, capped to remain readable on phones. Armor, ball speed, turret rate and trace pressure increase with level. Width/speed/entity caps bound performance while armor can keep growing. This is an endless arcade progression, not a finite campaign.

- Normal nodes: break for cash; armor shows remaining hits.
- Gold `?` caches: stronger armor hides a real cash cache and a random capsule until broken.
- Blast nodes (level 2+): damage nearby nodes and trigger real explosive chains.
- Prism nodes (3+): split active balls.
- Green relay / red locked nodes (4+): destroy every live relay to unlock the `#` nodes.
- Phase nodes (5+): cycle between solid and intangible.
- Moving rows (6+): synchronized lateral motion within reserved margins.
- Steel nodes (7+): indestructible obstacles, excluded from clear requirements.
- Turrets (8+): shoot downward bolts; shields can absorb hits.

A stage clear pays `100 + 30 × level`, in addition to node/cache earnings. Missing the final ball costs one life. Other multiballs can remain in play. Floor shields rescue individual missed balls. Trace expiration or a turret hit also costs one life. Read the trace timer; it pauses with the game.

## Capsules

Green `+` capsules: wider paddle, multiball, slow balls, extra shield, laser ammunition, extra life or magnetic catches. Click/tap/Space releases caught balls.

Red `!` capsules: smaller paddle, faster balls, reversed paddle input or +20 seconds of trace. Width/speed/input effects expire after 12 active seconds. Helpful and harmful capsules have distinct colors and marks; cache contents are intentionally hidden before destruction. Multiball caps at 12 simultaneous balls.

## Controls and presentation

Mouse movement, A/D, arrows or touch dragging moves the paddle. Click, tap or Space launches; Space/click also fires lasers when available. Dedicated LAUNCH, LASER and PAUSE touch targets remain below the playfield. P/Escape toggles pause. Losing focus pauses automatically.

Geometric cyan/magenta rendering, glow, armored node marks, particle breaks, ball trails, credit floats and procedural pooled SFX follow Classic's visual language. Nineteen Steps loops in the standalone version. The embedded game uses Privateer's existing soundtrack and does not start a second music player. Its sound toggle controls terminal SFX; standalone Sound controls SFX and music.

The public page uses the existing consent-based ad/house-promo strip, fullscreen controls and downloadable/copyable feedback form. No new advertising mechanism is introduced.

## Validation

Godot 4.7.2:

```
godot --headless --editor --path neon-firewall --quit
godot --headless --path neon-firewall --script res://tests/SmokeTest.gd
godot --headless --path . --script res://tests/FirewallIntegrationTest.gd
```

Run tests with an isolated user-data directory (e.g. a task-specific XDG_DATA_HOME using a non-self-contained Godot installation). The standalone suite exercises 400 generated boards, ball collisions, damage, relays, explosive chains, caches, bonus/hazard effects, lasers, shields, multiball losses, magnets, deterministic continuation, death/research/run-store rules, profiles and pause. Integration checks real cash/bank accounting, career isolation, native transitions, saved-run continuity, payout idempotence and interruption handling. Existing Privateer, Breach and Classic regression suites remain required. CI exports the standalone game and runs the tests against its exported PCK.

Physical iPhone/Android testing and longer economy/difficulty tuning remain playtest work; automated tests do not establish physical-device performance.

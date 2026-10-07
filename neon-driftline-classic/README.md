# Neon Driftline

A phone-first Godot arcade roguelite with persistent research between runs.

## True starting baseline

A fresh run now begins deliberately weak:

- **2 hits**
- **No weapon**
- **No shield**
- **Slow ship:** base level/world scroll multiplier is 0.72×
- **Short dash:** 160 px base distance at 700 px/s

The first level remains the easiest: sparse lazy circles, one short station split, and no advanced enemies.

## Permanent research

All score still held when a run ends is banked into persistent Research currency. Quitting through the pause screen also banks the current score.

### Ship Speed

Each level adds:

- +4% world/level scroll speed
- +4% left/right steering speed
- ordinary near-miss score scales proportionally with actual Ship Speed

Because level progress uses world scroll speed, a faster researched ship reaches the end of levels sooner in real time and faces faster incoming geometry.

### Dash

Each level adds:

- +35 px dash distance
- only +40 px/s dash speed
- dash-kill and dash-near-miss score scale proportionally with actual Dash Speed

Dash has 10 research levels. The baseline dash is intentionally short and slow; research extends its reach much more aggressively than its raw speed.

### Damage

Each level permanently adds **+3% player weapon damage**.

### Hits

Fresh ships begin with **2 hits**.

Hit research adds +1 starting hit per level, up to +5 extra hits. It is the cheapest permanent track, but now starts at **5,000 Research** and retains its existing 1.65× growth curve.

### Shields

Fresh ships begin with **0 shield charges**.

Each shield research level adds **one projectile block at the start of every run**, up to 5 charges. A charge absorbs one enemy projectile; it does not protect against enemy-body collisions or station walls.

Shield research is deliberately expensive and escalates sharply:

- Shield 1: **30,000**
- Shield 2: **75,000**
- Shield 3: **187,500**
- Shield 4: **468,750**
- Shield 5: **1,171,875**

## Starting-weapon research

The in-run weapon shop remains unchanged, but Research can permanently unlock weapons as **starting loadouts**.

Each starting-weapon unlock costs exactly **50× its normal one-level run-shop rental price**:

- Single Auto D1: **15,000 Research**
- Dual Auto D1x2: **50,000**
- Thin Laser: **125,000**
- Cone Cannon D3x3: **250,000**
- Heat Seeker D7: **500,000**

Unlocked starting weapons become selectable directly on the **run-start screen**. The selected weapon is the run's permanent **default loadout** and bypasses the one-level rental rule. **NONE** is always selectable, so an unlocked weapon never forces a loadout.

Normal in-run weapon prices remain:

- Single Auto: 300
- Dual Auto: 1,000
- Thin Laser: 2,500
- Cone Cannon: 5,000
- Heat Seeker: 10,000
- Repair +1 hit: 75

## Score economy

Enemy scoring is per enemy and has no combo/time-chain bonus. At baseline ship and dash speeds, an asteroid (enemy value 1) is worth:

- Normal kill: **1**
- Near miss: **10**
- Dash kill: **10**
- Dash near miss: **100**

Harder enemies multiply that same ladder by their normal enemy value:

- Asteroid: ×1
- Square drone: ×2
- Ranged trapezoid: ×4
- Smart diamond: ×5
- Pentagon missile turret: ×7

Normal kills are not speed-scaled. Ordinary near misses are multiplied by current Ship Speed relative to baseline Ship Speed. Dash kills and dash near misses are multiplied by current Dash Speed relative to baseline Dash Speed. The unupgraded ship therefore produces the exact 1/10/10/100 asteroid values above, while speed upgrades increase only their designated score classes.

Each qualifying enemy is scored independently, even when several enemies are killed or near-missed at nearly the same time. The hard lane adds **+35%** only when the scoring event physically occurs inside the hard-lane portion of the split structure. Score behind, ahead of, or outside that structure receives no hard-lane bonus.

Green energy orb scoring remains separate: **25** base score, or **125** during the dash scoring window, before any active lane pickup bonus. Nonlethal weapon damage gives no score.

### Green energy balls

Green energy balls are the game's renewable score pickups.

- They spawn randomly during normal play.
- Their random spawn interval gets gradually shorter as levels increase.
- While the split structure is crossing the **top generation boundary**, they spawn more frequently and are strongly biased toward the hard side. The instant the structure's trailing edge clears the top of the screen, pickup generation returns to normal.
- Destroyed enemies have an **8% chance** to release a green energy ball.
- Destroyed enemies separately have a **2% chance** to release a free **+1 hit** pickup.
- Kill drops remain intentionally rare; most kills still award only their normal single-digit score.

The +1 hit pickup restores one hit up to the ship's current maximum.

## Space presentation and enemy archetypes

The playfield now reads as open space rather than a lane/road: layered scrolling stars and faint deep-space haze replace the old vertical guide lines. The pre-split center guide is gone; the station divider only exists when the physical station segment actually arrives.

- **Asteroids (kind 0, 3 HP):** irregular grey rocks with craters and slow spin. They mostly ride the scroll and only barely drift laterally.
- **Square drones (kind 1, 4 HP):** weak pursuit drones. They move downfield and now make a modest lateral correction toward the player, capped well below diamond mobility.
- **Diamond drones (kind 2, 12 HP):** faster, strongest, smarter pursuit drones. They lead toward the player's intended horizontal movement but their lateral pursuit is capped so they remain avoidable.
- **Trapezoid drones (kind 3, 4 HP):** weak ranged skirmishers. They can move both up and down, try to maintain a standoff above the player baseline, fire aimed shots, and dodge player projectiles that are on an intercept path. They never intentionally move below the player's baseline.
- **Pentagon missile turrets (kind 4, 20 HP):** heavy stationary-in-world emplacements. They have no lateral AI and simply scroll by with the level. While above the player they launch slow homing missiles. A missile deals **2 hits** if unshielded, but a shield absorbs the entire missile for exactly **1 shield charge**.

Enemy progression now has long mastery windows:

- **Levels 1–2:** asteroids only; hard lanes can still bunch them into denser clusters.
- **Level 3:** easy square drones begin.
- **Level 7:** smart diamond drones begin.
- **Level 11:** ranged trapezoid drones begin.
- **Level 15:** heavy pentagon missile turrets begin. They do not pursue, dodge, or hold position on-screen; they simply scroll past with the level while firing homing missiles.

The generic difficulty curve is also softer. Per-level pressure rises by **0.075** instead of 0.12, and within-level pressure contributes at most **0.12** instead of 0.18. This gives several levels to learn each roster before density and speed become aggressive.

## Split structure lifecycle

The split structure itself defines three separate rules:

- **Generation:** the top edge of the screen is the generation boundary. Split-specific easy/hard spawning begins when the structure's first pixel reaches the top and ends immediately when its trailing/last pixel clears the top. Generation behind the structure is neutral full-width again even while the structure remains visible farther downscreen.
- **Visuals:** the red hard-lane tint exists only inside the physical hard-lane portion of the structure and moves downscreen with it. It never fills the full screen.
- **Scoring:** the +35% hard-lane bonus applies only to scoring events physically inside that hard-lane structure region.

When the entire structure eventually leaves the playfield, surviving lane-bound objects are released back to full-width movement, their hard-lane tag is cleared, and lane-only speed modifiers are removed.

## Pause and persistence

Active runs pause automatically on browser-window focus loss, application focus loss, or mobile application suspension.

The pause screen offers:

- **Resume**
- **Quit + Bank Score**

Paused runs are snapshotted to `user://neon_run.cfg`. Persistent Research is stored separately in `user://neon_meta.cfg`.

## Technical target

- Godot 4.7.2 stable
- Compatibility renderer
- 390×844 portrait reference viewport
- Touch-first controls with mouse fallback
- Persistent meta progression and paused-run recovery

## Automated smoke test

`godot --headless --path . --script res://tests/SmokeTest.gd`


## Impact rules

Player impacts now use a short **0.5 second hit-invulnerability window** so overlapping impacts cannot drain several hits almost simultaneously.

Physical contact outside a dash damages **only the player**. During the active forward dash, contact with a hazard becomes a **DASH KILL** instead: the hazard is destroyed, its normal kill score/drop rules apply, and the player takes no collision hit. Station-wall contact remains instant-lethal and is not converted into a dash kill.


## Menu presentation

Menus use compact labels and retain only actionable state: costs, levels, HP, score/research totals, weapon identity, selection state, and the one-level rental marker. Tutorial-style explanatory copy is kept out of the active menu screens.

## Controls

Phone steering uses three fixed bottom buttons:

- **LEFT** — hold to steer left.
- **DASH** — centered; tap to trigger the forward dash when ready.
- **RIGHT** — hold to steer right.

Keyboard play mirrors those controls: **Left Arrow/A** steers left, **Right Arrow/D** steers right, and **Up Arrow/W** triggers the forward dash. Swipe/drag steering remains removed. Multi-touch allows steering with one thumb while triggering DASH with another. Desktop mouse input can still use the on-screen buttons.


## Split readability tuning

- Weak square drones keep their slow lateral pursuit, but now move forward slightly faster than the neutral body-speed baseline.
- During an active station split, the hard side receives a translucent red background wash.
- The red wash exists only while the split is active and disappears when the station segment ends.
- No pre-split divider line is restored.


## Sound effects

Neon Driftline now uses a generated, self-contained procedural SFX bank rather than external audio assets. A pool of AudioStreamPlayer voices allows sounds to overlap instead of constantly cutting each other off.

Sound cues now cover:

- Single, dual, cone, seeker, and laser weapons
- Dash and near misses
- Enemy bolts and pentagon homing missiles
- Player hits and shield absorption
- Enemy destruction
- Green energy, +1 hit, and weapon pickups
- Shop/research purchases
- Level clear and run death

Weapon-fire sounds are intentionally short and quieter than impact/reward cues so automatic weapons do not dominate the mix.


## Classic progression update

Permanent research is now explicitly autosaved. Buying a permanent upgrade or starting-weapon unlock writes the meta save immediately, and starting a new run does **not** reset research.

Permanent research has been pushed further into long-term progression:

- **Hits:** starts at **5,000** research and remains the cheapest first permanent upgrade.
- **Ship Speed:** starts at **15,000**.
- **Dash:** starts at **18,000**.
- **Damage:** starts at **24,000**.
- **Shield:** starts at **30,000** and scales steeply.
- Permanent starting-weapon unlocks cost **50×** their normal one-level between-level store rental price.

The research screen highlights the first +1 Hit upgrade as **BEST FIRST**.

### Between-level store

The level-clear store now has two pages:

1. **RUN UPGRADES**
   - Ship Speed (scroll speed, left/right steering speed, near-miss bonus)
   - Dash
   - Damage
   - Max Hits
   - Shield
2. **WEAPONS / REPAIR**
   - Repair
   - Single
   - Dual
   - Cone
   - Thin Laser
   - Heat Seeker

Run upgrades use the current run's score, stack on top of permanent research, persist through later levels and durable pause/reload, and reset when a brand-new run begins.

Weapons bought on the **WEAPONS / REPAIR** page are different: they are **one-level rentals layered on top of the permanent default**. A purchased weapon equips for the immediately following level only, survives pause/reload during that level, then expires when that level clears. The selected permanent starting weapon immediately returns and remains the default for subsequent levels unless another rental temporarily replaces it. Field weapon pickups are not tagged as store rentals.

Permanent research remains permanent; non-weapon run upgrades remain run-only.

# Neon Breach — standalone tactical survivor

Play via GitHub Pages at `/Neon-Privateer/breach/`. This is the single-file
HTML5/Canvas subgame under `neon-breach/index.html`. It is independent of
Privateer and the frozen Neon Driftline Classic Godot game.

## Current perception and balance pass

- All enemies are simulated over the entire map, independent of distance from
  the player; the radar continues to reflect their updated world positions.
  Only *rendering* outside the camera viewport is culled.
- Wanderer zombie vision: **410 world units** ahead, **±82.8°**.
  Patroller zombie vision: **500 units**, **±84.6°**. Standard walking in
  their field of view gains a further 18% recognition range, while sneaking
  retains concealment.
- Normal footsteps generate noise heard by zombies in a meaningful radius.
  Zombies briefly investigate the last visible position without tracking
  through solid obstacles.
- Alert wanderers move at **2.25×** their base movement speed, and alert
  patrollers at **1.68×**. Their patrol/wander speeds are unchanged.
- Every stored-purchase weapon, radar, armor and medkit costs **1.5×** its
  previous amount, rounded up to whole credits.
- Existing persistent credits, HQ storage, and equipment remain valid.
  Prices apply on the next purchase; no saved profile conversion is needed.

## Validation

```sh
node --test tests/neon_breach.test.mjs
```

This launches the complete game module in a browser-like Node VM and verifies
shop prices, sight and stealth, noise, pursuit versus patrol speed, continued
AI motion beyond the former 1650-unit sleeping boundary, and 120 full enemy
updates on floors 15, 30 and 60 (the upper archaeology ceiling, a large
security floor, and the maximum-sized generated layout). The stress test prints
enemy count, room count, average AI update ms and p95 and applies a regression
budget. A real-device browser/frame-rate playtest remains recommended because
canvas rasterization, audio and mobile thermal throttling are not modeled in
the Node AI benchmark.

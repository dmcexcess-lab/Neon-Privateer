# Neon Privateer

A phone-first Privateer-style trading, contract, and space-combat game in Godot.

## Core loop

1. Dock at a planet.
2. Buy and sell commodities in a persistent simulated economy.
3. Accept a special-delivery, passenger, or bounty contract.
4. Choose a route to another planet.
5. Fly the route using the existing Neon arcade flight/combat layer.
6. Arrive, collect contract pay plus small flight bonuses, trade again, and improve the ship.

The old Neon Driftline arcade game is now the **space-travel layer** rather than the complete game.

## Procedural political system

Every career now owns one persistent **32-planet generated star system**.

The old Aster, Cinder, Vesper, and Helix identities are planet **types**, not fixed worlds:

- **LUSH** — former Aster visual/economic profile.
- **VOLCANIC** — former Cinder profile.
- **FROZEN** — former Vesper profile.
- **INDUSTRIAL** — former Helix profile.

Each generated planet has a stable internal ID, unique display name, type, and system position. All four types appear multiple times and reuse the existing generated planet art.

A new career also generates **2–4 superpowers** with separated capitals, colors, persistent player relation fields, influence radius/strength, and initial Arms/Narcotics law data. Political geography is derived from those influence fields:

- **CORE** — strong space around a capital; lowest political risk.
- **CONTROLLED** — clearly dominated by one power.
- **CONTESTED** — meaningful overlapping influence between powers; highest routine political risk.
- **UNCONTROLLED** — no power has sufficient influence.

The 32 worlds are connected by a sparse generated trade-lane network rather than a complete graph. Generation guarantees connectivity, adds local alternatives, limits excessive node degree/crossings, and includes a few longer strategic links.

Every lane is sampled through the authoritative political influence model and compressed into political segments. Route political danger is derived from those segments rather than assigned by a fixed route table. A short contested section therefore remains meaningful even on an otherwise safer route.

The system map supports touch pan, pinch zoom, mouse drag/wheel zoom, center/reset, direct planet selection, route planning, capitals, faction influence, and segment-colored trade lanes. Selecting a distant world plans a multi-hop route; pressing **FLY** launches the next real lane on that path.

See `POLITICAL_SYSTEM.md` for the authoritative world schema, influence rules, route generation/segmentation, danger derivation, persistence, and migration contract.

## Economy

Seven commodities are simulated:

- Food
- Ore
- Medicine
- Electronics
- Fuel
- Arms
- Narcotics

Every generated planet maintains persistent stock for every commodity plus local production and consumption rates. Its profile comes from its LUSH/VOLCANIC/FROZEN/INDUSTRIAL type. Industrial worlds are the strongest Arms producers; lush worlds are the strongest Narcotics producers. Prices continue to derive from stock scarcity, production/consumption pressure, base commodity value, and local production advantages.

**Arms** and **Narcotics** are politically restricted commodities. Every superpower independently decides whether each is legal. CORE/CONTROLLED markets show that controlling faction's law, CONTESTED worlds show mixed/shared claimant law, and UNCONTROLLED worlds report them as unregulated. The selected planet on the system map shows the same law summary.

Trading itself is not blocked yet. Police scans, confiscation, fines, criminal heat, and enforcement are later slices.

Player trades alter local stock immediately. Travel advances every planet's economy, so markets continue producing and consuming goods while the player moves through the system.

## Faction reputation and criminal state

Each superpower now tracks persistent player **Relation** and **Heat** independently.

Relation is long-term reputation from -100 to +100. Heat is current criminal attention from 0 to 100. A faction can dislike the player without actively hunting them, and a normally friendly player can acquire acute heat from a recent crime.

Status thresholds:

- Relation: ALLIED / FRIENDLY / NEUTRAL / UNFRIENDLY / HOSTILE
- Heat: CLEAR / WATCHED / WANTED / HUNTED

Future enforcement systems now have authoritative eligibility queries:

- police hostility: heat 30+ or relation -50 or worse
- heavy/pentagon enforcement: heat 60+ or relation -75 or worse

The hub, market, and system-map destination card expose current faction reputation/heat. Contested regions maintain separate state for both claimant factions. Uncontrolled space has no faction record.

Slice 3 does **not** yet cause police or defense platforms to spawn or attack. It provides the persistent state and APIs those later slices will use.


## Contracts

The contract board regenerates at each arrival and includes:

### Special delivery

- Reserves one cargo slot.
- Pays when the player successfully reaches the specified destination.
- Difficulty increases route pressure.

### Passenger

- Reserves one passenger berth.
- Pays on successful arrival.
- Passenger capacity is tracked separately from cargo.

### Bounty

- Requires an armed starting ship.
- The flight length/difficulty combines route risk with contract difficulty.
- At the destination threshold, the route transitions into a boss fight.
- The current first boss implementation is a heavy missile-firing pentagon with health and fire rate scaled by bounty difficulty.
- The contract pays only after the boss is destroyed.

## Generated Privateer menu art

Docked/privateer-facing screens use generated sci-fi artwork while the arcade flight layer remains procedural and unchanged.

The four planet portraits are now reusable archetype art:

- **LUSH:** ocean/jungle world.
- **VOLCANIC:** lava world.
- **FROZEN:** ice world.
- **INDUSTRIAL:** smog/industrial world.

Hub/career, market, navigation/contracts, and ship-upgrade screens continue using the generated station interiors. The 32 generated worlds reuse the portrait matching their type.

The atlas remains menu-only; the arcade renderer does not reference it.

## Space travel

The arcade renderer uses shape as object identity:

- **Circles — asteroids.** They retain environmental movement and are the only objects that award normal/dash near-miss credits. Destroying an asteroid gives no kill credits and has a rare 12% chance to release one unit of Ore salvage.
- **Squares — basic cargo containers.** Stationary laterally, low durability, one small random 1–2 unit commodity bundle.
- **Diamonds — reinforced cargo containers.** Stationary laterally, tougher and substantially rarer, two larger 2–3 unit bundles from a higher-value commodity table.
- **Trapezoids — hostile ships.** Their role now comes from territory: pirates in CONTESTED/UNCONTROLLED space, faction patrols in CORE/CONTROLLED space only when the player is criminal with that faction.
- **Pentagons — heavy enforcement platforms.** Random route pentagons are faction-only and require the Slice 3 heavy criminal threshold. Pirate encounters never spawn pentagons. The bounty-boss pentagon remains a contract-specific exception rather than random traffic.

### Territory encounter director

Hostile ships are no longer enabled merely because a route has a high danger value.

At the ship's exact current route segment:

- UNCONTROLLED / CONTESTED → pirate encounter windows may occur.
- CORE / CONTROLLED + clean player → no hostile patrol.
- CORE / CONTROLLED + WANTED/HOSTILE player → faction patrol windows may occur.
- CORE / CONTROLLED + heavy-enforcement threshold → patrols may include pentagon platforms.

Contacts remain random; eligibility means the director is allowed to schedule one, not that every eligible segment automatically contains enemies. Entering a different political segment immediately stops further spawns from a contact that is no longer valid there.

Faction patrol ships are colored by their superpower. Pirate ships are visually distinct.

Cargo containers still never award near-miss or kill credits. Their ownership comes from the political territory at spawn, and breaking an owned container applies the Slice 4 relation consequence.

Container loot and asteroid salvage remain physical in-flight cargo pickups and respect hold capacity.

The original LEFT / DASH / RIGHT controls, station splits, green energy pickups, weapons, shields, hit points, and procedural sound effects remain.

**Not in Slice 5:** police cargo scans, contraband detection, fines, confiscation, scan countdowns, or new heat from enforcement encounters.


## Flight bonus credits

Arcade score is a small travel bonus rather than the primary economy.

- Green energy ball: 2 bonus credits.
- Green energy during dash: 6 base bonus credits.
- **Asteroid** normal near miss: roughly 1–3 bonus credits.
- **Asteroid** dash near miss: only a few credits more.
- Asteroid and cargo-container destruction: **0 kill credits**.
- Existing ship/platform kill scoring remains in place until their later role-specific slices.

Flight bonus score is converted to credits on successful arrival. Destroying the ship loses the unbanked flight bonus. Manual quit still banks the accumulated flight bonus before returning to the origin and failing the active contract.

## Ship upgrades

The old Research currency is gone as a concept. Persistent **credits** pay for permanent ship upgrades:

- Ship speed
- Dash
- Weapon damage
- Hits
- Shield charges
- Starting weapon unlocks

Internally some legacy variable/function names still use `research_*` for compatibility, but the player-facing system is now credits and ship upgrades.

## Persistence

Three career slots are maintained. The persistent Privateer world save now includes political schema/seed plus economy schema 2 and crime schema 1, all 32 generated planets, factions, capitals, influence parameters, faction law fields, per-faction relation/heat/offense state, sparse route graph and political segments, current location, markets, cargo, contracts, passengers, and economy tick.

Generated political state is created once and never rerolled on reload.

Older four-world careers migrate once to political schema 2. Existing five-commodity saves also upgrade in place by adding Arms/Narcotics cargo keys and market entries without rerolling the political world. Existing political careers missing Slice 3 criminal-state fields receive clean heat/offense fields while preserving their faction relations and generated world. Their old location maps to a generated planet of the corresponding archetype, practical player state is preserved, and the migrated world is saved immediately.

The active route snapshot remains separate and preserves exact in-flight state.

## Technical target

- Godot 4.7.2 stable
- Compatibility renderer
- 390×844 portrait viewport
- Touch-first controls
- Web export / phone browser target

## Test

`godot --headless --path . --script res://tests/SmokeTest.gd`

The smoke test covers economy simulation, trading, political/crime state, route scaling, territory-authorized pirate/police eligibility, heavy-enforcement pentagon gating, route-boundary encounter changes, legacy pirate-run migration, asteroid-only near misses, asteroid Ore salvage, cargo-container ownership/loot/reputation penalties, durable route restore, and core flight mechanics.


## Preserved arcade version

The final standalone **Neon Driftline** build from immediately before the Privateer conversion is preserved verbatim under:

`neon-driftline-classic/`

It remains its own Godot project with the original endless escalating-level loop, permanent research/upgrades, starting-weapon research, station splits, enemies, pickups, button controls, and procedural SFX.

The repository CI runs its original smoke suite independently and exports it alongside Neon Privateer at the `/classic/` Pages path. This subproject is intentionally frozen as the arcade branch of the game rather than sharing Privateer's economy/career state.

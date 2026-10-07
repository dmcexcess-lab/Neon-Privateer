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

The system map supports touch pan, pinch zoom, mouse drag/wheel zoom, center/reset, direct planet selection, route planning, capitals, an authoritative political field, visible political borders, faction/state legend, and segment-colored trade lanes. CORE/CONTROLLED areas are faction-colored, CONTESTED bands are distinctly hatched/tinted, and UNCONTROLLED space remains visibly dark/open. Selecting a world opens jurisdiction, applicable law, and per-faction relation/heat inspection; selecting a distant world plans a multi-hop route, while pressing **FLY** launches the next real lane on that path.

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

Every generated planet maintains persistent stock for every commodity plus local production and consumption rates. Its profile comes from its LUSH/VOLCANIC/FROZEN/INDUSTRIAL type. Industrial worlds are the strongest Arms producers; lush worlds are the strongest Narcotics producers. Prices continue to derive from stock scarcity, production/consumption pressure, base commodity value, local production advantages, and—only for restricted commodities—the destination's legal status. Illegal Arms/Narcotics markets apply a 30% black-market multiplier; mixed-law markets apply a smaller 14% multiplier.

**Arms** and **Narcotics** are politically restricted commodities. Every superpower independently decides whether each is legal. CORE/CONTROLLED markets show that controlling faction's law, CONTESTED worlds show mixed/shared claimant law, and UNCONTROLLED worlds report them as unregulated. The selected planet on the system map shows the same law summary.

Trading itself remains mechanically available even where a commodity is illegal. The enforcement layer now supplies the risk: lawful patrols can scan cargo, confiscate faction-illegal Arms/Narcotics, fine the player, add heat/relation penalties, and escalate into combat.

Player trades alter local stock immediately. Travel advances every planet's economy, so markets continue producing and consuming goods while the player moves through the system.

## Faction reputation and criminal state

Each superpower now tracks persistent player **Relation** and **Heat** independently.

Relation is long-term reputation from -100 to +100. Heat is current criminal attention from 0 to 100. A faction can dislike the player without actively hunting them, and a normally friendly player can acquire acute heat from a recent crime.

Status thresholds:

- Relation: ALLIED / FRIENDLY / NEUTRAL / UNFRIENDLY / HOSTILE
- Heat: CLEAR / WATCHED / WANTED / HUNTED

Future enforcement systems now have authoritative eligibility queries:

- police hostility: heat 30+ or HOSTILE relation (-60 or worse)
- heavy/pentagon enforcement: heat 60+ or relation -75 or worse

The hub, market, and system-map destination card expose current faction reputation/heat. Contested regions maintain separate state for both claimant factions. Uncontrolled space has no faction record.

Slice 3 established the persistent criminal-state authority. Later encounter/enforcement slices now consume those same fields for patrol hostility, heavy enforcement, scans, and political-map inspection.


## Contracts

The contract board regenerates at each arrival and is now integrated with the generated economy and political map.

Every contract stores its origin, destination, issuer, route pirate exposure, payout breakdown, relation reward, and political role. Legitimate faction jobs improve relation with the issuing faction when completed; underworld smuggling jobs do not grant faction reputation.

### Freight / smuggling

- Delivery contracts reserve one cargo slot and name the actual commodity being moved.
- Legal freight selection follows market demand and destination legality rather than choosing arbitrary cargo.
- Restricted commodities sold in illegal markets carry a black-market price premium; mixed-law destinations have a smaller premium.
- When a destination bans Arms or Narcotics, the board can generate an **UNDERWORLD / SMUGGLE** delivery with a separate illegal-cargo premium.
- Smuggling contract cargo is real contraband for police scans. If a patrol faction bans that commodity and completes a scan, the contract cargo is confiscated, the contract fails, and normal contraband fine/relation/heat consequences apply.
- Successful freight delivery adds one unit of the named commodity into the destination market stock.

### Passenger

- Passenger contracts reserve one passenger berth.
- The generator prefers politically meaningful destinations such as rival-faction, contested, or uncontrolled worlds.
- Cross-faction passenger work receives a political payout premium.
- Legitimate passenger completion improves issuer relation.

### Bounty

- Bounties require an armed starting ship.
- The generator prefers destinations whose route has the greatest CONTESTED/UNCONTROLLED exposure.
- Pirate-region exposure directly raises bounty pay rather than merely raising an abstract difficulty value.
- At the destination threshold, the route transitions into the existing boss fight.
- The contract pays only after the boss is destroyed, and legitimate completion improves issuer relation.

### Risk premiums

CONTESTED + UNCONTROLLED route coverage is the authoritative **pirate exposure** percentage for contracts. It produces an explicit payout premium for freight, passengers, and especially bounties. Route danger still controls asteroid density and route length still controls travel time; neither substitutes for the political risk premium.

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

Every direct lane has three separate route axes:

- **Length / distance** controls total flight time. Danger and contract difficulty do not lengthen a lane.
- **Danger** controls asteroid density during travel.
- **Wealth** controls cargo-container density and modifies the random chance of patrol/pirate contacts. Wealth is generated from proximity to faction core worlds/capitals and from major traffic-lane centrality in the sparse route network.

The arcade renderer uses shape as object identity:

- **Circles — asteroids.** Environmental hazards and the only normal/dash near-miss objects. Destroying one gives no kill credits and has a rare 12% chance to release one Ore.
- **Squares — basic cargo containers.** Stationary laterally, low durability, one random 1–2 unit commodity bundle.
- **Diamonds — reinforced cargo containers.** Stationary laterally, tougher/rarer, two larger 2–3 unit bundles.
- **Trapezoids — ships.** Pirates in CONTESTED/UNCONTROLLED space; faction patrol ships in CORE/CONTROLLED space.
- **Pentagons — heavy government enforcement.** Random pentagons are faction-only, require the heavy criminal threshold, and can spawn only while a faction patrol is already in active hostile combat with the player. Pirate contacts never spawn them. Bounty bosses remain the explicit contract exception.

### Territory contacts and enforcement

Pirate contacts are random only in CONTESTED/UNCONTROLLED route segments and are always hostile.

Faction patrols are random only in that superpower's CORE/CONTROLLED route segments. Police presence itself does **not** mean the player is under attack:

- clean player → lawful patrol traffic;
- heat 30+ or HOSTILE relation (-60 or worse) → patrol becomes hostile;
- heat 60+ or relation -75 or worse → hostile patrol may also include pentagon heavy enforcement.

Lawful police do not track, fire, collide as damaging threats, or get hit/acquired by the player's automatic weapons. This prevents the auto-fire system from turning ordinary police traffic into an unavoidable crime.

If the player's faction status crosses the criminal threshold while a patrol is already on screen, that same patrol escalates immediately and becomes hostile/targetable.

Destroying faction enforcement has additional consequences:

- police trapezoid: -12 relation, +15 heat;
- heavy pentagon: -20 relation, +25 heat.

Faction ships use their superpower color; pirate ships use a distinct pirate treatment.

Container ownership, loot, asteroid salvage, LEFT/DASH/RIGHT controls, station splits, pickups, shields, hit points, and procedural SFX remain unchanged.

### Random police encounters and cargo scans

Police are **not guaranteed** by route difficulty.

CORE/CONTROLLED space only makes the controlling faction eligible to appear. Each patrol opportunity then makes a random roll based on that faction's persistent level (1–5) and the lane's route wealth. Route danger, contract difficulty, and heat do not increase police-contact probability. Failed rolls can leave an entire flight with no police encounter.

Faction level contributes a 19%–39% base police chance before the route-wealth multiplier. Wealthy core/traffic lanes raise that chance; poor backwater lanes lower it. Opportunity timing is randomized as well.

Pirate contacts remain random in CONTESTED/UNCONTROLLED space rather than guaranteed. Route wealth scales pirate-contact probability too, and every pirate contact is attack-on-sight.

A lawful patrol may also randomly initiate a timed cargo scan. The HUD shows the scan countdown. The scan checks Arms and Narcotics against that **specific faction's** laws.

If a completed scan finds contraband:

- only commodities illegal to that faction are confiscated;
- ordinary/legal cargo remains;
- a fine is deducted from available credits;
- relation drops and heat rises;
- the offense is recorded as `contraband_scan`;
- the patrol escalates into hostile enforcement.

A clean completed scan has no reputation/crime consequence.

If destination arrival occurs before scan completion, the scan is simply terminated with no confiscation, fine, relation loss, or heat. Active scan timers survive pause/reload.




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

Three career slots are maintained. The persistent Privateer world save now includes political schema/seed plus economy schema 2, crime schema 1, enforcement schema 1, and contract schema 1, all 32 generated planets, factions, capitals, influence parameters, faction level/law fields, per-faction relation/heat/offense state, sparse route graph and political segments, current location, markets, cargo, politically/economically annotated contracts, passengers, and economy tick.

Generated political state is created once and never rerolled on reload. Existing generated careers missing route-wealth metadata derive it deterministically from their preserved capitals and route graph, without rerolling planets or lanes.

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

The smoke test covers economy simulation, legal/illegal market premiums, faction-aware contract generation, smuggling opportunities, pirate-exposure payout premiums, contract-schema migration/persistence, smuggling-cargo scan confiscation, contract-driven market stock and faction-relation effects, political/crime state, faction-level and route-wealth migration, authoritative political-map field caching/borders/legend/inspection, length-only travel duration, danger-driven asteroid density, wealth-driven container density, wealth-scaled pirate/police opportunities, proof that encounter probability ignores route danger, quiet-flight failed rolls, lawful patrol behavior, HOSTILE-tier attack-on-sight, faction-specific contraband scans, arrival scan cancellation, scan persistence, live criminal escalation, neutral auto-fire protection, active-combat pentagon gating, enforcement-kill consequences, route-boundary encounter changes, legacy pirate-run migration, asteroid salvage/containers, durable route restore, and core flight mechanics.


## Preserved arcade version

The final standalone **Neon Driftline** build from immediately before the Privateer conversion is preserved verbatim under:

`neon-driftline-classic/`

It remains its own Godot project with the original endless escalating-level loop, permanent research/upgrades, starting-weapon research, station splits, enemies, pickups, button controls, and procedural SFX.

The repository CI runs its original smoke suite independently and exports it alongside Neon Privateer at the `/classic/` Pages path. This subproject is intentionally frozen as the arcade branch of the game rather than sharing Privateer's economy/career state.

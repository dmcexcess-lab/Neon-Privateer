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

A new career also generates **2–4 superpowers** with separated capitals, colors, persistent player relation fields, influence radius/strength, and item-level grey-market law data. Political geography is derived from those influence fields:

- **CORE** — strong space around a capital; lowest political risk.
- **CONTROLLED** — clearly dominated by one power.
- **CONTESTED** — meaningful overlapping influence between powers; highest routine political risk.
- **UNCONTROLLED** — no power has sufficient influence.

The 32 worlds are connected by a sparse generated trade-lane network rather than a complete graph. Generation guarantees connectivity, adds local alternatives, limits excessive node degree/crossings, and includes a few longer strategic links.

Every lane is sampled through the authoritative political influence model and compressed into political segments. Route political danger is derived from those segments rather than assigned by a fixed route table. A short contested section therefore remains meaningful even on an otherwise safer route.

The system map supports touch pan, pinch zoom, mouse drag/wheel zoom, center/reset, direct planet selection, route planning, capitals, an authoritative political field, visible political borders, faction/state legend, and segment-colored trade lanes. CORE/CONTROLLED areas are faction-colored, CONTESTED bands are distinctly hatched/tinted, and UNCONTROLLED space remains visibly dark/open. Selecting a world opens jurisdiction, applicable law, and per-faction relation/heat inspection; selecting a distant world plans a multi-hop route, while pressing **FLY** launches the next real lane on that path.

See `POLITICAL_SYSTEM.md` for the authoritative world schema, influence rules, route generation/segmentation, danger derivation, persistence, and migration contract.

## Bank, markets, and economy

Every docked world exposes its economy through the **Bank**. The Bank has four tabs:

- **ACCOUNT** — move money between carried cash and the protected bank balance.
- **GREEN** — trade the 12 legal commodities.
- **GREY** — trade all 12 grey commodities while seeing the local faction's item-level legality.
- **CURRENCY** — buy and sell investment units in each generated superpower.

### Cash and bank balance

`research_credits` remains the internal compatibility field for **carried cash**, but the player-facing economy distinguishes CASH from BANK.

- Flight bonuses, contracts, commodity sales, and currency sales pay carried cash.
- Commodity purchases, currency purchases, fines, and ship upgrades spend carried cash.
- **Ship destruction loses all carried cash.**
- The protected bank balance survives ship destruction.
- Depositing and withdrawing currently move the full available balance with one tap.
- The bank balance earns **3% once per successfully completed flight**. Reopening the Bank does not trigger interest.
- Faction-currency positions survive ship loss and use no cargo space.

### Green-market commodities

The legal catalog has 12 goods:

- **Food:** Grain, Protein, Produce, Luxury Food.
- **Metals:** Iron, Copper, Titanium, Rare Alloys.
- **Medicine:** First Aid, Antibiotics, Vaccines, Regenerative Medicine.

Green goods are always legal. Each item has its own base value and price volatility, so cheap staples are steadier while luxury food, rare alloys, and advanced medicine carry larger price swings.

### Grey-market commodities

The grey catalog also has 12 goods:

- **Weapons:** Small Arms, Heavy Weapons, Explosives, Military Tech.
- **Narcotics:** Stims, Sedatives, Euphorics, Neurodust.
- **Entertainment:** Holovids, Sim Chips, VR Experiences, Unlicensed Media.

A grey good is not automatically illegal. Every superpower independently permits **0–4 goods in each grey category**, so a faction can allow none, some, or all weapons, narcotics, and entertainment products. CORE/CONTROLLED law comes from the controlling faction; CONTESTED space can be mixed; UNCONTROLLED space is unregulated.

Illegal grey goods receive the existing black-market price premium: 30% in an illegal market and 14% in mixed-law territory. Police scans inspect every carried grey good and confiscate only the individual items banned by that patrol faction.

### Local day trading and hauling

Each world maintains its own persistent stock, production, consumption, and price factor for all 24 goods. Price movement combines scarcity, production/consumption pressure, planet-type specialization, item volatility, and grey-market law.

While the Bank is open, the economy advances periodically, so the player can **day trade a single local market without taking a flight**. The same physical commodities occupy cargo space, so buying locally and flying to a different world remains the hauling/arbitrage game.

Travel also advances the wider economy. LUSH worlds favor food and narcotics, VOLCANIC worlds favor metals, FROZEN worlds favor medicine, and INDUSTRIAL worlds favor weapons and entertainment.

### Faction currency market

Each generated superpower has a tradeable currency/index. Its underlying value derives from faction level, controlled-world footprint, and route wealth, with a persistent market factor adding bounded movement over time. Players buy and sell currency units directly from the Bank's CURRENCY tab; these positions do not occupy cargo space.

## Faction reputation and criminal state

Each superpower now tracks persistent player **Relation** and **Heat** independently.

Relation is long-term reputation from -100 to +100. Heat is current criminal attention from 0 to 100. A faction can dislike the player without actively hunting them, and a normally friendly player can acquire acute heat from a recent crime.

Status thresholds:

- Relation: ALLIED / FRIENDLY / NEUTRAL / UNFRIENDLY / HOSTILE
- Heat: CLEAR / WATCHED / WANTED / HUNTED

Enforcement uses these authoritative eligibility queries:

- police hostility: heat 30+ or HOSTILE relation (-60 or worse)
- heavy/pentagon enforcement: heat 60+ or relation -75 or worse

The hub, Bank, and system-map destination card expose current faction reputation/heat. Contested regions maintain separate state for both claimant factions. Uncontrolled space has no faction record.

Slice 3 established the persistent criminal-state authority. Later encounter/enforcement slices now consume those same fields for patrol hostility, heavy enforcement, scans, and political-map inspection.


## Contracts

The contract board regenerates at each arrival and is now integrated with the generated economy and political map.

Every contract stores its origin, destination, issuer, route pirate exposure, payout breakdown, relation reward, and political role. Legitimate faction jobs improve relation with the issuing faction when completed; underworld smuggling jobs do not grant faction reputation.

### Freight / smuggling

- Delivery contracts reserve one cargo slot and name the actual commodity being moved.
- Legal freight selection follows market demand and destination legality rather than choosing arbitrary cargo.
- Grey commodities sold where that **specific item** is illegal carry a black-market price premium; mixed-law destinations have a smaller premium.
- When a destination bans a grey good, the board can generate an **UNDERWORLD / SMUGGLE** delivery with a separate illegal-cargo premium.
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

Faction level contributes a **16.5%–34.5%** base police chance before the route-wealth multiplier. Route wealth scales that by **0.65×–1.35×**, so the final per-opportunity patrol chance remains probabilistic even at maximum traffic. Police opportunities occur every 11–16 seconds while eligible.

Pirate contacts remain random in CONTESTED/UNCONTROLLED space rather than guaranteed. The production bases are **22% in CONTESTED** and **32% in UNCONTROLLED** before the same 0.65×–1.35× wealth multiplier. Pirate opportunities occur every 9.5–14.5 seconds, and every actual pirate contact is attack-on-sight.

A lawful patrol may also randomly initiate a timed cargo scan. The HUD shows the scan countdown. The scan checks every carried grey-market good against that **specific faction's item-level laws**. Green-market goods are never contraband.

If a completed scan finds contraband:

- only commodities illegal to that faction are confiscated;
- ordinary/legal cargo remains;
- a fine is deducted from carried cash;
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

Flight bonus score is converted to carried cash on successful arrival. **Destroying the ship loses all carried cash, not just that flight's bonus; banked money and investment positions survive.** Manually aborting a flight preserves accumulated cash while returning to the origin and failing the active contract.

## Ship upgrades

The old Research currency is gone as a concept. Permanent ship upgrades are paid from **carried cash**:

- Ship speed
- Dash
- Weapon damage
- Hits
- Shield charges
- Starting weapon unlocks

Internally some legacy variable/function names still use `research_*` for save/code compatibility, but the player-facing financial state is CASH, BANK, commodity inventory, and faction-currency positions.

## Persistence

Three career slots are maintained. The persistent Privateer world save now includes political schema/seed plus **economy schema 3**, crime schema 1, enforcement schema 1, and **contract schema 2**, all 32 generated planets, item-level grey laws, faction level/reputation/crime state, sparse route graph and political segments, current location, all 24 local commodity markets, cargo, faction-currency holdings/indices, bank-interest cycle state, contracts, passengers, and economy tick. Carried cash and protected bank balance are persisted in the career meta save.

Generated political state is created once and never rerolled on reload. Existing generated careers missing route-wealth metadata derive it deterministically from their preserved capitals and route graph, without rerolling planets or lanes.

Older four-world careers still migrate once to political schema 2. Economy-2 careers migrate deterministically to economy schema 3: the retired seven commodity IDs map to their nearest new goods, all markets become exactly 24 active goods, old commodity keys are retired, faction grey laws are generated deterministically from the preserved world/faction identity, old credits remain carried cash, and the new bank starts at zero unless already saved. The political world, locations, routes, faction relations, and practical player progression are preserved.

The active route snapshot remains separate and preserves exact in-flight state.

## Slice 10 production closure

Slice 10 is the final balance/hardening pass for this system set; it adds no new game layer.

Production tuning is centralized in `Main.gd`:

- patrol contact: faction-level base 16.5%–34.5%, then route-wealth multiplier 0.65×–1.35×;
- pirate contact: 22% CONTESTED / 32% UNCONTROLLED base, then route wealth;
- scan chance: 14.5% at faction level 1 through 32.5% at level 5;
- patrol opportunity spacing: 11–16 seconds;
- pirate opportunity spacing: 9.5–14.5 seconds;
- asteroid Ore salvage: 10%;
- owned container relation loss: 3 basic / 7 reinforced;
- police kill: -15 relation / +20 heat;
- heavy enforcement kill: -25 relation / +35 heat;
- completed contraband scans still apply at least 30 heat, so discovery immediately reaches WANTED.

The production smoke suite sweeps 12 deterministic world seeds and verifies 32 worlds, 2–4 powers, all four political states, sparse connected routing, danger/wealth variation, law variation, deterministic regeneration, loot averages, encounter/scan envelopes, penalty hierarchy, phone hitboxes/layout, and a final live-route save/reload regression.

CI requires the production-closure marker before the frozen Classic regression, Web export, artifact upload, and GitHub Pages deployment.

## Technical target

- Godot 4.7.2 stable
- Compatibility renderer
- 390×844 portrait viewport
- Touch-first controls
- Web export / phone browser target

## Test

`godot --headless --path . --script res://tests/SmokeTest.gd`

The smoke test covers the complete Privateer system pass, including the 24-good economy, six-row Green/Grey pagination, item-level grey laws, local docked price ticks, bank deposit/withdrawal, exact 3% completed-flight interest, death loss of cash while preserving the bank, faction-currency trading with zero cargo use, career-slot financial isolation, economy-3/contract-2 migration, deterministic generated worlds, contracts, contraband scans, political/crime state, route/encounter balance, phone layout, Classic regression, durable active-route save/reload, and core flight mechanics.


## Preserved arcade version

The final standalone **Neon Driftline** build from immediately before the Privateer conversion is preserved verbatim under:

`neon-driftline-classic/`

It remains its own Godot project with the original endless escalating-level loop, permanent research/upgrades, starting-weapon research, station splits, enemies, pickups, button controls, and procedural SFX.

The repository CI runs its original smoke suite independently and exports it alongside Neon Privateer at the `/classic/` Pages path. This subproject is intentionally frozen as the arcade branch of the game rather than sharing Privateer's economy/career state.

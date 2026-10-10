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

## Physical commodity trading

Dock at any world and choose **COMMODITY TRADE** (separate from **BANK**).
The trade terminal shows all 24 physical commodities in Green and Grey
tabs, with six items per page. Each item displays local stock, current
legality, units held, and a separate BUY/SELL quote. Each tap trades one
unit immediately, updates cash/cargo/local market stock, and saves the
career. Purchases require available stock, enough carried cash, and room
in the eight-unit ship hold (delivery cargo reserves a slot); sales
require cargo on hand. Grey-market legality follows the current planet's
faction rules. The Bank still handles deposits, system indices, and
faction currency positions and does not move physical goods.

## Bank, markets, and economy

Every docked world exposes investing through the **Bank**. ACCOUNT is the cash/savings screen; the Bank then offers exactly **three investment markets**:

- **GREEN** — a low-volatility system index built from the summed value and price movement of all real Green commodity trade.
- **GREY** — a deliberately volatile system index built from the summed value and price movement of all real Grey commodity trade.
- **CURRENCY** — separate investable currencies for each generated superpower.

Green/Grey index positions and faction-currency positions are financial assets: they consume no cargo space and survive ship destruction.

### Cash and bank balance

`research_credits` remains the internal compatibility field for **carried cash**, but the player-facing economy distinguishes CASH from BANK.

- Flight bonuses, contracts, investment sales, and other payouts pay carried cash.
- Green/Grey index purchases, currency purchases, fines, and ship upgrades spend carried cash.
- **Ship destruction loses all carried cash, all cargo, all passengers, all ship upgrades, all weapon unlocks, and the current weapon/loadout.**
- The player respawns docked at the **last planet successfully landed on** (the route origin for an in-progress flight).
- The protected bank balance survives ship destruction.
- Green/Grey index positions and faction-currency positions survive ship loss and use no cargo space.
- Faction reputation/crime state, empire simulation, contracts board state, and the persistent galaxy continue from the same career.
- Depositing and withdrawing currently move the full available balance with one tap.
- The bank balance earns **3% once per successfully completed flight**. Reopening the Bank does not trigger interest.

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

### Real simulated trade

The 24 commodities remain the physical economy underneath the three Bank markets. Every planet has **one persistent specialty commodity** selected from its archetype-compatible production pool. That specialty receives the world's strongest surplus and is the main commodity the planet contributes to whichever empire currently controls it.

Each economy tick:

1. planets really produce and consume persistent stock;
2. specialist surplus is offered along actual generated trade lanes;
3. neighboring shortages and price differences determine shipment quantity;
4. actual stock is removed from the exporting planet and added to the importing planet;
5. the transaction value is recorded as Green or Grey trade;
6. same-empire and peaceful cross-empire trade add revenue/trade volume to the participating powers.

If two empires are at war, direct trade between those powers stops. Grey goods that are illegal at the destination are not magically erased from the economy, but official flow is sharply reduced, representing thinner black-market movement.

The **Green index** uses the legal commodity basket plus the summed value of real Green shipments. It has a tight spread and capped movement. The **Grey index** uses the Grey basket plus summed Grey shipments; its underlying goods have higher volatility and war demand can move it sharply. The index itself does not add cosmetic random movement—the volatility comes from the simulated underlying economy.

The economy advances while the Bank is open and when travel completes, so the system keeps trading even when the player is not hauling cargo personally.

### Empire growth, war, and faction currency

Trade now feeds politics. Controlled specialist worlds contribute revenue to their empire. Real shipment value builds faction treasury and trade volume; treasury funds military replacement and peaceful expansion.

A peaceful, solvent empire gradually spends surplus treasury to increase its existing influence **strength/radius**. This can turn uncontrolled or contested space into controlled territory. Expansion does not write a second ownership map: after influence changes, the game recomputes political route segments, danger, wealth, and the map overlay from the same authoritative influence query already used by encounters and contracts.

Wars can begin only between powers that share an actual contested frontier, have completed any cooldown, and possess enough economic depth to fight. During war both sides spend treasury and military capacity. Relative military/economic power pushes the shared influence frontier toward the stronger side; exhaustion or a decisive advantage eventually ends the war and applies a cooldown.

Each generated superpower's **Currency** instrument now derives from the empire's live fundamentals: faction level, controlled worlds, route wealth, treasury, military capacity, trade volume, and an active-war penalty, plus bounded currency-market movement. Currency positions use no cargo capacity.

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

### Special delivery / smuggling

- **Special deliveries are timed multi-jump jobs.** They deliberately choose a destination requiring at least two jumps with the current drive, reserve one cargo slot, and name the actual commodity being moved.
- Their deadline persists across intermediate landings; taking too long fails the job and releases the reserved slot.
- Normal legal freight selection still follows market demand and destination legality rather than choosing arbitrary cargo.
- Grey commodities sold where that **specific item** is illegal carry a black-market price premium; mixed-law destinations have a smaller premium.
- When a destination bans a grey good, the board can generate an **UNDERWORLD / SMUGGLE** delivery with a separate illegal-cargo premium.
- Smuggling contract cargo is real contraband for police scans. If a patrol faction bans that commodity and completes a scan, the contract cargo is confiscated, the contract fails, and normal contraband fine/relation/heat consequences apply.
- Successful freight delivery adds one unit of the named commodity into the destination market stock.

### Passenger

- Passenger contracts reserve one passenger berth and deliberately choose **multi-jump** destinations.
- They have no normal delivery deadline; intermediate landings do not fail them.
- Passenger patience is intentionally generous, but after an extreme delay (15 minutes of active contract time) the passenger leaves and the contract fails.
- The generator still prefers politically meaningful destinations such as rival-faction, contested, or uncontrolled worlds.
- Cross-faction passenger work receives a political payout premium.
- Legitimate passenger completion improves issuer relation.

### Bounty

- Bounties require an armed starting ship.
- Travel to the bounty target is ordinary distance-based travel using the same jump-range and fuel rules as everything else; multi-jump targets remain ordinary flights until the final destination.
- Pirate-region exposure and target distance both contribute to bounty selection/payout.
- At the **final target arrival**, normal forward travel stops, route/object spawning stops, and the game becomes a dedicated boss arena. Lateral movement, weapons, and dash remain active.
- Target classes are **trapezoid patrol**, **stationary pentagon platform**, or a high-HP **octagon flagship**. The octagon uses multiple weapon systems (spread cannon + homing missiles).
- The contract pays only after the target is destroyed; then landing completes and legitimate completion improves issuer relation.

### Risk premiums

CONTESTED + UNCONTROLLED route coverage is the authoritative **pirate exposure** percentage for contracts. It produces an explicit payout premium for freight, passengers, and especially bounties. Route danger still controls asteroid density and route length still controls travel time; neither substitutes for the political risk premium.

## Graphics overhaul

Privateer now uses a two-layer visual pipeline designed for phone/Web performance.

Docked screens keep the generated sci-fi atlas as their background layer, but the presentation pass adds animated scan-line treatment, cinematic darkening, double-framed/corner-bracket panels, stronger planet glows/rings, and higher-contrast information cards. The four planet portraits remain reusable archetype art:

- **LUSH:** ocean/jungle world with green atmospheric treatment.
- **VOLCANIC:** lava world with hot orange/red treatment.
- **FROZEN:** ice world with cyan/blue treatment.
- **INDUSTRIAL:** smog/industrial world with amber treatment.

The arcade flight layer remains procedural so it stays lightweight, but the placeholder-flat geometry has been replaced with a richer production renderer:

- layered nebula/parallax starfield and speed streaks;
- detailed player hull, canopy, wing insets, running lights, twin engines, animated exhaust, dash trails, and shield arcs;
- distinct pirate/police fighter silhouettes with faction lighting;
- armored pentagon enforcement/bounty platforms;
- a multi-turret octagon flagship with layered armor, core lighting, and engines;
- dimensional asteroids with lit edges and multiple crater layers;
- differentiated basic/reinforced containers;
- category-colored cargo pods;
- hex weapon pickups, medical pods, and animated energy cores;
- projectile glows/cores, missile geometry, laser layering, debris streaks, and variable explosion particles;
- redesigned flight HUD with route progress, segmented hull/fuel state, boss HP, and clearer touch controls.

`GRAPHICS_REVISION` is currently **2** and is enforced by Privateer smoke so the overhaul cannot silently regress to the old presentation layer.

The visual overhaul intentionally changes presentation only; flight rules, economy, political simulation, contracts, and Classic Neon Driftline behavior remain separate.

## Space travel

Every direct lane has separate route axes:

- **Length / distance** controls baseline flight time and fuel consumption.
- **Jump range** gates which direct lanes the current ship can cross. The navigator finds the shortest path using only edges within the current drive range, so range upgrades can open new regions and shortcuts.
- **Fuel** is ship state, not cargo. A jump burns fuel equal to that direct lane's distance; refueling is paid while docked at 20 credits per fuel unit. The tank holds 12 units.
- **Travel time** has bounded ±7% variation. Even the longest baseline jump is capped at 30 seconds, and the Ship Speed upgrade reduces real wall-clock travel time.
- **Danger** controls asteroid density during travel.
- **Wealth** controls cargo-container density and modifies random patrol/pirate contact probability.

The arcade renderer uses shape as object identity:

- **Circles — asteroids.** Environmental hazards and the only normal/dash near-miss objects. Destroying one gives no kill credits and has a rare 12% chance to release one Ore.
- **Squares — basic cargo containers.** Stationary laterally, low durability, one random 1–2 unit commodity bundle.
- **Diamonds — reinforced cargo containers.** Stationary laterally, tougher/rarer, two larger 2–3 unit bundles.
- **Trapezoids — ships.** Pirates in CONTESTED/UNCONTROLLED space; faction patrol ships in CORE/CONTROLLED space.
- **Pentagons — heavy government enforcement.** Random pentagons are faction-only, require the heavy criminal threshold, and can spawn only while a faction patrol is already in active hostile combat with the player. A stationary pentagon can also be an explicit bounty target.
- **Octagons — bounty flagships only.** Large, high-HP targets with multiple weapon systems; they do not appear as ordinary route traffic.

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

Container ownership, loot, asteroid salvage, LEFT/DASH/RIGHT controls, pickups, shields, hit points, and gameplay rules remain unchanged by the graphics pass. **Privateer travel has no station/lane splits:** flights are one continuous open field from departure to arrival.

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

Flight bonus score is converted to carried cash on successful arrival. **Destroying the ship is a total ship loss:** all unbanked cash, cargo, passengers, upgrades, weapon unlocks, and the current weapon are lost. The player respawns at the last planet successfully landed on. Banked money and financial investments survive. Manually aborting a flight is not a death and therefore preserves the ship, its cargo, upgrades, weapon research, and carried cash while returning to the origin and failing the active contract.

## Ship upgrades

The old Research currency is gone as a concept. Ship upgrades are paid from **carried cash** and remain installed only until the ship is destroyed:

- Max jump range
- Ship speed
- Dash
- Weapon damage
- Hits
- Shield charges
- Starting weapon unlocks

All six upgrade tracks and all starting-weapon unlocks reset to zero/locked on ship destruction. Jump range returns to the baseline drive, and the replacement ship starts with a **full fuel tank**, two hits, zero shield charges, and no starting weapon. Internally some legacy variable/function names still use `research_*` for save/code compatibility, but the player-facing financial state is CASH, BANK, commodity inventory, and faction-currency positions.

## Persistence

Three career slots are maintained. The persistent Privateer world save now includes political schema/seed plus **economy schema 4**, crime schema 1, enforcement schema 1, and **contract schema 3**, all 32 generated planets, one commodity specialty per planet, item-level grey laws, empire treasury/military/trade/war state, sparse route graph and dynamically recomputed political segments, current location, all 24 physical commodity markets, Green/Grey index state and holdings, the real-trade ledger, faction-currency holdings/indices, bank-interest cycle state, contracts, passengers, and economy tick. Carried cash and protected bank balance are persisted in the career meta save.

Generated political state is created once and never rerolled on reload. Existing generated careers missing route-wealth metadata derive it deterministically from their preserved capitals and route graph, without rerolling planets or lanes.

Older four-world careers still migrate once to political schema 2. Economy-2/3 careers migrate deterministically to economy schema 4: retired commodity IDs map to the 24-good model, existing worlds gain deterministic planet specialties, factions gain macroeconomic/war fields without rerolling geography, Green/Grey index holdings start clean when absent, old credits remain carried cash, and the existing bank/relations/routes/progression are preserved.

The active route snapshot remains separate and preserves exact in-flight state. Career meta state now also persists current fuel and the max-jump upgrade.

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

The smoke test covers the complete Privateer system pass, including 24 persistent physical goods, archetype-valid planet specialties, real route shipment stock transfer, summed Green/Grey trade ledgers, aggregate index investing, Green-vs-Grey risk/spread behavior, docked economy ticks, bank deposit/withdrawal, exact 3% completed-flight interest, **full ship-loss reset and last-landing respawn while preserving bank/investments**, faction currency, peaceful influence expansion, forced-war resource consumption/frontier movement, currency-fundamental response, career isolation, economy-4/contract-2 migration, deterministic worlds, contracts, contraband, route/encounter balance, phone layout, Classic regression, durable active-route save/reload, and core flight mechanics.


## Preserved arcade version

The final standalone **Neon Driftline** build from immediately before the Privateer conversion is preserved verbatim under:

`neon-driftline-classic/`

It remains its own Godot project with the original endless escalating-level loop, permanent research/upgrades, starting-weapon research, station splits, enemies, pickups, button controls, and procedural SFX.

The repository CI runs its original smoke suite independently and exports it alongside Neon Privateer at the `/classic/` Pages path. This subproject is intentionally frozen as the arcade branch of the game rather than sharing Privateer's economy/career state.

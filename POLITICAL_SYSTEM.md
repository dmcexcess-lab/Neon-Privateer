# Political System Architecture

This document is authoritative for Neon Privateer's procedural political world foundation.

## World schema

Current political world schema: **2**.

A career owns one persistent political world with:

- `seed`
- exactly 32 `planets`
- 2–4 `factions`
- sparse connected `routes`
- deterministic political geography derived from faction influence

The world is generated once per career and then persisted. Reloading does not reroll world identity.

## Planet record

Each generated planet has:

- `id`: stable internal ID such as `p00`
- `name`: generated player-facing name
- `type`: one of `LUSH`, `VOLCANIC`, `FROZEN`, `INDUSTRIAL`
- `pos`: logical system-map position

Generated display names are not used as gameplay identity. Contracts, markets, routes, and saves use planet IDs.

## Planet type profiles

The old four fixed worlds are now reusable archetypes:

- `LUSH` -> former Aster visual/economic profile
- `VOLCANIC` -> former Cinder profile
- `FROZEN` -> former Vesper profile
- `INDUSTRIAL` -> former Helix profile

The existing generated planet art is selected by type.

## Faction record

Each superpower has:

- `id`
- generated `name`
- `color`
- `capital_id`
- `radius`
- `strength`
- generated influence `radius`
- player `relation`
- `laws`

Initial law fields:

- `arms_legal`
- `narcotics_legal`

Slice 2 made these laws authoritative for commodity legality. The current production systems consume them for market/map indicators, black-market pricing, smuggling generation, police scans, confiscation, fines, and enforcement. Installed ship weapons are not governed by `arms_legal`; only the **Arms commodity** is.

## Commodity legality

Slice 2 adds two restricted commodities:

- `Arms`
- `Narcotics`

The authoritative law helpers are:

- `commodity_law_key(commodity)`
- `faction_commodity_legal(world, faction_id, commodity)`
- `commodity_legality_at(world, position, commodity)`

Ordinary commodities are always reported as legal/unrestricted.

For restricted commodities:

- **CORE / CONTROLLED:** the controlling superpower's law applies.
- **CONTESTED:** both meaningful claimant factions are consulted. If their laws disagree, status is `MIXED`; if they agree, the shared `LEGAL` or `ILLEGAL` result is returned.
- **UNCONTROLLED:** status is `UNREGULATED`.

This query remains the commodity-law authority. Police scans use the specific patrol faction's law directly rather than inferring enforcement from the generic contested-space label; Slice 9 uses the same result for black-market premiums and smuggling destinations.

## Faction reputation and criminal state

Slice 3 adds two independent persistent player-state axes for every superpower:

- **Relation**: long-term reputation, clamped to `-100…+100`.
- **Heat**: current criminal attention, clamped to `0…100`.

Relation bands:

- `ALLIED` at +60 or higher
- `FRIENDLY` at +25 or higher
- `NEUTRAL` from -24 through +24
- `UNFRIENDLY` from -59 through -25
- `HOSTILE` at -60 or lower

Heat bands:

- `CLEAR` below 10
- `WATCHED` from 10–29
- `WANTED` from 30–59
- `HUNTED` at 60+

The authoritative criminal-state query is `faction_crime_state(world, faction_id)`.

Production encounter/enforcement thresholds:

- ordinary police hostility becomes eligible at **heat >= 30** or **HOSTILE relation <= -60**;
- heavy/pentagon enforcement becomes eligible at **heat >= 60** or **relation <= -75**.

These thresholds are consumed by the current patrol system: eligible lawful patrols remain neutral until heat/relation makes them hostile, and heavy enforcement still requires its higher threshold plus active hostile patrol combat.

Authoritative mutation APIs:

- `adjust_faction_relation(world, faction_id, delta)`
- `adjust_faction_heat(world, faction_id, delta)`
- `record_crime(world, faction_id, relation_loss, heat_gain, offense)`
- `decay_all_heat(world, amount)`

`record_crime` increments an offense count and stores the last offense tag for debugging/future UI. Crimes are faction-specific: changing one superpower's relation/heat does not affect another.

The Main scene exposes wrappers for gameplay systems and UI, including:

- `_is_criminal_with_faction`
- `_police_hostile_eligible`
- `_heavy_enforcement_eligible`
- `_record_faction_crime`
- `_planet_crime_summary`

## Capital selection

The first capital is chosen on the outer system. Additional capitals maximize minimum distance from already chosen capitals. This deliberately spreads 2–4 superpowers instead of independently choosing random neighboring worlds.

## Influence

Faction influence is radial from its capital:

`influence = strength * (1 - distance / radius)^1.35`

Influence is zero outside the faction radius. Radius generation is informed by distance to the nearest rival capital so neighboring powers reliably form a real frontier rather than isolated bubbles.

Each generated world then calibrates and persists two geography thresholds from a deterministic sample of that influence field:

- `control_threshold` keeps the lowest-influence portion of the system politically uncontrolled;
- `contest_ratio` is derived from the strongest actual faction overlap so a meaningful contested frontier exists.

This calibration is still influence-driven; it does not paint manual territory polygons. It prevents random careers from accidentally generating no uncontrolled space or no contested border.

The authoritative query is:

`_get_political_context_at(position)`

It returns the strongest and second-strongest factions/influence plus the derived territory state.

## Territory states

### CORE

Strong, uncontested influence or position close to a faction capital.

### CONTROLLED

One faction clearly dominates but the point lies outside its core.

### CONTESTED

Two meaningful influence fields are sufficiently close in strength.

### UNCONTROLLED

No faction reaches the minimum influence threshold.

The same query is used by map rendering, route analysis, and later encounter/crime systems.

## Slice 4 object ownership and salvage contract

Slice 4 gives the arcade shapes semantic world roles:

- circle / kind 0 = asteroid
- square / kind 1 = basic cargo container
- diamond / kind 2 = reinforced cargo container
- trapezoid / kind 3 = ship
- pentagon / kind 4 = heavy ship/platform role reserved for later enforcement work

Container ownership is derived from the authoritative political context at the route position where the container spawns:

- **CORE / CONTROLLED:** owned by the controlling faction.
- **CONTESTED:** owned by one of the two claimant factions.
- **UNCONTROLLED:** unowned.

Container records persist their `owner_faction` and `territory_state` in the in-flight object snapshot. They do not recalculate ownership after spawning.

Destroying an owned basic container records `container_theft` and costs 4 faction relation. Destroying an owned reinforced container records `reinforced_container_theft` and costs 8 relation. Slice 4 intentionally adds **zero heat** for these events; later law/enforcement slices can revise the heat consequence without changing ownership authority.

Unowned containers carry no faction penalty.

Loot is released as in-flight cargo pickups rather than being inserted directly into the hold. Cargo pickup collection respects normal cargo capacity and persists through the ordinary Privateer world save.

Asteroids no longer award kill credits. They retain the existing near-miss/dash-near-miss credit behavior and have a 12% chance to release one unit of Ore when destroyed.

Basic and reinforced containers award no kill credits and no near-miss credits.

## Slice 5 territory encounter director

Flight encounters use the political segment the ship is physically crossing. Route danger no longer grants hostile-ship permission by itself.

Authoritative encounter mode:

- **UNCONTROLLED / CONTESTED:** random pirate contacts are eligible.
- **CORE / CONTROLLED:** random faction patrol contacts are eligible for the controlling superpower.

Slice 5 establishes **where** each contact type can occur. Slice 6 establishes whether a faction patrol is lawful/neutral or hostile.

Encounter state is generic and persisted:

- `encounter_active`
- `encounter_mode` = `pirate` or `police`
- `encounter_faction_id`
- `encounter_hostile`
- `encounter_timer`
- `encounter_clock`

The director queries the current route segment every update. Crossing into a segment that no longer permits the current mode/faction ends that contact window for new spawns; already-visible ships finish their passage instead of disappearing.

Pre-Slice-5 pirate-only route snapshots still migrate through the legacy `pirate_active / pirate_timer / pirate_clock` fields.


## Slice 6 ships and enforcement

Trapezoids now represent actual ships rather than generic hostile geometry.

### Pirate ships

Pirate trapezoids appear only during pirate contacts in CONTESTED/UNCONTROLLED space. They are always hostile, track/dodge the player, and fire normally.

Pirate encounters never spawn random pentagons.

### Faction patrol ships

Faction trapezoids may appear randomly in that faction's CORE/CONTROLLED space even when the player is clean.

A lawful patrol:

- carries `encounter_role = police` and its faction ID;
- is not hostile;
- does not track, dodge around player fire, or shoot;
- passes through as ordinary patrol traffic;
- does not damage the player through ship collision;
- is not acquired by seeker/laser targeting;
- is not damaged by automatic player fire.

This non-targetable behavior is required because the player's weapons auto-fire; merely encountering lawful police must not force an unavoidable crime.

The same live patrol becomes hostile immediately when that faction's Slice 3 criminal threshold becomes true. Hostile police use the same active combat behavior as other hostile ships and become valid player targets.

### Heavy government enforcement

Random pentagons are reserved for serious faction enforcement:

- police contact only;
- the patrol must already be in active hostile combat with the player;
- player must already meet the heavy-enforcement threshold;
- heat >= 60 or relation <= -75.

A lawful/non-hostile patrol never spawns a pentagon. Bounty-boss pentagons remain the contract-specific exception and are independent of faction patrol traffic.

### Enforcement consequences

Destroying a government trapezoid records `police_ship_destroyed`, costs 12 faction relation, and adds 15 heat.

Destroying a government pentagon records `heavy_enforcement_destroyed`, costs 20 faction relation, and adds 25 heat.

Pirate kills have no superpower reputation consequence.

Contraband scans, scan timers, cargo confiscation, and fines remain Slice 7.

## Slice 7 random patrols and contraband scans

Each superpower now has a persistent **faction level** from 1–5.

Faction level is generated from that power's strength and saved in the political world. Older careers missing the field derive it deterministically from the already-saved faction strength, so upgrading does not reroll the system.

### Random encounter rule

Police presence is probabilistic, like pirate presence.

A CORE/CONTROLLED segment makes that faction's patrols **eligible**. It does not guarantee a patrol.

At each encounter opportunity:

- a random roll is made;
- police base chance is based on that faction's level;
- route wealth scales that chance;
- route danger, contract difficulty, and player heat do not increase the probability of a police contact;
- a failed roll schedules another later opportunity rather than forcing an encounter.

The faction-level base police chance remains 19% at level 1 through 39% at level 5 before wealth scaling. Route wealth then multiplies that base so traffic-rich/core-adjacent lanes see more patrol traffic while poor backwater lanes see less. Opportunity timing remains randomized, so no route guarantees a patrol.

Pirate windows are also probabilistic rather than guaranteed when their territory is eligible. Route wealth scales pirate probability too, while CONTESTED/UNCONTROLLED political state remains the hard eligibility gate. Pirates are always hostile once an encounter starts.

Heat/relation still control whether a patrol is lawful or hostile **after** a patrol exists.

### Cargo scans

A lawful police patrol may independently choose to scan the player.

Scan chance also scales by faction level and remains random.

A scan is a visible timed action. While it is active the HUD shows the remaining scan time.

The scan uses the specific patrol faction's laws, not a generic regional legality label:

- illegal Arms are contraband only if that faction bans Arms;
- illegal Narcotics are contraband only if that faction bans Narcotics;
- unrestricted commodities are never confiscated.

If the scan completes with no contraband, it reports clear and changes no relation/heat.

If contraband is found:

- all cargo illegal to that scanning faction is confiscated;
- legal cargo is untouched;
- a fine is charged from available credits;
- `contraband_scan` is recorded as the faction offense;
- faction relation falls;
- heat rises to at least the WANTED threshold;
- the current patrol therefore escalates to hostile enforcement.

### Arrival and scan cancellation

If the player reaches the destination before the scan timer completes, arrival ends the scan immediately.

An unfinished scan causes:

- no confiscation;
- no fine;
- no faction relation loss;
- no heat increase.

Political-border/contact termination also cancels an unfinished scan.

Active scan state is persisted in the in-flight run snapshot so pausing/reloading cannot reset the timer.

### Enforcement schema

Enforcement schema version **1** persists faction level. Existing careers upgrade in place without rerolling planets, routes, laws, reputation, or markets.

## Route graph

The 32 planets are not a complete graph.

Generation:

1. build a minimum-spanning-tree style backbone;
2. add short local alternatives;
3. give one-link worlds another local option where practical;
4. add a few strategic longer links;
5. avoid duplicate edges;
6. limit excessive route crossings and node degree.

The result is one connected network with alternate paths.

## Route record

A route stores:

- canonical route `id`
- endpoints `a` and `b`
- geometric `length`
- gameplay `distance`
- contiguous political `segments`
- derived `danger`
- derived `wealth` from 1–5
- normalized `core_proximity`
- normalized `traffic_score`

Danger is derived from political segments and is never authoritative on its own. Wealth is derived from preserved world geography/network structure rather than rolled independently.

## Route segmentation

Each route is sampled repeatedly from endpoint to endpoint. Every sample calls the authoritative political query.

Adjacent matching samples are compressed into segments containing:

- territory `state`
- controlling/strongest faction IDs
- second faction ID
- normalized `start_t`
- normalized `end_t`

Encounter, contract-risk, and map systems use these stored segments instead of independently recalculating route territory.

## Derived political danger

Relative weights:

- CORE = 1
- CONTROLLED = 2
- UNCONTROLLED = 4
- CONTESTED = 5

Route danger combines weighted segment coverage with maximum segment severity so a short contested crossing remains meaningful.

In current flight gameplay, route danger is the authoritative control for **asteroid density**. It does not lengthen the flight and does not raise patrol/pirate encounter probability.

## Route wealth and traffic

Every generated direct lane receives deterministic wealth from two independent signals:

1. **Core proximity** — how close the lane passes to a faction capital/core world, normalized against that faction's influence radius.
2. **Traffic centrality** — how often that edge lies on shortest paths across the sparse 32-world route graph, normalized against the busiest generated lane.

The stronger of those two signals determines a 1–5 route wealth tier. A lane can therefore be wealthy because it serves a core world **or** because it is a major cross-system traffic artery.

Route wealth controls:

- cargo-container density during travel;
- patrol probability in CORE/CONTROLLED space;
- pirate probability in CONTESTED/UNCONTROLLED space.

Route wealth does not grant encounter eligibility by itself. Territory state still decides whether police or pirates are allowed to appear.

Existing political-schema-2 careers missing these route fields are upgraded in place by recomputing wealth from their already-saved factions and route graph. The migration does not reroll worlds or lanes.

## Route travel time

Gameplay `distance` is the authoritative control for total flight duration. Political danger, route wealth, and contract difficulty do not increase the time required to traverse the same direct lane.

## Route planning

`_route_spec(origin, destination)` can provide an aggregate shortest-path specification for contracts and planning.

Actual flight launch requires a direct generated lane. Multi-hop contracts therefore remain possible without turning the sparse graph into a complete graph.

## System map model

The travel screen renders the generated world, not fixed four-world coordinates.

The map supports:

- pan
- bounded zoom
- touch drag
- pinch zoom
- mouse drag
- mouse wheel zoom
- reset/center
- tap/click planet selection
- explicit FLY action

Initial view fits the complete system. Hit targets are screen-space and remain usable as visual planet size changes.

## Map political visualization

Slice 8 makes the political geography directly readable without introducing a second map authority.

The map consumes the same `political_context_at()` result used by gameplay. A cached low-resolution field samples the generated system bounds and renders:

- faction-colored **CORE** and **CONTROLLED** areas;
- distinctly tinted/hatched **CONTESTED** bands;
- dark/open **UNCONTROLLED** space;
- visible boundaries wherever the authoritative state/controller changes;
- capital markers;
- all generated routes;
- route segments colored independently by political state/faction;
- current world, selected destination, and active contract destination.

The coarse field is intentional. It communicates control/borders on a phone-sized map without pretending the radial influence model creates perfect polygonal borders.

The map also includes a faction/state legend. Selecting a planet exposes its jurisdiction, applicable Arms/Narcotics law, and the relevant faction relation/heat status. Contested worlds expose both claimant factions independently rather than collapsing them into one reputation record.

Selected/contract routes render above the political field so path readability wins over decorative shading.

No separate hand-painted political map is authoritative.

## Slice 8 political map polish

Slice 8 is presentation/inspection only. It does not alter influence math, territory ownership, route segmentation, encounter eligibility, laws, relation/heat, or route simulation.

Acceptance rules:

- political field cells must match the authoritative context query at their sampled positions;
- visible field transitions must come from changes in authoritative state/controller;
- route lines remain segment-colored rather than receiving one aggregate danger color;
- the faction legend is generated from the persistent faction records/colors;
- planet inspection names the controlling or contesting factions and surfaces applicable laws plus relation/heat status;
- tap/click still selects first and never launches directly;
- pan/zoom, current/selected/contract markers, 32 generated planets, and explicit **FLY** remain intact.


## Slice 9 economy / contract integration

Slice 9 consumes the political, law, route-segmentation, route-wealth, crime, and market systems rather than introducing a parallel contract simulation.

### Contract authority

Every generated contract now records:

- schema version;
- origin and destination planet IDs;
- contract type and player-facing political role;
- named commodity for deliveries;
- smuggling flag;
- issuing faction/name;
- faction relation reward;
- route pirate exposure;
- base reward;
- pirate-risk premium;
- cargo/law premium;
- political premium;
- final reward.

Legitimate jobs use the current world's primary faction as issuer when one exists. Underworld smuggling jobs deliberately have no legitimate faction issuer and grant no faction reputation.

### Destination selection

The contract board is faction/economy aware:

- legal freight prefers commodities with destination demand / favorable market spread while avoiding cargo illegal at that destination;
- smuggling searches for Arms or Narcotics destinations where the destination law is explicitly ILLEGAL;
- passenger work prefers cross-faction, contested, or uncontrolled destinations so passenger contracts cross political geography;
- bounties prefer routes with the greatest CONTESTED + UNCONTROLLED coverage.

This does not change route topology. Contracts still use the generated sparse network and normal shortest-path planning.

### Pirate exposure and payout

For contract purposes:

pirate exposure = contested route share + uncontrolled route share

The percentage is derived from the same segmented route path used by encounter eligibility.

Pirate exposure adds an explicit payout premium:

- freight: moderate;
- passenger: stronger;
- bounty: strongest.

Danger remains the asteroid-density axis. Distance remains the travel-time axis. Wealth remains the traffic/container/encounter-frequency axis. Pirate exposure is therefore a separate political-contract risk signal.

### Legal / illegal cargo premium

Restricted-market price multipliers now reflect enforcement risk:

- LEGAL / UNREGULATED: 1.00x;
- MIXED: 1.14x;
- ILLEGAL: 1.30x.

The multiplier applies to the market mid-price before the existing buy/sell spread, so illegal destinations can offer a genuine black-market premium while still exposing the player to faction scans.

Smuggling contracts receive an additional cargo premium on top of normal route payout.

### Contract cargo and scans

Delivery cargo still occupies one reserved cargo slot.

If a delivery's named Arms/Narcotics commodity is illegal to a scanning patrol faction, that reserved contract cargo is part of the contraband manifest even though it is not stored in the player's ordinary cargo dictionary.

A completed illegal scan:

- confiscates the contract cargo;
- fails/clears that delivery contract;
- counts the contract unit toward contraband value and fine;
- applies the same relation/heat crime consequences as ordinary illegal cargo.

This closes the loophole where a visually illegal smuggling contract could previously pass a scan because its reserved cargo was only abstract capacity.

### Completion effects

Successful legitimate contracts improve relation with the issuing faction:

- freight: +2;
- passenger: +3;
- bounty: +5.

Smuggling grants no faction relation.

Successful freight also adds one unit of its named commodity to the destination market stock so contract traffic feeds the persistent economy.

### Contract schema

Contract schema version 1 upgrades older saved contracts in place.

Legacy records keep their original ID, type, destination, difficulty, and reward while gaining safe defaults for origin, commodity, issuer, relation reward, pirate exposure, role, and payout-breakdown metadata. The political world and existing markets are not rerolled.

## Slice 10 balance + production closure

Slice 10 is production hardening only. It introduces no new simulation layer.

### Final balance envelope

Authoritative gameplay tuning is centralized in `Main.gd`:

- route-wealth encounter multiplier: 0.65x–1.35x;
- police encounter base: 12% + 4.5% per faction level = 16.5%–34.5% before wealth;
- pirate encounter base: 22% in CONTESTED / 32% in UNCONTROLLED before wealth;
- police encounter opportunities: every 11–16 seconds while eligible;
- pirate encounter opportunities: every 9.5–14.5 seconds while eligible;
- lawful patrol scan chance: 10% + 4.5% per faction level = 14.5%–32.5%;
- asteroid Ore salvage: 10%;
- owned-container relation loss: 3 basic / 7 reinforced;
- police ship destruction: -15 relation / +20 heat;
- heavy enforcement destruction: -25 relation / +35 heat;
- completed contraband scan base heat: 30, preserving immediate WANTED escalation.

The final hierarchy is intentional: ordinary property theft is reputationally meaningful but recoverable, reinforced theft is worse, killing government enforcement is substantially worse, and heavy-enforcement destruction is the most severe direct combat offense in this pass.

### Generated-world production validation

The terminal smoke suite generates 12 additional deterministic careers from fixed seeds and requires, for every seed:

- exactly 32 unique worlds;
- all four planet archetypes represented at least twice;
- 2–4 factions with valid capitals and varied laws;
- every capital in CORE;
- CORE, CONTROLLED, CONTESTED, and UNCONTROLLED represented by the influence field;
- a sparse 31–55 edge route network;
- complete route-segment coverage;
- route danger and wealth both within 1–5 and varying meaningfully;
- full graph connectivity;
- bit-for-behavior deterministic regeneration from the same seed.

### Phone/browser closure

The production test also verifies the 390x844 portrait viewport, canvas-item stretch mode, all primary touch controls within the viewport, minimum 44px primary hit targets, seven-row market fit, five-row contract-board fit, and non-overlap of the system route card with BACK/FLY controls.

The Web export remains single-thread compatible through the Godot Compatibility renderer and the CI deployment remains the browser acceptance path.

### Save/load closure

The final regression ends from a live flight, saves/pauses, reloads the same career, and requires:

- identical generated-world signature;
- same origin/destination;
- same route wealth;
- same elapsed route progress;
- active route restored paused rather than advanced offline.

This sits on top of the earlier schema/migration, career-slot isolation, contract migration, contraband-scan persistence, and active-run snapshot tests.

## Persistence

Career world saves persist:

- political schema
- economy schema
- crime schema
- enforcement schema
- contract schema
- schema
- seed
- planets
- faction records, laws, relation, heat, offense count, and last offense
- generated route graph
- current planet
- market state for all seven commodities
- cargo/contracts/passengers/economy state, including Slice 9 contract political/economic metadata

Route political segmentation and route-wealth metadata are saved with the generated graph and can also be deterministically reproduced from the same world.

## Legacy migration

A career without political schema is treated as a four-world legacy career.

Migration:

1. generate a 32-world political system once;
2. map old location by archetype:
   - Aster -> LUSH
   - Cinder -> VOLCANIC
   - Vesper -> FROZEN
   - Helix -> INDUSTRIAL
3. preserve player credits/upgrades/cargo and practical world state;
4. translate legacy contract destinations by archetype where possible;
5. save schema 2 immediately.

Reloading does not rerun migration.

## Public/query APIs

Current and later systems consume these authoritative queries or wrappers:

- political context at a map/route position
- controlling faction
- contesting factions
- faction laws
- route political segment at progress
- route wealth / traffic metadata
- direct route lookup
- route shortest-path specification
- planet type
- planet display name
- neighbors

These APIs now drive:

- pirate eligibility
- police eligibility
- container ownership
- contraband law
- faction reputation/crime consequences
- route encounter composition
- faction-aware contract issuers/destinations
- pirate-exposure contract premiums
- smuggling legality and scan consequences


## Slice 2 economy schema

Economy schema version **2** adds `Arms` and `Narcotics` to every generated market and cargo inventory.

Existing five-commodity careers are upgraded idempotently on load:

- missing cargo keys are added at zero;
- every generated market receives missing commodity entries from its planet-type production profile;
- existing stock for the original five commodities is preserved;
- the upgraded economy schema is saved back to the career.

Planet-type tendencies:

- **LUSH:** strong Food and Narcotics production; weak Arms.
- **VOLCANIC:** strong Ore/Fuel and moderate Arms; weak Narcotics.
- **FROZEN:** strong Medicine with modest Narcotics and weak Arms.
- **INDUSTRIAL:** strong Electronics/Arms; weak Narcotics.

Market trading remains mechanically available even when a commodity is illegal. Later slices now consume that same law authority for scans/confiscation and, in Slice 9, for black-market price premiums plus smuggling-contract generation.


## Slice 3 crime schema

Crime schema version **1** upgrades existing political careers in place. Missing faction fields are added without regenerating planets, factions, capitals, laws, influence, or routes:

- missing `relation` -> 0
- missing `heat` -> 0
- missing `offenses` -> 0
- missing `last_offense` -> empty string

Existing relation values are preserved and clamped. The upgraded schema is persisted immediately.

The market, career hub, and selected-world map card expose faction reputation/heat compactly. In contested space both claimant factions remain independent; uncontrolled space has no faction criminal record.

The Slice 3 fields are now consumed by patrol hostility, scans/fines/confiscation, heavy enforcement, political-map inspection, and legitimate contract reputation rewards.


## Slice 4 cargo-container loot

Basic square containers are stationary laterally, use the normal commodity catalog, and release one small 1–2 unit bundle.

Reinforced diamond containers are also stationary laterally, remain materially tougher/rarer, and release two 2–3 unit bundles from a higher-value table:

- Electronics
- Arms
- Medicine
- Narcotics
- Fuel
- Ore

The player's forward travel still makes containers scroll through the arcade field; "stationary" means they have no self-propelled lateral pursuit/drift.

Only asteroids qualify for normal and dash near-miss scoring after Slice 4.

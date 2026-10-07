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

Slice 2 makes these laws authoritative for commodity legality. They currently classify cargo and drive market/map indicators; police scans, fines, confiscation, and hostility still belong to later slices. Installed ship weapons are not governed by `arms_legal`; only the **Arms commodity** is.

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

This query is presentation/data authority now and is intended to become the source for police scans later. A future scan by a specific police faction should use that faction's law directly rather than infer enforcement from the generic contested-space label.

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

Eligibility thresholds reserved for later encounter/enforcement slices:

- ordinary police hostility becomes eligible at **heat >= 30** or **relation <= -50**;
- heavy/pentagon enforcement becomes eligible at **heat >= 60** or **relation <= -75**.

These are eligibility rules only. Slice 3 does not change encounter spawning or make police attack.

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
- player must already meet the heavy-enforcement threshold;
- heat >= 60 or relation <= -75.

Bounty-boss pentagons remain the contract-specific exception and are independent of faction patrol traffic.

### Enforcement consequences

Destroying a government trapezoid records `police_ship_destroyed`, costs 12 faction relation, and adds 15 heat.

Destroying a government pentagon records `heavy_enforcement_destroyed`, costs 20 faction relation, and adds 25 heat.

Pirate kills have no superpower reputation consequence.

Contraband scans, scan timers, cargo confiscation, and fines remain Slice 7.

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

Danger is derived from political segments and is never authoritative on its own.

## Route segmentation

Each route is sampled repeatedly from endpoint to endpoint. Every sample calls the authoritative political query.

Adjacent matching samples are compressed into segments containing:

- territory `state`
- controlling/strongest faction IDs
- second faction ID
- normalized `start_t`
- normalized `end_t`

Future encounter systems must use these segments instead of independently recalculating territory.

## Derived political danger

Relative weights:

- CORE = 1
- CONTROLLED = 2
- UNCONTROLLED = 4
- CONTESTED = 5

Route danger combines weighted segment coverage with maximum segment severity so a short contested crossing remains meaningful.

Asteroid/environmental difficulty remains separate in Slice 1.

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

The map consumes authoritative world data:

- faction influence halos
- capital markers
- all generated routes
- route segments colored by political state/faction
- current world
- selected destination
- active contract destination

No separate hand-painted political map is authoritative.

## Persistence

Career world saves persist:

- political schema
- economy schema
- crime schema
- schema
- seed
- planets
- faction records, laws, relation, heat, offense count, and last offense
- generated route graph
- current planet
- market state for all seven commodities
- cargo/contracts/passengers/economy state

Route political segmentation is saved with the generated graph and can also be deterministically reproduced from the same world.

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

## Public/query APIs reserved for later slices

Later systems should consume these authoritative queries or wrappers:

- political context at a map/route position
- controlling faction
- contesting factions
- faction laws
- route political segment at progress
- direct route lookup
- route shortest-path specification
- planet type
- planet display name
- neighbors

These APIs will later drive:

- pirate eligibility
- police eligibility
- container ownership
- contraband law
- faction reputation/crime consequences
- route encounter composition


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

Market trading remains mechanically available in Slice 2 even when a commodity is illegal. The law is surfaced now so later contraband/scanning systems can impose the actual risk.


## Slice 3 crime schema

Crime schema version **1** upgrades existing political careers in place. Missing faction fields are added without regenerating planets, factions, capitals, laws, influence, or routes:

- missing `relation` -> 0
- missing `heat` -> 0
- missing `offenses` -> 0
- missing `last_offense` -> empty string

Existing relation values are preserved and clamped. The upgraded schema is persisted immediately.

The market, career hub, and selected-world map card expose faction reputation/heat compactly. In contested space both claimant factions remain independent; uncontrolled space has no faction criminal record.

Police/pirate spawning, scans, fines, confiscation, and actual hostility remain deferred.


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

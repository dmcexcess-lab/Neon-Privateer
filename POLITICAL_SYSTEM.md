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
- schema
- seed
- planets
- faction records and laws
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

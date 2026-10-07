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
- player `relation`
- `laws`

Initial law fields:

- `arms_legal`
- `narcotics_legal`

Laws exist in Slice 1 as data only. Enforcement belongs to later slices.

## Capital selection

The first capital is chosen on the outer system. Additional capitals maximize minimum distance from already chosen capitals. This deliberately spreads 2–4 superpowers instead of independently choosing random neighboring worlds.

## Influence

Faction influence is radial from its capital:

`influence = strength * (1 - distance / radius)^1.35`

Influence is zero outside the faction radius.

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

- schema
- seed
- planets
- faction records and laws
- generated route graph
- current planet
- market state
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

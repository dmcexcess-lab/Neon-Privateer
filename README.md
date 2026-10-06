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

## Planets and routes

The initial playable network has four planets:

- **Aster**
- **Cinder**
- **Vesper**
- **Helix**

Routes have independent distance and danger values. Longer and more dangerous routes produce longer flights and higher flight difficulty. Contract difficulty is added on top, so a high-risk bounty can make the same physical route substantially harder.

## Economy

Five commodities are currently simulated:

- Food
- Ore
- Medicine
- Electronics
- Fuel

Every planet maintains persistent stock for every commodity plus local production and consumption rates. Prices are calculated from current stock scarcity, production/consumption pressure, base commodity value, and local production advantages.

Player trades alter local stock immediately. Travel advances every planet's economy, so markets continue producing and consuming goods while the player moves through the system. This makes prices stateful rather than fixed buy/sell tables.

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

## Space travel

The original flight mechanics remain:

- LEFT / DASH / RIGHT phone controls.
- Asteroids and ordinary drones.
- Smart diamond drones.
- Station splits with a red hard side.
- Green energy pickups.
- Weapons, shields, hit points, near misses, dash near misses, and procedural sound effects.

During normal Privateer routes, trapezoids and pentagons do **not** appear as routine traffic. They represent pirate contacts. Pirate windows occur during riskier routes; trapezoids and pentagons are introduced during those windows.

## Flight bonus credits

Arcade score is now a small travel bonus rather than the primary economy.

- Green energy ball: 2 bonus credits.
- Green energy during dash: 6 base bonus credits.
- Normal near miss: roughly 1–3 bonus credits.
- Dash near miss: only a few credits more.
- Enemy kills remain small single-digit bonuses.

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

Two save layers are maintained:

- Persistent Privateer world state: current planet, markets, cargo, contracts, passengers, economy tick, credits/upgrades.
- Active route snapshot: exact flight state, route identity, pirate state, bounty boss state, projectiles, hazards, HP, weapon, and timing.

Focus loss / phone suspension pauses and snapshots an active flight.

## Technical target

- Godot 4.7.2 stable
- Compatibility renderer
- 390×844 portrait viewport
- Touch-first controls
- Web export / phone browser target

## Test

`godot --headless --path . --script res://tests/SmokeTest.gd`

The smoke test covers economy simulation, trading, route scaling, contract classes, pirate gating, bounty boss flow, arrival payouts, delivery/passenger capacity, durable route restore, and core flight mechanics.

extends RefCounted
class_name PoliticalWorld

const WORLD_SCHEMA_VERSION := 2
const PLANET_COUNT := 32
const WORLD_BOUNDS := Rect2(-720.0, -520.0, 1440.0, 1040.0)
const MIN_PLANET_SPACING := 105.0
const PLANET_TYPES := ["LUSH", "VOLCANIC", "FROZEN", "INDUSTRIAL"]
const STATE_CORE := "CORE"
const STATE_CONTROLLED := "CONTROLLED"
const STATE_CONTESTED := "CONTESTED"
const STATE_UNCONTROLLED := "UNCONTROLLED"

const TYPE_VISUAL_KEY := {
    "LUSH": "Aster",
    "VOLCANIC": "Cinder",
    "FROZEN": "Vesper",
    "INDUSTRIAL": "Helix"
}

const DANGER_WEIGHT := {
    STATE_CORE: 1.0,
    STATE_CONTROLLED: 2.0,
    STATE_UNCONTROLLED: 4.0,
    STATE_CONTESTED: 5.0
}

const RESTRICTED_COMMODITIES := ["Arms", "Narcotics"]

const RELATION_MIN := -100
const RELATION_MAX := 100
const HEAT_MIN := 0
const HEAT_MAX := 100
const CRIMINAL_HEAT_THRESHOLD := 30
const HEAVY_HEAT_THRESHOLD := 60
const CRIMINAL_RELATION_THRESHOLD := -50
const HEAVY_RELATION_THRESHOLD := -75

const FACTION_COLORS := [
    Color("5dd7ff"),
    Color("ff6b91"),
    Color("ffd166"),
    Color("8dff9f")
]

const NAME_PREFIX := [
    "Ar", "Bel", "Cyr", "Dra", "El", "Fen", "Gal", "Hel",
    "Iri", "Jor", "Kel", "Lys", "Mor", "Nex", "Or", "Pra",
    "Qua", "Ryn", "Sol", "Tal", "Umb", "Vor", "Wex", "Xan",
    "Yor", "Zen"
]
const NAME_SUFFIX := [
    "adon", "aris", "ea", "eron", "ia", "ion", "ora", "os",
    " Prime", " Reach", " Secundus", " Station", "us", "ara", "yne", "oth"
]
const FACTION_ADJ := ["Solar", "Vanguard", "United", "Free", "Civic", "Astral", "Federal", "Crown"]
const FACTION_NOUN := ["Union", "Compact", "Directorate", "League", "Republic", "Authority", "Collective", "Dominion"]

static func generate(seed_value: int) -> Dictionary:
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    var planets: Array = _generate_planets(rng)
    var factions: Array = _generate_factions(rng, planets)
    var world := {
        "schema": WORLD_SCHEMA_VERSION,
        "seed": seed_value,
        "bounds": WORLD_BOUNDS,
        "planets": planets,
        "factions": factions,
        "control_threshold": 0.08,
        "contest_ratio": 0.50,
        "routes": []
    }
    _calibrate_political_thresholds(world)
    world.routes = _build_route_network(world)
    return world

static func _ranked_influence(world: Dictionary, pos: Vector2) -> Array:
    var ranked: Array = []
    for faction in world.get("factions", []):
        ranked.append({
            "id": String(faction.id),
            "value": _influence_for_faction(world, faction, pos),
            "capital_distance": pos.distance_to(planet_position(world, String(faction.capital_id))),
            "radius": float(faction.radius)
        })
    ranked.sort_custom(func(a, b): return float(a.value) > float(b.value))
    return ranked

static func _calibrate_political_thresholds(world: Dictionary) -> void:
    # Calibrate against this generated geography rather than relying on one
    # fixed threshold. This preserves influence-driven borders while ensuring
    # every career retains real uncontrolled gaps and contested frontiers.
    var strongest_values: Array[float] = []
    var samples: Array[Dictionary] = []
    var bounds: Rect2 = Rect2(world.get("bounds", WORLD_BOUNDS))
    for gy in 21:
        for gx in 29:
            var pos := bounds.position + Vector2(
                bounds.size.x * float(gx) / 28.0,
                bounds.size.y * float(gy) / 20.0
            )
            var ranked: Array = _ranked_influence(world, pos)
            if ranked.is_empty():
                continue
            var strongest: float = float(ranked[0].value)
            var second: float = float(ranked[1].value) if ranked.size() > 1 else 0.0
            strongest_values.append(strongest)
            samples.append({"strongest": strongest, "second": second})
    strongest_values.sort()
    if strongest_values.is_empty():
        world.control_threshold = 0.08
        world.contest_ratio = 0.50
        return

    # Roughly the lowest quarter of the map remains outside effective control.
    var threshold_index: int = clampi(int(floor(float(strongest_values.size() - 1) * 0.24)), 0, strongest_values.size() - 1)
    var threshold: float = clampf(strongest_values[threshold_index], 0.035, 0.24)
    world.control_threshold = threshold

    # Find the strongest actual overlap above the control threshold, then set
    # the contested cutoff just below it. This guarantees a real frontier
    # where powers meet without hand-painting territory.
    var max_ratio: float = 0.0
    for sample in samples:
        var strongest: float = float(sample.strongest)
        var second: float = float(sample.second)
        if strongest < threshold or second <= 0.0:
            continue
        max_ratio = maxf(max_ratio, second / maxf(strongest, 0.0001))
    world.contest_ratio = clampf(max_ratio * 0.90, 0.01, 0.58)

static func _generate_planets(rng: RandomNumberGenerator) -> Array:
    var cells: Array = []
    var cols := 7
    var rows := 5
    var margin_x := 85.0
    var margin_y := 75.0
    var step_x := (WORLD_BOUNDS.size.x - margin_x * 2.0) / float(cols - 1)
    var step_y := (WORLD_BOUNDS.size.y - margin_y * 2.0) / float(rows - 1)
    for y in rows:
        for x in cols:
            var pos := WORLD_BOUNDS.position + Vector2(
                margin_x + float(x) * step_x,
                margin_y + float(y) * step_y
            )
            cells.append(pos)
    # Fisher-Yates so each seed creates a different sparse shape while retaining spacing.
    for i in range(cells.size() - 1, 0, -1):
        var j := rng.randi_range(0, i)
        var temp = cells[i]
        cells[i] = cells[j]
        cells[j] = temp

    var planets: Array = []
    var used_names: Dictionary = {}
    for i in PLANET_COUNT:
        var base: Vector2 = cells[i]
        var jitter := Vector2(rng.randf_range(-34.0, 34.0), rng.randf_range(-30.0, 30.0))
        var pos := base + jitter
        pos.x = clampf(pos.x, WORLD_BOUNDS.position.x + 42.0, WORLD_BOUNDS.end.x - 42.0)
        pos.y = clampf(pos.y, WORLD_BOUNDS.position.y + 42.0, WORLD_BOUNDS.end.y - 42.0)

        var planet_type: String = String(PLANET_TYPES[i % PLANET_TYPES.size()] if i < 8 else PLANET_TYPES[rng.randi_range(0, PLANET_TYPES.size() - 1)])
        var display_name := _unique_planet_name(rng, used_names, i)
        used_names[display_name] = true
        planets.append({
            "id": "p%02d" % i,
            "name": display_name,
            "type": planet_type,
            "pos": pos
        })
    return planets

static func _unique_planet_name(rng: RandomNumberGenerator, used: Dictionary, index: int) -> String:
    for attempt in 128:
        var name: String = String(NAME_PREFIX[rng.randi_range(0, NAME_PREFIX.size() - 1)]) + String(NAME_SUFFIX[rng.randi_range(0, NAME_SUFFIX.size() - 1)])
        if not used.has(name):
            return name
    return "World %02d" % (index + 1)

static func _generate_factions(rng: RandomNumberGenerator, planets: Array) -> Array:
    var count := rng.randi_range(2, 4)
    var capital_ids: Array[String] = []
    # Start with the planet farthest from the system center.
    var first := String(planets[0].id)
    var first_dist := -1.0
    for planet in planets:
        var d := Vector2(planet.pos).length_squared()
        if d > first_dist:
            first_dist = d
            first = String(planet.id)
    capital_ids.append(first)

    while capital_ids.size() < count:
        var best_id := ""
        var best_min_dist := -1.0
        for planet in planets:
            var pid := String(planet.id)
            if capital_ids.has(pid):
                continue
            var p := Vector2(planet.pos)
            var min_dist := INF
            for cap_id in capital_ids:
                min_dist = minf(min_dist, p.distance_to(planet_position({"planets": planets}, cap_id)))
            if min_dist > best_min_dist:
                best_min_dist = min_dist
                best_id = pid
        capital_ids.append(best_id)

    var factions: Array = []
    var used_faction_names: Dictionary = {}
    var law_offset: int = rng.randi_range(0, 3)
    for i in count:
        var combo: int = (i + law_offset) % 4
        var capital_id: String = capital_ids[i]
        var capital_pos: Vector2 = planet_position({"planets": planets}, capital_id)
        var nearest_rival_distance: float = INF
        for rival_id in capital_ids:
            if rival_id == capital_id:
                continue
            nearest_rival_distance = minf(
                nearest_rival_distance,
                capital_pos.distance_to(planet_position({"planets": planets}, rival_id))
            )
        if nearest_rival_distance == INF:
            nearest_rival_distance = 1050.0
        # Rival distance is part of the influence scale: powers must overlap
        # enough to form an actual frontier, but control thresholds are
        # calibrated later so remote gaps remain uncontrolled.
        var influence_radius: float = clampf(
            nearest_rival_distance * 0.72 + rng.randf_range(-24.0, 24.0),
            760.0,
            1120.0
        )
        var faction_name: String = String(FACTION_ADJ[(i + rng.randi_range(0, FACTION_ADJ.size() - 1)) % FACTION_ADJ.size()]) + " " + String(FACTION_NOUN[(i * 3 + rng.randi_range(0, FACTION_NOUN.size() - 1)) % FACTION_NOUN.size()])
        if used_faction_names.has(faction_name):
            faction_name += " %d" % (i + 1)
        used_faction_names[faction_name] = true
        factions.append({
            "id": "f%02d" % i,
            "name": faction_name,
            "color": FACTION_COLORS[i % FACTION_COLORS.size()],
            "capital_id": capital_id,
            "radius": influence_radius,
            "strength": rng.randf_range(0.98, 1.16),
            "relation": 0,
            "heat": 0,
            "offenses": 0,
            "last_offense": "",
            "laws": {
                "arms_legal": combo == 0 or combo == 2,
                "narcotics_legal": combo == 0 or combo == 1
            }
        })
    return factions

static func planet_record(world: Dictionary, planet_id: String) -> Dictionary:
    for planet in world.get("planets", []):
        if String(planet.get("id", "")) == planet_id:
            return planet
    return {}

static func planet_position(world: Dictionary, planet_id: String) -> Vector2:
    var planet := planet_record(world, planet_id)
    return Vector2(planet.get("pos", Vector2.ZERO))

static func planet_name(world: Dictionary, planet_id: String) -> String:
    var planet := planet_record(world, planet_id)
    return String(planet.get("name", planet_id))

static func planet_type(world: Dictionary, planet_id: String) -> String:
    var planet := planet_record(world, planet_id)
    return String(planet.get("type", "LUSH"))

static func visual_key_for_type(planet_type_value: String) -> String:
    return String(TYPE_VISUAL_KEY.get(planet_type_value, "Aster"))

static func faction_record(world: Dictionary, faction_id: String) -> Dictionary:
    for faction in world.get("factions", []):
        if String(faction.get("id", "")) == faction_id:
            return faction
    return {}

static func ensure_crime_schema(world: Dictionary) -> bool:
    var changed := false
    var factions: Array = world.get("factions", [])
    for i in factions.size():
        var faction: Dictionary = factions[i]
        if not faction.has("relation"):
            faction["relation"] = 0
            changed = true
        if not faction.has("heat"):
            faction["heat"] = 0
            changed = true
        if not faction.has("offenses"):
            faction["offenses"] = 0
            changed = true
        if not faction.has("last_offense"):
            faction["last_offense"] = ""
            changed = true
        faction["relation"] = clampi(int(faction.get("relation", 0)), RELATION_MIN, RELATION_MAX)
        faction["heat"] = clampi(int(faction.get("heat", 0)), HEAT_MIN, HEAT_MAX)
        factions[i] = faction
    world["factions"] = factions
    return changed

static func faction_relation(world: Dictionary, faction_id: String) -> int:
    return clampi(int(faction_record(world, faction_id).get("relation", 0)), RELATION_MIN, RELATION_MAX)

static func faction_heat(world: Dictionary, faction_id: String) -> int:
    return clampi(int(faction_record(world, faction_id).get("heat", 0)), HEAT_MIN, HEAT_MAX)

static func relation_label(relation: int) -> String:
    if relation >= 60:
        return "ALLIED"
    if relation >= 25:
        return "FRIENDLY"
    if relation > -25:
        return "NEUTRAL"
    if relation > -60:
        return "UNFRIENDLY"
    return "HOSTILE"

static func heat_label(heat: int) -> String:
    if heat >= HEAVY_HEAT_THRESHOLD:
        return "HUNTED"
    if heat >= CRIMINAL_HEAT_THRESHOLD:
        return "WANTED"
    if heat >= 10:
        return "WATCHED"
    return "CLEAR"

static func faction_crime_state(world: Dictionary, faction_id: String) -> Dictionary:
    var relation := faction_relation(world, faction_id)
    var heat := faction_heat(world, faction_id)
    var criminal := heat >= CRIMINAL_HEAT_THRESHOLD or relation <= CRIMINAL_RELATION_THRESHOLD
    var heavy := heat >= HEAVY_HEAT_THRESHOLD or relation <= HEAVY_RELATION_THRESHOLD
    return {
        "faction_id": faction_id,
        "relation": relation,
        "relation_label": relation_label(relation),
        "heat": heat,
        "heat_label": heat_label(heat),
        "criminal": criminal,
        "police_hostile": criminal,
        "heavy_enforcement": heavy
    }

static func _replace_faction(world: Dictionary, faction_id: String, updated: Dictionary) -> bool:
    var factions: Array = world.get("factions", [])
    for i in factions.size():
        if String(factions[i].get("id", "")) == faction_id:
            factions[i] = updated
            world["factions"] = factions
            return true
    return false

static func adjust_faction_relation(world: Dictionary, faction_id: String, delta: int) -> int:
    var faction := faction_record(world, faction_id).duplicate(true)
    if faction.is_empty():
        return 0
    var value := clampi(int(faction.get("relation", 0)) + delta, RELATION_MIN, RELATION_MAX)
    faction["relation"] = value
    _replace_faction(world, faction_id, faction)
    return value

static func adjust_faction_heat(world: Dictionary, faction_id: String, delta: int) -> int:
    var faction := faction_record(world, faction_id).duplicate(true)
    if faction.is_empty():
        return 0
    var value := clampi(int(faction.get("heat", 0)) + delta, HEAT_MIN, HEAT_MAX)
    faction["heat"] = value
    _replace_faction(world, faction_id, faction)
    return value

static func record_crime(world: Dictionary, faction_id: String, relation_loss: int, heat_gain: int, offense: String = "") -> Dictionary:
    var faction := faction_record(world, faction_id).duplicate(true)
    if faction.is_empty():
        return {}
    faction["relation"] = clampi(int(faction.get("relation", 0)) - absi(relation_loss), RELATION_MIN, RELATION_MAX)
    faction["heat"] = clampi(int(faction.get("heat", 0)) + absi(heat_gain), HEAT_MIN, HEAT_MAX)
    faction["offenses"] = maxi(0, int(faction.get("offenses", 0))) + 1
    faction["last_offense"] = offense
    _replace_faction(world, faction_id, faction)
    return faction_crime_state(world, faction_id)

static func decay_all_heat(world: Dictionary, amount: int) -> bool:
    var decay := maxi(0, amount)
    if decay <= 0:
        return false
    var changed := false
    var factions: Array = world.get("factions", [])
    for i in factions.size():
        var faction: Dictionary = factions[i]
        var before := clampi(int(faction.get("heat", 0)), HEAT_MIN, HEAT_MAX)
        var after := maxi(HEAT_MIN, before - decay)
        if after != before:
            faction["heat"] = after
            factions[i] = faction
            changed = true
    if changed:
        world["factions"] = factions
    return changed

static func commodity_law_key(commodity: String) -> String:
    match commodity:
        "Arms":
            return "arms_legal"
        "Narcotics":
            return "narcotics_legal"
    return ""

static func faction_commodity_legal(world: Dictionary, faction_id: String, commodity: String) -> bool:
    var law_key: String = commodity_law_key(commodity)
    if law_key.is_empty():
        return true
    var faction: Dictionary = faction_record(world, faction_id)
    if faction.is_empty():
        return true
    var laws: Dictionary = faction.get("laws", {})
    return bool(laws.get(law_key, true))

static func commodity_legality_at(world: Dictionary, pos: Vector2, commodity: String) -> Dictionary:
    var context: Dictionary = political_context_at(world, pos)
    var state: String = String(context.get("state", STATE_UNCONTROLLED))
    var law_key: String = commodity_law_key(commodity)

    if law_key.is_empty():
        return {
            "commodity": commodity,
            "status": "LEGAL",
            "regulated": false,
            "mixed": false,
            "legal": true,
            "state": state,
            "faction_ids": []
        }

    if state == STATE_UNCONTROLLED:
        return {
            "commodity": commodity,
            "status": "UNREGULATED",
            "regulated": false,
            "mixed": false,
            "legal": true,
            "state": state,
            "faction_ids": []
        }

    if state == STATE_CONTESTED:
        var strongest_id: String = String(context.get("strongest_faction_id", ""))
        var second_id: String = String(context.get("second_faction_id", ""))
        var strongest_legal: bool = faction_commodity_legal(world, strongest_id, commodity)
        var second_legal: bool = faction_commodity_legal(world, second_id, commodity)
        var mixed: bool = strongest_legal != second_legal
        return {
            "commodity": commodity,
            "status": "MIXED" if mixed else ("LEGAL" if strongest_legal else "ILLEGAL"),
            "regulated": true,
            "mixed": mixed,
            "legal": strongest_legal and second_legal,
            "state": state,
            "faction_ids": [strongest_id, second_id]
        }

    var faction_id: String = String(context.get("faction_id", ""))
    if faction_id.is_empty():
        faction_id = String(context.get("strongest_faction_id", ""))
    var is_legal: bool = faction_commodity_legal(world, faction_id, commodity)
    return {
        "commodity": commodity,
        "status": "LEGAL" if is_legal else "ILLEGAL",
        "regulated": true,
        "mixed": false,
        "legal": is_legal,
        "state": state,
        "faction_ids": [faction_id]
    }

static func _influence_for_faction(world: Dictionary, faction: Dictionary, pos: Vector2) -> float:
    var capital := planet_position(world, String(faction.capital_id))
    var radius := maxf(1.0, float(faction.radius))
    var normalized := pos.distance_to(capital) / radius
    if normalized >= 1.0:
        return 0.0
    return float(faction.strength) * pow(maxf(0.0, 1.0 - normalized), 1.35)

static func political_context_at(world: Dictionary, pos: Vector2) -> Dictionary:
    var ranked: Array = _ranked_influence(world, pos)

    var strongest: Dictionary = ranked[0] if not ranked.is_empty() else {"id": "", "value": 0.0, "capital_distance": INF, "radius": 1.0}
    var second: Dictionary = ranked[1] if ranked.size() > 1 else {"id": "", "value": 0.0}
    var strongest_value: float = float(strongest.value)
    var second_value: float = float(second.value)
    var control_threshold: float = float(world.get("control_threshold", 0.08))
    var contest_ratio: float = float(world.get("contest_ratio", 0.50))
    var state := STATE_UNCONTROLLED
    var controller := ""

    if strongest_value >= control_threshold:
        var comparable := second_value > 0.0 and second_value / maxf(strongest_value, 0.001) >= contest_ratio
        if comparable:
            state = STATE_CONTESTED
        else:
            controller = String(strongest.id)
            var near_capital := float(strongest.capital_distance) <= float(strongest.radius) * 0.27
            if strongest_value >= 0.72 or near_capital:
                state = STATE_CORE
            else:
                state = STATE_CONTROLLED

    return {
        "state": state,
        "faction_id": controller,
        "strongest_faction_id": String(strongest.id),
        "second_faction_id": String(second.id),
        "strongest_influence": strongest_value,
        "second_influence": second_value,
        "contesting_factions": [String(strongest.id), String(second.id)] if state == STATE_CONTESTED else []
    }

static func _edge_id(a: String, b: String) -> String:
    return a + "|" + b if a < b else b + "|" + a

static func _segment_intersects(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> bool:
    var d1 := a2 - a1
    var d2 := b2 - b1
    var cross := d1.cross(d2)
    if absf(cross) < 0.001:
        return false
    var delta := b1 - a1
    var t := delta.cross(d2) / cross
    var u := delta.cross(d1) / cross
    return t > 0.04 and t < 0.96 and u > 0.04 and u < 0.96

static func _crossing_count(world: Dictionary, a: String, b: String, routes: Array) -> int:
    var a1 := planet_position(world, a)
    var a2 := planet_position(world, b)
    var count := 0
    for route in routes:
        var r1 := String(route.a)
        var r2 := String(route.b)
        if r1 == a or r1 == b or r2 == a or r2 == b:
            continue
        if _segment_intersects(a1, a2, planet_position(world, r1), planet_position(world, r2)):
            count += 1
    return count

static func _build_route_network(world: Dictionary) -> Array:
    var planets: Array = world.planets
    var routes: Array = []
    var edge_ids: Dictionary = {}
    var degree: Dictionary = {}
    for planet in planets:
        degree[String(planet.id)] = 0

    # Prim MST guarantees one connected network.
    var connected: Array[String] = [String(planets[0].id)]
    var remaining: Array[String] = []
    for i in range(1, planets.size()):
        remaining.append(String(planets[i].id))

    while not remaining.is_empty():
        var best_a := ""
        var best_b := ""
        var best_distance := INF
        for a in connected:
            var pa := planet_position(world, a)
            for b in remaining:
                var distance := pa.distance_to(planet_position(world, b))
                if distance < best_distance:
                    best_distance = distance
                    best_a = a
                    best_b = b
        _append_route(world, routes, edge_ids, degree, best_a, best_b)
        connected.append(best_b)
        remaining.erase(best_b)

    # Add local alternatives until average degree is roughly three.
    var candidates: Array = []
    for i in planets.size():
        for j in range(i + 1, planets.size()):
            var a := String(planets[i].id)
            var b := String(planets[j].id)
            if edge_ids.has(_edge_id(a, b)):
                continue
            candidates.append({
                "a": a,
                "b": b,
                "distance": planet_position(world, a).distance_to(planet_position(world, b))
            })
    candidates.sort_custom(func(a, b): return float(a.distance) < float(b.distance))

    var target_edges := 47
    for candidate in candidates:
        if routes.size() >= target_edges:
            break
        var a := String(candidate.a)
        var b := String(candidate.b)
        if int(degree[a]) >= 5 or int(degree[b]) >= 5:
            continue
        if int(degree[a]) >= 4 and int(degree[b]) >= 4:
            continue
        if float(candidate.distance) > 430.0:
            continue
        if _crossing_count(world, a, b, routes) > 1:
            continue
        _append_route(world, routes, edge_ids, degree, a, b)

    # Ensure planets that only have one MST link receive a local alternative where practical.
    for planet in planets:
        var pid := String(planet.id)
        if int(degree[pid]) >= 2:
            continue
        for candidate in candidates:
            var a := String(candidate.a)
            var b := String(candidate.b)
            if a != pid and b != pid:
                continue
            if edge_ids.has(_edge_id(a, b)):
                continue
            if int(degree[a]) >= 5 or int(degree[b]) >= 5:
                continue
            _append_route(world, routes, edge_ids, degree, a, b)
            break

    # A few strategic longer links reduce excessive hopping across the full map.
    for candidate in candidates:
        if routes.size() >= 50:
            break
        var d := float(candidate.distance)
        if d < 430.0 or d > 720.0:
            continue
        var a := String(candidate.a)
        var b := String(candidate.b)
        if edge_ids.has(_edge_id(a, b)) or int(degree[a]) >= 6 or int(degree[b]) >= 6:
            continue
        if _crossing_count(world, a, b, routes) > 2:
            continue
        _append_route(world, routes, edge_ids, degree, a, b)

    return routes

static func _append_route(world: Dictionary, routes: Array, edge_ids: Dictionary, degree: Dictionary, a: String, b: String) -> void:
    if a.is_empty() or b.is_empty() or a == b:
        return
    var eid := _edge_id(a, b)
    if edge_ids.has(eid):
        return
    var distance_px := planet_position(world, a).distance_to(planet_position(world, b))
    var route := {
        "id": eid,
        "a": a,
        "b": b,
        "length": distance_px,
        "distance": clampi(int(round(distance_px / 155.0)), 1, 6),
        "segments": []
    }
    route.segments = _segment_route(world, a, b)
    route.danger = _danger_from_segments(route.segments)
    routes.append(route)
    edge_ids[eid] = true
    degree[a] = int(degree.get(a, 0)) + 1
    degree[b] = int(degree.get(b, 0)) + 1

static func _segment_route(world: Dictionary, a: String, b: String) -> Array:
    var start := planet_position(world, a)
    var finish := planet_position(world, b)
    var samples := 48
    var groups: Array = []
    var current: Dictionary = {}
    for i in range(samples + 1):
        var t := float(i) / float(samples)
        var context := political_context_at(world, start.lerp(finish, t))
        var key := String(context.state) + "|" + String(context.faction_id) + "|" + String(context.second_faction_id)
        if current.is_empty() or String(current.key) != key:
            if not current.is_empty():
                current.end_t = t
                groups.append(current)
            current = {
                "key": key,
                "state": String(context.state),
                "faction_id": String(context.faction_id),
                "strongest_faction_id": String(context.strongest_faction_id),
                "second_faction_id": String(context.second_faction_id),
                "start_t": t,
                "end_t": t
            }
        current.end_t = t
    if not current.is_empty():
        current.end_t = 1.0
        groups.append(current)
    for group in groups:
        group.erase("key")
    return groups

static func _danger_from_segments(segments: Array) -> int:
    if segments.is_empty():
        return 2
    var weighted := 0.0
    var total := 0.0
    var maximum := 1.0
    for segment in segments:
        var span := maxf(0.0, float(segment.end_t) - float(segment.start_t))
        var weight := float(DANGER_WEIGHT.get(String(segment.state), 2.0))
        weighted += span * weight
        total += span
        maximum = maxf(maximum, weight)
    var average := weighted / maxf(total, 0.001)
    return clampi(int(round(average * 0.72 + maximum * 0.28)), 1, 5)

static func direct_route(world: Dictionary, a: String, b: String) -> Dictionary:
    var eid := _edge_id(a, b)
    for route in world.get("routes", []):
        if String(route.id) == eid:
            return route.duplicate(true)
    return {}

static func neighbors(world: Dictionary, planet_id: String) -> Array[String]:
    var result: Array[String] = []
    for route in world.get("routes", []):
        if String(route.a) == planet_id:
            result.append(String(route.b))
        elif String(route.b) == planet_id:
            result.append(String(route.a))
    return result

static func route_spec(world: Dictionary, origin: String, destination: String) -> Dictionary:
    if origin == destination:
        return {"distance": 0, "danger": 1, "path": [origin], "hops": 0, "direct": true}
    var direct := direct_route(world, origin, destination)
    if not direct.is_empty():
        return {
            "distance": int(direct.distance),
            "danger": int(direct.danger),
            "path": [origin, destination],
            "hops": 1,
            "direct": true,
            "segments": direct.segments
        }

    var unvisited: Dictionary = {}
    var dist: Dictionary = {}
    var prev: Dictionary = {}
    for planet in world.get("planets", []):
        var pid := String(planet.id)
        unvisited[pid] = true
        dist[pid] = INF
    dist[origin] = 0.0

    while not unvisited.is_empty():
        var current := ""
        var best := INF
        for pid in unvisited.keys():
            if float(dist.get(pid, INF)) < best:
                best = float(dist[pid])
                current = String(pid)
        if current.is_empty() or best == INF:
            break
        unvisited.erase(current)
        if current == destination:
            break
        for next_id in neighbors(world, current):
            if not unvisited.has(next_id):
                continue
            var edge := direct_route(world, current, next_id)
            var alt := best + float(edge.get("distance", 1))
            if alt < float(dist.get(next_id, INF)):
                dist[next_id] = alt
                prev[next_id] = current

    if not prev.has(destination):
        return {"distance": 2, "danger": 2, "path": [], "hops": 0, "direct": false}

    var path: Array[String] = [destination]
    var cursor := destination
    while cursor != origin:
        cursor = String(prev[cursor])
        path.push_front(cursor)

    var total_distance := 0
    var danger_sum := 0.0
    var max_danger := 1
    for i in range(path.size() - 1):
        var edge := direct_route(world, path[i], path[i + 1])
        total_distance += int(edge.distance)
        danger_sum += float(edge.danger)
        max_danger = maxi(max_danger, int(edge.danger))
    var avg_danger := danger_sum / maxf(1.0, float(path.size() - 1))
    var final_danger := clampi(int(round(avg_danger * 0.7 + float(max_danger) * 0.3)), 1, 5)
    return {
        "distance": total_distance,
        "danger": final_danger,
        "path": path,
        "hops": path.size() - 1,
        "direct": false
    }

static func find_planet_by_type(world: Dictionary, type_id: String) -> String:
    for planet in world.get("planets", []):
        if String(planet.type) == type_id:
            return String(planet.id)
    return String(world.get("planets", [{}])[0].get("id", ""))

static func legacy_type_for_name(legacy_name: String) -> String:
    match legacy_name:
        "Cinder":
            return "VOLCANIC"
        "Vesper":
            return "FROZEN"
        "Helix":
            return "INDUSTRIAL"
    return "LUSH"

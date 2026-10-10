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

const LEGAL_COMMODITIES := [
    "Grain", "Protein", "Produce", "Luxury Food",
    "Iron", "Copper", "Titanium", "Rare Alloys",
    "First Aid", "Antibiotics", "Vaccines", "Regenerative Medicine"
]
const GREY_WEAPONS := ["Small Arms", "Heavy Weapons", "Explosives", "Military Tech"]
const GREY_NARCOTICS := ["Stims", "Sedatives", "Euphorics", "Neurodust"]
const GREY_ENTERTAINMENT := ["Holovids", "Sim Chips", "VR Experiences", "Unlicensed Media"]
const GREY_COMMODITIES := GREY_WEAPONS + GREY_NARCOTICS + GREY_ENTERTAINMENT
const ALL_COMMODITIES := LEGAL_COMMODITIES + GREY_COMMODITIES
const SPECIALTY_BY_TYPE := {
    "LUSH": ["Grain", "Protein", "Produce", "Luxury Food", "Stims", "Sedatives", "Euphorics", "Neurodust"],
    "VOLCANIC": ["Iron", "Copper", "Titanium", "Rare Alloys", "Explosives", "Heavy Weapons"],
    "FROZEN": ["First Aid", "Antibiotics", "Vaccines", "Regenerative Medicine", "Holovids", "VR Experiences"],
    "INDUSTRIAL": ["Copper", "Titanium", "Small Arms", "Heavy Weapons", "Military Tech", "Sim Chips", "VR Experiences", "Unlicensed Media"]
}
# Compatibility name retained for encounter/scan code. All grey goods are
# potentially restricted; the actual legality is faction + item specific.
const RESTRICTED_COMMODITIES := GREY_COMMODITIES

const RELATION_MIN := -100
const RELATION_MAX := 100
const HEAT_MIN := 0
const HEAT_MAX := 100
const CRIMINAL_HEAT_THRESHOLD := 30
const HEAVY_HEAT_THRESHOLD := 60
const CRIMINAL_RELATION_THRESHOLD := -60
const HEAVY_RELATION_THRESHOLD := -75
const FACTION_LEVEL_MIN := 1
const FACTION_LEVEL_MAX := 5

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
        "routes": [],
        "wars": [],
        "macro_tick": 0
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
        var specialty_pool: Array = SPECIALTY_BY_TYPE.get(planet_type, ALL_COMMODITIES)
        var specialty := String(specialty_pool[rng.randi_range(0, specialty_pool.size() - 1)])
        planets.append({
            "id": "p%02d" % i,
            "name": display_name,
            "type": planet_type,
            "pos": pos,
            "commodity_specialty": specialty
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
        var faction_strength := rng.randf_range(0.98, 1.16)
        var grey_legal: Dictionary = {}
        for category in [GREY_WEAPONS, GREY_NARCOTICS, GREY_ENTERTAINMENT]:
            var allowed_count: int = rng.randi_range(0, 4)
            var shuffled: Array = category.duplicate()
            for si in range(shuffled.size() - 1, 0, -1):
                var sj := rng.randi_range(0, si)
                var swap_value = shuffled[si]
                shuffled[si] = shuffled[sj]
                shuffled[sj] = swap_value
            for grey_good in category:
                grey_legal[String(grey_good)] = false
            for ai in allowed_count:
                grey_legal[String(shuffled[ai])] = true
        factions.append({
            "id": "f%02d" % i,
            "name": faction_name,
            "color": FACTION_COLORS[i % FACTION_COLORS.size()],
            "capital_id": capital_id,
            "radius": influence_radius,
            "strength": faction_strength,
            "base_radius": influence_radius,
            "base_strength": faction_strength,
            "treasury": 900.0 + float(level_from_strength(faction_strength)) * 250.0,
            "military": 90.0 + float(level_from_strength(faction_strength)) * 28.0,
            "trade_volume": 0.0,
            "war_weariness": 0.0,
            "war_cooldown": 0,
            "level": level_from_strength(faction_strength),
            "relation": 0,
            "heat": 0,
            "offenses": 0,
            "last_offense": "",
            "laws": {
                "grey_legal": grey_legal,
                # Legacy category flags are retained only so schema-2 careers
                # written before the 24-good economy remain intelligible.
                "arms_legal": combo == 0 or combo == 2,
                "narcotics_legal": combo == 0 or combo == 1
            }
        })
    return factions

static func specialty_for_planet(world: Dictionary, planet_id: String) -> String:
    var planet := planet_record(world, planet_id)
    var existing := String(planet.get("commodity_specialty", ""))
    if not existing.is_empty():
        return existing
    var planet_type_value := String(planet.get("type", "LUSH"))
    var pool: Array = SPECIALTY_BY_TYPE.get(planet_type_value, ALL_COMMODITIES)
    if pool.is_empty():
        return "Grain"
    var seed_value := int(world.get("seed", 1))
    var index := posmod(_stable_text_hash("%d|%s|%s" % [seed_value, planet_id, planet_type_value]), pool.size())
    return String(pool[index])

static func ensure_empire_schema(world: Dictionary) -> bool:
    var changed := false
    var planets: Array = world.get("planets", [])
    for i in planets.size():
        var planet: Dictionary = planets[i]
        if String(planet.get("commodity_specialty", "")).is_empty():
            var planet_type_value := String(planet.get("type", "LUSH"))
            var pool: Array = SPECIALTY_BY_TYPE.get(planet_type_value, ALL_COMMODITIES)
            var seed_value := int(world.get("seed", 1))
            var index := posmod(_stable_text_hash("%d|%s|%s" % [seed_value, String(planet.get("id", i)), planet_type_value]), pool.size())
            planet["commodity_specialty"] = String(pool[index])
            planets[i] = planet
            changed = true
    world["planets"] = planets

    var factions: Array = world.get("factions", [])
    for i in factions.size():
        var faction: Dictionary = factions[i]
        if not faction.has("base_radius"):
            faction["base_radius"] = float(faction.get("radius", 900.0))
            changed = true
        if not faction.has("base_strength"):
            faction["base_strength"] = float(faction.get("strength", 1.0))
            changed = true
        if not faction.has("treasury"):
            faction["treasury"] = 900.0 + float(faction_level(world, String(faction.get("id", "")))) * 250.0
            changed = true
        if not faction.has("military"):
            faction["military"] = 90.0 + float(faction_level(world, String(faction.get("id", "")))) * 28.0
            changed = true
        if not faction.has("trade_volume"):
            faction["trade_volume"] = 0.0
            changed = true
        if not faction.has("war_weariness"):
            faction["war_weariness"] = 0.0
            changed = true
        if not faction.has("war_cooldown"):
            faction["war_cooldown"] = 0
            changed = true
        factions[i] = faction
    world["factions"] = factions
    if not world.has("wars"):
        world["wars"] = []
        changed = true
    if not world.has("macro_tick"):
        world["macro_tick"] = 0
        changed = true
    return changed


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

static func level_from_strength(strength: float) -> int:
    var normalized := inverse_lerp(0.98, 1.16, clampf(strength, 0.98, 1.16))
    return clampi(1 + int(round(normalized * 4.0)), FACTION_LEVEL_MIN, FACTION_LEVEL_MAX)

static func ensure_enforcement_schema(world: Dictionary) -> bool:
    var changed := false
    var factions: Array = world.get("factions", [])
    for i in factions.size():
        var faction: Dictionary = factions[i]
        if not faction.has("level"):
            faction["level"] = level_from_strength(float(faction.get("strength", 1.0)))
            changed = true
        faction["level"] = clampi(int(faction.get("level", FACTION_LEVEL_MIN)), FACTION_LEVEL_MIN, FACTION_LEVEL_MAX)
        factions[i] = faction
    world["factions"] = factions
    return changed

static func faction_level(world: Dictionary, faction_id: String) -> int:
    var faction := faction_record(world, faction_id)
    return clampi(int(faction.get("level", level_from_strength(float(faction.get("strength", 1.0))))), FACTION_LEVEL_MIN, FACTION_LEVEL_MAX)

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

static func _stable_text_hash(value: String) -> int:
    var result: int = 2166136261
    for byte in value.to_utf8_buffer():
        result = int((result ^ int(byte)) * 16777619) & 0x7fffffff
    return result

static func ensure_grey_law_schema(world: Dictionary) -> bool:
    var changed := false
    var factions: Array = world.get("factions", [])
    var seed_value := int(world.get("seed", 1))
    for i in factions.size():
        var faction: Dictionary = factions[i]
        var laws: Dictionary = faction.get("laws", {}).duplicate(true)
        var grey: Dictionary = laws.get("grey_legal", {}).duplicate(true)
        if grey.size() != GREY_COMMODITIES.size():
            var local_rng := RandomNumberGenerator.new()
            local_rng.seed = seed_value * 1009 + _stable_text_hash(String(faction.get("id", i))) * 9176 + 73
            grey.clear()
            for category in [GREY_WEAPONS, GREY_NARCOTICS, GREY_ENTERTAINMENT]:
                var allowed_count := local_rng.randi_range(0, 4)
                var shuffled: Array = category.duplicate()
                for si in range(shuffled.size() - 1, 0, -1):
                    var sj := local_rng.randi_range(0, si)
                    var swap_value = shuffled[si]
                    shuffled[si] = shuffled[sj]
                    shuffled[sj] = swap_value
                for grey_good in category:
                    grey[String(grey_good)] = false
                for ai in allowed_count:
                    grey[String(shuffled[ai])] = true
            laws["grey_legal"] = grey
            faction["laws"] = laws
            factions[i] = faction
            changed = true
    if changed:
        world["factions"] = factions
    return changed

static func commodity_law_key(commodity: String) -> String:
    return commodity if GREY_COMMODITIES.has(commodity) else ""

static func faction_commodity_legal(world: Dictionary, faction_id: String, commodity: String) -> bool:
    if not GREY_COMMODITIES.has(commodity):
        return true
    var faction: Dictionary = faction_record(world, faction_id)
    if faction.is_empty():
        return true
    var laws: Dictionary = faction.get("laws", {})
    var grey: Dictionary = laws.get("grey_legal", {})
    if grey.has(commodity):
        return bool(grey.get(commodity, true))
    # Pre-economy-3 fallback until ensure_grey_law_schema() persists migration.
    if GREY_WEAPONS.has(commodity):
        return bool(laws.get("arms_legal", true))
    if GREY_NARCOTICS.has(commodity):
        return bool(laws.get("narcotics_legal", true))
    return true

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

    _assign_route_wealth(world, routes)
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

static func _distance_point_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
    var delta := finish - start
    var length_sq := delta.length_squared()
    if length_sq <= 0.0001:
        return point.distance_to(start)
    var t := clampf((point - start).dot(delta) / length_sq, 0.0, 1.0)
    return point.distance_to(start + delta * t)

static func _route_core_proximity(world: Dictionary, route: Dictionary) -> float:
    var start := planet_position(world, String(route.get("a", "")))
    var finish := planet_position(world, String(route.get("b", "")))
    var best := 0.0
    for faction in world.get("factions", []):
        var capital := planet_position(world, String(faction.get("capital_id", "")))
        var core_reach := maxf(175.0, float(faction.get("radius", 1.0)) * 0.34)
        var distance := _distance_point_to_segment(capital, start, finish)
        best = maxf(best, 1.0 - clampf(distance / core_reach, 0.0, 1.0))
    return clampf(best, 0.0, 1.0)

static func _route_traffic_counts(world: Dictionary, routes: Array) -> Dictionary:
    var adjacency: Dictionary = {}
    var planet_ids: Array[String] = []
    var counts: Dictionary = {}
    for planet in world.get("planets", []):
        var pid := String(planet.get("id", ""))
        planet_ids.append(pid)
        adjacency[pid] = []
    planet_ids.sort()
    for route in routes:
        var a := String(route.get("a", ""))
        var b := String(route.get("b", ""))
        var eid := String(route.get("id", _edge_id(a, b)))
        var weight := maxf(1.0, float(route.get("distance", 1)))
        counts[eid] = 0.0
        var a_edges: Array = adjacency.get(a, [])
        a_edges.append({"to": b, "id": eid, "weight": weight})
        adjacency[a] = a_edges
        var b_edges: Array = adjacency.get(b, [])
        b_edges.append({"to": a, "id": eid, "weight": weight})
        adjacency[b] = b_edges

    for source_index in range(planet_ids.size()):
        var source := String(planet_ids[source_index])
        var dist: Dictionary = {}
        var previous_node: Dictionary = {}
        var previous_edge: Dictionary = {}
        var unvisited: Dictionary = {}
        for pid in planet_ids:
            dist[pid] = INF
            unvisited[pid] = true
        dist[source] = 0.0

        while not unvisited.is_empty():
            var current := ""
            var best := INF
            for pid in unvisited.keys():
                var candidate := float(dist.get(pid, INF))
                if candidate < best:
                    best = candidate
                    current = String(pid)
            if current.is_empty() or best == INF:
                break
            unvisited.erase(current)
            for edge in adjacency.get(current, []):
                var next_id := String(edge.get("to", ""))
                if not unvisited.has(next_id):
                    continue
                var alt := best + float(edge.get("weight", 1.0))
                if alt < float(dist.get(next_id, INF)):
                    dist[next_id] = alt
                    previous_node[next_id] = current
                    previous_edge[next_id] = String(edge.get("id", ""))

        for target_index in range(source_index + 1, planet_ids.size()):
            var cursor := String(planet_ids[target_index])
            var guard := 0
            while cursor != source and previous_node.has(cursor) and guard < planet_ids.size():
                var eid := String(previous_edge.get(cursor, ""))
                if not eid.is_empty():
                    counts[eid] = float(counts.get(eid, 0.0)) + 1.0
                cursor = String(previous_node[cursor])
                guard += 1

    return counts

static func _assign_route_wealth(world: Dictionary, routes: Array) -> void:
    if routes.is_empty():
        return
    var traffic_counts := _route_traffic_counts(world, routes)
    var max_traffic := 1.0
    for value in traffic_counts.values():
        max_traffic = maxf(max_traffic, float(value))

    for route in routes:
        var eid := String(route.get("id", ""))
        var core_proximity := _route_core_proximity(world, route)
        var traffic_score := clampf(float(traffic_counts.get(eid, 0.0)) / max_traffic, 0.0, 1.0)
        var wealth_signal := maxf(core_proximity, traffic_score)
        route["core_proximity"] = core_proximity
        route["traffic_score"] = traffic_score
        route["wealth"] = clampi(1 + int(round(wealth_signal * 4.0)), 1, 5)

static func refresh_route_politics(world: Dictionary) -> void:
    var routes: Array = world.get("routes", [])
    for i in routes.size():
        var route: Dictionary = routes[i]
        route["segments"] = _segment_route(world, String(route.get("a", "")), String(route.get("b", "")))
        route["danger"] = _danger_from_segments(route["segments"])
        routes[i] = route
    _assign_route_wealth(world, routes)
    world["routes"] = routes

static func war_key(a: String, b: String) -> String:
    return a + "|" + b if a < b else b + "|" + a

static func factions_at_war(world: Dictionary, a: String, b: String) -> bool:
    var key := war_key(a, b)
    for war in world.get("wars", []):
        if String(war.get("key", "")) == key:
            return true
    return false

static func active_war_for_faction(world: Dictionary, faction_id: String) -> Dictionary:
    for war in world.get("wars", []):
        if String(war.get("a", "")) == faction_id or String(war.get("b", "")) == faction_id:
            return war
    return {}


static func ensure_route_wealth(world: Dictionary) -> bool:
    var routes: Array = world.get("routes", [])
    var changed := false
    for route in routes:
        if not route.has("wealth") or not route.has("core_proximity") or not route.has("traffic_score"):
            changed = true
            break
        if int(route.get("wealth", 0)) < 1 or int(route.get("wealth", 0)) > 5:
            changed = true
            break
    if changed:
        _assign_route_wealth(world, routes)
        world["routes"] = routes
    return changed

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

static func ship_jump_route(world: Dictionary, origin: String, destination: String) -> Dictionary:
    # Free-flight routes are derived from planet positions; the sparse trade
    # lane graph is preserved solely for trade, traffic, and economic simulation.
    if origin == destination or planet_record(world, origin).is_empty() or planet_record(world, destination).is_empty():
        return {}
    var lane := direct_route(world, origin, destination)
    if not lane.is_empty():
        return lane
    var start := planet_position(world, origin)
    var finish := planet_position(world, destination)
    var length_px := start.distance_to(finish)
    var segments := _segment_route(world, origin, destination)
    var midpoint := start.lerp(finish, 0.5)
    var nearest_traffic := INF
    var wealth := 1
    for candidate in world.get("routes", []):
        var a := planet_position(world, String(candidate.a))
        var b := planet_position(world, String(candidate.b))
        var separation := _distance_point_to_segment(midpoint, a, b)
        if separation < nearest_traffic:
            nearest_traffic = separation
            wealth = clampi(int(candidate.get("wealth", 1)), 1, 5)
    return {
        "id": _edge_id(origin, destination),
        "a": origin,
        "b": destination,
        "length": length_px,
        "distance": maxi(1, int(ceil(length_px / 155.0))),
        "segments": segments,
        "danger": _danger_from_segments(segments),
        "wealth": wealth,
        "virtual": true
    }

static func neighbors(world: Dictionary, planet_id: String): Array[String]:
    var result: Array[String] = []
    for route in world.get("routes", []):
        if String(route.a) == planet_id:
            result.append(String(route.b))
        elif String(route.b) == planet_id:
            result.append(String(route.a))
    return result

static func route_spec(world: Dictionary, origin: String, destination: String) -> Dictionary:
    if origin == destination:
        return {"distance": 0, "danger": 1, "wealth": 1, "path": [origin], "hops": 0, "direct": true}
    var direct := direct_route(world, origin, destination)
    if not direct.is_empty():
        return {
            "distance": int(direct.distance),
            "danger": int(direct.danger),
            "wealth": int(direct.get("wealth", 1)),
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
        return {"distance": 2, "danger": 2, "wealth": 1, "path": [], "hops": 0, "direct": false}

    var path: Array[String] = [destination]
    var cursor := destination
    while cursor != origin:
        cursor = String(prev[cursor])
        path.push_front(cursor)

    var total_distance := 0
    var danger_sum := 0.0
    var max_danger := 1
    var wealth_sum := 0.0
    var wealth_weight := 0.0
    for i in range(path.size() - 1):
        var edge := direct_route(world, path[i], path[i + 1])
        var edge_distance := maxi(1, int(edge.distance))
        total_distance += edge_distance
        danger_sum += float(edge.danger)
        max_danger = maxi(max_danger, int(edge.danger))
        wealth_sum += float(edge.get("wealth", 1)) * float(edge_distance)
        wealth_weight += float(edge_distance)
    var avg_danger := danger_sum / maxf(1.0, float(path.size() - 1))
    var final_danger := clampi(int(round(avg_danger * 0.7 + float(max_danger) * 0.3)), 1, 5)
    var final_wealth := clampi(int(round(wealth_sum / maxf(1.0, wealth_weight))), 1, 5)
    return {
        "distance": total_distance,
        "danger": final_danger,
        "wealth": final_wealth,
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

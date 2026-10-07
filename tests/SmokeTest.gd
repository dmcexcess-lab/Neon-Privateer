extends SceneTree

func _fail(message: String) -> void:
    print("PRIVATEER SMOKE FAIL: " + message)
    quit(1)

func _world_signature(world: Dictionary) -> String:
    var parts: Array[String] = []
    parts.append("schema=%d seed=%d" % [int(world.get("schema", 0)), int(world.get("seed", 0))])
    for planet in world.get("planets", []):
        var p: Vector2 = Vector2(planet.pos)
        parts.append("planet,%s,%s,%s,%.4f,%.4f" % [String(planet.id), String(planet.name), String(planet.type), p.x, p.y])
    for faction in world.get("factions", []):
        var laws: Dictionary = faction.laws
        var color: Color = Color(faction.color)
        parts.append("faction,%s,%s,%s,%.5f,%.5f,%.4f,%.4f,%.4f,%.4f,%s,%s" % [
            String(faction.id), String(faction.name), String(faction.capital_id),
            float(faction.radius), float(faction.strength),
            color.r, color.g, color.b, color.a,
            str(bool(laws.arms_legal)), str(bool(laws.narcotics_legal))
        ])
    for route in world.get("routes", []):
        parts.append("route,%s,%s,%s,%.5f,%d,%d" % [
            String(route.id), String(route.a), String(route.b),
            float(route.length), int(route.distance), int(route.danger)
        ])
        for segment in route.get("segments", []):
            parts.append("segment,%s,%s,%s,%.6f,%.6f" % [
                String(segment.state), String(segment.faction_id),
                String(segment.second_faction_id),
                float(segment.start_t), float(segment.end_t)
            ])
    return "\n".join(parts)

func _world_difference(a: Dictionary, b: Dictionary) -> String:
    if int(a.get("schema", 0)) != int(b.get("schema", 0)):
        return "schema"
    if int(a.get("seed", 0)) != int(b.get("seed", 0)):
        return "seed"
    if absf(float(a.get("control_threshold", 0.0)) - float(b.get("control_threshold", 0.0))) > 0.000001:
        return "control threshold"
    if absf(float(a.get("contest_ratio", 0.0)) - float(b.get("contest_ratio", 0.0))) > 0.000001:
        return "contest ratio"
    var ap: Array = a.get("planets", [])
    var bp: Array = b.get("planets", [])
    if ap.size() != bp.size():
        return "planet count"
    for i in ap.size():
        for key in ["id", "name", "type"]:
            if String(ap[i].get(key, "")) != String(bp[i].get(key, "")):
                return "planet %d %s" % [i, key]
        if Vector2(ap[i].pos).distance_to(Vector2(bp[i].pos)) > 0.001:
            return "planet %d position" % i

    var af: Array = a.get("factions", [])
    var bf: Array = b.get("factions", [])
    if af.size() != bf.size():
        return "faction count"
    for i in af.size():
        for key in ["id", "name", "capital_id"]:
            if String(af[i].get(key, "")) != String(bf[i].get(key, "")):
                return "faction %d %s" % [i, key]
        if absf(float(af[i].radius) - float(bf[i].radius)) > 0.001:
            return "faction %d radius" % i
        if absf(float(af[i].strength) - float(bf[i].strength)) > 0.0001:
            return "faction %d strength" % i
        if Color(af[i].color) != Color(bf[i].color):
            return "faction %d color" % i
        var al: Dictionary = af[i].laws
        var bl: Dictionary = bf[i].laws
        if bool(al.arms_legal) != bool(bl.arms_legal) or bool(al.narcotics_legal) != bool(bl.narcotics_legal):
            return "faction %d laws" % i
        if int(af[i].get("relation", 0)) != int(bf[i].get("relation", 0)):
            return "faction %d relation" % i
        if int(af[i].get("heat", 0)) != int(bf[i].get("heat", 0)):
            return "faction %d heat" % i
        if int(af[i].get("offenses", 0)) != int(bf[i].get("offenses", 0)):
            return "faction %d offenses" % i
        if String(af[i].get("last_offense", "")) != String(bf[i].get("last_offense", "")):
            return "faction %d last offense" % i

    var ar: Array = a.get("routes", [])
    var br: Array = b.get("routes", [])
    if ar.size() != br.size():
        return "route count"
    for i in ar.size():
        for key in ["id", "a", "b"]:
            if String(ar[i].get(key, "")) != String(br[i].get(key, "")):
                return "route %d %s" % [i, key]
        if int(ar[i].distance) != int(br[i].distance) or int(ar[i].danger) != int(br[i].danger):
            return "route %d rating" % i
        if absf(float(ar[i].length) - float(br[i].length)) > 0.001:
            return "route %d length" % i
        var aseg: Array = ar[i].segments
        var bseg: Array = br[i].segments
        if aseg.size() != bseg.size():
            return "route %d segment count" % i
        for j in aseg.size():
            for key in ["state", "faction_id", "strongest_faction_id", "second_faction_id"]:
                if String(aseg[j].get(key, "")) != String(bseg[j].get(key, "")):
                    return "route %d segment %d %s" % [i, j, key]
            if absf(float(aseg[j].start_t) - float(bseg[j].start_t)) > 0.0001 or absf(float(aseg[j].end_t) - float(bseg[j].end_t)) > 0.0001:
                return "route %d segment %d span" % [i, j]
    return ""

func _reachable_planets(scene, start_id: String) -> Dictionary:
    var seen: Dictionary = {start_id: true}
    var queue: Array[String] = [start_id]
    while not queue.is_empty():
        var current: String = String(queue.pop_front())
        for neighbor in scene.PoliticalWorld.neighbors(scene.political_world, current):
            if not seen.has(neighbor):
                seen[neighbor] = true
                queue.append(neighbor)
    return seen

func _initialize() -> void:
    var packed: PackedScene = load("res://main.tscn")
    if packed == null:
        _fail("main scene did not load")
        return

    var scene = packed.instantiate()
    if scene == null:
        _fail("main scene did not instantiate")
        return

    root.add_child(scene)
    await process_frame

    for method_name in [
        "_init_privateer_world", "_generate_political_world", "_sync_generated_planets",
        "_planet_display_name", "_planet_type", "_planet_visual_key",
        "_get_political_context_at", "_political_laws_at",
        "_commodity_legality_at", "_planet_commodity_legality",
        "_commodity_legality_short", "_planet_law_summary",
        "_planet_jurisdiction_label", "_ensure_commodity_schema", "_new_market_entry",
        "_ensure_crime_schema", "_faction_relation", "_faction_heat",
        "_faction_crime_state", "_is_criminal_with_faction",
        "_police_hostile_eligible", "_heavy_enforcement_eligible",
        "_adjust_faction_relation", "_adjust_faction_heat",
        "_record_faction_crime", "_decay_all_faction_heat",
        "_planet_faction_ids", "_faction_status_summary", "_planet_crime_summary",
        "_route_progress_fraction", "_current_flight_political_context",
        "_container_owner_for_context", "_container_owner_for_current_space",
        "_make_cargo_pickup", "_queue_asteroid_ore_drop",
        "_basic_container_commodity", "_reinforced_container_commodity",
        "_queue_container_loot", "_handle_container_break", "_collect_cargo_pickup",
        "_route_political_segment_at_progress", "_direct_route_spec",
        "_route_political_percentages", "_market_price", "_simulate_economy",
        "_buy_commodity", "_sell_commodity", "_route_spec", "_regenerate_contracts",
        "_accept_contract", "_route_level_for", "_route_duration_for", "_start_route",
        "_encounter_eligibility_for_context", "_current_encounter_eligibility",
        "_encounter_cooldown", "_encounter_duration", "_sync_legacy_pirate_state",
        "_start_route_encounter", "_end_route_encounter", "_update_route_encounter",
        "_update_pirate_attack", "_begin_bounty_boss", "_handle_route_end",
        "_arrive_at_destination", "_fail_route", "_save_privateer_state",
        "_load_privateer_state", "_save_all_state", "_start_game", "_dash",
        "_fire_weapon", "_choose_enemy_kind", "_apply_damage_to_hazard",
        "_save_run_snapshot", "_load_run_snapshot", "_pause_run",
        "_create_new_career", "_load_career", "_continue_career",
        "_career_slot_exists", "_career_slot_summary", "_open_profile_menu",
        "_load_privateer_ui_art", "_privateer_art_ready", "_planet_art_region",
        "_draw_menu_art", "_draw_planet_art", "_draw_menu_panel",
        "_system_planet_world_position", "_system_planet_position",
        "_system_planet_hit_rect", "_system_planet_at_screen", "_system_route_pairs",
        "_default_travel_selection", "_set_travel_selection",
        "_reset_system_map_view", "_pan_system_map", "_zoom_system_map",
        "_map_world_to_screen", "_map_screen_to_world",
        "_system_map_touch_begin", "_system_map_touch_drag", "_system_map_touch_end",
        "_next_hop_toward"
    ]:
        if not scene.has_method(method_name):
            _fail("missing method " + method_name)
            return

    if not scene._privateer_art_ready():
        _fail("Privateer native generated-art texture did not load")
        return

    # Four reusable archetype portraits remain distinct.
    var art_regions: Dictionary = {}
    for visual_key in ["Aster", "Cinder", "Vesper", "Helix"]:
        var art_region: Rect2 = scene._planet_art_region(visual_key)
        if art_region.size != Vector2(195.0, 192.0):
            _fail("planet art region has wrong size for " + visual_key)
            return
        var region_key: String = "%d,%d" % [int(art_region.position.x), int(art_region.position.y)]
        if art_regions.has(region_key):
            _fail("planet archetype art region is not unique for " + visual_key)
            return
        art_regions[region_key] = true

    if not scene.profile_menu_open or scene.active_career_slot != 0:
        _fail("game should boot at career menu with no active slot")
        return

    # Fresh career = one persistent 32-world political system.
    if not scene._create_new_career(1):
        _fail("could not create career slot 1")
        return
    if scene.planet_names.size() != 32 or scene.political_world.get("planets", []).size() != 32:
        _fail("new career did not generate exactly 32 planets")
        return
    if int(scene.political_world.get("schema", 0)) != scene.POLITICAL_WORLD_SCHEMA:
        _fail("political world schema is not current")
        return

    if scene.commodity_names.size() != 7 or not scene.commodity_names.has("Arms") or not scene.commodity_names.has("Narcotics"):
        _fail("Slice 2 commodity catalog is incomplete")
        return
    for commodity in scene.commodity_names:
        if not scene.cargo.has(commodity):
            _fail("fresh cargo schema missing " + commodity)
            return
    if scene._market_sell_rect(6).end.y >= scene.SUBMENU_BACK_RECT.position.y:
        _fail("seven-row market layout overlaps BACK control")
        return

    var ids: Dictionary = {}
    var names: Dictionary = {}
    var type_counts: Dictionary = {"LUSH": 0, "VOLCANIC": 0, "FROZEN": 0, "INDUSTRIAL": 0}
    var bounds: Rect2 = Rect2(scene.political_world.bounds)
    var planets: Array = scene.political_world.planets
    for planet in planets:
        var pid: String = String(planet.id)
        var pname: String = String(planet.name)
        var ptype: String = String(planet.type)
        if ids.has(pid):
            _fail("duplicate planet ID " + pid)
            return
        if names.has(pname):
            _fail("duplicate planet display name " + pname)
            return
        ids[pid] = true
        names[pname] = true
        type_counts[ptype] = int(type_counts.get(ptype, 0)) + 1
        if not bounds.has_point(Vector2(planet.pos)):
            _fail("planet outside generation bounds: " + pid)
            return
        if not scene.markets.has(pid):
            _fail("missing market for generated planet " + pid)
            return
        for commodity in scene.commodity_names:
            if not scene.markets[pid].has(commodity):
                _fail("generated market missing %s on %s" % [commodity, pid])
                return
    for type_id in type_counts.keys():
        if int(type_counts[type_id]) < 2:
            _fail("planet type is not represented multiple times: " + String(type_id))
            return

    for i in planets.size():
        for j in range(i + 1, planets.size()):
            if Vector2(planets[i].pos).distance_to(Vector2(planets[j].pos)) < 90.0:
                _fail("generated planets overlap too closely")
                return

    var lush: String = String(scene.PoliticalWorld.find_planet_by_type(scene.political_world, "LUSH"))
    var volcanic: String = String(scene.PoliticalWorld.find_planet_by_type(scene.political_world, "VOLCANIC"))
    var frozen: String = String(scene.PoliticalWorld.find_planet_by_type(scene.political_world, "FROZEN"))
    var industrial: String = String(scene.PoliticalWorld.find_planet_by_type(scene.political_world, "INDUSTRIAL"))
    for representative in [lush, volcanic, frozen, industrial]:
        if representative.is_empty():
            _fail("missing representative planet type")
            return
    if scene._planet_art_region(lush) == scene._planet_art_region(volcanic):
        _fail("generated planet type did not map to distinct archetype art")
        return

    if scene._market_profile(industrial, "Arms").x <= scene._market_profile(lush, "Arms").x:
        _fail("INDUSTRIAL worlds should produce more Arms than LUSH worlds")
        return
    if scene._market_profile(lush, "Narcotics").x <= scene._market_profile(industrial, "Narcotics").x:
        _fail("LUSH worlds should produce more Narcotics than INDUSTRIAL worlds")
        return
    if scene._commodity_base_price("Arms") <= scene._commodity_base_price("Electronics"):
        _fail("Arms base value is not integrated into commodity pricing")
        return
    if scene._commodity_base_price("Narcotics") <= scene._commodity_base_price("Arms"):
        _fail("Narcotics base value is not above Arms")
        return

    # Superpowers, capitals, laws, and geographic separation.
    var factions: Array = scene.political_world.factions
    if factions.size() < 2 or factions.size() > 4:
        _fail("superpower count is outside 2-4")
        return
    var capitals: Dictionary = {}
    var faction_names: Dictionary = {}
    var law_profiles: Dictionary = {}
    for faction in factions:
        var faction_name: String = String(faction.name)
        if faction_names.has(faction_name):
            _fail("duplicate generated faction name")
            return
        faction_names[faction_name] = true
        var capital_id: String = String(faction.capital_id)
        if not ids.has(capital_id) or capitals.has(capital_id):
            _fail("invalid or duplicate faction capital")
            return
        capitals[capital_id] = true
        var laws: Dictionary = faction.laws
        if not laws.has("arms_legal") or not laws.has("narcotics_legal"):
            _fail("faction law fields are incomplete")
            return
        if not faction.has("relation") or not faction.has("heat") or not faction.has("offenses") or not faction.has("last_offense"):
            _fail("fresh faction crime schema is incomplete")
            return
        if int(faction.relation) != 0 or int(faction.heat) != 0 or int(faction.offenses) != 0:
            _fail("fresh faction crime state is not clean")
            return
        law_profiles["%s|%s" % [str(laws.arms_legal), str(laws.narcotics_legal)]] = true
        var capital_context: Dictionary = scene._get_political_context_at(scene._system_planet_world_position(capital_id))
        if String(capital_context.state) != "CORE":
            _fail("faction capital is not CORE")
            return
        var arms_legality: Dictionary = scene._planet_commodity_legality(capital_id, "Arms")
        var narc_legality: Dictionary = scene._planet_commodity_legality(capital_id, "Narcotics")
        var expected_arms: String = "LEGAL" if bool(laws.arms_legal) else "ILLEGAL"
        var expected_narc: String = "LEGAL" if bool(laws.narcotics_legal) else "ILLEGAL"
        if String(arms_legality.status) != expected_arms or String(narc_legality.status) != expected_narc:
            _fail("capital commodity legality does not match faction law")
            return
        var food_legality: Dictionary = scene._planet_commodity_legality(capital_id, "Food")
        if String(food_legality.status) != "LEGAL" or bool(food_legality.regulated):
            _fail("ordinary commodities should not use contraband law")
            return
    if factions.size() > 1 and law_profiles.size() < 2:
        _fail("generated factions have no law variation")
        return
    var capital_list: Array = capitals.keys()
    for i in capital_list.size():
        for j in range(i + 1, capital_list.size()):
            if scene._system_planet_world_position(capital_list[i]).distance_to(scene._system_planet_world_position(capital_list[j])) < 420.0:
                _fail("faction capitals are too clustered")
                return

    # Slice 3: faction reputation and heat are independent, clamped, and thresholded.
    var primary_faction: String = String(factions[0].id)
    var secondary_faction: String = String(factions[1].id)
    if scene._faction_relation(primary_faction) != 0 or scene._faction_heat(primary_faction) != 0:
        _fail("fresh primary faction relation/heat is not zero")
        return

    scene._adjust_faction_heat(primary_faction, 10, false)
    var crime_state: Dictionary = scene._faction_crime_state(primary_faction)
    if String(crime_state.heat_label) != "WATCHED" or bool(crime_state.criminal):
        _fail("heat 10 should be WATCHED but not criminal")
        return

    scene._adjust_faction_heat(primary_faction, 20, false)
    crime_state = scene._faction_crime_state(primary_faction)
    if int(crime_state.heat) != 30 or String(crime_state.heat_label) != "WANTED" or not bool(crime_state.criminal) or not scene._police_hostile_eligible(primary_faction):
        _fail("heat 30 did not enter WANTED/police-hostile eligibility")
        return
    if scene._heavy_enforcement_eligible(primary_faction):
        _fail("heat 30 incorrectly enabled heavy enforcement")
        return

    scene._adjust_faction_heat(primary_faction, 30, false)
    crime_state = scene._faction_crime_state(primary_faction)
    if int(crime_state.heat) != 60 or String(crime_state.heat_label) != "HUNTED" or not scene._heavy_enforcement_eligible(primary_faction):
        _fail("heat 60 did not enable HUNTED/heavy enforcement")
        return

    scene._adjust_faction_heat(primary_faction, -1000, false)
    scene._adjust_faction_relation(primary_faction, -50, false)
    crime_state = scene._faction_crime_state(primary_faction)
    if int(crime_state.relation) != -50 or not bool(crime_state.criminal) or scene._heavy_enforcement_eligible(primary_faction):
        _fail("relation -50 did not independently create ordinary criminal status")
        return
    scene._adjust_faction_relation(primary_faction, -25, false)
    if not scene._heavy_enforcement_eligible(primary_faction):
        _fail("relation -75 did not enable heavy enforcement")
        return

    if scene._adjust_faction_relation(secondary_faction, 1000, false) != 100:
        _fail("positive relation did not clamp at +100")
        return
    if scene._adjust_faction_relation(secondary_faction, -1000, false) != -100:
        _fail("negative relation did not clamp at -100")
        return
    scene._adjust_faction_relation(secondary_faction, 100, false)
    if scene._adjust_faction_heat(secondary_faction, 1000, false) != 100:
        _fail("heat did not clamp at 100")
        return
    if scene._adjust_faction_heat(secondary_faction, -1000, false) != 0:
        _fail("heat did not clamp at zero")
        return
    if scene._faction_relation(secondary_faction) != 0 or scene._faction_heat(secondary_faction) != 0:
        _fail("secondary faction did not reset independently")
        return

    scene._adjust_faction_relation(primary_faction, 75, false)
    var recorded: Dictionary = scene._record_faction_crime(primary_faction, 12, 35, "smoke_test", false)
    if int(recorded.relation) != -12 or int(recorded.heat) != 35 or String(recorded.heat_label) != "WANTED":
        _fail("generic faction crime event did not apply relation loss/heat")
        return
    var primary_record: Dictionary = scene.PoliticalWorld.faction_record(scene.political_world, primary_faction)
    if int(primary_record.offenses) != 1 or String(primary_record.last_offense) != "smoke_test":
        _fail("generic faction crime event did not record offense metadata")
        return
    if scene._faction_relation(secondary_faction) != 0 or scene._faction_heat(secondary_faction) != 0:
        _fail("crime against one faction leaked to another")
        return
    if not scene._decay_all_faction_heat(5, false) or scene._faction_heat(primary_faction) != 30 or scene._faction_relation(primary_faction) != -12:
        _fail("heat decay did not reduce heat without changing relation")
        return
    if not scene._faction_status_summary(primary_faction).contains("WANTED"):
        _fail("faction status summary does not expose criminal state")
        return

    # The generated influence field must actually contain all four political states.
    var states_seen: Dictionary = {}
    var uncontrolled_sample := Vector2(INF, INF)
    var contested_sample := Vector2(INF, INF)
    for gy in 17:
        for gx in 23:
            var sample: Vector2 = bounds.position + Vector2(
                bounds.size.x * float(gx) / 22.0,
                bounds.size.y * float(gy) / 16.0
            )
            var context: Dictionary = scene._get_political_context_at(sample)
            states_seen[String(context.state)] = true
            if String(context.state) == "UNCONTROLLED" and not is_finite(uncontrolled_sample.x):
                uncontrolled_sample = sample
            if String(context.state) == "CONTESTED" and not is_finite(contested_sample.x):
                contested_sample = sample
    for required_state in ["CORE", "CONTROLLED", "CONTESTED", "UNCONTROLLED"]:
        if not states_seen.has(required_state):
            _fail("generated political field lacks state " + required_state)
            return

    var free_arms: Dictionary = scene._commodity_legality_at(uncontrolled_sample, "Arms")
    var free_narc: Dictionary = scene._commodity_legality_at(uncontrolled_sample, "Narcotics")
    if String(free_arms.status) != "UNREGULATED" or String(free_narc.status) != "UNREGULATED":
        _fail("uncontrolled space should report restricted commodities as unregulated")
        return
    var contested_arms: Dictionary = scene._commodity_legality_at(contested_sample, "Arms")
    if not ["LEGAL", "ILLEGAL", "MIXED"].has(String(contested_arms.status)):
        _fail("contested-space Arms legality returned invalid state")
        return

    # Sparse route graph is unique, connected and segmented.
    var routes: Array = scene.political_world.routes
    if routes.size() < 31 or routes.size() > 55:
        _fail("route graph density is outside expected sparse range")
        return
    var route_ids: Dictionary = {}
    var degree: Dictionary = {}
    var min_route_danger: int = 99
    var max_route_danger: int = -1
    var saw_contested_segment: bool = false
    var saw_core_segment: bool = false
    for pid in scene.planet_names:
        degree[pid] = 0
    for route in routes:
        var rid: String = String(route.id)
        if route_ids.has(rid):
            _fail("duplicate route edge " + rid)
            return
        route_ids[rid] = true
        degree[String(route.a)] = int(degree[String(route.a)]) + 1
        degree[String(route.b)] = int(degree[String(route.b)]) + 1
        if route.segments.is_empty():
            _fail("route has no political segments")
            return
        var first_t: float = float(route.segments[0].start_t)
        var last_t: float = float(route.segments[-1].end_t)
        if first_t > 0.001 or last_t < 0.999:
            _fail("route political segments do not cover full lane")
            return
        var derived: int = int(scene.PoliticalWorld._danger_from_segments(route.segments))
        if int(route.danger) != int(derived):
            _fail("stored route danger is not derived from segments")
            return
        min_route_danger = mini(min_route_danger, int(route.danger))
        max_route_danger = maxi(max_route_danger, int(route.danger))
        for segment in route.segments:
            if String(segment.state) == "CONTESTED":
                saw_contested_segment = true
            if String(segment.state) == "CORE":
                saw_core_segment = true
    if not saw_contested_segment or not saw_core_segment or max_route_danger <= min_route_danger:
        _fail("route politics do not produce meaningful danger variation")
        return
    var reachable: Dictionary = _reachable_planets(scene, scene.planet_names[0])
    if reachable.size() != 32:
        _fail("route graph is not fully connected")
        return
    var high_degree_count: int = 0
    for pid in degree.keys():
        if int(degree[pid]) < 1:
            _fail("planet has no route " + String(pid))
            return
        if int(degree[pid]) > 5:
            high_degree_count += 1
    if high_degree_count > factions.size() + 2:
        _fail("too many ordinary worlds have excessive route degree")
        return

    # Slice 5: territory and criminal state are authoritative for hostile encounters.
    var pirate_uncontrolled: Dictionary = scene._encounter_eligibility_for_context({
        "state": "UNCONTROLLED",
        "faction_id": "",
        "strongest_faction_id": "",
        "second_faction_id": ""
    })
    if not bool(pirate_uncontrolled.eligible) or String(pirate_uncontrolled.mode) != "pirate":
        _fail("UNCONTROLLED space is not pirate-eligible")
        return

    var pirate_contested: Dictionary = scene._encounter_eligibility_for_context({
        "state": "CONTESTED",
        "faction_id": "",
        "strongest_faction_id": primary_faction,
        "second_faction_id": secondary_faction
    })
    if not bool(pirate_contested.eligible) or String(pirate_contested.mode) != "pirate":
        _fail("CONTESTED space is not pirate-eligible")
        return

    # Heat 30 from the Slice 3 fixture makes primary faction ordinary-police eligible.
    var police_controlled: Dictionary = scene._encounter_eligibility_for_context({
        "state": "CONTROLLED",
        "faction_id": primary_faction,
        "strongest_faction_id": primary_faction,
        "second_faction_id": ""
    })
    if not bool(police_controlled.eligible) or String(police_controlled.mode) != "police" or String(police_controlled.faction_id) != primary_faction or bool(police_controlled.heavy):
        _fail("criminal player did not produce ordinary police eligibility in CONTROLLED space")
        return

    var clean_controlled: Dictionary = scene._encounter_eligibility_for_context({
        "state": "CONTROLLED",
        "faction_id": secondary_faction,
        "strongest_faction_id": secondary_faction,
        "second_faction_id": ""
    })
    if bool(clean_controlled.eligible):
        _fail("clean player incorrectly produced hostile police in CONTROLLED space")
        return

    scene._adjust_faction_heat(primary_faction, 30, false)
    var heavy_controlled: Dictionary = scene._encounter_eligibility_for_context({
        "state": "CORE",
        "faction_id": primary_faction,
        "strongest_faction_id": primary_faction,
        "second_faction_id": ""
    })
    if not bool(heavy_controlled.eligible) or String(heavy_controlled.mode) != "police" or not bool(heavy_controlled.heavy):
        _fail("heavy criminal threshold did not enable CORE heavy enforcement")
        return
    scene._adjust_faction_heat(primary_faction, -30, false)

    # Ship/platform kind selection obeys encounter role.
    scene.route_active = true
    scene.level = 10
    scene.encounter_active = true
    scene.encounter_mode = "pirate"
    scene.encounter_faction_id = ""
    scene.rng.seed = 51001
    var pirate_ship_count := 0
    var pirate_pentagon_count := 0
    for sample_index in 1800:
        var kind_pirate: int = scene._choose_enemy_kind(false)
        if kind_pirate == 3:
            pirate_ship_count += 1
        elif kind_pirate == 4:
            pirate_pentagon_count += 1
    if pirate_ship_count <= 0 or pirate_pentagon_count != 0:
        _fail("pirate encounter did not produce trapezoids-only hostile ships")
        return

    scene.encounter_mode = "police"
    scene.encounter_faction_id = primary_faction
    scene._adjust_faction_heat(primary_faction, -scene._faction_heat(primary_faction), false)
    scene._adjust_faction_heat(primary_faction, 30, false)
    scene.rng.seed = 51002
    var patrol_ship_count := 0
    var ordinary_pentagon_count := 0
    for sample_index in 1800:
        var kind_patrol: int = scene._choose_enemy_kind(false)
        if kind_patrol == 3:
            patrol_ship_count += 1
        elif kind_patrol == 4:
            ordinary_pentagon_count += 1
    if patrol_ship_count <= 0 or ordinary_pentagon_count != 0:
        _fail("ordinary police encounter spawned a pentagon or no patrol ships")
        return

    scene._adjust_faction_heat(primary_faction, 30, false)
    scene.rng.seed = 51003
    var heavy_pentagon_count := 0
    for sample_index in 1800:
        if scene._choose_enemy_kind(false) == 4:
            heavy_pentagon_count += 1
    if heavy_pentagon_count <= 0:
        _fail("heavy police encounter never spawned pentagon enforcement")
        return

    scene.encounter_active = false
    scene.encounter_mode = ""
    scene.encounter_faction_id = ""
    scene.rng.seed = 51004
    for sample_index in 1200:
        if scene._choose_enemy_kind(false) > 2:
            _fail("hostile ship spawned outside active territory-authorized encounter")
            return

    # Find real lane segments to prove current-route position controls the director.
    var pirate_route: Dictionary = {}
    var pirate_segment: Dictionary = {}
    var controlled_route: Dictionary = {}
    var controlled_segment: Dictionary = {}
    for route in routes:
        for segment in route.segments:
            var segment_state := String(segment.state)
            var segment_span: float = float(segment.end_t) - float(segment.start_t)
            if pirate_route.is_empty() and segment_span >= 0.03 and (segment_state == "CONTESTED" or segment_state == "UNCONTROLLED"):
                pirate_route = route
                pirate_segment = segment
            if controlled_route.is_empty() and segment_span >= 0.03 and (segment_state == "CORE" or segment_state == "CONTROLLED"):
                var segment_faction := String(segment.get("faction_id", segment.get("strongest_faction_id", "")))
                if not segment_faction.is_empty():
                    controlled_route = route
                    controlled_segment = segment
        if not pirate_route.is_empty() and not controlled_route.is_empty():
            break
    if pirate_route.is_empty() or controlled_route.is_empty():
        _fail("generated lanes lack segments needed for encounter-director verification")
        return

    # Pirate segment: clock expiry starts pirate contact regardless of route danger.
    scene.route_origin = String(pirate_route.a)
    scene.destination_planet = String(pirate_route.b)
    scene.route_duration = 100.0
    scene.elapsed = (float(pirate_segment.start_t) + float(pirate_segment.end_t)) * 50.0
    scene.route_active = true
    scene.boss_active = false
    scene.encounter_active = false
    scene.encounter_mode = ""
    scene.encounter_faction_id = ""
    scene.encounter_clock = 0.0
    scene._update_route_encounter(0.01)
    if not scene.encounter_active or scene.encounter_mode != "pirate":
        _fail("real contested/uncontrolled route segment did not start pirate encounter")
        return

    # Crossing into a clean controlled segment immediately ends the pirate window.
    var controlled_faction := String(controlled_segment.get("faction_id", controlled_segment.get("strongest_faction_id", "")))
    var old_controlled_relation: int = scene._faction_relation(controlled_faction)
    var old_controlled_heat: int = scene._faction_heat(controlled_faction)
    scene._adjust_faction_relation(controlled_faction, -old_controlled_relation, false)
    scene._adjust_faction_heat(controlled_faction, -old_controlled_heat, false)
    scene.route_origin = String(controlled_route.a)
    scene.destination_planet = String(controlled_route.b)
    scene.elapsed = (float(controlled_segment.start_t) + float(controlled_segment.end_t)) * 50.0
    scene._update_route_encounter(0.01)
    if scene.encounter_active:
        _fail("pirate encounter remained active after entering clean controlled space")
        return

    # Same controlled segment becomes police-eligible only after that faction is criminal.
    scene._adjust_faction_heat(controlled_faction, 30, false)
    scene.encounter_clock = 0.0
    scene._update_route_encounter(0.01)
    if not scene.encounter_active or scene.encounter_mode != "police" or scene.encounter_faction_id != controlled_faction:
        _fail("criminal player did not trigger faction patrol on real controlled route segment")
        return
    scene._end_route_encounter()
    scene._adjust_faction_heat(controlled_faction, -scene._faction_heat(controlled_faction), false)
    scene._adjust_faction_relation(controlled_faction, old_controlled_relation, false)
    scene._adjust_faction_heat(controlled_faction, old_controlled_heat, false)

    # Restore Slice 3 primary fixture for subsequent tests.
    scene._adjust_faction_relation(primary_faction, -scene._faction_relation(primary_faction) - 12, false)
    scene._adjust_faction_heat(primary_faction, -scene._faction_heat(primary_faction) + 30, false)
    scene.route_active = false
    scene.encounter_active = false
    scene.encounter_mode = ""
    scene.encounter_faction_id = ""

    # Initial map view fits all world centers and each hit target covers its node.
    scene._reset_system_map_view()
    for pid in scene.planet_names:
        var screen_pos: Vector2 = scene._system_planet_position(pid)
        if not scene.SYSTEM_MAP_RECT.grow(2.0).has_point(screen_pos):
            _fail("initial map view does not fit planet " + pid)
            return
        if not scene._system_planet_hit_rect(pid).has_point(screen_pos):
            _fail("map hit target misses planet center")
            return
        if scene._system_planet_at_screen(screen_pos) != pid:
            _fail("map nearest-node selection does not resolve planet center")
            return

    var original_pan: Vector2 = scene.system_map_pan
    scene._pan_system_map(Vector2(28.0, 17.0))
    if scene.system_map_pan == original_pan:
        _fail("system map pan did not move view")
        return
    scene._zoom_system_map(100.0, scene.SYSTEM_MAP_RECT.get_center())
    if scene.system_map_zoom > scene.SYSTEM_MAP_MAX_ZOOM + 0.001:
        _fail("system map zoom exceeded maximum")
        return
    scene._zoom_system_map(0.0001, scene.SYSTEM_MAP_RECT.get_center())
    if scene.system_map_zoom < scene.SYSTEM_MAP_MIN_ZOOM - 0.001:
        _fail("system map zoom went below minimum")
        return
    scene._reset_system_map_view()

    # Contract target is favored for selection, tapping selects without launch, drag does not launch.
    scene.current_planet = scene.planet_names[0]
    var contract_target: String = String(scene.planet_names[-1])
    scene.active_contract = {"type": "delivery", "destination": contract_target, "difficulty": 2, "reward": 500}
    if scene._default_travel_selection() != contract_target:
        _fail("map did not prioritize active contract destination")
        return
    var neighbor_list: Array[String] = scene.PoliticalWorld.neighbors(scene.political_world, scene.current_planet)
    if neighbor_list.is_empty():
        _fail("current world has no generated neighbor")
        return
    var neighbor: String = String(neighbor_list[0])
    scene.travel_open = true
    scene.hub_open = false
    scene.travel_selected_planet = ""
    var neighbor_screen: Vector2 = scene._system_planet_position(neighbor)
    scene._handle_travel_tap(neighbor_screen)
    if scene.travel_selected_planet != neighbor or scene.playing:
        _fail("planet tap did not select without launching")
        return
    scene.travel_selected_planet = ""
    scene._system_map_touch_begin(7, neighbor_screen)
    scene._system_map_touch_drag(7, neighbor_screen + Vector2(24, 0), Vector2(24, 0))
    scene._system_map_touch_end(7, neighbor_screen + Vector2(24, 0))
    if scene.playing or not scene.travel_selected_planet.is_empty():
        _fail("dragging system map accidentally selected/launched")
        return
    scene._handle_travel_tap(scene.SYSTEM_RESET_RECT.get_center())
    if absf(scene.system_map_zoom - 1.0) > 0.001 or scene.system_map_pan != Vector2.ZERO:
        _fail("CENTER did not reset map view")
        return
    scene.active_contract = {}

    # Slice 4: circles are asteroids; squares/diamonds are cargo containers.
    if scene._kill_score(0) != 0 or scene._kill_score(1) != 0 or scene._kill_score(2) != 0:
        _fail("asteroids/containers still award kill credits")
        return
    if scene._kill_score(3) <= 0 or scene._kill_score(4) <= 0:
        _fail("ship/platform kill scoring regressed before their later slice")
        return

    var controlled_context := {
        "state": "CONTROLLED",
        "faction_id": primary_faction,
        "strongest_faction_id": primary_faction,
        "second_faction_id": ""
    }
    if scene._container_owner_for_context(controlled_context) != primary_faction:
        _fail("controlled-space container did not inherit controlling faction")
        return
    var uncontrolled_context := {
        "state": "UNCONTROLLED",
        "faction_id": "",
        "strongest_faction_id": "",
        "second_faction_id": ""
    }
    if not scene._container_owner_for_context(uncontrolled_context).is_empty():
        _fail("uncontrolled-space container should be unowned")
        return
    var contested_context := {
        "state": "CONTESTED",
        "faction_id": "",
        "strongest_faction_id": primary_faction,
        "second_faction_id": secondary_faction
    }
    scene.rng.seed = 991
    var contested_owner: String = scene._container_owner_for_context(contested_context)
    if contested_owner != primary_faction and contested_owner != secondary_faction:
        _fail("contested container owner is not one of the claimant factions")
        return

    # Asteroid salvage is rare Ore and not generic kill loot.
    scene.pending_drops.clear()
    var asteroid_fixture := {
        "id": 70001, "type": "hazard", "kind": 0,
        "x": 190.0, "y": 200.0, "r": 20.0, "hard": false
    }
    if not scene._queue_asteroid_ore_drop(asteroid_fixture, 0.0):
        _fail("forced asteroid salvage roll did not drop Ore")
        return
    if scene.pending_drops.size() != 1 or String(scene.pending_drops[0].type) != "cargo" or String(scene.pending_drops[0].commodity) != "Ore" or int(scene.pending_drops[0].quantity) != 1:
        _fail("asteroid salvage payload is not one unit of Ore")
        return
    scene.pending_drops.clear()
    if scene._queue_asteroid_ore_drop(asteroid_fixture, 0.99) or not scene.pending_drops.is_empty():
        _fail("failed asteroid salvage roll still produced cargo")
        return

    # Basic crates produce one small random bundle; reinforced crates produce two larger premium bundles.
    scene.rng.seed = 4421
    scene.pending_drops.clear()
    var square_fixture := {
        "id": 70002, "type": "hazard", "kind": 1,
        "x": 170.0, "y": 220.0, "r": 17.0, "hard": false,
        "owner_faction": ""
    }
    var square_units: int = scene._queue_container_loot(square_fixture)
    if scene.pending_drops.size() != 1 or square_units < 1 or square_units > 2:
        _fail("basic container loot is not one small bundle")
        return
    if not scene.commodity_names.has(String(scene.pending_drops[0].commodity)):
        _fail("basic container produced unknown commodity")
        return

    scene.rng.seed = 4421
    scene.pending_drops.clear()
    var diamond_fixture := {
        "id": 70003, "type": "hazard", "kind": 2,
        "x": 210.0, "y": 220.0, "r": 17.0, "hard": false,
        "owner_faction": ""
    }
    var diamond_units: int = scene._queue_container_loot(diamond_fixture)
    if scene.pending_drops.size() != 2 or diamond_units < 4 or diamond_units > 6 or diamond_units <= square_units:
        _fail("reinforced container loot is not larger than basic-container loot")
        return
    var premium_goods := ["Electronics", "Arms", "Medicine", "Narcotics", "Fuel", "Ore"]
    for loot in scene.pending_drops:
        if not premium_goods.has(String(loot.commodity)):
            _fail("reinforced container used non-premium loot table")
            return

    # Owned container destruction damages only the owner's relation, records an offense, and adds no heat.
    scene._adjust_faction_relation(primary_faction, -scene._faction_relation(primary_faction), false)
    scene._adjust_faction_heat(primary_faction, -scene._faction_heat(primary_faction), false)
    scene._adjust_faction_relation(secondary_faction, -scene._faction_relation(secondary_faction), false)
    scene._adjust_faction_heat(secondary_faction, -scene._faction_heat(secondary_faction), false)
    var owner_record_before: Dictionary = scene.PoliticalWorld.faction_record(scene.political_world, primary_faction)
    var offenses_before: int = int(owner_record_before.get("offenses", 0))
    scene.pending_drops.clear()
    var owned_square := {
        "id": 70004, "type": "hazard", "kind": 1,
        "hp": 1.0, "max_hp": 4.0,
        "x": 180.0, "y": 200.0, "r": 17.0, "hard": false,
        "owner_faction": primary_faction
    }
    scene.score = 0
    if not scene._apply_damage_to_hazard(owned_square, 5.0):
        _fail("owned square did not break")
        return
    if scene.score != 0:
        _fail("breaking a square still awarded combat score")
        return
    if scene._faction_relation(primary_faction) != -scene.BASIC_CONTAINER_RELATION_LOSS or scene._faction_heat(primary_faction) != 0:
        _fail("owned square did not apply relation-only faction penalty")
        return
    var owner_record_after: Dictionary = scene.PoliticalWorld.faction_record(scene.political_world, primary_faction)
    if int(owner_record_after.get("offenses", 0)) != offenses_before + 1 or String(owner_record_after.get("last_offense", "")) != "container_theft":
        _fail("owned square crime metadata was not recorded")
        return
    if scene._faction_relation(secondary_faction) != 0 or scene._faction_heat(secondary_faction) != 0:
        _fail("owned-container penalty leaked to another faction")
        return

    scene._adjust_faction_relation(primary_faction, -scene._faction_relation(primary_faction), false)
    scene.pending_drops.clear()
    var owned_diamond := {
        "id": 70005, "type": "hazard", "kind": 2,
        "hp": 1.0, "max_hp": 12.0,
        "x": 200.0, "y": 200.0, "r": 17.0, "hard": false,
        "owner_faction": primary_faction
    }
    if not scene._apply_damage_to_hazard(owned_diamond, 20.0):
        _fail("owned reinforced container did not break")
        return
    if scene._faction_relation(primary_faction) != -scene.REINFORCED_CONTAINER_RELATION_LOSS or scene._faction_heat(primary_faction) != 0:
        _fail("reinforced container did not apply larger relation-only penalty")
        return
    if scene.pending_drops.size() != 2:
        _fail("reinforced container did not release two commodity bundles")
        return

    # Unowned containers remain consequence-free.
    scene._adjust_faction_relation(primary_faction, -scene._faction_relation(primary_faction), false)
    var unowned_square := owned_square.duplicate(true)
    unowned_square.hp = 1.0
    unowned_square.owner_faction = ""
    scene.pending_drops.clear()
    scene._apply_damage_to_hazard(unowned_square, 5.0)
    if scene._faction_relation(primary_faction) != 0 or scene._faction_heat(primary_faction) != 0:
        _fail("unowned container changed faction state")
        return

    # Cargo pickups obey hold capacity.
    for commodity in scene.commodity_names:
        scene.cargo[commodity] = 0
    var cargo_pickup: Dictionary = scene._make_cargo_pickup("Electronics", 3, scene.player_x, scene.player_y, false)
    if scene._collect_cargo_pickup(cargo_pickup) != 3 or int(scene.cargo.Electronics) != 3 or int(cargo_pickup.quantity) != 0:
        _fail("cargo pickup did not load available commodity units")
        return
    for commodity in scene.commodity_names:
        scene.cargo[commodity] = 0
    scene.cargo["Food"] = scene._cargo_capacity()
    var full_pickup: Dictionary = scene._make_cargo_pickup("Ore", 2, scene.player_x, scene.player_y, false)
    if scene._collect_cargo_pickup(full_pickup) != 0 or int(full_pickup.quantity) != 2:
        _fail("full hold consumed cargo pickup")
        return
    for commodity in scene.commodity_names:
        scene.cargo[commodity] = 0

    # Containers have no self-propelled lateral motion and cannot trigger near-miss credits.
    scene.playing = true
    scene.invuln = 99.0
    scene.player_x = 195.0
    scene.player_y = scene.PLAYER_Y
    scene.target_x = scene.player_x
    scene.last_near_ids.clear()
    scene.score = 0
    var square_x: float = float(scene.player_x) + 37.0
    var moving_square := {
        "id": 70006, "type": "hazard", "kind": 1,
        "hp": 4.0, "max_hp": 4.0, "hard": false,
        "x": square_x, "y": scene.player_y + 19.0,
        "r": 17.0, "speed": 10.0, "drift": 80.0,
        "shoot_clock": 999.0, "angle": 0.0, "spin": 0.0,
        "lane_min": scene.LEFT, "lane_max": scene.RIGHT,
        "owner_faction": ""
    }
    scene.objects.clear()
    scene.objects.append(moving_square)
    scene._move_objects(0.01)
    if scene.objects.is_empty() or absf(float(scene.objects[0].x) - square_x) > 0.001:
        _fail("square container still has lateral movement")
        return
    if scene.score != 0:
        _fail("square container triggered near-miss credits")
        return

    scene.last_near_ids.clear()
    scene.score = 0
    var moving_diamond := moving_square.duplicate(true)
    moving_diamond.id = 70007
    moving_diamond.kind = 2
    moving_diamond.hp = 12.0
    moving_diamond.max_hp = 12.0
    moving_diamond.x = square_x
    moving_diamond.drift = -80.0
    scene.objects.clear()
    scene.objects.append(moving_diamond)
    scene._move_objects(0.01)
    if scene.objects.is_empty() or absf(float(scene.objects[0].x) - square_x) > 0.001:
        _fail("diamond container still has lateral movement")
        return
    if scene.score != 0:
        _fail("diamond container triggered near-miss credits")
        return

    # The equivalent asteroid pass still awards near-miss credits and asteroid destruction gives no kill credits.
    scene.last_near_ids.clear()
    scene.score = 0
    var near_asteroid := moving_square.duplicate(true)
    near_asteroid.id = 70008
    near_asteroid.kind = 0
    near_asteroid.hp = 3.0
    near_asteroid.max_hp = 3.0
    near_asteroid.x = square_x
    near_asteroid.drift = 0.0
    scene.objects.clear()
    scene.objects.append(near_asteroid)
    scene._move_objects(0.01)
    if scene.score <= 0:
        _fail("asteroid no longer awards near-miss credits")
        return

    scene.pending_drops.clear()
    scene.score = 0
    var kill_asteroid := asteroid_fixture.duplicate(true)
    kill_asteroid.hp = 1.0
    kill_asteroid.max_hp = 3.0
    scene.rng.seed = 7777
    scene._apply_damage_to_hazard(kill_asteroid, 9.0)
    if scene.score != 0:
        _fail("destroyed asteroid still awarded kill credits")
        return

    # Reinforced containers are materially rarer than basic containers at the same route cap.
    scene.route_active = true
    scene.encounter_active = false
    scene.encounter_mode = ""
    scene.encounter_faction_id = ""
    scene.pirate_attack_active = false
    scene.level = 5
    scene.rng.seed = 81173
    var square_count := 0
    var diamond_count := 0
    for sample_index in 2000:
        var sampled_kind: int = scene._choose_enemy_kind(false)
        if sampled_kind == 1:
            square_count += 1
        elif sampled_kind == 2:
            diamond_count += 1
    if diamond_count <= 0 or square_count <= diamond_count * 3:
        _fail("reinforced containers are not substantially rarer than basic containers")
        return
    scene.route_active = false
    scene.playing = false
    scene.objects.clear()
    scene.pending_drops.clear()
    scene.score = 0

    # Save/reload must reproduce the exact political world and current faction state.
    var expected_primary_relation: int = scene._faction_relation(primary_faction)
    var expected_primary_heat: int = scene._faction_heat(primary_faction)
    var expected_primary_record: Dictionary = scene.PoliticalWorld.faction_record(scene.political_world, primary_faction)
    var expected_primary_offenses: int = int(expected_primary_record.get("offenses", 0))
    var expected_primary_last_offense: String = String(expected_primary_record.get("last_offense", ""))
    var world_before: Dictionary = scene.political_world.duplicate(true)
    scene.cargo["Arms"] = 1
    scene.cargo["Narcotics"] = 2
    var signature_before: String = _world_signature(scene.political_world)
    if signature_before.is_empty():
        _fail("political world signature unexpectedly empty")
        return
    var seed_before: int = int(scene.world_seed)
    var location_before: String = String(scene.current_planet)
    scene._save_all_state()
    scene.political_world.clear()
    scene.planet_names.clear()
    scene.current_planet = ""
    scene.markets.clear()
    scene._load_privateer_state()
    if scene.world_seed != seed_before or scene.current_planet != location_before:
        _fail("political world save/reload changed seed or location")
        return
    if int(scene.cargo.get("Arms", 0)) != 1 or int(scene.cargo.get("Narcotics", 0)) != 2:
        _fail("Arms/Narcotics cargo did not persist")
        return
    if scene._faction_relation(primary_faction) != expected_primary_relation or scene._faction_heat(primary_faction) != expected_primary_heat:
        _fail("faction relation/heat did not persist")
        return
    var persisted_primary: Dictionary = scene.PoliticalWorld.faction_record(scene.political_world, primary_faction)
    if int(persisted_primary.get("offenses", 0)) != expected_primary_offenses or String(persisted_primary.get("last_offense", "")) != expected_primary_last_offense:
        _fail("faction offense metadata did not persist")
        return
    var reload_difference: String = _world_difference(world_before, scene.political_world)
    if not reload_difference.is_empty():
        _fail("political world save/reload changed " + reload_difference)
        return

    # Existing political-schema careers upgrade crime fields in place without rerolling.
    var pre_crime_upgrade_seed: int = int(scene.world_seed)
    var pre_crime_upgrade_first_planet: String = String(scene.political_world.planets[0].id)
    var crime_upgrade_cfg: ConfigFile = ConfigFile.new()
    if crime_upgrade_cfg.load(scene._active_world_path()) != OK:
        _fail("could not load career for crime-schema migration fixture")
        return
    var old_crime_world: Dictionary = crime_upgrade_cfg.get_value("political", "world", {}).duplicate(true)
    var old_factions: Array = old_crime_world.get("factions", [])
    for fi in old_factions.size():
        var old_faction: Dictionary = old_factions[fi]
        old_faction.erase("heat")
        old_faction.erase("offenses")
        old_faction.erase("last_offense")
        old_factions[fi] = old_faction
    old_factions[0]["relation"] = -7
    old_crime_world["factions"] = old_factions
    crime_upgrade_cfg.set_value("political", "world", old_crime_world)
    crime_upgrade_cfg.set_value("world", "crime_schema", 0)
    if crime_upgrade_cfg.save(scene._active_world_path()) != OK:
        _fail("could not write crime-schema migration fixture")
        return
    scene.political_world.clear()
    scene.planet_names.clear()
    scene.markets.clear()
    scene.current_planet = ""
    scene._load_privateer_state()
    if scene.world_seed != pre_crime_upgrade_seed or String(scene.political_world.planets[0].id) != pre_crime_upgrade_first_planet:
        _fail("crime-schema upgrade rerolled the political world")
        return
    var upgraded_faction: Dictionary = scene.PoliticalWorld.faction_record(scene.political_world, primary_faction)
    if int(upgraded_faction.get("relation", 0)) != -7 or int(upgraded_faction.get("heat", -1)) != 0 or int(upgraded_faction.get("offenses", -1)) != 0 or String(upgraded_faction.get("last_offense", "x")) != "":
        _fail("crime-schema upgrade did not preserve relation/add clean criminal fields")
        return
    var crime_upgrade_saved: ConfigFile = ConfigFile.new()
    if crime_upgrade_saved.load(scene._active_world_path()) != OK or int(crime_upgrade_saved.get_value("world", "crime_schema", 0)) != scene.CRIME_SCHEMA_VERSION:
        _fail("crime-schema upgrade did not persist schema version")
        return

    # Career slots remain isolated under generated worlds.
    scene.research_credits = 4321
    scene.cargo["Food"] = 2
    var slot_one_planet: String = String(scene.current_planet)
    scene._save_all_state()
    if not scene._create_new_career(2):
        _fail("could not create career slot 2")
        return
    if scene.research_credits != 1200 or int(scene.cargo.get("Food", 0)) != 0:
        _fail("new career inherited credits/cargo")
        return
    scene.research_credits = 2222
    scene._save_all_state()
    if not scene._load_career(1):
        _fail("could not reload career slot 1")
        return
    if scene.research_credits != 4321 or scene.current_planet != slot_one_planet or int(scene.cargo.get("Food", 0)) != 2:
        _fail("career slot 1 did not restore isolated generated state")
        return

    # Legacy four-world world file migrates once to schema 2 and matching archetype.
    if not scene._create_new_career(3):
        _fail("could not create career slot 3 for migration test")
        return
    var legacy_cfg: ConfigFile = ConfigFile.new()
    legacy_cfg.set_value("world", "planet", "Cinder")
    legacy_cfg.set_value("world", "markets", {})
    legacy_cfg.set_value("world", "cargo", {"Food": 1, "Ore": 0, "Medicine": 0, "Electronics": 0, "Fuel": 0})
    legacy_cfg.set_value("world", "contracts", [])
    legacy_cfg.set_value("world", "active_contract", {})
    legacy_cfg.set_value("world", "passengers", 0)
    legacy_cfg.set_value("world", "economy_tick", 9)
    legacy_cfg.set_value("world", "summary", "Legacy")
    if legacy_cfg.save(scene._active_world_path()) != OK:
        _fail("could not write legacy migration fixture")
        return
    scene.political_world.clear()
    scene.planet_names.clear()
    scene.markets.clear()
    scene.current_planet = ""
    scene._load_privateer_state()
    if scene._planet_type(scene.current_planet) != "VOLCANIC":
        _fail("legacy Cinder location did not migrate to VOLCANIC world")
        return
    if int(scene.cargo.get("Arms", -1)) != 0 or int(scene.cargo.get("Narcotics", -1)) != 0:
        _fail("legacy five-commodity cargo did not gain zeroed restricted commodities")
        return
    for migrated_planet in scene.planet_names:
        if not scene.markets[migrated_planet].has("Arms") or not scene.markets[migrated_planet].has("Narcotics"):
            _fail("legacy market migration did not add restricted commodities")
            return
    var migrated_seed: int = int(scene.world_seed)
    var migrated_world_before: Dictionary = scene.political_world.duplicate(true)
    var migrated_signature: String = _world_signature(scene.political_world)
    if migrated_signature.is_empty():
        _fail("migrated world signature unexpectedly empty")
        return
    var migrated_cfg: ConfigFile = ConfigFile.new()
    if migrated_cfg.load(scene._active_world_path()) != OK or int(migrated_cfg.get_value("political", "schema", 0)) != scene.POLITICAL_WORLD_SCHEMA:
        _fail("legacy migration did not persist new political schema")
        return
    if int(migrated_cfg.get_value("world", "economy_schema", 0)) != scene.ECONOMY_SCHEMA_VERSION:
        _fail("legacy migration did not persist Slice 2 economy schema")
        return
    if int(migrated_cfg.get_value("world", "crime_schema", 0)) != scene.CRIME_SCHEMA_VERSION:
        _fail("legacy migration did not persist Slice 3 crime schema")
        return
    scene.political_world.clear()
    scene.planet_names.clear()
    scene.markets.clear()
    scene.current_planet = ""
    scene._load_privateer_state()
    if scene.world_seed != migrated_seed:
        _fail("migrated legacy career changed seed on reload")
        return
    var migration_difference: String = _world_difference(migrated_world_before, scene.political_world)
    if not migration_difference.is_empty():
        _fail("migrated legacy career changed " + migration_difference)
        return

    # Return to a clean generated career for economy/contract/flight regression.
    if not scene._create_new_career(1):
        _fail("could not reset career 1 for gameplay regression")
        return
    lush = scene.PoliticalWorld.find_planet_by_type(scene.political_world, "LUSH")
    volcanic = scene.PoliticalWorld.find_planet_by_type(scene.political_world, "VOLCANIC")
    scene.current_planet = lush

    # Market prices remain stock-sensitive on generated planets.
    scene.research_credits = 5000
    scene.cargo["Food"] = 0
    var food_data: Dictionary = scene.markets[lush]["Food"]
    food_data.stock = 70.0
    scene.markets[lush]["Food"] = food_data
    var food_mid_before: int = scene._market_price(lush, "Food")
    var food_buy_before: int = scene._market_buy_price(lush, "Food")
    var food_sell_before: int = scene._market_sell_price(lush, "Food")
    if food_buy_before <= food_mid_before or food_sell_before >= food_mid_before:
        _fail("market bid/ask spread is invalid")
        return
    var credits_before_buy: int = int(scene.research_credits)
    if not scene._buy_commodity("Food"):
        _fail("could not buy generated-world commodity")
        return
    if scene.research_credits != credits_before_buy - food_buy_before or int(scene.cargo.Food) != 1:
        _fail("commodity buy did not update credits/cargo")
        return
    if not scene._sell_commodity("Food") or int(scene.cargo.Food) != 0:
        _fail("commodity sell failed")
        return

    scene.current_planet = industrial
    scene.research_credits = 10000
    scene.cargo["Arms"] = 0
    var arms_data: Dictionary = scene.markets[industrial]["Arms"]
    arms_data.stock = maxf(5.0, float(arms_data.stock))
    scene.markets[industrial]["Arms"] = arms_data
    if not scene._buy_commodity("Arms") or int(scene.cargo.Arms) != 1:
        _fail("could not trade Arms commodity")
        return
    if not scene._sell_commodity("Arms") or int(scene.cargo.Arms) != 0:
        _fail("could not sell Arms commodity")
        return
    scene.current_planet = lush

    var ore: Dictionary = scene.markets[volcanic]["Ore"]
    ore.stock = 40.0
    ore.production = 10.0
    ore.consumption = 2.0
    scene.markets[volcanic]["Ore"] = ore
    scene.rng.seed = 12345
    scene._simulate_economy(2)
    if float(scene.markets[volcanic]["Ore"].stock) <= 40.0:
        _fail("generated-world economy did not simulate production")
        return

    # Contract board still supplies all three contract classes against generated IDs.
    scene.current_planet = lush
    scene.active_contract.clear()
    scene.rng.seed = 4242
    scene._regenerate_contracts()
    var saw_delivery: bool = false
    var saw_passenger: bool = false
    var saw_bounty: bool = false
    for contract in scene.contract_board:
        if not scene.planet_names.has(String(contract.destination)):
            _fail("contract destination is not generated planet ID")
            return
        match String(contract.type):
            "delivery": saw_delivery = true
            "passenger": saw_passenger = true
            "bounty": saw_bounty = true
    if not saw_delivery or not saw_passenger or not saw_bounty:
        _fail("contract board lost required job classes")
        return

    # Route planning scales and actual launch uses a real direct lane.
    var all_specs: Array = []
    for route in scene.political_world.routes:
        all_specs.append({"distance": int(route.distance), "danger": int(route.danger)})
    all_specs.sort_custom(func(a, b): return int(a.distance) + int(a.danger) < int(b.distance) + int(b.danger))
    var easy_spec: Dictionary = all_specs[0]
    var hard_spec: Dictionary = all_specs[-1]
    if scene._route_duration_for(int(hard_spec.distance), int(hard_spec.danger), 0) <= scene._route_duration_for(int(easy_spec.distance), int(easy_spec.danger), 0):
        _fail("generated route difficulty does not scale flight duration")
        return

    scene.current_planet = scene.planet_names[0]
    neighbor_list = scene.PoliticalWorld.neighbors(scene.political_world, scene.current_planet)
    neighbor = neighbor_list[0]
    if not scene._start_route(neighbor):
        _fail("could not launch generated direct lane")
        return
    if not scene.playing or not scene.route_active or scene.destination_planet != neighbor:
        _fail("generated direct lane did not enter flight mode")
        return

    # Active route snapshot preserves generated IDs and Slice 5 encounter context.
    scene.elapsed = 7.5
    scene.score = 4
    scene.encounter_active = true
    scene.encounter_mode = "police"
    scene.encounter_faction_id = primary_faction
    scene.encounter_timer = 3.25
    scene.encounter_clock = 9.5
    scene._sync_legacy_pirate_state()
    scene._pause_run()
    if not scene._load_run_snapshot():
        _fail("generated route snapshot could not reload")
        return
    if scene.destination_planet != neighbor or scene.route_origin != scene.current_planet or absf(scene.elapsed - 7.5) > 0.01:
        _fail("route snapshot did not preserve generated route identity")
        return
    if not scene.encounter_active or scene.encounter_mode != "police" or scene.encounter_faction_id != primary_faction or absf(scene.encounter_timer - 3.25) > 0.01:
        _fail("route snapshot did not preserve Slice 5 encounter context")
        return
    scene._end_route_encounter()

    # Pre-Slice-5 pirate-only run snapshots migrate into generic encounter state.
    var legacy_run_cfg: ConfigFile = ConfigFile.new()
    if legacy_run_cfg.load(scene._active_run_path()) != OK:
        _fail("could not load run snapshot for Slice 5 legacy fixture")
        return
    for encounter_key in [
        "encounter_active", "encounter_mode", "encounter_faction_id",
        "encounter_timer", "encounter_clock", "encounter_banner_timer"
    ]:
        legacy_run_cfg.erase_section_key("run", encounter_key)
    legacy_run_cfg.set_value("run", "pirate_active", true)
    legacy_run_cfg.set_value("run", "pirate_timer", 2.75)
    legacy_run_cfg.set_value("run", "pirate_clock", 8.25)
    if legacy_run_cfg.save(scene._active_run_path()) != OK:
        _fail("could not write Slice 5 legacy run fixture")
        return
    scene.encounter_active = false
    scene.encounter_mode = ""
    scene.encounter_faction_id = ""
    scene.encounter_timer = 0.0
    scene.encounter_clock = 999.0
    if not scene._load_run_snapshot():
        _fail("legacy pirate-only run snapshot did not reload")
        return
    if not scene.encounter_active or scene.encounter_mode != "pirate" or not scene.pirate_attack_active or absf(scene.encounter_timer - 2.75) > 0.01:
        _fail("legacy pirate-only snapshot did not migrate to generic PIRATE encounter")
        return
    scene._end_route_encounter()

    # Arrival still banks flight score and advances to the generated destination.
    scene.run_paused = false
    scene.playing = true
    scene.score = 6
    var credits_before_arrival: int = int(scene.research_credits)
    scene._arrive_at_destination()
    if scene.current_planet != neighbor or scene.route_active or scene.playing:
        _fail("generated route did not arrive normally")
        return
    if scene.research_credits < credits_before_arrival + 6:
        _fail("arrival did not bank flight bonus")
        return

    # Delivery contract on a direct lane still reserves cargo and pays.
    var delivery_origin: String = String(scene.current_planet)
    var delivery_neighbors: Array[String] = scene.PoliticalWorld.neighbors(scene.political_world, delivery_origin)
    var delivery_dest: String = String(delivery_neighbors[0])
    scene.active_contract.clear()
    scene.contract_board.clear()
    scene.contract_board.append({"id": 9001, "type": "delivery", "destination": delivery_dest, "difficulty": 2, "reward": 500})
    var cargo_used_before: int = int(scene._cargo_used())
    if not scene._accept_contract(0) or scene._cargo_used() != cargo_used_before + 1:
        _fail("delivery did not reserve cargo")
        return
    var delivery_reward: int = int(scene.active_contract.reward)
    var credits_before_delivery: int = int(scene.research_credits)
    if not scene._start_route(delivery_dest):
        _fail("could not launch direct delivery route")
        return
    scene.score = 3
    scene._arrive_at_destination()
    if scene.current_planet != delivery_dest or scene.research_credits < credits_before_delivery + delivery_reward + 3:
        _fail("delivery did not complete/pay on generated arrival")
        return

    # Passenger capacity remains separate.
    var pax_neighbors: Array[String] = scene.PoliticalWorld.neighbors(scene.political_world, scene.current_planet)
    scene.active_contract.clear()
    scene.passengers = 0
    scene.contract_board.clear()
    scene.contract_board.append({"id": 9002, "type": "passenger", "destination": pax_neighbors[0], "difficulty": 1, "reward": 350})
    if not scene._accept_contract(0) or scene.passengers != 1:
        _fail("passenger contract did not reserve berth")
        return

    # Bounty still requires an armed permanent starting weapon; encounter behavior itself is unchanged this slice.
    scene.active_contract.clear()
    scene.passengers = 0
    scene.contract_board.clear()
    scene.contract_board.append({"id": 9003, "type": "bounty", "destination": pax_neighbors[0], "difficulty": 3, "reward": 900})
    scene.starting_weapon = "none"
    scene.research_start_single = false
    if scene._accept_contract(0):
        _fail("unarmed ship accepted bounty")
        return
    scene.research_start_single = true
    scene.starting_weapon = "single"
    if not scene._accept_contract(0):
        _fail("armed ship could not accept bounty")
        return

    # Basic arcade controls remain intact.
    scene.active_contract.clear()
    scene._fail_route("TEST RESET")
    scene.current_planet = scene.planet_names[0]
    var dash_neighbor: Array[String] = scene.PoliticalWorld.neighbors(scene.political_world, scene.current_planet)
    if not scene._start_route(dash_neighbor[0]):
        _fail("could not start route for arcade regression")
        return
    scene.dash_cooldown = 0.0
    scene.dash_timer = 0.0
    scene._dash()
    if scene.dash_timer <= 0.0 or scene.dash_cooldown <= 0.0:
        _fail("dash mechanic changed during political slice")
        return

    print("NEON PRIVATEER SMOKE OK")
    quit(0)

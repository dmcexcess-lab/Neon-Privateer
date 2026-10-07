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
        "_route_political_segment_at_progress", "_direct_route_spec",
        "_route_political_percentages", "_market_price", "_simulate_economy",
        "_buy_commodity", "_sell_commodity", "_route_spec", "_regenerate_contracts",
        "_accept_contract", "_route_level_for", "_route_duration_for", "_start_route",
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
        "_system_planet_hit_rect", "_system_route_pairs",
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

    # Superpowers, capitals, laws, and geographic separation.
    var factions: Array = scene.political_world.factions
    if factions.size() < 2 or factions.size() > 4:
        _fail("superpower count is outside 2-4")
        return
    var capitals: Dictionary = {}
    var law_profiles: Dictionary = {}
    for faction in factions:
        var capital_id: String = String(faction.capital_id)
        if not ids.has(capital_id) or capitals.has(capital_id):
            _fail("invalid or duplicate faction capital")
            return
        capitals[capital_id] = true
        var laws: Dictionary = faction.laws
        if not laws.has("arms_legal") or not laws.has("narcotics_legal"):
            _fail("faction law fields are incomplete")
            return
        law_profiles["%s|%s" % [str(laws.arms_legal), str(laws.narcotics_legal)]] = true
        var capital_context: Dictionary = scene._get_political_context_at(scene._system_planet_world_position(capital_id))
        if String(capital_context.state) != "CORE":
            _fail("faction capital is not CORE")
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

    # The generated influence field must actually contain all four political states.
    var states_seen: Dictionary = {}
    for gy in 17:
        for gx in 23:
            var sample: Vector2 = bounds.position + Vector2(
                bounds.size.x * float(gx) / 22.0,
                bounds.size.y * float(gy) / 16.0
            )
            var context: Dictionary = scene._get_political_context_at(sample)
            states_seen[String(context.state)] = true
    for required_state in ["CORE", "CONTROLLED", "CONTESTED", "UNCONTROLLED"]:
        if not states_seen.has(required_state):
            _fail("generated political field lacks state " + required_state)
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

    # Save/reload must reproduce the exact political world.
    var world_before: Dictionary = scene.political_world.duplicate(true)
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
    var reload_difference: String = _world_difference(world_before, scene.political_world)
    if not reload_difference.is_empty():
        _fail("political world save/reload changed " + reload_difference)
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

    # Active route snapshot preserves generated IDs.
    scene.elapsed = 7.5
    scene.score = 4
    scene._pause_run()
    if not scene._load_run_snapshot():
        _fail("generated route snapshot could not reload")
        return
    if scene.destination_planet != neighbor or scene.route_origin != scene.current_planet or absf(scene.elapsed - 7.5) > 0.01:
        _fail("route snapshot did not preserve generated route identity")
        return

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
    scene._fail_route(false)
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

    print("PRIVATEER SMOKE OK")
    quit(0)

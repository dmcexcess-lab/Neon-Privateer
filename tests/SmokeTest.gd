extends SceneTree

func _fail(message: String) -> void:
    print("PRIVATEER SMOKE FAIL: " + message)
    quit(1)

func _initialize() -> void:
    var packed := load("res://main.tscn")
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
        "_init_privateer_world", "_market_price", "_simulate_economy",
        "_buy_commodity", "_sell_commodity", "_route_spec", "_regenerate_contracts",
        "_accept_contract", "_route_level_for", "_route_duration_for", "_start_route",
        "_update_pirate_attack", "_begin_bounty_boss", "_handle_route_end",
        "_arrive_at_destination", "_fail_route", "_save_privateer_state",
        "_load_privateer_state", "_save_all_state", "_start_game", "_dash",
        "_fire_weapon", "_choose_enemy_kind", "_apply_damage_to_hazard",
        "_save_run_snapshot", "_load_run_snapshot", "_pause_run",
        "_create_new_career", "_load_career", "_continue_career",
        "_career_slot_exists", "_career_slot_summary", "_open_profile_menu",
        "_privateer_art_ready", "_planet_art_region", "_draw_menu_art", "_draw_planet_art", "_draw_menu_panel"
    ]:
        if not scene.has_method(method_name):
            _fail("missing method " + method_name)
            return

    # Generated Privateer menu art is present and each world maps to its own atlas region.
    if not scene._privateer_art_ready():
        _fail("Privateer generated-art atlas did not import at expected dimensions")
        return
    var art_regions: Dictionary = {}
    for planet_name in ["Aster", "Cinder", "Vesper", "Helix"]:
        var art_region: Rect2 = scene._planet_art_region(planet_name)
        if art_region.size != Vector2(192.0, 192.0):
            _fail("planet art region has wrong size for " + planet_name)
            return
        var key := "%d,%d" % [int(art_region.position.x), int(art_region.position.y)]
        if art_regions.has(key):
            _fail("planet art region is not unique for " + planet_name)
            return
        art_regions[key] = true

    # Career menu boots before any career is loaded.
    if not scene.profile_menu_open or scene.active_career_slot != 0:
        _fail("game should boot at career menu with no active slot")
        return

    # Three slots are isolated: credits/world/cargo cannot leak between careers.
    if not scene._create_new_career(1):
        _fail("could not create career slot 1")
        return
    scene.research_credits = 4321
    scene.current_planet = "Cinder"
    scene.cargo["Food"] = 2
    scene._save_all_state()

    if not scene._create_new_career(2):
        _fail("could not create career slot 2")
        return
    if scene.research_credits != 1200 or scene.current_planet != "Aster" or int(scene.cargo.get("Food", 0)) != 0:
        _fail("new career inherited data from another slot")
        return
    scene.research_credits = 2222
    scene._save_all_state()

    if not scene._load_career(1):
        _fail("could not reload career slot 1")
        return
    if scene.research_credits != 4321 or scene.current_planet != "Cinder" or int(scene.cargo.get("Food", 0)) != 2:
        _fail("career slot 1 did not restore its own state")
        return

    var slot_one_summary: Dictionary = scene._career_slot_summary(1)
    var slot_two_summary: Dictionary = scene._career_slot_summary(2)
    if not bool(slot_one_summary.exists) or not bool(slot_two_summary.exists):
        _fail("career slot summaries did not detect saves")
        return
    if int(slot_one_summary.credits) != 4321 or int(slot_two_summary.credits) != 2222:
        _fail("career slot summaries mixed credits")
        return

    scene._open_profile_menu()
    if not scene.profile_menu_open or scene.hub_open:
        _fail("career menu did not open from active career")
        return
    if not scene._continue_career() or scene.active_career_slot != 1:
        _fail("continue did not restore the most recently loaded career")
        return

    # Reset slot 1 to a clean career for the gameplay smoke below.
    if not scene._create_new_career(1):
        _fail("could not reset career slot 1 for gameplay smoke")
        return

    # Hub/world baseline.
    if scene.playing:
        _fail("game should boot docked, not already in flight")
        return
    if scene.current_planet != "Aster":
        _fail("fresh Privateer game should begin at Aster")
        return
    if scene.planet_names.size() != 4 or scene.commodity_names.size() != 5:
        _fail("planet/commodity world was not initialized")
        return
    for planet in scene.planet_names:
        if not scene.markets.has(planet):
            _fail("missing market for " + planet)
            return

    # Market prices are real stock-sensitive prices and trading changes local supply.
    scene.research_credits = 5000
    scene.current_planet = "Aster"
    scene.cargo["Food"] = 0
    var food_data: Dictionary = scene.markets["Aster"]["Food"]
    food_data.stock = 70.0
    scene.markets["Aster"]["Food"] = food_data
    var food_mid_before: int = scene._market_price("Aster", "Food")
    var food_buy_before: int = scene._market_buy_price("Aster", "Food")
    var food_sell_before: int = scene._market_sell_price("Aster", "Food")
    if food_buy_before <= food_mid_before or food_sell_before >= food_mid_before:
        _fail("market bid/ask spread is invalid")
        return
    var credits_before_buy: int = scene.research_credits
    if not scene._buy_commodity("Food"):
        _fail("could not buy available commodity")
        return
    if int(scene.cargo["Food"]) != 1 or scene.research_credits != credits_before_buy - food_buy_before:
        _fail("commodity buy did not change cargo/credits correctly")
        return
    var stock_after_buy: float = float(scene.markets["Aster"]["Food"].stock)
    if stock_after_buy >= 70.0:
        _fail("buy did not remove supply from local market")
        return
    if not scene._sell_commodity("Food"):
        _fail("could not sell owned commodity")
        return
    if int(scene.cargo["Food"]) != 0 or float(scene.markets["Aster"]["Food"].stock) <= stock_after_buy:
        _fail("sell did not return supply to local market")
        return

    # Economy advances from production/consumption during travel time.
    var ore: Dictionary = scene.markets["Cinder"]["Ore"]
    ore.stock = 40.0
    ore.production = 10.0
    ore.consumption = 2.0
    scene.markets["Cinder"]["Ore"] = ore
    scene.rng.seed = 12345
    scene._simulate_economy(2)
    if float(scene.markets["Cinder"]["Ore"].stock) <= 40.0:
        _fail("sim economy did not apply production/consumption")
        return

    # Longer/more dangerous routes produce longer, harder flights.
    var short_spec: Dictionary = scene._route_spec("Aster", "Cinder")
    var long_spec: Dictionary = scene._route_spec("Aster", "Helix")
    var short_duration: float = scene._route_duration_for(int(short_spec.distance), int(short_spec.danger), 0)
    var long_duration: float = scene._route_duration_for(int(long_spec.distance), int(long_spec.danger), 0)
    var short_level: int = scene._route_level_for(int(short_spec.distance), int(short_spec.danger), 0)
    var long_level: int = scene._route_level_for(int(long_spec.distance), int(long_spec.danger), 0)
    if long_duration <= short_duration or long_level <= short_level:
        _fail("route distance/danger does not scale flight length/difficulty")
        return

    # Contract board contains the three requested job classes.
    scene.current_planet = "Aster"
    scene.active_contract.clear()
    scene._regenerate_contracts()
    var saw_delivery := false
    var saw_passenger := false
    var saw_bounty := false
    for contract in scene.contract_board:
        match String(contract.type):
            "delivery": saw_delivery = true
            "passenger": saw_passenger = true
            "bounty": saw_bounty = true
    if not saw_delivery or not saw_passenger or not saw_bounty:
        _fail("contract board missing delivery/passenger/bounty jobs")
        return

    # Bounties require an armed starting ship.
    scene.contract_board.clear()
    scene.contract_board.append({"id": 1, "type": "bounty", "destination": "Cinder", "difficulty": 2, "reward": 900})
    scene.starting_weapon = "none"
    scene.research_start_single = false
    if scene._accept_contract(0):
        _fail("unarmed ship accepted an impossible bounty")
        return
    scene.research_start_single = true
    scene.starting_weapon = "single"
    if not scene._accept_contract(0):
        _fail("armed ship could not accept bounty")
        return

    # Route start turns the existing arcade game into travel.
    if not scene._start_route("Cinder"):
        _fail("could not launch route")
        return
    if not scene.playing or not scene.route_active or scene.destination_planet != "Cinder":
        _fail("route did not enter flight mode")
        return
    if scene.level <= 1 or scene.route_duration <= 18.0:
        _fail("contract difficulty did not feed flight difficulty")
        return

    # Trapezoids/pentagons are pirate-contact enemies, not routine route traffic.
    scene.level = 10
    scene.route_danger = 4
    scene.pirate_attack_active = false
    scene.rng.seed = 99
    for i in 60:
        if scene._choose_enemy_kind(false) >= 3:
            _fail("pirate archetype spawned outside pirate contact")
            return
    scene.pirate_attack_active = true
    scene.rng.seed = 99
    var saw_pirate := false
    for i in 80:
        if scene._choose_enemy_kind(true) >= 3:
            saw_pirate = true
            break
    if not saw_pirate:
        _fail("pirate contact never produced trapezoid/pentagon")
        return

    # Flight bonuses are deliberately tiny credit extras now.
    if scene.ENERGY_ORB_BASE_SCORE > 3 or int(scene.ENERGY_ORB_BASE_SCORE * scene.ENERGY_ORB_DASH_MULT) > 10:
        _fail("green-orb bonus is too large for Privateer economy")
        return
    scene.lane_event_active = false
    scene.research_ship_speed = 0
    scene.research_dash = 0
    scene.score = 0
    scene.combo = 1
    scene.dash_score_timer = 0.0
    scene._register_near_miss()
    var normal_near: int = scene.score
    scene.score = 0
    scene.combo = 1
    scene.dash_score_timer = 0.5
    scene._register_near_miss()
    var dash_near: int = scene.score
    if normal_near < 1 or normal_near > 3 or dash_near <= normal_near or dash_near > 10:
        _fail("near/dash-near bonuses are not a few credits")
        return

    # Bounty route ends in a boss, not immediate arrival.
    scene.elapsed = scene._level_duration()
    scene._handle_route_end()
    if not scene.boss_active or scene.objects.is_empty():
        _fail("bounty route did not start boss fight")
        return
    var boss: Dictionary = scene.objects[0]
    if not bool(boss.get("boss", false)) or int(boss.kind) != 4 or float(boss.max_hp) < 60.0:
        _fail("bounty boss does not scale as a heavy target")
        return

    # Boss death completes route and pays bonus + contract.
    var credits_before_bounty: int = scene.research_credits
    var bounty_reward: int = int(scene.active_contract.reward)
    scene.score = 6
    scene._apply_damage_to_hazard(boss, float(boss.hp) + 1.0)
    if not scene.boss_defeated_pending:
        _fail("boss kill did not arm bounty completion")
        return
    scene._process(0.0)
    if scene.current_planet != "Cinder" or scene.route_active or scene.playing:
        _fail("boss completion did not arrive at destination")
        return
    if scene.research_credits < credits_before_bounty + bounty_reward + 6:
        _fail("bounty/flight bonus credits were not paid")
        return
    if not scene.active_contract.is_empty():
        _fail("completed bounty remained active")
        return

    # Delivery contracts reserve cargo and pay on ordinary arrival.
    scene.current_planet = "Cinder"
    scene.active_contract.clear()
    scene.contract_board.clear()
    scene.contract_board.append({"id": 2, "type": "delivery", "destination": "Vesper", "difficulty": 2, "reward": 500})
    var cargo_used_before: int = scene._cargo_used()
    if not scene._accept_contract(0) or scene._cargo_used() != cargo_used_before + 1:
        _fail("delivery did not reserve one cargo slot")
        return
    var delivery_reward: int = int(scene.active_contract.reward)
    var credits_before_delivery: int = scene.research_credits
    scene._start_route("Vesper")
    scene.score = 3
    scene._arrive_at_destination()
    if scene.current_planet != "Vesper" or scene.research_credits < credits_before_delivery + delivery_reward + 3:
        _fail("delivery did not complete/pay on arrival")
        return

    # Passenger contracts reserve capacity.
    scene.current_planet = "Vesper"
    scene.active_contract.clear()
    scene.passengers = 0
    scene.contract_board.clear()
    scene.contract_board.append({"id": 3, "type": "passenger", "destination": "Aster", "difficulty": 1, "reward": 350})
    if not scene._accept_contract(0) or scene.passengers != 1:
        _fail("passenger contract did not reserve passenger capacity")
        return

    # Route snapshot preserves the new Privateer flight identity.
    scene._start_route("Aster")
    scene.elapsed = 7.5
    scene.score = 4
    scene.pirate_attack_active = true
    scene.pirate_attack_timer = 2.0
    scene._pause_run()
    if not scene._load_run_snapshot():
        _fail("paused route snapshot could not reload")
        return
    if not scene.route_active or scene.destination_planet != "Aster" or absf(scene.elapsed - 7.5) > 0.01:
        _fail("paused route lost Privateer route state")
        return

    # Existing flight mechanics still exist: button controls, dash, weapons, missile rules.
    scene.run_paused = false
    scene.playing = true
    scene.current_weapon = "single"
    scene.shots.clear()
    scene._fire_weapon()
    if scene.shots.size() != 1:
        _fail("existing flight weapon layer broke during wrapper conversion")
        return
    scene.dash_cooldown = 0.0
    scene.dash_timer = 0.0
    scene._dash()
    if scene.dash_timer <= 0.0:
        _fail("existing dash layer broke during wrapper conversion")
        return

    print("NEON PRIVATEER SMOKE OK")
    quit(0)

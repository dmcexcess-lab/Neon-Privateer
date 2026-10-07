extends SceneTree

func _fail(message: String) -> void:
    print("SMOKE FAIL: " + message)
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
        "_start_game", "_dash", "_handle_key_input", "_handle_tap", "_release_control_touch", "_clear_control_holds",
        "_fire_weapon", "_weapon_interval", "_weapon_damage", "_award_hazard_kill",
        "_weapon_label", "_obstacle_max_hp", "_kill_score", "_enemy_kind_cap_for_level",
        "_enemy_body_speed_multiplier", "_hard_lane_background_rect",
        "_spawn_circle_bunch", "_move_shots", "_consume_shot_hit",
        "_apply_laser_damage", "_fire_enemy_shot", "_fire_enemy_missile", "_move_enemy_shots", "_energy_spawn_interval",
        "_make_energy_orb", "_make_repair_pickup", "_kill_drop_kind", "_queue_kill_drop",
        "_flush_pending_drops", "_spawn_repair", "_spawn_pickup", "_register_near_miss",
        "_begin_lane_event", "_end_lane_event", "_neutralize_lane_objects", "_station_at_player",
        "_station_barrier_rects", "_check_station_collision", "_split_visible", "_split_rules_active", "_point_inside_split", "_hard_lane_score_multiplier", "_lane_score_multiplier",
        "_activate_split_generation", "_spawn_split_generation", "_spawn_neutral_generation",
        "_incoming_shot_dodge_direction",
        "_dash_score_multiplier", "_level_duration", "_split_count_for_level",
        "_station_height_for_level", "_first_split_time", "_level_difficulty", "_spawn_interval",
        "_shop_weapon_cost", "_open_shop", "_buy_repair", "_buy_weapon",
        "_run_upgrade_level", "_run_upgrade_max", "_run_upgrade_cost", "_buy_run_upgrade",
        "_start_next_level", "_handle_shop_tap", "_ship_speed_multiplier", "_lateral_control_speed", "_dash_distance",
        "_dash_speed", "_damage_multiplier", "_ship_speed_score_multiplier", "_dash_speed_score_multiplier", "_enemy_event_score",
        "_research_cost", "_buy_research", "_weapon_research_cost", "_weapon_start_unlocked",
        "_buy_start_weapon_research", "_select_start_weapon", "_valid_starting_weapon", "_unlocked_start_weapon_options", "_cycle_starting_weapon",
        "_pause_run", "_resume_run", "_quit_run_with_score", "_bank_run_score", "_autosave_permanent_progress", "_save_meta", "_load_meta", "_save_run_snapshot",
        "_load_run_snapshot", "_clear_run_snapshot", "_make_tone", "_make_sweep", "_play_sfx"
    ]:
        if not scene.has_method(method_name):
            _fail("missing gameplay method " + method_name)
            return

    # Procedural SFX bank is self-contained and polyphonic.
    if scene.sfx_players.size() < 8:
        _fail("SFX pool is not polyphonic enough")
        return
    for stream_name in [
        "shot_sfx", "dual_sfx", "cone_sfx", "seeker_sfx", "laser_sfx",
        "enemy_shot_sfx", "missile_sfx", "hit_sfx", "shield_sfx", "kill_sfx",
        "energy_sfx", "repair_sfx", "weapon_pickup_sfx", "buy_sfx",
        "level_clear_sfx", "death_sfx", "near_sfx", "dash_sfx"
    ]:
        var stream = scene.get(stream_name)
        if stream == null or stream.data.size() <= 0:
            _fail("missing/generated-empty SFX stream " + stream_name)
            return
    var cursor_before_sfx: int = scene.sfx_cursor
    scene._play_sfx(scene.shot_sfx)
    scene._play_sfx(scene.energy_sfx)
    if scene.sfx_cursor == cursor_before_sfx:
        _fail("SFX pool cursor did not advance")
        return

    # Title loadout selector is part of the actual run-start input path and
    # exposes only permanently unlocked weapons.
    scene.playing = false
    scene.game_over = false
    scene.research_start_single = true
    scene.starting_weapon = "none"
    scene._handle_tap(scene.MAIN_LOADOUT_RECT.get_center())
    if scene.starting_weapon != "single":
        _fail("title-screen loadout button did not select an unlocked permanent weapon")
        return
    scene.research_start_single = false
    scene.starting_weapon = "none"

    scene._start_game()
    await process_frame
    if not scene.playing or scene.shop_open or scene.level != 1 or scene.hp != 2 or scene.max_hp != 2:
        _fail("run did not initialize with the two-hit baseline")
        return
    if scene.current_weapon != "none":
        _fail("new run should start unarmed")
        return
    if scene._level_duration() != 18.0:
        _fail("level 1 should be the shortest at 18 seconds")
        return
    if scene._split_count_for_level() != 1:
        _fail("level 1 should contain exactly one split")
        return
    if scene._station_height_for_level() != scene.STATION_HEIGHT_BASE:
        _fail("level 1 should use the shortest station split")
        return

    # True baseline is intentionally weak.
    if scene._ship_speed_multiplier() >= 1.0:
        _fail("starting ship should scroll slower than nominal speed")
        return
    if scene.DASH_FORWARD_DISTANCE > 180.0 or scene.DASH_FORWARD_SPEED > 750.0:
        _fail("starting dash is not short/slow enough")
        return
    if scene.research_shield != 0 or scene.shield_charges != 0:
        _fail("baseline run should start with no shield")
        return

    # Phone steering is three bottom buttons: held LEFT / center DASH / held RIGHT.
    if scene.LEFT_CONTROL_RECT.end.x >= scene.DASH_RECT.position.x or scene.DASH_RECT.end.x >= scene.RIGHT_CONTROL_RECT.position.x:
        _fail("left/dash/right controls overlap or are out of order")
        return
    if absf(scene.DASH_RECT.get_center().x - scene.W * 0.5) > 1.0:
        _fail("dash button is not centered")
        return

    scene.neutral_spawn_clock = 999.0
    scene.easy_spawn_clock = 999.0
    scene.hard_spawn_clock = 999.0
    scene.pickup_clock = 999.0
    scene.repair_clock = 999.0
    scene.fire_clock = 999.0
    scene.target_x = scene.W * 0.5
    scene.player_x = scene.W * 0.5

    scene._handle_tap(scene.LEFT_CONTROL_RECT.get_center(), 11)
    if not scene.left_control_held or scene.left_touch_index != 11:
        _fail("LEFT button did not enter held state")
        return
    var left_start_x: float = scene.player_x
    scene._process(0.20)
    if scene.player_x >= left_start_x:
        _fail("held LEFT button did not steer ship left")
        return
    scene._release_control_touch(11)
    if scene.left_control_held:
        _fail("LEFT button remained held after touch release")
        return

    scene.target_x = scene.player_x
    scene._handle_tap(scene.RIGHT_CONTROL_RECT.get_center(), 12)
    if not scene.right_control_held or scene.right_touch_index != 12:
        _fail("RIGHT button did not enter held state")
        return
    var right_start_x: float = scene.player_x
    scene._process(0.20)
    if scene.player_x <= right_start_x:
        _fail("held RIGHT button did not steer ship right")
        return
    scene._release_control_touch(12)
    if scene.right_control_held:
        _fail("RIGHT button remained held after touch release")
        return

    # Drag gestures no longer steer.
    scene.target_x = scene.player_x
    var target_before_drag: float = scene.target_x
    var drag: InputEventScreenDrag = InputEventScreenDrag.new()
    drag.index = 44
    drag.position = Vector2(scene.RIGHT - 5.0, 500.0)
    scene._input(drag)
    if absf(scene.target_x - target_before_drag) > 0.01:
        _fail("screen drag still changes steering target")
        return

    # Center DASH button triggers dash without changing lateral target.
    scene.dash_cooldown = 0.0
    scene.dash_timer = 0.0
    var lateral_before_dash: float = scene.target_x
    scene._handle_tap(scene.DASH_RECT.get_center(), 13)
    if scene.dash_timer <= 0.0 or scene.dash_cooldown <= 0.0:
        _fail("center DASH button did not trigger dash")
        return
    if absf(scene.target_x - lateral_before_dash) > 0.01:
        _fail("DASH button changed lateral steering")
        return
    scene._release_control_touch(13)
    scene.dash_timer = 0.0
    scene.dash_cooldown = 0.0

    # Keyboard mirrors the three touch controls: arrows or A/D steer, Up/W dashes.
    scene.target_x = scene.player_x
    var key_left_down := InputEventKey.new()
    key_left_down.device = 0
    key_left_down.physical_keycode = KEY_LEFT
    key_left_down.pressed = true
    scene._input(key_left_down)
    if not scene.keyboard_left_held:
        _fail("keyboard LEFT did not enter held steering state")
        return
    var keyboard_left_start: float = scene.player_x
    scene._process(0.20)
    if scene.player_x >= keyboard_left_start:
        _fail("held keyboard LEFT did not steer ship left")
        return
    var key_left_up := InputEventKey.new()
    key_left_up.device = 0
    key_left_up.physical_keycode = KEY_LEFT
    key_left_up.pressed = false
    scene._input(key_left_up)
    if scene.keyboard_left_held:
        _fail("keyboard LEFT remained held after key release")
        return

    scene.target_x = scene.player_x
    var key_d_down := InputEventKey.new()
    key_d_down.device = 0
    key_d_down.physical_keycode = KEY_D
    key_d_down.pressed = true
    scene._input(key_d_down)
    if not scene.keyboard_right_held:
        _fail("keyboard D did not enter held steering state")
        return
    var keyboard_right_start: float = scene.player_x
    scene._process(0.20)
    if scene.player_x <= keyboard_right_start:
        _fail("held keyboard D did not steer ship right")
        return
    var key_d_up := InputEventKey.new()
    key_d_up.device = 0
    key_d_up.physical_keycode = KEY_D
    key_d_up.pressed = false
    scene._input(key_d_up)
    if scene.keyboard_right_held:
        _fail("keyboard D remained held after key release")
        return

    scene.dash_timer = 0.0
    scene.dash_cooldown = 0.0
    var key_w_down := InputEventKey.new()
    key_w_down.device = 0
    key_w_down.physical_keycode = KEY_W
    key_w_down.pressed = true
    scene._input(key_w_down)
    if scene.dash_timer <= 0.0 or scene.dash_cooldown <= 0.0:
        _fail("keyboard W did not trigger forward dash")
        return
    scene.dash_timer = 0.0
    scene.dash_cooldown = 0.0
    scene.dash_score_timer = 0.0

    # Permanent research modifies the intended systems and uses accumulated banked score.
    var base_ship_speed: float = scene._ship_speed_multiplier()
    var base_lateral_speed: float = scene._lateral_control_speed()
    var base_dash_distance: float = scene._dash_distance()
    var base_dash_speed: float = scene._dash_speed()
    scene.research_credits = 5000000
    if not scene._buy_research("ship") or not scene._buy_research("dash") or not scene._buy_research("damage") or not scene._buy_research("hits") or not scene._buy_research("shield"):
        _fail("research purchase flow failed")
        return
    if scene.research_ship_speed != 1 or scene.research_dash != 1 or scene.research_damage != 1 or scene.research_hits != 1 or scene.research_shield != 1:
        _fail("research levels did not increment correctly")
        return
    if scene._ship_speed_multiplier() <= base_ship_speed or scene._lateral_control_speed() <= base_lateral_speed or scene._dash_distance() <= base_dash_distance or scene._dash_speed() <= base_dash_speed or scene._damage_multiplier() <= 1.0:
        _fail("research effects were not applied")
        return
    if absf(scene._lateral_control_speed() - base_lateral_speed * 1.04) > 0.05:
        _fail("ship-speed research should add 4% lateral steering speed per level")
        return
    if absf((scene._dash_speed() - base_dash_speed) - 40.0) > 0.01:
        _fail("dash speed research should increase speed only slightly")
        return

    # Permanent research is deliberately expensive; first +1 hit is the cheapest obvious entry upgrade.
    scene.research_ship_speed = 0
    scene.research_dash = 0
    scene.research_damage = 0
    scene.research_hits = 0
    scene.research_shield = 0
    var hits_first: int = scene._research_cost("hits")
    var ship_first: int = scene._research_cost("ship")
    var dash_first: int = scene._research_cost("dash")
    var damage_first: int = scene._research_cost("damage")
    var shield_first: int = scene._research_cost("shield")
    if hits_first != 5000:
        _fail("first permanent hit upgrade should cost 5000")
        return
    if hits_first >= ship_first or hits_first >= dash_first or hits_first >= damage_first or hits_first >= shield_first:
        _fail("first hit is not the cheapest permanent upgrade")
        return
    if ship_first != 15000 or dash_first != 18000 or damage_first != 24000 or shield_first != 30000:
        _fail("permanent research did not use the new doubled base costs")
        return

    scene.research_ship_speed = 1
    scene.research_dash = 1
    scene.research_damage = 1
    scene.research_hits = 1
    var hits_second: int = scene._research_cost("hits")
    if hits_second <= hits_first or hits_second >= hits_first * 2:
        _fail("hit research should rise steadily without exploding")
        return

    scene.research_shield = 1
    var shield_second: int = scene._research_cost("shield")
    scene.research_shield = 2
    var shield_third: int = scene._research_cost("shield")
    if shield_second != 75000 or shield_third != 187500 or shield_third <= shield_second * 2:
        _fail("shield research should remain a high-cost permanent track")
        return

    scene.research_hits = 1
    scene.research_shield = 1
    var credits_before_second_shield: int = scene.research_credits
    if not scene._buy_research("shield") or scene.research_shield != 2 or scene.research_credits != credits_before_second_shield - 75000:
        _fail("second shield charge research purchase failed")
        return

    # Starting-weapon permanent research costs 50x the normal one-level run-shop rental.
    if scene._weapon_research_cost("single") != scene.SHOP_SINGLE_COST * 50     or scene._weapon_research_cost("dual") != scene.SHOP_DUAL_COST * 50     or scene._weapon_research_cost("laser") != scene.SHOP_LASER_COST * 50     or scene._weapon_research_cost("cone") != scene.SHOP_CONE_COST * 50     or scene._weapon_research_cost("seeker") != scene.SHOP_SEEKER_COST * 50:
        _fail("starting weapon research is not 50x run-shop rental price")
        return
    for weapon in ["single", "dual", "laser", "cone", "seeker"]:
        if not scene._buy_start_weapon_research(weapon):
            _fail("starting weapon research unlock failed for " + weapon)
            return
    if not scene._select_start_weapon("single") or scene._valid_starting_weapon() != "single":
        _fail("researched starting weapon could not be selected")
        return

    # Unlocked permanent starters are selectable directly from the run-start screen.
    scene.starting_weapon = "none"
    scene._cycle_starting_weapon()
    if scene.starting_weapon != "single":
        _fail("run-start selector did not cycle to first unlocked permanent weapon")
        return
    scene._cycle_starting_weapon()
    if scene.starting_weapon != "dual":
        _fail("run-start selector did not cycle through unlocked permanent weapons")
        return
    if not scene._select_start_weapon("single"):
        _fail("could not restore single as permanent default after title selector test")
        return

    # Permanent progression is autosaved immediately and survives a fresh in-memory reset.
    var saved_credits: int = scene.research_credits
    var saved_ship: int = scene.research_ship_speed
    var saved_dash: int = scene.research_dash
    var saved_damage: int = scene.research_damage
    var saved_hits: int = scene.research_hits
    var saved_shield: int = scene.research_shield
    scene.research_credits = 0
    scene.research_ship_speed = 0
    scene.research_dash = 0
    scene.research_damage = 0
    scene.research_hits = 0
    scene.research_shield = 0
    scene.research_start_single = false
    scene.starting_weapon = "none"
    scene._load_meta()
    if scene.research_credits != saved_credits or scene.research_ship_speed != saved_ship or scene.research_dash != saved_dash or scene.research_damage != saved_damage or scene.research_hits != saved_hits or scene.research_shield != saved_shield:
        _fail("permanent research did not autosave/reload")
        return
    if not scene.research_start_single or scene.starting_weapon != "single":
        _fail("permanent starting weapon did not autosave/reload")
        return

    scene._start_game()
    if scene.current_weapon != "single" or not scene.store_weapon_rental.is_empty():
        _fail("selected permanent weapon did not equip as non-rental run default")
        return
    scene.neutral_spawn_clock = 999.0
    scene.easy_spawn_clock = 999.0
    scene.hard_spawn_clock = 999.0
    scene.pickup_clock = 999.0
    scene.repair_clock = 999.0
    scene.fire_clock = 999.0
    var elapsed_before_speed: float = scene.elapsed
    scene._process(1.0)
    if scene.elapsed - elapsed_before_speed <= base_ship_speed:
        _fail("ship-speed research did not accelerate level scroll/progress")
        return

    # Enemy scoring is a strict per-enemy ladder at baseline speeds:
    # asteroid = 1 kill / 10 near / 10 dash kill / 100 dash near.
    scene.lane_event_active = false
    scene.research_ship_speed = 0
    scene.run_ship_speed = 0
    scene.research_dash = 0
    scene.run_dash = 0
    if scene._enemy_event_score(0, "kill") != 1 or scene._enemy_event_score(0, "near") != 10 or scene._enemy_event_score(0, "dash_kill") != 10 or scene._enemy_event_score(0, "dash_near") != 100:
        _fail("asteroid baseline scoring is not 1/10/10/100")
        return
    if scene._enemy_event_score(2, "kill") != 5 or scene._enemy_event_score(2, "near") != 50 or scene._enemy_event_score(2, "dash_kill") != 50 or scene._enemy_event_score(2, "dash_near") != 500:
        _fail("harder enemy scoring does not scale from enemy kill value")
        return

    # Hard-lane +35% is spatial: only score events physically inside the structure get it.
    scene.level = 4
    scene._begin_lane_event()
    if scene._split_visible() or scene._split_rules_active():
        _fail("offscreen split structure activated before reaching the top boundary")
        return
    if scene._enemy_event_score(0, "dash_near", true, 0.0) != 100:
        _fail("offscreen split applied hard-lane score bonus")
        return
    scene.station_top = 120.0
    scene.hard_lane_right = true
    if not scene._split_visible():
        _fail("onscreen split structure was not considered visible")
        return
    if scene._split_rules_active():
        _fail("split generation remained active after trailing edge left top boundary")
        return
    if scene._enemy_event_score(0, "dash_near", true, 150.0) != 135:
        _fail("hard-lane score inside structure did not receive 35 percent")
        return
    if scene._enemy_event_score(0, "dash_near", true, 100.0) != 100:
        _fail("hard-lane score above structure incorrectly received bonus")
        return
    if scene._enemy_event_score(0, "dash_near", false, 150.0) != 100:
        _fail("easy-lane score inside structure incorrectly received hard bonus")
        return
    scene._end_lane_event()
    scene.level = 1

    # Every qualifying enemy scores independently; there is no combo/time-chain bonus.
    scene.score = 0
    scene.combo = 8
    scene.dash_score_timer = 0.0
    scene._register_near_miss(0)
    scene._register_near_miss(0)
    if scene.score != 20:
        _fail("two asteroid near misses should score exactly 10 each with no combo bonus")
        return
    scene.score = 0
    scene.dash_score_timer = 0.5
    scene._register_near_miss(0)
    scene._register_near_miss(0)
    if scene.score != 200:
        _fail("two asteroid dash near misses should score exactly 100 each with no combo bonus")
        return

    # Ship Speed scales ordinary near misses from baseline ship speed.
    scene.research_ship_speed = 1
    if scene._ship_speed_score_multiplier() <= 1.0 or scene._enemy_event_score(0, "near") <= 10:
        _fail("ship-speed upgrade did not raise ordinary near-miss score")
        return
    if scene._enemy_event_score(0, "dash_near") != 100:
        _fail("ship speed should not change dash-near scoring")
        return

    # Dash Speed scales dash kills and dash near misses from baseline dash speed.
    scene.research_ship_speed = 0
    scene.research_dash = 1
    if scene._dash_speed_score_multiplier() <= 1.0 or scene._enemy_event_score(0, "dash_kill") <= 10 or scene._enemy_event_score(0, "dash_near") <= 100:
        _fail("dash-speed upgrade did not raise dash-event scoring")
        return
    if scene._enemy_event_score(0, "near") != 10:
        _fail("dash speed should not change ordinary near-miss scoring")
        return
    scene.research_dash = 0

    # Starting a researched run applies permanent hits and shield charges.
    scene.research_hits = 1
    scene.research_shield = 2
    scene._start_game()
    if scene.max_hp != 3 or scene.hp != 3 or scene.shield_charges != 2:
        _fail("researched hits/shield charges did not apply to new run")
        return
    scene.current_weapon = "single"
    scene.shots.clear()
    scene._fire_weapon()
    if scene.shots.is_empty() or float(scene.shots[0].damage) <= scene.SINGLE_DAMAGE:
        _fail("permanent damage research did not raise weapon damage")
        return

    # Shield absorbs one projectile without consuming a hit.
    scene.enemy_shots.clear()
    scene.invuln = 0.0
    var hp_before_shield: int = scene.hp
    scene.enemy_shots.append({"x": scene.player_x, "y": scene.player_y, "vx": 0.0, "vy": 0.0, "r": scene.ENEMY_SHOT_RADIUS})
    scene._move_enemy_shots(0.0)
    if scene.hp != hp_before_shield or scene.shield_charges != 1:
        _fail("shield did not consume exactly one charge for one projectile")
        return

    # Pause freezes the run; resume continues; quitting banks the remaining score.
    scene.score = 321
    scene.neutral_spawn_clock = 999.0
    scene.easy_spawn_clock = 999.0
    scene.hard_spawn_clock = 999.0
    scene.pickup_clock = 999.0
    scene.repair_clock = 999.0
    var elapsed_before_pause: float = scene.elapsed
    scene._pause_run()
    scene._process(1.0)
    if not scene.run_paused or scene.elapsed != elapsed_before_pause:
        _fail("paused run continued simulating")
        return
    scene._resume_run()
    if scene.run_paused:
        _fail("resume did not clear paused state")
        return
    var credits_before_quit: int = scene.research_credits
    scene._pause_run()
    scene._quit_run_with_score()
    if scene.playing or scene.run_paused or scene.research_credits != credits_before_quit + 321:
        _fail("quit-with-score did not bank run score and return to menu")
        return

    # Reset research to baseline for legacy gameplay balance tests.
    scene.research_ship_speed = 0
    scene.research_dash = 0
    scene.research_damage = 0
    scene.research_hits = 0
    scene.research_shield = 0
    scene.research_start_single = false
    scene.research_start_dual = false
    scene.research_start_laser = false
    scene.research_start_cone = false
    scene.research_start_seeker = false
    scene.starting_weapon = "none"
    scene.research_credits = 0
    scene._save_meta()
    scene._clear_run_snapshot()
    scene._start_game()
    scene.elapsed = scene._first_split_time()
    scene._begin_lane_event()
    if scene.lane_events_started != 1 or scene.station_height != scene.STATION_HEIGHT_BASE:
        _fail("level 1 did not start exactly one short split")
        return
    if scene.next_lane_event_at <= scene._level_duration():
        _fail("level 1 scheduled an extra split")
        return
    scene._end_lane_event()
    scene.elapsed = 0.0
    scene.lane_events_started = 0
    scene.next_lane_event_at = scene._first_split_time()

    # The top edge is the generation boundary. The structure may remain visible
    # after its trailing edge clears y=0, but split spawning must stop immediately.
    scene.objects.clear()
    scene.level = 4
    scene._begin_lane_event()
    scene.pickup_clock = 999.0
    scene.repair_clock = 999.0
    scene.fire_clock = 999.0
    if scene._split_visible() or scene._split_rules_active():
        _fail("split became visible/active while fully above the screen")
        return

    # Before the leading edge reaches the top, generation is neutral.
    scene.neutral_spawn_clock = 0.0
    scene.easy_spawn_clock = 0.0
    scene.hard_spawn_clock = 0.0
    scene._process(0.0)
    if scene.objects.size() != 1 or bool(scene.objects[0].hard) or float(scene.objects[0].lane_min) != scene.LEFT or float(scene.objects[0].lane_max) != scene.RIGHT:
        _fail("offscreen split used split generation before reaching top boundary")
        return

    # First pixel through y=0: red becomes visible and split generation begins.
    scene.objects.clear()
    scene.station_top = -scene.station_height + 1.0
    scene.neutral_spawn_clock = 999.0
    scene.easy_spawn_clock = 0.0
    scene.hard_spawn_clock = 0.0
    if not scene._split_visible() or not scene._split_rules_active():
        _fail("first split pixel at top did not activate visible split generation")
        return
    scene._process(0.0)
    var saw_hard := false
    var saw_easy := false
    for obj in scene.objects:
        if obj.type != "hazard":
            continue
        if bool(obj.hard):
            saw_hard = true
        else:
            saw_easy = true
    if not saw_hard or not saw_easy:
        _fail("top-boundary split generation did not create separate easy/hard lanes")
        return

    # Red is clipped to the structure's visible Y span and the actual hard-lane X bounds.
    scene.hard_lane_right = true
    var entering_right_rect: Rect2 = scene._hard_lane_background_rect()
    if absf(entering_right_rect.position.x - scene.RIGHT_LANE_MIN) > 0.01 or absf(entering_right_rect.size.x - (scene.RIGHT_LANE_MAX - scene.RIGHT_LANE_MIN)) > 0.01 or entering_right_rect.position.y != 0.0 or entering_right_rect.size.y <= 0.0 or entering_right_rect.size.y > 2.0:
        _fail("entering hard-right red tint is not clipped to the structure")
        return

    # The instant the trailing edge passes y=0, spawning behind the structure is neutral.
    scene.objects.clear()
    scene.station_top = 1.0
    scene.neutral_spawn_clock = 0.0
    scene.easy_spawn_clock = 0.0
    scene.hard_spawn_clock = 0.0
    if not scene._split_visible() or scene._split_rules_active():
        _fail("top boundary did not end split generation at trailing edge")
        return
    scene._process(0.0)
    if not scene.lane_event_active or not scene._split_visible():
        _fail("structure should remain onscreen after top-boundary generation ends")
        return
    if scene.objects.size() != 1 or bool(scene.objects[0].hard) or float(scene.objects[0].lane_min) != scene.LEFT or float(scene.objects[0].lane_max) != scene.RIGHT:
        _fail("generation behind split structure did not return immediately to neutral")
        return

    # Red continues only over the remaining visible physical structure.
    scene.hard_lane_right = true
    var hard_right_rect: Rect2 = scene._hard_lane_background_rect()
    var expected_visible_height: float = minf(scene.station_height, scene.H - 1.0)
    if absf(hard_right_rect.position.x - scene.RIGHT_LANE_MIN) > 0.01 or absf(hard_right_rect.size.x - (scene.RIGHT_LANE_MAX - scene.RIGHT_LANE_MIN)) > 0.01 or absf(hard_right_rect.position.y - 1.0) > 0.01 or absf(hard_right_rect.size.y - expected_visible_height) > 0.01:
        _fail("hard-right red tint does not follow remaining structure bounds")
        return
    scene.hard_lane_right = false
    var hard_left_rect: Rect2 = scene._hard_lane_background_rect()
    if absf(hard_left_rect.position.x - scene.LEFT_LANE_MIN) > 0.01 or absf(hard_left_rect.size.x - (scene.LEFT_LANE_MAX - scene.LEFT_LANE_MIN)) > 0.01 or absf(hard_left_rect.position.y - 1.0) > 0.01 or absf(hard_left_rect.size.y - expected_visible_height) > 0.01:
        _fail("hard-left red tint does not follow remaining structure bounds")
        return
    scene.hard_lane_right = true

    # Score bonus follows the physical structure, not the generation state.
    if scene._enemy_event_score(0, "near", true, 20.0) != 14:
        _fail("hard-lane score inside visible structure lost 35 percent after top cleared")
        return
    if scene._enemy_event_score(0, "near", true, 0.0) != 10:
        _fail("score behind the structure retained hard-lane bonus")
        return

    # Split difficulty must end with the physical station: survivors become neutral/full-width.
    scene._end_lane_event()
    scene.objects.clear()
    scene._begin_lane_event()
    scene.station_top = 120.0
    scene.hard_lane_right = true
    scene._spawn_hazard(0.6, true, true)
    if scene.objects.is_empty() or not bool(scene.objects[0].hard):
        _fail("hard-lane test enemy did not spawn as hard")
        return
    var hard_speed_before: float = float(scene.objects[0].speed)
    var lane_mult_before: float = float(scene.objects[0].lane_speed_mult)
    scene._end_lane_event()
    if bool(scene.objects[0].hard) or float(scene.objects[0].lane_min) != scene.LEFT or float(scene.objects[0].lane_max) != scene.RIGHT:
        _fail("lane-bound enemy stayed hard/constrained after split")
        return
    if float(scene.objects[0].lane_speed_mult) != 1.0 or float(scene.objects[0].speed) >= hard_speed_before or absf(float(scene.objects[0].speed) - hard_speed_before / lane_mult_before) > 0.05:
        _fail("hard-lane speed modifier persisted after split")
        return

    # Anything spawned after a split must use neutral full-width rules even if passed the old side.
    scene.objects.clear()
    for i in 20:
        scene._spawn_hazard(0.6, true, false)
    for obj in scene.objects:
        if bool(obj.hard) or float(obj.lane_min) != scene.LEFT or float(obj.lane_max) != scene.RIGHT or absf(float(obj.lane_speed_mult) - 1.0) > 0.001:
            _fail("post-split spawn inherited hard-lane state")
            return
    scene.objects.clear()
    scene._start_game()

    # Unarmed means genuinely no automatic fire.
    scene.shots.clear()
    scene.fire_clock = 0.0
    scene.neutral_spawn_clock = 999.0
    scene.easy_spawn_clock = 999.0
    scene.hard_spawn_clock = 999.0
    scene.pickup_clock = 999.0
    scene.repair_clock = 999.0
    scene._process(0.05)
    if not scene.shots.is_empty():
        _fail("unarmed ship fired a projectile")
        return

    # Level 1 starts deliberately light and later levels scale upward.
    scene.elapsed = 0.0
    scene.level = 1
    var level_one_start: float = scene._level_difficulty()
    scene.elapsed = scene._level_duration()
    var level_one_end: float = scene._level_difficulty()
    scene.elapsed = 0.0
    scene.level = 2
    var level_two_duration: float = scene._level_duration()
    var level_two_splits: int = scene._split_count_for_level()
    var level_two_height: float = scene._station_height_for_level()
    scene.level = 3
    var level_three_start: float = scene._level_difficulty()
    scene.level = 7
    var level_seven_start: float = scene._level_difficulty()
    if level_one_start > 0.01 or level_one_end <= level_one_start or level_three_start <= level_one_start or level_seven_start <= level_three_start:
        _fail("level difficulty does not ramp correctly")
        return
    if level_three_start >= 0.20 or level_seven_start >= 0.50:
        _fail("level difficulty still climbs too quickly in the early game")
        return
    scene.level = 3
    if level_two_duration != 21.0 or scene._level_duration() != 24.0:
        _fail("level duration does not increase gradually")
        return
    if level_two_splits != 1 or scene._split_count_for_level() != 2:
        _fail("split count does not increase gradually")
        return
    if level_two_height <= scene.STATION_HEIGHT_BASE or scene._station_height_for_level() <= level_two_height:
        _fail("station split length does not increase by level")
        return
    if scene._spawn_interval(1.10, 0.43, level_one_start) <= scene._spawn_interval(1.10, 0.43, level_three_start):
        _fail("later levels should have denser hazard cadence")
        return

    # Restore clean level-1 state for combat tests.
    scene._start_game()

    # Enemy ladder: long mastery windows before each new archetype.
    scene.level = 1
    if scene._enemy_kind_cap_for_level() != 0:
        _fail("level 1 should unlock asteroids only")
        return
    scene.level = 2
    if scene._enemy_kind_cap_for_level() != 0:
        _fail("level 2 should still be asteroid-only")
        return
    scene.level = 3
    if scene._enemy_kind_cap_for_level() != 1:
        _fail("easy square drones should unlock at level 3")
        return
    scene.level = 6
    if scene._enemy_kind_cap_for_level() != 1:
        _fail("level 6 should still cap at square drones")
        return
    scene.level = 7
    if scene._enemy_kind_cap_for_level() != 2:
        _fail("smart diamonds should unlock at level 7")
        return
    scene.level = 10
    if scene._enemy_kind_cap_for_level() != 2:
        _fail("level 10 should still cap at diamonds")
        return
    scene.level = 11
    if scene._enemy_kind_cap_for_level() != 3:
        _fail("shooting trapezoids should unlock at level 11")
        return
    scene.level = 14
    if scene._enemy_kind_cap_for_level() != 3:
        _fail("level 14 should still cap at trapezoids")
        return
    scene.level = 15
    if scene._enemy_kind_cap_for_level() != 4:
        _fail("pentagon missile turrets should unlock at level 15")
        return

    scene._start_game()
    scene.objects.clear()
    for i in 40:
        scene._spawn_hazard(1.65, false, false)
    for obj in scene.objects:
        if int(obj.kind) != 0:
            _fail("level 1 spawned anything other than a lazy circle")
            return
        if absf(float(obj.drift)) > 5.1:
            _fail("level 1 asteroid should only barely drift")
            return
    scene.objects.clear()

    # Level 1 hard lane creates a small bunched circle cluster.
    scene._spawn_circle_bunch(true, 3)
    if scene.objects.size() != 3:
        _fail("level 1 hard-lane bunch did not spawn three circles")
        return
    var bunch_min_x := 9999.0
    var bunch_max_x := -9999.0
    for obj in scene.objects:
        if int(obj.kind) != 0 or not bool(obj.hard):
            _fail("hard-lane bunch contained a non-circle or non-hard enemy")
            return
        bunch_min_x = minf(bunch_min_x, float(obj.x))
        bunch_max_x = maxf(bunch_max_x, float(obj.x))
    if bunch_max_x - bunch_min_x > 55.0:
        _fail("level 1 hard-lane circles were not bunched")
        return
    scene.objects.clear()

    # Drone durability: square and trapezoid stay weak; diamond remains strongest.
    if scene._obstacle_max_hp(1) != 4.0 or scene._obstacle_max_hp(3) != 4.0:
        _fail("square and trapezoid drones should stay weak")
        return
    if scene._obstacle_max_hp(2) != 12.0 or scene._obstacle_max_hp(2) <= scene._obstacle_max_hp(1):
        _fail("yellow diamond should remain tankier than mobile weak drones")
        return
    if scene._obstacle_max_hp(4) != 20.0:
        _fail("pentagon missile turret should have lots of health")
        return
    if scene._kill_score(0) != 1 or scene._kill_score(1) != 2 or scene._kill_score(2) != 5 or scene._kill_score(3) != 4 or scene._kill_score(4) != 7:
        _fail("kill scores should stay in single digits")
        return

    # First purchasable gun is intentionally weak: one D1 projectile.
    scene.shots.clear()
    scene.current_weapon = "single"
    scene._fire_weapon()
    if scene.SINGLE_DAMAGE != 1.0 or scene.shots.size() != 1 or float(scene.shots[0].damage) != 1.0:
        _fail("single auto should be the weak D1 starter purchase")
        return

    # Dual auto.
    scene.shots.clear()
    scene.current_weapon = "dual"
    scene._fire_weapon()
    if scene.shots.size() != 2:
        _fail("dual auto did not fire two shots")
        return
    for shot in scene.shots:
        if float(shot.damage) != scene.DUAL_DAMAGE:
            _fail("dual auto damage is wrong")
            return

    # Cone cannon.
    scene.shots.clear()
    scene.current_weapon = "cone"
    scene._fire_weapon()
    if scene.shots.size() != 3 or scene._weapon_interval() <= scene.DUAL_INTERVAL:
        _fail("cone weapon cadence/spread is wrong")
        return
    if not (float(scene.shots[0].vx) < 0.0 and float(scene.shots[1].vx) == 0.0 and float(scene.shots[2].vx) > 0.0):
        _fail("cone shots do not form a spread")
        return

    # Heat seeker.
    scene.shots.clear()
    scene.current_weapon = "seeker"
    scene._fire_weapon()
    if scene.shots.size() != 1 or not scene.shots[0].homing or float(scene.shots[0].damage) != scene.SEEKER_DAMAGE:
        _fail("heat seeker profile is wrong")
        return
    if scene._weapon_interval() <= scene.CONE_INTERVAL:
        _fail("heat seeker should be the slowest projectile weapon")
        return

    # Persistent obstacle HP.
    scene.shots.clear()
    scene.current_weapon = "single"
    scene.objects.clear()
    var circle_hp: float = scene._obstacle_max_hp(0)
    scene.objects.append({
        "id": 999001,
        "type": "hazard",
        "kind": 0,
        "hp": circle_hp,
        "max_hp": circle_hp,
        "hard": false,
        "x": scene.player_x,
        "y": scene.player_y - 120.0,
        "r": 18.0,
        "speed": 0.0,
        "drift": 0.0,
        "lane_min": scene.LEFT,
        "lane_max": scene.RIGHT
    })
    scene.score = 0
    scene._spawn_shot(float(scene.objects[0].x), float(scene.objects[0].y), 0.0, 0.0, scene.SINGLE_DAMAGE)
    scene._move_objects(0.0)
    if scene.objects.is_empty() or absf(float(scene.objects[0].hp) - 2.0) > 0.01:
        _fail("D1 single shot did not leave correct persistent circle HP")
        return
    if scene.score != 0:
        _fail("nonlethal damage should not award score")
        return
    scene._spawn_shot(float(scene.objects[0].x), float(scene.objects[0].y), 0.0, 0.0, scene.SINGLE_DAMAGE)
    scene._move_objects(0.0)
    if scene.objects.is_empty() or absf(float(scene.objects[0].hp) - 1.0) > 0.01:
        _fail("second D1 shot did not leave correct persistent circle HP")
        return
    scene._spawn_shot(float(scene.objects[0].x), float(scene.objects[0].y), 0.0, 0.0, scene.SINGLE_DAMAGE)
    scene._move_objects(0.0)
    for obj in scene.objects:
        if obj.type == "hazard":
            _fail("third D1 shot did not destroy 3 HP asteroid")
            return
    if scene.score != 1:
        _fail("asteroid kill should award exactly one point")
        return

    # Green energy balls score in the tens normally and hundreds during dash.
    scene.objects.clear()
    scene.lane_event_active = false
    scene.score = 0
    scene.energy = 0
    scene.dash_score_timer = 0.0
    var orb: Dictionary = scene._make_energy_orb(scene.player_x, scene.player_y, false)
    orb.speed = 0.0
    orb.drift = 0.0
    scene.objects.append(orb)
    scene._move_objects(0.0)
    if scene.score != scene.ENERGY_ORB_BASE_SCORE or scene.score < 10 or scene.score >= 100 or scene.energy != 1:
        _fail("normal energy orb should score in the tens")
        return

    scene.objects.clear()
    scene.score = 0
    scene.dash_score_timer = 0.5
    var dash_orb: Dictionary = scene._make_energy_orb(scene.player_x, scene.player_y, false)
    dash_orb.speed = 0.0
    dash_orb.drift = 0.0
    scene.objects.append(dash_orb)
    scene._move_objects(0.0)
    if scene.score != int(scene.ENERGY_ORB_BASE_SCORE * scene.ENERGY_ORB_DASH_MULT) or scene.score < 100:
        _fail("dash energy orb should score in the hundreds")
        return

    # Random orb cadence increases by level and only gets faster while the
    # split structure is crossing the top generation boundary.
    scene.rng.seed = 424242
    scene.level = 1
    scene.lane_event_active = false
    var level_one_orb_interval: float = scene._energy_spawn_interval()
    scene.rng.seed = 424242
    scene.level = 8
    scene.lane_event_active = false
    var late_orb_interval: float = scene._energy_spawn_interval()
    scene.rng.seed = 424242
    scene.lane_event_active = true
    scene.station_height = scene._station_height_for_level()
    scene.station_top = -scene.station_height + 1.0
    var split_orb_interval: float = scene._energy_spawn_interval()
    if late_orb_interval >= level_one_orb_interval:
        _fail("energy orbs did not become more frequent in later levels")
        return
    if split_orb_interval >= late_orb_interval:
        _fail("energy orbs did not become more frequent while split crossed top boundary")
        return

    # Once the trailing edge clears the top, pickup cadence returns to neutral
    # even though the structure remains visible farther downscreen.
    scene.rng.seed = 424242
    scene.station_top = 1.0
    var behind_split_orb_interval: float = scene._energy_spawn_interval()
    if absf(behind_split_orb_interval - late_orb_interval) > 0.001:
        _fail("energy orb cadence stayed boosted behind split structure")
        return

    # While crossing the top boundary, random energy balls strongly favor the hard lane.
    scene.objects.clear()
    scene.level = 8
    scene.lane_event_active = true
    scene.station_height = scene._station_height_for_level()
    scene.station_top = -scene.station_height + 1.0
    scene.hard_lane_right = true
    scene.rng.seed = 777
    var hard_orbs := 0
    var easy_orbs := 0
    for i in 100:
        scene._spawn_pickup()
    for obj in scene.objects:
        if bool(obj.hard):
            hard_orbs += 1
        else:
            easy_orbs += 1
    if hard_orbs <= easy_orbs * 2:
        _fail("top-boundary split energy orbs do not favor hard lane strongly enough")
        return

    # Kill rewards have rare, explicit orb and +1-hit bands.
    if scene._kill_drop_kind(0.0) != "repair":
        _fail("kill drop repair band is missing")
        return
    if scene._kill_drop_kind(0.05) != "energy":
        _fail("kill drop energy band is missing")
        return
    if scene._kill_drop_kind(0.50) != "":
        _fail("kill drops are not rare enough")
        return
    if scene.KILL_REPAIR_DROP_CHANCE >= 0.05 or scene.KILL_ORB_DROP_CHANCE >= 0.15:
        _fail("kill orb/repair drops should remain rare")
        return

    scene.objects.clear()
    scene.lane_event_active = false
    scene.dash_score_timer = 0.0

    # Score scale: ordinary near misses are tens; dash near misses are hundreds.
    scene.lane_event_active = false
    scene.score = 0
    scene.combo = 1
    scene.dash_score_timer = 0.0
    scene._register_near_miss(0)
    var ordinary_near_score: int = scene.score
    if ordinary_near_score < 10 or ordinary_near_score >= 100:
        _fail("ordinary near miss should score in the tens")
        return
    scene.score = 0
    scene.combo = 1
    scene.dash_score_timer = 0.5
    scene._register_near_miss(0)
    var dash_near_score: int = scene.score
    if dash_near_score < 100 or dash_near_score >= 1000:
        _fail("dash near miss should score in the hundreds")
        return

    # Square drone keeps dumb tracking but now has a modest forward-speed bump.
    if scene._enemy_body_speed_multiplier(1) <= 1.0 or scene._enemy_body_speed_multiplier(1) > 1.10:
        _fail("weak square drone forward-speed bump is outside the intended modest range")
        return

    # Square drone is dumb/slow laterally: it only creeps toward the player.
    scene.objects.clear()
    scene.player_x = 300.0
    scene.player_y = scene.PLAYER_Y
    scene.objects.append({
        "id": 990000, "type": "hazard", "kind": 1,
        "hp": 4.0, "max_hp": 4.0, "hard": false,
        "x": 100.0, "y": 120.0, "r": 16.0,
        "speed": 0.0, "drift": 0.0, "shoot_clock": 999.0,
        "lane_speed_mult": 1.0, "lane_min": scene.LEFT, "lane_max": scene.RIGHT
    })
    scene._move_objects(0.1)
    var square_drift: float = float(scene.objects[0].drift)
    if square_drift <= 0.0 or square_drift > 5.5:
        _fail("square drone should track laterally a little faster, but still slowly")
        return

    # Diamond is smarter/faster laterally, but remains capped and dodgeable.
    scene.objects.clear()
    scene.level = 4
    scene.player_x = 300.0
    scene.target_x = 330.0
    scene.objects.append({
        "id": 990001, "type": "hazard", "kind": 2,
        "hp": 12.0, "max_hp": 12.0, "hard": false,
        "x": 100.0, "y": 120.0, "r": 15.0,
        "speed": 0.0, "drift": 0.0, "shoot_clock": 999.0,
        "lane_speed_mult": 1.0, "lane_min": scene.LEFT, "lane_max": scene.RIGHT
    })
    scene._move_objects(0.1)
    var diamond_drift: float = float(scene.objects[0].drift)
    if diamond_drift <= square_drift * 3.0 or diamond_drift > 82.0:
        _fail("smart diamond should track faster than square but remain capped")
        return

    # Trapezoid is a weak ranged skirmisher: full vertical movement, aimed fire, and shot avoidance.
    scene.objects.clear()
    scene.enemy_shots.clear()
    scene.shots.clear()
    scene.level = 6
    scene.player_x = 195.0
    scene.target_x = 195.0
    scene.objects.append({
        "id": 990002, "type": "hazard", "kind": 3,
        "hp": 4.0, "max_hp": 4.0, "hard": false,
        "x": 195.0, "y": scene.player_y - 110.0, "r": 16.0,
        "speed": 90.0, "drift": 0.0, "shoot_clock": 0.0,
        "lane_speed_mult": 1.0, "lane_min": scene.LEFT, "lane_max": scene.RIGHT
    })
    var trap_start_y: float = float(scene.objects[0].y)
    scene._move_objects(0.25)
    if float(scene.objects[0].y) >= trap_start_y:
        _fail("trapezoid did not move upward to regain ranged spacing")
        return
    if float(scene.objects[0].y) >= scene.player_y:
        _fail("trapezoid crossed below player baseline")
        return
    if scene.enemy_shots.size() != 1 or float(scene.enemy_shots[0].vy) <= 0.0:
        _fail("trapezoid did not fire toward the player")
        return

    scene.enemy_shots.clear()
    scene.shots.clear()
    scene.objects[0].x = 195.0
    scene.objects[0].y = 360.0
    scene.objects[0].drift = 0.0
    scene.objects[0].shoot_clock = 999.0
    scene.shots.append({"x": 195.0, "y": 480.0, "vx": 0.0, "vy": -600.0, "r": 4.0, "damage": 1.0, "homing": false})
    if scene._incoming_shot_dodge_direction(scene.objects[0]) == 0.0:
        _fail("trapezoid did not detect incoming fire")
        return
    scene._move_objects(0.1)
    if absf(float(scene.objects[0].drift)) < 5.0:
        _fail("trapezoid did not dodge incoming fire")
        return

    # Pentagon turret does not steer: it simply scrolls by and launches a homing 2-hit missile.
    scene.objects.clear()
    scene.enemy_shots.clear()
    scene.shots.clear()
    scene.level = 8
    scene.player_x = 260.0
    scene.player_y = scene.PLAYER_Y
    scene.objects.append({
        "id": 990003, "type": "hazard", "kind": 4,
        "hp": 20.0, "max_hp": 20.0, "hard": false,
        "x": 120.0, "y": 180.0, "r": 22.0,
        "speed": 170.0, "drift": 0.0, "shoot_clock": 0.0,
        "lane_speed_mult": 1.0, "lane_min": scene.LEFT, "lane_max": scene.RIGHT
    })
    var pent_x: float = float(scene.objects[0].x)
    var pent_y: float = float(scene.objects[0].y)
    scene._move_objects(0.1)
    if absf(float(scene.objects[0].x) - pent_x) > 0.01:
        _fail("pentagon turret should not steer or drift")
        return
    if float(scene.objects[0].y) <= pent_y:
        _fail("pentagon turret should scroll by with the level")
        return
    if scene.enemy_shots.size() != 1 or not bool(scene.enemy_shots[0].homing) or int(scene.enemy_shots[0].damage) != 2:
        _fail("pentagon did not fire a homing 2-hit missile")
        return

    # Homing missile should turn toward a later player position.
    var missile_vx_before: float = float(scene.enemy_shots[0].vx)
    scene.player_x = 340.0
    scene._move_enemy_shots(0.1)
    if float(scene.enemy_shots[0].vx) <= missile_vx_before:
        _fail("pentagon missile did not home toward player")
        return

    # A missile costs two hits, but a shield cancels the whole missile for one charge.
    scene.enemy_shots.clear()
    scene.player_x = 195.0
    scene.hp = 4
    scene.max_hp = 4
    scene.shield_charges = 0
    scene.invuln = 0.0
    scene.enemy_shots.append({
        "type": "missile", "x": scene.player_x, "y": scene.player_y,
        "vx": 0.0, "vy": 0.0, "r": scene.ENEMY_MISSILE_RADIUS,
        "damage": 2, "homing": true
    })
    scene._move_enemy_shots(0.0)
    if scene.hp != 2:
        _fail("unshielded homing missile should cost two hits")
        return
    if absf(scene.invuln - scene.HIT_INVULN_TIME) > 0.01 or absf(scene.HIT_INVULN_TIME - 0.5) > 0.01:
        _fail("post-hit invulnerability should be about half a second")
        return

    scene.enemy_shots.clear()
    scene.hp = 4
    scene.invuln = 0.0
    scene.shield_charges = 2
    scene.enemy_shots.append({
        "type": "missile", "x": scene.player_x, "y": scene.player_y,
        "vx": 0.0, "vy": 0.0, "r": scene.ENEMY_MISSILE_RADIUS,
        "damage": 2, "homing": true
    })
    scene._move_enemy_shots(0.0)
    if scene.hp != 4 or scene.shield_charges != 1:
        _fail("one shield charge should absorb the entire 2-hit missile")
        return

    # Physical collisions hurt only the player; the enemy survives, and hit grace prevents rapid stacking.
    scene.objects.clear()
    scene.shots.clear()
    scene.hp = 4
    scene.max_hp = 4
    scene.invuln = 0.0
    scene.player_x = 195.0
    scene.player_y = scene.PLAYER_Y
    scene.objects.append({
        "id": 990004, "type": "hazard", "kind": 1,
        "hp": 4.0, "max_hp": 4.0, "hard": false,
        "x": scene.player_x, "y": scene.player_y, "r": 16.0,
        "speed": 0.0, "drift": 0.0, "shoot_clock": 999.0,
        "lane_speed_mult": 1.0, "lane_min": scene.LEFT, "lane_max": scene.RIGHT
    })
    scene._move_objects(0.0)
    if scene.hp != 3 or scene.objects.size() != 1 or float(scene.objects[0].hp) != 4.0:
        _fail("collision should damage only the player and leave enemy unchanged")
        return
    scene._move_objects(0.0)
    if scene.hp != 3:
        _fail("immediate repeated collision ignored hit invulnerability")
        return
    scene.invuln = 0.0
    scene._move_objects(0.0)
    if scene.hp != 2:
        _fail("collision did not hurt again after invulnerability expired")
        return

    # During the active forward dash, body contact becomes a dash kill and causes no hit.
    scene.objects.clear()
    scene.pending_drops.clear()
    scene.hp = 4
    scene.max_hp = 4
    scene.invuln = 0.0
    scene.score = 0
    scene.dash_timer = 0.20
    scene.dash_score_timer = 0.5
    scene.objects.append({
        "id": 990005, "type": "hazard", "kind": 1,
        "hp": 4.0, "max_hp": 4.0, "hard": false,
        "x": scene.player_x, "y": scene.player_y, "r": 16.0,
        "speed": 0.0, "drift": 0.0, "shoot_clock": 999.0,
        "lane_speed_mult": 1.0, "lane_min": scene.LEFT, "lane_max": scene.RIGHT
    })
    scene._move_objects(0.0)
    if scene.hp != 4:
        _fail("dash collision damaged the player")
        return
    for obj in scene.objects:
        if obj.type == "hazard" and int(obj.id) == 990005:
            _fail("dash collision did not destroy the enemy")
            return
    if scene.score != 20:
        _fail("baseline square dash kill should score 20")
        return
    if not scene.near_miss_text.begins_with("DASH KILL +"):
        _fail("dash collision did not register dash-kill feedback")
        return
    scene.dash_timer = 0.0
    scene.dash_score_timer = 0.0

    scene.objects.clear()
    scene.enemy_shots.clear()
    scene.shots.clear()
    scene._start_game()

    # Thin weak laser.
    scene.objects.clear()
    scene.current_weapon = "laser"
    scene.player_x = 195.0
    scene.objects.append({
        "id": 999002,
        "type": "hazard",
        "kind": 0,
        "hp": circle_hp,
        "max_hp": circle_hp,
        "hard": false,
        "x": scene.player_x,
        "y": scene.player_y - 180.0,
        "r": 18.0,
        "speed": 0.0,
        "drift": 0.0,
        "lane_min": scene.LEFT,
        "lane_max": scene.RIGHT
    })
    scene._apply_laser_damage(0.5)
    if scene.objects.is_empty() or float(scene.objects[0].hp) >= circle_hp:
        _fail("laser did not apply weak continuous damage")
        return
    scene._apply_laser_damage(0.6)
    for obj in scene.objects:
        if obj.type == "hazard":
            _fail("laser did not eventually destroy depleted target")
            return

    # Rare field repairs still restore exactly one hit when they appear.
    if scene.REPAIR_INTERVAL_MIN < 20.0 or scene.FIELD_REPAIR_CHANCE >= 0.5:
        _fail("field repairs are not rare enough")
        return
    scene.objects.clear()
    scene.hp = 1
    scene._spawn_repair()
    if scene.objects.size() != 1 or scene.objects[0].type != "repair":
        _fail("repair core did not spawn while damaged")
        return
    scene.objects[0].x = scene.player_x
    scene.objects[0].y = scene.player_y
    scene.objects[0].speed = 0.0
    scene.objects[0].drift = 0.0
    scene._move_objects(0.0)
    if scene.hp != 2:
        _fail("field repair did not restore exactly one hit")
        return

    # Per-enemy scoring remains independent when multiple hazards qualify in the same update.
    scene.objects.clear()
    scene.score = 0
    scene.dash_score_timer = 0.0
    scene.player_x = 195.0
    scene.player_y = scene.PLAYER_Y
    for enemy_id in [991001, 991002]:
        scene.objects.append({
            "id": enemy_id, "type": "hazard", "kind": 0,
            "hp": 3.0, "max_hp": 3.0, "hard": false,
            "x": scene.player_x, "y": scene.player_y + 20.0, "r": 18.0,
            "speed": 0.0, "drift": 0.0, "shoot_clock": 999.0,
            "lane_speed_mult": 1.0, "lane_min": scene.LEFT, "lane_max": scene.RIGHT
        })
    scene._move_objects(0.0)
    if scene.score != 20:
        _fail("multiple simultaneous asteroid near misses did not each score 10")
        return

    # Economy should be on the compact score scale.
    if scene.SHOP_SINGLE_COST != 300 or scene.SHOP_DUAL_COST != 1000 or scene.SHOP_LASER_COST != 2500 or scene.SHOP_CONE_COST != 5000 or scene.SHOP_SEEKER_COST != 10000:
        _fail("weapon prices do not span hundreds through ten-thousands")
        return
    if scene.SHOP_REPAIR_COST != 75:
        _fail("repair price should remain on the compact score scale")
        return

    # Level clear opens a frozen shop and awards a clear bonus.
    scene.score = 15000
    scene.hp = 1
    scene.current_weapon = "none"
    scene.objects.append({
        "id": 999003,
        "type": "energy",
        "hard": false,
        "x": 100.0,
        "y": 100.0,
        "r": 12.0,
        "speed": 0.0,
        "drift": 0.0,
        "lane_min": scene.LEFT,
        "lane_max": scene.RIGHT
    })
    var score_before_shop: int = scene.score
    scene._open_shop()
    if scene.playing or not scene.shop_open or scene.level != 1:
        _fail("level clear did not enter shop state")
        return
    if scene.score != score_before_shop + scene.last_level_bonus or scene.last_level_bonus <= 0:
        _fail("level clear bonus was not awarded")
        return
    if not scene.objects.is_empty() or not scene.shots.is_empty() or not scene.enemy_shots.is_empty():
        _fail("shop did not freeze and clear active gameplay objects")
        return

    # Shop defaults to run-only upgrades and exposes every permanent research track as a temporary version.
    if scene.shop_page != 0:
        _fail("between-level store did not default to run upgrades")
        return
    var base_run_ship_speed: float = scene._ship_speed_multiplier()
    var base_run_lateral_speed: float = scene._lateral_control_speed()
    var base_run_dash_distance: float = scene._dash_distance()
    var base_run_dash_speed: float = scene._dash_speed()
    var base_run_damage: float = scene._damage_multiplier()
    if not scene._buy_run_upgrade("ship") or not scene._buy_run_upgrade("dash") or not scene._buy_run_upgrade("damage") or not scene._buy_run_upgrade("hits") or not scene._buy_run_upgrade("shield"):
        _fail("run-upgrade store purchase flow failed")
        return
    if scene.run_ship_speed != 1 or scene.run_dash != 1 or scene.run_damage != 1 or scene.run_hits != 1 or scene.run_shield != 1:
        _fail("run-only upgrade levels did not increment")
        return
    if scene._ship_speed_multiplier() <= base_run_ship_speed or scene._lateral_control_speed() <= base_run_lateral_speed or scene._dash_distance() <= base_run_dash_distance or scene._dash_speed() <= base_run_dash_speed or scene._damage_multiplier() <= base_run_damage:
        _fail("run-only upgrades did not affect active ship")
        return
    if scene.max_hp != 3 or scene.hp != 2 or scene.shield_charges != 1:
        _fail("run-only hit/shield upgrades applied incorrectly")
        return

    # Shop page switching must activate once even when Godot emits a synthesized
    # compatibility event alongside the physical pointer event.
    var shop_toggle_pos: Vector2 = scene.SHOP_PAGE_TOGGLE_RECT.get_center()
    var desktop_click := InputEventMouseButton.new()
    desktop_click.device = InputEvent.DEVICE_ID_MOUSE
    desktop_click.button_index = MOUSE_BUTTON_LEFT
    desktop_click.position = shop_toggle_pos
    desktop_click.pressed = true
    scene._input(desktop_click)
    var emulated_touch := InputEventScreenTouch.new()
    emulated_touch.device = InputEvent.DEVICE_ID_EMULATION
    emulated_touch.index = 77
    emulated_touch.position = shop_toggle_pos
    emulated_touch.pressed = true
    scene._input(emulated_touch)
    if scene.shop_page != 1:
        _fail("desktop shop page toggle was double-activated by emulated touch")
        return

    scene.shop_page = 0
    var phone_touch := InputEventScreenTouch.new()
    phone_touch.device = 0
    phone_touch.index = 78
    phone_touch.position = shop_toggle_pos
    phone_touch.pressed = true
    scene._input(phone_touch)
    var emulated_mouse := InputEventMouseButton.new()
    emulated_mouse.device = InputEvent.DEVICE_ID_EMULATION
    emulated_mouse.button_index = MOUSE_BUTTON_LEFT
    emulated_mouse.position = shop_toggle_pos
    emulated_mouse.pressed = true
    scene._input(emulated_mouse)
    if scene.shop_page != 1:
        _fail("phone shop page toggle was double-activated by emulated mouse")
        return

    # Shop repair spends score and restores one hit.
    var before_repair: int = scene.score
    if not scene._buy_repair() or scene.hp != 3 or scene.score != before_repair - scene.SHOP_REPAIR_COST:
        _fail("shop repair purchase failed")
        return

    # Store weapons overlay the permanent default for one level only.
    scene.research_start_single = true
    scene.starting_weapon = "single"
    scene.current_weapon = scene._valid_starting_weapon()
    scene.store_weapon_rental = ""
    var before_single: int = scene.score
    if scene._buy_weapon("single"):
        _fail("shop should not charge to rent the already-equipped permanent default")
        return

    var before_weapon: int = scene.score
    if not scene._buy_weapon("dual"):
        _fail("shop dual rental purchase failed")
        return
    if scene.current_weapon != "dual" or scene.store_weapon_rental != "dual" or scene.score != before_weapon - scene.SHOP_DUAL_COST:
        _fail("dual shop rental did not overlay permanent default")
        return

    # Insufficient score blocks a purchase.
    scene.score = 0
    if scene._buy_weapon("seeker"):
        _fail("shop allowed unaffordable weapon")
        return

    # Next level preserves run resources/equipment but increases difficulty.
    scene.score = 777
    var hp_before_next: int = scene.hp
    var weapon_before_next: String = scene.current_weapon
    var rental_before_next: String = scene.store_weapon_rental
    var difficulty_before_next: float = scene._level_difficulty()
    scene._start_next_level()
    if not scene.playing or scene.shop_open or scene.level != 2 or scene.elapsed != 0.0:
        _fail("next level did not start correctly")
        return
    if scene.hp != hp_before_next or scene.current_weapon != weapon_before_next or scene.store_weapon_rental != rental_before_next or scene.score != 777:
        _fail("next level did not preserve the one-level weapon rental")
        return
    if scene.run_ship_speed != 1 or scene.run_dash != 1 or scene.run_damage != 1 or scene.run_hits != 1 or scene.run_shield != 1:
        _fail("next level did not preserve temporary run upgrades")
        return
    if scene._level_difficulty() <= difficulty_before_next:
        _fail("next level did not become harder")
        return

    # Timer reaching level duration must open the next shop rather than end the run.
    scene.elapsed = scene._level_duration() - 0.01
    scene.objects.clear()
    scene.shots.clear()
    scene.neutral_spawn_clock = 999.0
    scene.easy_spawn_clock = 999.0
    scene.hard_spawn_clock = 999.0
    scene.pickup_clock = 999.0
    scene.fire_clock = 999.0
    scene.repair_clock = 999.0
    scene._process(0.02)
    if not scene.shop_open or scene.game_over or scene.level != 2:
        _fail("level timer did not transition into shop")
        return
    if not scene.store_weapon_rental.is_empty() or scene.current_weapon != "single" or scene.current_weapon != scene._valid_starting_weapon():
        _fail("store weapon did not expire back to permanent default after one level")
        return

    # A brand-new run wipes store upgrades while permanent research remains separate.
    scene._start_game()
    if scene.run_ship_speed != 0 or scene.run_dash != 0 or scene.run_damage != 0 or scene.run_hits != 0 or scene.run_shield != 0:
        _fail("new run did not clear temporary store upgrades")
        return

    # Durable run snapshot preserves temporary upgrades as part of the current run.
    scene.run_ship_speed = 2
    scene.run_dash = 1
    scene.run_damage = 3
    scene.run_hits = 1
    scene.run_shield = 2
    scene.max_hp = 3
    scene.hp = 3
    scene.shield_charges = 2
    scene.score = 432
    scene.level = 3
    scene.elapsed = 7.5
    scene.current_weapon = "dual"
    scene.store_weapon_rental = "dual"
    scene._pause_run()
    if not scene._load_run_snapshot():
        _fail("saved run snapshot could not be reloaded")
        return
    if scene.score != 432 or scene.level != 3 or absf(scene.elapsed - 7.5) > 0.01 or scene.current_weapon != "dual" or scene.store_weapon_rental != "dual":
        _fail("run snapshot did not preserve core run/rental state")
        return
    if scene.run_ship_speed != 2 or scene.run_dash != 1 or scene.run_damage != 3 or scene.run_hits != 1 or scene.run_shield != 2:
        _fail("run snapshot did not preserve temporary store upgrades")
        return

    # A field pickup replaces the rented weapon and is not itself tagged as a store rental.
    scene.objects.clear()
    scene.player_x = 195.0
    scene.player_y = scene.PLAYER_Y
    scene.objects.append({
        "id": 881122, "type": "weapon", "weapon": "single", "hard": false,
        "x": scene.player_x, "y": scene.player_y, "r": 14.0,
        "speed": 0.0, "drift": 0.0, "lane_min": scene.LEFT, "lane_max": scene.RIGHT
    })
    scene._move_objects(0.0)
    if scene.current_weapon != "single" or not scene.store_weapon_rental.is_empty():
        _fail("field weapon pickup was incorrectly kept as a store rental")
        return
    scene.run_paused = false
    scene.run_ship_speed = 0
    scene.run_dash = 0
    scene.run_damage = 0
    scene.run_hits = 0
    scene.run_shield = 0
    scene.research_dash = 0

    # Baseline dash is deliberately short; research grows distance faster than speed.
    scene._start_next_level()
    scene.player_x = 195.0
    scene.target_x = 195.0
    scene.player_y = scene.PLAYER_Y
    scene.dash_cooldown = 0.0
    scene._dash()
    scene._process(0.30)
    var baseline_dash_distance: float = scene.PLAYER_Y - scene.player_y
    if baseline_dash_distance < 145.0 or baseline_dash_distance > 175.0:
        _fail("baseline dash should travel only about 160 pixels")
        return
    scene.research_dash = 3
    scene.player_y = scene.PLAYER_Y
    scene.dash_timer = 0.0
    scene.dash_cooldown = 0.0
    scene._dash()
    scene._process(0.40)
    var researched_dash_distance: float = scene.PLAYER_Y - scene.player_y
    if researched_dash_distance <= baseline_dash_distance + 80.0:
        _fail("dash research did not materially extend distance")
        return
    if scene._dash_speed() >= scene.DASH_FORWARD_SPEED + 150.0:
        _fail("dash research increased speed too aggressively")
        return

    # Station structure remains instant-lethal through invulnerability.
    scene._begin_lane_event()
    scene.station_top = scene.player_y - 120.0
    scene.player_x = scene.LANE_SPLIT
    scene.invuln = 999.0
    scene._check_station_collision()
    if scene.playing or scene.hp != 0 or scene.result_reason != "STATION COLLISION":
        _fail("station barrier contact was not an instant kill")
        return

    print("NEON DRIFTLINE SMOKE OK")
    quit(0)

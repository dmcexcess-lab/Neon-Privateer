extends Node2D

const W := 390.0
const H := 844.0
const PoliticalWorld = preload("res://scripts/PoliticalWorld.gd")
const POLITICAL_WORLD_SCHEMA := 2
const ECONOMY_SCHEMA_VERSION := 3
const CRIME_SCHEMA_VERSION := 1
const ENFORCEMENT_SCHEMA_VERSION := 1
const CONTRACT_SCHEMA_VERSION := 2
const PRIVATEER_UI_ATLAS_PATH := "res://assets/privateer_ui/privateer_ui_atlas.res"

# Generated-menu-art atlas regions. These are used only while docked/in menus;
# the arcade-flight renderer remains fully procedural.
const ART_BG_HUB := Rect2(0.0, 0.0, 195.0, 422.0)
const ART_BG_MARKET := Rect2(195.0, 0.0, 195.0, 422.0)
const ART_BG_OPS := Rect2(0.0, 422.0, 195.0, 422.0)
const ART_BG_UPGRADES := Rect2(195.0, 422.0, 195.0, 422.0)
const ART_PLANET_ASTER := Rect2(0.0, 844.0, 195.0, 192.0)
const ART_PLANET_CINDER := Rect2(195.0, 844.0, 195.0, 192.0)
const ART_PLANET_VESPER := Rect2(0.0, 1036.0, 195.0, 192.0)
const ART_PLANET_HELIX := Rect2(195.0, 1036.0, 195.0, 192.0)
const PLAYER_Y := 680.0
const LEFT := 32.0
const RIGHT := 358.0
const LEVEL_TIME_BASE := 18.0
const LEVEL_TIME_STEP := 3.0
const LEVEL_TIME_MAX := 45.0
const SHOP_REPAIR_COST := 75
const SHOP_SINGLE_COST := 300
const SHOP_DUAL_COST := 1000
const SHOP_CONE_COST := 5000
const SHOP_SEEKER_COST := 10000
const SHOP_LASER_COST := 2500
const LANE_SPLIT := W * 0.5
const LEFT_LANE_MIN := LEFT
const LEFT_LANE_MAX := LANE_SPLIT - 7.0
const RIGHT_LANE_MIN := LANE_SPLIT + 7.0
const RIGHT_LANE_MAX := RIGHT
const LEFT_CONTROL_RECT := Rect2(20.0, 748.0, 105.0, 64.0)
const DASH_RECT := Rect2(142.5, 748.0, 105.0, 64.0)
const RIGHT_CONTROL_RECT := Rect2(265.0, 748.0, 105.0, 64.0)
const CONTROL_TARGET_SPEED := 285.0
const SHOP_REPAIR_RECT := Rect2(35.0, 236.0, 320.0, 56.0)
const SHOP_SINGLE_RECT := Rect2(35.0, 318.0, 150.0, 58.0)
const SHOP_DUAL_RECT := Rect2(205.0, 318.0, 150.0, 58.0)
const SHOP_CONE_RECT := Rect2(35.0, 394.0, 150.0, 58.0)
const SHOP_SEEKER_RECT := Rect2(205.0, 394.0, 150.0, 58.0)
const SHOP_LASER_RECT := Rect2(35.0, 470.0, 320.0, 58.0)
const SHOP_CONTINUE_RECT := Rect2(35.0, 562.0, 320.0, 72.0)
const MAIN_START_RECT := Rect2(54.0, 560.0, 282.0, 64.0)
const MAIN_RESEARCH_RECT := Rect2(54.0, 640.0, 282.0, 64.0)
const RESEARCH_SHIP_RECT := Rect2(35.0, 188.0, 320.0, 64.0)
const RESEARCH_DASH_RECT := Rect2(35.0, 270.0, 320.0, 64.0)
const RESEARCH_DAMAGE_RECT := Rect2(35.0, 352.0, 320.0, 64.0)
const RESEARCH_HITS_RECT := Rect2(35.0, 434.0, 320.0, 64.0)
const RESEARCH_SHIELD_RECT := Rect2(35.0, 516.0, 320.0, 64.0)
const RESEARCH_WEAPONS_RECT := Rect2(35.0, 598.0, 320.0, 58.0)
const RESEARCH_BACK_RECT := Rect2(54.0, 684.0, 282.0, 58.0)
const WEAPON_NONE_RECT := Rect2(35.0, 164.0, 320.0, 54.0)
const WEAPON_SINGLE_RECT := Rect2(35.0, 232.0, 320.0, 54.0)
const WEAPON_DUAL_RECT := Rect2(35.0, 300.0, 320.0, 54.0)
const WEAPON_LASER_RECT := Rect2(35.0, 368.0, 320.0, 54.0)
const WEAPON_CONE_RECT := Rect2(35.0, 436.0, 320.0, 54.0)
const WEAPON_SEEKER_RECT := Rect2(35.0, 504.0, 320.0, 54.0)
const WEAPON_RESEARCH_BACK_RECT := Rect2(54.0, 620.0, 282.0, 58.0)
const PAUSE_RECT := Rect2(300.0, 16.0, 72.0, 38.0)
const PAUSE_RESUME_RECT := Rect2(55.0, 360.0, 280.0, 74.0)
const PAUSE_QUIT_RECT := Rect2(55.0, 458.0, 280.0, 74.0)
const LEGACY_META_SAVE_PATH := "user://neon_meta.cfg"
const LEGACY_RUN_SAVE_PATH := "user://neon_run.cfg"
const LEGACY_PRIVATEER_SAVE_PATH := "user://neon_privateer.cfg"
const CAREER_INDEX_PATH := "user://neon_careers.cfg"
const CAREER_SLOT_COUNT := 3
const PROFILE_CONTINUE_RECT := Rect2(54.0, 352.0, 282.0, 64.0)
const PROFILE_NEW_RECT := Rect2(54.0, 434.0, 282.0, 64.0)
const PROFILE_LOAD_RECT := Rect2(54.0, 516.0, 282.0, 64.0)
const PROFILE_SLOT_BACK_RECT := Rect2(54.0, 672.0, 282.0, 58.0)
const HUB_CAREERS_RECT := Rect2(35.0, 700.0, 320.0, 58.0)
const HUB_TRAVEL_RECT := Rect2(35.0, 404.0, 320.0, 58.0)
const HUB_MARKET_RECT := Rect2(35.0, 478.0, 320.0, 58.0)
const BANK_ACCOUNT_TAB_RECT := Rect2(18.0, 126.0, 84.0, 42.0)
const BANK_GREEN_TAB_RECT := Rect2(106.0, 126.0, 84.0, 42.0)
const BANK_GREY_TAB_RECT := Rect2(194.0, 126.0, 84.0, 42.0)
const BANK_CURRENCY_TAB_RECT := Rect2(282.0, 126.0, 90.0, 42.0)
const BANK_DEPOSIT_RECT := Rect2(32.0, 250.0, 326.0, 64.0)
const BANK_WITHDRAW_RECT := Rect2(32.0, 332.0, 326.0, 64.0)
const BANK_PAGE_PREV_RECT := Rect2(32.0, 668.0, 142.0, 50.0)
const BANK_PAGE_NEXT_RECT := Rect2(216.0, 668.0, 142.0, 50.0)
const BANK_MARKET_ROWS_PER_PAGE := 6
const BANK_INTEREST_RATE := 0.03
const DOCKED_MARKET_TICK_SECONDS := 10.0
const HUB_CONTRACTS_RECT := Rect2(35.0, 552.0, 320.0, 58.0)
const HUB_UPGRADES_RECT := Rect2(35.0, 626.0, 320.0, 58.0)
const SUBMENU_BACK_RECT := Rect2(55.0, 742.0, 280.0, 56.0)
const SYSTEM_MAP_RECT := Rect2(16.0, 106.0, 358.0, 466.0)
const SYSTEM_ROUTE_INFO_RECT := Rect2(24.0, 582.0, 342.0, 156.0)
const SYSTEM_MAP_BACK_RECT := Rect2(24.0, 756.0, 158.0, 54.0)
const SYSTEM_FLY_RECT := Rect2(208.0, 756.0, 158.0, 54.0)
const SYSTEM_RESET_RECT := Rect2(292.0, 114.0, 68.0, 34.0)
const SYSTEM_STAR_POS := Vector2(195.0, 350.0)
const SYSTEM_PLANET_HIT_SIZE := 52.0
const SYSTEM_MAP_MIN_ZOOM := 1.0
const SYSTEM_MAP_MAX_ZOOM := 3.6
const POLITICAL_MAP_GRID_X := 20
const POLITICAL_MAP_GRID_Y := 15
const CARGO_CAPACITY_BASE := 8
const PASSENGER_CAPACITY_BASE := 2
const DASH_COOLDOWN := 2.4
const DASH_DURATION := 0.30
const DASH_FORWARD_SPEED := 700.0
const DASH_FORWARD_DISTANCE := 160.0
const DASH_RETURN_RATE := 0.55
const DASH_SCORE_DURATION := 0.9
const LANE_EVENT_FIRST := 7.0
const PLAYER_RADIUS := 14.0
const STATION_HEIGHT_BASE := 300.0
const STATION_HEIGHT_STEP := 45.0
const STATION_HEIGHT_MAX := 660.0
const STATION_SPEED := 210.0
const STATION_CENTER_WALL := 24.0
const STATION_EDGE_WALL := 42.0
const SHOT_RADIUS := 4.0
const SINGLE_INTERVAL := 0.24
const DUAL_INTERVAL := 0.32
const CONE_INTERVAL := 0.72
const SEEKER_INTERVAL := 1.05
const LASER_INTERVAL := 0.06
const SINGLE_DAMAGE := 1.0
const DUAL_DAMAGE := 1.0
const CONE_DAMAGE := 3.0
const SEEKER_DAMAGE := 7.0
const LASER_DPS := 3.0
const REPAIR_INTERVAL_MIN := 24.0
const REPAIR_INTERVAL_MAX := 34.0
const REPAIR_RETRY_FULL := 12.0
const FIELD_REPAIR_CHANCE := 0.28
const ENERGY_ORB_BASE_SCORE := 2
const ENERGY_ORB_DASH_MULT := 3.0
const KILL_ORB_DROP_CHANCE := 0.08
const KILL_REPAIR_DROP_CHANCE := 0.02
const ASTEROID_ORE_DROP_CHANCE := 0.10

# Slice 10 production balance knobs. Keep these centralized so encounter/penalty
# tuning cannot silently drift across gameplay and regression coverage.
const ENCOUNTER_WEALTH_MULT_MIN := 0.65
const ENCOUNTER_WEALTH_MULT_MAX := 1.35
const PIRATE_UNCONTROLLED_BASE_CHANCE := 0.32
const PIRATE_CONTESTED_BASE_CHANCE := 0.22
const POLICE_ENCOUNTER_BASE_CHANCE := 0.12
const POLICE_ENCOUNTER_LEVEL_STEP := 0.045
const POLICE_SCAN_BASE_CHANCE := 0.10
const POLICE_SCAN_LEVEL_STEP := 0.045
const POLICE_OPPORTUNITY_MIN := 11.0
const POLICE_OPPORTUNITY_MAX := 16.0
const PIRATE_OPPORTUNITY_MIN := 9.5
const PIRATE_OPPORTUNITY_MAX := 14.5

const BASIC_CONTAINER_RELATION_LOSS := 3
const REINFORCED_CONTAINER_RELATION_LOSS := 7
const POLICE_SHIP_KILL_RELATION_LOSS := 15
const POLICE_SHIP_KILL_HEAT_GAIN := 20
const HEAVY_ENFORCEMENT_KILL_RELATION_LOSS := 25
const HEAVY_ENFORCEMENT_KILL_HEAT_GAIN := 35
const POLICE_SCAN_RELATION_BASE_LOSS := 6
const POLICE_SCAN_HEAT_BASE_GAIN := 30
const POLICE_SCAN_FINE_BASE := 50
const POLICE_SCAN_FINE_VALUE_FACTOR := 0.25
const ENEMY_SHOT_SPEED := 255.0
const ENEMY_SHOT_RADIUS := 5.0
const ENEMY_MISSILE_SPEED := 190.0
const ENEMY_MISSILE_RADIUS := 7.0
const ENEMY_MISSILE_DAMAGE := 2
const ENEMY_MISSILE_TURN_RATE := 3.2
const HIT_INVULN_TIME := 0.5

var rng := RandomNumberGenerator.new()
var privateer_ui_atlas: Texture2D
var playing := false
var game_over := false
var won := false
var elapsed := 0.0
var level := 1
var shop_open := false
var last_level_bonus := 0
var score := 0
# Legacy variable name retained across the codebase: this is now carried CASH.
var research_credits := 1200
var bank_balance := 0
var currency_holdings: Dictionary = {}
var currency_markets: Dictionary = {}
var bank_interest_cycles := 0
var bank_last_interest := 0
var bank_view := "account"
var bank_market_page := 0
var docked_market_clock := 0.0
var research_ship_speed := 0
var research_dash := 0
var research_damage := 0
var research_hits := 0
var research_shield := 0
var research_start_single := false
var research_start_dual := false
var research_start_laser := false
var research_start_cone := false
var research_start_seeker := false
var starting_weapon := "none"
var research_open := false
var weapon_research_open := false
var profile_menu_open := true
var career_slots_open := false
var career_new_mode := false
var pending_overwrite_slot := 0
var active_career_slot := 0
var last_career_slot := 0
var hub_open := false
var market_open := false
var contracts_open := false
var travel_open := false
var travel_selected_planet := ""
var political_world: Dictionary = {}
var world_seed := 0
var system_map_zoom := 1.0
var system_map_pan := Vector2.ZERO
var political_map_overlay_cells: Array = []
var system_map_touches: Dictionary = {}
var system_map_touch_moved := false
var system_map_last_pinch_distance := 0.0
var system_map_mouse_dragging := false
var system_map_mouse_moved := false
var system_map_mouse_last := Vector2.ZERO
var current_planet := ""
var destination_planet := ""
var route_origin := ""
var route_distance := 1
var route_danger := 1
var route_wealth := 1
var route_duration := 18.0
var route_active := false
var boss_active := false
var boss_defeated_pending := false
var bounty_completed_this_route := false
var encounter_active := false
var encounter_mode := ""
var encounter_faction_id := ""
var encounter_hostile := false
var encounter_timer := 0.0
var encounter_clock := 999.0
var encounter_banner_timer := 0.0
var police_scan_active := false
var police_scan_faction_id := ""
var police_scan_timer := 0.0
var police_scan_duration := 0.0
var police_scan_attempted := false
var police_scan_result_timer := 0.0
var police_scan_result_text := ""
# Legacy mirrors kept for pre-Slice-5 run snapshots/tests.
var pirate_attack_active := false
var pirate_attack_timer := 0.0
var pirate_attack_clock := 999.0
var pirate_banner_timer := 0.0
var last_trip_summary := "Docked"
var planet_names: Array[String] = []
var legal_commodity_names: Array[String] = [
    "Grain", "Protein", "Produce", "Luxury Food",
    "Iron", "Copper", "Titanium", "Rare Alloys",
    "First Aid", "Antibiotics", "Vaccines", "Regenerative Medicine"
]
var grey_commodity_names: Array[String] = [
    "Small Arms", "Heavy Weapons", "Explosives", "Military Tech",
    "Stims", "Sedatives", "Euphorics", "Neurodust",
    "Holovids", "Sim Chips", "VR Experiences", "Unlicensed Media"
]
var commodity_names: Array[String] = legal_commodity_names + grey_commodity_names
const LEGACY_COMMODITY_MAP := {
    "Food": "Grain",
    "Ore": "Iron",
    "Medicine": "First Aid",
    "Electronics": "Sim Chips",
    "Fuel": "Titanium",
    "Arms": "Small Arms",
    "Narcotics": "Stims"
}
const COMMODITY_INFO := {
    "Grain": {"category": "food", "base": 20, "volatility": 0.008},
    "Protein": {"category": "food", "base": 45, "volatility": 0.012},
    "Produce": {"category": "food", "base": 32, "volatility": 0.018},
    "Luxury Food": {"category": "food", "base": 110, "volatility": 0.035},
    "Iron": {"category": "metal", "base": 40, "volatility": 0.010},
    "Copper": {"category": "metal", "base": 70, "volatility": 0.015},
    "Titanium": {"category": "metal", "base": 170, "volatility": 0.028},
    "Rare Alloys": {"category": "metal", "base": 420, "volatility": 0.050},
    "First Aid": {"category": "medicine", "base": 55, "volatility": 0.010},
    "Antibiotics": {"category": "medicine", "base": 95, "volatility": 0.018},
    "Vaccines": {"category": "medicine", "base": 180, "volatility": 0.025},
    "Regenerative Medicine": {"category": "medicine", "base": 520, "volatility": 0.055},
    "Small Arms": {"category": "weapons", "base": 220, "volatility": 0.030},
    "Heavy Weapons": {"category": "weapons", "base": 520, "volatility": 0.050},
    "Explosives": {"category": "weapons", "base": 380, "volatility": 0.060},
    "Military Tech": {"category": "weapons", "base": 900, "volatility": 0.075},
    "Stims": {"category": "narcotics", "base": 160, "volatility": 0.060},
    "Sedatives": {"category": "narcotics", "base": 240, "volatility": 0.045},
    "Euphorics": {"category": "narcotics", "base": 430, "volatility": 0.080},
    "Neurodust": {"category": "narcotics", "base": 780, "volatility": 0.100},
    "Holovids": {"category": "entertainment", "base": 75, "volatility": 0.020},
    "Sim Chips": {"category": "entertainment", "base": 140, "volatility": 0.035},
    "VR Experiences": {"category": "entertainment", "base": 280, "volatility": 0.050},
    "Unlicensed Media": {"category": "entertainment", "base": 500, "volatility": 0.080}
}
var markets: Dictionary = {}
var cargo: Dictionary = {}
var contract_board: Array[Dictionary] = []
var active_contract: Dictionary = {}
var passengers := 0
var economy_tick := 0
var run_paused := false
var banked_this_run := false
var last_banked_score := 0
var max_hp := 2
var shield_charges := 0
var world_scroll := 0.0
var energy := 0
var combo := 1
var best_combo := 1
var hp := 2
var player_x := W * 0.5
var player_y := PLAYER_Y
var target_x := W * 0.5
var invuln := 0.0
var flash := 0.0
var cyan_flash := 0.0
var shake := 0.0
var easy_spawn_clock := 0.0
var hard_spawn_clock := 0.0
var pickup_clock := 0.0
var dash_cooldown := 0.0
var dash_timer := 0.0
var dash_touch_index := -1
var left_touch_index := -1
var right_touch_index := -1
var left_control_held := false
var right_control_held := false
var dash_score_timer := 0.0
var near_miss_timer := 0.0
var near_miss_text := ""
var slowmo_timer := 0.0
var finale_active := false
var finale_banner_timer := 0.0
var extraction_spawned := false
var extraction_lane := ""
var result_reason := ""
var hard_lane_right := true
var lane_event_active := false
var lane_event_timer := 0.0
var next_lane_event_at := LANE_EVENT_FIRST
var lane_events_started := 0
var lane_choice_banner_timer := 0.0
var neutral_spawn_clock := 0.0
var fire_clock := 0.0
var repair_clock := 0.0
var current_weapon := "none"
var weapon_banner_timer := 0.0
var weapon_banner_text := ""
var loot_banner_timer := 0.0
var loot_banner_text := ""
var station_height := STATION_HEIGHT_BASE
var station_top := -STATION_HEIGHT_BASE - 40.0
var station_locked_side := ""
var objects: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var enemy_shots: Array[Dictionary] = []
var pending_drops: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var last_near_ids: Dictionary = {}
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_cursor := 0
var near_sfx: AudioStreamWAV
var dash_sfx: AudioStreamWAV
var finale_sfx: AudioStreamWAV
var shot_sfx: AudioStreamWAV
var dual_sfx: AudioStreamWAV
var cone_sfx: AudioStreamWAV
var seeker_sfx: AudioStreamWAV
var laser_sfx: AudioStreamWAV
var enemy_shot_sfx: AudioStreamWAV
var missile_sfx: AudioStreamWAV
var hit_sfx: AudioStreamWAV
var shield_sfx: AudioStreamWAV
var kill_sfx: AudioStreamWAV
var energy_sfx: AudioStreamWAV
var repair_sfx: AudioStreamWAV
var weapon_pickup_sfx: AudioStreamWAV
var buy_sfx: AudioStreamWAV
var level_clear_sfx: AudioStreamWAV
var death_sfx: AudioStreamWAV
var laser_sfx_clock := 0.0

func _ready() -> void:
    rng.randomize()
    _load_privateer_ui_art()
    _setup_audio()
    _load_career_index()
    _migrate_legacy_career_if_needed()
    profile_menu_open = true
    career_slots_open = false
    hub_open = false
    set_process(true)
    queue_redraw()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
        if (playing or shop_open) and not game_over:
            _pause_run()
        if active_career_slot > 0:
            _save_all_state()

func _setup_audio() -> void:
    for i in 10:
        var player := AudioStreamPlayer.new()
        player.bus = "Master"
        add_child(player)
        sfx_players.append(player)

    near_sfx = _make_sweep(760.0, 1160.0, 0.085, 0.16)
    dash_sfx = _make_sweep(180.0, 520.0, 0.11, 0.22)
    finale_sfx = _make_sweep(480.0, 820.0, 0.18, 0.17)
    shot_sfx = _make_sweep(760.0, 510.0, 0.045, 0.09)
    dual_sfx = _make_sweep(690.0, 430.0, 0.055, 0.085)
    cone_sfx = _make_sweep(330.0, 170.0, 0.10, 0.14, 0.10)
    seeker_sfx = _make_sweep(250.0, 420.0, 0.13, 0.14, 0.06)
    laser_sfx = _make_sweep(1280.0, 1040.0, 0.055, 0.055)
    enemy_shot_sfx = _make_sweep(390.0, 270.0, 0.07, 0.08)
    missile_sfx = _make_sweep(150.0, 250.0, 0.18, 0.13, 0.12)
    hit_sfx = _make_sweep(150.0, 75.0, 0.16, 0.22, 0.22)
    shield_sfx = _make_sweep(920.0, 1460.0, 0.12, 0.16)
    kill_sfx = _make_sweep(520.0, 180.0, 0.11, 0.11, 0.18)
    energy_sfx = _make_sweep(720.0, 1180.0, 0.10, 0.13)
    repair_sfx = _make_sweep(520.0, 960.0, 0.16, 0.13)
    weapon_pickup_sfx = _make_sweep(410.0, 780.0, 0.15, 0.13)
    buy_sfx = _make_sweep(620.0, 840.0, 0.07, 0.09)
    level_clear_sfx = _make_sweep(430.0, 980.0, 0.24, 0.16)
    death_sfx = _make_sweep(210.0, 55.0, 0.34, 0.20, 0.24)

func _make_tone(freq: float, duration: float, volume: float) -> AudioStreamWAV:
    return _make_sweep(freq, freq, duration, volume)

func _make_sweep(start_freq: float, end_freq: float, duration: float, volume: float, noise_mix: float = 0.0) -> AudioStreamWAV:
    var rate := 22050
    var sample_count := maxi(1, int(rate * duration))
    var data := PackedByteArray()
    data.resize(sample_count * 2)
    var phase := 0.0
    var local_rng := RandomNumberGenerator.new()
    local_rng.seed = int(start_freq * 31.0 + end_freq * 17.0 + duration * 10000.0)
    for i in sample_count:
        var u := float(i) / float(sample_count)
        var freq := lerpf(start_freq, end_freq, u)
        phase += TAU * freq / float(rate)
        var envelope := pow(1.0 - u, 1.55)
        var tonal := sin(phase)
        var noise := local_rng.randf_range(-1.0, 1.0)
        var mixed := lerpf(tonal, noise, clampf(noise_mix, 0.0, 1.0))
        var sample := int(clampf(mixed * volume * envelope, -1.0, 1.0) * 32767.0)
        data.encode_s16(i * 2, sample)
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = rate
    wav.stereo = false
    wav.data = data
    return wav

func _play_sfx(stream: AudioStreamWAV, pitch: float = 1.0, volume_db: float = 0.0) -> void:
    if stream == null or sfx_players.is_empty():
        return
    var player := sfx_players[sfx_cursor % sfx_players.size()]
    sfx_cursor = (sfx_cursor + 1) % sfx_players.size()
    player.stop()
    player.stream = stream
    player.pitch_scale = pitch
    player.volume_db = volume_db
    player.play()

func _career_meta_path(slot: int) -> String:
    return "user://career_%d_meta.cfg" % slot

func _career_world_path(slot: int) -> String:
    return "user://career_%d_world.cfg" % slot

func _career_run_path(slot: int) -> String:
    return "user://career_%d_run.cfg" % slot

func _active_meta_path() -> String:
    return _career_meta_path(active_career_slot) if active_career_slot > 0 else ""

func _active_world_path() -> String:
    return _career_world_path(active_career_slot) if active_career_slot > 0 else ""

func _active_run_path() -> String:
    return _career_run_path(active_career_slot) if active_career_slot > 0 else ""

func _career_slot_exists(slot: int) -> bool:
    if slot < 1 or slot > CAREER_SLOT_COUNT:
        return false
    return FileAccess.file_exists(_career_meta_path(slot)) or FileAccess.file_exists(_career_world_path(slot))

func _load_career_index() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(CAREER_INDEX_PATH) != OK:
        last_career_slot = 0
        return
    last_career_slot = clampi(int(cfg.get_value("careers", "last_slot", 0)), 0, CAREER_SLOT_COUNT)
    if last_career_slot > 0 and not _career_slot_exists(last_career_slot):
        last_career_slot = 0

func _save_career_index() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("careers", "last_slot", last_career_slot)
    cfg.save(CAREER_INDEX_PATH)

func _copy_user_file(source_path: String, destination_path: String) -> bool:
    if not FileAccess.file_exists(source_path):
        return false
    var source := FileAccess.open(source_path, FileAccess.READ)
    if source == null:
        return false
    var bytes := source.get_buffer(source.get_length())
    var destination := FileAccess.open(destination_path, FileAccess.WRITE)
    if destination == null:
        return false
    destination.store_buffer(bytes)
    return true

func _migrate_legacy_career_if_needed() -> void:
    for slot in range(1, CAREER_SLOT_COUNT + 1):
        if _career_slot_exists(slot):
            return
    var has_legacy := FileAccess.file_exists(LEGACY_META_SAVE_PATH) or FileAccess.file_exists(LEGACY_PRIVATEER_SAVE_PATH)
    if not has_legacy:
        return
    _copy_user_file(LEGACY_META_SAVE_PATH, _career_meta_path(1))
    _copy_user_file(LEGACY_PRIVATEER_SAVE_PATH, _career_world_path(1))
    _copy_user_file(LEGACY_RUN_SAVE_PATH, _career_run_path(1))
    last_career_slot = 1
    _save_career_index()

func _reset_career_state() -> void:
    research_credits = 1200
    research_ship_speed = 0
    research_dash = 0
    research_damage = 0
    research_hits = 0
    research_shield = 0
    research_start_single = false
    research_start_dual = false
    research_start_laser = false
    research_start_cone = false
    research_start_seeker = false
    starting_weapon = "none"

    political_world.clear()
    world_seed = 0
    planet_names.clear()
    current_planet = ""
    destination_planet = ""
    route_origin = ""
    route_distance = 1
    route_danger = 1
    route_wealth = 1
    route_duration = 18.0
    route_active = false
    boss_active = false
    boss_defeated_pending = false
    bounty_completed_this_route = false
    encounter_active = false
    encounter_mode = ""
    encounter_faction_id = ""
    encounter_hostile = false
    encounter_timer = 0.0
    encounter_clock = 999.0
    encounter_banner_timer = 0.0
    police_scan_active = false
    police_scan_faction_id = ""
    police_scan_timer = 0.0
    police_scan_duration = 0.0
    police_scan_attempted = false
    police_scan_result_timer = 0.0
    police_scan_result_text = ""
    pirate_attack_active = false
    pirate_attack_timer = 0.0
    pirate_attack_clock = 999.0
    pirate_banner_timer = 0.0
    last_trip_summary = "Docked"
    system_map_zoom = 1.0
    system_map_pan = Vector2.ZERO
    political_map_overlay_cells.clear()
    system_map_touches.clear()
    markets.clear()
    cargo.clear()
    contract_board.clear()
    active_contract.clear()
    passengers = 0
    economy_tick = 0

    playing = false
    game_over = false
    won = false
    elapsed = 0.0
    level = 1
    shop_open = false
    score = 0
    energy = 0
    combo = 1
    best_combo = 1
    max_hp = 2
    hp = 2
    shield_charges = 0
    run_paused = false
    banked_this_run = false
    world_scroll = 0.0
    objects.clear()
    shots.clear()
    enemy_shots.clear()
    pending_drops.clear()
    particles.clear()
    last_near_ids.clear()
    research_open = false
    weapon_research_open = false
    market_open = false
    contracts_open = false
    travel_open = false
    _clear_control_holds()
    _init_privateer_world()

func _create_new_career(slot: int) -> bool:
    if slot < 1 or slot > CAREER_SLOT_COUNT:
        return false
    active_career_slot = slot
    _reset_career_state()
    _clear_run_snapshot()
    _save_all_state()
    last_career_slot = slot
    _save_career_index()
    profile_menu_open = false
    career_slots_open = false
    career_new_mode = false
    pending_overwrite_slot = 0
    hub_open = true
    queue_redraw()
    return true

func _load_career(slot: int) -> bool:
    if not _career_slot_exists(slot):
        return false
    active_career_slot = slot
    _reset_career_state()
    _load_meta()
    _load_privateer_state()
    profile_menu_open = false
    career_slots_open = false
    career_new_mode = false
    pending_overwrite_slot = 0
    last_career_slot = slot
    _save_career_index()
    if _load_run_snapshot():
        run_paused = true
        hub_open = false
    else:
        run_paused = false
        hub_open = true
    queue_redraw()
    return true

func _continue_career() -> bool:
    if last_career_slot <= 0 or not _career_slot_exists(last_career_slot):
        return false
    return _load_career(last_career_slot)

func _career_slot_summary(slot: int) -> Dictionary:
    var result := {
        "exists": _career_slot_exists(slot),
        "planet": "",
        "credits": 0,
        "in_flight": false,
        "destination": ""
    }
    if not bool(result.exists):
        return result
    var meta := ConfigFile.new()
    if meta.load(_career_meta_path(slot)) == OK:
        result.credits = int(meta.get_value("meta", "credits", 0))
    var world_cfg := ConfigFile.new()
    var saved_world: Dictionary = {}
    if world_cfg.load(_career_world_path(slot)) == OK:
        var saved_id := String(world_cfg.get_value("world", "planet", ""))
        saved_world = world_cfg.get_value("political", "world", {})
        result.planet = PoliticalWorld.planet_name(saved_world, saved_id) if not saved_world.is_empty() else saved_id
    var run := ConfigFile.new()
    if run.load(_career_run_path(slot)) == OK and bool(run.get_value("run", "exists", false)):
        result.in_flight = bool(run.get_value("run", "route_active", false))
        var destination_id := String(run.get_value("run", "destination_planet", ""))
        var origin_id := String(run.get_value("run", "route_origin", ""))
        result.destination = PoliticalWorld.planet_name(saved_world, destination_id) if not saved_world.is_empty() else destination_id
        if bool(result.in_flight):
            result.planet = PoliticalWorld.planet_name(saved_world, origin_id) if not saved_world.is_empty() else origin_id
    return result


func _open_profile_menu() -> void:
    if active_career_slot > 0:
        _save_all_state()
    profile_menu_open = true
    career_slots_open = false
    career_new_mode = false
    pending_overwrite_slot = 0
    hub_open = false
    market_open = false
    contracts_open = false
    travel_open = false
    research_open = false
    weapon_research_open = false
    queue_redraw()

func _generate_political_world(seed_override: int = 0) -> void:
    if seed_override != 0:
        world_seed = seed_override
    elif world_seed == 0:
        world_seed = int(rng.randi())
        if world_seed == 0:
            world_seed = 1
    political_world = PoliticalWorld.generate(world_seed)
    _sync_generated_planets()

func _sync_generated_planets() -> void:
    planet_names.clear()
    for planet in political_world.get("planets", []):
        planet_names.append(String(planet.id))
    if current_planet.is_empty() or not planet_names.has(current_planet):
        current_planet = planet_names[0] if not planet_names.is_empty() else ""
    _rebuild_political_map_overlay()

func _planet_display_name(planet_id: String) -> String:
    if ["Aster", "Cinder", "Vesper", "Helix"].has(planet_id):
        return planet_id
    return PoliticalWorld.planet_name(political_world, planet_id)

func _planet_type(planet_id: String) -> String:
    if ["Aster", "Cinder", "Vesper", "Helix"].has(planet_id):
        return PoliticalWorld.legacy_type_for_name(planet_id)
    return PoliticalWorld.planet_type(political_world, planet_id)

func _planet_visual_key(planet_id: String) -> String:
    if ["Aster", "Cinder", "Vesper", "Helix"].has(planet_id):
        return planet_id
    return PoliticalWorld.visual_key_for_type(_planet_type(planet_id))

func _get_political_context_at(position: Vector2) -> Dictionary:
    return PoliticalWorld.political_context_at(political_world, position)

func _political_laws_at(position: Vector2) -> Dictionary:
    var context := _get_political_context_at(position)
    var faction_id := String(context.get("faction_id", ""))
    if faction_id.is_empty():
        return {}
    return PoliticalWorld.faction_record(political_world, faction_id).get("laws", {}).duplicate(true)

func _ensure_crime_schema() -> bool:
    return PoliticalWorld.ensure_crime_schema(political_world)

func _ensure_enforcement_schema() -> bool:
    return PoliticalWorld.ensure_enforcement_schema(political_world)

func _ensure_route_wealth_schema() -> bool:
    return PoliticalWorld.ensure_route_wealth(political_world)

func _faction_level(faction_id: String) -> int:
    return PoliticalWorld.faction_level(political_world, faction_id)

func _faction_relation(faction_id: String) -> int:
    return PoliticalWorld.faction_relation(political_world, faction_id)

func _faction_heat(faction_id: String) -> int:
    return PoliticalWorld.faction_heat(political_world, faction_id)

func _faction_crime_state(faction_id: String) -> Dictionary:
    return PoliticalWorld.faction_crime_state(political_world, faction_id)

func _is_criminal_with_faction(faction_id: String) -> bool:
    return bool(_faction_crime_state(faction_id).get("criminal", false))

func _police_hostile_eligible(faction_id: String) -> bool:
    return bool(_faction_crime_state(faction_id).get("police_hostile", false))

func _heavy_enforcement_eligible(faction_id: String) -> bool:
    return bool(_faction_crime_state(faction_id).get("heavy_enforcement", false))

func _adjust_faction_relation(faction_id: String, delta: int, persist: bool = true) -> int:
    var value := PoliticalWorld.adjust_faction_relation(political_world, faction_id, delta)
    if persist and not faction_id.is_empty():
        _save_all_state()
    queue_redraw()
    return value

func _adjust_faction_heat(faction_id: String, delta: int, persist: bool = true) -> int:
    var value := PoliticalWorld.adjust_faction_heat(political_world, faction_id, delta)
    if persist and not faction_id.is_empty():
        _save_all_state()
    queue_redraw()
    return value

func _record_faction_crime(faction_id: String, relation_loss: int, heat_gain: int, offense: String = "", persist: bool = true) -> Dictionary:
    var state := PoliticalWorld.record_crime(political_world, faction_id, relation_loss, heat_gain, offense)
    if persist and not state.is_empty():
        _save_all_state()
    queue_redraw()
    return state

func _decay_all_faction_heat(amount: int, persist: bool = true) -> bool:
    var changed := PoliticalWorld.decay_all_heat(political_world, amount)
    if changed and persist:
        _save_all_state()
    if changed:
        queue_redraw()
    return changed

func _planet_faction_ids(planet_id: String) -> Array[String]:
    var context := _get_political_context_at(_system_planet_world_position(planet_id))
    var result: Array[String] = []
    var state := String(context.get("state", "UNCONTROLLED"))
    if state == "CONTESTED":
        for faction_id in context.get("contesting_factions", []):
            var fid := String(faction_id)
            if not fid.is_empty() and not result.has(fid):
                result.append(fid)
    else:
        var fid := String(context.get("faction_id", ""))
        if not fid.is_empty():
            result.append(fid)
    return result

func _faction_status_summary(faction_id: String) -> String:
    if faction_id.is_empty():
        return "NO FACTION"
    var state := _faction_crime_state(faction_id)
    return "L%d  REP %+d %s  H%d %s" % [
        _faction_level(faction_id),
        int(state.get("relation", 0)),
        String(state.get("relation_label", "NEUTRAL")),
        int(state.get("heat", 0)),
        String(state.get("heat_label", "CLEAR"))
    ]

func _planet_crime_summary(planet_id: String) -> String:
    var factions := _planet_faction_ids(planet_id)
    if factions.is_empty():
        return "NO FACTION RECORD"
    if factions.size() == 1:
        return _faction_status_summary(factions[0])
    var first := _faction_crime_state(factions[0])
    var second := _faction_crime_state(factions[1])
    return "REP %+d/H%d • %+d/H%d" % [
        int(first.get("relation", 0)), int(first.get("heat", 0)),
        int(second.get("relation", 0)), int(second.get("heat", 0))
    ]

func _short_map_label(value: String, max_chars: int = 12) -> String:
    if value.length() <= max_chars:
        return value
    return value.substr(0, maxi(1, max_chars - 1)) + "…"

func _faction_tag(faction_id: String) -> String:
    var faction := PoliticalWorld.faction_record(political_world, faction_id)
    var name := String(faction.get("name", faction_id))
    var tag := ""
    for part in name.split(" ", false):
        var word := String(part)
        if not word.is_empty():
            tag += word.substr(0, 1).to_upper()
    if tag.is_empty():
        tag = faction_id.to_upper()
    return tag.substr(0, mini(4, tag.length()))

func _faction_map_status_line(faction_id: String) -> String:
    var faction := PoliticalWorld.faction_record(political_world, faction_id)
    var state := _faction_crime_state(faction_id)
    return "%s  R%+d %s  H%d %s" % [
        _short_map_label(String(faction.get("name", faction_id)).to_upper(), 12),
        int(state.get("relation", 0)),
        String(state.get("relation_label", "NEUTRAL")),
        int(state.get("heat", 0)),
        String(state.get("heat_label", "CLEAR"))
    ]

func _faction_status_color(faction_id: String) -> Color:
    var state := _faction_crime_state(faction_id)
    if bool(state.get("heavy_enforcement", false)):
        return Color("ff6687")
    if bool(state.get("police_hostile", false)):
        return Color("ffb347")
    return Color("8ea9b8")

func _planet_political_status_lines(planet_id: String) -> Array[String]:
    var faction_ids := _planet_faction_ids(planet_id)
    var lines: Array[String] = []
    if faction_ids.is_empty():
        lines.append("NO FACTION RECORD")
        return lines
    for faction_id in faction_ids:
        lines.append(_faction_map_status_line(faction_id))
        if lines.size() >= 2:
            break
    return lines

func _commodity_legality_at(position: Vector2, commodity: String) -> Dictionary:
    return PoliticalWorld.commodity_legality_at(political_world, position, commodity)

func _planet_commodity_legality(planet_id: String, commodity: String) -> Dictionary:
    return _commodity_legality_at(_system_planet_world_position(planet_id), commodity)

func _commodity_legality_color(status: String) -> Color:
    match status:
        "ILLEGAL":
            return Color("ff6687")
        "MIXED":
            return Color("ffb347")
        "UNREGULATED":
            return Color("8ea9b8")
        _:
            return Color("6bffb0")

func _commodity_legality_short(planet_id: String, commodity: String) -> String:
    var legality: Dictionary = _planet_commodity_legality(planet_id, commodity)
    match String(legality.get("status", "LEGAL")):
        "ILLEGAL":
            return "ILLEGAL"
        "MIXED":
            return "MIXED"
        "UNREGULATED":
            return "FREE"
        _:
            return "LEGAL"

func _planet_law_summary(planet_id: String) -> String:
    var faction_ids := _planet_faction_ids(planet_id)
    if faction_ids.size() >= 2:
        var pieces: Array[String] = []
        for faction_id in faction_ids:
            pieces.append("%s A:%s N:%s" % [
                _faction_tag(faction_id),
                "OK" if PoliticalWorld.faction_commodity_legal(political_world, faction_id, "Arms") else "NO",
                "OK" if PoliticalWorld.faction_commodity_legal(political_world, faction_id, "Narcotics") else "NO"
            ])
            if pieces.size() >= 2:
                break
        return " • ".join(pieces)
    return "ARMS %s  NARC %s" % [
        _commodity_legality_short(planet_id, "Arms"),
        _commodity_legality_short(planet_id, "Narcotics")
    ]

func _planet_jurisdiction_label(planet_id: String) -> String:
    var context: Dictionary = _get_political_context_at(_system_planet_world_position(planet_id))
    var state: String = String(context.get("state", "UNCONTROLLED"))
    if state == "UNCONTROLLED":
        return "UNCONTROLLED"
    if state == "CONTESTED":
        var first: Dictionary = PoliticalWorld.faction_record(political_world, String(context.get("strongest_faction_id", "")))
        var second: Dictionary = PoliticalWorld.faction_record(political_world, String(context.get("second_faction_id", "")))
        return "CONTESTED • %s / %s" % [String(first.get("name", "?")), String(second.get("name", "?"))]
    var faction: Dictionary = PoliticalWorld.faction_record(political_world, String(context.get("faction_id", "")))
    return "%s • %s" % [String(faction.get("name", "UNKNOWN")), state]

func _route_political_segment_at_progress(origin: String, destination: String, progress: float) -> Dictionary:
    var route := PoliticalWorld.direct_route(political_world, origin, destination)
    if route.is_empty():
        return {}
    var t := clampf(progress, 0.0, 1.0)
    for segment in route.get("segments", []):
        if t >= float(segment.start_t) and t <= float(segment.end_t) + 0.0001:
            return segment.duplicate(true)
    return {}

func _direct_route_spec(origin: String, destination: String) -> Dictionary:
    var route := PoliticalWorld.direct_route(political_world, origin, destination)
    if route.is_empty():
        return {}
    return {
        "distance": int(route.distance),
        "danger": int(route.danger),
        "wealth": int(route.get("wealth", 1)),
        "segments": route.segments,
        "direct": true,
        "path": [origin, destination],
        "hops": 1
    }

func _route_political_percentages_for_spec(spec: Dictionary) -> Dictionary:
    var totals := {"CORE": 0.0, "CONTROLLED": 0.0, "CONTESTED": 0.0, "UNCONTROLLED": 0.0}
    var path: Array = spec.get("path", [])
    var total_weight := 0.0
    for i in range(maxi(0, path.size() - 1)):
        var route := PoliticalWorld.direct_route(political_world, String(path[i]), String(path[i + 1]))
        var length := float(route.get("length", 1.0))
        for segment in route.get("segments", []):
            var weight := length * maxf(0.0, float(segment.end_t) - float(segment.start_t))
            var state := String(segment.state)
            totals[state] = float(totals.get(state, 0.0)) + weight
            total_weight += weight
    if total_weight > 0.0:
        for state in totals.keys():
            totals[state] = float(totals[state]) / total_weight
    return totals

func _route_political_percentages(origin: String, destination: String) -> Dictionary:
    return _route_political_percentages_for_spec(_route_spec(origin, destination))

func _route_pirate_exposure(origin: String, destination: String) -> float:
    var pct := _route_political_percentages(origin, destination)
    return clampf(float(pct.get("CONTESTED", 0.0)) + float(pct.get("UNCONTROLLED", 0.0)), 0.0, 1.0)

func _commodity_category(commodity: String) -> String:
    return String(COMMODITY_INFO.get(commodity, {}).get("category", "unknown"))

func _commodity_volatility(commodity: String) -> float:
    return float(COMMODITY_INFO.get(commodity, {}).get("volatility", 0.02))

func _commodity_base_price(commodity: String) -> int:
    return int(COMMODITY_INFO.get(commodity, {}).get("base", 50))

func _is_grey_commodity(commodity: String) -> bool:
    return grey_commodity_names.has(commodity)

func _migrate_commodity_id(commodity: String) -> String:
    return String(LEGACY_COMMODITY_MAP.get(commodity, commodity))

func _new_market_entry(planet: String, commodity: String) -> Dictionary:
    var flow: Vector2 = _market_profile(planet, commodity)
    var starting_stock: float = clampf(58.0 + flow.x * 3.0 - flow.y * 2.0, 18.0, 112.0)
    return {
        "stock": starting_stock,
        "production": flow.x,
        "consumption": flow.y,
        "price_factor": 1.0,
        "volatility": _commodity_volatility(commodity)
    }

func _ensure_commodity_schema() -> bool:
    var changed := false

    # Economy-2 -> economy-3 cargo migration. Existing cargo quantities are
    # preserved by mapping each retired good into its closest new instrument.
    for legacy_name in LEGACY_COMMODITY_MAP.keys():
        if cargo.has(legacy_name):
            var quantity := int(cargo.get(legacy_name, 0))
            var replacement := _migrate_commodity_id(String(legacy_name))
            cargo[replacement] = int(cargo.get(replacement, 0)) + quantity
            cargo.erase(legacy_name)
            changed = true

    for commodity in commodity_names:
        if not cargo.has(commodity):
            cargo[commodity] = 0
            changed = true

    for planet in planet_names:
        var planet_market: Dictionary = markets.get(planet, {})
        # Preserve legacy stock in the mapped replacement when practical, then
        # retire all old seven-good keys so active markets contain exactly 24.
        for legacy_name in LEGACY_COMMODITY_MAP.keys():
            if planet_market.has(legacy_name):
                var replacement := _migrate_commodity_id(String(legacy_name))
                if not planet_market.has(replacement):
                    var migrated_entry := _new_market_entry(planet, replacement)
                    var old_entry: Dictionary = planet_market[legacy_name]
                    migrated_entry["stock"] = clampf(float(old_entry.get("stock", migrated_entry.stock)), 2.0, 140.0)
                    planet_market[replacement] = migrated_entry
                planet_market.erase(legacy_name)
                changed = true
        for commodity in commodity_names:
            if not planet_market.has(commodity):
                planet_market[commodity] = _new_market_entry(planet, commodity)
                changed = true
            else:
                var entry: Dictionary = planet_market[commodity]
                if not entry.has("price_factor"):
                    entry["price_factor"] = 1.0
                    changed = true
                if not entry.has("volatility"):
                    entry["volatility"] = _commodity_volatility(commodity)
                    changed = true
                var flow := _market_profile(planet, commodity)
                entry["production"] = flow.x
                entry["consumption"] = flow.y
                planet_market[commodity] = entry
        markets[planet] = planet_market
    return changed

func _ensure_currency_schema() -> bool:
    var changed := false
    var live_ids: Dictionary = {}
    for faction in political_world.get("factions", []):
        var faction_id := String(faction.get("id", ""))
        live_ids[faction_id] = true
        if not currency_holdings.has(faction_id):
            currency_holdings[faction_id] = 0
            changed = true
        if not currency_markets.has(faction_id):
            currency_markets[faction_id] = {
                "price_factor": 1.0,
                "volatility": 0.018 + float(int(faction.get("level", 1)) - 1) * 0.002
            }
            changed = true
    for faction_id in currency_holdings.keys():
        if not live_ids.has(String(faction_id)):
            currency_holdings.erase(faction_id)
            changed = true
    for faction_id in currency_markets.keys():
        if not live_ids.has(String(faction_id)):
            currency_markets.erase(faction_id)
            changed = true
    return changed

func _init_privateer_world() -> void:
    if political_world.is_empty() or int(political_world.get("schema", 0)) < POLITICAL_WORLD_SCHEMA:
        _generate_political_world()
    else:
        world_seed = int(political_world.get("seed", world_seed))
        _sync_generated_planets()
    if current_planet.is_empty() and not planet_names.is_empty():
        current_planet = planet_names[0]
    _ensure_crime_schema()
    _ensure_enforcement_schema()
    PoliticalWorld.ensure_grey_law_schema(political_world)
    _ensure_commodity_schema()
    _ensure_currency_schema()
    if contract_board.is_empty():
        _regenerate_contracts()
    if last_trip_summary == "Docked":
        last_trip_summary = "Docked at %s" % _planet_display_name(current_planet)

func _market_profile(planet: String, commodity: String) -> Vector2:
    var category := _commodity_category(commodity)
    match _planet_type(planet):
        "LUSH":
            match category:
                "food": return Vector2(9.0, 3.0)
                "metal": return Vector2(2.0, 6.0)
                "medicine": return Vector2(4.0, 4.0)
                "weapons": return Vector2(1.0, 6.0)
                "narcotics": return Vector2(8.0, 3.0)
                "entertainment": return Vector2(5.0, 4.0)
        "VOLCANIC":
            match category:
                "food": return Vector2(1.0, 8.0)
                "metal": return Vector2(10.0, 2.0)
                "medicine": return Vector2(2.0, 6.0)
                "weapons": return Vector2(6.0, 4.0)
                "narcotics": return Vector2(1.0, 6.0)
                "entertainment": return Vector2(2.0, 5.0)
        "FROZEN":
            match category:
                "food": return Vector2(4.0, 6.0)
                "metal": return Vector2(3.0, 5.0)
                "medicine": return Vector2(9.0, 2.0)
                "weapons": return Vector2(2.0, 5.0)
                "narcotics": return Vector2(4.0, 4.0)
                "entertainment": return Vector2(3.0, 6.0)
        "INDUSTRIAL":
            match category:
                "food": return Vector2(2.0, 7.0)
                "metal": return Vector2(8.0, 3.0)
                "medicine": return Vector2(4.0, 4.0)
                "weapons": return Vector2(10.0, 2.0)
                "narcotics": return Vector2(2.0, 6.0)
                "entertainment": return Vector2(8.0, 3.0)
    return Vector2(4.0, 4.0)

func _market_law_multiplier(planet: String, commodity: String) -> float:
    if not _is_grey_commodity(commodity):
        return 1.0
    var status := String(_planet_commodity_legality(planet, commodity).get("status", "LEGAL"))
    match status:
        "ILLEGAL":
            return 1.30
        "MIXED":
            return 1.14
        _:
            return 1.0

func _market_planet_bias(planet: String, commodity: String) -> float:
    var category := _commodity_category(commodity)
    var type_id := _planet_type(planet)
    if type_id == "LUSH" and category == "food": return 0.88
    if type_id == "VOLCANIC" and category == "metal": return 0.86
    if type_id == "FROZEN" and category == "medicine": return 0.86
    if type_id == "INDUSTRIAL" and category == "weapons": return 0.84
    if type_id == "LUSH" and category == "narcotics": return 0.86
    if type_id == "INDUSTRIAL" and category == "entertainment": return 0.90
    return 1.0

func _market_price(planet: String, commodity: String) -> int:
    if not markets.has(planet) or not markets[planet].has(commodity):
        return maxi(1, int(round(float(_commodity_base_price(commodity)) * _market_law_multiplier(planet, commodity))))
    var data: Dictionary = markets[planet][commodity]
    var stock := float(data.get("stock", 52.0))
    var production := float(data.get("production", 4.0))
    var consumption := float(data.get("consumption", 4.0))
    var target_stock := 52.0 + consumption * 4.5
    var scarcity := clampf((target_stock - stock) / maxf(20.0, target_stock), -0.55, 1.25)
    var flow_pressure := clampf((consumption - production) / 12.0, -0.25, 0.45)
    var price_factor := clampf(float(data.get("price_factor", 1.0)), 0.62, 1.60)
    return maxi(1, int(round(
        float(_commodity_base_price(commodity))
        * _market_planet_bias(planet, commodity)
        * _market_law_multiplier(planet, commodity)
        * price_factor
        * (1.0 + scarcity * 0.72 + flow_pressure * 0.20)
    )))

func _market_buy_price(planet: String, commodity: String) -> int:
    return maxi(1, int(ceil(float(_market_price(planet, commodity)) * 1.06)))

func _market_sell_price(planet: String, commodity: String) -> int:
    return maxi(1, int(floor(float(_market_price(planet, commodity)) * 0.94)))

func _faction_currency_base_price(faction_id: String) -> float:
    var faction := PoliticalWorld.faction_record(political_world, faction_id)
    if faction.is_empty():
        return 100.0
    var controlled_worlds := 0
    var wealth_sum := 0.0
    for planet_id in planet_names:
        if _planet_primary_faction(planet_id) == faction_id:
            controlled_worlds += 1
            var neighbors := PoliticalWorld.neighbors(political_world, planet_id)
            for neighbor in neighbors:
                var route := PoliticalWorld.direct_route(political_world, planet_id, neighbor)
                wealth_sum += float(route.get("wealth", 1))
    var level_component := float(_faction_level(faction_id)) * 12.0
    var territory_component := float(controlled_worlds) * 2.5
    var traffic_component := minf(22.0, wealth_sum * 0.35)
    return 55.0 + level_component + territory_component + traffic_component

func _faction_currency_price(faction_id: String) -> int:
    var market: Dictionary = currency_markets.get(faction_id, {"price_factor": 1.0})
    return maxi(1, int(round(_faction_currency_base_price(faction_id) * clampf(float(market.get("price_factor", 1.0)), 0.65, 1.55))))

func _currency_buy_price(faction_id: String) -> int:
    return maxi(1, int(ceil(float(_faction_currency_price(faction_id)) * 1.02)))

func _currency_sell_price(faction_id: String) -> int:
    return maxi(1, int(floor(float(_faction_currency_price(faction_id)) * 0.98)))

func _simulate_economy(ticks: int) -> void:
    _ensure_currency_schema()
    for step in maxi(1, ticks):
        economy_tick += 1
        for planet in planet_names:
            var planet_market: Dictionary = markets[planet]
            for commodity in commodity_names:
                var data: Dictionary = planet_market[commodity]
                var noise := rng.randf_range(-1.4, 1.4)
                data["stock"] = clampf(float(data.get("stock", 52.0)) + float(data.get("production", 4.0)) - float(data.get("consumption", 4.0)) + noise, 2.0, 140.0)
                var volatility := float(data.get("volatility", _commodity_volatility(commodity)))
                var factor := float(data.get("price_factor", 1.0))
                var mean_reversion := (1.0 - factor) * 0.08
                data["price_factor"] = clampf(factor + mean_reversion + rng.randf_range(-volatility, volatility), 0.62, 1.60)
                planet_market[commodity] = data
            markets[planet] = planet_market
        for faction_id in currency_markets.keys():
            var currency: Dictionary = currency_markets[faction_id]
            var factor := float(currency.get("price_factor", 1.0))
            var volatility := float(currency.get("volatility", 0.02))
            currency["price_factor"] = clampf(factor + (1.0 - factor) * 0.06 + rng.randf_range(-volatility, volatility), 0.68, 1.50)
            currency_markets[faction_id] = currency

func _cargo_used() -> int:
    var used := 0
    for commodity in commodity_names:
        used += int(cargo.get(commodity, 0))
    if not active_contract.is_empty() and String(active_contract.get("type", "")) == "delivery":
        used += 1
    return used

func _cargo_capacity() -> int:
    return CARGO_CAPACITY_BASE

func _passenger_capacity() -> int:
    return PASSENGER_CAPACITY_BASE

func _deposit_all_cash() -> int:
    var amount := maxi(0, research_credits)
    if amount <= 0:
        return 0
    research_credits = 0
    bank_balance += amount
    _play_sfx(buy_sfx, 1.08, -3.0)
    _save_all_state()
    return amount

func _withdraw_all_bank() -> int:
    var amount := maxi(0, bank_balance)
    if amount <= 0:
        return 0
    bank_balance = 0
    research_credits += amount
    _play_sfx(buy_sfx, 0.96, -3.0)
    _save_all_state()
    return amount

func _apply_bank_interest() -> int:
    if bank_balance <= 0:
        bank_last_interest = 0
        return 0
    var interest := maxi(0, int(round(float(bank_balance) * BANK_INTEREST_RATE)))
    bank_balance += interest
    bank_last_interest = interest
    bank_interest_cycles += 1
    return interest

func _buy_currency(faction_id: String) -> bool:
    if not currency_holdings.has(faction_id):
        return false
    var price := _currency_buy_price(faction_id)
    if research_credits < price:
        return false
    research_credits -= price
    currency_holdings[faction_id] = int(currency_holdings.get(faction_id, 0)) + 1
    _play_sfx(buy_sfx, 1.04, -3.0)
    _save_all_state()
    return true

func _sell_currency(faction_id: String) -> bool:
    var held := int(currency_holdings.get(faction_id, 0))
    if held <= 0:
        return false
    research_credits += _currency_sell_price(faction_id)
    currency_holdings[faction_id] = held - 1
    _play_sfx(buy_sfx, 0.95, -3.0)
    _save_all_state()
    return true

func _buy_commodity(commodity: String) -> bool:
    if not commodity_names.has(commodity) or _cargo_used() >= _cargo_capacity():
        return false
    var data: Dictionary = markets[current_planet][commodity]
    if float(data.get("stock", 0.0)) < 1.0:
        return false
    var price := _market_buy_price(current_planet, commodity)
    if research_credits < price:
        return false
    research_credits -= price
    cargo[commodity] = int(cargo.get(commodity, 0)) + 1
    data["stock"] = maxf(0.0, float(data.get("stock", 0.0)) - 1.0)
    markets[current_planet][commodity] = data
    _play_sfx(buy_sfx, 1.05, -3.0)
    _save_all_state()
    return true

func _sell_commodity(commodity: String) -> bool:
    if not commodity_names.has(commodity) or int(cargo.get(commodity, 0)) <= 0:
        return false
    var price := _market_sell_price(current_planet, commodity)
    cargo[commodity] = int(cargo.get(commodity, 0)) - 1
    research_credits += price
    var data: Dictionary = markets[current_planet][commodity]
    data["stock"] = minf(140.0, float(data.get("stock", 0.0)) + 1.0)
    markets[current_planet][commodity] = data
    _play_sfx(buy_sfx, 0.94, -3.0)
    _save_all_state()
    return true

func _route_spec(origin: String, dest: String) -> Dictionary:
    return PoliticalWorld.route_spec(political_world, origin, dest)

func _other_planets(origin: String) -> Array[String]:
    var result: Array[String] = []
    for planet in planet_names:
        if planet != origin:
            result.append(planet)
    return result

func _planet_primary_faction(planet_id: String) -> String:
    if planet_id.is_empty() or not planet_names.has(planet_id):
        return ""
    var context := _get_political_context_at(_system_planet_world_position(planet_id))
    var state := String(context.get("state", "UNCONTROLLED"))
    if state == "UNCONTROLLED":
        return ""
    if state == "CONTESTED":
        return String(context.get("strongest_faction_id", ""))
    return String(context.get("faction_id", context.get("strongest_faction_id", "")))

func _contract_issuer_name(faction_id: String, smuggling: bool = false) -> String:
    if smuggling:
        return "UNDERWORLD"
    if faction_id.is_empty():
        return "LOCAL"
    return String(PoliticalWorld.faction_record(political_world, faction_id).get("name", "LOCAL"))

func _contract_destination_profiles(origin: String) -> Array:
    var profiles: Array = []
    for destination in _other_planets(origin):
        var spec := _route_spec(origin, destination)
        if spec.get("path", []).is_empty():
            continue
        var pct := _route_political_percentages_for_spec(spec)
        profiles.append({
            "destination": destination,
            "spec": spec,
            "pirate_exposure": clampf(float(pct.get("CONTESTED", 0.0)) + float(pct.get("UNCONTROLLED", 0.0)), 0.0, 1.0),
            "destination_faction": _planet_primary_faction(destination),
            "destination_state": String(_get_political_context_at(_system_planet_world_position(destination)).get("state", "UNCONTROLLED"))
        })
    return profiles

func _best_legal_delivery_profile(origin: String, profiles: Array) -> Dictionary:
    var best: Dictionary = {}
    var best_score := -INF
    for profile_variant in profiles:
        var profile: Dictionary = profile_variant
        var destination := String(profile.destination)
        var commodity := ""
        var commodity_score := -INF
        for candidate in commodity_names:
            var legality := String(_planet_commodity_legality(destination, candidate).get("status", "LEGAL"))
            if legality == "ILLEGAL":
                continue
            var spread := float(_market_sell_price(destination, candidate) - _market_buy_price(origin, candidate))
            var demand := float(_market_profile(destination, candidate).y - _market_profile(destination, candidate).x) * 5.0
            var score := spread + demand + float(_commodity_base_price(candidate)) * 0.08
            if score > commodity_score:
                commodity_score = score
                commodity = candidate
        if commodity.is_empty():
            continue
        var total_score := commodity_score + float(profile.get("pirate_exposure", 0.0)) * 45.0 + rng.randf_range(0.0, 18.0)
        if total_score > best_score:
            best_score = total_score
            best = profile.duplicate(true)
            best["commodity"] = commodity
    return best

func _best_smuggling_profile(origin: String, profiles: Array) -> Dictionary:
    var best: Dictionary = {}
    var best_score := -INF
    for profile_variant in profiles:
        var profile: Dictionary = profile_variant
        var destination := String(profile.destination)
        for commodity in PoliticalWorld.RESTRICTED_COMMODITIES:
            if String(_planet_commodity_legality(destination, commodity).get("status", "LEGAL")) != "ILLEGAL":
                continue
            var score := float(_commodity_base_price(commodity))
            score += float(_market_sell_price(destination, commodity) - _market_buy_price(origin, commodity))
            score += float(profile.get("pirate_exposure", 0.0)) * 80.0
            score += rng.randf_range(0.0, 22.0)
            if score > best_score:
                best_score = score
                best = profile.duplicate(true)
                best["commodity"] = commodity
    return best

func _best_passenger_profile(profiles: Array, issuer_faction: String) -> Dictionary:
    var best: Dictionary = {}
    var best_score := -INF
    for profile_variant in profiles:
        var profile: Dictionary = profile_variant
        var destination_faction := String(profile.get("destination_faction", ""))
        var destination_state := String(profile.get("destination_state", "UNCONTROLLED"))
        var political_value := 0.0
        if destination_state == "CONTESTED":
            political_value += 80.0
        elif destination_faction != issuer_faction:
            political_value += 60.0
        if destination_state == "UNCONTROLLED":
            political_value += 30.0
        var spec: Dictionary = profile.spec
        var score := political_value + float(spec.get("distance", 1)) * 8.0 + rng.randf_range(0.0, 35.0)
        if score > best_score:
            best_score = score
            best = profile.duplicate(true)
    return best

func _best_bounty_profiles(profiles: Array, count: int) -> Array:
    var ranked: Array = []
    for profile_variant in profiles:
        var profile: Dictionary = profile_variant.duplicate(true)
        var spec: Dictionary = profile.spec
        profile["bounty_score"] = float(profile.get("pirate_exposure", 0.0)) * 1000.0 + float(spec.get("danger", 1)) * 40.0 + rng.randf_range(0.0, 25.0)
        ranked.append(profile)
    ranked.sort_custom(func(a, b): return float(a.get("bounty_score", 0.0)) > float(b.get("bounty_score", 0.0)))
    var result: Array = []
    for profile in ranked:
        if float(profile.get("pirate_exposure", 0.0)) <= 0.0 and not result.is_empty():
            continue
        result.append(profile)
        if result.size() >= count:
            break
    return result

func _contract_reward_breakdown(kind: String, origin: String, destination: String, commodity: String = "", smuggling: bool = false) -> Dictionary:
    var spec := _route_spec(origin, destination)
    var danger := int(spec.get("danger", 1))
    var distance := int(spec.get("distance", 1))
    var pirate_exposure := _route_pirate_exposure(origin, destination)
    var difficulty := clampi(danger + int(round(pirate_exposure * 2.0)) + (1 if smuggling else 0), 1, 5)
    var base_reward := 0
    match kind:
        "delivery":
            base_reward = 160 + distance * 90 + difficulty * 70
        "passenger":
            base_reward = 220 + distance * 100 + difficulty * 80
        _:
            base_reward = 420 + distance * 150 + difficulty * 180
    var risk_factor := 0.35 if kind == "delivery" else (0.45 if kind == "passenger" else 0.70)
    var risk_premium := int(round(float(base_reward) * pirate_exposure * risk_factor))
    var cargo_premium := 0
    if kind == "delivery" and not commodity.is_empty():
        var market_opportunity := maxi(0, _market_sell_price(destination, commodity) - _market_buy_price(origin, commodity))
        cargo_premium += market_opportunity * 2
        if smuggling:
            cargo_premium += int(round(float(_commodity_base_price(commodity)) * 1.10 + float(base_reward) * 0.28))
    var origin_faction := _planet_primary_faction(origin)
    var destination_faction := _planet_primary_faction(destination)
    var political_premium := 0
    if kind == "passenger" and origin_faction != destination_faction:
        political_premium = int(round(float(base_reward) * 0.14))
    var reward := base_reward + risk_premium + cargo_premium + political_premium
    return {
        "difficulty": difficulty,
        "base_reward": base_reward,
        "risk_premium": risk_premium,
        "cargo_premium": cargo_premium,
        "political_premium": political_premium,
        "pirate_exposure": pirate_exposure,
        "reward": reward
    }

func _contract_role(kind: String, issuer_faction: String, destination: String, smuggling: bool = false) -> String:
    if smuggling:
        return "SMUGGLE"
    if kind == "bounty":
        return "PIRATE BOUNTY"
    if kind == "passenger":
        var destination_faction := _planet_primary_faction(destination)
        var destination_state := String(_get_political_context_at(_system_planet_world_position(destination)).get("state", "UNCONTROLLED"))
        if destination_state == "CONTESTED":
            return "FRONTIER PAX"
        if not issuer_faction.is_empty() and destination_faction != issuer_faction:
            return "ENVOY"
        return "PASSENGER"
    return "FREIGHT"

func _contract_relation_reward(kind: String, smuggling: bool = false) -> int:
    if smuggling:
        return 0
    match kind:
        "bounty":
            return 5
        "passenger":
            return 3
        _:
            return 2

func _make_contract(kind: String, origin: String, profile: Dictionary, commodity: String = "", smuggling: bool = false, issuer_override: String = "__AUTO__") -> Dictionary:
    var destination := String(profile.get("destination", ""))
    if destination.is_empty():
        return {}
    var issuer_faction := _planet_primary_faction(origin) if issuer_override == "__AUTO__" else issuer_override
    if smuggling:
        issuer_faction = ""
    var reward_data := _contract_reward_breakdown(kind, origin, destination, commodity, smuggling)
    return {
        "id": rng.randi(),
        "schema": CONTRACT_SCHEMA_VERSION,
        "type": kind,
        "origin": origin,
        "destination": destination,
        "difficulty": int(reward_data.difficulty),
        "reward": int(reward_data.reward),
        "base_reward": int(reward_data.base_reward),
        "risk_premium": int(reward_data.risk_premium),
        "cargo_premium": int(reward_data.cargo_premium),
        "political_premium": int(reward_data.political_premium),
        "pirate_exposure": float(reward_data.pirate_exposure),
        "issuer_faction": issuer_faction,
        "issuer_name": _contract_issuer_name(issuer_faction, smuggling),
        "relation_reward": _contract_relation_reward(kind, smuggling),
        "role": _contract_role(kind, issuer_faction, destination, smuggling),
        "commodity": commodity,
        "smuggling": smuggling
    }

func _upgrade_contract_record(contract: Dictionary, fallback_origin: String) -> Dictionary:
    var upgraded := contract.duplicate(true)
    var kind := String(upgraded.get("type", "delivery"))
    var origin := String(upgraded.get("origin", fallback_origin))
    var destination := String(upgraded.get("destination", ""))
    var smuggling := bool(upgraded.get("smuggling", false))
    var commodity := String(upgraded.get("commodity", "Food" if kind == "delivery" else ""))
    var issuer_faction := String(upgraded.get("issuer_faction", _planet_primary_faction(origin)))
    if smuggling:
        issuer_faction = ""
    upgraded["schema"] = CONTRACT_SCHEMA_VERSION
    upgraded["origin"] = origin
    upgraded["commodity"] = commodity
    upgraded["smuggling"] = smuggling
    upgraded["issuer_faction"] = issuer_faction
    upgraded["issuer_name"] = String(upgraded.get("issuer_name", _contract_issuer_name(issuer_faction, smuggling)))
    upgraded["relation_reward"] = int(upgraded.get("relation_reward", _contract_relation_reward(kind, smuggling)))
    upgraded["role"] = String(upgraded.get("role", _contract_role(kind, issuer_faction, destination, smuggling)))
    upgraded["pirate_exposure"] = float(upgraded.get("pirate_exposure", _route_pirate_exposure(origin, destination) if planet_names.has(destination) else 0.0))
    upgraded["base_reward"] = int(upgraded.get("base_reward", upgraded.get("reward", 0)))
    upgraded["risk_premium"] = int(upgraded.get("risk_premium", 0))
    upgraded["cargo_premium"] = int(upgraded.get("cargo_premium", 0))
    upgraded["political_premium"] = int(upgraded.get("political_premium", 0))
    return upgraded

func _ensure_contract_schema() -> bool:
    var changed := false
    for i in contract_board.size():
        var original: Dictionary = contract_board[i]
        var upgraded := _upgrade_contract_record(original, current_planet)
        if int(original.get("schema", 0)) < CONTRACT_SCHEMA_VERSION:
            changed = true
        contract_board[i] = upgraded
    if not active_contract.is_empty():
        var active_before := active_contract.duplicate(true)
        active_contract = _upgrade_contract_record(active_contract, current_planet)
        if int(active_before.get("schema", 0)) < CONTRACT_SCHEMA_VERSION:
            changed = true
    return changed

func _regenerate_contracts() -> void:
    contract_board.clear()
    var profiles := _contract_destination_profiles(current_planet)
    if profiles.is_empty():
        return
    var issuer_faction := _planet_primary_faction(current_planet)

    var legal_profile := _best_legal_delivery_profile(current_planet, profiles)
    if not legal_profile.is_empty():
        contract_board.append(_make_contract("delivery", current_planet, legal_profile, String(legal_profile.get("commodity", "Food")), false))

    var passenger_profile := _best_passenger_profile(profiles, issuer_faction)
    if not passenger_profile.is_empty():
        contract_board.append(_make_contract("passenger", current_planet, passenger_profile))

    for bounty_profile in _best_bounty_profiles(profiles, 2):
        contract_board.append(_make_contract("bounty", current_planet, bounty_profile))

    var smuggling_profile := _best_smuggling_profile(current_planet, profiles)
    if not smuggling_profile.is_empty():
        contract_board.append(_make_contract("delivery", current_planet, smuggling_profile, String(smuggling_profile.get("commodity", "Arms")), true))
    elif not legal_profile.is_empty():
        var alternate := _best_legal_delivery_profile(current_planet, profiles)
        if not alternate.is_empty():
            contract_board.append(_make_contract("delivery", current_planet, alternate, String(alternate.get("commodity", "Food")), false))

func _accept_contract(index: int) -> bool:
    if not active_contract.is_empty() or index < 0 or index >= contract_board.size():
        return false
    var contract: Dictionary = _upgrade_contract_record(contract_board[index], current_planet)
    var kind := String(contract.type)
    if kind == "delivery" and _cargo_used() >= _cargo_capacity():
        return false
    if kind == "passenger" and passengers >= _passenger_capacity():
        return false
    if kind == "bounty" and _valid_starting_weapon() == "none":
        return false
    active_contract = contract.duplicate(true)
    if kind == "passenger":
        passengers += 1
    contract_board.remove_at(index)
    _play_sfx(buy_sfx, 1.10)
    _save_all_state()
    return true

func _contract_target_matches(destination: String) -> bool:
    return not active_contract.is_empty() and String(active_contract.get("destination", "")) == destination

func _route_level_for(distance: int, danger: int, contract_difficulty: int = 0) -> int:
    return clampi(1 + danger + int(round(float(contract_difficulty) * 0.7)), 1, 10)

func _route_duration_for(distance: int, danger: int, contract_difficulty: int = 0) -> float:
    # Route length controls travel time. Political danger and contract pressure do not lengthen the lane.
    return clampf(14.0 + float(maxi(1, distance)) * 8.0, 18.0, 62.0)

func _start_route(destination: String) -> bool:
    if destination == current_planet or not planet_names.has(destination):
        return false
    var spec := _direct_route_spec(current_planet, destination)
    if spec.is_empty():
        return false
    var contract_difficulty := 0
    if _contract_target_matches(destination):
        contract_difficulty = int(active_contract.get("difficulty", 0))
    route_origin = current_planet
    destination_planet = destination
    route_distance = int(spec.distance)
    route_danger = int(spec.danger)
    route_wealth = clampi(int(spec.get("wealth", 1)), 1, 5)
    route_duration = _route_duration_for(route_distance, route_danger, contract_difficulty)
    _start_game()
    level = _route_level_for(route_distance, route_danger, contract_difficulty)
    route_active = true
    next_lane_event_at = _first_split_time()
    easy_spawn_clock = _route_object_spawn_interval(false, true)
    hard_spawn_clock = _route_object_spawn_interval(true, true)
    neutral_spawn_clock = _route_object_spawn_interval(false, false)
    hub_open = false
    market_open = false
    contracts_open = false
    travel_open = false
    boss_active = false
    boss_defeated_pending = false
    bounty_completed_this_route = false
    encounter_active = false
    encounter_mode = ""
    encounter_faction_id = ""
    encounter_hostile = false
    encounter_timer = 0.0
    encounter_clock = rng.randf_range(8.0, 13.0)
    encounter_banner_timer = 0.0
    police_scan_active = false
    police_scan_faction_id = ""
    police_scan_timer = 0.0
    police_scan_duration = 0.0
    police_scan_attempted = false
    police_scan_result_timer = 0.0
    police_scan_result_text = ""
    pirate_attack_active = false
    pirate_attack_timer = 0.0
    pirate_attack_clock = encounter_clock
    pirate_banner_timer = 0.0
    result_reason = ""
    _save_all_state()
    return true

func _encounter_eligibility_for_context(context: Dictionary) -> Dictionary:
    var state := String(context.get("state", "UNCONTROLLED"))
    if state == "UNCONTROLLED" or state == "CONTESTED":
        return {
            "eligible": true,
            "mode": "pirate",
            "faction_id": "",
            "hostile": true,
            "heavy": false,
            "state": state
        }

    if state == "CORE" or state == "CONTROLLED":
        var faction_id := String(context.get("faction_id", ""))
        if faction_id.is_empty():
            faction_id = String(context.get("strongest_faction_id", ""))
        if not faction_id.is_empty():
            var hostile := _police_hostile_eligible(faction_id)
            return {
                "eligible": true,
                "mode": "police",
                "faction_id": faction_id,
                "hostile": hostile,
                "heavy": hostile and _heavy_enforcement_eligible(faction_id),
                "state": state
            }

    return {
        "eligible": false,
        "mode": "",
        "faction_id": "",
        "hostile": false,
        "heavy": false,
        "state": state
    }


func _current_encounter_eligibility() -> Dictionary:
    return _encounter_eligibility_for_context(_current_flight_political_context())

func _route_wealth_encounter_multiplier() -> float:
    return lerpf(ENCOUNTER_WEALTH_MULT_MIN, ENCOUNTER_WEALTH_MULT_MAX, float(clampi(route_wealth, 1, 5) - 1) / 4.0)

func _encounter_roll_chance(eligibility: Dictionary) -> float:
    var mode := String(eligibility.get("mode", ""))
    var wealth_multiplier := _route_wealth_encounter_multiplier()
    if mode == "pirate":
        var base := PIRATE_UNCONTROLLED_BASE_CHANCE if String(eligibility.get("state", "UNCONTROLLED")) == "UNCONTROLLED" else PIRATE_CONTESTED_BASE_CHANCE
        return clampf(base * wealth_multiplier, 0.0, 0.90)
    if mode == "police":
        var faction_id := String(eligibility.get("faction_id", ""))
        # Police occurrence is faction level + route wealth + RNG. Danger, contract pressure, and heat are excluded.
        var base := POLICE_ENCOUNTER_BASE_CHANCE + float(_faction_level(faction_id)) * POLICE_ENCOUNTER_LEVEL_STEP
        return clampf(base * wealth_multiplier, 0.0, 0.90)
    return 0.0

func _encounter_opportunity_interval(eligibility: Dictionary) -> float:
    var mode := String(eligibility.get("mode", ""))
    if mode == "police":
        return rng.randf_range(POLICE_OPPORTUNITY_MIN, POLICE_OPPORTUNITY_MAX)
    if mode == "pirate":
        return rng.randf_range(PIRATE_OPPORTUNITY_MIN, PIRATE_OPPORTUNITY_MAX)
    return 999.0

func _encounter_cooldown(eligibility: Dictionary) -> float:
    return _encounter_opportunity_interval(eligibility)

func _try_start_route_encounter(eligibility: Dictionary, roll: float = -1.0) -> bool:
    if not bool(eligibility.get("eligible", false)):
        return false
    var use_roll := rng.randf() if roll < 0.0 else roll
    if use_roll < _encounter_roll_chance(eligibility):
        return _start_route_encounter(eligibility)
    encounter_clock = _encounter_opportunity_interval(eligibility)
    _sync_legacy_pirate_state()
    return false

func _police_scan_chance(faction_id: String) -> float:
    return clampf(POLICE_SCAN_BASE_CHANCE + float(_faction_level(faction_id)) * POLICE_SCAN_LEVEL_STEP, 0.0, 0.95)

func _police_scan_duration_for_faction(faction_id: String) -> float:
    return clampf(6.2 - float(_faction_level(faction_id)) * 0.4, 4.2, 5.8)

func _illegal_cargo_for_faction(faction_id: String) -> Dictionary:
    var illegal: Dictionary = {}
    for commodity in PoliticalWorld.RESTRICTED_COMMODITIES:
        var quantity := int(cargo.get(commodity, 0))
        if quantity > 0 and not PoliticalWorld.faction_commodity_legal(political_world, faction_id, commodity):
            illegal[commodity] = quantity
    return illegal

func _active_delivery_contraband_for_faction(faction_id: String) -> String:
    if active_contract.is_empty() or String(active_contract.get("type", "")) != "delivery":
        return ""
    var commodity := String(active_contract.get("commodity", ""))
    if not PoliticalWorld.RESTRICTED_COMMODITIES.has(commodity):
        return ""
    if PoliticalWorld.faction_commodity_legal(political_world, faction_id, commodity):
        return ""
    return commodity

func _begin_police_scan(faction_id: String, duration_override: float = -1.0) -> bool:
    if faction_id.is_empty() or encounter_mode != "police" or encounter_hostile:
        return false
    police_scan_active = true
    police_scan_attempted = true
    police_scan_faction_id = faction_id
    police_scan_duration = duration_override if duration_override > 0.0 else _police_scan_duration_for_faction(faction_id)
    police_scan_timer = police_scan_duration
    police_scan_result_timer = 0.0
    police_scan_result_text = ""
    encounter_timer = maxf(encounter_timer, police_scan_duration + 1.0)
    weapon_banner_text = "CARGO SCAN"
    weapon_banner_timer = 1.2
    return true

func _maybe_begin_police_scan(roll: float = -1.0) -> bool:
    if encounter_mode != "police" or encounter_hostile or police_scan_attempted or encounter_faction_id.is_empty():
        return false
    police_scan_attempted = true
    var use_roll := rng.randf() if roll < 0.0 else roll
    if use_roll < _police_scan_chance(encounter_faction_id):
        return _begin_police_scan(encounter_faction_id)
    return false

func _cancel_police_scan(reason: String = "") -> void:
    if police_scan_active and not reason.is_empty():
        police_scan_result_text = reason
        police_scan_result_timer = 1.2
    police_scan_active = false
    police_scan_faction_id = ""
    police_scan_timer = 0.0
    police_scan_duration = 0.0

func _complete_police_scan() -> Dictionary:
    if not police_scan_active or police_scan_faction_id.is_empty():
        return {}
    var faction_id := police_scan_faction_id
    var illegal := _illegal_cargo_for_faction(faction_id)
    var contract_contraband := _active_delivery_contraband_for_faction(faction_id)
    police_scan_active = false
    police_scan_timer = 0.0

    if illegal.is_empty() and contract_contraband.is_empty():
        police_scan_result_text = "SCAN CLEAR"
        police_scan_result_timer = 2.0
        police_scan_faction_id = ""
        return {"clear": true, "units": 0, "fine": 0, "contract_confiscated": false}

    var total_units := 0
    var total_value := 0
    for commodity in illegal.keys():
        var quantity := int(illegal[commodity])
        total_units += quantity
        total_value += quantity * _commodity_base_price(String(commodity))
        cargo[commodity] = maxi(0, int(cargo.get(commodity, 0)) - quantity)

    var contract_confiscated := not contract_contraband.is_empty()
    if contract_confiscated:
        total_units += 1
        total_value += _commodity_base_price(contract_contraband)
        active_contract.clear()
        loot_banner_text = "CONTRACT CARGO CONFISCATED"
        loot_banner_timer = 2.4

    var fine := POLICE_SCAN_FINE_BASE + int(round(float(total_value) * POLICE_SCAN_FINE_VALUE_FACTOR))
    var paid := mini(research_credits, fine)
    research_credits -= paid
    var relation_loss := mini(20, POLICE_SCAN_RELATION_BASE_LOSS + total_units * 2)
    var heat_gain := mini(50, POLICE_SCAN_HEAT_BASE_GAIN + maxi(0, total_units - 1) * 3)
    _record_faction_crime(faction_id, relation_loss, heat_gain, "contraband_scan", false)
    encounter_hostile = _police_hostile_eligible(faction_id)
    police_scan_result_text = "CONTRABAND %d  FINE %d" % [total_units, paid]
    police_scan_result_timer = 2.5
    police_scan_faction_id = ""
    weapon_banner_text = "CONTRABAND FOUND"
    weapon_banner_timer = 1.8
    _save_privateer_state()
    return {"clear": false, "units": total_units, "fine": paid, "contract_confiscated": contract_confiscated}

func _update_police_scan(delta: float) -> void:
    police_scan_result_timer = maxf(0.0, police_scan_result_timer - delta)
    if not police_scan_active:
        return
    if not encounter_active or encounter_mode != "police" or encounter_hostile or encounter_faction_id != police_scan_faction_id:
        _cancel_police_scan()
        return
    police_scan_timer = maxf(0.0, police_scan_timer - delta)
    if police_scan_timer <= 0.0:
        _complete_police_scan()


func _encounter_duration(eligibility: Dictionary) -> float:
    var mode := String(eligibility.get("mode", ""))
    if mode == "police":
        var faction_id := String(eligibility.get("faction_id", ""))
        return 4.0 + float(_faction_heat(faction_id)) * 0.025
    return 4.2 + float(route_danger) * 0.65

func _sync_legacy_pirate_state() -> void:
    pirate_attack_active = encounter_active and encounter_mode == "pirate"
    pirate_attack_timer = encounter_timer if pirate_attack_active else 0.0
    pirate_attack_clock = encounter_clock
    pirate_banner_timer = encounter_banner_timer if pirate_attack_active else 0.0

func _end_route_encounter(eligibility: Dictionary = {}) -> void:
    _cancel_police_scan()
    police_scan_attempted = false
    encounter_active = false
    encounter_mode = ""
    encounter_faction_id = ""
    encounter_hostile = false
    encounter_timer = 0.0
    encounter_clock = _encounter_cooldown(eligibility) if bool(eligibility.get("eligible", false)) else 999.0
    _sync_legacy_pirate_state()

func _start_route_encounter(eligibility: Dictionary) -> bool:
    if not bool(eligibility.get("eligible", false)):
        return false
    encounter_active = true
    encounter_mode = String(eligibility.get("mode", ""))
    encounter_faction_id = String(eligibility.get("faction_id", ""))
    encounter_hostile = bool(eligibility.get("hostile", encounter_mode == "pirate"))
    encounter_timer = _encounter_duration(eligibility)
    encounter_banner_timer = 1.8

    if encounter_mode == "police":
        var faction := PoliticalWorld.faction_record(political_world, encounter_faction_id)
        var suffix := "ENFORCEMENT" if encounter_hostile else "PATROL"
        weapon_banner_text = "%s %s" % [String(faction.get("name", "FACTION")).to_upper(), suffix]
    else:
        weapon_banner_text = "PIRATE CONTACT"
    weapon_banner_timer = 1.8
    police_scan_attempted = false
    _sync_legacy_pirate_state()
    if encounter_mode == "police" and not encounter_hostile:
        _maybe_begin_police_scan()
    return true

func _update_route_encounter(delta: float) -> void:
    encounter_banner_timer = maxf(0.0, encounter_banner_timer - delta)

    if not route_active or boss_active:
        _end_route_encounter()
        return

    var eligibility := _current_encounter_eligibility()
    if encounter_active:
        var same_mode := String(eligibility.get("mode", "")) == encounter_mode
        var same_faction := encounter_mode != "police" or String(eligibility.get("faction_id", "")) == encounter_faction_id
        if not bool(eligibility.get("eligible", false)) or not same_mode or not same_faction:
            _end_route_encounter(eligibility)
            return
        var was_hostile := encounter_hostile
        encounter_hostile = bool(eligibility.get("hostile", encounter_mode == "pirate"))
        if encounter_mode == "police" and encounter_hostile and not was_hostile:
            _cancel_police_scan()
            var faction := PoliticalWorld.faction_record(political_world, encounter_faction_id)
            weapon_banner_text = "%s ENFORCEMENT" % String(faction.get("name", "FACTION")).to_upper()
            weapon_banner_timer = 1.8
        _update_police_scan(delta)
        encounter_timer = maxf(0.0, encounter_timer - delta)
        if encounter_timer <= 0.0:
            _end_route_encounter(eligibility)
        else:
            _sync_legacy_pirate_state()
        return

    if not bool(eligibility.get("eligible", false)):
        encounter_clock = 999.0
        _sync_legacy_pirate_state()
        return

    if encounter_clock >= 900.0:
        encounter_clock = _encounter_cooldown(eligibility)
    encounter_clock -= delta
    if encounter_clock <= 0.0:
        _try_start_route_encounter(eligibility)
    else:
        _sync_legacy_pirate_state()

# Compatibility entry point for older tests/callers.
func _update_pirate_attack(delta: float) -> void:
    _update_route_encounter(delta)


func _begin_bounty_boss() -> void:
    if boss_active:
        return
    boss_active = true
    _end_route_encounter()
    lane_event_active = false
    lane_event_timer = 0.0
    station_locked_side = ""
    objects.clear()
    enemy_shots.clear()
    var difficulty := int(active_contract.get("difficulty", 1))
    var boss_hp := 34.0 + float(difficulty) * 18.0
    objects.append({
        "id": rng.randi(),
        "type": "hazard",
        "kind": 4,
        "boss": true,
        "hp": boss_hp,
        "max_hp": boss_hp,
        "hard": false,
        "x": W * 0.5,
        "y": 150.0,
        "r": 30.0,
        "speed": 0.0,
        "drift": 0.0,
        "shoot_clock": maxf(0.45, 1.25 - float(difficulty) * 0.10),
        "lane_speed_mult": 1.0,
        "lane_min": LEFT,
        "lane_max": RIGHT
    })
    weapon_banner_text = "BOUNTY TARGET"
    weapon_banner_timer = 2.4
    shake = 4.0

func _handle_route_end() -> void:
    if not route_active:
        return
    var bounty_due := _contract_target_matches(destination_planet) and String(active_contract.get("type", "")) == "bounty"
    if bounty_due and not bounty_completed_this_route:
        _begin_bounty_boss()
        return
    _arrive_at_destination()

func _complete_contract_if_ready() -> int:
    if active_contract.is_empty() or String(active_contract.get("destination", "")) != current_planet:
        return 0
    if String(active_contract.get("type", "")) == "bounty" and not bounty_completed_this_route:
        return 0
    var completed := _upgrade_contract_record(active_contract, current_planet)
    var reward := int(completed.get("reward", 0))
    var kind := String(completed.get("type", ""))
    if kind == "passenger":
        passengers = maxi(0, passengers - 1)
    elif kind == "delivery":
        var commodity := String(completed.get("commodity", ""))
        if not commodity.is_empty() and markets.has(current_planet) and markets[current_planet].has(commodity):
            var data: Dictionary = markets[current_planet][commodity]
            data.stock = minf(140.0, float(data.stock) + 1.0)
            markets[current_planet][commodity] = data
    var issuer_faction := String(completed.get("issuer_faction", ""))
    var relation_reward := int(completed.get("relation_reward", 0))
    if not issuer_faction.is_empty() and relation_reward > 0:
        _adjust_faction_relation(issuer_faction, relation_reward, false)
    active_contract.clear()
    return reward

func _arrive_at_destination() -> void:
    _cancel_police_scan("SCAN ENDED — ARRIVAL")
    playing = false
    route_active = false
    boss_active = false
    boss_defeated_pending = false
    current_planet = destination_planet
    destination_planet = ""
    var flight_bonus := maxi(0, score)
    research_credits += flight_bonus
    score = 0
    var contract_reward := _complete_contract_if_ready()
    research_credits += contract_reward
    _simulate_economy(route_distance + route_danger)
    _regenerate_contracts()
    last_trip_summary = "ARRIVED %s  +%d CR" % [_planet_display_name(current_planet), flight_bonus + contract_reward]
    hub_open = true
    market_open = false
    contracts_open = false
    travel_open = false
    game_over = false
    run_paused = false
    objects.clear()
    shots.clear()
    enemy_shots.clear()
    pending_drops.clear()
    _play_sfx(level_clear_sfx)
    _clear_run_snapshot()
    _save_all_state()
    queue_redraw()

func _fail_route(reason: String) -> void:
    _cancel_police_scan()
    playing = false
    route_active = false
    boss_active = false
    boss_defeated_pending = false
    destination_planet = ""
    score = 0
    if not active_contract.is_empty():
        if String(active_contract.get("type", "")) == "passenger":
            passengers = maxi(0, passengers - 1)
        active_contract.clear()
    last_trip_summary = reason + " — CONTRACT LOST"
    hub_open = true
    market_open = false
    contracts_open = false
    travel_open = false
    game_over = false
    run_paused = false
    objects.clear()
    shots.clear()
    enemy_shots.clear()
    pending_drops.clear()
    _play_sfx(death_sfx)
    _clear_run_snapshot()
    _save_all_state()
    queue_redraw()

func _save_privateer_state() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("political", "schema", POLITICAL_WORLD_SCHEMA)
    cfg.set_value("political", "world", political_world)
    cfg.set_value("world", "economy_schema", ECONOMY_SCHEMA_VERSION)
    cfg.set_value("world", "crime_schema", CRIME_SCHEMA_VERSION)
    cfg.set_value("world", "enforcement_schema", ENFORCEMENT_SCHEMA_VERSION)
    cfg.set_value("world", "contract_schema", CONTRACT_SCHEMA_VERSION)
    cfg.set_value("world", "planet", current_planet)
    cfg.set_value("world", "markets", markets)
    cfg.set_value("world", "cargo", cargo)
    cfg.set_value("world", "contracts", contract_board)
    cfg.set_value("world", "active_contract", active_contract)
    cfg.set_value("world", "passengers", passengers)
    cfg.set_value("world", "economy_tick", economy_tick)
    cfg.set_value("world", "summary", last_trip_summary)
    var path := _active_world_path()
    if path.is_empty():
        return
    cfg.save(path)


func _load_privateer_state() -> void:
    var cfg := ConfigFile.new()
    var path := _active_world_path()
    if path.is_empty() or cfg.load(path) != OK:
        return

    var saved_schema := int(cfg.get_value("political", "schema", 0))
    var saved_world = cfg.get_value("political", "world", {})
    var saved_planet := String(cfg.get_value("world", "planet", "Aster"))
    var saved_markets: Dictionary = cfg.get_value("world", "markets", {})
    var migrated_world := false

    if saved_schema >= POLITICAL_WORLD_SCHEMA and saved_world is Dictionary and not saved_world.is_empty():
        political_world = saved_world
        world_seed = int(political_world.get("seed", 1))
        _sync_generated_planets()
        current_planet = saved_planet
        if not planet_names.has(current_planet):
            current_planet = planet_names[0]
        markets = saved_markets
    else:
        # One-time migration from the fixed four-world career model.
        world_seed = int(rng.randi())
        if world_seed == 0:
            world_seed = 1
        _generate_political_world(world_seed)
        current_planet = PoliticalWorld.find_planet_by_type(
            political_world,
            PoliticalWorld.legacy_type_for_name(saved_planet)
        )
        markets.clear()
        _init_privateer_world()
        for old_name in ["Aster", "Cinder", "Vesper", "Helix"]:
            if saved_markets.has(old_name):
                var mapped_id := PoliticalWorld.find_planet_by_type(
                    political_world,
                    PoliticalWorld.legacy_type_for_name(old_name)
                )
                markets[mapped_id] = saved_markets[old_name]
        migrated_world = true

    var crime_schema_changed: bool = _ensure_crime_schema()
    var enforcement_schema_changed: bool = _ensure_enforcement_schema()
    var route_wealth_schema_changed: bool = _ensure_route_wealth_schema()
    cargo = cfg.get_value("world", "cargo", cargo)
    var commodity_schema_changed: bool = _ensure_commodity_schema()
    contract_board.clear()
    for contract in cfg.get_value("world", "contracts", []):
        var migrated: Dictionary = contract.duplicate(true)
        var old_dest := String(migrated.get("destination", ""))
        if ["Aster", "Cinder", "Vesper", "Helix"].has(old_dest):
            migrated.destination = PoliticalWorld.find_planet_by_type(
                political_world,
                PoliticalWorld.legacy_type_for_name(old_dest)
            )
        contract_board.append(migrated)
    active_contract = cfg.get_value("world", "active_contract", {})
    if not active_contract.is_empty():
        var old_active_dest := String(active_contract.get("destination", ""))
        if ["Aster", "Cinder", "Vesper", "Helix"].has(old_active_dest):
            active_contract.destination = PoliticalWorld.find_planet_by_type(
                political_world,
                PoliticalWorld.legacy_type_for_name(old_active_dest)
            )
    var contract_schema_changed := _ensure_contract_schema()
    passengers = int(cfg.get_value("world", "passengers", 0))
    economy_tick = int(cfg.get_value("world", "economy_tick", 0))
    last_trip_summary = String(cfg.get_value("world", "summary", "Docked at %s" % _planet_display_name(current_planet)))
    if markets.is_empty():
        _init_privateer_world()
    if contract_board.is_empty():
        _regenerate_contracts()
    if migrated_world:
        last_trip_summary = "Migrated to %s" % _planet_display_name(current_planet)
    if migrated_world or crime_schema_changed or enforcement_schema_changed or route_wealth_schema_changed or commodity_schema_changed or contract_schema_changed or int(cfg.get_value("world", "economy_schema", 0)) < ECONOMY_SCHEMA_VERSION or int(cfg.get_value("world", "crime_schema", 0)) < CRIME_SCHEMA_VERSION or int(cfg.get_value("world", "enforcement_schema", 0)) < ENFORCEMENT_SCHEMA_VERSION or int(cfg.get_value("world", "contract_schema", 0)) < CONTRACT_SCHEMA_VERSION:
        _save_privateer_state()


func _save_all_state() -> void:
    _save_meta()
    _save_privateer_state()

func _process(delta: float) -> void:
    if run_paused or not playing:
        queue_redraw()
        return

    near_miss_timer = maxf(0.0, near_miss_timer - delta)
    weapon_banner_timer = maxf(0.0, weapon_banner_timer - delta)
    loot_banner_timer = maxf(0.0, loot_banner_timer - delta)
    lane_choice_banner_timer = maxf(0.0, lane_choice_banner_timer - delta)
    finale_banner_timer = maxf(0.0, finale_banner_timer - delta)
    flash = maxf(0.0, flash - delta)
    cyan_flash = maxf(0.0, cyan_flash - delta)
    shake = maxf(0.0, shake - delta * 28.0)
    dash_cooldown = maxf(0.0, dash_cooldown - delta)
    dash_score_timer = maxf(0.0, dash_score_timer - delta)
    slowmo_timer = maxf(0.0, slowmo_timer - delta)
    laser_sfx_clock = maxf(0.0, laser_sfx_clock - delta)

    var game_delta := delta * (0.52 if slowmo_timer > 0.0 else 1.0)
    var world_delta := game_delta * _ship_speed_multiplier()
    elapsed += world_delta
    world_scroll += world_delta * 170.0
    invuln = maxf(0.0, invuln - game_delta)

    if left_control_held and not right_control_held:
        target_x -= CONTROL_TARGET_SPEED * game_delta
    elif right_control_held and not left_control_held:
        target_x += CONTROL_TARGET_SPEED * game_delta

    player_x = lerpf(player_x, target_x, minf(1.0, game_delta * 13.0))
    player_x = clampf(player_x, LEFT, RIGHT)
    target_x = clampf(target_x, LEFT, RIGHT)

    if dash_timer > 0.0:
        dash_timer = maxf(0.0, dash_timer - game_delta)
        player_y = maxf(PLAYER_Y - _dash_distance(), player_y - _dash_speed() * game_delta)
    else:
        player_y = lerpf(player_y, PLAYER_Y, minf(1.0, game_delta * DASH_RETURN_RATE))

    easy_spawn_clock -= world_delta
    hard_spawn_clock -= world_delta
    neutral_spawn_clock -= world_delta
    pickup_clock -= world_delta
    fire_clock -= game_delta
    repair_clock -= game_delta
    var difficulty := _level_difficulty()
    _update_route_encounter(world_delta)

    if current_weapon == "laser":
        _apply_laser_damage(game_delta)
    elif current_weapon != "none" and fire_clock <= 0.0:
        _fire_weapon()
        fire_clock = _weapon_interval()

    if repair_clock <= 0.0:
        if hp < max_hp and rng.randf() < FIELD_REPAIR_CHANCE:
            _spawn_repair()
        repair_clock = rng.randf_range(REPAIR_INTERVAL_MIN, REPAIR_INTERVAL_MAX) if hp < max_hp else REPAIR_RETRY_FULL

    if boss_active:
        _move_shots(game_delta)
        _move_objects(world_delta)
        _move_enemy_shots(game_delta)
        _move_particles(delta)
        if boss_defeated_pending:
            bounty_completed_this_route = true
            boss_defeated_pending = false
            _arrive_at_destination()
        queue_redraw()
        return

    if lane_event_active:
        station_top += STATION_SPEED * world_delta
        lane_event_timer = maxf(0.0, lane_event_timer - world_delta)
        _check_station_collision()
        if not playing:
            queue_redraw()
            return
        if easy_spawn_clock <= 0.0:
            _spawn_hazard(difficulty, false, true)
            easy_spawn_clock = _route_object_spawn_interval(false, true) if route_active else (rng.randf_range(1.55, 1.95) if level == 1 else _spawn_interval(1.05, 0.52, difficulty) * rng.randf_range(0.88, 1.18))
        if hard_spawn_clock <= 0.0:
            if route_active:
                _spawn_hazard(difficulty, true, true)
                hard_spawn_clock = _route_object_spawn_interval(true, true)
            elif level == 1:
                _spawn_circle_bunch(true, rng.randi_range(2, 3))
                hard_spawn_clock = rng.randf_range(1.65, 2.15)
            else:
                _spawn_hazard(difficulty, true, true)
                hard_spawn_clock = _spawn_interval(0.82, 0.34, difficulty) * rng.randf_range(0.84, 1.14)
        if station_top > H + 40.0:
            _end_lane_event()
    else:
        if neutral_spawn_clock <= 0.0:
            _spawn_hazard(difficulty, false, false)
            neutral_spawn_clock = _route_object_spawn_interval(false, false) if route_active else (rng.randf_range(1.65, 2.20) if level == 1 else _spawn_interval(1.10, 0.43, difficulty) * rng.randf_range(0.86, 1.18))
        if lane_events_started < _split_count_for_level() and elapsed >= next_lane_event_at and elapsed < _level_duration() - 3.0:
            _begin_lane_event()

    if pickup_clock <= 0.0:
        _spawn_pickup()
        pickup_clock = _energy_spawn_interval()

    _move_shots(game_delta)
    _move_objects(world_delta)
    _move_enemy_shots(game_delta)
    _move_particles(delta)

    if elapsed >= _level_duration() and playing:
        if route_active:
            _handle_route_end()
        else:
            _open_shop()
        queue_redraw()
        return
    queue_redraw()

func _input(event: InputEvent) -> void:
    if travel_open:
        if event is InputEventScreenTouch:
            if event.pressed:
                _system_map_touch_begin(event.index, event.position)
            else:
                _system_map_touch_end(event.index, event.position)
            return
        if event is InputEventScreenDrag:
            _system_map_touch_drag(event.index, event.position, event.relative)
            return
        if event is InputEventMouseButton:
            if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed and SYSTEM_MAP_RECT.has_point(event.position):
                _zoom_system_map(1.16, event.position)
                return
            if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed and SYSTEM_MAP_RECT.has_point(event.position):
                _zoom_system_map(1.0 / 1.16, event.position)
                return
            if event.button_index == MOUSE_BUTTON_LEFT:
                if event.pressed:
                    if SYSTEM_MAP_RECT.has_point(event.position):
                        system_map_mouse_dragging = true
                        system_map_mouse_moved = false
                        system_map_mouse_last = event.position
                    else:
                        _handle_travel_tap(event.position)
                else:
                    if system_map_mouse_dragging and not system_map_mouse_moved:
                        _handle_travel_tap(event.position)
                    system_map_mouse_dragging = false
                return
        if event is InputEventMouseMotion and system_map_mouse_dragging:
            if event.relative.length() > 0.75:
                system_map_mouse_moved = true
            _pan_system_map(event.relative)
            system_map_mouse_last = event.position
            return

    if event is InputEventScreenTouch:
        if event.pressed:
            _handle_tap(event.position, event.index)
        else:
            _release_control_touch(event.index)
        return

    if event is InputEventScreenDrag:
        return

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _handle_tap(event.position, -1)
        else:
            _release_control_touch(-1)
        return

func _hub_button_rect(index: int) -> Rect2:
    match index:
        0: return HUB_TRAVEL_RECT
        1: return HUB_MARKET_RECT
        2: return HUB_CONTRACTS_RECT
        3: return HUB_UPGRADES_RECT
    return Rect2()

func _career_slot_rect(index: int) -> Rect2:
    return Rect2(32.0, 178.0 + float(index) * 144.0, 326.0, 112.0)

func _handle_profile_tap(pos: Vector2) -> void:
    if PROFILE_CONTINUE_RECT.has_point(pos):
        _continue_career()
        return
    if PROFILE_NEW_RECT.has_point(pos):
        profile_menu_open = false
        career_slots_open = true
        career_new_mode = true
        pending_overwrite_slot = 0
        queue_redraw()
        return
    if PROFILE_LOAD_RECT.has_point(pos):
        profile_menu_open = false
        career_slots_open = true
        career_new_mode = false
        pending_overwrite_slot = 0
        queue_redraw()
        return
    if active_career_slot > 0 and PROFILE_SLOT_BACK_RECT.has_point(pos):
        profile_menu_open = false
        hub_open = true
        queue_redraw()

func _handle_career_slots_tap(pos: Vector2) -> void:
    if PROFILE_SLOT_BACK_RECT.has_point(pos):
        career_slots_open = false
        profile_menu_open = true
        pending_overwrite_slot = 0
        queue_redraw()
        return
    for i in CAREER_SLOT_COUNT:
        var slot := i + 1
        if not _career_slot_rect(i).has_point(pos):
            continue
        if career_new_mode:
            if _career_slot_exists(slot) and pending_overwrite_slot != slot:
                pending_overwrite_slot = slot
                queue_redraw()
                return
            _create_new_career(slot)
            return
        if _career_slot_exists(slot):
            _load_career(slot)
            return

func _system_world_bounds() -> Rect2:
    return Rect2(political_world.get("bounds", PoliticalWorld.WORLD_BOUNDS))

func _political_context_key(context: Dictionary) -> String:
    var state := String(context.get("state", "UNCONTROLLED"))
    if state == "CONTESTED":
        var ids: Array[String] = [
            String(context.get("strongest_faction_id", "")),
            String(context.get("second_faction_id", ""))
        ]
        ids.sort()
        return "%s|%s|%s" % [state, ids[0], ids[1]]
    var faction_id := String(context.get("faction_id", context.get("strongest_faction_id", "")))
    return "%s|%s" % [state, faction_id]

func _rebuild_political_map_overlay() -> void:
    political_map_overlay_cells.clear()
    if political_world.is_empty():
        return
    var bounds := _system_world_bounds()
    var cell_size := Vector2(
        bounds.size.x / float(POLITICAL_MAP_GRID_X),
        bounds.size.y / float(POLITICAL_MAP_GRID_Y)
    )
    for gy in range(POLITICAL_MAP_GRID_Y):
        for gx in range(POLITICAL_MAP_GRID_X):
            var cell_pos := bounds.position + Vector2(float(gx) * cell_size.x, float(gy) * cell_size.y)
            var center := cell_pos + cell_size * 0.5
            var context := _get_political_context_at(center)
            political_map_overlay_cells.append({
                "gx": gx,
                "gy": gy,
                "rect": Rect2(cell_pos, cell_size),
                "center": center,
                "state": String(context.get("state", "UNCONTROLLED")),
                "faction_id": String(context.get("faction_id", "")),
                "strongest_faction_id": String(context.get("strongest_faction_id", "")),
                "second_faction_id": String(context.get("second_faction_id", "")),
                "key": _political_context_key(context)
            })

func _political_overlay_fill_color(cell: Dictionary) -> Color:
    var state := String(cell.get("state", "UNCONTROLLED"))
    if state == "CORE":
        var core := _faction_color(String(cell.get("faction_id", cell.get("strongest_faction_id", ""))))
        return Color(core.r, core.g, core.b, 0.15)
    if state == "CONTROLLED":
        var controlled := _faction_color(String(cell.get("faction_id", cell.get("strongest_faction_id", ""))))
        return Color(controlled.r, controlled.g, controlled.b, 0.085)
    if state == "CONTESTED":
        var first := _faction_color(String(cell.get("strongest_faction_id", "")))
        var second := _faction_color(String(cell.get("second_faction_id", "")))
        var mixed := first.lerp(second, 0.5).lerp(Color("ff6687"), 0.35)
        return Color(mixed.r, mixed.g, mixed.b, 0.16)
    return Color(0.025, 0.040, 0.070, 0.42)

func _political_border_color(first: Dictionary, second: Dictionary) -> Color:
    var first_state := String(first.get("state", "UNCONTROLLED"))
    var second_state := String(second.get("state", "UNCONTROLLED"))
    if first_state == "CONTESTED" or second_state == "CONTESTED":
        return Color(1.0, 0.40, 0.56, 0.52)
    if first_state == "UNCONTROLLED" or second_state == "UNCONTROLLED":
        return Color(0.62, 0.70, 0.78, 0.34)
    var faction_id := String(first.get("faction_id", first.get("strongest_faction_id", "")))
    var fc := _faction_color(faction_id)
    return Color(fc.r, fc.g, fc.b, 0.44)

func _draw_clipped_political_border(a: Vector2, b: Vector2, color: Color) -> void:
    if absf(a.x - b.x) < 0.01:
        var x := a.x
        if x < SYSTEM_MAP_RECT.position.x or x > SYSTEM_MAP_RECT.end.x:
            return
        var y0 := clampf(minf(a.y, b.y), SYSTEM_MAP_RECT.position.y, SYSTEM_MAP_RECT.end.y)
        var y1 := clampf(maxf(a.y, b.y), SYSTEM_MAP_RECT.position.y, SYSTEM_MAP_RECT.end.y)
        if y1 - y0 > 0.5:
            draw_line(Vector2(x, y0), Vector2(x, y1), color, 1.15, true)
        return
    var y := a.y
    if y < SYSTEM_MAP_RECT.position.y or y > SYSTEM_MAP_RECT.end.y:
        return
    var x0 := clampf(minf(a.x, b.x), SYSTEM_MAP_RECT.position.x, SYSTEM_MAP_RECT.end.x)
    var x1 := clampf(maxf(a.x, b.x), SYSTEM_MAP_RECT.position.x, SYSTEM_MAP_RECT.end.x)
    if x1 - x0 > 0.5:
        draw_line(Vector2(x0, y), Vector2(x1, y), color, 1.15, true)

func _draw_political_map_overlay() -> void:
    if political_map_overlay_cells.size() != POLITICAL_MAP_GRID_X * POLITICAL_MAP_GRID_Y:
        _rebuild_political_map_overlay()
    for cell_variant in political_map_overlay_cells:
        var cell: Dictionary = cell_variant
        var world_rect: Rect2 = Rect2(cell.get("rect", Rect2()))
        var screen_start := _map_world_to_screen(world_rect.position)
        var screen_end := _map_world_to_screen(world_rect.end)
        var screen_rect := Rect2(screen_start, screen_end - screen_start)
        var clipped := screen_rect.intersection(SYSTEM_MAP_RECT)
        if clipped.size.x <= 0.0 or clipped.size.y <= 0.0:
            continue
        draw_rect(clipped, _political_overlay_fill_color(cell), true)
        if String(cell.get("state", "")) == "CONTESTED" and clipped.size.x > 5.0 and clipped.size.y > 5.0:
            draw_line(clipped.position, clipped.end, Color(1.0, 0.42, 0.58, 0.11), 0.8, true)

    for index in range(political_map_overlay_cells.size()):
        var cell: Dictionary = political_map_overlay_cells[index]
        var gx := int(cell.get("gx", 0))
        var gy := int(cell.get("gy", 0))
        var world_rect: Rect2 = Rect2(cell.get("rect", Rect2()))
        if gx < POLITICAL_MAP_GRID_X - 1:
            var right: Dictionary = political_map_overlay_cells[index + 1]
            if String(cell.get("key", "")) != String(right.get("key", "")):
                _draw_clipped_political_border(
                    _map_world_to_screen(Vector2(world_rect.end.x, world_rect.position.y)),
                    _map_world_to_screen(world_rect.end),
                    _political_border_color(cell, right)
                )
        if gy < POLITICAL_MAP_GRID_Y - 1:
            var below: Dictionary = political_map_overlay_cells[index + POLITICAL_MAP_GRID_X]
            if String(cell.get("key", "")) != String(below.get("key", "")):
                _draw_clipped_political_border(
                    _map_world_to_screen(Vector2(world_rect.position.x, world_rect.end.y)),
                    _map_world_to_screen(world_rect.end),
                    _political_border_color(cell, below)
                )

func _political_map_legend_entries() -> Array:
    var entries: Array = []
    for faction in political_world.get("factions", []):
        entries.append({
            "id": String(faction.get("id", "")),
            "name": String(faction.get("name", "UNKNOWN")),
            "color": Color(faction.get("color", Color("77f7ff"))),
            "capital_id": String(faction.get("capital_id", ""))
        })
    return entries

func _draw_political_map_legend() -> void:
    var entries: Array = _political_map_legend_entries()
    var panel_height := 36.0 + float(entries.size()) * 14.0 + 20.0
    var panel := Rect2(22.0, 114.0, 154.0, panel_height)
    draw_rect(panel, Color(0.015, 0.035, 0.060, 0.88), true)
    draw_rect(panel, Color(0.42, 0.82, 0.95, 0.28), false, 1.0)
    _text("POLITICAL FIELD", Vector2(panel.position.x + 8.0, panel.position.y + 15.0), 8, Color("bdeef4"))
    var y := panel.position.y + 30.0
    for entry in entries:
        var fc := Color(entry.get("color", Color("77f7ff")))
        draw_rect(Rect2(panel.position.x + 8.0, y - 7.0, 8.0, 8.0), fc, true)
        _text(_short_map_label(String(entry.get("name", "UNKNOWN")).to_upper(), 17), Vector2(panel.position.x + 22.0, y), 8, Color("f0fbff"))
        y += 14.0
    draw_rect(Rect2(panel.position.x + 8.0, y - 7.0, 8.0, 8.0), Color("ff6687"), true)
    _text("CONTESTED", Vector2(panel.position.x + 22.0, y), 7, Color("ff8fa6"))
    draw_rect(Rect2(panel.position.x + 82.0, y - 7.0, 8.0, 8.0), Color("65717e"), true)
    _text("UNCONTROLLED", Vector2(panel.position.x + 96.0, y), 7, Color("aeb9c4"))

func _system_map_fit_scale() -> float:
    var bounds := _system_world_bounds()
    return minf(SYSTEM_MAP_RECT.size.x / bounds.size.x, SYSTEM_MAP_RECT.size.y / bounds.size.y)

func _reset_system_map_view() -> void:
    system_map_zoom = SYSTEM_MAP_MIN_ZOOM
    system_map_pan = Vector2.ZERO
    system_map_touches.clear()
    system_map_touch_moved = false
    system_map_last_pinch_distance = 0.0
    queue_redraw()

func _clamp_system_map_view() -> void:
    system_map_zoom = clampf(system_map_zoom, SYSTEM_MAP_MIN_ZOOM, SYSTEM_MAP_MAX_ZOOM)
    var bounds := _system_world_bounds()
    var scale := _system_map_fit_scale() * system_map_zoom
    var scaled := bounds.size * scale
    var max_x := maxf(0.0, (scaled.x - SYSTEM_MAP_RECT.size.x) * 0.5 + 96.0)
    var max_y := maxf(0.0, (scaled.y - SYSTEM_MAP_RECT.size.y) * 0.5 + 96.0)
    system_map_pan.x = clampf(system_map_pan.x, -max_x, max_x)
    system_map_pan.y = clampf(system_map_pan.y, -max_y, max_y)

func _map_world_to_screen(world_pos: Vector2) -> Vector2:
    var bounds := _system_world_bounds()
    var scale := _system_map_fit_scale() * system_map_zoom
    return SYSTEM_MAP_RECT.get_center() + (world_pos - bounds.get_center()) * scale + system_map_pan

func _map_screen_to_world(screen_pos: Vector2) -> Vector2:
    var bounds := _system_world_bounds()
    var scale := maxf(0.0001, _system_map_fit_scale() * system_map_zoom)
    return bounds.get_center() + (screen_pos - SYSTEM_MAP_RECT.get_center() - system_map_pan) / scale

func _pan_system_map(delta_screen: Vector2) -> void:
    system_map_pan += delta_screen
    _clamp_system_map_view()
    queue_redraw()

func _zoom_system_map(factor: float, anchor: Vector2 = SYSTEM_MAP_RECT.get_center()) -> void:
    var before := _map_screen_to_world(anchor)
    system_map_zoom = clampf(system_map_zoom * factor, SYSTEM_MAP_MIN_ZOOM, SYSTEM_MAP_MAX_ZOOM)
    var after_screen := _map_world_to_screen(before)
    system_map_pan += anchor - after_screen
    _clamp_system_map_view()
    queue_redraw()

func _system_map_touch_begin(index: int, pos: Vector2) -> void:
    if not SYSTEM_MAP_RECT.has_point(pos):
        _handle_travel_tap(pos)
        return
    system_map_touches[index] = pos
    if system_map_touches.size() == 1:
        system_map_touch_moved = false
    elif system_map_touches.size() >= 2:
        var keys := system_map_touches.keys()
        system_map_last_pinch_distance = Vector2(system_map_touches[keys[0]]).distance_to(Vector2(system_map_touches[keys[1]]))
        system_map_touch_moved = true

func _system_map_touch_drag(index: int, pos: Vector2, relative: Vector2) -> void:
    if not system_map_touches.has(index):
        return
    system_map_touches[index] = pos
    if system_map_touches.size() >= 2:
        var keys := system_map_touches.keys()
        var p0 := Vector2(system_map_touches[keys[0]])
        var p1 := Vector2(system_map_touches[keys[1]])
        var distance := p0.distance_to(p1)
        if system_map_last_pinch_distance > 1.0 and distance > 1.0:
            _zoom_system_map(distance / system_map_last_pinch_distance, (p0 + p1) * 0.5)
        system_map_last_pinch_distance = distance
        system_map_touch_moved = true
    else:
        if relative.length() > 1.5:
            system_map_touch_moved = true
        _pan_system_map(relative)

func _system_map_touch_end(index: int, pos: Vector2) -> void:
    if not system_map_touches.has(index):
        return
    var was_single := system_map_touches.size() == 1
    var should_tap := was_single and not system_map_touch_moved and SYSTEM_MAP_RECT.has_point(pos)
    system_map_touches.erase(index)
    if system_map_touches.size() < 2:
        system_map_last_pinch_distance = 0.0
    if system_map_touches.is_empty():
        system_map_touch_moved = false
    if should_tap:
        _handle_travel_tap(pos)

func _system_planet_world_position(planet: String) -> Vector2:
    return PoliticalWorld.planet_position(political_world, planet)

func _system_planet_position(planet: String) -> Vector2:
    return _map_world_to_screen(_system_planet_world_position(planet))

func _system_planet_hit_rect(planet: String) -> Rect2:
    var center := _system_planet_position(planet)
    var hit_size := clampf(SYSTEM_PLANET_HIT_SIZE * sqrt(system_map_zoom), 44.0, 70.0)
    return Rect2(center - Vector2.ONE * hit_size * 0.5, Vector2.ONE * hit_size)

func _system_planet_at_screen(pos: Vector2) -> String:
    var best_id := ""
    var best_distance := INF
    for planet in planet_names:
        var hit_rect := _system_planet_hit_rect(planet)
        if not hit_rect.has_point(pos):
            continue
        var distance := pos.distance_to(_system_planet_position(planet))
        if distance < best_distance:
            best_distance = distance
            best_id = planet
    return best_id

func _system_route_pairs() -> Array:
    var pairs: Array = []
    for route in political_world.get("routes", []):
        pairs.append([String(route.a), String(route.b)])
    return pairs

func _default_travel_selection() -> String:
    if not active_contract.is_empty():
        var contract_dest := String(active_contract.get("destination", ""))
        if planet_names.has(contract_dest) and contract_dest != current_planet:
            return contract_dest
    var neighbors := PoliticalWorld.neighbors(political_world, current_planet)
    if not neighbors.is_empty():
        return neighbors[0]
    for planet in planet_names:
        if planet != current_planet:
            return planet
    return current_planet

func _set_travel_selection(planet: String) -> bool:
    if not planet_names.has(planet):
        return false
    travel_selected_planet = planet
    queue_redraw()
    return true

func _faction_color(faction_id: String) -> Color:
    var faction := PoliticalWorld.faction_record(political_world, faction_id)
    return Color(faction.get("color", Color("77f7ff")))

func _territory_color(state: String, faction_id: String = "") -> Color:
    match state:
        "CORE":
            var core := _faction_color(faction_id)
            return Color(core.r, core.g, core.b, 0.96)
        "CONTROLLED":
            var controlled := _faction_color(faction_id)
            return Color(controlled.r, controlled.g, controlled.b, 0.70)
        "CONTESTED":
            return Color("ff6687")
        "UNCONTROLLED":
            return Color("8c98a6")
    return Color("77f7ff")

func _system_route_color(danger: int) -> Color:
    match danger:
        1:
            return Color("6bffb0")
        2:
            return Color("77f7ff")
        3:
            return Color("ffb347")
        _:
            return Color("ff6687")

func _political_risk_label(danger: int) -> String:
    match danger:
        1:
            return "LOW"
        2:
            return "GUARDED"
        3:
            return "ELEVATED"
        4:
            return "HIGH"
        _:
            return "SEVERE"


func _market_buy_rect(index: int) -> Rect2:
    return Rect2(22.0, 166.0 + float(index) * 74.0, 165.0, 60.0)

func _market_sell_rect(index: int) -> Rect2:
    return Rect2(203.0, 166.0 + float(index) * 74.0, 165.0, 60.0)

func _contract_row_rect(index: int) -> Rect2:
    return Rect2(26.0, 146.0 + float(index) * 108.0, 338.0, 92.0)

func _handle_hub_tap(pos: Vector2) -> void:
    if HUB_TRAVEL_RECT.has_point(pos):
        travel_selected_planet = _default_travel_selection()
        _reset_system_map_view()
        travel_open = true
        hub_open = false
    elif HUB_MARKET_RECT.has_point(pos):
        market_open = true
        hub_open = false
    elif HUB_CONTRACTS_RECT.has_point(pos):
        contracts_open = true
        hub_open = false
    elif HUB_UPGRADES_RECT.has_point(pos):
        research_open = true
        hub_open = false
    elif HUB_CAREERS_RECT.has_point(pos):
        _open_profile_menu()
        return
    queue_redraw()

func _next_hop_toward(destination: String) -> String:
    if destination == current_planet:
        return ""
    var spec := _route_spec(current_planet, destination)
    var path: Array = spec.get("path", [])
    if path.size() < 2:
        return ""
    return String(path[1])

func _handle_travel_tap(pos: Vector2) -> void:
    if SYSTEM_MAP_BACK_RECT.has_point(pos):
        travel_open = false
        hub_open = true
        travel_selected_planet = ""
        system_map_touches.clear()
        queue_redraw()
        return
    if SYSTEM_RESET_RECT.has_point(pos):
        _reset_system_map_view()
        return

    if SYSTEM_MAP_RECT.has_point(pos):
        var tapped_planet := _system_planet_at_screen(pos)
        if not tapped_planet.is_empty():
            _set_travel_selection(tapped_planet)
            return

    if SYSTEM_FLY_RECT.has_point(pos):
        if planet_names.has(travel_selected_planet) and travel_selected_planet != current_planet:
            var next_hop := _next_hop_toward(travel_selected_planet)
            if not next_hop.is_empty():
                _start_route(next_hop)
        return


func _handle_market_tap(pos: Vector2) -> void:
    if SUBMENU_BACK_RECT.has_point(pos):
        market_open = false
        hub_open = true
        queue_redraw()
        return
    for i in commodity_names.size():
        if _market_buy_rect(i).has_point(pos):
            _buy_commodity(commodity_names[i])
            queue_redraw()
            return
        if _market_sell_rect(i).has_point(pos):
            _sell_commodity(commodity_names[i])
            queue_redraw()
            return

func _handle_contracts_tap(pos: Vector2) -> void:
    if SUBMENU_BACK_RECT.has_point(pos):
        contracts_open = false
        hub_open = true
        queue_redraw()
        return
    for i in contract_board.size():
        if _contract_row_rect(i).has_point(pos):
            _accept_contract(i)
            queue_redraw()
            return

func _handle_tap(pos: Vector2, touch_index: int = -1) -> void:
    if career_slots_open:
        _handle_career_slots_tap(pos)
        return
    if profile_menu_open:
        _handle_profile_tap(pos)
        return
    if run_paused:
        _handle_pause_tap(pos)
        return
    if travel_open:
        _handle_travel_tap(pos)
        return
    if market_open:
        _handle_market_tap(pos)
        return
    if contracts_open:
        _handle_contracts_tap(pos)
        return
    if weapon_research_open:
        _handle_weapon_research_tap(pos)
        return
    if research_open:
        _handle_research_tap(pos)
        return
    if game_over:
        _return_to_menu()
        return
    if shop_open:
        _handle_shop_tap(pos)
        return
    if not playing:
        _handle_hub_tap(pos)
        return
    if PAUSE_RECT.has_point(pos):
        _clear_control_holds()
        _pause_run()
        return
    if LEFT_CONTROL_RECT.has_point(pos):
        left_control_held = true
        left_touch_index = touch_index
        return
    if RIGHT_CONTROL_RECT.has_point(pos):
        right_control_held = true
        right_touch_index = touch_index
        return
    if DASH_RECT.has_point(pos):
        dash_touch_index = touch_index
        _dash()
        return

func _release_control_touch(touch_index: int) -> void:
    if touch_index == left_touch_index:
        left_control_held = false
        left_touch_index = -1
    if touch_index == right_touch_index:
        right_control_held = false
        right_touch_index = -1
    if touch_index == dash_touch_index:
        dash_touch_index = -1

func _clear_control_holds() -> void:
    left_control_held = false
    right_control_held = false
    left_touch_index = -1
    right_touch_index = -1
    dash_touch_index = -1

func _set_target(x: float) -> void:
    target_x = clampf(x, LEFT, RIGHT)

func _dash() -> void:
    if not playing or dash_cooldown > 0.0 or dash_timer > 0.0:
        return
    dash_timer = DASH_DURATION
    dash_cooldown = DASH_COOLDOWN
    dash_score_timer = DASH_SCORE_DURATION
    invuln = maxf(invuln, 0.24)
    shake = maxf(shake, 3.5)
    _burst(Vector2(player_x, player_y), 10, Color("77f7ff"))
    _play_sfx(dash_sfx)

func _start_game() -> void:
    _clear_control_holds()
    playing = true
    game_over = false
    won = false
    elapsed = 0.0
    level = 1
    shop_open = false
    last_level_bonus = 0
    score = 0
    energy = 0
    combo = 1
    best_combo = 1
    max_hp = 2 + research_hits
    hp = max_hp
    shield_charges = research_shield
    player_x = W * 0.5
    player_y = PLAYER_Y
    target_x = player_x
    invuln = 0.0
    flash = 0.0
    cyan_flash = 0.0
    shake = 0.0
    easy_spawn_clock = 0.90
    hard_spawn_clock = 0.72
    pickup_clock = _energy_spawn_interval()
    neutral_spawn_clock = 1.65
    fire_clock = 0.18
    repair_clock = 18.0
    current_weapon = _valid_starting_weapon()
    weapon_banner_timer = 0.0
    weapon_banner_text = ""
    loot_banner_timer = 0.0
    loot_banner_text = ""
    police_scan_active = false
    police_scan_faction_id = ""
    police_scan_timer = 0.0
    police_scan_duration = 0.0
    police_scan_attempted = false
    police_scan_result_timer = 0.0
    police_scan_result_text = ""
    dash_cooldown = 0.0
    dash_timer = 0.0
    dash_score_timer = 0.0
    near_miss_timer = 0.0
    slowmo_timer = 0.0
    finale_active = false
    finale_banner_timer = 0.0
    extraction_spawned = false
    extraction_lane = ""
    result_reason = ""
    research_open = false
    weapon_research_open = false
    run_paused = false
    banked_this_run = false
    last_banked_score = 0
    world_scroll = 0.0
    hard_lane_right = true
    lane_event_active = false
    lane_event_timer = 0.0
    lane_events_started = 0
    next_lane_event_at = _first_split_time()
    lane_choice_banner_timer = 0.0
    station_height = _station_height_for_level()
    station_top = -station_height - 40.0
    station_locked_side = ""
    objects.clear()
    shots.clear()
    enemy_shots.clear()
    pending_drops.clear()
    particles.clear()
    last_near_ids.clear()
    _clear_run_snapshot()

func _ship_speed_multiplier() -> float:
    return 0.72 + float(research_ship_speed) * 0.04

func _dash_distance() -> float:
    return minf(PLAYER_Y - 45.0, DASH_FORWARD_DISTANCE + float(research_dash) * 35.0)

func _dash_speed() -> float:
    return DASH_FORWARD_SPEED + float(research_dash) * 40.0

func _damage_multiplier() -> float:
    return 1.0 + float(research_damage) * 0.03

func _near_miss_research_multiplier(is_dash: bool) -> float:
    var mult := 1.0 + float(research_ship_speed) * 0.08
    if is_dash:
        mult += float(research_dash) * 0.12
    return mult

func _level_duration() -> float:
    if route_active:
        return route_duration
    return minf(LEVEL_TIME_MAX, LEVEL_TIME_BASE + float(level - 1) * LEVEL_TIME_STEP)

func _split_count_for_level() -> int:
    return mini(4, 1 + int((level - 1) / 2))

func _station_height_for_level() -> float:
    return minf(STATION_HEIGHT_MAX, STATION_HEIGHT_BASE + float(level - 1) * STATION_HEIGHT_STEP)

func _first_split_time() -> float:
    var count := _split_count_for_level()
    return maxf(6.0, _level_duration() / float(count + 1))

func _schedule_next_split() -> void:
    var count := _split_count_for_level()
    if lane_events_started >= count:
        next_lane_event_at = _level_duration() + 1.0
        return
    var target := _level_duration() * float(lane_events_started + 1) / float(count + 1)
    next_lane_event_at = maxf(target, elapsed + 1.25)

func _level_difficulty() -> float:
    var level_pressure := float(level - 1) * 0.12
    var stage_pressure := clampf(elapsed / _level_duration(), 0.0, 1.0) * 0.18
    return minf(1.65, level_pressure + stage_pressure)

func _spawn_interval(easy_value: float, hard_value: float, difficulty: float) -> float:
    var base := lerpf(easy_value, hard_value, clampf(difficulty, 0.0, 1.0))
    if difficulty > 1.0:
        base /= 1.0 + (difficulty - 1.0) * 0.42
    return maxf(0.24, base)

func _shop_weapon_cost(weapon: String) -> int:
    match weapon:
        "single":
            return SHOP_SINGLE_COST
        "dual":
            return SHOP_DUAL_COST
        "cone":
            return SHOP_CONE_COST
        "seeker":
            return SHOP_SEEKER_COST
        "laser":
            return SHOP_LASER_COST
    return 999999

func _open_shop() -> void:
    if shop_open or game_over:
        return
    playing = false
    shop_open = true
    last_level_bonus = 30 + level * 10
    score += last_level_bonus
    combo = 1
    dash_timer = 0.0
    dash_score_timer = 0.0
    invuln = 0.0
    objects.clear()
    shots.clear()
    enemy_shots.clear()
    lane_event_active = false
    lane_event_timer = 0.0
    station_locked_side = ""
    station_top = -station_height - 40.0
    _play_sfx(level_clear_sfx)
    _save_run_snapshot()
    queue_redraw()

func _buy_repair() -> bool:
    if not shop_open or hp >= max_hp or score < SHOP_REPAIR_COST:
        return false
    score -= SHOP_REPAIR_COST
    hp += 1
    _play_sfx(repair_sfx)
    _save_run_snapshot()
    return true

func _buy_weapon(weapon: String) -> bool:
    if not shop_open or weapon == current_weapon:
        return false
    var cost := _shop_weapon_cost(weapon)
    if score < cost:
        return false
    score -= cost
    current_weapon = weapon
    _play_sfx(buy_sfx)
    _save_run_snapshot()
    return true

func _start_next_level() -> void:
    if not shop_open:
        return
    _clear_control_holds()
    level += 1
    elapsed = 0.0
    shop_open = false
    playing = true
    player_x = W * 0.5
    player_y = PLAYER_Y
    target_x = player_x
    combo = 1
    invuln = 0.0
    flash = 0.0
    cyan_flash = 0.0
    shake = 0.0
    easy_spawn_clock = 0.72
    hard_spawn_clock = 0.54
    neutral_spawn_clock = 0.72
    pickup_clock = _energy_spawn_interval()
    fire_clock = 0.15
    repair_clock = rng.randf_range(18.0, 24.0)
    dash_cooldown = 0.0
    dash_timer = 0.0
    dash_score_timer = 0.0
    near_miss_timer = 0.0
    slowmo_timer = 0.0
    finale_active = false
    extraction_spawned = false
    extraction_lane = ""
    lane_event_active = false
    lane_event_timer = 0.0
    lane_events_started = 0
    next_lane_event_at = _first_split_time()
    lane_choice_banner_timer = 0.0
    station_height = _station_height_for_level()
    station_top = -station_height - 40.0
    station_locked_side = ""
    objects.clear()
    shots.clear()
    enemy_shots.clear()
    last_near_ids.clear()
    _play_sfx(finale_sfx, 1.12, -2.0)

func _handle_shop_tap(pos: Vector2) -> void:
    if SHOP_REPAIR_RECT.has_point(pos):
        _buy_repair()
    elif SHOP_SINGLE_RECT.has_point(pos):
        _buy_weapon("single")
    elif SHOP_DUAL_RECT.has_point(pos):
        _buy_weapon("dual")
    elif SHOP_CONE_RECT.has_point(pos):
        _buy_weapon("cone")
    elif SHOP_SEEKER_RECT.has_point(pos):
        _buy_weapon("seeker")
    elif SHOP_LASER_RECT.has_point(pos):
        _buy_weapon("laser")
    elif SHOP_CONTINUE_RECT.has_point(pos):
        _start_next_level()
    queue_redraw()

func _finish(success: bool) -> void:
    if route_active:
        if success:
            _arrive_at_destination()
        else:
            _fail_route(result_reason if not result_reason.is_empty() else "SHIP LOST")
        return
    playing = false
    game_over = true
    won = success
    if result_reason.is_empty():
        result_reason = "RUN ENDED"
    _play_sfx(level_clear_sfx if success else death_sfx)
    _bank_run_score()
    _clear_run_snapshot()
    queue_redraw()

func _research_level(track: String) -> int:
    match track:
        "ship":
            return research_ship_speed
        "dash":
            return research_dash
        "damage":
            return research_damage
        "hits":
            return research_hits
        "shield":
            return research_shield
    return 0

func _research_max(track: String) -> int:
    if track == "shield":
        return 5
    if track == "hits":
        return 5
    if track == "dash":
        return 10
    return 20

func _research_cost(track: String) -> int:
    var lvl := _research_level(track)
    match track:
        "ship":
            return int(round(500.0 * pow(1.75, lvl)))
        "dash":
            return int(round(750.0 * pow(1.75, lvl)))
        "damage":
            return int(round(1000.0 * pow(1.80, lvl)))
        "hits":
            return int(round(5000.0 * pow(1.35, lvl)))
        "shield":
            return int(round(500.0 * pow(5.0, lvl)))
    return 99999999

func _buy_research(track: String) -> bool:
    var lvl := _research_level(track)
    if lvl >= _research_max(track):
        return false
    var cost := _research_cost(track)
    if research_credits < cost:
        return false
    research_credits -= cost
    match track:
        "ship":
            research_ship_speed += 1
        "dash":
            research_dash += 1
        "damage":
            research_damage += 1
        "hits":
            research_hits += 1
        "shield":
            research_shield += 1
    _play_sfx(buy_sfx, 1.08)
    _save_all_state()
    return true

func _weapon_research_cost(weapon: String) -> int:
    return _shop_weapon_cost(weapon) * 10

func _weapon_start_unlocked(weapon: String) -> bool:
    match weapon:
        "none":
            return true
        "single":
            return research_start_single
        "dual":
            return research_start_dual
        "laser":
            return research_start_laser
        "cone":
            return research_start_cone
        "seeker":
            return research_start_seeker
    return false

func _valid_starting_weapon() -> String:
    return starting_weapon if _weapon_start_unlocked(starting_weapon) else "none"

func _buy_start_weapon_research(weapon: String) -> bool:
    if weapon == "none" or _weapon_start_unlocked(weapon):
        return false
    var cost := _weapon_research_cost(weapon)
    if research_credits < cost:
        return false
    research_credits -= cost
    match weapon:
        "single":
            research_start_single = true
        "dual":
            research_start_dual = true
        "laser":
            research_start_laser = true
        "cone":
            research_start_cone = true
        "seeker":
            research_start_seeker = true
        _:
            return false
    starting_weapon = weapon
    _play_sfx(weapon_pickup_sfx, 0.96)
    _save_all_state()
    return true

func _select_start_weapon(weapon: String) -> bool:
    if not _weapon_start_unlocked(weapon):
        return false
    starting_weapon = weapon
    _play_sfx(buy_sfx, 1.16, -3.0)
    _save_all_state()
    return true

func _handle_weapon_research_tap(pos: Vector2) -> void:
    if WEAPON_NONE_RECT.has_point(pos):
        _select_start_weapon("none")
    elif WEAPON_SINGLE_RECT.has_point(pos):
        if research_start_single:
            _select_start_weapon("single")
        else:
            _buy_start_weapon_research("single")
    elif WEAPON_DUAL_RECT.has_point(pos):
        if research_start_dual:
            _select_start_weapon("dual")
        else:
            _buy_start_weapon_research("dual")
    elif WEAPON_LASER_RECT.has_point(pos):
        if research_start_laser:
            _select_start_weapon("laser")
        else:
            _buy_start_weapon_research("laser")
    elif WEAPON_CONE_RECT.has_point(pos):
        if research_start_cone:
            _select_start_weapon("cone")
        else:
            _buy_start_weapon_research("cone")
    elif WEAPON_SEEKER_RECT.has_point(pos):
        if research_start_seeker:
            _select_start_weapon("seeker")
        else:
            _buy_start_weapon_research("seeker")
    elif WEAPON_RESEARCH_BACK_RECT.has_point(pos):
        weapon_research_open = false
        research_open = true
    queue_redraw()

func _handle_research_tap(pos: Vector2) -> void:
    if RESEARCH_SHIP_RECT.has_point(pos):
        _buy_research("ship")
    elif RESEARCH_DASH_RECT.has_point(pos):
        _buy_research("dash")
    elif RESEARCH_DAMAGE_RECT.has_point(pos):
        _buy_research("damage")
    elif RESEARCH_HITS_RECT.has_point(pos):
        _buy_research("hits")
    elif RESEARCH_SHIELD_RECT.has_point(pos):
        _buy_research("shield")
    elif RESEARCH_WEAPONS_RECT.has_point(pos):
        research_open = false
        weapon_research_open = true
    elif RESEARCH_BACK_RECT.has_point(pos):
        research_open = false
        hub_open = true
    queue_redraw()

func _pause_run() -> void:
    if run_paused or game_over or (not playing and not shop_open):
        return
    _clear_control_holds()
    run_paused = true
    _save_run_snapshot()
    _save_meta()
    queue_redraw()

func _resume_run() -> void:
    if not run_paused:
        return
    run_paused = false
    queue_redraw()

func _handle_pause_tap(pos: Vector2) -> void:
    if PAUSE_RESUME_RECT.has_point(pos):
        _resume_run()
    elif PAUSE_QUIT_RECT.has_point(pos):
        _quit_run_with_score()

func _quit_run_with_score() -> void:
    _clear_control_holds()
    if route_active:
        _bank_run_score()
        _fail_route("FLIGHT ABORTED")
        return
    _bank_run_score()
    _clear_run_snapshot()
    playing = false
    shop_open = false
    game_over = false
    run_paused = false
    research_open = false
    weapon_research_open = false
    hub_open = true
    objects.clear()
    shots.clear()
    enemy_shots.clear()
    pending_drops.clear()
    particles.clear()
    queue_redraw()

func _return_to_menu() -> void:
    _clear_control_holds()
    playing = false
    game_over = false
    shop_open = false
    run_paused = false
    research_open = false
    weapon_research_open = false
    market_open = false
    contracts_open = false
    travel_open = false
    hub_open = true
    queue_redraw()

func _bank_run_score() -> void:
    if banked_this_run:
        return
    last_banked_score = maxi(0, score)
    research_credits += last_banked_score
    banked_this_run = true
    _save_meta()

func _save_meta() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("meta", "credits", research_credits)
    cfg.set_value("meta", "ship_speed", research_ship_speed)
    cfg.set_value("meta", "dash", research_dash)
    cfg.set_value("meta", "damage", research_damage)
    cfg.set_value("meta", "hits", research_hits)
    cfg.set_value("meta", "shield", research_shield)
    cfg.set_value("meta", "start_single", research_start_single)
    cfg.set_value("meta", "start_dual", research_start_dual)
    cfg.set_value("meta", "start_laser", research_start_laser)
    cfg.set_value("meta", "start_cone", research_start_cone)
    cfg.set_value("meta", "start_seeker", research_start_seeker)
    cfg.set_value("meta", "starting_weapon", starting_weapon)
    var path := _active_meta_path()
    if path.is_empty():
        return
    cfg.save(path)

func _load_meta() -> void:
    var cfg := ConfigFile.new()
    var path := _active_meta_path()
    if path.is_empty() or cfg.load(path) != OK:
        return
    research_credits = int(cfg.get_value("meta", "credits", 0))
    research_ship_speed = int(cfg.get_value("meta", "ship_speed", 0))
    research_dash = int(cfg.get_value("meta", "dash", 0))
    research_damage = int(cfg.get_value("meta", "damage", 0))
    research_hits = int(cfg.get_value("meta", "hits", 0))
    research_shield = int(cfg.get_value("meta", "shield", 0))
    research_start_single = bool(cfg.get_value("meta", "start_single", false))
    research_start_dual = bool(cfg.get_value("meta", "start_dual", false))
    research_start_laser = bool(cfg.get_value("meta", "start_laser", false))
    research_start_cone = bool(cfg.get_value("meta", "start_cone", false))
    research_start_seeker = bool(cfg.get_value("meta", "start_seeker", false))
    starting_weapon = String(cfg.get_value("meta", "starting_weapon", "none"))
    if not _weapon_start_unlocked(starting_weapon):
        starting_weapon = "none"

func _save_run_snapshot() -> void:
    if game_over or (not playing and not shop_open):
        return
    var cfg := ConfigFile.new()
    cfg.set_value("run", "exists", true)
    cfg.set_value("run", "playing", playing)
    cfg.set_value("run", "shop_open", shop_open)
    cfg.set_value("run", "level", level)
    cfg.set_value("run", "elapsed", elapsed)
    cfg.set_value("run", "score", score)
    cfg.set_value("run", "energy", energy)
    cfg.set_value("run", "combo", combo)
    cfg.set_value("run", "best_combo", best_combo)
    cfg.set_value("run", "hp", hp)
    cfg.set_value("run", "max_hp", max_hp)
    cfg.set_value("run", "shield_charges", shield_charges)
    cfg.set_value("run", "player_x", player_x)
    cfg.set_value("run", "player_y", player_y)
    cfg.set_value("run", "target_x", target_x)
    cfg.set_value("run", "invuln", invuln)
    cfg.set_value("run", "easy_spawn_clock", easy_spawn_clock)
    cfg.set_value("run", "hard_spawn_clock", hard_spawn_clock)
    cfg.set_value("run", "neutral_spawn_clock", neutral_spawn_clock)
    cfg.set_value("run", "pickup_clock", pickup_clock)
    cfg.set_value("run", "fire_clock", fire_clock)
    cfg.set_value("run", "repair_clock", repair_clock)
    cfg.set_value("run", "dash_cooldown", dash_cooldown)
    cfg.set_value("run", "dash_timer", dash_timer)
    cfg.set_value("run", "dash_score_timer", dash_score_timer)
    cfg.set_value("run", "current_weapon", current_weapon)
    cfg.set_value("run", "hard_lane_right", hard_lane_right)
    cfg.set_value("run", "lane_event_active", lane_event_active)
    cfg.set_value("run", "lane_event_timer", lane_event_timer)
    cfg.set_value("run", "lane_events_started", lane_events_started)
    cfg.set_value("run", "next_lane_event_at", next_lane_event_at)
    cfg.set_value("run", "station_height", station_height)
    cfg.set_value("run", "station_top", station_top)
    cfg.set_value("run", "station_locked_side", station_locked_side)
    cfg.set_value("run", "world_scroll", world_scroll)
    cfg.set_value("run", "last_level_bonus", last_level_bonus)
    cfg.set_value("run", "route_active", route_active)
    cfg.set_value("run", "route_origin", route_origin)
    cfg.set_value("run", "destination_planet", destination_planet)
    cfg.set_value("run", "route_distance", route_distance)
    cfg.set_value("run", "route_danger", route_danger)
    cfg.set_value("run", "route_wealth", route_wealth)
    cfg.set_value("run", "route_duration", route_duration)
    cfg.set_value("run", "boss_active", boss_active)
    cfg.set_value("run", "boss_defeated_pending", boss_defeated_pending)
    cfg.set_value("run", "bounty_completed", bounty_completed_this_route)
    cfg.set_value("run", "encounter_active", encounter_active)
    cfg.set_value("run", "encounter_mode", encounter_mode)
    cfg.set_value("run", "encounter_faction_id", encounter_faction_id)
    cfg.set_value("run", "encounter_hostile", encounter_hostile)
    cfg.set_value("run", "encounter_timer", encounter_timer)
    cfg.set_value("run", "encounter_clock", encounter_clock)
    cfg.set_value("run", "encounter_banner_timer", encounter_banner_timer)
    cfg.set_value("run", "police_scan_active", police_scan_active)
    cfg.set_value("run", "police_scan_faction_id", police_scan_faction_id)
    cfg.set_value("run", "police_scan_timer", police_scan_timer)
    cfg.set_value("run", "police_scan_duration", police_scan_duration)
    cfg.set_value("run", "police_scan_attempted", police_scan_attempted)
    cfg.set_value("run", "police_scan_result_timer", police_scan_result_timer)
    cfg.set_value("run", "police_scan_result_text", police_scan_result_text)
    # Legacy keys remain for pre-Slice-5 compatibility.
    cfg.set_value("run", "pirate_active", encounter_active and encounter_mode == "pirate")
    cfg.set_value("run", "pirate_timer", encounter_timer if encounter_mode == "pirate" else 0.0)
    cfg.set_value("run", "pirate_clock", encounter_clock)
    cfg.set_value("run", "objects", objects)
    cfg.set_value("run", "shots", shots)
    cfg.set_value("run", "enemy_shots", enemy_shots)
    cfg.set_value("run", "last_near_ids", last_near_ids)
    cfg.set_value("run", "rng_state", rng.state)
    var path := _active_run_path()
    if path.is_empty():
        return
    cfg.save(path)

func _load_run_snapshot() -> bool:
    var cfg := ConfigFile.new()
    var path := _active_run_path()
    if path.is_empty() or cfg.load(path) != OK or not bool(cfg.get_value("run", "exists", false)):
        return false
    playing = bool(cfg.get_value("run", "playing", true))
    shop_open = bool(cfg.get_value("run", "shop_open", false))
    level = int(cfg.get_value("run", "level", 1))
    elapsed = float(cfg.get_value("run", "elapsed", 0.0))
    score = int(cfg.get_value("run", "score", 0))
    energy = int(cfg.get_value("run", "energy", 0))
    combo = int(cfg.get_value("run", "combo", 1))
    best_combo = int(cfg.get_value("run", "best_combo", 1))
    max_hp = int(cfg.get_value("run", "max_hp", 2 + research_hits))
    hp = int(cfg.get_value("run", "hp", max_hp))
    shield_charges = int(cfg.get_value("run", "shield_charges", 0))
    player_x = float(cfg.get_value("run", "player_x", W * 0.5))
    player_y = float(cfg.get_value("run", "player_y", PLAYER_Y))
    target_x = float(cfg.get_value("run", "target_x", player_x))
    invuln = float(cfg.get_value("run", "invuln", 0.0))
    easy_spawn_clock = float(cfg.get_value("run", "easy_spawn_clock", 0.9))
    hard_spawn_clock = float(cfg.get_value("run", "hard_spawn_clock", 0.7))
    neutral_spawn_clock = float(cfg.get_value("run", "neutral_spawn_clock", 1.6))
    pickup_clock = float(cfg.get_value("run", "pickup_clock", 1.3))
    fire_clock = float(cfg.get_value("run", "fire_clock", 0.2))
    repair_clock = float(cfg.get_value("run", "repair_clock", 18.0))
    dash_cooldown = float(cfg.get_value("run", "dash_cooldown", 0.0))
    dash_timer = float(cfg.get_value("run", "dash_timer", 0.0))
    dash_score_timer = float(cfg.get_value("run", "dash_score_timer", 0.0))
    current_weapon = String(cfg.get_value("run", "current_weapon", "none"))
    hard_lane_right = bool(cfg.get_value("run", "hard_lane_right", true))
    lane_event_active = bool(cfg.get_value("run", "lane_event_active", false))
    lane_event_timer = float(cfg.get_value("run", "lane_event_timer", 0.0))
    lane_events_started = int(cfg.get_value("run", "lane_events_started", 0))
    next_lane_event_at = float(cfg.get_value("run", "next_lane_event_at", _first_split_time()))
    station_height = float(cfg.get_value("run", "station_height", _station_height_for_level()))
    station_top = float(cfg.get_value("run", "station_top", -station_height - 40.0))
    station_locked_side = String(cfg.get_value("run", "station_locked_side", ""))
    world_scroll = float(cfg.get_value("run", "world_scroll", 0.0))
    last_level_bonus = int(cfg.get_value("run", "last_level_bonus", 0))
    route_active = bool(cfg.get_value("run", "route_active", false))
    route_origin = String(cfg.get_value("run", "route_origin", current_planet))
    destination_planet = String(cfg.get_value("run", "destination_planet", ""))
    if ["Aster", "Cinder", "Vesper", "Helix"].has(route_origin):
        route_origin = PoliticalWorld.find_planet_by_type(
            political_world,
            PoliticalWorld.legacy_type_for_name(route_origin)
        )
    if ["Aster", "Cinder", "Vesper", "Helix"].has(destination_planet):
        destination_planet = PoliticalWorld.find_planet_by_type(
            political_world,
            PoliticalWorld.legacy_type_for_name(destination_planet)
        )
    route_distance = int(cfg.get_value("run", "route_distance", 1))
    route_danger = int(cfg.get_value("run", "route_danger", 1))
    route_wealth = clampi(int(cfg.get_value("run", "route_wealth", 1)), 1, 5)
    route_duration = float(cfg.get_value("run", "route_duration", 18.0))
    boss_active = bool(cfg.get_value("run", "boss_active", false))
    boss_defeated_pending = bool(cfg.get_value("run", "boss_defeated_pending", false))
    bounty_completed_this_route = bool(cfg.get_value("run", "bounty_completed", false))
    var legacy_pirate_active := bool(cfg.get_value("run", "pirate_active", false))
    encounter_active = bool(cfg.get_value("run", "encounter_active", legacy_pirate_active))
    encounter_mode = String(cfg.get_value("run", "encounter_mode", "pirate" if legacy_pirate_active else ""))
    encounter_faction_id = String(cfg.get_value("run", "encounter_faction_id", ""))
    encounter_hostile = bool(cfg.get_value("run", "encounter_hostile", encounter_mode == "pirate" or (encounter_mode == "police" and _police_hostile_eligible(encounter_faction_id))))
    encounter_timer = float(cfg.get_value("run", "encounter_timer", cfg.get_value("run", "pirate_timer", 0.0)))
    encounter_clock = float(cfg.get_value("run", "encounter_clock", cfg.get_value("run", "pirate_clock", 999.0)))
    encounter_banner_timer = float(cfg.get_value("run", "encounter_banner_timer", 0.0))
    police_scan_active = bool(cfg.get_value("run", "police_scan_active", false))
    police_scan_faction_id = String(cfg.get_value("run", "police_scan_faction_id", ""))
    police_scan_timer = float(cfg.get_value("run", "police_scan_timer", 0.0))
    police_scan_duration = float(cfg.get_value("run", "police_scan_duration", 0.0))
    police_scan_attempted = bool(cfg.get_value("run", "police_scan_attempted", false))
    police_scan_result_timer = float(cfg.get_value("run", "police_scan_result_timer", 0.0))
    police_scan_result_text = String(cfg.get_value("run", "police_scan_result_text", ""))
    if police_scan_active and (encounter_mode != "police" or encounter_hostile or police_scan_faction_id != encounter_faction_id):
        _cancel_police_scan()
    _sync_legacy_pirate_state()
    hub_open = not route_active
    objects.clear()
    for item in cfg.get_value("run", "objects", []):
        objects.append(item)
    shots.clear()
    for item in cfg.get_value("run", "shots", []):
        shots.append(item)
    enemy_shots.clear()
    for item in cfg.get_value("run", "enemy_shots", []):
        enemy_shots.append(item)
    last_near_ids = cfg.get_value("run", "last_near_ids", {})
    rng.state = int(cfg.get_value("run", "rng_state", rng.state))
    game_over = false
    banked_this_run = false
    research_open = false
    particles.clear()
    return true

func _clear_run_snapshot() -> void:
    var path := _active_run_path()
    if path.is_empty():
        return
    var cfg := ConfigFile.new()
    cfg.set_value("run", "exists", false)
    cfg.save(path)

func _lane_score_multiplier() -> float:
    return 1.35 if _station_at_player() and _is_hard_position(player_x) else 1.0

func _dash_score_multiplier() -> float:
    return 2.0 if dash_score_timer > 0.0 else 1.0

func _begin_lane_event() -> void:
    lane_event_active = true
    station_height = _station_height_for_level()
    station_top = -station_height - 40.0
    station_locked_side = ""
    lane_event_timer = (H + 80.0 + station_height) / STATION_SPEED
    lane_events_started += 1
    _schedule_next_split()
    hard_lane_right = rng.randf() < 0.5
    lane_choice_banner_timer = 2.4
    easy_spawn_clock = 0.18 if level == 1 else 0.12
    hard_spawn_clock = 0.14 if level == 1 else 0.08
    shake = maxf(shake, 1.8)

func _end_lane_event() -> void:
    lane_event_active = false
    lane_event_timer = 0.0
    lane_choice_banner_timer = 0.0
    station_locked_side = ""
    station_top = -station_height - 40.0
    hard_lane_right = false
    neutral_spawn_clock = maxf(neutral_spawn_clock, 0.45)
    _neutralize_lane_objects()

func _neutralize_lane_objects() -> void:
    for obj in objects:
        if not obj.has("lane_min") or not obj.has("lane_max"):
            continue
        obj.lane_min = LEFT
        obj.lane_max = RIGHT
        obj.hard = false
        if obj.type == "hazard" and obj.has("lane_speed_mult"):
            var lane_mult := maxf(0.01, float(obj.lane_speed_mult))
            obj.speed = float(obj.speed) / lane_mult
            obj.lane_speed_mult = 1.0

func _station_at_player() -> bool:
    if not lane_event_active:
        return false
    return player_y + PLAYER_RADIUS >= station_top and player_y - PLAYER_RADIUS <= station_top + station_height

func _station_barrier_rects() -> Array[Rect2]:
    return [
        Rect2(0.0, station_top, STATION_EDGE_WALL, station_height),
        Rect2(LANE_SPLIT - STATION_CENTER_WALL * 0.5, station_top, STATION_CENTER_WALL, station_height),
        Rect2(W - STATION_EDGE_WALL, station_top, STATION_EDGE_WALL, station_height)
    ]

func _check_station_collision() -> void:
    if not _station_at_player():
        return

    var player_rect := Rect2(
        Vector2(player_x - PLAYER_RADIUS, player_y - PLAYER_RADIUS),
        Vector2(PLAYER_RADIUS * 2.0, PLAYER_RADIUS * 2.0)
    )

    for barrier in _station_barrier_rects():
        if player_rect.intersects(barrier):
            hp = 0
            combo = 1
            flash = 0.45
            shake = 12.0
            result_reason = "STATION COLLISION"
            _burst(Vector2(player_x, player_y), 24, Color("ffb347"))
            _finish(false)
            return

    if station_locked_side.is_empty():
        station_locked_side = "RIGHT" if player_x > LANE_SPLIT else "LEFT"

func _is_hard_position(x: float) -> bool:
    if x >= RIGHT_LANE_MIN:
        return hard_lane_right
    if x <= LEFT_LANE_MAX:
        return not hard_lane_right
    return false

func _lane_bounds(hard_lane: bool) -> Vector2:
    var use_right := hard_lane == hard_lane_right
    if use_right:
        return Vector2(RIGHT_LANE_MIN, RIGHT_LANE_MAX)
    return Vector2(LEFT_LANE_MIN, LEFT_LANE_MAX)

func _lane_center(hard_lane: bool) -> float:
    var bounds := _lane_bounds(hard_lane)
    return (bounds.x + bounds.y) * 0.5

func _enemy_kind_cap_for_level() -> int:
    if level <= 1:
        return 0
    if level <= 3:
        return 1
    if level <= 5:
        return 2
    if level <= 7:
        return 3
    return 4

func _route_asteroid_weight() -> float:
    return 1.0 + float(clampi(route_danger, 1, 5) - 1) * 0.36

func _route_container_weight() -> float:
    return 0.28 + float(clampi(route_wealth, 1, 5) - 1) * 0.14

func _route_object_spawn_interval(hard_lane: bool = false, lane_mode: bool = false) -> float:
    var total_weight := _route_asteroid_weight() + _route_container_weight()
    var interval := 1.58 / maxf(0.1, total_weight)
    if lane_mode:
        interval *= 0.78 if hard_lane else 1.12
    return clampf(interval, 0.34, 1.45)

func _choose_route_environment_kind() -> int:
    var asteroid_weight := _route_asteroid_weight()
    var container_weight := _route_container_weight()
    var container_chance := container_weight / maxf(0.01, asteroid_weight + container_weight)
    if rng.randf() >= container_chance:
        return 0
    var reinforced_chance := 0.06 + float(clampi(route_wealth, 1, 5) - 1) * 0.02
    return 2 if rng.randf() < reinforced_chance else 1

func _police_combat_active() -> bool:
    return route_active and encounter_active and encounter_mode == "police" and encounter_hostile

func _choose_enemy_kind(hard_lane: bool) -> int:
    var cap := _enemy_kind_cap_for_level()
    var roll := rng.randf()

    if route_active:
        if encounter_active:
            if encounter_mode == "pirate":
                # Pirates always attack on sight. Pirate contacts never produce pentagons.
                if roll < (0.48 if hard_lane else 0.36):
                    return 3
            elif encounter_mode == "police":
                # Heavy pentagons exist only during active hostile patrol combat.
                if _police_combat_active() and _heavy_enforcement_eligible(encounter_faction_id) and roll < (0.18 if hard_lane else 0.12):
                    return 4
                if roll < (0.52 if hard_lane else 0.40):
                    return 3
        return _choose_route_environment_kind()

    if cap <= 0:
        return 0
    if cap == 1:
        return 1 if roll < (0.34 if hard_lane else 0.26) else 0
    if cap == 2:
        if roll < (0.08 if hard_lane else 0.05):
            return 2
        if roll < (0.42 if hard_lane else 0.34):
            return 1
        return 0
    if cap == 3:
        if roll < (0.16 if hard_lane else 0.10):
            return 3
        if roll < (0.39 if hard_lane else 0.30):
            return 2
        if roll < (0.70 if hard_lane else 0.62):
            return 1
        return 0
    if roll < (0.11 if hard_lane else 0.07):
        return 4
    if roll < (0.25 if hard_lane else 0.18):
        return 3
    if roll < (0.48 if hard_lane else 0.37):
        return 2
    if roll < (0.74 if hard_lane else 0.66):
        return 1
    return 0


func _spawn_circle_bunch(hard_lane: bool, count: int) -> void:
    var bounds := _lane_bounds(hard_lane)
    var center := rng.randf_range(bounds.x + 34.0, bounds.y - 34.0)
    for i in count:
        var radius := rng.randf_range(17.0, 22.0)
        var x := clampf(center + rng.randf_range(-24.0, 24.0), bounds.x + radius, bounds.y - radius)
        var hp_value := _obstacle_max_hp(0)
        objects.append({
            "id": rng.randi(),
            "type": "hazard",
            "kind": 0,
            "hp": hp_value,
            "max_hp": hp_value,
            "hard": hard_lane,
            "x": x,
            "y": -40.0 - float(i) * rng.randf_range(20.0, 34.0),
            "r": radius,
            "speed": rng.randf_range(165.0, 195.0),
            "drift": rng.randf_range(-5.0, 5.0),
            "shoot_clock": 999.0,
            "angle": rng.randf_range(0.0, TAU),
            "spin": rng.randf_range(-0.18, 0.18),
            "lane_speed_mult": 1.0,
            "lane_min": bounds.x,
            "lane_max": bounds.y
        })

func _route_progress_fraction() -> float:
    if not route_active or route_duration <= 0.0:
        return 0.0
    return clampf(elapsed / route_duration, 0.0, 1.0)

func _current_flight_political_context() -> Dictionary:
    if route_active and not route_origin.is_empty() and not destination_planet.is_empty():
        var segment := _route_political_segment_at_progress(route_origin, destination_planet, _route_progress_fraction())
        if not segment.is_empty():
            return {
                "state": String(segment.get("state", "UNCONTROLLED")),
                "faction_id": String(segment.get("faction_id", "")),
                "strongest_faction_id": String(segment.get("strongest_faction_id", "")),
                "second_faction_id": String(segment.get("second_faction_id", ""))
            }
    if not current_planet.is_empty():
        return _get_political_context_at(_system_planet_world_position(current_planet))
    return {"state": "UNCONTROLLED", "faction_id": "", "strongest_faction_id": "", "second_faction_id": ""}

func _container_owner_for_context(context: Dictionary) -> String:
    var state := String(context.get("state", "UNCONTROLLED"))
    if state == "UNCONTROLLED":
        return ""
    if state == "CONTESTED":
        var first := String(context.get("strongest_faction_id", ""))
        var second := String(context.get("second_faction_id", ""))
        if first.is_empty():
            return second
        if second.is_empty():
            return first
        return first if rng.randf() < 0.5 else second
    var owner := String(context.get("faction_id", ""))
    if owner.is_empty():
        owner = String(context.get("strongest_faction_id", ""))
    return owner

func _container_owner_for_current_space() -> String:
    return _container_owner_for_context(_current_flight_political_context())

func _make_cargo_pickup(commodity: String, quantity: int, x: float, y: float, hard: bool = false) -> Dictionary:
    var bounds := _lane_bounds(hard) if lane_event_active else Vector2(LEFT, RIGHT)
    return {
        "id": rng.randi(),
        "type": "cargo",
        "commodity": commodity,
        "quantity": maxi(1, quantity),
        "hard": hard and lane_event_active,
        "x": clampf(x, bounds.x + 16.0, bounds.y - 16.0),
        "y": y,
        "r": 13.0,
        "speed": rng.randf_range(195.0, 225.0),
        "drift": 0.0,
        "lane_min": bounds.x,
        "lane_max": bounds.y
    }

func _queue_asteroid_ore_drop(obj: Dictionary, roll: float = -1.0) -> bool:
    var use_roll := rng.randf() if roll < 0.0 else roll
    if use_roll >= ASTEROID_ORE_DROP_CHANCE:
        return false
    pending_drops.append(_make_cargo_pickup("Ore", 1, float(obj.x), float(obj.y), bool(obj.get("hard", false))))
    return true

func _basic_container_commodity() -> String:
    return commodity_names[rng.randi_range(0, commodity_names.size() - 1)]

func _reinforced_container_commodity() -> String:
    var premium := ["Electronics", "Arms", "Medicine", "Narcotics", "Fuel", "Ore"]
    return String(premium[rng.randi_range(0, premium.size() - 1)])

func _queue_container_loot(obj: Dictionary) -> int:
    var kind := int(obj.get("kind", 1))
    var bundles := 2 if kind == 2 else 1
    var total_units := 0
    for bundle_index in bundles:
        var commodity := _reinforced_container_commodity() if kind == 2 else _basic_container_commodity()
        var quantity := rng.randi_range(1, 2) if kind == 1 else rng.randi_range(2, 3)
        total_units += quantity
        var spread := float(bundle_index) * 18.0 - float(bundles - 1) * 9.0
        pending_drops.append(_make_cargo_pickup(
            commodity,
            quantity,
            float(obj.x) + spread,
            float(obj.y),
            bool(obj.get("hard", false))
        ))
    return total_units

func _handle_container_break(obj: Dictionary) -> void:
    _queue_container_loot(obj)
    var owner := String(obj.get("owner_faction", ""))
    if not owner.is_empty():
        var loss := REINFORCED_CONTAINER_RELATION_LOSS if int(obj.get("kind", 1)) == 2 else BASIC_CONTAINER_RELATION_LOSS
        _record_faction_crime(owner, loss, 0, "reinforced_container_theft" if int(obj.get("kind", 1)) == 2 else "container_theft", false)
        _save_privateer_state()

func _collect_cargo_pickup(obj: Dictionary) -> int:
    var free := maxi(0, _cargo_capacity() - _cargo_used())
    if free <= 0:
        loot_banner_text = "CARGO FULL"
        loot_banner_timer = 0.9
        return 0
    var commodity := String(obj.get("commodity", "Ore"))
    if not cargo.has(commodity):
        cargo[commodity] = 0
    var available := maxi(1, int(obj.get("quantity", 1)))
    var taken := mini(free, available)
    cargo[commodity] = int(cargo.get(commodity, 0)) + taken
    obj["quantity"] = available - taken
    loot_banner_text = "%s +%d" % [commodity.to_upper(), taken]
    loot_banner_timer = 1.1
    _save_privateer_state()
    return taken

func _enemy_body_speed_multiplier(kind: int) -> float:
    if kind == 1:
        return 1.04
    return 1.0

func _spawn_hazard(difficulty: float, hard_lane: bool, lane_mode: bool = true) -> void:
    var kind := _choose_enemy_kind(hard_lane and lane_mode)
    var radius := rng.randf_range(17.0, 26.0)
    var base_speed := rng.randf_range(185.0, 235.0) + difficulty * 95.0
    if level == 1:
        base_speed = rng.randf_range(155.0, 185.0)

    var lane_speed_mult := 1.0
    if lane_mode:
        lane_speed_mult = 1.10 if hard_lane else 0.92

    var speed := base_speed * lane_speed_mult
    var bounds := _lane_bounds(hard_lane) if lane_mode else Vector2(LEFT, RIGHT)
    var lane_min := bounds.x
    var lane_max := bounds.y
    var x := rng.randf_range(lane_min + radius, lane_max - radius)
    var drift := rng.randf_range(-5.0, 5.0)
    var shoot_clock := 999.0

    if kind == 1:
        radius = rng.randf_range(15.0, 19.0)
        drift = 0.0
    elif kind == 2:
        radius = rng.randf_range(15.0, 18.0)
        speed *= 0.96
        drift = 0.0
    elif kind == 3:
        radius = rng.randf_range(14.0, 18.0)
        speed *= 0.58
        drift = rng.randf_range(-12.0, 12.0)
        shoot_clock = rng.randf_range(1.1, 1.7)
    elif kind == 4:
        radius = rng.randf_range(20.0, 24.0)
        speed = 170.0
        drift = 0.0
        shoot_clock = rng.randf_range(0.9, 1.4)

    var obstacle_hp := _obstacle_max_hp(kind)
    var owner_faction := _container_owner_for_current_space() if kind == 1 or kind == 2 else ""
    var territory_state := String(_current_flight_political_context().get("state", "UNCONTROLLED")) if kind == 1 or kind == 2 else ""
    var encounter_role := encounter_mode if kind == 3 or kind == 4 else ""
    var ship_faction := encounter_faction_id if encounter_role == "police" else ""
    var ship_hostile := encounter_role == "pirate" or (encounter_role == "police" and encounter_hostile) or bool(false)
    objects.append({
        "id": rng.randi(),
        "type": "hazard",
        "kind": kind,
        "hp": obstacle_hp,
        "max_hp": obstacle_hp,
        "hard": hard_lane and lane_mode,
        "x": x,
        "y": -40.0,
        "r": radius,
        "speed": speed,
        "drift": drift,
        "shoot_clock": shoot_clock,
        "angle": rng.randf_range(0.0, TAU),
        "spin": rng.randf_range(-0.18, 0.18) if kind == 0 else 0.0,
        "lane_speed_mult": lane_speed_mult,
        "lane_min": lane_min,
        "lane_max": lane_max,
        "owner_faction": owner_faction,
        "territory_state": territory_state,
        "encounter_role": encounter_role,
        "encounter_faction_id": ship_faction,
        "hostile": ship_hostile
    })

func _ship_is_hostile(obj: Dictionary) -> bool:
    if bool(obj.get("boss", false)):
        return true
    var role := String(obj.get("encounter_role", ""))
    if role == "pirate":
        return true
    if role == "police":
        var faction_id := String(obj.get("encounter_faction_id", ""))
        if not faction_id.is_empty() and _police_hostile_eligible(faction_id):
            return true
        return bool(obj.get("hostile", false))
    # Legacy/non-route combat objects retain their historical hostile behavior.
    return int(obj.get("kind", 0)) == 3 or int(obj.get("kind", 0)) == 4

func _player_can_damage_hazard(obj: Dictionary) -> bool:
    var kind := int(obj.get("kind", 0))
    if kind != 3 and kind != 4:
        return true
    if bool(obj.get("boss", false)):
        return true
    if String(obj.get("encounter_role", "")) == "police":
        return _ship_is_hostile(obj)
    return true

func _handle_enforcement_kill(obj: Dictionary) -> void:
    if String(obj.get("encounter_role", "")) != "police":
        return
    var faction_id := String(obj.get("encounter_faction_id", ""))
    if faction_id.is_empty():
        return
    var heavy := int(obj.get("kind", 3)) == 4
    var relation_loss := HEAVY_ENFORCEMENT_KILL_RELATION_LOSS if heavy else POLICE_SHIP_KILL_RELATION_LOSS
    var heat_gain := HEAVY_ENFORCEMENT_KILL_HEAT_GAIN if heavy else POLICE_SHIP_KILL_HEAT_GAIN
    var offense := "heavy_enforcement_destroyed" if heavy else "police_ship_destroyed"
    _record_faction_crime(faction_id, relation_loss, heat_gain, offense, false)
    encounter_hostile = true
    _save_privateer_state()

func _weapon_interval() -> float:
    match current_weapon:
        "none":
            return 0.5
        "single":
            return SINGLE_INTERVAL
        "dual":
            return DUAL_INTERVAL
        "cone":
            return CONE_INTERVAL
        "seeker":
            return SEEKER_INTERVAL
        "laser":
            return LASER_INTERVAL
    return SINGLE_INTERVAL

func _weapon_damage(weapon: String) -> float:
    match weapon:
        "none":
            return 0.0
        "single":
            return SINGLE_DAMAGE
        "dual":
            return DUAL_DAMAGE
        "cone":
            return CONE_DAMAGE
        "seeker":
            return SEEKER_DAMAGE
        "laser":
            return LASER_DPS
    return SINGLE_DAMAGE

func _weapon_label(weapon: String) -> String:
    match weapon:
        "none":
            return "NO WEAPON"
        "single":
            return "SINGLE D1"
        "dual":
            return "DUAL D1x2"
        "cone":
            return "CONE D3x3"
        "seeker":
            return "SEEKER D7"
        "laser":
            return "LASER 3 DPS"
    return "SINGLE D1"

func _weapon_icon(weapon: String) -> String:
    match weapon:
        "none":
            return "-"
        "single":
            return "1"
        "dual":
            return "2"
        "cone":
            return "C"
        "seeker":
            return "H"
        "laser":
            return "L"
    return "?"

func _obstacle_max_hp(kind: int) -> float:
    match kind:
        0:
            return 3.0
        1:
            return 4.0
        2:
            return 12.0
        3:
            return 4.0
        4:
            return 20.0
    return 3.0

func _kill_score(kind: int) -> int:
    match kind:
        3:
            return 4
        4:
            return 7
    return 0


func _spawn_shot(x: float, y: float, vx: float, vy: float, damage: float, homing: bool = false) -> void:
    shots.append({
        "x": x,
        "y": y,
        "vx": vx,
        "vy": vy,
        "r": SHOT_RADIUS,
        "damage": damage,
        "homing": homing
    })

func _fire_weapon() -> void:
    if not playing:
        return
    match current_weapon:
        "none":
            pass
        "single":
            _spawn_shot(player_x, player_y - 22.0, 0.0, -690.0, SINGLE_DAMAGE * _damage_multiplier())
            _play_sfx(shot_sfx, rng.randf_range(0.97, 1.03), -5.0)
        "dual":
            _spawn_shot(player_x - 10.0, player_y - 20.0, 0.0, -650.0, DUAL_DAMAGE * _damage_multiplier())
            _spawn_shot(player_x + 10.0, player_y - 20.0, 0.0, -650.0, DUAL_DAMAGE * _damage_multiplier())
            _play_sfx(dual_sfx, rng.randf_range(0.98, 1.04), -5.0)
        "cone":
            _spawn_shot(player_x, player_y - 22.0, -145.0, -520.0, CONE_DAMAGE * _damage_multiplier())
            _spawn_shot(player_x, player_y - 24.0, 0.0, -560.0, CONE_DAMAGE * _damage_multiplier())
            _spawn_shot(player_x, player_y - 22.0, 145.0, -520.0, CONE_DAMAGE * _damage_multiplier())
            _play_sfx(cone_sfx, rng.randf_range(0.96, 1.02), -3.0)
        "seeker":
            _spawn_shot(player_x, player_y - 24.0, 0.0, -370.0, SEEKER_DAMAGE * _damage_multiplier(), true)
            _play_sfx(seeker_sfx, rng.randf_range(0.97, 1.03), -3.0)
        "laser":
            pass

func _nearest_hazard_position(from_pos: Vector2) -> Vector2:
    var best := Vector2(from_pos.x, -40.0)
    var best_d := INF
    for obj in objects:
        if obj.type != "hazard":
            continue
        if not _player_can_damage_hazard(obj):
            continue
        var p := Vector2(float(obj.x), float(obj.y))
        if p.y >= from_pos.y:
            continue
        var d := from_pos.distance_squared_to(p)
        if d < best_d:
            best_d = d
            best = p
    return best

func _move_shots(delta: float) -> void:
    var next: Array[Dictionary] = []
    for shot in shots:
        if shot.homing:
            var pos := Vector2(float(shot.x), float(shot.y))
            var target := _nearest_hazard_position(pos)
            var desired := (target - pos).normalized() * 430.0
            shot.vx = lerpf(float(shot.vx), desired.x, minf(1.0, delta * 4.5))
            shot.vy = lerpf(float(shot.vy), desired.y, minf(1.0, delta * 4.5))
        shot.x += float(shot.vx) * delta
        shot.y += float(shot.vy) * delta

        var blocked := false
        if lane_event_active:
            var point := Vector2(shot.x, shot.y)
            for barrier in _station_barrier_rects():
                if barrier.has_point(point):
                    blocked = true
                    break
        if not blocked and shot.y > -45.0 and shot.y < H + 40.0 and shot.x > -40.0 and shot.x < W + 40.0:
            next.append(shot)
    shots = next

func _apply_damage_to_hazard(obj: Dictionary, damage: float) -> bool:
    obj.hp = maxf(0.0, float(obj.hp) - damage)
    if float(obj.hp) <= 0.0:
        var kind := int(obj.kind)
        var kill_value := _kill_score(kind)
        if kill_value > 0:
            score += int(round(float(kill_value) * _lane_score_multiplier()))

        if kind == 0:
            _queue_asteroid_ore_drop(obj)
        elif kind == 1 or kind == 2:
            _handle_container_break(obj)
        elif bool(obj.get("boss", false)):
            boss_defeated_pending = true
        else:
            if kind == 3 or kind == 4:
                _handle_enforcement_kill(obj)
            _queue_kill_drop(obj)

        _burst(Vector2(obj.x, obj.y), 10, Color("ffd166"))
        _play_sfx(kill_sfx, rng.randf_range(0.92, 1.08), -3.0)
        return true
    if damage >= 1.0:
        _burst(Vector2(obj.x, obj.y), 3, Color("fff4c2"))
    return false


func _consume_shot_hit(obj: Dictionary) -> bool:
    if not _player_can_damage_hazard(obj):
        return false
    for i in range(shots.size() - 1, -1, -1):
        var shot: Dictionary = shots[i]
        var dx := absf(float(shot.x) - float(obj.x))
        var dy := absf(float(shot.y) - float(obj.y))
        if dx < float(obj.r) + float(shot.r) and dy < float(obj.r) + float(shot.r):
            var damage := float(shot.damage)
            shots.remove_at(i)
            return _apply_damage_to_hazard(obj, damage)
    return false


func _apply_laser_damage(delta: float) -> void:
    if current_weapon != "laser" or not playing:
        return
    var target_index := -1
    var target_y := -INF
    for i in objects.size():
        var obj: Dictionary = objects[i]
        if obj.type != "hazard":
            continue
        if not _player_can_damage_hazard(obj):
            continue
        if float(obj.y) >= player_y:
            continue
        if absf(float(obj.x) - player_x) > float(obj.r) + 4.0:
            continue
        if float(obj.y) > target_y:
            target_y = float(obj.y)
            target_index = i
    if target_index < 0:
        return
    var target: Dictionary = objects[target_index]
    if laser_sfx_clock <= 0.0:
        _play_sfx(laser_sfx, rng.randf_range(0.98, 1.03), -8.0)
        laser_sfx_clock = 0.12
    if _apply_damage_to_hazard(target, LASER_DPS * _damage_multiplier() * delta):
        objects.remove_at(target_index)
        _flush_pending_drops(objects)

func _spawn_weapon_pickup() -> void:
    var choices: Array[String] = ["single", "dual", "cone", "seeker", "laser"]
    choices.erase(current_weapon)
    var weapon: String = choices[rng.randi_range(0, choices.size() - 1)]
    var hard_lane := lane_event_active and rng.randf() < 0.5
    var bounds := _lane_bounds(hard_lane) if lane_event_active else Vector2(LEFT, RIGHT)
    objects.append({
        "id": rng.randi(),
        "type": "weapon",
        "weapon": weapon,
        "hard": false,
        "x": rng.randf_range(bounds.x + 18.0, bounds.y - 18.0),
        "y": -34.0,
        "r": 14.0,
        "speed": rng.randf_range(210.0, 245.0),
        "drift": rng.randf_range(-10.0, 10.0),
        "lane_min": bounds.x,
        "lane_max": bounds.y
    })

func _fire_enemy_shot(obj: Dictionary) -> void:
    var from_pos := Vector2(float(obj.x), float(obj.y) + float(obj.r))
    var to_player := Vector2(player_x, player_y) - from_pos
    if to_player.length() < 1.0:
        to_player = Vector2.DOWN
    var velocity := to_player.normalized() * ENEMY_SHOT_SPEED
    enemy_shots.append({
        "type": "bolt",
        "x": from_pos.x,
        "y": from_pos.y,
        "vx": velocity.x,
        "vy": velocity.y,
        "r": ENEMY_SHOT_RADIUS,
        "damage": 1,
        "homing": false
    })
    _play_sfx(enemy_shot_sfx, rng.randf_range(0.94, 1.06), -7.0)

func _fire_enemy_missile(obj: Dictionary) -> void:
    var from_pos := Vector2(float(obj.x), float(obj.y) + float(obj.r))
    var to_player := Vector2(player_x, player_y) - from_pos
    if to_player.length() < 1.0:
        to_player = Vector2.DOWN
    var velocity := to_player.normalized() * ENEMY_MISSILE_SPEED
    enemy_shots.append({
        "type": "missile",
        "x": from_pos.x,
        "y": from_pos.y,
        "vx": velocity.x,
        "vy": velocity.y,
        "r": ENEMY_MISSILE_RADIUS,
        "damage": ENEMY_MISSILE_DAMAGE,
        "homing": true
    })
    _play_sfx(missile_sfx, rng.randf_range(0.96, 1.04), -4.0)

func _move_enemy_shots(delta: float) -> void:
    var next: Array[Dictionary] = []
    for shot in enemy_shots:
        if bool(shot.get("homing", false)):
            var pos := Vector2(float(shot.x), float(shot.y))
            var desired := (Vector2(player_x, player_y) - pos).normalized() * ENEMY_MISSILE_SPEED
            shot.vx = lerpf(float(shot.vx), desired.x, minf(1.0, delta * ENEMY_MISSILE_TURN_RATE))
            shot.vy = lerpf(float(shot.vy), desired.y, minf(1.0, delta * ENEMY_MISSILE_TURN_RATE))

        shot.x += float(shot.vx) * delta
        shot.y += float(shot.vy) * delta

        var blocked := false
        if lane_event_active:
            var point := Vector2(float(shot.x), float(shot.y))
            for barrier in _station_barrier_rects():
                if barrier.has_point(point):
                    blocked = true
                    break
        if blocked:
            continue

        var radius := float(shot.get("r", ENEMY_SHOT_RADIUS))
        var dx := absf(float(shot.x) - player_x)
        var dy := absf(float(shot.y) - player_y)
        if dx < PLAYER_RADIUS + radius and dy < PLAYER_RADIUS + radius:
            if shield_charges > 0:
                # Any enemy projectile, including a 2-hit missile, consumes only one shield charge.
                shield_charges -= 1
                _burst(Vector2(shot.x, shot.y), 12, Color("77f7ff"))
                _play_sfx(shield_sfx, 1.0, -2.0)
            elif invuln <= 0.0:
                _take_hit(int(shot.get("damage", 1)))
                _burst(Vector2(shot.x, shot.y), 8 if bool(shot.get("homing", false)) else 6, Color("ff8f5b") if bool(shot.get("homing", false)) else Color("d48cff"))
            continue

        if shot.y < H + 40.0 and shot.y > -40.0 and shot.x > -40.0 and shot.x < W + 40.0:
            next.append(shot)
    enemy_shots = next

func _energy_spawn_interval() -> float:
    var interval := maxf(0.85, 2.8 - float(level - 1) * 0.18)
    if lane_event_active:
        interval *= 0.82
    return interval * rng.randf_range(0.88, 1.14)

func _make_energy_orb(x: float, y: float, hard: bool = false) -> Dictionary:
    var bounds := _lane_bounds(hard) if lane_event_active else Vector2(LEFT, RIGHT)
    return {
        "id": rng.randi(),
        "type": "energy",
        "hard": hard and lane_event_active,
        "x": clampf(x, bounds.x + 16.0, bounds.y - 16.0),
        "y": y,
        "r": 12.0,
        "speed": rng.randf_range(215.0, 255.0),
        "drift": rng.randf_range(-10.0, 10.0),
        "lane_min": bounds.x,
        "lane_max": bounds.y
    }

func _make_repair_pickup(x: float, y: float) -> Dictionary:
    return {
        "id": rng.randi(),
        "type": "repair",
        "hard": false,
        "x": clampf(x, LEFT + 16.0, RIGHT - 16.0),
        "y": y,
        "r": 14.0,
        "speed": rng.randf_range(205.0, 235.0),
        "drift": rng.randf_range(-8.0, 8.0),
        "lane_min": LEFT,
        "lane_max": RIGHT
    }

func _kill_drop_kind(roll: float) -> String:
    if roll < KILL_REPAIR_DROP_CHANCE:
        return "repair"
    if roll < KILL_REPAIR_DROP_CHANCE + KILL_ORB_DROP_CHANCE:
        return "energy"
    return ""

func _queue_kill_drop(obj: Dictionary) -> void:
    var drop_kind := _kill_drop_kind(rng.randf())
    if drop_kind == "repair":
        pending_drops.append(_make_repair_pickup(float(obj.x), float(obj.y)))
    elif drop_kind == "energy":
        pending_drops.append(_make_energy_orb(float(obj.x), float(obj.y), bool(obj.get("hard", false))))

func _flush_pending_drops(target: Array[Dictionary]) -> void:
    if pending_drops.is_empty():
        return
    for drop in pending_drops:
        target.append(drop)
    pending_drops.clear()

func _spawn_repair() -> void:
    if hp >= max_hp:
        return
    var lane_hard := lane_event_active and rng.randf() < 0.5
    var bounds := _lane_bounds(lane_hard) if lane_event_active else Vector2(LEFT, RIGHT)
    var x := rng.randf_range(bounds.x + 18.0, bounds.y - 18.0)
    objects.append(_make_repair_pickup(x, -34.0))

func _spawn_pickup() -> void:
    var hard_lane := lane_event_active and rng.randf() < 0.82
    var bounds := _lane_bounds(hard_lane) if lane_event_active else Vector2(LEFT, RIGHT)
    var x := rng.randf_range(bounds.x + 16.0, bounds.y - 16.0)
    objects.append(_make_energy_orb(x, -30.0, hard_lane))

func _begin_finale() -> void:
    finale_active = true
    finale_banner_timer = 2.4
    hard_spawn_clock = minf(hard_spawn_clock, 0.16)
    easy_spawn_clock = minf(easy_spawn_clock, 0.28)
    shake = maxf(shake, 2.0)
    _play_sfx(finale_sfx)

func _spawn_extraction_gate() -> void:
    extraction_spawned = true
    var gate_right := rng.randf() < 0.5
    extraction_lane = "RIGHT" if gate_right else "LEFT"
    var x := (RIGHT_LANE_MIN + RIGHT_LANE_MAX) * 0.5 if gate_right else (LEFT_LANE_MIN + LEFT_LANE_MAX) * 0.5
    objects.append({
        "id": rng.randi(),
        "type": "extraction",
        "x": x,
        "y": -80.0,
        "r": 0.0,
        "speed": 120.0,
        "drift": 0.0,
        "half_width": 55.0
    })
    finale_banner_timer = 2.8
    _play_sfx(finale_sfx)

func _incoming_shot_dodge_direction(obj: Dictionary) -> float:
    var obj_y := float(obj.y)
    var obj_x := float(obj.x)
    var radius := float(obj.r)
    for shot in shots:
        var vy := float(shot.vy)
        if vy >= -1.0:
            continue
        var shot_y := float(shot.y)
        if shot_y <= obj_y or shot_y - obj_y > 190.0:
            continue
        var time_to_y := (shot_y - obj_y) / -vy
        if time_to_y < 0.0 or time_to_y > 0.55:
            continue
        var projected_x := float(shot.x) + float(shot.vx) * time_to_y
        if absf(projected_x - obj_x) <= radius + 14.0:
            return 1.0 if projected_x <= obj_x else -1.0
    return 0.0

func _move_objects(delta: float) -> void:
    var next: Array[Dictionary] = []
    for obj in objects:
        var motion_y := float(obj.speed)

        if obj.type == "hazard":
            var kind := int(obj.kind)
            if obj.has("angle"):
                obj.angle = float(obj.angle) + float(obj.get("spin", 0.0)) * delta

            if kind == 0:
                obj.drift = lerpf(float(obj.drift), 0.0, minf(1.0, delta * 0.20))

            elif kind == 1 or kind == 2:
                # Cargo containers have no self-propelled lateral movement.
                obj.drift = 0.0

            elif kind == 3:
                var hostile_ship := _ship_is_hostile(obj)
                obj["hostile"] = hostile_ship
                if hostile_ship:
                    var dodge_dir := _incoming_shot_dodge_direction(obj)
                    var trapezoid_target := clampf((player_x - float(obj.x)) * 0.14, -28.0, 28.0)
                    if dodge_dir != 0.0:
                        trapezoid_target = dodge_dir * 72.0
                    obj.drift = lerpf(float(obj.drift), trapezoid_target, minf(1.0, delta * 2.4))

                    var preferred_y := player_y - 245.0
                    var y_error := preferred_y - float(obj.y)
                    if y_error > 55.0:
                        motion_y = minf(72.0, float(obj.speed))
                    elif y_error < -45.0:
                        motion_y = -58.0
                    else:
                        motion_y = clampf(y_error * 0.30, -28.0, 28.0)

                    obj.shoot_clock = float(obj.shoot_clock) - delta
                    if float(obj.shoot_clock) <= 0.0 and float(obj.y) > 45.0 and float(obj.y) < player_y - 75.0:
                        _fire_enemy_shot(obj)
                        obj.shoot_clock = rng.randf_range(1.45, 2.10)
                else:
                    # Lawful patrol traffic passes through without tracking, dodging or firing.
                    obj.drift = lerpf(float(obj.drift), 0.0, minf(1.0, delta * 1.8))
                    motion_y = float(obj.speed)

            elif kind == 4:
                obj.drift = 0.0
                if bool(obj.get("boss", false)):
                    motion_y = 0.0
                else:
                    # Heavy enforcement platforms are fixed in world-space and scroll past with the route.
                    motion_y = float(obj.speed)
                var hostile_platform := _ship_is_hostile(obj)
                obj["hostile"] = hostile_platform
                if hostile_platform:
                    obj.shoot_clock = float(obj.shoot_clock) - delta
                    if float(obj.shoot_clock) <= 0.0 and float(obj.y) > 55.0 and float(obj.y) < player_y - 85.0:
                        _fire_enemy_missile(obj)
                        var boss_rate := maxf(0.65, 1.55 - float(active_contract.get("difficulty", 1)) * 0.12) if bool(obj.get("boss", false)) else rng.randf_range(1.8, 2.5)
                        obj.shoot_clock = boss_rate

        obj.y += motion_y * delta
        obj.x += float(obj.drift) * delta

        if obj.type == "hazard" and int(obj.kind) == 3 and _ship_is_hostile(obj):
            obj.y = minf(float(obj.y), player_y - float(obj.r) - 12.0)

        if obj.type != "extraction":
            if obj.x < obj.lane_min + obj.r or obj.x > obj.lane_max - obj.r:
                obj.drift *= -1.0
                obj.x = clampf(obj.x, obj.lane_min + obj.r, obj.lane_max - obj.r)

        var dy: float = obj.y - player_y
        var dx: float = absf(obj.x - player_x)

        if obj.type == "hazard":
            var collision_kind := int(obj.kind)
            if _consume_shot_hit(obj):
                continue
            var hit_dist: float = obj.r + 14.0
            var collision_threat := collision_kind < 3 or _ship_is_hostile(obj)
            if collision_threat and absf(dy) < hit_dist and dx < hit_dist:
                if invuln <= 0.0:
                    _take_hit(1)
                    _burst(Vector2(player_x, player_y), 13, Color("ff426f"))
                # Physical collision hurts only the player. Enemy survives unchanged.


            var near_dist: float = obj.r + 40.0
            if collision_kind == 0 and obj.y > player_y + obj.r and not last_near_ids.has(obj.id):
                last_near_ids[obj.id] = true
                if dx < near_dist:
                    _register_near_miss()
        elif obj.type == "energy":
            if absf(dy) < obj.r + 18.0 and dx < obj.r + 20.0:
                energy += 1
                var orb_score := float(ENERGY_ORB_BASE_SCORE)
                if dash_score_timer > 0.0:
                    orb_score *= ENERGY_ORB_DASH_MULT
                orb_score *= _lane_score_multiplier()
                score += int(round(orb_score))
                combo = mini(combo + 1, 8)
                best_combo = maxi(best_combo, combo)
                _burst(Vector2(obj.x, obj.y), 9, Color("6bffb0"))
                _play_sfx(energy_sfx, 1.06 if dash_score_timer > 0.0 else 1.0, -3.0)
                continue
        elif obj.type == "repair":
            if absf(dy) < obj.r + 18.0 and dx < obj.r + 20.0:
                if hp < max_hp:
                    hp += 1
                    score += 0
                    _burst(Vector2(obj.x, obj.y), 12, Color("e8fff3"))
                    _play_sfx(repair_sfx, 1.0, -2.0)
                continue
        elif obj.type == "weapon":
            if absf(dy) < obj.r + 18.0 and dx < obj.r + 20.0:
                current_weapon = String(obj.weapon)
                fire_clock = 0.04
                weapon_banner_text = _weapon_label(current_weapon)
                weapon_banner_timer = 1.35
                score += 0
                _burst(Vector2(obj.x, obj.y), 12, Color("a882ff"))
                _play_sfx(weapon_pickup_sfx, 1.0, -2.0)
                continue
        elif obj.type == "cargo":
            if absf(dy) < obj.r + 18.0 and dx < obj.r + 20.0:
                var taken := _collect_cargo_pickup(obj)
                if taken > 0:
                    _burst(Vector2(obj.x, obj.y), 10, Color("ffd166"))
                    if int(obj.get("quantity", 0)) <= 0:
                        continue
        elif obj.type == "extraction":
            if absf(dy) < 19.0:
                if dx <= obj.half_width - 10.0:
                    _burst(Vector2(player_x, player_y), 22, Color("77f7ff"))
                    _finish(true)
                    continue
            if obj.y > player_y + 32.0:
                result_reason = "MISSED THE GATE"
                _finish(false)
                continue

        if obj.y < H + 80.0:
            next.append(obj)
    _flush_pending_drops(next)
    objects = next

func _register_near_miss() -> void:
    combo = mini(combo + 1, 8)
    best_combo = maxi(best_combo, combo)
    var dash_near := dash_score_timer > 0.0
    var near_score := 4 + int(combo / 3) if dash_near else 1 + int(combo / 4)
    near_score = maxi(1, int(round(float(near_score) * _near_miss_research_multiplier(dash_near) * _lane_score_multiplier())))
    score += near_score
    near_miss_text = ("DASH NEAR +%d" if dash_near else "NEAR +%d") % near_score
    near_miss_timer = 0.62
    slowmo_timer = 0.11
    cyan_flash = 0.13
    shake = maxf(shake, 2.8)
    dash_cooldown = maxf(0.0, dash_cooldown - 0.2)
    _burst(Vector2(player_x, player_y), 10, Color("77f7ff"))
    _play_sfx(near_sfx)

func _take_hit(amount: int = 1) -> void:
    hp -= maxi(1, amount)
    combo = 1
    invuln = HIT_INVULN_TIME
    flash = 0.22
    shake = 7.0
    _play_sfx(hit_sfx, 0.92 if amount > 1 else 1.0, -1.0)
    if hp <= 0:
        _finish(false)

func _burst(pos: Vector2, count: int, color: Color) -> void:
    for i in count:
        var a := rng.randf_range(0.0, TAU)
        var s := rng.randf_range(55.0, 160.0)
        particles.append({
            "x": pos.x,
            "y": pos.y,
            "vx": cos(a) * s,
            "vy": sin(a) * s,
            "life": rng.randf_range(0.22, 0.5),
            "max": 0.5,
            "color": color
        })

func _move_particles(delta: float) -> void:
    var next: Array[Dictionary] = []
    for p in particles:
        p.life -= delta
        p.x += p.vx * delta
        p.y += p.vy * delta
        p.vx *= 0.96
        p.vy *= 0.96
        if p.life > 0.0:
            next.append(p)
    particles = next

func _draw() -> void:
    var offset := Vector2(rng.randf_range(-shake, shake), rng.randf_range(-shake, shake)) if shake > 0.0 else Vector2.ZERO
    draw_rect(Rect2(Vector2.ZERO, Vector2(W, H)), Color("080b14"))
    _draw_background()

    if career_slots_open:
        _draw_career_slots_menu()
        return

    if profile_menu_open:
        _draw_profile_menu()
        return

    if travel_open:
        _draw_travel_menu()
        return

    if market_open:
        _draw_market_menu()
        return

    if contracts_open:
        _draw_contracts_menu()
        return

    if weapon_research_open:
        _draw_weapon_research()
        return

    if research_open:
        _draw_research()
        return

    if shop_open:
        _draw_shop()
        if run_paused:
            _draw_pause_overlay()
        return

    if not playing and not game_over:
        _draw_title()
        return

    for obj in objects:
        _draw_object(obj, offset)

    for shot in shots:
        var sp := Vector2(shot.x, shot.y) + offset
        var col := Color("ffd166") if not shot.homing else Color("ff8fa6")
        draw_line(sp - Vector2(float(shot.vx), float(shot.vy)).normalized() * -10.0, sp, col, 4.0)
        draw_circle(sp, 3.0 if not shot.homing else 5.0, Color("fff4c2"))

    for shot in enemy_shots:
        var ep := Vector2(shot.x, shot.y) + offset
        if bool(shot.get("homing", false)):
            var dir := Vector2(float(shot.vx), float(shot.vy)).normalized()
            draw_circle(ep, ENEMY_MISSILE_RADIUS + 4.0, Color(1.0, 0.35, 0.18, 0.14))
            draw_circle(ep, ENEMY_MISSILE_RADIUS, Color("ff7b45"))
            draw_line(ep - dir * 7.0, ep - dir * 16.0, Color("ffd2a6"), 3.0)
        else:
            draw_circle(ep, ENEMY_SHOT_RADIUS + 3.0, Color(0.72, 0.35, 1.0, 0.16))
            draw_circle(ep, ENEMY_SHOT_RADIUS, Color("d48cff"))

    if current_weapon == "laser" and playing:
        var laser_x := player_x + offset.x
        draw_line(Vector2(laser_x, player_y - 20.0 + offset.y), Vector2(laser_x, 0.0), Color(0.65, 0.95, 1.0, 0.78), 2.0)

    _draw_station(offset)

    for p in particles:
        var alpha: float = clampf(p.life / p.max, 0.0, 1.0)
        var pc: Color = p.color
        draw_circle(Vector2(p.x, p.y) + offset, 3.0, Color(pc.r, pc.g, pc.b, alpha))

    _draw_player(offset)
    _draw_hud()
    _draw_controls()
    _draw_pause_button()

    if lane_choice_banner_timer > 0.0 and lane_event_active:
        var choice := "STATION SPLIT — CHOOSE A LANE"
        draw_rect(Rect2(Vector2(38, 192), Vector2(314, 42)), Color(0.02, 0.04, 0.07, 0.92), true)
        _text(choice, Vector2(62, 220), 16, Color("ffd166"))

    if weapon_banner_timer > 0.0:
        draw_rect(Rect2(Vector2(68, 244), Vector2(254, 38)), Color(0.08, 0.04, 0.16, 0.9), true)
        var banner_prefix := "" if weapon_banner_text == "PIRATE CONTACT" or weapon_banner_text == "BOUNTY TARGET" or (weapon_banner_text.ends_with(" PATROL") or weapon_banner_text.ends_with(" ENFORCEMENT")) else "WEAPON: "
        _text(banner_prefix + weapon_banner_text, Vector2(82, 270), 17, Color("d4b8ff"))

    if near_miss_timer > 0.0:
        var pulse := 0.78 + sin(Time.get_ticks_msec() * 0.035) * 0.12
        _text(near_miss_text, Vector2(92, 608), 26, Color(0.47, 0.97, 1.0, pulse))

    if loot_banner_timer > 0.0:
        draw_rect(Rect2(Vector2(92, 570), Vector2(206, 30)), Color(0.10, 0.075, 0.025, 0.82), true)
        _text_center(loot_banner_text, 592.0, 14, Color("ffd166"), 92.0, 298.0)

    if finale_banner_timer > 0.0:
        var label := "EXTRACTION INBOUND"
        if extraction_spawned:
            label = "GATE: %s LANE" % extraction_lane
        _text(label, Vector2(70 if not extraction_spawned else 84, 188), 22, Color("ffd166"))

    if flash > 0.0:
        draw_rect(Rect2(Vector2.ZERO, Vector2(W, H)), Color(1.0, 0.2, 0.35, flash * 1.8))
    if cyan_flash > 0.0:
        draw_rect(Rect2(Vector2.ZERO, Vector2(W, H)), Color(0.25, 0.95, 1.0, cyan_flash * 1.5))
    if game_over:
        _draw_results()
    elif run_paused:
        _draw_pause_overlay()

func _hard_lane_background_rect() -> Rect2:
    if hard_lane_right:
        return Rect2(LANE_SPLIT, 0.0, W - LANE_SPLIT, H)
    return Rect2(0.0, 0.0, LANE_SPLIT, H)

func _draw_background() -> void:
    var t := Time.get_ticks_msec() / 1000.0

    draw_circle(Vector2(74, 170), 118.0, Color(0.10, 0.16, 0.34, 0.055))
    draw_circle(Vector2(320, 520), 150.0, Color(0.24, 0.08, 0.30, 0.035))

    if lane_event_active:
        draw_rect(_hard_lane_background_rect(), Color(0.58, 0.03, 0.08, 0.18), true)

    for i in 44:
        var layer := float(i % 4)
        var speed_factor := 0.18 + layer * 0.08
        var y := fmod(float(i) * 43.0 + world_scroll * speed_factor, H + 90.0) - 45.0
        var x := 10.0 + float((i * 83 + 37) % 370)
        var twinkle := 0.58 + sin(t * (0.7 + layer * 0.18) + float(i) * 0.9) * 0.18
        var radius := 0.8 + layer * 0.38
        var star_col := Color(0.68 + layer * 0.06, 0.78 + layer * 0.04, 1.0, 0.22 + twinkle * 0.22)
        draw_circle(Vector2(x, y), radius, star_col)

    for i in 7:
        var y2 := fmod(float(i) * 139.0 + world_scroll * 0.42, H + 120.0) - 60.0
        var x2 := 28.0 + float((i * 127 + 91) % 330)
        draw_circle(Vector2(x2, y2), 2.1, Color(0.88, 0.93, 1.0, 0.48))

func _draw_station(offset: Vector2) -> void:
    if not lane_event_active:
        return

    var y0 := station_top
    var y1 := station_top + station_height

    var metal := Color("596777")
    var metal_dark := Color("1e2833")
    var edge := Color("9aa9b8")
    var warning := Color("ffb347")

    for barrier in _station_barrier_rects():
        var shifted := Rect2(barrier.position + offset, barrier.size)
        draw_rect(shifted, metal_dark, true)
        draw_rect(shifted, metal, false, 4.0)
        var strip_y := shifted.position.y + 24.0
        while strip_y < shifted.end.y - 12.0:
            draw_line(Vector2(shifted.position.x + 4.0, strip_y), Vector2(shifted.end.x - 4.0, strip_y + 18.0), warning, 4.0)
            draw_line(Vector2(shifted.position.x + 4.0, strip_y + 18.0), Vector2(shifted.end.x - 4.0, strip_y), metal_dark, 4.0)
            strip_y += 62.0

    var panel_y := y0 + 38.0
    while panel_y < y1 - 24.0:
        draw_circle(Vector2(LANE_SPLIT, panel_y) + offset, 4.0, edge)
        panel_y += 74.0

    if _station_at_player() and not station_locked_side.is_empty():
        _text("LOCKED %s" % station_locked_side, Vector2(135, 650), 17, Color("ffd166"))

func _draw_player(offset: Vector2) -> void:
    var pos := Vector2(player_x, player_y) + offset
    var c := Color("77f7ff") if invuln <= 0.0 or int(Time.get_ticks_msec() / 90) % 2 == 0 else Color(0.4, 0.4, 0.5, 0.5)
    if dash_timer > 0.0:
        draw_line(pos + Vector2(0, 58.0), pos, Color(0.35, 0.95, 1.0, 0.42), 10.0)
    draw_circle(pos, 22.0, Color(0.2, 0.9, 1.0, 0.10))
    draw_colored_polygon(PackedVector2Array([
        pos + Vector2(0, -22),
        pos + Vector2(8, -5),
        pos + Vector2(18, 11),
        pos + Vector2(7, 8),
        pos + Vector2(0, 17),
        pos + Vector2(-7, 8),
        pos + Vector2(-18, 11),
        pos + Vector2(-8, -5)
    ]), c)
    draw_colored_polygon(PackedVector2Array([
        pos + Vector2(0, -13),
        pos + Vector2(5, 2),
        pos + Vector2(0, 8),
        pos + Vector2(-5, 2)
    ]), Color("173545"))
    draw_line(pos + Vector2(-6, 14), pos + Vector2(-6, 33), Color(0.3, 0.85, 1.0, 0.34), 3.0)
    draw_line(pos + Vector2(6, 14), pos + Vector2(6, 33), Color(0.3, 0.85, 1.0, 0.34), 3.0)
    if shield_charges > 0:
        draw_arc(pos, 27.0, -PI, PI, 40, Color("77f7ff"), 3.0)

func _draw_object(obj: Dictionary, offset: Vector2) -> void:
    var p := Vector2(obj.x, obj.y) + offset

    if obj.type == "extraction":
        var half_width: float = obj.half_width
        draw_rect(Rect2(Vector2(p.x - half_width - 12.0, p.y - 12.0), Vector2(12.0, 24.0)), Color("77f7ff"), true)
        draw_rect(Rect2(Vector2(p.x + half_width, p.y - 12.0), Vector2(12.0, 24.0)), Color("77f7ff"), true)
        draw_line(Vector2(p.x - half_width, p.y), Vector2(p.x + half_width, p.y), Color(0.45, 0.97, 1.0, 0.45), 4.0)
        draw_rect(Rect2(Vector2(p.x - half_width, p.y - 18.0), Vector2(half_width * 2.0, 36.0)), Color(0.3, 0.95, 1.0, 0.08), true)
        return

    if obj.type == "cargo":
        var cargo_r := float(obj.r)
        draw_circle(p, cargo_r + 6.0, Color(1.0, 0.75, 0.25, 0.13))
        draw_rect(Rect2(p - Vector2(cargo_r, cargo_r * 0.72), Vector2(cargo_r * 2.0, cargo_r * 1.44)), Color("9b6a2f"), true)
        draw_rect(Rect2(p - Vector2(cargo_r - 3.0, cargo_r * 0.72 - 3.0), Vector2((cargo_r - 3.0) * 2.0, cargo_r * 1.44 - 6.0)), Color("2f261c"), true)
        draw_line(p + Vector2(-cargo_r, 0), p + Vector2(cargo_r, 0), Color("ffd166"), 2.0)
        _text(String(obj.get("commodity", "Ore")).substr(0, 1).to_upper(), p + Vector2(-4, 5), 12, Color("fff4c2"))
        var qty := int(obj.get("quantity", 1))
        if qty > 1:
            _text("x%d" % qty, p + Vector2(10, 16), 9, Color("ffd166"))
        return

    if obj.type == "weapon":
        draw_circle(p, obj.r + 8.0, Color(0.66, 0.45, 1.0, 0.18))
        draw_circle(p, obj.r, Color("a882ff"))
        _text(_weapon_icon(String(obj.weapon)), p + Vector2(-5, 6), 16, Color("ffffff"))
        return

    if obj.type == "repair":
        draw_circle(p, obj.r + 7.0, Color(0.85, 1.0, 0.95, 0.14))
        draw_circle(p, obj.r, Color("d9fff2"))
        draw_rect(Rect2(p - Vector2(3.0, 9.0), Vector2(6.0, 18.0)), Color("187f68"), true)
        draw_rect(Rect2(p - Vector2(9.0, 3.0), Vector2(18.0, 6.0)), Color("187f68"), true)
        return

    if obj.type == "energy":
        var glow_alpha := 0.22 if obj.hard else 0.15
        draw_circle(p, obj.r + 9.0, Color(0.18, 1.0, 0.52, glow_alpha * 0.45))
        draw_circle(p, obj.r + 5.0, Color(0.20, 1.0, 0.60, glow_alpha))
        draw_circle(p, obj.r, Color("55e98a"))
        draw_circle(p - Vector2(3.0, 3.0), obj.r * 0.34, Color("dffff0"))
        return

    var kind := int(obj.kind)

    if kind == 0:
        var rock := PackedVector2Array()
        var angle := float(obj.get("angle", 0.0))
        for i in 10:
            var a := TAU * float(i) / 10.0 + angle
            var wobble := 0.78 + 0.18 * sin(float(obj.id % 997) * 0.013 + float(i) * 2.17)
            rock.append(p + Vector2(cos(a), sin(a)) * float(obj.r) * wobble)
        draw_colored_polygon(rock, Color("6d7278"))
        var rock_outline := rock.duplicate()
        rock_outline.append(rock[0])
        draw_polyline(rock_outline, Color("9ca2a8"), 2.0)
        var crater_a := Vector2(cos(angle + 0.8), sin(angle + 0.8)) * float(obj.r) * 0.30
        var crater_b := Vector2(cos(angle + 3.1), sin(angle + 3.1)) * float(obj.r) * 0.42
        draw_circle(p + crater_a, float(obj.r) * 0.18, Color("44484d"))
        draw_circle(p + crater_b, float(obj.r) * 0.12, Color("50545a"))

    elif kind == 1:
        var r := float(obj.r)
        draw_circle(p, r + 5.0, Color(0.25, 0.55, 0.75, 0.10))
        draw_rect(Rect2(p - Vector2(r, r), Vector2(r * 2.0, r * 2.0)), Color("526b7a"), true)
        draw_rect(Rect2(p - Vector2(r - 4.0, r - 4.0), Vector2((r - 4.0) * 2.0, (r - 4.0) * 2.0)), Color("182630"), true)
        draw_line(p + Vector2(-r, 0), p + Vector2(r, 0), Color("7894a3"), 2.0)
        draw_circle(p, 4.0, Color("7bd7ff"))

    elif kind == 2:
        var r2 := float(obj.r)
        draw_circle(p, r2 + 7.0, Color(1.0, 0.66, 0.20, 0.12))
        draw_colored_polygon(PackedVector2Array([
            p + Vector2(0, -r2 * 1.25),
            p + Vector2(r2 * 1.15, 0),
            p + Vector2(0, r2 * 1.25),
            p + Vector2(-r2 * 1.15, 0)
        ]), Color("c27a24"))
        draw_colored_polygon(PackedVector2Array([
            p + Vector2(0, -r2 * 0.65),
            p + Vector2(r2 * 0.58, 0),
            p + Vector2(0, r2 * 0.65),
            p + Vector2(-r2 * 0.58, 0)
        ]), Color("332414"))
        draw_circle(p, 4.0, Color("fff0a8"))

    elif kind == 3:
        var r3 := float(obj.r)
        var role3 := String(obj.get("encounter_role", ""))
        var body3 := Color("66527d")
        var glow3 := Color(0.70, 0.38, 1.0, 0.10)
        var accent3 := Color("c9a5ff")
        if role3 == "pirate":
            body3 = Color("7f4032")
            glow3 = Color(1.0, 0.30, 0.16, 0.12)
            accent3 = Color("ff9b68")
        elif role3 == "police":
            var police3 := _faction_color(String(obj.get("encounter_faction_id", "")))
            body3 = Color(police3.r * 0.58, police3.g * 0.58, police3.b * 0.58, 1.0)
            glow3 = Color(police3.r, police3.g, police3.b, 0.13)
            accent3 = police3
        draw_circle(p, r3 + 6.0, glow3)
        draw_colored_polygon(PackedVector2Array([
            p + Vector2(-r3 * 0.72, -r3 * 0.72),
            p + Vector2(r3 * 0.72, -r3 * 0.72),
            p + Vector2(r3 * 1.18, r3 * 0.70),
            p + Vector2(-r3 * 1.18, r3 * 0.70)
        ]), body3)
        draw_line(p + Vector2(0, 3), p + Vector2(0, r3 + 8.0), accent3, 3.0)
        draw_circle(p, 4.0, accent3)

    else:
        var r4 := float(obj.r)
        var role4 := String(obj.get("encounter_role", ""))
        var body4 := Color("88413b")
        var glow4 := Color(1.0, 0.24, 0.18, 0.10)
        var accent4 := Color("ffb27c")
        if role4 == "police":
            var police4 := _faction_color(String(obj.get("encounter_faction_id", "")))
            body4 = Color(police4.r * 0.52, police4.g * 0.52, police4.b * 0.52, 1.0)
            glow4 = Color(police4.r, police4.g, police4.b, 0.16)
            accent4 = police4
        draw_circle(p, r4 + 8.0, glow4)
        var pent := PackedVector2Array()
        for i in 5:
            var a := -PI * 0.5 + TAU * float(i) / 5.0
            pent.append(p + Vector2(cos(a), sin(a)) * r4)
        draw_colored_polygon(pent, body4)
        var inner := PackedVector2Array()
        for i in 5:
            var a2 := -PI * 0.5 + TAU * float(i) / 5.0
            inner.append(p + Vector2(cos(a2), sin(a2)) * r4 * 0.56)
        draw_colored_polygon(inner, Color("271719"))
        draw_circle(p, 5.0, accent4)
        draw_line(p + Vector2(0, 2), p + Vector2(0, r4 + 9.0), accent4, 4.0)

    if (kind == 1 or kind == 2) and not String(obj.get("owner_faction", "")).is_empty():
        var owner_color := _faction_color(String(obj.owner_faction))
        draw_arc(p, float(obj.r) + 7.0, 0.0, TAU, 24, owner_color, 2.0, true)
    if (kind == 3 or kind == 4) and String(obj.get("encounter_role", "")) == "police" and _ship_is_hostile(obj):
        draw_arc(p, float(obj.r) + 10.0, 0.0, TAU, 24, Color("ff426f"), 2.0, true)

    if obj.has("hp") and float(obj.hp) < float(obj.max_hp):
        var bw := maxf(18.0, float(obj.r) * 1.8)
        var ratio := clampf(float(obj.hp) / float(obj.max_hp), 0.0, 1.0)
        draw_rect(Rect2(Vector2(p.x - bw * 0.5, p.y + obj.r + 7.0), Vector2(bw, 3.0)), Color(0.15,0.15,0.18,0.85), true)
        draw_rect(Rect2(Vector2(p.x - bw * 0.5, p.y + obj.r + 7.0), Vector2(bw * ratio, 3.0)), Color("ffd166"), true)

func _draw_hud() -> void:
    _text("%02d" % int(maxf(0.0, _level_duration() - elapsed)), Vector2(20, 50), 30, Color("f0fbff"))
    _text("BONUS %03d CR" % score, Vector2(118, 46), 18, Color("bdeef4"))
    _text("%s > %s" % [_planet_display_name(route_origin), _planet_display_name(destination_planet)], Vector2(20, 88), 15, Color("6bffb0"))
    _text("D%d R%d" % [route_distance, route_danger], Vector2(302, 88), 16, Color("ffd166"))

    if lane_event_active:
        var left_hard := not hard_lane_right
        _text("HARD +35%" if left_hard else "EASY", Vector2(55 if left_hard else 72, 122), 15, Color("ff8fa6") if left_hard else Color("82d8e8"))
        _text("HARD +35%" if hard_lane_right else "EASY", Vector2(238 if hard_lane_right else 267, 122), 15, Color("ff8fa6") if hard_lane_right else Color("82d8e8"))
    else:
        _text("OPEN FIELD", Vector2(145, 122), 15, Color("82d8e8"))

    if boss_active:
        _text("BOUNTY BOSS", Vector2(137, 146), 16, Color("ff9a6b"))
    elif police_scan_active:
        _text("CARGO SCAN %.1fs" % police_scan_timer, Vector2(121, 146), 15, Color("ffd166"))
    elif police_scan_result_timer > 0.0 and not police_scan_result_text.is_empty():
        _text_center(police_scan_result_text, 146.0, 13, Color("ff8fa6") if police_scan_result_text.begins_with("CONTRABAND") else Color("6bffb0"), 52.0, 338.0)
    elif encounter_active and encounter_mode == "pirate":
        _text("PIRATE CONTACT", Vector2(128, 146), 15, Color("ff8fa6"))
    elif encounter_active and encounter_mode == "police":
        _text("ENFORCEMENT" if encounter_hostile else "FACTION PATROL", Vector2(126 if not encounter_hostile else 137, 146), 15, Color("ff8fa6") if encounter_hostile else _faction_color(encounter_faction_id))
    elif dash_score_timer > 0.0:
        _text("DASH BONUS", Vector2(143, 146), 16, Color("ffd166"))
    else:
        _text(_weapon_label(current_weapon), Vector2(118, 146), 14, Color("ffd166"))

    for i in max_hp:
        var c := Color("ff4f78") if i < hp else Color(0.3,0.3,0.38,0.55)
        draw_circle(Vector2(28 + i * 21, 146), 7.0, c)
    if shield_charges > 0:
        _text("SHIELD x%d" % shield_charges, Vector2(20, 199), 13, Color("77f7ff"))

    var progress := clampf(elapsed / _level_duration(), 0.0, 1.0)
    draw_rect(Rect2(Vector2(20, 169), Vector2(350, 6)), Color(0.2,0.25,0.3,0.7))
    draw_rect(Rect2(Vector2(20, 169), Vector2(350 * progress, 6)), Color("77f7ff"))

func _draw_controls() -> void:
    var move_fill := Color("102633")
    var move_border := Color("5eb7d4")
    var held_fill := Color("174759")
    var held_border := Color("77f7ff")

    draw_rect(LEFT_CONTROL_RECT, held_fill if left_control_held else move_fill, true)
    draw_rect(LEFT_CONTROL_RECT, held_border if left_control_held else move_border, false, 3.0)
    _text("LEFT", LEFT_CONTROL_RECT.position + Vector2(26, 40), 19, Color("f0fbff"))

    var ready := dash_cooldown <= 0.0
    var dash_fill := Color("123544") if ready else Color(0.12, 0.14, 0.18, 0.86)
    var dash_border := Color("77f7ff") if ready else Color(0.35, 0.42, 0.46, 0.7)
    draw_rect(DASH_RECT, dash_fill, true)
    draw_rect(DASH_RECT, dash_border, false, 3.0)
    var dash_label := "DASH" if ready else "%.1f" % dash_cooldown
    _text(dash_label, DASH_RECT.position + Vector2(26 if ready else 34, 40), 19, Color("f0fbff") if ready else Color("8ea9b8"))

    draw_rect(RIGHT_CONTROL_RECT, held_fill if right_control_held else move_fill, true)
    draw_rect(RIGHT_CONTROL_RECT, held_border if right_control_held else move_border, false, 3.0)
    _text("RIGHT", RIGHT_CONTROL_RECT.position + Vector2(20, 40), 19, Color("f0fbff"))

func _draw_profile_menu() -> void:
    _draw_menu_art(ART_BG_HUB, 0.58)
    _draw_menu_panel(Rect2(30.0, 35.0, 330.0, 625.0), 0.70)
    _text_center("NEON PRIVATEER", 92.0, 32, Color("77f7ff"), 30.0, 360.0)
    _text_center("CAREERS", 142.0, 23, Color("bdeef4"), 30.0, 360.0)

    var can_continue := last_career_slot > 0 and _career_slot_exists(last_career_slot)
    var continue_fill := Color(0.05, 0.17, 0.20, 0.93) if can_continue else Color(0.05, 0.07, 0.09, 0.93)
    var continue_border := Color("6bffb0") if can_continue else Color("46515c")
    draw_rect(PROFILE_CONTINUE_RECT, continue_fill, true)
    draw_rect(PROFILE_CONTINUE_RECT, continue_border, false, 3.0)
    _text_center("CONTINUE", PROFILE_CONTINUE_RECT.position.y + 40.0, 21, Color("f0fbff") if can_continue else Color("71808a"), PROFILE_CONTINUE_RECT.position.x, PROFILE_CONTINUE_RECT.end.x)

    draw_rect(PROFILE_NEW_RECT, Color(0.04, 0.14, 0.19, 0.93), true)
    draw_rect(PROFILE_NEW_RECT, Color("77f7ff"), false, 3.0)
    _text_center("NEW CAREER", PROFILE_NEW_RECT.position.y + 40.0, 21, Color("f0fbff"), PROFILE_NEW_RECT.position.x, PROFILE_NEW_RECT.end.x)

    draw_rect(PROFILE_LOAD_RECT, Color(0.08, 0.08, 0.18, 0.93), true)
    draw_rect(PROFILE_LOAD_RECT, Color("b56cff"), false, 3.0)
    _text_center("LOAD CAREER", PROFILE_LOAD_RECT.position.y + 40.0, 21, Color("f0fbff"), PROFILE_LOAD_RECT.position.x, PROFILE_LOAD_RECT.end.x)

    if can_continue:
        var summary := _career_slot_summary(last_career_slot)
        var location := String(summary.planet)
        if bool(summary.in_flight):
            location = "%s > %s" % [String(summary.planet), String(summary.destination)]
        _text_center("LAST: SLOT %d   %s" % [last_career_slot, location], 618.0, 14, Color("8ea9b8"), 42.0, 348.0)
        _text_center("%d CR" % int(summary.credits), 644.0, 14, Color("ffd166"), 42.0, 348.0)
    else:
        _text_center("NO CAREER SAVES YET", 626.0, 14, Color("8ea9b8"), 42.0, 348.0)

    if active_career_slot > 0:
        draw_rect(PROFILE_SLOT_BACK_RECT, Color(0.05, 0.15, 0.19, 0.94), true)
        draw_rect(PROFILE_SLOT_BACK_RECT, Color("77f7ff"), false, 2.0)
        _text_center("BACK TO CAREER", PROFILE_SLOT_BACK_RECT.position.y + 37.0, 19, Color("f0fbff"), PROFILE_SLOT_BACK_RECT.position.x, PROFILE_SLOT_BACK_RECT.end.x)
func _draw_career_slots_menu() -> void:
    _draw_menu_art(ART_BG_HUB, 0.60)
    _draw_menu_panel(Rect2(24.0, 38.0, 342.0, 615.0), 0.73)
    _text_center("NEW CAREER" if career_new_mode else "LOAD CAREER", 78.0, 30, Color("77f7ff"), 30.0, 360.0)
    _text_center("3 CAREER SLOTS", 116.0, 15, Color("8ea9b8"), 30.0, 360.0)

    for i in CAREER_SLOT_COUNT:
        var slot := i + 1
        var rect := _career_slot_rect(i)
        var summary := _career_slot_summary(slot)
        var exists := bool(summary.exists)
        var selected_warning := career_new_mode and exists and pending_overwrite_slot == slot
        var fill := Color(0.04, 0.08, 0.12, 0.92) if exists else Color(0.035, 0.055, 0.075, 0.92)
        var border := Color("ff8fa6") if selected_warning else (Color("77f7ff") if exists else Color("46515c"))
        draw_rect(rect, fill, true)
        draw_rect(rect, border, false, 3.0)

        _text("SLOT %d" % slot, rect.position + Vector2(14, 28), 20, Color("f0fbff"))
        if not exists:
            _text("EMPTY", rect.position + Vector2(14, 62), 16, Color("71808a"))
            if career_new_mode:
                _text("START NEW", rect.position + Vector2(213, 62), 14, Color("6bffb0"))
            continue

        var location := String(summary.planet)
        if bool(summary.in_flight):
            location = "IN FLIGHT > %s" % String(summary.destination)
        _text(location, rect.position + Vector2(14, 58), 15, Color("bdeef4"))
        _text("%d CR" % int(summary.credits), rect.position + Vector2(14, 86), 14, Color("ffd166"))

        if career_new_mode:
            if selected_warning:
                _text("TAP AGAIN", rect.position + Vector2(220, 48), 13, Color("ff8fa6"))
                _text("OVERWRITE", rect.position + Vector2(217, 72), 13, Color("ff8fa6"))
            else:
                _text("OVERWRITE", rect.position + Vector2(218, 62), 13, Color("ff8fa6"))
        else:
            _text("LOAD", rect.position + Vector2(257, 62), 14, Color("6bffb0"))

    draw_rect(PROFILE_SLOT_BACK_RECT, Color(0.05, 0.15, 0.19, 0.94), true)
    draw_rect(PROFILE_SLOT_BACK_RECT, Color("77f7ff"), false, 2.0)
    _text_center("BACK", PROFILE_SLOT_BACK_RECT.position.y + 37.0, 20, Color("f0fbff"), PROFILE_SLOT_BACK_RECT.position.x, PROFILE_SLOT_BACK_RECT.end.x)
func _load_privateer_ui_art() -> void:
    privateer_ui_atlas = null
    if not ResourceLoader.exists(PRIVATEER_UI_ATLAS_PATH):
        return
    var art_resource := load(PRIVATEER_UI_ATLAS_PATH)
    if art_resource is Image:
        privateer_ui_atlas = ImageTexture.create_from_image(art_resource)
    elif art_resource is Texture2D:
        privateer_ui_atlas = art_resource

func _privateer_art_ready() -> bool:
    return privateer_ui_atlas != null and privateer_ui_atlas.get_width() == 390 and privateer_ui_atlas.get_height() == 1228

func _planet_art_region(planet: String) -> Rect2:
    match _planet_visual_key(planet):
        "Cinder":
            return ART_PLANET_CINDER
        "Vesper":
            return ART_PLANET_VESPER
        "Helix":
            return ART_PLANET_HELIX
    return ART_PLANET_ASTER


func _draw_menu_art(region: Rect2, darken: float = 0.56) -> void:
    if privateer_ui_atlas != null:
        draw_texture_rect_region(
            privateer_ui_atlas,
            Rect2(Vector2.ZERO, Vector2(W, H)),
            region,
            Color.WHITE
        )
    else:
        draw_rect(Rect2(Vector2.ZERO, Vector2(W, H)), Color("080b14"), true)
    draw_rect(Rect2(Vector2.ZERO, Vector2(W, H)), Color(0.01, 0.02, 0.045, darken), true)

func _draw_planet_art(planet: String, rect: Rect2, alpha: float = 1.0) -> void:
    if privateer_ui_atlas == null:
        return
    var region := _planet_art_region(planet)
    var center := rect.get_center()
    var radius := minf(rect.size.x, rect.size.y) * 0.54
    draw_circle(center, radius, Color(0.22, 0.85, 1.0, 0.07 * alpha))
    draw_texture_rect_region(
        privateer_ui_atlas,
        rect,
        region,
        Color(1.0, 1.0, 1.0, alpha)
    )

func _draw_menu_panel(rect: Rect2, alpha: float = 0.82, border: Color = Color(0.30, 0.76, 0.90, 0.28)) -> void:
    draw_rect(rect, Color(0.018, 0.035, 0.065, alpha), true)
    draw_rect(rect, border, false, 1.5)

func _text_center(s: String, y: float, size: int, color: Color, left_x: float = 0.0, right_x: float = W) -> void:
    draw_string(ThemeDB.fallback_font, Vector2(left_x, y), s, HORIZONTAL_ALIGNMENT_CENTER, right_x - left_x, size, color)

func _draw_title() -> void:
    _draw_menu_art(ART_BG_HUB, 0.48)
    _draw_menu_panel(Rect2(24.0, 22.0, 342.0, 360.0), 0.58)

    _text_center("NEON PRIVATEER", 62.0, 30, Color("77f7ff"), 24.0, 366.0)
    _draw_planet_art(current_planet, Rect2(126.0, 78.0, 138.0, 138.0), 1.0)
    _text_center(_planet_display_name(current_planet), 244.0, 25, Color("f0fbff"), 60.0, 330.0)
    _text_center("%07d CREDITS" % research_credits, 276.0, 18, Color("ffd166"), 55.0, 335.0)
    _text_center("CARGO %d/%d   PAX %d/%d" % [_cargo_used(), _cargo_capacity(), passengers, _passenger_capacity()], 304.0, 14, Color("bdeef4"), 48.0, 342.0)
    _text_center(_planet_crime_summary(current_planet), 324.0, 10, Color("8ea9b8"), 40.0, 350.0)

    if not active_contract.is_empty():
        var ct := String(active_contract.get("type", "")).to_upper()
        var cd := String(active_contract.get("destination", ""))
        var cr := int(active_contract.get("reward", 0))
        _text_center("%s > %s  %d CR" % [ct, _planet_display_name(cd), cr], 344.0, 13, Color("6bffb0"), 38.0, 352.0)
    else:
        _text_center("NO ACTIVE CONTRACT", 344.0, 13, Color("8ea9b8"), 38.0, 352.0)

    _text_center(last_trip_summary, 370.0, 11, Color("8ea9b8"), 35.0, 355.0)
    _text("CAREER %d" % active_career_slot, Vector2(292, 38), 11, Color("8ea9b8"))

    var labels := ["TRAVEL", "MARKET", "CONTRACTS", "SHIP UPGRADES"]
    for i in 4:
        var rect := _hub_button_rect(i)
        draw_rect(rect, Color(0.04, 0.12, 0.17, 0.91), true)
        draw_rect(rect, Color("77f7ff") if i != 2 else Color("6bffb0"), false, 3.0)
        _text_center(labels[i], rect.position.y + 38.0, 21, Color("f0fbff"), rect.position.x, rect.end.x)

    draw_rect(HUB_CAREERS_RECT, Color(0.07, 0.08, 0.16, 0.92), true)
    draw_rect(HUB_CAREERS_RECT, Color("b56cff"), false, 3.0)
    _text_center("CAREERS", HUB_CAREERS_RECT.position.y + 38.0, 20, Color("f0fbff"), HUB_CAREERS_RECT.position.x, HUB_CAREERS_RECT.end.x)
func _draw_submenu_back() -> void:
    draw_rect(SUBMENU_BACK_RECT, Color(0.05, 0.15, 0.19, 0.94), true)
    draw_rect(SUBMENU_BACK_RECT, Color("77f7ff"), false, 2.0)
    _text_center("BACK", SUBMENU_BACK_RECT.position.y + 37.0, 20, Color("f0fbff"), SUBMENU_BACK_RECT.position.x, SUBMENU_BACK_RECT.end.x)
func _draw_travel_menu() -> void:
    _draw_menu_art(ART_BG_OPS, 0.78)
    _draw_menu_panel(Rect2(16.0, 14.0, 358.0, 78.0), 0.80)
    _text_center("SYSTEM MAP", 50.0, 27, Color("77f7ff"), 24.0, 366.0)
    _text_center("CURRENT: %s" % _planet_display_name(current_planet).to_upper(), 76.0, 12, Color("bdeef4"), 24.0, 366.0)

    draw_rect(SYSTEM_MAP_RECT, Color(0.004, 0.012, 0.030, 0.90), true)
    draw_rect(SYSTEM_MAP_RECT, Color(0.25, 0.78, 0.96, 0.30), false, 1.5)

    # Slice 8 political field: sampled from the exact authoritative context query.
    # This intentionally uses a coarse field rather than pretending borders are perfect polygons.
    _draw_political_map_overlay()

    # System primary at logical origin.
    var star := _map_world_to_screen(Vector2.ZERO)
    if SYSTEM_MAP_RECT.grow(40.0).has_point(star):
        draw_circle(star, 18.0, Color(1.0, 0.68, 0.20, 0.08))
        draw_circle(star, 11.0, Color("ffd166"))
        draw_circle(star, 5.0, Color("fff4c2"))

    # Resolve each highlighted path once per draw. With ~50 lanes this avoids
    # rerunning shortest-path search for every line segment on phone/browser.
    var selected_path: Array = _route_spec(current_planet, travel_selected_planet).get("path", []) if not travel_selected_planet.is_empty() else []
    var contract_path: Array = _route_spec(current_planet, String(active_contract.get("destination", ""))).get("path", []) if not active_contract.is_empty() else []

    # Every generated trade lane is drawn segment-by-segment from the same political data gameplay queries.
    for route in political_world.get("routes", []):
        var origin := String(route.a)
        var dest := String(route.b)
        var wa := _system_planet_world_position(origin)
        var wb := _system_planet_world_position(dest)
        var on_selected_path := false
        for i in range(maxi(0, selected_path.size() - 1)):
            if (String(selected_path[i]) == origin and String(selected_path[i + 1]) == dest) or (String(selected_path[i]) == dest and String(selected_path[i + 1]) == origin):
                on_selected_path = true
                break
        var on_contract_path := false
        for i in range(maxi(0, contract_path.size() - 1)):
            if (String(contract_path[i]) == origin and String(contract_path[i + 1]) == dest) or (String(contract_path[i]) == dest and String(contract_path[i + 1]) == origin):
                on_contract_path = true
                break

        for segment in route.get("segments", []):
            var t0 := float(segment.start_t)
            var t1 := float(segment.end_t)
            var a := _map_world_to_screen(wa.lerp(wb, t0))
            var b := _map_world_to_screen(wa.lerp(wb, t1))
            var state := String(segment.state)
            var faction_id := String(segment.get("faction_id", segment.get("strongest_faction_id", "")))
            var rc := _territory_color(state, faction_id)
            var alpha := 0.92 if on_selected_path else (0.72 if on_contract_path else 0.43)
            var width := 4.0 if on_selected_path else (2.8 if on_contract_path else 1.5)
            draw_line(a, b, Color(0.0, 0.0, 0.0, 0.72), width + 2.2, true)
            draw_line(a, b, Color(rc.r, rc.g, rc.b, alpha), width, true)

    # Planet nodes.
    for planet in planet_names:
        var center := _system_planet_position(planet)
        if not SYSTEM_MAP_RECT.grow(52.0).has_point(center):
            continue
        var is_current := planet == current_planet
        var is_selected := planet == travel_selected_planet
        var is_contract := _contract_target_matches(planet)
        var record := PoliticalWorld.planet_record(political_world, planet)
        var context := _get_political_context_at(Vector2(record.pos))
        var faction_id := String(context.get("faction_id", context.get("strongest_faction_id", "")))
        var portrait_size := clampf(25.0 + system_map_zoom * 5.0, 30.0, 43.0)
        if is_selected or is_current:
            portrait_size += 5.0
        var portrait_rect := Rect2(center - Vector2.ONE * portrait_size * 0.5, Vector2.ONE * portrait_size)

        if is_selected:
            draw_circle(center, portrait_size * 0.72, Color(0.47, 0.97, 1.0, 0.11))
            draw_arc(center, portrait_size * 0.70, 0.0, TAU, 32, Color("77f7ff"), 2.0, true)
        if is_current:
            draw_arc(center, portrait_size * 0.61, 0.0, TAU, 32, Color("ffd166"), 2.5, true)
        if is_contract:
            draw_arc(center, portrait_size * 0.82, 0.0, TAU, 32, Color("6bffb0"), 1.8, true)

        _draw_planet_art(planet, portrait_rect, 1.0)

        var is_capital := false
        for faction in political_world.get("factions", []):
            if String(faction.capital_id) == planet:
                is_capital = true
                var fc := Color(faction.color)
                draw_arc(center, portrait_size * 0.92, 0.0, TAU, 32, fc, 2.0, true)
                break

        var show_label := system_map_zoom >= 1.25 or is_current or is_selected or is_contract or is_capital
        if show_label:
            var label_color := Color("ffd166") if is_current else (Color("6bffb0") if is_contract else Color("f0fbff"))
            _text_center(_planet_display_name(planet).to_upper(), center.y + portrait_size * 0.82, 9, label_color, center.x - 58.0, center.x + 58.0)
            if is_capital:
                _text_center("CAP", center.y + portrait_size * 0.82 + 12.0, 8, _faction_color(faction_id), center.x - 34.0, center.x + 34.0)

    _draw_political_map_legend()

    draw_rect(SYSTEM_RESET_RECT, Color(0.04, 0.08, 0.12, 0.92), true)
    draw_rect(SYSTEM_RESET_RECT, Color("77f7ff"), false, 1.5)
    _text_center("CENTER", SYSTEM_RESET_RECT.position.y + 23.0, 10, Color("bdeef4"), SYSTEM_RESET_RECT.position.x, SYSTEM_RESET_RECT.end.x)

    # Route planning + political inspection card.
    _draw_menu_panel(SYSTEM_ROUTE_INFO_RECT, 0.91, Color(0.35, 0.85, 1.0, 0.34))
    var selected := travel_selected_planet if planet_names.has(travel_selected_planet) else current_planet
    _draw_planet_art(selected, Rect2(36.0, 593.0, 76.0, 74.0), 1.0)
    _text(_planet_display_name(selected).to_upper(), Vector2(126.0, 607.0), 17, Color("f0fbff"))
    _text(_planet_jurisdiction_label(selected), Vector2(126.0, 628.0), 8, Color("bdeef4"))
    var selected_factions := _planet_faction_ids(selected)
    var status_lines := _planet_political_status_lines(selected)

    var next_hop := ""
    if selected == current_planet:
        _text("DOCKED HERE", Vector2(126.0, 648.0), 12, Color("ffd166"))
        _text(_planet_law_summary(selected), Vector2(126.0, 674.0), 8, Color("bdeef4"))
        for status_index in range(status_lines.size()):
            if status_index >= 2:
                break
            var status_color := _faction_status_color(selected_factions[status_index]) if status_index < selected_factions.size() else Color("8ea9b8")
            _text(String(status_lines[status_index]), Vector2(126.0, 695.0 + float(status_index) * 13.0), 7, status_color)
        _text("TAP WORLD • DRAG/PINCH MAP", Vector2(126.0, 727.0), 8, Color("8ea9b8"))
    else:
        var selected_spec := _route_spec(current_planet, selected)
        next_hop = _next_hop_toward(selected)
        var contract_diff := int(active_contract.get("difficulty", 0)) if _contract_target_matches(selected) else 0
        var selected_level := _route_level_for(int(selected_spec.distance), int(selected_spec.danger), contract_diff)
        var selected_duration := _route_duration_for(int(selected_spec.distance), int(selected_spec.danger), contract_diff)
        var pct := _route_political_percentages(current_planet, selected)
        _text("D%d  W%d  RISK %s  HOPS %d" % [int(selected_spec.distance), int(selected_spec.get("wealth", 1)), _political_risk_label(int(selected_spec.danger)), int(selected_spec.hops)], Vector2(126.0, 646.0), 9, _system_route_color(int(selected_spec.danger)))
        _text("C%d%%  X%d%%  U%d%%" % [int(round(float(pct.CONTROLLED + pct.CORE) * 100.0)), int(round(float(pct.CONTESTED) * 100.0)), int(round(float(pct.UNCONTROLLED) * 100.0))], Vector2(126.0, 662.0), 9, Color("8ea9b8"))
        _text("FLIGHT %ds  L%d  NEXT %s" % [int(selected_duration), selected_level, _planet_display_name(next_hop).to_upper()], Vector2(126.0, 678.0), 9, Color("ffd166"))
        _text(_planet_law_summary(selected), Vector2(126.0, 697.0), 7, Color("bdeef4"))
        for status_index in range(status_lines.size()):
            if status_index >= 2:
                break
            var status_color := _faction_status_color(selected_factions[status_index]) if status_index < selected_factions.size() else Color("8ea9b8")
            _text(String(status_lines[status_index]), Vector2(126.0, 712.0 + float(status_index) * 13.0), 7, status_color)
        if _contract_target_matches(selected):
            _text("CONTRACT", Vector2(306.0, 628.0), 7, Color("6bffb0"))

    draw_rect(SYSTEM_MAP_BACK_RECT, Color(0.04, 0.10, 0.14, 0.95), true)
    draw_rect(SYSTEM_MAP_BACK_RECT, Color("77f7ff"), false, 2.0)
    _text_center("BACK", SYSTEM_MAP_BACK_RECT.position.y + 35.0, 18, Color("f0fbff"), SYSTEM_MAP_BACK_RECT.position.x, SYSTEM_MAP_BACK_RECT.end.x)

    var can_fly := not next_hop.is_empty()
    draw_rect(SYSTEM_FLY_RECT, Color(0.04, 0.18, 0.15, 0.96) if can_fly else Color(0.05, 0.06, 0.08, 0.96), true)
    draw_rect(SYSTEM_FLY_RECT, Color("6bffb0") if can_fly else Color("46515c"), false, 2.5)
    _text_center("FLY", SYSTEM_FLY_RECT.position.y + 35.0, 19, Color("f0fbff") if can_fly else Color("68737d"), SYSTEM_FLY_RECT.position.x, SYSTEM_FLY_RECT.end.x)

func _draw_market_menu() -> void:
    _draw_menu_art(ART_BG_MARKET, 0.67)
    _draw_menu_panel(Rect2(18.0, 15.0, 354.0, 144.0), 0.78)
    _draw_planet_art(current_planet, Rect2(306.0, 18.0, 60.0, 60.0), 0.96)
    _text("%s MARKET" % _planet_display_name(current_planet).to_upper(), Vector2(28, 48), 24, Color("77f7ff"))
    _text("%d CR   CARGO %d/%d" % [research_credits, _cargo_used(), _cargo_capacity()], Vector2(28, 76), 14, Color("ffd166"))
    _text(_planet_jurisdiction_label(current_planet), Vector2(28, 101), 10, Color("bdeef4"))
    _text(_planet_law_summary(current_planet), Vector2(28, 121), 10, Color("8ea9b8"))
    _text(_planet_crime_summary(current_planet), Vector2(28, 142), 9, Color("ffb347") if _planet_crime_summary(current_planet).contains("HUNTED") or _planet_crime_summary(current_planet).contains("WANTED") else Color("8ea9b8"))

    for i in commodity_names.size():
        var commodity: String = commodity_names[i]
        var buy_price: int = _market_buy_price(current_planet, commodity)
        var sell_price: int = _market_sell_price(current_planet, commodity)
        var market_data: Dictionary = markets[current_planet][commodity]
        var stock: int = int(round(float(market_data.stock)))
        var held: int = int(cargo.get(commodity, 0))
        var buy_rect: Rect2 = _market_buy_rect(i)
        var sell_rect: Rect2 = _market_sell_rect(i)
        draw_rect(buy_rect, Color(0.035, 0.16, 0.12, 0.91), true)
        draw_rect(buy_rect, Color("6bffb0"), false, 2.0)
        draw_rect(sell_rect, Color(0.16, 0.07, 0.11, 0.91), true)
        draw_rect(sell_rect, Color("ff8fa6"), false, 2.0)
        _text(commodity, buy_rect.position + Vector2(8, 19), 14, Color("f0fbff"))
        _text("BUY %d" % buy_price, buy_rect.position + Vector2(8, 46), 13, Color("6bffb0"))
        _text("SELL %d" % sell_price, sell_rect.position + Vector2(9, 46), 13, Color("ffb0c0"))
        _text("H%d S%d" % [held, stock], sell_rect.position + Vector2(86, 19), 11, Color("8ea9b8"))
        if PoliticalWorld.RESTRICTED_COMMODITIES.has(commodity):
            var legality: Dictionary = _planet_commodity_legality(current_planet, commodity)
            var status: String = _commodity_legality_short(current_planet, commodity)
            _text(status, sell_rect.position + Vector2(9, 19), 10, _commodity_legality_color(String(legality.status)))
    _draw_submenu_back()

func _draw_contracts_menu() -> void:
    _draw_menu_art(ART_BG_OPS, 0.65)
    _draw_menu_panel(Rect2(18.0, 14.0, 354.0, 108.0), 0.74)
    _draw_planet_art(current_planet, Rect2(304.0, 20.0, 64.0, 64.0), 0.95)
    _text("CONTRACT BOARD", Vector2(28, 55), 27, Color("77f7ff"))
    if not active_contract.is_empty():
        var active_label := "SMUGGLE" if bool(active_contract.get("smuggling", false)) else String(active_contract.get("type", "")).to_upper()
        _text("ACTIVE: %s > %s" % [active_label, _planet_display_name(String(active_contract.destination))], Vector2(30, 94), 14, Color("6bffb0"))
    else:
        _text("TAP A JOB TO ACCEPT", Vector2(30, 94), 14, Color("8ea9b8"))
    for i in contract_board.size():
        var contract: Dictionary = contract_board[i]
        var rect := _contract_row_rect(i)
        draw_rect(rect, Color(0.035, 0.065, 0.10, 0.91), true)
        draw_rect(rect, Color("465f72"), false, 2.0)
        var smuggling := bool(contract.get("smuggling", false))
        var role := String(contract.get("role", String(contract.type).to_upper()))
        _text(role, rect.position + Vector2(12, 23), 15, Color("ffb347") if smuggling else Color("f0fbff"))
        _text("> %s   D%d" % [_planet_display_name(String(contract.destination)), int(contract.difficulty)], rect.position + Vector2(12, 47), 12, Color("8ea9b8"))
        _text("%d CR" % int(contract.reward), rect.position + Vector2(244, 47), 14, Color("ffd166"))
        var exposure := int(round(float(contract.get("pirate_exposure", 0.0)) * 100.0))
        var issuer := _short_map_label(String(contract.get("issuer_name", "LOCAL")).to_upper(), 14)
        var relation_gain := int(contract.get("relation_reward", 0))
        _text("%s  PIR %d%%  REP +%d" % [issuer, exposure, relation_gain], rect.position + Vector2(12, 73), 9, Color("bdeef4"))
        if String(contract.type) == "delivery":
            var cargo_label := String(contract.get("commodity", "CARGO")).to_upper()
            _text(cargo_label, rect.position + Vector2(254, 23), 10, Color("ff8fa6") if smuggling else Color("bdeef4"))
        elif String(contract.type) == "passenger":
            _text("1 PAX", rect.position + Vector2(252, 23), 10, Color("bdeef4"))
        else:
            _text("BOSS", rect.position + Vector2(258, 23), 10, Color("ff8fa6"))
    _draw_submenu_back()
func _draw_research_button(rect: Rect2, track: String, label: String, effect: String) -> void:
    var lvl := _research_level(track)
    var max_lvl := _research_max(track)
    var at_max := lvl >= max_lvl
    var cost := _research_cost(track)
    var can_buy := not at_max and research_credits >= cost
    draw_rect(rect, Color("14232f") if can_buy else Color("0d1118"), true)
    draw_rect(rect, Color("77f7ff") if can_buy else Color("46515c"), false, 2.0)
    _text("%s  L%d" % [label, lvl], rect.position + Vector2(10, 23), 16, Color("f0fbff"))
    _text(effect, rect.position + Vector2(10, 45), 13, Color("8ea9b8"))
    var cost_text := "MAX" if at_max else ("%d" % cost)
    _text(cost_text, rect.position + Vector2(244, 35), 15, Color("6bffb0") if at_max else Color("ffd166"))

func _draw_research() -> void:
    _draw_menu_art(ART_BG_UPGRADES, 0.68)
    _draw_menu_panel(Rect2(22.0, 20.0, 346.0, 135.0), 0.76)
    _text_center("SHIP UPGRADES", 74.0, 31, Color("b56cff"), 26.0, 364.0)
    _text_center("CREDITS %07d" % research_credits, 112.0, 18, Color("ffd166"), 26.0, 364.0)
    _text_center("PERMANENT SHIP MODS", 145.0, 15, Color("8ea9b8"), 26.0, 364.0)
    _draw_research_button(RESEARCH_SHIP_RECT, "ship", "SHIP SPEED", "+4% scroll, +8% near score")
    _draw_research_button(RESEARCH_DASH_RECT, "dash", "DASH", "+35px / +40 speed / +12% dash-near")
    _draw_research_button(RESEARCH_DAMAGE_RECT, "damage", "DAMAGE", "+3% all weapon damage")
    _draw_research_button(RESEARCH_HITS_RECT, "hits", "HITS", "+1 starting hit")
    _draw_research_button(RESEARCH_SHIELD_RECT, "shield", "SHIELD", "+1 projectile block/run")
    draw_rect(RESEARCH_WEAPONS_RECT, Color(0.10, 0.05, 0.18, 0.93), true)
    draw_rect(RESEARCH_WEAPONS_RECT, Color("b56cff"), false, 2.0)
    _text_center("STARTING WEAPONS", RESEARCH_WEAPONS_RECT.position.y + 37.0, 18, Color("f1dcff"), RESEARCH_WEAPONS_RECT.position.x, RESEARCH_WEAPONS_RECT.end.x)
    draw_rect(RESEARCH_BACK_RECT, Color(0.05, 0.15, 0.19, 0.94), true)
    draw_rect(RESEARCH_BACK_RECT, Color("77f7ff"), false, 3.0)
    _text_center("BACK", RESEARCH_BACK_RECT.position.y + 42.0, 22, Color("f0fbff"), RESEARCH_BACK_RECT.position.x, RESEARCH_BACK_RECT.end.x)
func _draw_weapon_unlock_button(rect: Rect2, weapon: String, label: String) -> void:
    var unlocked := _weapon_start_unlocked(weapon)
    var selected := starting_weapon == weapon
    var cost := 0 if weapon == "none" else _weapon_research_cost(weapon)
    var can_buy := unlocked or research_credits >= cost
    var fill := Color("14232f") if can_buy else Color("0d1118")
    var border := Color("77f7ff") if can_buy else Color("46515c")
    if selected:
        fill = Color("183524")
        border = Color("6bffb0")
    draw_rect(rect, fill, true)
    draw_rect(rect, border, false, 2.0)
    _text(label, rect.position + Vector2(12, 23), 16, Color("f0fbff"))
    var right := "SELECTED" if selected else ("SELECT" if unlocked else ("%d" % cost))
    _text(right, rect.position + Vector2(215, 34), 13, Color("6bffb0") if unlocked or selected else Color("ffd166"))

func _draw_weapon_research() -> void:
    _draw_menu_art(ART_BG_UPGRADES, 0.70)
    _draw_menu_panel(Rect2(22.0, 20.0, 346.0, 128.0), 0.77)
    _text_center("STARTING WEAPONS", 76.0, 29, Color("b56cff"), 25.0, 365.0)
    _text_center("CREDITS %07d" % research_credits, 112.0, 18, Color("ffd166"), 25.0, 365.0)
    _text_center("PERMANENT UNLOCK — 10x RUN PRICE", 140.0, 14, Color("8ea9b8"), 25.0, 365.0)
    _draw_weapon_unlock_button(WEAPON_NONE_RECT, "none", "NONE")
    _draw_weapon_unlock_button(WEAPON_SINGLE_RECT, "single", "SINGLE D1")
    _draw_weapon_unlock_button(WEAPON_DUAL_RECT, "dual", "DUAL D1x2")
    _draw_weapon_unlock_button(WEAPON_LASER_RECT, "laser", "THIN LASER")
    _draw_weapon_unlock_button(WEAPON_CONE_RECT, "cone", "CONE D3x3")
    _draw_weapon_unlock_button(WEAPON_SEEKER_RECT, "seeker", "SEEKER D7")
    draw_rect(WEAPON_RESEARCH_BACK_RECT, Color(0.05, 0.15, 0.19, 0.94), true)
    draw_rect(WEAPON_RESEARCH_BACK_RECT, Color("77f7ff"), false, 3.0)
    _text_center("BACK", WEAPON_RESEARCH_BACK_RECT.position.y + 39.0, 22, Color("f0fbff"), WEAPON_RESEARCH_BACK_RECT.position.x, WEAPON_RESEARCH_BACK_RECT.end.x)
func _draw_pause_button() -> void:
    draw_rect(PAUSE_RECT, Color(0.05, 0.08, 0.12, 0.82), true)
    draw_rect(PAUSE_RECT, Color("77f7ff"), false, 2.0)
    _text("II", PAUSE_RECT.position + Vector2(27, 26), 18, Color("f0fbff"))

func _draw_pause_overlay() -> void:
    draw_rect(Rect2(Vector2.ZERO, Vector2(W, H)), Color(0.02, 0.03, 0.06, 0.88), true)
    _text("RUN PAUSED", Vector2(91, 260), 34, Color("77f7ff"))
    _text("SCORE %06d" % score, Vector2(122, 306), 20, Color("ffd166"))
    draw_rect(PAUSE_RESUME_RECT, Color("123544"), true)
    draw_rect(PAUSE_RESUME_RECT, Color("77f7ff"), false, 3.0)
    _text("RESUME", PAUSE_RESUME_RECT.position + Vector2(91, 46), 24, Color("f0fbff"))
    draw_rect(PAUSE_QUIT_RECT, Color("341521"), true)
    draw_rect(PAUSE_QUIT_RECT, Color("ff6687"), false, 3.0)
    _text("QUIT + BANK SCORE", PAUSE_QUIT_RECT.position + Vector2(39, 46), 20, Color("ffd166"))
    _text("Focus loss / phone sleep pauses automatically.", Vector2(42, 580), 14, Color("8ea9b8"))

func _draw_shop_button(rect: Rect2, label: String, cost: int, enabled: bool, owned: bool = false) -> void:
    var fill := Color("17303b") if enabled else Color(0.09, 0.10, 0.13, 0.92)
    var border := Color("77f7ff") if enabled else Color(0.28, 0.32, 0.36, 0.8)
    if owned:
        fill = Color(0.13, 0.20, 0.16, 0.95)
        border = Color("6bffb0")
    draw_rect(rect, fill, true)
    draw_rect(rect, border, false, 2.0)
    var suffix := "OWNED" if owned else ("%d" % cost)
    _text(label, rect.position + Vector2(10, 24), 15, Color("f0fbff"))
    _text(suffix, rect.position + Vector2(10, 47), 14, Color("6bffb0") if owned else Color("ffd166"))

func _draw_shop() -> void:
    draw_rect(Rect2(Vector2.ZERO, Vector2(W, H)), Color("080b14"))
    _text("LEVEL %d CLEAR" % level, Vector2(92, 82), 28, Color("77f7ff"))
    _text("+%d CLEAR BONUS" % last_level_bonus, Vector2(112, 112), 16, Color("6bffb0"))
    _text("SCORE / CREDITS  %06d" % score, Vector2(75, 154), 20, Color("ffd166"))
    _text("HP %d/%d   %s" % [hp, max_hp, _weapon_label(current_weapon)], Vector2(62, 187), 16, Color("bdeef4"))

    var can_repair := hp < max_hp and score >= SHOP_REPAIR_COST
    _draw_shop_button(SHOP_REPAIR_RECT, "REPAIR +1 HIT", SHOP_REPAIR_COST, can_repair, hp >= max_hp)

    _draw_shop_button(SHOP_SINGLE_RECT, "SINGLE D1", SHOP_SINGLE_COST, score >= SHOP_SINGLE_COST and current_weapon != "single", current_weapon == "single")
    _draw_shop_button(SHOP_DUAL_RECT, "DUAL D1x2", SHOP_DUAL_COST, score >= SHOP_DUAL_COST and current_weapon != "dual", current_weapon == "dual")
    _draw_shop_button(SHOP_CONE_RECT, "CONE D3x3", SHOP_CONE_COST, score >= SHOP_CONE_COST and current_weapon != "cone", current_weapon == "cone")
    _draw_shop_button(SHOP_SEEKER_RECT, "SEEKER D7", SHOP_SEEKER_COST, score >= SHOP_SEEKER_COST and current_weapon != "seeker", current_weapon == "seeker")
    _draw_shop_button(SHOP_LASER_RECT, "THIN LASER 3 DPS", SHOP_LASER_COST, score >= SHOP_LASER_COST and current_weapon != "laser", current_weapon == "laser")

    draw_rect(SHOP_CONTINUE_RECT, Color("123544"), true)
    draw_rect(SHOP_CONTINUE_RECT, Color("77f7ff"), false, 3.0)
    _text("START LEVEL %d" % (level + 1), SHOP_CONTINUE_RECT.position + Vector2(71, 43), 21, Color("f0fbff"))
    _text("NEXT LEVEL: MORE SPEED + DENSITY", Vector2(62, 680), 15, Color("ffb347"))
    _text("FIELD REPAIRS ARE RARE", Vector2(92, 710), 15, Color("8ea9b8"))

func _draw_results() -> void:
    draw_rect(Rect2(Vector2(30, 210), Vector2(330, 410)), Color(0.03,0.05,0.09,0.94), true)
    draw_rect(Rect2(Vector2(30, 210), Vector2(330, 410)), Color("77f7ff") if won else Color("ff426f"), false, 3.0)
    _text("EXTRACTION!" if won else "RUN ENDED", Vector2(70 if won else 91, 275), 34, Color("77f7ff") if won else Color("ff6687"))
    _text(result_reason, Vector2(94, 314), 17, Color("8ea9b8"))
    _text("LEVEL  %02d" % level, Vector2(118, 350), 22, Color("bdeef4"))
    _text("BANKED %07d" % last_banked_score, Vector2(74, 392), 24, Color("ffd166"))
    _text("RESEARCH %07d" % research_credits, Vector2(76, 435), 20, Color("b56cff"))
    _text("BEST COMBO x%d" % best_combo, Vector2(97, 474), 20, Color("ffd166"))
    _text("TAP FOR MAIN MENU", Vector2(74, 560), 22, Color("bdeef4"))

func _text(s: String, pos: Vector2, size: int, color: Color) -> void:
    draw_string(ThemeDB.fallback_font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, color)

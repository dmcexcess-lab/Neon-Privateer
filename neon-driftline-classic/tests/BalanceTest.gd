extends SceneTree

# Deterministic balance telemetry on real Classic gameplay physics, spawns,
# collisions and score awards. Bots are bounded reaction heuristics, not humans.
# No mocks: this runs the actual Main.gd _process at fixed 0.10 second steps.

const DT := 0.10
const SEEDS := 12
const MAX_LEVEL := 5
const MAX_STEPS := 2100

func _move_bot(scene, policy: String) -> void:
    scene.left_control_held = false
    scene.right_control_held = false
    if policy == "passive":
        return

    var desired_x: float = float(scene.W) * 0.5
    var best_orb_dy := 100000.0
    var best_hazard_dy := 100000.0
    var imminent_hazard_x := -1.0
    var imminent_hazard_dist := 9999.0

    # The split barrier must be committed to a side well before reaching player.
    var station_close: bool = scene.lane_event_active and scene.station_top + scene.station_height >= scene.player_y - 160.0 and scene.station_top <= scene.player_y + 60.0
    if station_close:
        # Prefer the easy side for both survival policies.
        desired_x = 110.0 if scene.hard_lane_right else 280.0
    else:
        for o in scene.objects:
            if o.type == "energy" and float(o.y) > scene.player_y - 260.0 and float(o.y) < scene.player_y - 45.0:
                var orb_dy: float = scene.player_y - float(o.y)
                if orb_dy < best_orb_dy:
                    best_orb_dy = orb_dy
                    desired_x = float(o.x)
        if policy == "score":
            for o in scene.objects:
                if o.type == "hazard" and float(o.y) > scene.player_y - 390.0 and float(o.y) < scene.player_y - 105.0:
                    var approach_dy: float = scene.player_y - float(o.y)
                    if approach_dy < best_hazard_dy:
                        best_hazard_dy = approach_dy
                        desired_x = clampf(float(o.x) + (45.0 if float(o.x) < scene.W * 0.5 else -45.0), scene.LEFT, scene.RIGHT)

    for o in scene.objects:
        if o.type != "hazard":
            continue
        var dy: float = float(o.y) - scene.player_y
        var dx: float = absf(float(o.x) - scene.player_x)
        if dy > -130.0 and dy < 50.0 and dx < 65.0:
            if absf(dy) < absf(imminent_hazard_dist):
                imminent_hazard_dist = dy
                imminent_hazard_x = float(o.x)

    if imminent_hazard_x >= 0.0:
        if scene.dash_cooldown <= 0.0 and scene.dash_timer <= 0.0 and imminent_hazard_dist < -35.0:
            scene._dash()
        elif absf(scene.player_x - imminent_hazard_x) < 43.0 and not station_close:
            desired_x = clampf(imminent_hazard_x + (85.0 if scene.player_x >= imminent_hazard_x else -85.0), scene.LEFT, scene.RIGHT)

    scene.left_control_held = desired_x < scene.player_x - 10.0
    scene.right_control_held = desired_x > scene.player_x + 10.0

func _percentile(numbers: Array[int], fraction: float) -> int:
    if numbers.is_empty():
        return 0
    var sorted := numbers.duplicate()
    sorted.sort()
    return sorted[int(floor(float(sorted.size() - 1) * fraction))]

func _initialize() -> void:
    var packed: PackedScene = load("res://main.tscn")
    if packed == null:
        push_error("BALANCE FAIL: missing game scene")
        quit(1)
        return
    var scene = packed.instantiate()
    root.add_child(scene)
    await process_frame
    scene.set_process(false)
    var data: Dictionary = {}
    for scenario in ["passive", "avoid", "score", "upgraded"]:
        var scores: Array[int] = []
        var best_levels: Array[int] = []
        var orbs: Array[int] = []
        var total_successful_levels := 0
        for trial in SEEDS:
            scene.research_ship_speed = 0
            scene.research_dash = 0
            scene.research_dash_cooldown = 0
            scene.research_damage = 0
            scene.research_hits = 0
            scene.research_shield = 0
            scene.starting_weapon = "none"
            scene.research_start_single = false
            if scenario == "upgraded":
                scene.research_hits = 1
                scene.research_dash_cooldown = 3
                scene.research_start_single = true
                scene.starting_weapon = "single"
            scene._start_game()
            scene.rng.seed = 11731 + trial * 919
            scene.neutral_spawn_clock = 1.65
            scene.pickup_clock = 1.4
            var last_shop_level := 0
            for tick in MAX_STEPS:
                if scene.game_over:
                    break
                if scene.shop_open:
                    total_successful_levels += 1
                    last_shop_level = scene.level
                    if scene.level >= MAX_LEVEL:
                        break
                    scene._start_next_level()
                _move_bot(scene, "score" if scenario == "upgraded" else scenario)
                scene._process(DT)
            scores.append(scene.score)
            best_levels.append(maxi(scene.level, last_shop_level))
            orbs.append(scene.energy)
        var sum_score := 0
        var sum_level := 0
        var sum_orbs := 0
        for i in scores.size():
            sum_score += scores[i]
            sum_level += best_levels[i]
            sum_orbs += orbs[i]
        var avg := int(round(float(sum_score) / float(scores.size())))
        data[scenario] = {
            "mean": avg,
            "median": _percentile(scores, 0.5),
            "p25": _percentile(scores, 0.25),
            "p75": _percentile(scores, 0.75),
            "mean_level": snappedf(float(sum_level) / float(scores.size()), 0.1),
            "mean_orbs": snappedf(float(sum_orbs) / float(scores.size()), 0.1),
            "cleared_levels": total_successful_levels,
            "runs_for_5000_at_mean": int(ceil(5000.0 / float(maxi(1, avg)))),
            "all_scores": scores
        }
        print("BALANCE PROFILE ", scenario, " ", JSON.stringify(data[scenario]))

    print("BALANCE RESEARCH COSTS hit=", scene._research_cost("hits"), " cooldown=", scene._research_cost("cooldown"), " starter_single=", scene._weapon_research_cost("single"))
    print("BALANCE COOLDOWN 0=", snappedf(scene.DASH_COOLDOWN, 0.01), " 1=", snappedf(scene.DASH_COOLDOWN * pow(scene.DASH_COOLDOWN_REDUCTION, 1), 0.01), " 10=", snappedf(scene.DASH_COOLDOWN * pow(scene.DASH_COOLDOWN_REDUCTION, 10), 0.01))
    print("NEON DRIFTLINE BALANCE TELEMETRY OK")
    quit(0)

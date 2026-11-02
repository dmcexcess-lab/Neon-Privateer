extends SceneTree

var failures: Array[String] = []
var checks := 0

func check(condition: bool, message: String) -> void:
    checks += 1
    if not condition:
        failures.append(message)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var scene = load("res://main.tscn").instantiate()
    root.add_child(scene)
    scene.set_process(false)

    check(scene._create_new_career(1), "new career created")
    check(scene.tutorial_open and not scene.tutorial_complete and scene.tutorial_step == 0, "new career opens overview")
    check(scene._tutorial_title() == "WELCOME TO NEON PRIVATEER", "overview title")
    check(scene._tutorial_lines().size() >= 5, "overview copy")

    var expected_targets := [
        scene.HUB_OPERATIONS_RECT,
        scene.HUB_TRAVEL_RECT,
        scene.HUB_TRADE_RECT,
        scene.HUB_MARKET_RECT,
        scene.HUB_CONTRACTS_RECT,
        scene.HUB_UPGRADES_RECT,
        scene.HUB_CAREERS_RECT
    ]
    for i in expected_targets.size():
        scene._tutorial_next()
        check(scene.tutorial_step == i + 1, "advanced to section %d" % (i + 1))
        check(scene._tutorial_target_rect() == expected_targets[i], "spotlight section %d" % (i + 1))
        check(not scene._tutorial_title().is_empty() and not scene._tutorial_lines().is_empty(), "section %d has guidance" % (i + 1))

    scene._tutorial_next()
    check(not scene.tutorial_open and scene.tutorial_complete, "final step completes tutorial")
    var meta := ConfigFile.new()
    check(meta.load(scene._active_meta_path()) == OK and bool(meta.get_value("meta", "tutorial_complete", false)), "completion persists")

    check(scene._create_new_career(2), "second career created")
    scene.tutorial_step = 3
    check(scene._load_career(2) and scene.tutorial_open and scene.tutorial_step == 0, "unfinished tutorial resumes from overview")
    scene._finish_tutorial()
    check(scene._load_career(2) and not scene.tutorial_open, "completed tutorial stays dismissed")

    # Saves from before this feature have no key and must not be interrupted.
    meta = ConfigFile.new()
    check(meta.load(scene._active_meta_path()) == OK, "legacy fixture loaded")
    meta.erase_section_key("meta", "tutorial_complete")
    meta.save(scene._active_meta_path())
    check(scene._load_career(2) and scene.tutorial_complete and not scene.tutorial_open, "legacy career defaults to complete")

    scene.queue_free()
    await process_frame
    if failures.is_empty():
        print("NEON TUTORIAL OK: %d checks, overview, seven sections, persistence and legacy migration" % checks)
        quit(0)
    else:
        print("NEON TUTORIAL FAIL: " + str(failures))
        quit(1)

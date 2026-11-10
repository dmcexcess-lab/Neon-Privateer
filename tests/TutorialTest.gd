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
    check(not scene.tutorial_open and scene.tutorial_complete, "new career skips modal field guide")
    check(scene.first_adventure_state == "READY", "new career begins authored first adventure")
    var meta := ConfigFile.new()
    check(meta.load(scene._active_meta_path()) == OK and meta.get_value("meta", "first_adventure_state", "") == "READY", "opening adventure state persists")

    check(scene._create_new_career(2), "second career created")
    scene.first_adventure_state = "CONTACTED"
    scene._save_meta()
    check(scene._load_career(2) and scene.first_adventure_state == "CONTACTED" and not scene.tutorial_open, "adventure resumes without modal guide")

    # Saves from before this feature have no key and must not be interrupted.
    meta = ConfigFile.new()
    check(meta.load(scene._active_meta_path()) == OK, "legacy fixture loaded")
    meta.erase_section_key("meta", "tutorial_complete")
    meta.save(scene._active_meta_path())
    check(scene._load_career(2) and scene.tutorial_complete and not scene.tutorial_open and scene.first_adventure_state == "READY", "legacy career defaults to no modal and can try the new adventure")

    scene.queue_free()
    await process_frame
    if failures.is_empty():
        print("NEON FIRST ADVENTURE OK: %d checks, no modal tutorial, opening state persistence and legacy migration" % checks)
        quit(0)
    else:
        print("NEON TUTORIAL FAIL: " + str(failures))
        quit(1)

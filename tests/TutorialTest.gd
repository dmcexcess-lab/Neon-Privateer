extends SceneTree
const CovertCareer=preload("res://covert/CovertCareer.gd")

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
    scene.tutorial_step=2
    var service_guide := str(scene._tutorial_lines())
    check(service_guide.contains("marked counter inside") and not service_guide.contains("marked doorway"), "legacy guide describes open entrances and service counters, not door interaction")
    scene.tutorial_step=3
    var terminal_guide := str(scene._tutorial_lines())
    check(terminal_guide.contains("Visible illegal terminals") and terminal_guide.contains("alert security") and not terminal_guide.contains("Unmarked terminals"), "legacy guide matches visible randomized illegal terminals")
    scene.tutorial_step=0
    scene.first_adventure_state="CALLING"
    check(scene._start_first_bounty(),"answering the opening cinematic auto-accepts the first bounty")
    check(scene.active_contract.type=="bounty" and scene.active_contract.destination==scene.current_planet,"opening bounty belongs to the full Privateer contract ledger")
    check(scene.covert_profile.active.steps==["rumor","tail","wiretap","target"] and scene.covert_profile.active.target=="Kest Arden","opening case preserves the ask-around, tail, terminal clue and target sequence")
    check(scene.covert_profile.active.people[0].name=="Kest Arden" and scene.covert_profile.active.clues[0].text.contains("Kest Arden"),"opening lead, named suspect and initial dossier clue remain consistent")
    check(not scene._start_first_bounty(),"the opening contract cannot be duplicated")
    check(scene._advance_active_case("rumor","Mara Voss") and CovertCareer.next_task(scene.covert_profile.active)=="tail","asking around advances the persistent career dossier")
    scene.first_adventure_state="CONTACTED"
    check(scene._advance_active_case("tail","Field surveillance") and CovertCareer.next_task(scene.covert_profile.active)=="wiretap","tailing reveals the illegal terminal objective")
    scene.first_adventure_state="OBSERVED"
    check(scene._advance_active_case("wiretap","Terminal intercept") and CovertCareer.next_task(scene.covert_profile.active)=="target","the hack reveals the hideout clue")
    scene.first_adventure_state="LOCATED"
    check(scene._advance_active_case("target","Hideout breach"),"the target encounter resolves through the Privateer case system")
    check(scene.first_adventure_state=="COMPLETE" and scene.active_contract.is_empty() and scene.covert_profile.active.is_empty(),"closing the authored mission clears and pays the full-game bounty")
    check(scene.research_credits>=900,"opening bounty rewards the career wallet")
    scene._create_new_career(1)
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
    meta.erase_section_key("meta", "first_adventure_state")
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

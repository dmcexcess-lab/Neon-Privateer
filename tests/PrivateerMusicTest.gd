extends SceneTree

var music: Node
var player: AudioStreamPlayer
var scene: Node
var player_id: int

func _check(ok: bool, message: String) -> bool:
    if not ok:
        push_error("PRIVATEER MUSIC FAIL: " + message)
        quit(1)
    return ok

func _initialize() -> void:
    call_deferred("_run")

func _checkpoint(expected: String, floor_position: float, label: String) -> bool:
    scene._sync_soundtrack()
    await create_timer(0.10).timeout
    return _check(music.context == expected and player.get_instance_id() == player_id
        and music.find_children("*", "AudioStreamPlayer", true, false).size() == 1
        and player.playing and not player.stream_paused
        and player.get_playback_position() >= floor_position,
        label + " selected the wrong track, restarted it or duplicated a player")

func _run() -> void:
    music = root.get_node_or_null("PrivateerSoundtrack")
    if not _check(music != null, "autoload absent"):
        return
    player = music.player
    player_id = player.get_instance_id()
    if not _check(is_equal_approx(player.volume_db, -11.0)
        and player.max_polyphony == 1 and player.playback_type == AudioServer.PLAYBACK_TYPE_STREAM,
        "volume/polyphony/streaming changed"):
        return
    for key in music.TRACK_PATHS:
        var imported: AudioStreamOggVorbis = load(music.TRACK_PATHS[key])
        if not _check(imported != null and imported.loop and imported.get_length() > 170.0,
            "missing real loop-enabled imported song: " + key):
            return

    scene = load("res://main.tscn").instantiate()
    root.add_child(scene)
    scene.hide()
    scene.set_process(false)
    if not _check(scene.sfx_players.size() == 10, "existing SFX voices lost"):
        return
    player.seek(20.0)
    if not await _checkpoint("port", 19.9, "title"):
        return
    scene._create_new_career(1)
    for screen in ["hub_open", "market_open", "trade_open", "contracts_open", "travel_open", "research_open", "weapon_research_open"]:
        scene.set(screen, true)
        if not await _checkpoint("port", 19.9, screen):
            return
        scene.set(screen, false)
    var destination := ""
    for candidate in scene.planet_names:
        var spec: Dictionary = scene._direct_route_spec(scene.current_planet, candidate)
        if candidate != scene.current_planet and not spec.is_empty() and int(spec.distance) <= scene._jump_range():
            destination = candidate
            break
    if not _check(not destination.is_empty() and scene._start_route(destination), "real route failed to launch"):
        return
    if not await _checkpoint("flight", 0.0, "departure"):
        return
    player.seek(30.0)
    scene._pause_run()
    if not await _checkpoint("flight", 29.9, "flight pause"):
        return
    paused = true
    if not await _checkpoint("flight", 29.9, "SceneTree pause"):
        return
    paused = false
    scene._resume_run()
    if not await _checkpoint("flight", 29.9, "flight resume"):
        return
    scene._arrive_at_destination()
    if not await _checkpoint("port", 19.9, "landing resumes port position"):
        return
    scene._start_game()
    scene.profile_menu_open = false
    scene.hub_open = false
    if not await _checkpoint("flight", 29.9, "next flight resumes flight position"):
        return
    scene._open_profile_menu()
    if not await _checkpoint("port", 19.9, "main menu during saved flight"):
        return
    scene.profile_menu_open = false
    if not await _checkpoint("flight", 29.9, "return from menu"):
        return
    scene.route_active = true
    scene._finish(false)
    if not await _checkpoint("port", 19.9, "ship loss and respawn"):
        return

    var key := InputEventKey.new()
    key.keycode = KEY_A
    key.pressed = true
    for i in 10:
        music._input(key)
    if not await _checkpoint("port", 19.9, "repeated unlock input"):
        return
    music._set_application_paused(true)
    music._set_audio_focus_lost(true)
    var at := player.get_playback_position()
    await create_timer(0.20).timeout
    if not _check(player.stream_paused and absf(player.get_playback_position() - at) < 0.05,
        "application suspension lost position"):
        return
    music._set_application_paused(false)
    if not _check(player.stream_paused, "resume ignored missing audio focus"):
        return
    player.stop()
    music._set_audio_focus_lost(false)
    if not await _checkpoint("port", 19.9, "interrupted audio driver recovery"):
        return
    music._set_audio_focus_lost(true)
    music._set_application_paused(true)
    music._set_audio_focus_lost(false)
    if not _check(player.stream_paused, "focus returned before application resumed"):
        return
    music._set_application_paused(false)
    for track_context in ["port", "flight"]:
        music.set_flight(track_context == "flight")
        player.seek(player.stream.get_length() - 0.12)
        var playback := player.get_stream_playback()
        var loops := playback.get_loop_count()
        await create_timer(0.45).timeout
        if not _check(player.playing and player.get_playback_position() < 1.0
            and playback.get_loop_count() > loops, track_context + " actual EOF failed to loop"):
            return
        playback = null
    var checkpoint_id := player.get_instance_id()
    scene.queue_free()
    await process_frame
    scene = load("res://main.tscn").instantiate()
    root.add_child(scene)
    scene.hide()
    scene.set_process(false)
    scene._sync_soundtrack()
    if not _check(player.get_instance_id() == checkpoint_id, "scene reload replaced music player"):
        return
    scene.queue_free()
    player.stop()
    player.stream = null
    music.tracks.clear()
    await create_timer(0.10).timeout
    print("NEON PRIVATEER MUSIC OK: port/flight continuity, real loops, saved positions, input, lifecycle, SFX")
    quit(0)

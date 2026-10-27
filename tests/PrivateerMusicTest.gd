extends SceneTree
## Test actual Ogg EOF transitions, single-player continuity, incarceration, lifecycle.

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

func _checkpoint(floor_position: float, label: String) -> bool:
    scene._sync_soundtrack()
    await create_timer(0.10).timeout
    return _check(music.context == "playlist" and player.get_instance_id() == player_id
        and music.find_children("*", "AudioStreamPlayer", true, false).size() == 1
        and player.playing and not player.stream_paused
        and player.get_playback_position() >= floor_position,
        label + " stopped, duplicated, or restarted the playlist")

func _run() -> void:
    music = root.get_node_or_null("PrivateerSoundtrack")
    if not _check(music != null, "autoload missing"):
        return
    player = music.player
    player_id = player.get_instance_id()
    if not _check(is_equal_approx(player.volume_db, -11.0)
        and player.max_polyphony == 1
        and player.playback_type == AudioServer.PLAYBACK_TYPE_STREAM,
        "streaming voice configuration changed"):
        return
    if not _check(music.PLAYLIST_IDS == ["nineteen_steps", "neon_cathedral", "do_androids_dream"]
        and music.TRACK_PATHS.has("j_space"), "Neon Quartet mapping changed"):
        return

    var expected: Array[String] = []
    for id in music.PLAYLIST_IDS:
        if ResourceLoader.exists(music.TRACK_PATHS[id]):
            expected.append(id)
            if not _check(music.tracks.has(id) and not music.tracks[id].loop
                and music.tracks[id].get_length() > 10.0, "invalid real normal recording " + id):
                return
    if not _check(music.available_playlist == expected and expected.size() >= 2,
        "playlist failed to skip pending songs without changing order"):
        return
    scene = load("res://main.tscn").instantiate()
    root.add_child(scene)
    scene.hide()
    scene.set_process(false)
    if not _check(scene.sfx_players.size() == 10, "existing SFX voices lost"):
        return
    player.seek(20.0)
    if not await _checkpoint(19.9, "title"):
        return
    scene._create_new_career(1)
    for screen in ["hub_open", "market_open", "trade_open", "contracts_open", "travel_open", "research_open", "weapon_research_open"]:
        scene.set(screen, true)
        if not await _checkpoint(19.9, screen):
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
    if not await _checkpoint(19.9, "departure"):
        return
    scene._pause_run()
    if not await _checkpoint(19.9, "flight pause"):
        return
    paused = true
    if not await _checkpoint(19.9, "SceneTree pause"):
        return
    paused = false
    scene._resume_run()
    scene._arrive_at_destination()
    if not await _checkpoint(19.9, "arrival"):
        return

    scene.covert_open = true
    if not await _checkpoint(19.9, "normal ground operation"):
        return
    scene.covert.data.incarcerated = true
    scene._sync_soundtrack()
    if not _check(music.context == "prison" and music.current_track_id == "j_space",
        "incarceration did not select J-Space"):
        return
    if music.tracks.has("j_space"):
        if not _check(player.playing and player.stream.loop,
            "installed J-Space is not looping"):
            return
    elif not _check(player.stream == null and not player.playing,
        "prison played unrelated music when J-Space is pending"):
        return
    scene.covert.data.incarcerated = false
    scene.covert_open = false
    if not await _checkpoint(19.9, "release resumes the saved song position"):
        return

    # Seek near real EOF, crossing each available recording before wrapping.
    for i in expected.size():
        var before: int = music.playlist_index
        var old_id: String = music.current_track_id
        player.seek(player.stream.get_length() - 0.12)
        await create_timer(0.55).timeout
        var next_index: int = (before + 1) % expected.size()
        if not _check(music.context == "playlist" and music.playlist_index == next_index
            and music.current_track_id == expected[next_index]
            and player.playing and player.get_playback_position() < 1.0,
            "real EOF did not advance from " + old_id):
            return
    var key := InputEventKey.new()
    key.keycode = KEY_A
    key.pressed = true
    for i in 10:
        music._input(key)
    if not await _checkpoint(0.0, "repeated audio unlock input"):
        return

    music._set_application_paused(true)
    music._set_audio_focus_lost(true)
    var held := player.get_playback_position()
    await create_timer(0.20).timeout
    if not _check(player.stream_paused and absf(player.get_playback_position() - held) < 0.05,
        "suspension lost position"):
        return
    music._set_application_paused(false)
    if not _check(player.stream_paused, "resumed before focus"):
        return
    player.stop()
    music._set_audio_focus_lost(false)
    if not await _checkpoint(0.0, "stopped driver recovered"):
        return
    var same_player := player.get_instance_id()
    scene.queue_free()
    await process_frame
    scene = load("res://main.tscn").instantiate()
    root.add_child(scene)
    scene.hide()
    scene.set_process(false)
    scene._sync_soundtrack()
    if not _check(player.get_instance_id() == same_player, "scene reload created new player"):
        return
    scene.queue_free()
    player.stop()
    player.stream = null
    music.tracks.clear()
    await create_timer(0.10).timeout
    print("NEON PRIVATEER MUSIC OK: real playlist EOF, prison exclusivity, continuity, lifecycle")
    quit(0)

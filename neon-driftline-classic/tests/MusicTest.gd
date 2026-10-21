extends SceneTree
## Exercise the real imported Ogg/player and actual Classic state transitions.

var soundtrack: Node
var player: AudioStreamPlayer
var player_id: int
var scene: Node
var previous_position := 0.0

func _check(ok: bool, message: String) -> bool:
    if not ok:
        push_error("MUSIC FAIL: " + message)
        quit(1)
    return ok

func _checkpoint(label: String) -> bool:
    await create_timer(0.10).timeout
    var position := player.get_playback_position()
    var players := soundtrack.find_children("*", "AudioStreamPlayer", true, false)
    var ok := _check(player.get_instance_id() == player_id and players.size() == 1
        and player.playing and not player.stream_paused and position >= previous_position
        and position > 15.0, label + " interrupted, duplicated or restarted music")
    previous_position = position
    return ok

func _initialize() -> void:
    # Autoloads finish entering the tree after SceneTree initialization.
    call_deferred("_run")

func _run() -> void:
    soundtrack = root.get_node_or_null("Soundtrack")
    if not _check(soundtrack != null, "Classic soundtrack autoload missing"):
        return
    player = soundtrack.player
    player_id = player.get_instance_id()
    if not _check(player.stream is AudioStreamOggVorbis and player.stream.loop
        and is_zero_approx(player.stream.loop_offset) and player.stream.get_length() > 170.0
        and is_equal_approx(player.volume_db, -11.0) and player.max_polyphony == 1
        and player.playback_type == AudioServer.PLAYBACK_TYPE_STREAM,
        "imported song, looping, volume or streaming configuration invalid"):
        return
    var imported: AudioStreamOggVorbis = load("res://assets/audio/nineteen_steps.ogg")
    if not _check(imported.loop, "audio import lost its loop flag"):
        return

    scene = load("res://main.tscn").instantiate()
    root.add_child(scene)
    scene.hide()
    scene.set_process(false)
    scene._return_to_menu()
    # A nonzero position catches scene actions that accidentally call play().
    player.seek(20.0)
    await create_timer(0.10).timeout
    previous_position = player.get_playback_position()
    if not await _checkpoint("title"):
        return
    scene._handle_tap(scene.MAIN_RESEARCH_RECT.get_center())
    if not _check(scene.research_open, "research screen did not open") or not await _checkpoint("research"):
        return
    scene._handle_tap(scene.RESEARCH_WEAPONS_RECT.get_center())
    if not _check(scene.weapon_research_open, "weapon research did not open") or not await _checkpoint("weapon research"):
        return
    scene._handle_tap(scene.WEAPON_RESEARCH_BACK_RECT.get_center())
    scene._handle_tap(scene.RESEARCH_BACK_RECT.get_center())
    scene._start_game()
    if not await _checkpoint("new run"):
        return
    scene._pause_run()
    if not await _checkpoint("pause screen"):
        return
    paused = true
    if not await _checkpoint("SceneTree pause"):
        return
    paused = false
    scene._resume_run()
    scene._open_shop()
    if not _check(scene.shop_open, "shop did not open") or not await _checkpoint("shop"):
        return
    scene._start_next_level()
    if not await _checkpoint("level transition"):
        return
    scene._finish(false)
    if not _check(scene.game_over, "death screen did not open") or not await _checkpoint("death"):
        return
    scene._return_to_menu()
    scene._start_game()
    if not await _checkpoint("restart"):
        return
    scene.queue_free()
    await process_frame
    scene = load("res://main.tscn").instantiate()
    root.add_child(scene)
    scene.hide()
    scene.set_process(false)
    if not await _checkpoint("scene replacement"):
        return

    # Repeated legitimate gestures must never restart an already active stream.
    var key := InputEventKey.new()
    key.pressed = true
    key.keycode = KEY_A
    for i in range(10):
        soundtrack._input(key)
    if not await _checkpoint("repeated autoplay-unlock input"):
        return

    # Resume requires BOTH application and audio focus; ordering can vary.
    soundtrack._set_application_paused(true)
    soundtrack._set_audio_focus_lost(true)
    var suspended_at := player.get_playback_position()
    await create_timer(0.20).timeout
    if not _check(player.stream_paused and absf(player.get_playback_position() - suspended_at) < 0.05,
        "suspension did not hold the decoder position"):
        return
    soundtrack._set_application_paused(false)
    if not _check(player.stream_paused, "resumed before Android regained audio focus"):
        return
    soundtrack._set_audio_focus_lost(false)
    if not await _checkpoint("Android resume"):
        return
    soundtrack._set_audio_focus_lost(true)
    soundtrack._set_application_paused(true)
    # An OS/driver may stop playback during the interruption. Recover at the
    # saved position, including when focus returns before the resume event.
    player.stop()
    soundtrack._set_audio_focus_lost(false)
    if not _check(not player.playing, "focus return bypassed application suspension"):
        return
    soundtrack._set_application_paused(false)
    if not await _checkpoint("Android stopped-driver recovery"):
        return

    # Cross the actual end of the real song twice, rather than mocking finished.
    for i in range(2):
        player.seek(player.stream.get_length() - 0.12)
        var playback := player.get_stream_playback()
        var loops := playback.get_loop_count()
        await create_timer(0.45).timeout
        print("Ogg loop probe: position=", player.get_playback_position(), " loops=", playback.get_loop_count(), " prior=", loops)
        if not _check(player.playing and player.get_playback_position() < 1.0
            and playback.get_loop_count() > loops, "real Ogg did not loop at EOF"):
            return
        playback = null
    scene._clear_run_snapshot()
    scene.queue_free()
    player.stop()
    player.stream = null
    imported = null
    await create_timer(0.10).timeout
    print("NEON DRIFTLINE MUSIC OK: persistent player, all screens, suspend/resume, two Ogg loops")
    call_deferred("quit", 0)

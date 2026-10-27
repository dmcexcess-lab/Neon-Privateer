extends Node
## Single-player Neon Quartet: three-song Privateer rotation, J-Space in prison only.

const PLAYLIST_IDS := ["nineteen_steps", "neon_cathedral", "do_androids_dream"]
const TRACK_PATHS := {
    "nineteen_steps": "res://assets/audio/nineteen_steps.ogg",
    "neon_cathedral": "res://assets/audio/neon_cathedral.ogg",
    "do_androids_dream": "res://assets/audio/do_androids_dream.ogg",
    "j_space": "res://assets/audio/j_space.ogg"
}
const INITIAL_VOLUME_DB := -11.0

var player: AudioStreamPlayer
var context := "playlist"
var current_track_id := ""
var playlist_index := 0
var available_playlist: Array[String] = []
var tracks: Dictionary = {}
var positions: Dictionary = {}
var _application_paused := false
var _audio_focus_lost := false
var _suspended := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    for id in TRACK_PATHS:
        var path: String = TRACK_PATHS[id]
        if not ResourceLoader.exists(path):
            push_warning("Neon Quartet recording pending: " + id)
            continue
        var song := load(path) as AudioStreamOggVorbis
        if song == null:
            push_error("Invalid Neon Quartet recording: " + path)
            continue
        song.loop = id == "j_space"
        song.loop_offset = 0.0
        tracks[id] = song
        positions[id] = 0.0
    for id in PLAYLIST_IDS:
        if tracks.has(id):
            available_playlist.append(id)
    player = AudioStreamPlayer.new()
    player.name = "PrivateerMusic"
    player.volume_db = INITIAL_VOLUME_DB
    player.max_polyphony = 1
    player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
    add_child(player)
    player.finished.connect(_on_track_finished)
    if not available_playlist.is_empty():
        _select_track(available_playlist[0], 0.0)

func _select_track(id: String, position: float) -> void:
    player.stop()
    current_track_id = id
    player.stream = tracks.get(id, null)
    if player.stream == null:
        return # Never play non-prison music while incarcerated.
    if not _suspended:
        player.play(position)
    player.stream_paused = _suspended

func set_prison(incarcerated: bool) -> void:
    var next_context := "prison" if incarcerated else "playlist"
    if next_context == context:
        return
    if tracks.has(current_track_id) and player.playing:
        positions[current_track_id] = player.get_playback_position()
    context = next_context
    if incarcerated:
        _select_track("j_space", float(positions.get("j_space", 0.0)))
    elif not available_playlist.is_empty():
        var id: String = available_playlist[playlist_index]
        _select_track(id, float(positions.get(id, 0.0)))

func _on_track_finished() -> void:
    if context != "playlist" or available_playlist.is_empty():
        return
    positions[current_track_id] = 0.0
    playlist_index = (playlist_index + 1) % available_playlist.size()
    _select_track(available_playlist[playlist_index], 0.0)

func _start_if_needed() -> void:
    if not is_instance_valid(player) or _suspended or player.stream == null:
        return
    if not player.playing:
        player.play(float(positions.get(current_track_id, 0.0)))

func _input(event: InputEvent) -> void:
    if event.device == InputEvent.DEVICE_ID_EMULATION:
        return
    if event is InputEventKey and event.pressed and not event.echo:
        _start_if_needed()
    elif event is InputEventMouseButton and event.pressed:
        _start_if_needed()
    elif event is InputEventScreenTouch and event.pressed:
        _start_if_needed()
    elif event is InputEventJoypadButton and event.pressed:
        _start_if_needed()

func _notification(what: int) -> void:
    if OS.get_name() != "Android":
        return
    match what:
        NOTIFICATION_APPLICATION_PAUSED:
            _set_application_paused(true)
        NOTIFICATION_APPLICATION_RESUMED:
            _set_application_paused(false)
        NOTIFICATION_APPLICATION_FOCUS_OUT:
            _set_audio_focus_lost(true)
        NOTIFICATION_APPLICATION_FOCUS_IN:
            _set_audio_focus_lost(false)

func _set_application_paused(value: bool) -> void:
    _application_paused = value
    _update_suspension()

func _set_audio_focus_lost(value: bool) -> void:
    _audio_focus_lost = value
    _update_suspension()

func _update_suspension() -> void:
    if not is_instance_valid(player):
        return
    var suspended := _application_paused or _audio_focus_lost
    if suspended and not _suspended and player.playing and tracks.has(current_track_id):
        positions[current_track_id] = player.get_playback_position()
    _suspended = suspended
    if player.stream != null:
        player.stream_paused = suspended
    if not suspended:
        _start_if_needed()

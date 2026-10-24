extends Node
## One persistent player; each context remembers its position between visits.

const TRACK_PATHS := {
    "port": "res://assets/audio/do_androids_dream.ogg",
    "flight": "res://assets/audio/nineteen_steps.ogg"
}
const INITIAL_VOLUME_DB := -11.0

var player: AudioStreamPlayer
var context := "port"
var tracks: Dictionary = {}
var positions := {"port": 0.0, "flight": 0.0}
var _application_paused := false
var _audio_focus_lost := false
var _suspended := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    for key in TRACK_PATHS:
        var track: AudioStreamOggVorbis = load(TRACK_PATHS[key])
        track.loop = true
        track.loop_offset = 0.0
        tracks[key] = track
    player = AudioStreamPlayer.new()
    player.name = "PrivateerMusic"
    player.volume_db = INITIAL_VOLUME_DB
    player.max_polyphony = 1
    player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
    player.stream = tracks[context]
    add_child(player)
    _start_if_needed()

func set_flight(in_flight: bool) -> void:
    var next := "flight" if in_flight else "port"
    if next == context:
        return
    # Avoid saving a stopped driver's zero over an interruption checkpoint.
    if player.playing and not _suspended:
        positions[context] = player.get_playback_position()
    context = next
    player.stream = tracks[context] # Stops the previous stream, never overlaps.
    _start_if_needed()
    player.stream_paused = _suspended

func _start_if_needed() -> void:
    if not is_instance_valid(player) or _suspended:
        return
    if not player.playing:
        player.play(float(positions[context]))

func _input(event: InputEvent) -> void:
    # Godot unlocks Web Audio on a trusted gesture in the game frame.
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
    if suspended and not _suspended and player.playing:
        positions[context] = player.get_playback_position()
    _suspended = suspended
    player.stream_paused = suspended
    if not suspended:
        _start_if_needed()

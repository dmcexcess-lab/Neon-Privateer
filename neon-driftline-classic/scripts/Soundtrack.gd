extends Node
## Classic-only autoload. Game scenes never own or restart the soundtrack.

# Neon Cathedral is the designated standalone theme; until its recording
# exists, preserve the existing real music instead of synthesizing a substitute.
const NEON_CATHEDRAL_PATH := "res://assets/audio/neon_cathedral.ogg"
const TRACK_PATH := "res://assets/audio/nineteen_steps.ogg"
var selected_track_path := ""
const INITIAL_VOLUME_DB := -11.0

var player: AudioStreamPlayer
var _application_paused := false
var _audio_focus_lost := false
var _suspended := false
var _resume_position := 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    player = AudioStreamPlayer.new()
    player.name = "ClassicMusic"
    selected_track_path = NEON_CATHEDRAL_PATH if ResourceLoader.exists(NEON_CATHEDRAL_PATH) else TRACK_PATH
    var track: AudioStreamOggVorbis = load(selected_track_path)
    # Set on the actual stream as well as in its checked-in import settings.
    track.loop = true
    track.loop_offset = 0.0
    player.stream = track
    player.volume_db = INITIAL_VOLUME_DB
    player.max_polyphony = 1
    # Keep compressed music streamed on Web, independently of the SFX mode.
    player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
    add_child(player)
    _start_if_needed()

func _start_if_needed() -> void:
    if not is_instance_valid(player) or _application_paused or _audio_focus_lost:
        return
    if not player.playing:
        player.play(_resume_position)

func _input(event: InputEvent) -> void:
    # Godot resumes Web Audio's suspended context on trusted browser input.
    # Retry playback in that gesture too, without replaying an active stream.
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
        _resume_position = player.get_playback_position()
    _suspended = suspended
    # stream_paused retains the decoder and position; play() would reset it.
    player.stream_paused = suspended
    if not suspended:
        _start_if_needed()

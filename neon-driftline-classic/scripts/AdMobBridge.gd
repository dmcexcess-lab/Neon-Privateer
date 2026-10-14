extends Node
# Optional Android-only AdMob integration. Uses Poing Studios' Godot v5.1.0
# addon via dynamic loading, so Web/desktop and headless smoke runs need no SDK.
# The release pipeline installs the pinned addon/native Android binaries.
# Only test ads are enabled by default. Never place banners over touch controls.

const API := "res://addons/admob/gdscript/src/api/"
const UMP := "res://addons/admob/gdscript/src/ump/api/"
const UMP_CORE := "res://addons/admob/gdscript/src/ump/core/"
const TEST_UNIT := "ca-app-pub-3940256099942544/1033173712"

var _mobile_script: Script
var _ump_script: Script
var _consent_info
var _loaded_ad
var _ad_loader
var _load_callback
var _full_screen_callback
var _initialized := false
var _pending := false
var _presenting := false

func _ready() -> void:
    if OS.get_name() != "Android":
        return
    if not Engine.has_singleton("PoingGodotAdMob"):
        return
    if not ResourceLoader.exists(API + "MobileAds.gd") or not ResourceLoader.exists(UMP + "UserMessagingPlatform.gd"):
        return
    _mobile_script = load(API + "MobileAds.gd")
    _ump_script = load(UMP + "UserMessagingPlatform.gd")
    if _mobile_script == null or _ump_script == null:
        return
    _consent_info = _ump_script.get("consent_information")
    if _consent_info == null:
        return
    # Update consent on every launch. No ad requests until status permits them.
    var params_script: Script = load(UMP_CORE + "ConsentRequestParameters.gd")
    if params_script == null:
        return
    var params = params_script.new()
    _consent_info.update(params, _on_consent_updated, _on_consent_error)

func _status_allows_ads() -> bool:
    # ConsentStatus: UNKNOWN=0, NOT_REQUIRED=1, REQUIRED=2, OBTAINED=3.
    if _consent_info == null:
        return false
    return int(_consent_info.get_consent_status()) in [1, 3]

func _on_consent_updated() -> void:
    if _status_allows_ads():
        _initialize_sdk()
    elif _consent_info.get_is_consent_form_available():
        _ump_script.call("load_consent_form", _on_consent_form_loaded, _on_consent_error)

func _on_consent_form_loaded(form) -> void:
    if int(_consent_info.get_consent_status()) == 2:
        form.show(_on_consent_dismissed)
    elif _status_allows_ads():
        _initialize_sdk()

func _on_consent_dismissed(_error) -> void:
    if _status_allows_ads():
        _initialize_sdk()

func _on_consent_error(_error) -> void:
    # No consent or update = no ad request. Gameplay is always available.
    if _status_allows_ads():
        _initialize_sdk()

func _initialize_sdk() -> void:
    if _initialized or _mobile_script == null:
        return
    _initialized = true
    var listener_script: Script = load(API + "listeners/OnInitializationCompleteListener.gd")
    if listener_script == null:
        return
    var listener = listener_script.new()
    listener.on_initialization_complete = _on_sdk_ready
    _mobile_script.call("initialize", listener)

func _on_sdk_ready(_status) -> void:
    _load_ad()

func _ad_unit_id() -> String:
    return String(ProjectSettings.get_setting("neon/ads/interstitial_unit_id", TEST_UNIT))

func _load_ad() -> void:
    if not _initialized or not _status_allows_ads() or _pending or _loaded_ad != null:
        return
    var unit_id := _ad_unit_id()
    if not unit_id.begins_with("ca-app-pub-") or not "/" in unit_id:
        return
    var loader_script: Script = load(API + "InterstitialAdLoader.gd")
    var callback_script: Script = load(API + "listeners/InterstitialAdLoadCallback.gd")
    var request_script: Script = load(API + "core/AdRequest.gd")
    if loader_script == null or callback_script == null or request_script == null:
        return
    _ad_loader = loader_script.new()
    _load_callback = callback_script.new()
    _load_callback.on_ad_loaded = _on_ad_loaded
    _load_callback.on_ad_failed_to_load = _on_ad_load_failed
    _pending = true
    _ad_loader.load(unit_id, request_script.new(), _load_callback)

func _on_ad_loaded(ad) -> void:
    _pending = false
    _loaded_ad = ad
    var callback_script: Script = load(API + "listeners/FullScreenContentCallback.gd")
    if callback_script == null:
        _cleanup_ad()
        return
    _full_screen_callback = callback_script.new()
    _full_screen_callback.on_ad_dismissed_full_screen_content = _on_ad_dismissed
    _full_screen_callback.on_ad_failed_to_show_full_screen_content = _on_ad_show_failed
    _full_screen_callback.on_ad_showed_full_screen_content = _on_ad_showed
    _loaded_ad.full_screen_content_callback = _full_screen_callback

func _on_ad_load_failed(_error) -> void:
    _pending = false
    _ad_loader = null

func _on_ad_showed() -> void:
    AudioServer.set_bus_mute(0, true)

func _on_ad_dismissed() -> void:
    AudioServer.set_bus_mute(0, false)
    _presenting = false
    _cleanup_ad()
    _load_ad()

func _on_ad_show_failed(_error) -> void:
    AudioServer.set_bus_mute(0, false)
    _presenting = false
    _cleanup_ad()
    _load_ad()

func _cleanup_ad() -> void:
    if _loaded_ad != null:
        _loaded_ad.destroy()
        _loaded_ad = null
    _ad_loader = null

func show_between_levels(completed_level: int) -> void:
    # Level 3, 6, 9, etc; no app-open ads, ads during flights, or ads at death.
    if completed_level < 3 or completed_level % 3 != 0:
        return
    if not _status_allows_ads() or _loaded_ad == null or _presenting:
        return
    _presenting = true
    _loaded_ad.show()

func open_privacy_options() -> void:
    if _ump_script != null:
        _ump_script.call("show_privacy_options_form", func(_error): pass)

func _exit_tree() -> void:
    AudioServer.set_bus_mute(0, false)
    _cleanup_ad()

extends Node
# Android-only, consent-gated AdMob top banner. Web never loads ads.
# Poing Studios Godot AdMob v5.1.0 is installed only in Android CI exports.
# Google-provided test ad IDs are the only defaults; replace before release.

const API := "res://addons/admob/gdscript/src/api/"
const UMP := "res://addons/admob/gdscript/src/ump/api/"
const UMP_CORE := "res://addons/admob/gdscript/src/ump/core/"
const TEST_BANNER_UNIT := "ca-app-pub-3940256099942544/6300978111"

var _mobile_script: Script
var _ump_script: Script
var _consent_info
var _banner
var _banner_listener
var _started := false

func _ready() -> void:
    if OS.get_name() != "Android" or not Engine.has_singleton("PoingGodotAdMob"):
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
    # Update UMP consent on every launch, before any ad requests.
    var consent_params_script: Script = load(UMP_CORE + "ConsentRequestParameters.gd")
    if consent_params_script == null:
        return
    _consent_info.update(consent_params_script.new(), _on_consent_updated, _on_consent_error)

func _may_request_ads() -> bool:
    if _consent_info == null:
        return false
    # ConsentStatus NOT_REQUIRED=1 or OBTAINED=3.
    return int(_consent_info.get_consent_status()) in [1, 3]

func _on_consent_updated() -> void:
    if _may_request_ads():
        _initialize_sdk()
    elif _consent_info.get_is_consent_form_available():
        _ump_script.load_consent_form(_on_consent_form_loaded, _on_consent_error)

func _on_consent_form_loaded(form) -> void:
    if int(_consent_info.get_consent_status()) == 2:
        form.show(_on_consent_dismissed)
    elif _may_request_ads():
        _initialize_sdk()

func _on_consent_dismissed(_error) -> void:
    if _may_request_ads():
        _initialize_sdk()

func _on_consent_error(_error) -> void:
    # Offline, SDK unavailable, consent denied: play the game ad-free.
    if _may_request_ads():
        _initialize_sdk()

func _initialize_sdk() -> void:
    if _started or _mobile_script == null:
        return
    _started = true
    var listener_script: Script = load(API + "listeners/OnInitializationCompleteListener.gd")
    if listener_script == null:
        return
    var listener = listener_script.new()
    listener.on_initialization_complete = _on_sdk_ready
    _mobile_script.initialize(listener)

func _on_sdk_ready(_status) -> void:
    _attach_banner()

func _attach_banner() -> void:
    if _banner != null or not _may_request_ads():
        return
    var unit_id: String = String(ProjectSettings.get_setting("neon/ads/banner_unit_id", TEST_BANNER_UNIT))
    if not unit_id.begins_with("ca-app-pub-") or not "/" in unit_id:
        return
    var banner_script: Script = load(API + "AdView.gd")
    var size_script: Script = load(API + "core/AdSize.gd")
    var pos_script: Script = load(API + "core/AdPosition.gd")
    var request_script: Script = load(API + "core/AdRequest.gd")
    if banner_script == null or size_script == null or pos_script == null or request_script == null:
        return
    # Fixed standard 320x50dp banner, top-center. Maintained for the whole app.
    # Never replace with a full-screen, interstitial, rewarded, or app-open ad.
    _banner = banner_script.new(unit_id, size_script.get("BANNER"), pos_script.get("TOP"))
    _banner.load_ad(request_script.new())

func open_privacy_options() -> void:
    if _ump_script != null:
        _ump_script.show_privacy_options_form(func(_error): pass)

func _exit_tree() -> void:
    if _banner != null:
        _banner.destroy()
        _banner = null

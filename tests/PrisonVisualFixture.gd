extends Node2D
## Isolated visual QA entry point. Never used by the normal game or user saves.
## Web preview: use res://tests/PrisonVisualFixture.tscn as the main scene.
const View=preload("res://covert/CovertGame.gd")
const Career=preload("res://covert/CovertCareer.gd")
const Justice=preload("res://covert/JusticeSystem.gd")
func _ready() -> void:call_deferred("_show")
func _show() -> void:
    var view=View.new();add_child(view)
    var profile:=Career.default_profile()
    Justice.record(profile.justice,"fixture","station_robbery",4)
    Justice.record(profile.justice,"fixture","police_ship_destroyed",8)
    view.configure(profile,0,"visual_fixture","ISOLATED PRISON PREVIEW",{},"fixture","VISUAL TEST AUTHORITY")
    view.serve_sentence()

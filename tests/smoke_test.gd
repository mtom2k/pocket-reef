extends Node
## Smoke test: boots the real tank and drives every settings/menu path.
##
##   godot --path . res://tests/smoke_test.tscn -- --save-file=user://smoke_test.json
##
## Prints PASS/FAIL per check and exits with code 1 on any failure.

const Main := preload("res://scenes/main.tscn")
const Tray := preload("res://scripts/tray.gd")

var _failures := 0
var _tank: Node


func _ready() -> void:
	if TankState.save_path == TankState.DEFAULT_SAVE_PATH:
		push_error("Refusing to run against the real save file; pass --save-file=user://smoke_test.json")
		get_tree().quit(2)
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TankState.save_path))
	TankState.load_state()
	TankState.roster_changed.emit()

	_tank = Main.instantiate()
	add_child(_tank)
	await _frames(10)
	await _run()
	print("SMOKE TEST %s (%d failures)" % ["PASSED" if _failures == 0 else "FAILED", _failures])
	SpeciesDB.clear_cache()
	get_tree().quit(1 if _failures else 0)


func _run() -> void:
	var win := get_window()
	_check("default roster has 8 fish", TankState.fish.size() == 8)
	_check("one Fish node per roster entry", _tank.fish_nodes().size() == TankState.fish.size())

	for s in [2, 4, 3]:
		TankState.set_setting("scale", s)
		await _frames(3)
		_check("scale %d resizes window" % s, win.size == _tank.TANK_SIZE * _tank._pixel_scale())

	TankState.set_setting("tank_visible", false)
	await _frames(3)
	_check("hide tank", not _tank.visible and win.mouse_passthrough)
	TankState.set_setting("tank_visible", true)
	await _frames(3)
	_check("show tank", _tank.visible and not win.mouse_passthrough)

	TankState.set_setting("always_on_top", false)
	await _frames(2)
	_check("always-on-top off", not win.always_on_top)
	TankState.set_setting("always_on_top", true)
	await _frames(2)
	_check("always-on-top on", win.always_on_top)

	TankState.set_setting("muted", true)
	await _frames(2)
	_check("mute stops bubbler", not _tank._audio._loop_player.playing)
	TankState.set_setting("muted", false)
	await _frames(2)
	_check("unmute restarts bubbler", _tank._audio._loop_player.playing)

	_check("second betta refused", TankState.add_fish("betta", "royal_blue") == "Only one betta per tank.")
	_check("overstock refused", TankState.add_fish("goldfish", "default", 3) != "")
	_check("calico goldfish added", TankState.add_fish("goldfish", "calico") == "")
	await _frames(3)
	_check("new fish spawned", _tank.fish_nodes().size() == 9)
	TankState.remove_fish(TankState.fish[-1].id)
	await _frames(3)
	_check("removed fish despawned", _tank.fish_nodes().size() == 8)

	_tank._tray._on_item(Tray.Item.FEED)
	await _frames(2)
	_check("menu feed drops food", _tank._food_layer.get_child_count() > 0)

	_tank._open_settings()
	await _frames(5)
	_check("settings window opens", _tank._settings.visible)
	_tank._settings.hide()

	TankState.save()
	_check("save file written", FileAccess.file_exists(TankState.save_path))
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TankState.save_path))
	_check("save records app version", saved.app_version == TankState.version())


func _check(what: String, ok: bool) -> void:
	print("%s  %s" % ["PASS" if ok else "FAIL", what])
	if not ok:
		_failures += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

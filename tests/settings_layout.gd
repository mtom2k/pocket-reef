extends Node
## Settings layout check: opens the settings window at several sizes and reports any control that
## sticks out past the visible width (cut off), per tab. Optionally saves screenshots.
##
##   godot --path . res://tests/settings_layout.tscn -- --save-file=user://layout.json [--shots=DIR]
##
## Exits with code 1 if anything is cut off.

const Main := preload("res://scenes/main.tscn")
const SIZES := [Vector2i(420, 400), Vector2i(520, 480), Vector2i(640, 560), Vector2i(780, 740), Vector2i(1200, 900)]

var _failures := 0


func _ready() -> void:
	if TankState.save_path == TankState.DEFAULT_SAVE_PATH:
		push_error("Pass --save-file=user://layout.json so the real tank isn't touched")
		get_tree().quit(2)
		return
	var shots := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shots = arg.trim_prefix("--shots=")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TankState.save_path))
	TankState.load_state()
	TankState.add_fish("oranda", "tricolor")
	TankState.add_fish("clownfish", "default", 2)
	var tank := Main.instantiate()
	add_child(tank)
	for c in get_window().close_requested.get_connections():
		get_window().close_requested.disconnect(c.callable)
	await get_tree().process_frame
	tank._open_settings()
	var win: Window = tank._settings
	var ui: float = win.ui_scale()
	for logical in SIZES:
		win.size = Vector2i(Vector2(logical) * ui)
		for tab in win.tabs.get_tab_count():
			win.tabs.current_tab = tab
			for i in 6:
				await get_tree().process_frame
			var limit := float(win.content_scale_size.x) + 1.0  # the window's visible width
			var cut := []
			var over: Array[Control] = []
			for node in win.find_children("*", "Control", true, false):
				var c := node as Control
				if c.is_visible_in_tree() and c.get_global_rect().end.x > limit:
					over.append(c)
			for c in over:  # report the innermost culprits, not every container around them
				if not over.any(func(o): return o != c and c.is_ancestor_of(o)):
					var label: String = str(c.get("text")) if c.get("text") else String(c.name)
					cut.append("%s '%s' min %.0f" % [c.get_class(), label.left(24), c.get_combined_minimum_size().x])
			var name: String = win.tabs.get_tab_title(tab)
			var ok := cut.is_empty()
			print("%s  %dx%d %-6s zoom %.2f%s" % ["PASS" if ok else "FAIL", logical.x, logical.y, name,
				float(win.size.x) / win.content_scale_size.x / ui, "" if ok else "  cut off: " + ", ".join(cut.slice(0, 4))])
			if not ok:
				_failures += 1
			if shots != "":
				win.get_texture().get_image().save_png("%s/%dx%d_%s.png" % [shots, logical.x, logical.y, name])
	print("LAYOUT %s (%d failures)" % ["PASSED" if _failures == 0 else "FAILED", _failures])
	SpeciesDB.clear_cache()
	get_tree().quit(1 if _failures else 0)

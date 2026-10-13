extends Node
## Performance probe: boots the real tank in a given scenario and prints engine monitors.
##
##   godot --path . res://tests/perf_probe.tscn -- --save-file=user://perf.json --scenario=busy
##
## Scenarios: "starter" (1 fish), "busy" (40 fish, 16 decorations, max tank), "hidden" (busy, tank hidden),
## "frozen" (starter with all game scripts paused, i.e. pure engine overhead).
## Options: --zoom=N (window pixels per tank pixel), --fps=N (frame cap), --mute. Engine flags such as
## --rendering-method go before the `--`. Reports its own CPU use (from `ps`) and memory. Prints one line per second for 10 s, then averages.

const Main := preload("res://scenes/main.tscn")

var _tank: Node
var _samples: Array[Dictionary] = []


func _ready() -> void:
	if TankState.save_path == TankState.DEFAULT_SAVE_PATH:
		push_error("Pass --save-file=user://perf.json so the real tank isn't touched")
		get_tree().quit(2)
		return
	var scenario := "starter"
	var zoom := 3
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scenario="):
			scenario = arg.trim_prefix("--scenario=")
		elif arg.begins_with("--zoom="):
			zoom = int(arg.trim_prefix("--zoom="))
		elif arg.begins_with("--fps="):
			ProjectSettings.set_setting("application/run/max_fps", int(arg.trim_prefix("--fps=")))

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TankState.save_path))
	TankState.load_state()
	TankState.settings.scale = zoom
	TankState.settings.muted = "--mute" in OS.get_cmdline_user_args()
	if scenario != "starter":
		TankState.set_tank_size(TankState.MAX_TANK)
		for s in [["neon_tetra", 12], ["guppy", 10], ["corydoras", 8], ["cherry_shrimp", 10]]:
			TankState.add_fish(s[0], "default", s[1])
		for i in DecorDB.MAX_ITEMS - TankState.decor.size():
			TankState.add_decor(DecorDB.DECOR.keys()[i % DecorDB.DECOR.size()])

	_tank = Main.instantiate()
	add_child(_tank)
	if scenario == "hidden":
		TankState.set_setting("tank_visible", false)
	if scenario == "frozen":  # no game scripts running: what's left is engine overhead
		await get_tree().process_frame
		_tank.process_mode = Node.PROCESS_MODE_DISABLED
	print("scenario=%s fish=%d decor=%d tank=%s" % [scenario, TankState.fish.size(), TankState.decor.size(), TankState.tank_size()])

	await get_tree().create_timer(2.0).timeout  # warm-up
	var cpu_start := _cpu_seconds()
	var wall_start := Time.get_ticks_msec()
	for i in 10:
		await get_tree().create_timer(1.0).timeout
		var s := {
			"fps": Performance.get_monitor(Performance.TIME_FPS),
			"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
			"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			"static_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
			"video_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		}
		_samples.append(s)
		print(JSON.stringify(s))
	var avg := {}
	for key in _samples[0]:
		var total := 0.0
		for s in _samples:
			total += s[key]
		avg[key] = snappedf(total / _samples.size(), 0.01)
	avg["cpu_percent"] = snappedf(100.0 * (_cpu_seconds() - cpu_start) / ((Time.get_ticks_msec() - wall_start) / 1000.0), 0.1)
	var rss := []
	OS.execute("ps", ["-o", "rss=", "-p", str(OS.get_process_id())], rss)
	avg["rss_mb"] = snappedf(int(rss[0].strip_edges()) / 1024.0, 0.1)
	print("AVERAGE ", JSON.stringify(avg))
	SpeciesDB.clear_cache()
	get_tree().quit()


## Total CPU time this process has used (user + system), from `ps`.
func _cpu_seconds() -> float:
	var out := []
	OS.execute("ps", ["-o", "time=", "-p", str(OS.get_process_id())], out)
	var parts: PackedStringArray = out[0].strip_edges().split(":")  # [[hh:]mm:]ss.cc
	var total := 0.0
	for part in parts:
		total = total * 60.0 + float(part)
	return total

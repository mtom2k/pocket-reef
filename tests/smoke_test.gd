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

	_tank = Main.instantiate()
	add_child(_tank)
	# Auto-quit utilities (e.g. one that quits apps after their last window closes) treat this
	# test run, a regular "Godot" app, as fair game once the settings window closes. The packaged
	# menu-bar app isn't affected. Keep the test running and say so.
	for c in get_window().close_requested.get_connections():
		get_window().close_requested.disconnect(c.callable)
	get_window().close_requested.connect(func(): print("NOTE  ignored a quit request from outside the app"))
	await _frames(10)
	await _run()
	print("SMOKE TEST %s (%d failures)" % ["PASSED" if _failures == 0 else "FAILED", _failures])
	SpeciesDB.clear_cache()
	get_tree().quit(1 if _failures else 0)


func _run() -> void:
	var win := get_window()

	# New tank
	_check("new tank starts with one fish", TankState.fish.size() == 1)
	_check("...and it's a goldfish", TankState.fish[0].species == "goldfish")
	_check("one Fish node per roster entry", _tank.fish_nodes().size() == TankState.fish.size())
	_check("starter decorations placed", _tank._decor.get_child_count() == DecorDB.DEFAULT_LAYOUT.size())
	_check("air stone emits bubbles", _tank._decor.emitters().size() == 1)

	# Zoom
	for s in [2, 4, 3]:
		TankState.set_setting("scale", s)
		await _frames(3)
		_check("zoom %d resizes window" % s, win.size == _tank.tank_size * _tank._pixel_scale())

	# Tank size
	TankState.set_tank_size(Vector2i(10, 10))
	await _frames(3)
	_check("tank can't shrink below minimum", _tank.tank_size == TankState.MIN_TANK)
	_check("window follows tank size", win.size == TankState.MIN_TANK * _tank._pixel_scale())
	_check("viewport follows tank size", win.content_scale_size == TankState.MIN_TANK)
	_check("water redrawn at new size", _tank._water.texture.get_size() == Vector2(TankState.MIN_TANK))
	_check("capacity shrinks with the tank", TankState.capacity() < TankState.BASE_CAPACITY)
	_check("nano tank refuses an angelfish (overstock)", TankState.add_fish("angelfish", "default") != "")
	await _frames(20)
	var inside := true
	for f: Fish in _tank.fish_nodes():
		inside = inside and Rect2(Vector2.ZERO, Vector2(_tank.tank_size)).has_point(f.position)
	_check("fish stay inside the shrunken tank", inside)
	TankState.set_tank_size(Vector2i(999, 999))
	await _frames(3)
	_check("tank can't grow past maximum", _tank.tank_size == TankState.MAX_TANK)
	TankState.set_tank_size(Vector2i(133, 101))
	_check("sizes snap to %d px" % TankState.SIZE_STEP, TankState.tank_size() == Vector2i(136, 104))
	TankState.set_tank_size(TankState.DEFAULT_TANK)
	await _frames(3)

	# Timing model: uncapped loop in low-processor mode; the tank animates on its own clock.
	_check("loop is uncapped, in low-processor mode", Engine.max_fps == 0 and OS.low_processor_usage_mode)
	for mode in TankState.PERFORMANCE_MODES:
		TankState.set_setting("performance", mode)
		var want: int = TankState.PERFORMANCE_MODES[mode].fps
		var ticks := await _ticks_per_second(1.0)
		_check("%s: tank animates at %d/s (measured %.1f)" % [mode, want, ticks], absf(ticks - want) <= want * 0.15)
	TankState.set_setting("performance", "balanced")
	var draws := await _draws_per_second(1.0)
	_check("visible tank redraws only on its ticks (%.1f frames/s)" % draws, draws <= 22.0 and draws >= 15.0)
	_check("bubbles are flowing", _tank._bubble_layer.count() > 0)

	# The settings window is not held back by the tank's frame rate.
	TankState.set_setting("performance", "saver")
	_tank._open_settings()
	await _frames(5)
	var ui_frames := Engine.get_frames_drawn()
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 1000:
		_tank._settings._stock_bar.value = randf() * _tank._settings._stock_bar.max_value  # a UI change every iteration
		await get_tree().process_frame
	var ui_rate := (Engine.get_frames_drawn() - ui_frames) / ((Time.get_ticks_msec() - t0) / 1000.0)
	_check("settings UI redraws at %.0f frames/s while the tank runs at 12" % ui_rate, ui_rate >= 50.0)
	_tank._settings.hide()
	_tank._settings._update_stocking()
	TankState.set_setting("performance", "balanced")
	await _frames(3)

	var behind := await _water_behind_tank()
	var tank_on_screen := await _screen_water_fraction()
	TankState.set_setting("tank_visible", false)
	await get_tree().create_timer(0.5).timeout
	_check("hide tank", not _tank.visible and win.mouse_passthrough)
	draws = await _draws_per_second(1.0)
	_check("hidden tank draws nothing (%.1f frames/s)" % draws, draws < 0.5)
	_check("hidden tank checks input every %d ms" % (_tank.IDLE_SLEEP_USEC / 1000),
		OS.low_processor_usage_mode_sleep_usec == _tank.IDLE_SLEEP_USEC)
	if tank_on_screen >= 0.0:
		var after := await _screen_water_fraction()
		_check("hidden tank really disappears from the screen (water %.0f%% -> %.0f%%, %.0f%% is whatever is behind it)"
			% [tank_on_screen * 100, after * 100, behind * 100],
			tank_on_screen > behind + 0.15 and after <= behind + 0.05)
	_tank._tray._menus[0].about_to_popup.emit()
	await _frames(1)
	_check("menu open: input checked every %.1f ms" % (_tank.ACTIVE_SLEEP_USEC / 1000.0),
		OS.low_processor_usage_mode_sleep_usec == _tank.ACTIVE_SLEEP_USEC)
	_tank._tray._menus[0].popup_hide.emit()
	await _frames(1)
	_check("menu closed: back to idle", OS.low_processor_usage_mode_sleep_usec == _tank.IDLE_SLEEP_USEC)
	var fish0: Fish = _tank.fish_nodes()[0]
	var where := fish0.exact_pos
	var hunger_before: float = TankState.fish[0].hunger
	await get_tree().create_timer(1.5).timeout
	_check("hidden tank pauses fish", fish0.exact_pos == where)
	_check("fish still get hungry while hidden", TankState.fish[0].hunger > hunger_before)
	_tank._open_settings()
	await _frames(2)
	_check("settings while hidden: responsive", OS.low_processor_usage_mode_sleep_usec == _tank.ACTIVE_SLEEP_USEC)
	_tank._settings.hide()
	await _frames(2)
	_check("closing settings while hidden: idle again", OS.low_processor_usage_mode_sleep_usec == _tank.IDLE_SLEEP_USEC)
	TankState.set_setting("tank_visible", true)
	await _frames(3)
	_check("show tank", _tank.visible and not win.mouse_passthrough)
	draws = await _draws_per_second(1.0)
	_check("showing resumes drawing (%.1f frames/s)" % draws, draws >= 15.0)
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

	# Covered tank (occlusion). First the logic, with the flag set by hand...
	OS.set_environment("FISHTANK_OCCLUDED", "1")
	await get_tree().create_timer(0.6).timeout
	where = fish0.exact_pos
	draws = await _draws_per_second(1.0)
	_check("covered tank pauses fish and draws nothing (%.1f frames/s)" % draws, draws < 0.5 and fish0.exact_pos == where)
	_check("covered tank still clickable", not win.mouse_passthrough and _tank.visible)
	OS.set_environment("FISHTANK_OCCLUDED", "0")
	await get_tree().create_timer(0.6).timeout
	draws = await _draws_per_second(1.0)
	_check("uncovered tank resumes (%.1f frames/s)" % draws, draws >= 15.0 and fish0.exact_pos != where)
	# ...then for real on macOS: a window moved fully off-screen is reported as not visible.
	if OS.get_name() == "macOS" and OS.has_environment("FISHTANK_OCCLUDED"):
		var home := win.position
		win.position = Vector2i(-20000, -20000)
		var waited := 0.0
		while not _tank._occluded and waited < 5.0:
			await get_tree().create_timer(0.25).timeout
			waited += 0.25
		_check("macOS reports an off-screen tank as covered (%.2fs)" % waited, _tank._occluded)
		draws = await _draws_per_second(1.0)
		_check("...and the tank stops drawing (%.1f frames/s)" % draws, draws < 0.5)
		win.position = home
		waited = 0.0
		while _tank._occluded and waited < 5.0:
			await get_tree().create_timer(0.25).timeout
			waited += 0.25
		_check("bringing it back resumes it (%.2fs)" % waited, not _tank._occluded)
		TankState.settings.window_position = [home.x, home.y]
		# Hiding while covered (drawing already stopped) must still clear the screen.
		win.position = Vector2i(-20000, -20000)
		await get_tree().create_timer(1.0).timeout
		TankState.set_setting("tank_visible", false)
		await get_tree().create_timer(0.5).timeout
		win.position = home
		await get_tree().create_timer(2.0).timeout
		var shown := await _screen_water_fraction()
		var behind_now := await _water_behind_tank()
		if shown >= 0.0:
			_check("hidden-while-covered tank stays off the screen (water %.0f%%, %.0f%% behind it)"
				% [shown * 100, behind_now * 100], shown <= behind_now + 0.05)
		TankState.set_setting("tank_visible", true)
		await get_tree().create_timer(0.5).timeout

	# Species
	_check("guppies added", TankState.add_fish("guppy", "red", 3) == "")
	_check("corydoras added", TankState.add_fish("corydoras", "albino", 2) == "")
	_check("shrimp added", TankState.add_fish("cherry_shrimp", "blue", 3) == "")
	_check("angelfish added", TankState.add_fish("angelfish", "gold") == "")
	_check("betta added", TankState.add_fish("betta", "default") == "")
	_check("second betta refused", TankState.add_fish("betta", "royal_blue") == "Only one betta per tank.")
	await _frames(60)
	_check("every species spawned", _tank.fish_nodes().size() == TankState.fish.size())
	var on_floor := true
	for f: Fish in _tank.fish_nodes():
		if f.spec.habit == "crawl":
			on_floor = on_floor and absf(f.exact_pos.y + f._half.y - 1.0 - _tank.floor_y()) < 0.01
	_check("shrimp walk on the gravel", on_floor)
	for f in TankState.fish.duplicate():
		if f.species != "goldfish":
			TankState.remove_fish(f.id)
	await _frames(3)
	_check("removed fish despawned", _tank.fish_nodes().size() == 1)

	# v0.4 species: orandas, clownfish (who move into an anemone), hillstream loaches, snails
	_check("oranda added", TankState.add_fish("oranda", "tricolor") == "")
	_check("clownfish added", TankState.add_fish("clownfish", "default", 2) == "")
	_check("hillstream loaches added", TankState.add_fish("hillstream_loach", "golden", 2) == "")
	_check("snails added", TankState.add_fish("snail", "zebra", 2) == "")
	_check("goldfish colour variants exist", SpeciesDB.SPECIES.goldfish.variants.has("sarasa")
		and ResourceLoader.exists(SpeciesDB.texture_path("goldfish", "sarasa")))
	TankState.add_decor("anemone", 0.75)
	await _frames(2)
	var home: Rect2 = _tank.decor_home("anemone")
	_check("anemone placed", home.has_area())
	await get_tree().create_timer(9.0).timeout
	var clown_dist := 0.0
	var loach_moved := false
	var loach_on_glass := true
	var snails_down := true
	for f: Fish in _tank.fish_nodes():
		match f.data.species:
			"clownfish":
				clown_dist = maxf(clown_dist, f.exact_pos.distance_to(home.get_center()))
			"hillstream_loach":
				loach_on_glass = loach_on_glass and f.z_index > 0
				loach_moved = loach_moved or f.velocity.length() > 0.0 or f._rest > 0.0
			"snail":
				snails_down = snails_down and absf(f.exact_pos.y + f._half.y - 1.0 - _tank.floor_y()) < 0.01
	_check("clownfish stay near their anemone (furthest %.0f px)" % clown_dist, clown_dist < 40.0)
	_check("hillstream loaches cling to the front glass", loach_on_glass and loach_moved)
	_check("snails crawl on the gravel", snails_down)
	for f in TankState.fish.duplicate():
		if f.species != "goldfish":
			TankState.remove_fish(f.id)
	TankState.reset_decor()
	await _frames(3)

	# Decorations
	_check("castle added", TankState.add_decor("castle", 0.5) == "")
	_check("chest added", TankState.add_decor("treasure_chest", 0.2) == "")
	await _frames(2)
	_check("decor layer shows them", _tank._decor.get_child_count() == DecorDB.DEFAULT_LAYOUT.size() + 2)
	_check("chest is a bubble emitter", _tank._decor.emitters().size() == 2)
	var castle_id: int = TankState.decor.filter(func(d): return d.type == "castle")[0].id
	var r: Rect2 = _tank._decor.item_rect(castle_id)
	_check("castle sits on the gravel", absf(r.end.y - (_tank.floor_y() + DecorDB.DECOR.castle.sink)) < 0.01)
	_check("castle hit-test", _tank._decor.item_at(r.get_center()) == castle_id)
	TankState.move_decor(castle_id, 0.8)
	await _frames(2)
	_check("castle moved", absf(_tank._decor.item_rect(castle_id).get_center().x - 0.8 * _tank.tank_size.x) <= 1.0)
	TankState.set_tank_size(TankState.MIN_TANK)
	await _frames(3)
	var trimmed := true
	for i in _tank._decor.get_child_count():
		var s: Sprite2D = _tank._decor.get_child(i)
		trimmed = trimmed and s.position.y >= TankRenderer.WATER_TOP
	_check("tall plants trimmed to the water in a small tank", trimmed)
	TankState.set_tank_size(TankState.DEFAULT_TANK)
	TankState.remove_decor(castle_id)
	await _frames(2)
	_check("castle removed", _tank._decor.item_at(r.get_center()) != castle_id)
	var too_many := ""
	for i in DecorDB.MAX_ITEMS:
		too_many = TankState.add_decor("shell")
	_check("decor limit enforced", too_many != "")
	TankState.reset_decor()
	_check("reset restores starter layout", TankState.decor.size() == DecorDB.DEFAULT_LAYOUT.size())

	# Every decoration in the catalogue spawns, sits on the gravel and can be removed
	TankState.decor.clear()
	TankState.decor_changed.emit()
	var placed_ok := true
	for type in DecorDB.DECOR:
		TankState.add_decor(type, 0.5)
		await _frames(1)
		var id: int = TankState.decor[-1].id
		var rect: Rect2 = _tank._decor.item_rect(id)
		placed_ok = placed_ok and rect.size.x > 0 and absf(rect.end.y - (_tank.floor_y() + DecorDB.DECOR[type].sink)) < 0.01
		TankState.remove_decor(id)
	_check("all %d decorations spawn on the gravel" % DecorDB.DECOR.size(), placed_ok)
	var categorised := []
	for category in DecorDB.CATEGORIES:
		categorised.append_array(category[1])
	_check("every decoration is in a catalogue category", categorised.size() == DecorDB.DECOR.size()
		and DecorDB.DECOR.keys().all(func(k): return k in categorised))
	TankState.reset_decor()

	# Floors
	var floors_ok := true
	var previous: Color = _tank._gravel.texture.get_image().get_pixel(10, _tank.tank_size.y - 8)
	for key in TankRenderer.SUBSTRATES:
		TankState.set_setting("substrate", key)
		await _frames(1)
		floors_ok = floors_ok and _tank._substrate == key
	_check("every floor type can be chosen (%d)" % TankRenderer.SUBSTRATES.size(), floors_ok)
	_check("floor change redraws the gravel",
		_tank._gravel.texture.get_image().get_pixel(10, _tank.tank_size.y - 8) != previous)
	TankState.set_setting("substrate", "gravel")

	# Decorate mode
	_tank._tray._on_item(Tray.Item.DECORATE)
	await _frames(2)
	_check("menu toggles decorate mode", TankState.decorating)
	_check("frame turns gold in decorate mode",
		_tank._frame.texture.get_image().get_pixel(0, 0).is_equal_approx(Color("feae34")))
	TankState.set_decorating(false)

	# Eating (fish decide 10x a second but chase and eat every frame)
	var gold: Fish = _tank.fish_nodes()[0]
	gold.data.hunger = 0.9
	_tank.feed_at(gold.exact_pos.x, 6)
	var waited := 0.0
	while gold.data.hunger >= 0.9 and waited < 12.0:
		await get_tree().create_timer(0.25).timeout
		waited += 0.25
	_check("hungry fish finds and eats food (%.1fs)" % waited, gold.data.hunger < 0.9)

	# Pointer interactions (simulated mouse input)
	var feed_before: int = _tank._food_layer.get_child_count()
	await _click(Vector2(60, 50))
	_check("clicking the water drops food", _tank._food_layer.get_child_count() > feed_before)

	TankState.add_decor("castle", 0.5)  # clear of the starter pieces
	TankState.set_decorating(true)
	await _frames(2)
	var cid: int = TankState.decor[-1].id
	var start: Vector2 = _tank._decor.item_rect(cid).get_center()
	await _mouse(start, MOUSE_BUTTON_LEFT, true)
	await _move(start + Vector2(40, 0))
	await _mouse(start + Vector2(40, 0), MOUSE_BUTTON_LEFT, false)
	var moved_to: float = TankState.decor[-1].x * _tank.tank_size.x
	_check("dragging a decoration moves it", absf(moved_to - (start.x + 40)) <= 1.5)
	var at: Vector2 = _tank._decor.item_rect(cid).get_center()
	await _mouse(at, MOUSE_BUTTON_LEFT, true, true)
	await _mouse(at, MOUSE_BUTTON_LEFT, false)
	_check("double-clicking a decoration flips it", TankState.decor[-1].flip)
	await _mouse(at, MOUSE_BUTTON_RIGHT, true)
	await _mouse(at, MOUSE_BUTTON_RIGHT, false)
	_check("right-clicking a decoration removes it", TankState.decor.filter(func(d): return d.id == cid).is_empty())
	TankState.set_decorating(false)

	var corner := Vector2(_tank.tank_size) - Vector2(2, 2)
	await _mouse(corner, MOUSE_BUTTON_LEFT, true)
	await _move(corner - Vector2(60, 30))
	await _mouse(corner - Vector2(60, 30), MOUSE_BUTTON_LEFT, false)
	_check("dragging the corner resizes the tank", TankState.tank_size() == Vector2i(136, 88))
	await _mouse(Vector2(_tank.tank_size) - Vector2(2, 2), MOUSE_BUTTON_LEFT, true)
	await _move(Vector2(-200, -200))
	await _mouse(Vector2(-200, -200), MOUSE_BUTTON_LEFT, false)
	_check("corner drag stops at the minimum size", TankState.tank_size() == TankState.MIN_TANK)
	TankState.set_tank_size(TankState.DEFAULT_TANK)
	await _frames(3)

	# Menu, settings, save
	_tank._tray._on_item(Tray.Item.FEED)
	await _frames(2)
	_check("menu feed drops food", _tank._food_layer.get_child_count() > 0)
	_tank._open_settings()
	await _frames(5)
	_check("settings window opens", _tank._settings.visible)
	var ui: float = _tank._settings.ui_scale()
	_check("settings window is sized for this screen (%.0fx)" % ui,
		_tank._settings.size.x >= _tank._settings.LOGICAL_SIZE.x * ui - 2
		and _tank._settings.content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS)
	_check("settings text renders at %dpx on screen" % int(UITheme.FONT_SIZE * ui),
		absf(_tank._settings.size.x / float(_tank._settings.content_scale_size.x) - ui) < 0.05)
	_tank._settings.hide()

	TankState.save()
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TankState.save_path))
	_check("save records app version", saved.app_version == TankState.version())
	_check("save records decor", saved.decor.size() == TankState.decor.size())
	_check("save records tank size", int(saved.settings.tank_width) == TankState.DEFAULT_TANK.x)
	_check("save records the floor", saved.settings.substrate == "gravel")

	TankState.add_fish("guppy", "default", 2)
	TankState.set_tank_size(TankState.MIN_TANK)
	TankState.new_tank()
	await _frames(3)
	_check("new tank: one goldfish", TankState.fish.size() == 1 and TankState.fish[0].species == "goldfish")
	_check("new tank: standard size", _tank.tank_size == TankState.DEFAULT_TANK)
	_check("new tank: starter decor", _tank._decor.get_child_count() == DecorDB.DEFAULT_LAYOUT.size())

	# Format 1 saves (v0.1.0) migrate: fish kept, starter decor added.
	var old := FileAccess.open(TankState.save_path, FileAccess.WRITE)
	old.store_string(JSON.stringify({"format": 1, "saved_at": Time.get_unix_time_from_system(),
		"settings": {"scale": 3}, "next_id": 3,
		"fish": [{"id": 1, "species": "betta", "variant": "default", "name": "Fig", "hunger": 0.2},
			{"id": 2, "species": "neon_tetra", "variant": "default", "name": "Pip", "hunger": 0.2}]}))
	old.close()
	TankState.load_state()
	_check("v0.1 save keeps its fish", TankState.fish.size() == 2)
	_check("v0.1 save gets starter decor", TankState.decor.size() == DecorDB.DEFAULT_LAYOUT.size())
	_check("v0.1 save gets default tank size", TankState.tank_size() == TankState.DEFAULT_TANK)


func _check(what: String, ok: bool) -> void:
	print("%s  %s" % ["PASS" if ok else "FAIL", what])
	if not ok:
		_failures += 1


## Same measurement for whatever is *behind* the tank (another Fishtank, a blue wallpaper...):
## the test window steps aside for a moment so the real screen can be captured.
func _water_behind_tank() -> float:
	var win := get_window()
	var home := win.position
	win.position = Vector2i(-20000, -20000)
	await get_tree().create_timer(0.6).timeout
	var f := await _screen_water_fraction(Rect2i(home, win.size))
	win.position = home
	await get_tree().create_timer(0.6).timeout
	return maxf(f, 0.0)


## Fraction of the tank window's screen area that is water-coloured, from a real screen
## capture (what the user sees, not what Godot thinks it drew). -1 if capture isn't possible.
func _screen_water_fraction(area := Rect2i()) -> float:
	if OS.get_name() != "macOS":
		return -1.0
	var win := get_window()
	if area == Rect2i():
		area = Rect2i(win.position, win.size)
	var k := DisplayServer.screen_get_scale()
	var rect := "%d,%d,%d,%d" % [area.position.x / k, area.position.y / k, area.size.x / k, area.size.y / k]
	var path := OS.get_cache_dir().path_join("fishtank_smoke_capture.png")
	OS.execute("screencapture", ["-x", "-R", rect, path])
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		return -1.0
	var water := 0
	var total := 0
	for y in range(0, img.get_height(), 6):
		for x in range(0, img.get_width(), 6):
			var c := img.get_pixel(x, y)
			total += 1
			# The water's deep blue (#124e89), allowing for the display's colour profile.
			if c.b > 0.4 and c.b < 0.65 and c.g > 0.22 and c.g < 0.4 and c.r < 0.25:
				water += 1
	return float(water) / total


func _draws_per_second(seconds: float) -> float:
	var f0 := Engine.get_frames_drawn()
	var t0 := Time.get_ticks_msec()
	await get_tree().create_timer(seconds).timeout
	return (Engine.get_frames_drawn() - f0) / ((Time.get_ticks_msec() - t0) / 1000.0)


func _ticks_per_second(seconds: float) -> float:
	var k0: int = _tank.tick_count
	var t0 := Time.get_ticks_msec()
	await get_tree().create_timer(seconds).timeout
	return (_tank.tick_count - k0) / ((Time.get_ticks_msec() - t0) / 1000.0)


## Mouse events in tank pixels, converted to window pixels like real OS events.
func _mouse(p: Vector2, button: MouseButton, pressed: bool, double := false) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = pressed
	e.double_click = double
	e.position = p * _tank._pixel_scale()
	e.global_position = e.position
	Input.parse_input_event(e)
	await _frames(2)


func _move(p: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = p * _tank._pixel_scale()
	e.global_position = e.position
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(e)
	await _frames(2)


func _click(p: Vector2) -> void:
	await _mouse(p, MOUSE_BUTTON_LEFT, true)
	await _mouse(p, MOUSE_BUTTON_LEFT, false)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

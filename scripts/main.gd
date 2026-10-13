extends Node2D
## The tank: a borderless, transparent, always-on-top window you can drag around the desktop.
##
## Click the water to drop food, drag to move the tank, right-click for the menu.
## The tray / menu bar icon has the same menu.
##
## Debug: `godot --path . -- --screenshot=/tmp/tank.png` saves a frame after 3 s and quits.
## Add `--debug-feed` to drop food, `--debug-settings[=tab]` to open (and capture) the settings window.

const SettingsWindow := preload("res://scripts/settings_window.gd")
const TankAudio := preload("res://scripts/tank_audio.gd")
const Tray := preload("res://scripts/tray.gd")
const SWAY_SHADER := preload("res://shaders/sway.gdshader")
const BUBBLE_SMALL := preload("res://art/sprites/fx/bubble_small.png")
const BUBBLE_BIG := preload("res://art/sprites/fx/bubble_big.png")

const TANK_SIZE := Vector2i(192, 120)
const WATER_TOP := 10
const GRAVEL_TOP := 104
const BUBBLER_X := 182
const DRAG_THRESHOLD := 4.0
const PLANTS := [  # texture, base x, sway amplitude
	["res://art/tank/plant_tall.png", 22, 2.0],
	["res://art/tank/plant_short.png", 120, 1.0],
	["res://art/tank/plant_medium.png", 172, 2.0],
]

var _fish_layer: Node2D
var _food_layer: Node2D
var _bubble_layer: Node2D
var _audio: Node
var _tray: Node
var _settings: Window
var _school_targets := {}
var _school_timer := 0.0
var _bubble_timer := 0.0
var _press_screen := Vector2i.ZERO
var _pressing := false
var _last_window_pos := Vector2i.ZERO
var _screenshot_path := ""


func _ready() -> void:
	_build_layers()

	_audio = TankAudio.new()
	add_child(_audio)
	_tray = Tray.new()
	add_child(_tray)
	_tray.quit_requested.connect(_quit)

	TankState.roster_changed.connect(_sync_fish)
	TankState.settings_changed.connect(_apply_window_settings)
	TankState.feed_requested.connect(func(): feed_at(randf_range(20, TANK_SIZE.x - 20), 4))
	TankState.settings_window_requested.connect(_open_settings)

	_sync_fish()
	_apply_window_settings()
	get_window().close_requested.connect(_quit)

	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			_screenshot_path = arg.trim_prefix("--screenshot=")
			get_tree().create_timer(3.0).timeout.connect(_take_screenshot)
		elif arg == "--debug-feed":
			get_tree().create_timer(0.5).timeout.connect(feed_at.bind(96.0, 8))
		elif arg.begins_with("--debug-settings"):
			_open_settings.call_deferred()
			if "=" in arg:
				(func(): _settings.tabs.current_tab = int(arg.get_slice("=", 1))).call_deferred()


func _process(delta: float) -> void:
	_school_timer -= delta
	if _school_timer <= 0.0:
		_school_timer = randf_range(4.0, 8.0)
		for species in SpeciesDB.SPECIES:
			if SpeciesDB.SPECIES[species].schooling:
				_school_targets[species] = random_point_in_band(SpeciesDB.SPECIES[species].depth)

	_bubble_timer -= delta
	if _bubble_timer <= 0.0:
		_bubble_timer = randf_range(0.2, 0.55)
		_spawn_bubble()
	_move_bubbles(delta)

	# Native window drags don't report back, so persist the position when it changes.
	var pos := get_window().position
	if pos != _last_window_pos:
		_last_window_pos = pos
		TankState.settings.window_position = [pos.x, pos.y]
		TankState.queue_save()


# --- Scene ----------------------------------------------------------------

func _build_layers() -> void:
	_add_sprite("res://art/tank/water.png")
	for p in PLANTS:
		var mat := ShaderMaterial.new()
		mat.shader = SWAY_SHADER
		mat.set_shader_parameter("amplitude", p[2])
		mat.set_shader_parameter("seed", randf() * TAU)
		var pad := Vector2i(3, 0)
		var tex := SpeciesDB.padded_texture(p[0], pad)
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.material = mat
		s.position = Vector2(p[1] - tex.get_width() / 2, GRAVEL_TOP + 3 - tex.get_height())
		add_child(s)
	_add_sprite("res://art/tank/gravel.png")
	_fish_layer = Node2D.new()
	add_child(_fish_layer)
	_food_layer = Node2D.new()
	add_child(_food_layer)
	_bubble_layer = Node2D.new()
	add_child(_bubble_layer)
	_add_sprite("res://art/tank/frame.png")


func _add_sprite(path: String) -> void:
	var s := Sprite2D.new()
	s.texture = load(path)
	s.centered = false
	add_child(s)


func _sync_fish() -> void:
	var existing := {}
	for node: Fish in fish_nodes():
		existing[node.data.id] = node
	var wanted := {}
	for entry in TankState.fish:
		wanted[entry.id] = true
		if not existing.has(entry.id):
			var f := Fish.new()
			_fish_layer.add_child(f)
			f.setup(entry, self, random_point_in_band(SpeciesDB.SPECIES[entry.species].depth))
	for id in existing:
		if not wanted.has(id):
			existing[id].queue_free()


# --- Queries used by Fish ---------------------------------------------------

func fish_nodes() -> Array[Node]:
	return _fish_layer.get_children().filter(func(n): return not n.is_queued_for_deletion())


func clamp_to_water(p: Vector2, half: Vector2) -> Vector2:
	return Vector2(
		clampf(p.x, 2 + half.x, TANK_SIZE.x - 2 - half.x),
		clampf(p.y, WATER_TOP + 3 + half.y, GRAVEL_TOP - 1 - half.y * 0.5))


func random_point_in_band(band: Vector2) -> Vector2:
	var depth := float(GRAVEL_TOP - WATER_TOP)
	return Vector2(randf_range(14, TANK_SIZE.x - 14), WATER_TOP + depth * randf_range(band.x, band.y))


func school_target(species: String) -> Vector2:
	if not _school_targets.has(species):
		_school_targets[species] = random_point_in_band(SpeciesDB.SPECIES[species].depth)
	return _school_targets[species]


func nearest_food(from: Vector2, max_distance: float) -> Node2D:
	var best: Node2D = null
	var best_d := max_distance
	for food: Node2D in _food_layer.get_children():
		if food.is_queued_for_deletion():
			continue
		var d := from.distance_to(food.position)
		if d < best_d:
			best_d = d
			best = food
	return best


func eat(food: Node2D) -> void:
	food.queue_free()


# --- Food & bubbles -----------------------------------------------------------

func feed_at(x: float, flakes: int) -> void:
	for i in flakes:
		var food := Food.new()
		food.position = Vector2(clampf(x + randf_range(-6, 6), 4, TANK_SIZE.x - 4), WATER_TOP + 1)
		food.floor_y = GRAVEL_TOP + randf_range(-1, 2)
		_food_layer.add_child(food)


func _spawn_bubble() -> void:
	var big := randf() < 0.25
	var b := Sprite2D.new()
	b.texture = BUBBLE_BIG if big else BUBBLE_SMALL
	b.set_meta("exact", Vector2(BUBBLER_X + randf_range(-1, 1), GRAVEL_TOP - 4))
	b.set_meta("wobble", randf() * TAU)
	b.set_meta("big", big)
	_bubble_layer.add_child(b)


func _move_bubbles(delta: float) -> void:
	for b: Sprite2D in _bubble_layer.get_children():
		var p: Vector2 = b.get_meta("exact")
		var w: float = b.get_meta("wobble") + delta * 4.0
		p += Vector2(cos(w) * 4.0, -(22.0 if b.get_meta("big") else 16.0)) * delta
		b.set_meta("exact", p)
		b.set_meta("wobble", w)
		b.position = p.round()
		if p.y < WATER_TOP + 2:
			if b.get_meta("big") and randf() < 0.35:
				_audio.pop()
			b.queue_free()


# --- Input: click to feed, drag to move, right-click for menu --------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_pressing = true
				_press_screen = DisplayServer.mouse_get_position()
			elif _pressing:
				_pressing = false
				if mb.position.y > WATER_TOP and mb.position.y < GRAVEL_TOP:
					feed_at(mb.position.x, 4)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_tray.show_context_menu(DisplayServer.mouse_get_position())
	elif event is InputEventMouseMotion and _pressing:
		if Vector2(DisplayServer.mouse_get_position() - _press_screen).length() > DRAG_THRESHOLD:
			_pressing = false
			get_window().start_drag()


# --- Window -------------------------------------------------------------------

func _pixel_scale() -> int:
	var dpi_scale := DisplayServer.screen_get_scale() if OS.get_name() == "macOS" \
		else roundf(maxf(1.0, DisplayServer.screen_get_dpi() / 96.0))
	return int(TankState.settings.scale * dpi_scale)


func _apply_window_settings() -> void:
	var win := get_window()
	var s := TankState.settings
	win.always_on_top = s.always_on_top
	var new_size := TANK_SIZE * _pixel_scale()
	if win.size != new_size:
		win.size = new_size

	var pos: Array = s.window_position
	if pos.size() == 2 and _on_some_screen(Vector2i(pos[0], pos[1]), new_size):
		if win.position != Vector2i(pos[0], pos[1]):
			win.position = Vector2i(pos[0], pos[1])
	else:
		var usable := DisplayServer.screen_get_usable_rect()
		win.position = usable.position + (usable.size - new_size) / 2
	_last_window_pos = win.position

	# Godot can't hide its main window, so "hidden" = nothing drawn + clicks pass through.
	# Audio and the fish simulation keep running (hunger, background bubbling).
	visible = s.tank_visible
	win.mouse_passthrough = not s.tank_visible
	Engine.max_fps = ProjectSettings.get_setting("application/run/max_fps") if s.tank_visible else 5


func _on_some_screen(pos: Vector2i, win_size: Vector2i) -> bool:
	var centre := pos + win_size / 2
	for i in DisplayServer.get_screen_count():
		if DisplayServer.screen_get_usable_rect(i).has_point(centre):
			return true
	return false


func _open_settings() -> void:
	if _settings == null:
		_settings = SettingsWindow.new()
		add_child(_settings)
	_settings.open_near(get_window())


func _quit() -> void:
	TankState.save()
	SpeciesDB.clear_cache()
	get_tree().quit()


func _take_screenshot() -> void:
	get_viewport().get_texture().get_image().save_png(_screenshot_path)
	if _settings and _settings.visible:
		_settings.get_texture().get_image().save_png(_screenshot_path.get_basename() + "_settings.png")
	print("screenshot saved: ", _screenshot_path)
	_quit()

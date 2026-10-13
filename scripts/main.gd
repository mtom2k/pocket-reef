extends Node2D
## The tank: a borderless, transparent, always-on-top window you can drag around the desktop.
##
## Click the water to drop food, drag to move the tank, drag the bottom-right corner to resize,
## right-click for the menu. In decorate mode, drag decorations to move them, double-click to
## flip, right-click to remove, Esc to finish. The tray / menu bar icon has the same menu.
##
## Debug: `godot --path . -- --screenshot=/tmp/tank.png` saves a frame after 3 s and quits.
## Add `--debug-feed` to drop food, `--debug-settings[=tab]` to open (and capture) the settings window.

const SettingsWindow := preload("res://scripts/settings_window.gd")
const TankAudio := preload("res://scripts/tank_audio.gd")
const Tray := preload("res://scripts/tray.gd")
const DecorLayer := preload("res://scripts/decor_layer.gd")
const BubbleLayer := preload("res://scripts/bubble_layer.gd")

const DRAG_THRESHOLD := 4.0
const WINDOW_POLL := 0.5  # seconds between checks for a moved window
const OCCLUSION_POLL := 0.25  # seconds between checks of the native "can anyone see us?" flag
## Never tick slower than this, even when idle. Godot's frame cap sleeps the main thread, and
## macOS needs that thread to answer menu-bar clicks: at 1 tick a second the whole menu bar
## stalled (see tests/responsiveness.sh). 10/s is as responsive as a visible tank for ~1% CPU.
const IDLE_FPS := 10
## While one of our menus is open, so its highlight follows the mouse smoothly.
const MENU_FPS := 60
const GRIP_SIZE := 8  # bottom-right resize handle, in tank pixels

var tank_size := TankState.DEFAULT_TANK

var _water: Sprite2D
var _gravel: Sprite2D
var _frame: Sprite2D
var _decor: Node2D
var _fish_layer: Node2D
var _food_layer: Node2D
var _bubble_layer: Node2D
var _overlay: Node2D
var _audio: Node
var _tray: Node
var _settings: Window
var _school_targets := {}
var _school_timer := 0.0
var _emit_timers := {}  # decor id -> seconds until next bubble(s)
var _last_window_pos := Vector2i.ZERO
var _window_poll := 0.0
var _fish_cache: Array[Node] = []
var _hidden := false  # the player hid the tank
var _occluded := false  # macOS says no Fishtank window is visible (covered, other Space, locked...)
var _occlusion_poll := 0.0
var _menu_open := false
var _power_generation := 0  # bumped on every power-state change; cancels stale waits
var _screen_shows_tank := true  # what the last frame drawn before we stopped drawing showed
var _screenshot_path := ""

# Pointer state
var _press_screen := Vector2i.ZERO
var _pressing := false
var _resizing := false
var _resize_grab := Vector2.ZERO  # tank corner minus pointer, so the corner tracks the pointer
var _dragging_decor := -1
var _drag_offset := 0.0
var _hover_decor := -1
var _hover_grip := false


func _ready() -> void:
	_build_layers()

	_audio = TankAudio.new()
	add_child(_audio)
	_tray = Tray.new()
	add_child(_tray)
	_tray.quit_requested.connect(_quit)
	_tray.menu_open_changed.connect(_on_menu_open_changed)

	TankState.roster_changed.connect(_sync_fish)
	TankState.decor_changed.connect(func(): _decor.sync(tank_size))
	TankState.decorate_mode_changed.connect(_on_decorate_mode)
	TankState.settings_changed.connect(_apply_window_settings)
	TankState.feed_requested.connect(func(): feed_at(randf_range(20, tank_size.x - 20), 4))
	TankState.settings_window_requested.connect(_open_settings)

	_apply_window_settings()
	_sync_fish()
	get_window().close_requested.connect(_quit)
	LoginItem.refresh()

	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			_screenshot_path = arg.trim_prefix("--screenshot=")
			get_tree().create_timer(3.0).timeout.connect(_take_screenshot)
		elif arg == "--debug-feed":
			get_tree().create_timer(0.5).timeout.connect(func(): feed_at(tank_size.x / 2.0, 8))
		elif arg.begins_with("--debug-settings"):
			_open_settings.call_deferred()
			if "=" in arg:
				(func(): _settings.tabs.current_tab = int(arg.get_slice("=", 1))).call_deferred()


func _process(delta: float) -> void:
	_poll_occlusion(delta)
	if _hidden or _occluded:
		# Nobody can see the tank: nothing to draw or animate; fish just keep getting hungry.
		for f in TankState.fish:
			f.hunger = minf(1.0, f.hunger + TankState.HUNGER_PER_SECOND * delta)
		return

	_school_timer -= delta
	if _school_timer <= 0.0:
		_school_timer = randf_range(4.0, 8.0)
		for species in SpeciesDB.SPECIES:
			if SpeciesDB.SPECIES[species].schooling:
				_school_targets[species] = random_point_in_band(SpeciesDB.SPECIES[species].depth)

	_run_emitters(delta)
	_update_hover()

	# Native window drags don't report back, so persist the position when it changes.
	_window_poll -= delta
	if _window_poll <= 0.0:
		_window_poll = WINDOW_POLL
		var pos := get_window().position
		if pos != _last_window_pos:
			_last_window_pos = pos
			TankState.settings.window_position = [pos.x, pos.y]
			TankState.queue_save()


# --- Scene ----------------------------------------------------------------

func _build_layers() -> void:
	_water = _layer_sprite()
	_decor = DecorLayer.new()
	add_child(_decor)
	_gravel = _layer_sprite()
	_fish_layer = Node2D.new()
	add_child(_fish_layer)
	_food_layer = Node2D.new()
	add_child(_food_layer)
	_bubble_layer = BubbleLayer.new()
	_bubble_layer.surface_y = water_top() + 2
	_bubble_layer.surfaced.connect(_on_bubble_surfaced)
	add_child(_bubble_layer)
	_frame = _layer_sprite()
	_overlay = Node2D.new()
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)


func _layer_sprite() -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = false
	add_child(s)
	return s


func _rebuild_tank() -> void:
	_water.texture = ImageTexture.create_from_image(TankRenderer.water(tank_size))
	_gravel.texture = ImageTexture.create_from_image(TankRenderer.gravel(tank_size))
	_rebuild_frame()
	_decor.sync(tank_size)
	# Keep food inside a shrunken tank.
	for food: Food in _food_layer.get_children():
		food.floor_y = minf(food.floor_y, floor_y() + 1.0)
		food.exact_pos = food.exact_pos.clamp(Vector2(2, water_top() + 1), Vector2(tank_size.x - 3, food.floor_y))
	_overlay.queue_redraw()


func _rebuild_frame() -> void:
	_frame.texture = ImageTexture.create_from_image(TankRenderer.frame(tank_size, TankState.decorating))


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
	_fish_cache.assign(_fish_layer.get_children().filter(func(n): return not n.is_queued_for_deletion()))


# --- Queries used by Fish ---------------------------------------------------

## Every live fish. Cached on roster changes: each fish asks for this ~10 times a second.
func fish_nodes() -> Array[Node]:
	return _fish_cache


func water_top() -> float:
	return float(TankRenderer.WATER_TOP)


func floor_y() -> float:
	return float(TankRenderer.gravel_top(tank_size))


func clamp_to_water(p: Vector2, half: Vector2) -> Vector2:
	var lo := Vector2(2 + half.x, water_top() + 3 + half.y)
	var hi := Vector2(tank_size.x - 2 - half.x, floor_y() - 1 - half.y * 0.5)
	return p.clamp(lo, hi.max(lo))


func random_point_in_band(band: Vector2) -> Vector2:
	var depth := floor_y() - water_top()
	var margin := minf(14.0, tank_size.x / 6.0)
	return Vector2(randf_range(margin, tank_size.x - margin), water_top() + depth * randf_range(band.x, band.y))


func school_target(species: String) -> Vector2:
	if not _school_targets.has(species):
		_school_targets[species] = random_point_in_band(SpeciesDB.SPECIES[species].depth)
	return _school_targets[species]


## Nearest food within `max_distance`; `on_floor_only` is for crawlers that can't swim up to it.
func nearest_food(from: Vector2, max_distance: float, on_floor_only := false) -> Node2D:
	var best: Node2D = null
	var best_d := max_distance
	for food: Node2D in _food_layer.get_children():
		if food.is_queued_for_deletion():
			continue
		if on_floor_only and food.position.y < floor_y() - 6.0:
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
		food.position = Vector2(clampf(x + randf_range(-6, 6), 4, tank_size.x - 4), water_top() + 1)
		food.floor_y = floor_y() + randf_range(-1, 2)
		_food_layer.add_child(food)


func _run_emitters(delta: float) -> void:
	var alive := {}
	for e in _decor.emitters():
		alive[e.id] = true
		var t: float = _emit_timers.get(e.id, randf_range(0.0, 3.0)) - delta
		if t <= 0.0:
			if e.mode == "stream":
				_spawn_bubble(e.position, randf() < 0.25)
				t = randf_range(0.2, 0.55)
			else:  # burst: a little gush every so often
				for i in randi_range(4, 8):
					_spawn_bubble(e.position + Vector2(randf_range(-2, 2), i * 3), randf() < 0.4)
				t = randf_range(6.0, 14.0)
		_emit_timers[e.id] = t
	for id in _emit_timers.keys():
		if not alive.has(id):
			_emit_timers.erase(id)


func _spawn_bubble(at: Vector2, big: bool) -> void:
	_bubble_layer.spawn(at, big)


func _on_bubble_surfaced(big: bool) -> void:
	if big and randf() < 0.35:
		_audio.pop()


# --- Input ----------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		TankState.set_decorating(false)
	elif event is InputEventMouseButton:
		_on_mouse_button(event)
	elif event is InputEventMouseMotion:
		_on_mouse_motion(event)


func _on_mouse_button(mb: InputEventMouseButton) -> void:
	var p := mb.position
	if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
		var id: int = _decor.item_at(p) if TankState.decorating else -1
		if id >= 0:
			TankState.remove_decor(id)
		else:
			_tray.show_context_menu(DisplayServer.mouse_get_position())
		return
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return

	if mb.pressed:
		_press_screen = DisplayServer.mouse_get_position()
		var id: int = _decor.item_at(p) if TankState.decorating else -1
		if _in_grip(p):
			_resizing = true
			_resize_grab = Vector2(tank_size) - p
		elif id >= 0 and mb.double_click:
			TankState.flip_decor(id)
		elif id >= 0:
			_dragging_decor = id
			_drag_offset = p.x - _decor.item_rect(id).get_center().x
		else:
			_pressing = true
		return

	# Release
	if _resizing:
		_resizing = false
	elif _dragging_decor >= 0:
		TankState.move_decor(_dragging_decor, (p.x - _drag_offset) / tank_size.x)
		_dragging_decor = -1
	elif _pressing:
		_pressing = false
		if not TankState.decorating and p.y > water_top() and p.y < floor_y():
			feed_at(p.x, 4)


func _on_mouse_motion(mm: InputEventMouseMotion) -> void:
	if _resizing:
		# The window's top-left stays put while resizing, so the pointer position gives the size.
		TankState.set_tank_size(Vector2i((mm.position + _resize_grab).round()))
	elif _dragging_decor >= 0:
		_decor.preview_move(_dragging_decor, (mm.position.x - _drag_offset) / tank_size.x)
		_overlay.queue_redraw()
	elif _pressing:
		if Vector2(DisplayServer.mouse_get_position() - _press_screen).length() > DRAG_THRESHOLD:
			_pressing = false
			get_window().start_drag()


func _in_grip(p: Vector2) -> bool:
	return p.x >= tank_size.x - GRIP_SIZE and p.y >= tank_size.y - GRIP_SIZE


func _update_hover() -> void:
	var p := get_viewport().get_mouse_position()
	var inside := Rect2(Vector2.ZERO, Vector2(tank_size)).has_point(p)
	var grip := inside and (_in_grip(p) or _resizing)
	var deco: int = _decor.item_at(p) if inside and TankState.decorating else -1
	if _dragging_decor >= 0:
		deco = _dragging_decor
	if grip != _hover_grip or deco != _hover_decor:
		_hover_grip = grip
		_hover_decor = deco
		_overlay.queue_redraw()
		var shape := Input.CURSOR_ARROW
		if grip:
			shape = Input.CURSOR_FDIAGSIZE
		elif deco >= 0:
			shape = Input.CURSOR_DRAG if _dragging_decor >= 0 else Input.CURSOR_MOVE
		Input.set_default_cursor_shape(shape)


func _draw_overlay() -> void:
	var amber := Color("feae34")
	if TankState.decorating and _hover_decor >= 0:
		var r: Rect2 = _decor.item_rect(_hover_decor).grow(1)
		_overlay.draw_rect(r, Color(amber, 0.9), false, 1.0)
	if _hover_grip or TankState.decorating:
		# Three diagonal pixel steps, like a window's resize corner.
		var c := Color("c0cbdc") if not TankState.decorating else amber
		for i in 3:
			for j in range(i + 1):
				_overlay.draw_rect(Rect2(tank_size.x - 3 - j * 2, tank_size.y - 3 - (i - j) * 2, 1, 1), c)


func _on_decorate_mode() -> void:
	_rebuild_frame()
	_hover_decor = -1
	_overlay.queue_redraw()


# --- Window -------------------------------------------------------------------

func _pixel_scale() -> int:
	var dpi_scale := DisplayServer.screen_get_scale() if OS.get_name() == "macOS" \
		else roundf(maxf(1.0, DisplayServer.screen_get_dpi() / 96.0))
	return int(TankState.settings.scale * dpi_scale)


func _apply_window_settings() -> void:
	var win := get_window()
	var s := TankState.settings
	win.always_on_top = s.always_on_top

	var new_tank := TankState.tank_size()
	if new_tank != tank_size or _water.texture == null:
		tank_size = new_tank
		win.content_scale_size = tank_size
		_rebuild_tank()
	var new_size := tank_size * _pixel_scale()
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

	_hidden = not s.tank_visible
	visible = not _hidden
	win.mouse_passthrough = _hidden
	if _hidden:
		_bubble_layer.clear()
	_apply_power_state()


## The native plugin (native/macos_agent) sets FISHTANK_OCCLUDED when macOS reports that no
## Fishtank window can be seen. Elsewhere the variable is never set, so the tank never pauses.
func _poll_occlusion(delta: float) -> void:
	_occlusion_poll -= delta
	if _occlusion_poll > 0.0:
		return
	_occlusion_poll = OCCLUSION_POLL
	var occluded := OS.get_environment("FISHTANK_OCCLUDED") == "1"
	if occluded != _occluded:
		_occluded = occluded
		_apply_power_state()


## Godot can't hide its main window, so "hidden" means: nothing drawn, clicks pass through,
## and the main loop idles. A covered tank (occluded) idles the same way but stays clickable.
## The bubbling sound keeps playing either way (it has its own thread).
func _apply_power_state() -> void:
	_power_generation += 1
	var generation := _power_generation
	var paused := _hidden or _occluded
	for layer in [_fish_layer, _food_layer, _bubble_layer]:
		layer.process_mode = Node.PROCESS_MODE_DISABLED if paused else Node.PROCESS_MODE_INHERIT
	var settings_open := _settings != null and _settings.visible
	var idle := paused and not settings_open
	var fps := TankState.target_fps()
	if idle:
		fps = IDLE_FPS
	if _menu_open:
		fps = MENU_FPS
	# macOS menus are native, so Godot can stop drawing entirely while idle. Elsewhere Godot
	# draws the tray menu itself, so it keeps rendering.
	var stop_drawing := idle and OS.get_name() == "macOS"
	if not stop_drawing:
		RenderingServer.render_loop_enabled = true
		_screen_shows_tank = visible
		Engine.max_fps = fps
		return
	if _screen_shows_tank != visible:
		# The tank was just hidden (or shown): draw two more frames first (the window is
		# double-buffered) so the screen matches, e.g. an empty window after "Show Tank" is
		# unchecked. Stopping straight away left the last frame of fish frozen on screen.
		# While covered, macOS draws nothing, so this finishes once the window is uncovered.
		RenderingServer.render_loop_enabled = true
		Engine.max_fps = IDLE_FPS if _occluded else TankState.target_fps()
		for i in 2:
			await RenderingServer.frame_post_draw
		if generation != _power_generation:
			return  # something changed while we waited; that call has taken over
		_screen_shows_tank = visible
	# Covered with nothing changed: nobody can see the last frame, so stop straight away.
	RenderingServer.render_loop_enabled = false
	Engine.max_fps = fps


func _on_menu_open_changed(open: bool) -> void:
	_menu_open = open
	_apply_power_state()


func _on_some_screen(pos: Vector2i, win_size: Vector2i) -> bool:
	var centre := pos + win_size / 2
	for i in DisplayServer.get_screen_count():
		if DisplayServer.screen_get_usable_rect(i).has_point(centre):
			return true
	return false


func _open_settings() -> void:
	if _settings == null:
		_settings = SettingsWindow.new()
		_settings.visibility_changed.connect(_apply_power_state)
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

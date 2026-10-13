extends Node
## Autoload: everything the player can change (settings, fish roster, decorations),
## persisted to user://tank.json.
##
## Roster entries are plain Dictionaries shared by reference with the Fish nodes, so hunger
## changes made by a fish are saved without extra bookkeeping.

signal settings_changed
signal roster_changed
signal decor_changed
signal decorate_mode_changed
signal feed_requested
signal settings_window_requested

const DEFAULT_SAVE_PATH := "user://tank.json"
const SAVE_FORMAT := 2

## Tank dimensions in art pixels. Width/height snap to SIZE_STEP.
const DEFAULT_TANK := Vector2i(192, 120)
const MIN_TANK := Vector2i(96, 72)
const MAX_TANK := Vector2i(256, 144)
const SIZE_STEP := 8
const SIZE_PRESETS := [
	["Nano", Vector2i(96, 72)], ["Small", Vector2i(128, 88)],
	["Standard", Vector2i(192, 120)], ["Large", Vector2i(256, 144)],
]
## Stocking points for the standard tank; scales with tank area.
const BASE_CAPACITY := 24
## Full to starving in about four hours, including while the app is closed.
const HUNGER_PER_SECOND := 0.25 / 3600.0

var settings := {
	"scale": 3,
	"volume": 0.4,
	"muted": false,
	"always_on_top": true,
	"tank_visible": true,
	"window_position": [],
	"tank_width": DEFAULT_TANK.x,
	"tank_height": DEFAULT_TANK.y,
}
var fish: Array[Dictionary] = []
var decor: Array[Dictionary] = []  # {id, type, x (0..1 of tank width), flip}
## Not saved: decorate mode always starts off.
var decorating := false

var save_path := DEFAULT_SAVE_PATH
var _next_id := 1
var _save_timer: Timer


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save-file="):  # used by tests to keep the real tank untouched
			save_path = arg.trim_prefix("--save-file=")
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = 1.0
	_save_timer.timeout.connect(save)
	add_child(_save_timer)

	var autosave := Timer.new()
	autosave.wait_time = 60.0
	autosave.timeout.connect(save)
	add_child(autosave)
	autosave.start()

	load_state()


func version() -> String:
	return ProjectSettings.get_setting("application/config/version", "0.0.0")


func app_name() -> String:
	return ProjectSettings.get_setting("application/config/name", "Fishtank")


func set_setting(key: String, value: Variant) -> void:
	if settings.get(key) == value:
		return
	settings[key] = value
	settings_changed.emit()
	queue_save()


func queue_save() -> void:
	_save_timer.start()


func set_decorating(on: bool) -> void:
	if decorating != on:
		decorating = on
		decorate_mode_changed.emit()


# --- Tank size ----------------------------------------------------------------

func tank_size() -> Vector2i:
	return Vector2i(settings.tank_width, settings.tank_height)


func set_tank_size(size: Vector2i) -> void:
	size = clamp_tank_size(size)
	if size == tank_size():
		return
	settings.tank_width = size.x
	settings.tank_height = size.y
	settings_changed.emit()
	queue_save()


func clamp_tank_size(size: Vector2i) -> Vector2i:
	var snapped := Vector2i(snappedi(size.x, SIZE_STEP), snappedi(size.y, SIZE_STEP))
	return snapped.clamp(MIN_TANK, MAX_TANK)


func capacity() -> int:
	var area := float(settings.tank_width * settings.tank_height)
	return maxi(4, roundi(BASE_CAPACITY * area / (DEFAULT_TANK.x * DEFAULT_TANK.y)))


# --- Roster -----------------------------------------------------------------

func stocking() -> int:
	var total := 0
	for f in fish:
		total += SpeciesDB.SPECIES[f.species].bioload
	return total


func count_of(species: String) -> int:
	return fish.filter(func(f): return f.species == species).size()


## Empty string if the fish can be added, otherwise a player-facing reason.
func why_cannot_add(species: String, amount := 1) -> String:
	var spec: Dictionary = SpeciesDB.SPECIES[species]
	if count_of(species) + amount > spec.max:
		if spec.max == 1:
			return "Only one %s per tank." % spec.name.to_lower()
		return "At most %d of this species per tank." % spec.max
	if stocking() + spec.bioload * amount > capacity():
		return "Not enough room: the tank would be overstocked. Try a bigger tank."
	return ""


func add_fish(species: String, variant: String, amount := 1) -> String:
	var reason := why_cannot_add(species, amount)
	if reason != "":
		return reason
	for i in amount:
		fish.append({
			"id": _take_id(),
			"species": species,
			"variant": variant,
			"name": SpeciesDB.random_name(),
			"hunger": 0.3,
		})
	roster_changed.emit()
	queue_save()
	return ""


func remove_fish(id: int) -> void:
	fish = fish.filter(func(f): return f.id != id)
	roster_changed.emit()
	queue_save()


func rename_fish(id: int, new_name: String) -> void:
	for f in fish:
		if f.id == id and new_name.strip_edges() != "":
			f.name = new_name.strip_edges()
			queue_save()


# --- Decorations ----------------------------------------------------------------

func add_decor(type: String, x := -1.0) -> String:
	if decor.size() >= DecorDB.MAX_ITEMS:
		return "The tank is full of decorations (max %d)." % DecorDB.MAX_ITEMS
	decor.append({"id": _take_id(), "type": type, "x": x if x >= 0.0 else randf_range(0.1, 0.9), "flip": false})
	decor_changed.emit()
	queue_save()
	return ""


func remove_decor(id: int) -> void:
	decor = decor.filter(func(d): return d.id != id)
	decor_changed.emit()
	queue_save()


func move_decor(id: int, x: float) -> void:
	for d in decor:
		if d.id == id:
			d.x = clampf(x, 0.0, 1.0)
	decor_changed.emit()
	queue_save()


func flip_decor(id: int) -> void:
	for d in decor:
		if d.id == id:
			d.flip = not d.flip
	decor_changed.emit()
	queue_save()


func reset_decor() -> void:
	decor.clear()
	for item in DecorDB.DEFAULT_LAYOUT:
		decor.append({"id": _take_id(), "type": item[0], "x": item[1], "flip": false})
	decor_changed.emit()
	queue_save()


func _take_id() -> int:
	_next_id += 1
	return _next_id - 1


## Starts over: one goldfish, the starter decorations and the standard tank size.
## Display preferences (zoom, volume, position...) are kept.
func new_tank() -> void:
	fish.clear()
	settings.tank_width = DEFAULT_TANK.x
	settings.tank_height = DEFAULT_TANK.y
	add_fish("goldfish", "default")
	reset_decor()
	settings_changed.emit()


# --- Persistence ----------------------------------------------------------

func save() -> void:
	var data := {
		"format": SAVE_FORMAT,
		"app_version": version(),
		"saved_at": Time.get_unix_time_from_system(),
		"settings": settings,
		"fish": fish,
		"decor": decor,
		"next_id": _next_id,
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save tank: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data, "\t"))


func load_state() -> void:
	if not FileAccess.file_exists(save_path):
		new_tank()
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save file unreadable, starting a fresh tank.")
		new_tank()
		return

	for key in parsed.get("settings", {}):
		if settings.has(key):
			settings[key] = parsed.settings[key]
	for key in ["scale", "tank_width", "tank_height"]:
		settings[key] = int(settings[key])
	var size := clamp_tank_size(tank_size())
	settings.tank_width = size.x
	settings.tank_height = size.y

	var away: float = maxf(0.0, Time.get_unix_time_from_system() - float(parsed.get("saved_at", 0)))
	fish.clear()
	for f in parsed.get("fish", []):
		if not SpeciesDB.SPECIES.has(f.get("species", "")):
			continue
		fish.append({
			"id": int(f.id),
			"species": f.species,
			"variant": f.get("variant", "default"),
			"name": f.get("name", SpeciesDB.random_name()),
			"hunger": clampf(float(f.get("hunger", 0.3)) + away * HUNGER_PER_SECOND, 0.0, 1.0),
		})
	_next_id = int(parsed.get("next_id", fish.size() + 1))

	decor.clear()
	if int(parsed.get("format", 1)) < 2:
		reset_decor()  # format 1 had a fixed layout; give it the same one as editable decor
	else:
		for d in parsed.get("decor", []):
			if DecorDB.DECOR.has(d.get("type", "")):
				decor.append({"id": int(d.id), "type": d.type, "x": float(d.x), "flip": bool(d.get("flip", false))})

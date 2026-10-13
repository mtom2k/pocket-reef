extends Node
## Autoload: everything the player can change (settings + fish roster), persisted to user://tank.json.
##
## Roster entries are plain Dictionaries shared by reference with the Fish nodes, so hunger
## changes made by a fish are saved without extra bookkeeping.

signal settings_changed
signal roster_changed
signal feed_requested
signal settings_window_requested

const DEFAULT_SAVE_PATH := "user://tank.json"
const SAVE_FORMAT := 1
const CAPACITY := 24
## Full to starving in about four hours, including while the app is closed.
const HUNGER_PER_SECOND := 0.25 / 3600.0

var settings := {
	"scale": 3,
	"volume": 0.4,
	"muted": false,
	"always_on_top": true,
	"tank_visible": true,
	"window_position": [],
}
var fish: Array[Dictionary] = []

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
		return "At most %d %ss per tank." % [spec.max, spec.name.to_lower()]
	if stocking() + spec.bioload * amount > CAPACITY:
		return "Not enough room: the tank would be overstocked."
	return ""


func add_fish(species: String, variant: String, amount := 1) -> String:
	var reason := why_cannot_add(species, amount)
	if reason != "":
		return reason
	for i in amount:
		fish.append({
			"id": _next_id,
			"species": species,
			"variant": variant,
			"name": SpeciesDB.random_name(),
			"hunger": 0.3,
		})
		_next_id += 1
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


func _default_roster() -> void:
	fish.clear()
	add_fish("goldfish", "default")
	add_fish("betta", "default")
	add_fish("neon_tetra", "default", 6)


# --- Persistence ----------------------------------------------------------

func save() -> void:
	var data := {
		"format": SAVE_FORMAT,
		"app_version": version(),
		"saved_at": Time.get_unix_time_from_system(),
		"settings": settings,
		"fish": fish,
		"next_id": _next_id,
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save tank: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(data, "\t"))


func load_state() -> void:
	if not FileAccess.file_exists(save_path):
		_default_roster()
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save file unreadable, starting a fresh tank.")
		_default_roster()
		return

	for key in parsed.get("settings", {}):
		if settings.has(key):
			settings[key] = parsed.settings[key]
	settings.scale = int(settings.scale)

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

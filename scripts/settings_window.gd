extends Window
## Native settings window: manage fish, tank options, and see the app version.

const LIST_ICON_SCALE := 2

var _stock_label: Label
var _stock_bar: ProgressBar
var _fish_list: VBoxContainer
var _species_pick: OptionButton
var _variant_pick: OptionButton
var _count_pick: SpinBox
var _add_status: Label
var _blurb: Label
var _scale_pick: OptionButton
var _volume: HSlider
var _mute: CheckBox
var _on_top: CheckBox
var _login: CheckBox
var _login_note: Label
var _hunger_bars := {}  # fish id -> ProgressBar
var tabs: TabContainer


func _init() -> void:
	# Must be configured before the window enters the tree (and is shown).
	visible = false
	force_native = true
	always_on_top = true
	title = "%s Settings" % TankState.app_name()
	var ui := _ui_scale()
	content_scale_factor = ui
	min_size = Vector2i(560, 600) * ui
	size = min_size
	close_requested.connect(hide)


## Shows the window centred on the screen the tank is on.
func open_near(anchor: Window) -> void:
	var screen := DisplayServer.screen_get_usable_rect(anchor.current_screen)
	position = screen.position + (screen.size - size) / 2
	show()
	grab_focus()


func _ready() -> void:

	var bg := PanelContainer.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	bg.add_child(margin)
	tabs = TabContainer.new()
	margin.add_child(tabs)
	tabs.add_child(_build_fish_tab())
	tabs.add_child(_build_tank_tab())
	tabs.add_child(_build_about_tab())

	TankState.roster_changed.connect(_rebuild_fish_list)
	TankState.settings_changed.connect(_sync_tank_tab)
	_rebuild_fish_list()
	_sync_tank_tab()


func _process(_delta: float) -> void:
	if not visible:
		return
	for f in TankState.fish:
		if _hunger_bars.has(f.id):
			_hunger_bars[f.id].value = 1.0 - f.hunger


static func _ui_scale() -> float:
	if OS.get_name() == "macOS":
		return 1.0  # macOS sizes native windows in points already
	return maxf(1.0, DisplayServer.screen_get_dpi() / 96.0)


# --- Fish tab -------------------------------------------------------------

func _build_fish_tab() -> Control:
	var root := VBoxContainer.new()
	root.name = "Fish"
	root.add_theme_constant_override("separation", 8)

	var stock_row := HBoxContainer.new()
	_stock_label = Label.new()
	_stock_label.custom_minimum_size.x = 150
	_stock_bar = ProgressBar.new()
	_stock_bar.max_value = TankState.CAPACITY
	_stock_bar.show_percentage = false
	_stock_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stock_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_stock_bar.custom_minimum_size.y = 12
	_style_bar(_stock_bar, Color("0099db"))
	stock_row.add_child(_stock_label)
	stock_row.add_child(_stock_bar)
	root.add_child(stock_row)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_fish_list = VBoxContainer.new()
	_fish_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_fish_list)
	root.add_child(scroll)

	root.add_child(HSeparator.new())
	var add_title := Label.new()
	add_title.text = "Add fish"
	root.add_child(add_title)

	var add_row := HBoxContainer.new()
	_species_pick = OptionButton.new()
	for key in SpeciesDB.SPECIES:
		_species_pick.add_item(SpeciesDB.SPECIES[key].name)
		_species_pick.set_item_metadata(_species_pick.item_count - 1, key)
	_species_pick.item_selected.connect(func(_i): _refresh_variants())
	_variant_pick = OptionButton.new()
	_count_pick = SpinBox.new()
	_count_pick.min_value = 1
	_count_pick.max_value = 12
	_count_pick.value = 1
	var add_button := Button.new()
	add_button.text = "Add"
	add_button.pressed.connect(_on_add)
	for c in [_species_pick, _variant_pick, _count_pick, add_button]:
		add_row.add_child(c)
	_species_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_variant_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(add_row)

	_blurb = Label.new()
	_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_blurb.modulate = Color(1, 1, 1, 0.7)
	root.add_child(_blurb)
	_add_status = Label.new()
	_add_status.add_theme_color_override("font_color", Color("f6757a"))
	root.add_child(_add_status)

	var feed := Button.new()
	feed.text = "Feed fish"
	feed.pressed.connect(TankState.feed_requested.emit)
	root.add_child(feed)

	_refresh_variants()
	return root


static func _style_bar(bar: ProgressBar, colour: Color) -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = colour
	fill.set_corner_radius_all(3)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("3a4466")
	bg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)


func _refresh_variants() -> void:
	var key: String = _species_pick.get_item_metadata(_species_pick.selected)
	var spec: Dictionary = SpeciesDB.SPECIES[key]
	_variant_pick.clear()
	for v in spec.variants:
		_variant_pick.add_item(spec.variants[v])
		_variant_pick.set_item_metadata(_variant_pick.item_count - 1, v)
	_blurb.text = "%s  (space per fish: %d)" % [spec.blurb, spec.bioload]
	_add_status.text = ""


func _on_add() -> void:
	var key: String = _species_pick.get_item_metadata(_species_pick.selected)
	var variant: String = _variant_pick.get_item_metadata(_variant_pick.selected)
	_add_status.text = TankState.add_fish(key, variant, int(_count_pick.value))


func _rebuild_fish_list() -> void:
	for child in _fish_list.get_children():
		child.queue_free()
	_hunger_bars.clear()

	_stock_label.text = "Stocking %d / %d" % [TankState.stocking(), TankState.CAPACITY]
	_stock_bar.value = TankState.stocking()

	if TankState.fish.is_empty():
		var empty := Label.new()
		empty.text = "Your tank is empty. Add some fish below."
		_fish_list.add_child(empty)
		return

	for f in TankState.fish:
		var spec: Dictionary = SpeciesDB.SPECIES[f.species]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var icon := TextureRect.new()
		icon.texture = load(SpeciesDB.texture_path(f.species, f.variant))
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(28, 18) * LIST_ICON_SCALE
		row.add_child(icon)

		var name_edit := LineEdit.new()
		name_edit.text = f.name
		name_edit.tooltip_text = "%s (%s)" % [spec.name, spec.variants[f.variant]]
		name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var id: int = f.id
		name_edit.text_submitted.connect(func(t): TankState.rename_fish(id, t))
		name_edit.focus_exited.connect(func(): TankState.rename_fish(id, name_edit.text))
		row.add_child(name_edit)

		var kind := Label.new()
		kind.text = spec.name
		kind.custom_minimum_size.x = 90
		row.add_child(kind)

		var hunger := ProgressBar.new()
		hunger.max_value = 1.0
		hunger.value = 1.0 - f.hunger
		hunger.show_percentage = false
		hunger.tooltip_text = "Fullness"
		hunger.custom_minimum_size = Vector2(70, 10)
		_style_bar(hunger, Color("63c74d"))
		hunger.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_hunger_bars[id] = hunger
		row.add_child(hunger)

		var remove := Button.new()
		remove.text = "Remove"
		remove.pressed.connect(func(): TankState.remove_fish(id))
		row.add_child(remove)

		_fish_list.add_child(row)


# --- Tank tab -------------------------------------------------------------

func _build_tank_tab() -> Control:
	var grid := GridContainer.new()
	grid.name = "Tank"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 12)

	_scale_pick = OptionButton.new()
	for s in [2, 3, 4, 5]:
		_scale_pick.add_item("%d×" % s, s)
	_scale_pick.item_selected.connect(func(i): TankState.set_setting("scale", _scale_pick.get_item_id(i)))
	_row(grid, "Tank size", _scale_pick)

	_volume = HSlider.new()
	_volume.max_value = 1.0
	_volume.step = 0.05
	_volume.custom_minimum_size.x = 200
	_volume.value_changed.connect(func(v): TankState.set_setting("volume", v))
	_row(grid, "Bubble volume", _volume)

	_mute = CheckBox.new()
	_mute.text = "Mute"
	_mute.toggled.connect(func(on): TankState.set_setting("muted", on))
	_row(grid, "", _mute)

	_on_top = CheckBox.new()
	_on_top.text = "Keep tank above other windows"
	_on_top.toggled.connect(func(on): TankState.set_setting("always_on_top", on))
	_row(grid, "Always on top", _on_top)

	var startup := VBoxContainer.new()
	_login = CheckBox.new()
	_login.text = "Open %s when I log in" % TankState.app_name()
	_login.toggled.connect(_on_login_toggled)
	_login_note = Label.new()
	_login_note.modulate = Color(1, 1, 1, 0.7)
	_login_note.add_theme_font_size_override("font_size", 12)
	_login_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_login_note.custom_minimum_size.x = 260
	startup.add_child(_login)
	startup.add_child(_login_note)
	_row(grid, "Startup", startup)

	var reset := Button.new()
	reset.text = "Move tank to centre of screen"
	reset.pressed.connect(func(): TankState.set_setting("window_position", []))
	_row(grid, "Position", reset)
	return grid


func _row(grid: GridContainer, label: String, control: Control) -> void:
	var l := Label.new()
	l.text = label
	grid.add_child(l)
	grid.add_child(control)


func _sync_tank_tab() -> void:
	var s := TankState.settings
	_scale_pick.select(_scale_pick.get_item_index(s.scale))
	_volume.set_value_no_signal(s.volume)
	_mute.set_pressed_no_signal(s.muted)
	_on_top.set_pressed_no_signal(s.always_on_top)
	_sync_login()


func _sync_login() -> void:
	var reason := LoginItem.unavailable_reason()
	_login.disabled = reason != ""
	_login.set_pressed_no_signal(reason == "" and LoginItem.is_enabled())
	_login_note.text = reason
	_login_note.visible = reason != ""


func _on_login_toggled(on: bool) -> void:
	var error := LoginItem.set_enabled(on)
	_sync_login()
	if error != "":
		_login_note.text = error
		_login_note.visible = true


# --- About tab ------------------------------------------------------------

func _build_about_tab() -> Control:
	var box := VBoxContainer.new()
	box.name = "About"
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)

	var icon := TextureRect.new()
	icon.texture = load("res://art/icons/app_icon.png")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(96, 96)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	box.add_child(icon)

	var lines := [
		["%s" % TankState.app_name(), 22],
		["Version %s" % TankState.version(), 16],
		["Built with Godot %s" % Engine.get_version_info().string, 12],
		["Palette: ENDESGA 32", 12],
		["Save data: %s" % ProjectSettings.globalize_path("user://"), 11],
	]
	for line in lines:
		var l := Label.new()
		l.text = line[0]
		l.add_theme_font_size_override("font_size", line[1])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(l)
	return box

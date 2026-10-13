extends Window
## Native settings window: fish, decorations and floor, tank options, and the app version.
##
## HiDPI: the window is sized in logical pixels times the screen's scale (2 on Retina) and uses
## the "canvas_items" content scale, so text is rendered at full resolution and stays crisp. When
## the user resizes the window, the layout reflows instead of zooming.

const LOGICAL_SIZE := Vector2i(780, 740)
const LOGICAL_MIN := Vector2i(640, 520)
const FISH_ICON := Vector2(72, 40)

var tabs: TabContainer

var _ui := 1.0
var _stock_label: Label
var _stock_bar: ProgressBar
var _fish_list: VBoxContainer
var _species_pick: OptionButton
var _variant_pick: OptionButton
var _count_pick: SpinBox
var _add_preview: TextureRect
var _add_status: Label
var _blurb: Label
var _hunger_bars := {}  # fish id -> ProgressBar

var _decorate_toggle: Button
var _floor_buttons := {}  # substrate key -> Button
var _decor_list: VBoxContainer
var _decor_count: Label
var _decor_status: Label

var _size_preset: OptionButton
var _width: SpinBox
var _height: SpinBox
var _scale_pick: OptionButton
var _performance: OptionButton
var _volume: HSlider
var _mute: CheckBox
var _on_top: CheckBox
var _login: CheckBox
var _login_note: Label


func _init() -> void:
	# Must be configured before the window enters the tree (and is shown).
	visible = false
	force_native = true
	always_on_top = true
	title = "%s Settings" % TankState.app_name()
	_ui = ui_scale()
	content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	min_size = Vector2i(Vector2(LOGICAL_MIN) * _ui)
	size = Vector2i(Vector2(LOGICAL_SIZE) * _ui)
	content_scale_size = LOGICAL_SIZE
	size_changed.connect(_on_size_changed)
	close_requested.connect(hide)
	theme = UITheme.build()


## Screen pixels per logical pixel: 2 on Retina Macs, DPI-based on Windows.
static func ui_scale() -> float:
	if OS.get_name() == "macOS":
		return maxf(1.0, DisplayServer.screen_get_scale())
	return maxf(1.0, DisplayServer.screen_get_dpi() / 96.0)


## Shows the window centred on the screen the tank is on, fitting it to that screen.
func open_near(anchor: Window) -> void:
	var screen := DisplayServer.screen_get_usable_rect(anchor.current_screen)
	size = size.min(Vector2i(Vector2(screen.size) * 0.92))
	position = screen.position + (screen.size - size) / 2
	show()
	grab_focus()


func _on_size_changed() -> void:
	# Keep the scale fixed at the screen's scale and give the layout the extra room.
	content_scale_size = Vector2i(Vector2(size) / _ui)


func _ready() -> void:
	var bg := PanelContainer.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := _margin(18)
	bg.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	column.add_child(_build_header())
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(tabs)
	tabs.add_child(_scroll_tab("Fish", _build_fish_tab()))
	tabs.add_child(_scroll_tab("Decor", _build_decor_tab()))
	tabs.add_child(_scroll_tab("Tank", _build_tank_tab()))
	tabs.add_child(_scroll_tab("About", _build_about_tab()))

	TankState.roster_changed.connect(_rebuild_fish_list)
	TankState.settings_changed.connect(_sync_tank_tab)
	TankState.settings_changed.connect(_update_stocking)
	TankState.settings_changed.connect(_sync_floor)
	TankState.decor_changed.connect(_rebuild_decor_list)
	TankState.decorate_mode_changed.connect(_sync_decorate_toggle)
	_rebuild_fish_list()
	_rebuild_decor_list()
	_sync_tank_tab()
	_sync_floor()
	_sync_decorate_toggle()


func _process(_delta: float) -> void:
	if not visible:
		return
	for f in TankState.fish:
		if _hunger_bars.has(f.id):
			_hunger_bars[f.id].value = 1.0 - f.hunger


# --- Layout helpers ---------------------------------------------------------

func _build_header() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.add_child(_pixel_icon(load("res://art/icons/app_icon.png"), Vector2(52, 52)))
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 0)
	titles.alignment = BoxContainer.ALIGNMENT_CENTER
	titles.add_child(_label(TankState.app_name(), "Title"))
	titles.add_child(_label("Version %s" % TankState.version(), "Hint"))
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(titles)
	var feed := _button("Feed fish", "AccentButton")
	feed.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	feed.pressed.connect(TankState.feed_requested.emit)
	row.add_child(feed)
	return row


func _scroll_tab(title: String, content: Control) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var pad := _margin(4)
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_child(content)
	scroll.add_child(pad)
	return scroll


## A titled card; returns the card's content box.
func _card(parent: Control, heading: String, hint := "") -> VBoxContainer:
	var card := PanelContainer.new()
	card.theme_type_variation = "Card"
	parent.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	if heading != "":
		box.add_child(_label(heading, "Section"))
	if hint != "":
		box.add_child(_label(hint, "Hint", true))
	return box


func _column() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return v


func _label(text: String, variation := "", wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 200
	return l


func _button(text: String, variation := "") -> Button:
	var b := Button.new()
	b.text = text
	b.theme_type_variation = variation
	return b


func _margin(px: int) -> MarginContainer:
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, px)
	return m


## A labelled row inside a card: fixed-width label on the left, control on the right.
func _setting_row(parent: Control, label: String, control: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var l := _label(label)
	l.custom_minimum_size.x = 150
	row.add_child(l)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	parent.add_child(row)


func _pixel_icon(texture: Texture2D, box: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = box
	return icon


func _bar(colour: Color, width: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(width, 12)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("fill", UITheme.bar_fill(colour))
	return bar


# --- Fish tab -------------------------------------------------------------

func _build_fish_tab() -> Control:
	var root := _column()

	var stock := _card(root, "Tank space")
	var stock_row := HBoxContainer.new()
	stock_row.add_theme_constant_override("separation", 14)
	_stock_label = _label("")
	_stock_label.custom_minimum_size.x = 260
	stock_row.add_child(_stock_label)
	_stock_bar = _bar(UITheme.ACCENT, 160)
	_stock_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stock_row.add_child(_stock_bar)
	stock.add_child(stock_row)

	var fish := _card(root, "Your fish", "Click a name to rename. The green bar shows how full each fish is.")
	_fish_list = VBoxContainer.new()
	_fish_list.add_theme_constant_override("separation", 6)
	fish.add_child(_fish_list)

	var add := _card(root, "Add fish")
	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 10)
	_add_preview = _pixel_icon(null, FISH_ICON)
	add_row.add_child(_add_preview)
	_species_pick = OptionButton.new()
	for key in SpeciesDB.SPECIES:
		_species_pick.add_item(SpeciesDB.SPECIES[key].name)
		_species_pick.set_item_metadata(_species_pick.item_count - 1, key)
	_species_pick.item_selected.connect(func(_i): _refresh_variants())
	_species_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_variant_pick = OptionButton.new()
	_variant_pick.item_selected.connect(func(_i): _refresh_preview())
	_variant_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_count_pick = SpinBox.new()
	_count_pick.min_value = 1
	_count_pick.max_value = 12
	_count_pick.value = 1
	_count_pick.tooltip_text = "How many"
	var add_button := _button("Add", "AccentButton")
	add_button.pressed.connect(_on_add)
	for c in [_species_pick, _variant_pick, _count_pick, add_button]:
		add_row.add_child(c)
	add.add_child(add_row)
	_blurb = _label("", "Hint", true)
	add.add_child(_blurb)
	_add_status = _label("", "Status", true)
	add.add_child(_add_status)

	_refresh_variants()
	return root


func _refresh_variants() -> void:
	var key: String = _species_pick.get_item_metadata(_species_pick.selected)
	var spec: Dictionary = SpeciesDB.SPECIES[key]
	_variant_pick.clear()
	for v in spec.variants:
		_variant_pick.add_item(spec.variants[v])
		_variant_pick.set_item_metadata(_variant_pick.item_count - 1, v)
	_blurb.text = "%s Takes %d space%s." % [spec.blurb, spec.bioload, "" if spec.bioload == 1 else "s"]
	_add_status.text = ""
	_refresh_preview()


func _refresh_preview() -> void:
	var key: String = _species_pick.get_item_metadata(_species_pick.selected)
	var variant: String = _variant_pick.get_item_metadata(maxi(0, _variant_pick.selected))
	_add_preview.texture = load(SpeciesDB.texture_path(key, variant))


func _on_add() -> void:
	var key: String = _species_pick.get_item_metadata(_species_pick.selected)
	var variant: String = _variant_pick.get_item_metadata(_variant_pick.selected)
	_add_status.text = TankState.add_fish(key, variant, int(_count_pick.value))


func _update_stocking() -> void:
	var used := TankState.stocking()
	var room := TankState.capacity()
	var over := used > room
	_stock_label.text = "%d of %d spaces used%s" % [used, room, "  (overstocked!)" if over else ""]
	_stock_label.add_theme_color_override("font_color", UITheme.WARN if over else UITheme.TEXT)
	_stock_bar.max_value = room
	_stock_bar.value = mini(used, room)


func _rebuild_fish_list() -> void:
	for child in _fish_list.get_children():
		child.queue_free()
	_hunger_bars.clear()
	_update_stocking()

	if TankState.fish.is_empty():
		_fish_list.add_child(_label("Your tank is empty. Add some fish below.", "Hint"))
		return

	for f in TankState.fish:
		var spec: Dictionary = SpeciesDB.SPECIES[f.species]
		var id: int = f.id
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.add_child(_pixel_icon(load(SpeciesDB.texture_path(f.species, f.variant)), FISH_ICON))

		var names := VBoxContainer.new()
		names.add_theme_constant_override("separation", 2)
		names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_edit := LineEdit.new()
		name_edit.text = f.name
		name_edit.text_submitted.connect(func(t): TankState.rename_fish(id, t))
		name_edit.focus_exited.connect(func(): TankState.rename_fish(id, name_edit.text))
		names.add_child(name_edit)
		names.add_child(_label("%s · %s" % [spec.name, spec.variants[f.variant]], "Hint"))
		row.add_child(names)

		var hunger := _bar(UITheme.GOOD, 110)
		hunger.max_value = 1.0
		hunger.value = 1.0 - f.hunger
		hunger.tooltip_text = "Fullness"
		_hunger_bars[id] = hunger
		row.add_child(hunger)

		var remove := _button("Remove")
		remove.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		remove.pressed.connect(func(): TankState.remove_fish(id))
		row.add_child(remove)
		_fish_list.add_child(row)


# --- Decor tab ------------------------------------------------------------

func _build_decor_tab() -> Control:
	var root := _column()

	var mode := _card(root, "Arrange your tank",
		"In decorate mode the glass turns gold: drag a decoration to move it, double-click to flip it, right-click to remove it, and press Esc when you're done.")
	_decorate_toggle = _button("Start decorating", "AccentButton")
	_decorate_toggle.toggle_mode = true
	_decorate_toggle.toggled.connect(TankState.set_decorating)
	mode.add_child(_decorate_toggle)

	var floor_box := _card(root, "Floor", "Pick what covers the bottom of the tank.")
	var floors := GridContainer.new()
	floors.columns = 4
	floors.add_theme_constant_override("h_separation", 8)
	floors.add_theme_constant_override("v_separation", 8)
	var group := ButtonGroup.new()
	for key in TankRenderer.SUBSTRATES:
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.icon = _floor_swatch(key)
		b.text = TankRenderer.SUBSTRATES[key].name
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		b.add_theme_font_size_override("font_size", 13)
		b.custom_minimum_size = Vector2(150, 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(TankState.set_setting.bind("substrate", key))
		floors.add_child(b)
		_floor_buttons[key] = b
	floor_box.add_child(floors)

	for category in DecorDB.CATEGORIES:
		var box := _card(root, category[0])
		var grid := GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		for type in category[1]:
			var b := Button.new()
			b.icon = _catalogue_icon(type)
			b.text = DecorDB.DECOR[type].name
			b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
			b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			b.add_theme_font_size_override("font_size", 12)
			b.clip_text = true
			b.custom_minimum_size = Vector2(118, 0)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.tooltip_text = "Add %s to the tank" % DecorDB.DECOR[type].name
			b.pressed.connect(func(): _decor_status.text = TankState.add_decor(type))
			grid.add_child(b)
		box.add_child(grid)

	var placed := _card(root, "")
	var placed_head := HBoxContainer.new()
	_decor_count = _label("", "Section")
	_decor_count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placed_head.add_child(_decor_count)
	var reset := _button("Reset to starter layout")
	reset.pressed.connect(TankState.reset_decor)
	placed_head.add_child(reset)
	placed.add_child(placed_head)
	_decor_status = _label("", "Status", true)
	placed.add_child(_decor_status)
	_decor_list = VBoxContainer.new()
	_decor_list.add_theme_constant_override("separation", 6)
	placed.add_child(_decor_list)
	return root


## Catalogue icons share a 48px canvas, with small pieces zoomed by a whole number so they
## stay crisp and readable; drawn 2x in the button.
static func _catalogue_icon(type: String) -> Texture2D:
	var src: Image = load(DecorDB.texture_path(type)).get_image()
	src.convert(Image.FORMAT_RGBA8)
	var zoom := clampi(40 / maxi(src.get_width(), src.get_height()), 1, 3)
	src.resize(src.get_width() * zoom, src.get_height() * zoom, Image.INTERPOLATE_NEAREST)
	var canvas := Image.create_empty(48, 48, false, Image.FORMAT_RGBA8)
	var at := Vector2i((48 - src.get_width()) / 2, 48 - src.get_height())
	canvas.blit_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), at)
	canvas.resize(96, 96, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(canvas)


## A strip of the actual floor, as the tank draws it.
static func _floor_swatch(key: String) -> Texture2D:
	var size := Vector2i(48, TankRenderer.GRAVEL_DEPTH + 4)
	var img := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(TankRenderer.C.dusk)
	var strip := TankRenderer.gravel(size, key)
	img.blend_rect(strip, Rect2i(Vector2i.ZERO, size), Vector2i.ZERO)
	img.resize(size.x * 3, size.y * 3, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)


func _sync_floor() -> void:
	var key: String = TankState.settings.substrate
	if _floor_buttons.has(key):
		_floor_buttons[key].set_pressed_no_signal(true)


func _sync_decorate_toggle() -> void:
	_decorate_toggle.set_pressed_no_signal(TankState.decorating)
	_decorate_toggle.text = "Done decorating" if TankState.decorating else "Start decorating"


func _rebuild_decor_list() -> void:
	for child in _decor_list.get_children():
		child.queue_free()
	_decor_count.text = "In your tank (%d of %d)" % [TankState.decor.size(), DecorDB.MAX_ITEMS]
	if TankState.decor.is_empty():
		_decor_list.add_child(_label("No decorations yet. Pick some above.", "Hint"))
	for d in TankState.decor:
		var id: int = d.id
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.add_child(_pixel_icon(load(DecorDB.texture_path(d.type)), Vector2(56, 36)))
		var label := _label(DecorDB.DECOR[d.type].name)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var flip := _button("Flip")
		flip.pressed.connect(func(): TankState.flip_decor(id))
		row.add_child(flip)
		var remove := _button("Remove")
		remove.pressed.connect(func(): TankState.remove_decor(id))
		row.add_child(remove)
		_decor_list.add_child(row)


# --- Tank tab -------------------------------------------------------------

func _build_tank_tab() -> Control:
	var root := _column()

	var size_card := _card(root, "Size", "Smallest %d × %d, largest %d × %d tank pixels. You can also drag the tank's bottom-right corner." % [
		TankState.MIN_TANK.x, TankState.MIN_TANK.y, TankState.MAX_TANK.x, TankState.MAX_TANK.y])
	_size_preset = OptionButton.new()
	for preset in TankState.SIZE_PRESETS:
		_size_preset.add_item("%s (%d × %d)" % [preset[0], preset[1].x, preset[1].y])
	_size_preset.add_item("Custom")
	_size_preset.item_selected.connect(_on_size_preset)
	_setting_row(size_card, "Preset", _size_preset)
	var dims := HBoxContainer.new()
	dims.add_theme_constant_override("separation", 8)
	_width = _size_spin(TankState.MIN_TANK.x, TankState.MAX_TANK.x)
	_height = _size_spin(TankState.MIN_TANK.y, TankState.MAX_TANK.y)
	dims.add_child(_width)
	dims.add_child(_label("×"))
	dims.add_child(_height)
	_setting_row(size_card, "Width × height", dims)

	var display := _card(root, "Display")
	_scale_pick = OptionButton.new()
	for s in [2, 3, 4, 5]:
		_scale_pick.add_item("%d×" % s, s)
	_scale_pick.item_selected.connect(func(i): TankState.set_setting("scale", _scale_pick.get_item_id(i)))
	_setting_row(display, "Zoom", _scale_pick)
	_performance = OptionButton.new()
	for key in TankState.PERFORMANCE_MODES:
		_performance.add_item(TankState.PERFORMANCE_MODES[key].name)
		_performance.set_item_metadata(_performance.item_count - 1, key)
	_performance.item_selected.connect(func(i): TankState.set_setting("performance", _performance.get_item_metadata(i)))
	_performance.tooltip_text = "Lower frame rates use less CPU and battery. The fish look almost the same at 20 fps."
	_setting_row(display, "Performance", _performance)
	_on_top = CheckBox.new()
	_on_top.text = "Keep the tank above other windows"
	_on_top.toggled.connect(func(on): TankState.set_setting("always_on_top", on))
	display.add_child(_on_top)

	var sound := _card(root, "Sound")
	_volume = HSlider.new()
	_volume.max_value = 1.0
	_volume.step = 0.05
	_volume.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_volume.value_changed.connect(func(v): TankState.set_setting("volume", v))
	_setting_row(sound, "Bubble volume", _volume)
	_mute = CheckBox.new()
	_mute.text = "Mute the bubbles"
	_mute.toggled.connect(func(on): TankState.set_setting("muted", on))
	sound.add_child(_mute)

	var system := _card(root, "System")
	_login = CheckBox.new()
	_login.text = "Open %s when I log in" % TankState.app_name()
	_login.toggled.connect(_on_login_toggled)
	system.add_child(_login)
	_login_note = _label("", "Hint", true)
	system.add_child(_login_note)
	var centre := _button("Move tank to centre of screen")
	centre.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	centre.pressed.connect(func(): TankState.set_setting("window_position", []))
	system.add_child(centre)

	var restart_card := _card(root, "Start over", "Replaces all your fish with one goldfish, restores the starter decorations and the standard size.")
	var restart := _button("Start a new tank…", "DangerButton")
	restart.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	restart.pressed.connect(_on_new_tank.bind(restart))
	restart_card.add_child(restart)
	return root


func _size_spin(lo: int, hi: int) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = lo
	spin.max_value = hi
	spin.step = TankState.SIZE_STEP
	spin.custom_minimum_size.x = 110
	spin.value_changed.connect(func(_v): TankState.set_tank_size(Vector2i(int(_width.value), int(_height.value))))
	return spin


func _on_size_preset(index: int) -> void:
	if index < TankState.SIZE_PRESETS.size():
		TankState.set_tank_size(TankState.SIZE_PRESETS[index][1])


## Two clicks needed, so a stray click can't wipe the tank.
func _on_new_tank(button: Button) -> void:
	if button.has_meta("armed"):
		button.remove_meta("armed")
		button.text = "Start a new tank…"
		TankState.new_tank()
		return
	button.set_meta("armed", true)
	button.text = "Click again to replace all your fish"
	await get_tree().create_timer(4.0).timeout
	if button.has_meta("armed"):
		button.remove_meta("armed")
		button.text = "Start a new tank…"


func _sync_tank_tab() -> void:
	var s := TankState.settings
	_scale_pick.select(_scale_pick.get_item_index(s.scale))
	for i in _performance.item_count:
		if _performance.get_item_metadata(i) == s.performance:
			_performance.select(i)
	var size := TankState.tank_size()
	_width.set_value_no_signal(size.x)
	_height.set_value_no_signal(size.y)
	var preset := TankState.SIZE_PRESETS.size()  # "Custom"
	for i in TankState.SIZE_PRESETS.size():
		if TankState.SIZE_PRESETS[i][1] == size:
			preset = i
	_size_preset.select(preset)
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
	var root := _column()
	var card := _card(root, "")
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon := _pixel_icon(load("res://art/icons/app_icon.png"), Vector2(128, 128))
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.add_child(icon)
	for line in [
		[TankState.app_name(), "Title"],
		["Version %s" % TankState.version(), "Section"],
		["A tiny aquarium that lives on your desktop.", ""],
		["Built with Godot %s · Palette: ENDESGA 32" % Engine.get_version_info().string, "Hint"],
	]:
		var l := _label(line[0], line[1])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(l)
	var data := _button("Open save folder")
	data.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	data.tooltip_text = ProjectSettings.globalize_path("user://")
	data.pressed.connect(func(): OS.shell_open(ProjectSettings.globalize_path("user://")))
	card.add_child(data)
	return root

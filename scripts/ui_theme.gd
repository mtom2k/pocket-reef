class_name UITheme
## The settings window's look: the tank's palette (ENDESGA 32), readable type, card layout.
##
## Sizes are in logical pixels; the window scales them for HiDPI screens (see settings_window.gd).
## Type variations used by the UI: "Title", "Section", "Hint", "Status", "Card",
## "AccentButton", "DangerButton".

const BG := Color("262b44")         # navy
const CARD := Color("3a4466")       # dusk
const CARD_HOVER := Color("5a6988") # slate
const INSET := Color("181425")      # ink
const ACCENT := Color("0099db")     # sky
const ACCENT_HOVER := Color("2ce8f5")
const DANGER := Color("a22633")     # crimson
const DANGER_HOVER := Color("e43b44")
const TEXT := Color("ffffff")
const TEXT_DIM := Color("c0cbdc")   # silver
const TEXT_FAINT := Color("8b9bb4") # steel
const WARN := Color("f6757a")       # salmon
const GOOD := Color("63c74d")       # leaf

const FONT_SIZE := 15


static func build() -> Theme:
	var t := Theme.new()
	t.default_font_size = FONT_SIZE

	var bold := FontVariation.new()
	bold.base_font = ThemeDB.fallback_font
	bold.variation_embolden = 0.7
	var semibold := FontVariation.new()
	semibold.base_font = ThemeDB.fallback_font
	semibold.variation_embolden = 0.4

	# Labels
	t.set_color("font_color", "Label", TEXT)
	_variation(t, "Title", "Label")
	t.set_font("font", "Title", bold)
	t.set_font_size("font_size", "Title", 22)
	_variation(t, "Section", "Label")
	t.set_font("font", "Section", semibold)
	t.set_font_size("font_size", "Section", 17)
	t.set_color("font_color", "Section", TEXT)
	_variation(t, "Hint", "Label")
	t.set_font_size("font_size", "Hint", 13)
	t.set_color("font_color", "Hint", TEXT_FAINT)
	_variation(t, "Status", "Label")
	t.set_font_size("font_size", "Status", 14)
	t.set_color("font_color", "Status", WARN)

	# Window background and cards
	t.set_stylebox("panel", "PanelContainer", _box(BG, 0, 0))
	_variation(t, "Card", "PanelContainer")
	t.set_stylebox("panel", "Card", _box(CARD, 10, 14))

	# Buttons (OptionButton inherits)
	_button(t, "Button", Color(CARD.lightened(0.08)), CARD_HOVER, INSET, TEXT)
	_button(t, "OptionButton", Color(CARD.lightened(0.08)), CARD_HOVER, INSET, TEXT)
	_variation(t, "AccentButton", "Button")
	_button(t, "AccentButton", ACCENT, ACCENT_HOVER, Color("124e89"), TEXT)
	t.set_color("font_hover_color", "AccentButton", INSET)
	t.set_font("font", "AccentButton", semibold)
	_variation(t, "DangerButton", "Button")
	_button(t, "DangerButton", DANGER, DANGER_HOVER, Color("68386c"), TEXT)
	for type in ["Button", "OptionButton", "CheckBox", "CheckButton"]:
		t.set_color("font_disabled_color", type, TEXT_FAINT)
	# Checkboxes are plain text + tick, not button-shaped.
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var flat := StyleBoxEmpty.new()
		flat.content_margin_top = 4
		flat.content_margin_bottom = 4
		t.set_stylebox(state, "CheckBox", flat)
	t.set_color("font_color", "CheckBox", TEXT)
	t.set_color("font_hover_color", "CheckBox", ACCENT_HOVER)
	t.set_color("font_pressed_color", "CheckBox", TEXT)
	t.set_constant("h_separation", "CheckBox", 8)

	# Text fields
	var field := _box(INSET, 6, 8)
	field.content_margin_top = 6
	field.content_margin_bottom = 6
	t.set_stylebox("normal", "LineEdit", field)
	var focus := _box(INSET, 6, 8)
	focus.border_color = ACCENT
	focus.set_border_width_all(2)
	t.set_stylebox("focus", "LineEdit", focus)
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("caret_color", "LineEdit", ACCENT_HOVER)
	t.set_color("selection_color", "LineEdit", Color(ACCENT, 0.5))

	# Tabs
	var tab_selected := _box(CARD, 8, 14)
	tab_selected.corner_radius_bottom_left = 0
	tab_selected.corner_radius_bottom_right = 0
	tab_selected.border_color = ACCENT
	tab_selected.border_width_top = 3
	var tab_idle := tab_selected.duplicate()
	tab_idle.bg_color = BG
	tab_idle.border_width_top = 0
	var tab_hover := tab_idle.duplicate()
	tab_hover.bg_color = CARD.darkened(0.25)
	t.set_stylebox("tab_selected", "TabContainer", tab_selected)
	t.set_stylebox("tab_unselected", "TabContainer", tab_idle)
	t.set_stylebox("tab_hovered", "TabContainer", tab_hover)
	t.set_stylebox("panel", "TabContainer", _box(Color(CARD, 0.35), 10, 12))
	t.set_font("font", "TabContainer", semibold)
	t.set_font_size("font_size", "TabContainer", 16)
	t.set_color("font_selected_color", "TabContainer", TEXT)
	t.set_color("font_unselected_color", "TabContainer", TEXT_DIM)
	t.set_color("font_hovered_color", "TabContainer", TEXT)

	# Bars, sliders, scrolling
	t.set_stylebox("background", "ProgressBar", _box(INSET, 4, 0))
	t.set_stylebox("fill", "ProgressBar", _box(ACCENT, 4, 0))
	var track := _box(INSET, 4, 0)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", _box(ACCENT, 4, 0))
	t.set_stylebox("grabber_area_highlight", "HSlider", _box(ACCENT_HOVER, 4, 0))
	var grip := _box(TEXT_FAINT, 4, 0)
	grip.content_margin_left = 4
	grip.content_margin_right = 4
	t.set_stylebox("grabber", "VScrollBar", grip)
	t.set_stylebox("grabber_highlight", "VScrollBar", _box(TEXT_DIM, 4, 0))
	t.set_stylebox("scroll", "VScrollBar", _box(Color(INSET, 0.4), 4, 0))

	# Popups and tooltips
	t.set_stylebox("panel", "PopupMenu", _box(CARD, 6, 6))
	t.set_stylebox("hover", "PopupMenu", _box(ACCENT, 4, 6))
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_stylebox("panel", "TooltipPanel", _box(INSET, 6, 8))
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_font_size("font_size", "TooltipLabel", 13)
	return t


## A coloured bar style for progress bars (fullness, stocking).
static func bar_fill(colour: Color) -> StyleBoxFlat:
	return _box(colour, 4, 0)


static func _variation(t: Theme, name: String, base: String) -> void:
	t.set_type_variation(name, base)


static func _box(colour: Color, radius: int, padding: int) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = colour
	b.set_corner_radius_all(radius)
	b.content_margin_left = padding
	b.content_margin_right = padding
	b.content_margin_top = padding
	b.content_margin_bottom = padding
	b.anti_aliasing = true
	return b


static func _button(t: Theme, type: String, normal: Color, hover: Color, pressed: Color, text: Color) -> void:
	for state in [["normal", normal], ["hover", hover], ["pressed", pressed], ["disabled", Color(normal, 0.4)]]:
		var b := _box(state[1], 6, 12)
		b.content_margin_top = 7
		b.content_margin_bottom = 7
		t.set_stylebox(state[0], type, b)
	# Toggle buttons (e.g. the selected floor) stay "pressed": make that unmistakable.
	var selected: StyleBoxFlat = t.get_stylebox("pressed", type).duplicate()
	selected.border_color = ACCENT_HOVER
	selected.set_border_width_all(3)
	t.set_stylebox("pressed", type, selected)
	var focus := _box(Color(0, 0, 0, 0), 6, 12)
	focus.border_color = ACCENT_HOVER
	focus.set_border_width_all(2)
	focus.draw_center = false
	t.set_stylebox("focus", type, focus)
	t.set_color("font_color", type, text)
	t.set_color("font_hover_color", type, text)
	t.set_color("font_pressed_color", type, text)
	t.set_color("font_focus_color", type, text)

extends Node
## System tray (Windows) / menu bar (macOS) icon, plus the same menu as a right-click
## context menu on the tank itself.

signal quit_requested

enum Item { VERSION, SHOW_TANK, FEED, MUTE, ON_TOP, SETTINGS, QUIT, DECORATE }

const ICON := preload("res://art/icons/tray.png")

var _menus: Array[PopupMenu] = []
var _indicator: StatusIndicator


func _ready() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_STATUS_INDICATOR):
		var tray_menu := _build_menu()
		_indicator = StatusIndicator.new()
		_indicator.icon = ICON
		_indicator.tooltip = "%s %s" % [TankState.app_name(), TankState.version()]
		add_child(_indicator)
		_indicator.menu = _indicator.get_path_to(tray_menu)
		_indicator.pressed.connect(_on_indicator_pressed)
	else:
		push_warning("No tray/menu bar support on this platform; use right-click on the tank.")
	_build_menu()  # context menu
	TankState.settings_changed.connect(_sync_checks)
	TankState.decorate_mode_changed.connect(_sync_checks)
	_sync_checks()


func show_context_menu(screen_position: Vector2i) -> void:
	var menu := _menus[-1]
	_sync_checks()
	menu.position = screen_position
	menu.popup()


func _build_menu() -> PopupMenu:
	var menu := PopupMenu.new()
	menu.prefer_native_menu = true
	menu.add_item("%s v%s" % [TankState.app_name(), TankState.version()], Item.VERSION)
	menu.set_item_disabled(menu.get_item_index(Item.VERSION), true)
	menu.add_separator()
	menu.add_check_item("Show Tank", Item.SHOW_TANK)
	menu.add_item("Feed Fish", Item.FEED)
	menu.add_check_item("Decorate Mode", Item.DECORATE)
	menu.add_check_item("Mute Bubbles", Item.MUTE)
	menu.add_check_item("Always on Top", Item.ON_TOP)
	menu.add_separator()
	menu.add_item("Settings…", Item.SETTINGS)
	menu.add_separator()
	menu.add_item("Quit %s" % TankState.app_name(), Item.QUIT)
	menu.id_pressed.connect(_on_item)
	add_child(menu)
	_menus.append(menu)
	return menu


func _sync_checks() -> void:
	var s := TankState.settings
	for menu in _menus:
		menu.set_item_checked(menu.get_item_index(Item.SHOW_TANK), s.tank_visible)
		menu.set_item_checked(menu.get_item_index(Item.MUTE), s.muted)
		menu.set_item_checked(menu.get_item_index(Item.ON_TOP), s.always_on_top)
		menu.set_item_checked(menu.get_item_index(Item.DECORATE), TankState.decorating)


func _on_item(id: int) -> void:
	var s := TankState.settings
	match id:
		Item.SHOW_TANK:
			TankState.set_setting("tank_visible", not s.tank_visible)
		Item.FEED:
			TankState.feed_requested.emit()
		Item.DECORATE:
			TankState.set_decorating(not TankState.decorating)
		Item.MUTE:
			TankState.set_setting("muted", not s.muted)
		Item.ON_TOP:
			TankState.set_setting("always_on_top", not s.always_on_top)
		Item.SETTINGS:
			TankState.settings_window_requested.emit()
		Item.QUIT:
			quit_requested.emit()


func _on_indicator_pressed(button: int, _pos: Vector2i) -> void:
	# Left-click brings the tank back if it was hidden (the menu handles everything else).
	if button == MOUSE_BUTTON_LEFT and not TankState.settings.tank_visible:
		TankState.set_setting("tank_visible", true)

class_name LoginItem
## "Open at login". The OS is the source of truth, not the save file, so the checkbox can't
## drift out of sync if the user removes the login item in System Settings.
##
## macOS: a per-user LaunchAgent (~/Library/LaunchAgents/<bundle id>.plist).
## Windows: a value under HKCU\...\CurrentVersion\Run.
## Only available in exported builds; from the editor it would register the Godot binary.

const LABEL := "dev.fishtank.app"  # keep in sync with the macOS bundle id in export_presets.cfg
const WINDOWS_RUN_KEY := "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run"


## Empty if available, otherwise a player-facing reason it isn't.
static func unavailable_reason() -> String:
	if not OS.get_name() in ["macOS", "Windows"]:
		return "Not supported on this platform yet."
	if not OS.has_feature("template"):
		return "Available in the installed app (not when running from Godot)."
	if OS.get_name() == "macOS" and _bundle_path().begins_with("/Volumes/"):
		return "Move Fishtank to your Applications folder first."
	return ""


static func is_enabled() -> bool:
	match OS.get_name():
		"macOS":
			return FileAccess.file_exists(_plist_path())
		"Windows":
			return OS.execute("reg", ["query", WINDOWS_RUN_KEY, "/v", _name()]) == 0
	return false


## Returns an error message, or "" on success.
static func set_enabled(enabled: bool) -> String:
	var reason := unavailable_reason()
	if reason != "":
		return reason
	match OS.get_name():
		"macOS":
			return _set_macos(enabled)
		"Windows":
			return _set_windows(enabled)
	return ""


## Re-registers with the current app location, in case the app was moved since.
static func refresh() -> void:
	if unavailable_reason() == "" and is_enabled():
		set_enabled(true)


static func _name() -> String:
	return ProjectSettings.get_setting("application/config/name", "Fishtank")


# --- macOS ------------------------------------------------------------------

static func _plist_path() -> String:
	return OS.get_environment("HOME").path_join("Library/LaunchAgents/%s.plist" % LABEL)


static func _bundle_path() -> String:
	# .../Fishtank.app/Contents/MacOS/Fishtank -> .../Fishtank.app
	return OS.get_executable_path().get_base_dir().get_base_dir().get_base_dir()


static func _set_macos(enabled: bool) -> String:
	var path := _plist_path()
	if not enabled:
		if FileAccess.file_exists(path) and DirAccess.remove_absolute(path) != OK:
			return "Couldn't remove the login item."
		return ""

	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	# `open -a` launches through LaunchServices, exactly like double-clicking the app.
	var plist := """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>%s</string>
	<key>ProgramArguments</key>
	<array>
		<string>/usr/bin/open</string>
		<string>-a</string>
		<string>%s</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
</dict>
</plist>
""" % [LABEL, _bundle_path().xml_escape()]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return "Couldn't create the login item (%s)." % error_string(FileAccess.get_open_error())
	file.store_string(plist)
	return ""


# --- Windows ----------------------------------------------------------------

static func _set_windows(enabled: bool) -> String:
	var args := ["delete", WINDOWS_RUN_KEY, "/v", _name(), "/f"]
	if enabled:
		args = ["add", WINDOWS_RUN_KEY, "/v", _name(), "/t", "REG_SZ",
			"/d", "\"%s\"" % OS.get_executable_path(), "/f"]
	var code := OS.execute("reg", args)
	if code != 0 and enabled:
		return "Couldn't register with Windows startup (reg exited with %d)." % code
	return ""

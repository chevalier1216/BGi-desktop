extends Node

const SETTINGS_PATH := "user://desktop_preferences.cfg"
const SECTION := "desktop_window"
const TOPMOST_KEY := "always_on_top"
const STANDARD_HEIGHT := 450
const COMPACT_HEIGHT := 188

var _compact_layout := false
var _always_on_top := false

func _ready() -> void:
	# Startup must never cover other Windows; users can opt in through the UI toggle.
	_always_on_top = false
	_apply_window_mode()

func set_always_on_top(enabled: bool) -> void:
	_always_on_top = enabled
	get_window().always_on_top = enabled
	_save_preferences()

func is_always_on_top() -> bool:
	return _always_on_top

func toggle_layout_density() -> void:
	_compact_layout = not _compact_layout
	_apply_window_mode()

func _apply_window_mode() -> void:
	var window := get_window()
	var screen := DisplayServer.window_get_current_screen()
	var usable_rect := DisplayServer.screen_get_usable_rect(screen)
	var desired_height: int = COMPACT_HEIGHT if _compact_layout else STANDARD_HEIGHT
	var height: int = mini(desired_height, usable_rect.size.y)
	window.size = Vector2i(usable_rect.size.x, height)
	window.position = Vector2i(usable_rect.position.x, usable_rect.end.y - height)
	window.always_on_top = _always_on_top

func _load_preferences() -> void:
	var preferences := ConfigFile.new()
	if preferences.load(SETTINGS_PATH) == OK:
		_always_on_top = preferences.get_value(SECTION, TOPMOST_KEY, false)

func _save_preferences() -> void:
	var preferences := ConfigFile.new()
	preferences.set_value(SECTION, TOPMOST_KEY, _always_on_top)
	preferences.save(SETTINGS_PATH)

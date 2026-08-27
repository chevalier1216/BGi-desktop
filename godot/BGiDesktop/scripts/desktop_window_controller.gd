extends Node

const SETTINGS_PATH := "user://desktop_preferences.cfg"
const SECTION := "desktop_window"
const TOPMOST_KEY := "always_on_top"
var _always_on_top := false
var _mouse_passthrough_polygon := PackedVector2Array()

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
	_apply_window_mode()

## Sets the in-app drawn region that should receive pointer input.
## An empty polygon restores normal window hit testing.
func set_mouse_passthrough_polygon(polygon: PackedVector2Array) -> void:
	_mouse_passthrough_polygon = polygon
	if _is_headless_or_unavailable() or _is_embedded_game():
		return
	DisplayServer.window_set_mouse_passthrough(_mouse_passthrough_polygon, get_window().get_window_id())

func clear_mouse_passthrough() -> void:
	set_mouse_passthrough_polygon(PackedVector2Array())

func _apply_window_mode() -> void:
	if _is_headless_or_unavailable() or _is_embedded_game():
		return
	var window := get_window()
	var screen := DisplayServer.window_get_current_screen()
	var usable_rect := DisplayServer.screen_get_usable_rect(screen)
	if usable_rect.size.x <= 0 or usable_rect.size.y <= 0:
		return
	window.borderless = true
	window.transparent = true
	window.size = usable_rect.size
	window.position = usable_rect.position
	window.always_on_top = _always_on_top
	if not _mouse_passthrough_polygon.is_empty():
		DisplayServer.window_set_mouse_passthrough(_mouse_passthrough_polygon, window.get_window_id())

func _load_preferences() -> void:
	var preferences := ConfigFile.new()
	if preferences.load(SETTINGS_PATH) == OK:
		_always_on_top = preferences.get_value(SECTION, TOPMOST_KEY, false)

func _save_preferences() -> void:
	var preferences := ConfigFile.new()
	preferences.set_value(SECTION, TOPMOST_KEY, _always_on_top)
	preferences.save(SETTINGS_PATH)

func _is_embedded_game(arguments: PackedStringArray = OS.get_cmdline_args()) -> bool:
	return arguments.has("--editor-pid")

func _is_headless_or_unavailable() -> bool:
	return DisplayServer.get_name() == "headless" or not is_inside_tree() or get_window() == null

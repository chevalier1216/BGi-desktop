extends SceneTree

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var controller := root.get_node_or_null("DesktopWindowController")
	_expect(controller != null, "DesktopWindowController autoload must be available")
	if controller != null:
		_expect(controller._is_embedded_game(PackedStringArray(["--editor-pid", "52412"])), "Embedded Game must be detected from the editor process marker")
		_expect(not controller._is_embedded_game(PackedStringArray(["--path", "res://"])), "Standalone game arguments must not be treated as Embedded Game")
		var window := root.get_window()
		var original_size := window.size
		var original_content_scale_size := window.content_scale_size
		var original_position := window.position
		var usable_rect := Rect2i(12, 34, 1600, 900)
		controller._apply_native_window_geometry(window, usable_rect)
		_expect(window.size == usable_rect.size, "Desktop host must use the usable work-area size")
		_expect(window.content_scale_size == usable_rect.size, "Desktop host must keep content scale aligned with native pointer coordinates")
		_expect(window.position == usable_rect.position, "Desktop host must use the usable work-area position")
		window.size = original_size
		window.content_scale_size = original_content_scale_size
		window.position = original_position
		controller.set_mouse_passthrough_polygon(PackedVector2Array([
			Vector2(0, 0), Vector2(120, 0), Vector2(120, 40), Vector2(0, 40)
		]))
		_expect(not controller._mouse_passthrough_polygon.is_empty(), "Mouse passthrough state must be retained for in-app lifecycle management")
		controller.clear_mouse_passthrough()
		_expect(controller._mouse_passthrough_polygon.is_empty(), "Mouse passthrough state must clear cleanly")
	print("DesktopWindowEmbeddedLifecycle: PASS" if not _failed else "DesktopWindowEmbeddedLifecycle: FAIL")
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("DesktopWindowEmbeddedLifecycle failed: %s" % message)
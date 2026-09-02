extends SceneTree

const READY_FILE := "native_ready.json"
const WINDOW_EVENT_FILE := "bgi_window_input_received.json"
const BUTTON_GUI_EVENT_FILE := "bgi_button_gui_input_received.json"
const BGI_EVENT_FILE := "bgi_ui_received.txt"
const TIMEOUT_SECONDS := 15.0

var _report_dir := ""
var _button: Button
var _deadline_msec := 0

class NativeInputProbe extends Node:
	var report_dir := ""
	var button: Button

	func _vector_payload(value: Vector2) -> Dictionary:
		return {"x": value.x, "y": value.y}

	func _rect_payload(value: Rect2) -> Dictionary:
		return {
			"x": value.position.x,
			"y": value.position.y,
			"width": value.size.x,
			"height": value.size.y,
		}

	func _transform_payload(value: Transform2D) -> Dictionary:
		return {
			"x": _vector_payload(value.x),
			"y": _vector_payload(value.y),
			"origin": _vector_payload(value.origin),
		}

	func _input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var output := FileAccess.open(report_dir.path_join(WINDOW_EVENT_FILE), FileAccess.WRITE)
			if output != null:
				var viewport := get_viewport()
				output.store_string(JSON.stringify({
					"position": _vector_payload(event.position),
					"button_global_rect": _rect_payload(button.get_global_rect()) if button != null else {},
					"viewport_visible_rect": _rect_payload(viewport.get_visible_rect()),
					"viewport_final_transform": _transform_payload(viewport.get_final_transform()),
					"viewport_canvas_transform": _transform_payload(viewport.get_canvas_transform()),
				}))
				output.close()

func _init() -> void:
	call_deferred("_configure")

func _configure() -> void:
	if OS.get_environment("BGI_NATIVE_ACCEPTANCE_STATIC_CHECK") == "1":
		print("NativeClickthroughAcceptance: STATIC_CHECK PASS")
		quit(0)
		return
	_report_dir = OS.get_environment("BGI_NATIVE_ACCEPTANCE_DIR")
	if _report_dir.is_empty():
		_fail("missing_report_directory")
		return
	var controller := root.get_node_or_null("DesktopWindowController")
	if controller == null:
		_fail("missing_desktop_window_controller")
		return
	var window := root.get_window()
	var screen := DisplayServer.window_get_current_screen(window.get_window_id())
	var usable_rect := DisplayServer.screen_get_usable_rect(screen)
	if usable_rect.size.x <= 0 or usable_rect.size.y <= 0:
		_fail("invalid_usable_screen_rect")
		return
	window.borderless = true
	window.transparent = true
	window.always_on_top = true
	window.position = usable_rect.position
	window.size = usable_rect.size
	_button = Button.new()
	_button.text = "BGi native UI input target"
	_button.position = Vector2(420, 260)
	_button.size = Vector2(300, 100)
	_button.tooltip_text = "Native acceptance only"
	_button.gui_input.connect(_on_button_gui_input)
	_button.pressed.connect(_on_bgi_ui_pressed)
	root.add_child(_button)
	var ui_rect := Rect2(_button.position, _button.size)
	var input_polygon := PackedVector2Array([
		ui_rect.position,
		Vector2(ui_rect.end.x, ui_rect.position.y),
		ui_rect.end,
		Vector2(ui_rect.position.x, ui_rect.end.y),
	])
	controller.set_mouse_passthrough_polygon(input_polygon)
	var probe := NativeInputProbe.new()
	probe.report_dir = _report_dir
	probe.button = _button
	root.add_child(probe)
	await process_frame
	await create_timer(0.5).timeout
	var button_rect := _button.get_global_rect()
	_write_ready({
		"screen": screen,
		"usable_screen_rect": {
			"x": int(usable_rect.position.x),
			"y": int(usable_rect.position.y),
			"width": int(usable_rect.size.x),
			"height": int(usable_rect.size.y),
		},
		"window_position": {"x": int(window.position.x), "y": int(window.position.y)},
		"screen_scale": DisplayServer.screen_get_scale(screen),
		"window_size": _vector_payload(window.size),
		"content_scale_size": _vector_payload(window.content_scale_size),
		"viewport_visible_rect": _rect_payload(root.get_viewport().get_visible_rect()),
		"viewport_final_transform": _transform_payload(root.get_viewport().get_final_transform()),
		"viewport_canvas_transform": _transform_payload(root.get_viewport().get_canvas_transform()),
		"button_rect": {
			"x": int(button_rect.position.x), "y": int(button_rect.position.y),
			"width": int(button_rect.size.x), "height": int(button_rect.size.y),
		},
		"ui_point_in_polygon": Geometry2D.is_point_in_polygon(button_rect.get_center(), input_polygon),
		"ui_click": {
			"x": int(window.position.x + button_rect.get_center().x),
			"y": int(window.position.y + button_rect.get_center().y),
		},
	})
	if OS.get_environment("BGI_NATIVE_ACCEPTANCE_DIAGNOSTIC_ONLY") == "1":
		await create_timer(5.0).timeout
		quit(0)
		return
	_deadline_msec = Time.get_ticks_msec() + int(TIMEOUT_SECONDS * 1000.0)

func _process(_delta: float) -> bool:
	if _deadline_msec > 0 and Time.get_ticks_msec() >= _deadline_msec:
		_fail("ui_input_timeout")
	return false

func _on_bgi_ui_pressed() -> void:
	var output := FileAccess.open(_report_dir.path_join(BGI_EVENT_FILE), FileAccess.WRITE)
	if output == null:
		_fail("bgi_event_write_failed")
		return
	output.store_string("bgi_ui_received")
	output.close()
	quit(0)

func _on_button_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var output := FileAccess.open(_report_dir.path_join(BUTTON_GUI_EVENT_FILE), FileAccess.WRITE)
		if output != null:
			output.store_string("button_gui_input_received")
			output.close()

func _write_ready(payload: Dictionary) -> void:
	var output := FileAccess.open(_report_dir.path_join(READY_FILE), FileAccess.WRITE)
	if output == null:
		_fail("ready_write_failed")
		return
	output.store_string(JSON.stringify(payload))
	output.close()

func _vector_payload(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}

func _rect_payload(value: Rect2) -> Dictionary:
	return {
		"x": value.position.x,
		"y": value.position.y,
		"width": value.size.x,
		"height": value.size.y,
	}

func _transform_payload(value: Transform2D) -> Dictionary:
	return {
		"x": _vector_payload(value.x),
		"y": _vector_payload(value.y),
		"origin": _vector_payload(value.origin),
	}

func _fail(reason: String) -> void:
	if not _report_dir.is_empty():
		var output := FileAccess.open(_report_dir.path_join("failure.txt"), FileAccess.WRITE)
		if output != null:
			output.store_string(reason)
			output.close()
	push_error("NativeClickthroughAcceptance: %s" % reason)
	quit(1)

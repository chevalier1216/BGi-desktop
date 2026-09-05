extends Control

const ProgressionScript = preload("res://scripts/skeleton_c_playtest_progression.gd")
const TRANSPARENCY_RECEIPT_PATH := "user://playtest_r01_progression_c/transparency_runtime.json"
var _progression: RefCounted
var _availability: VBoxContainer
var _status: Label
var _panel_box: VBoxContainer

func _ready() -> void:
	get_viewport().transparent_bg = true
	RenderingServer.set_default_clear_color(Color(0.0, 0.0, 0.0, 0.0))
	_progression = ProgressionScript.new()
	var load_result: Dictionary = _progression.load()
	if not bool(load_result["is_loaded"]):
		push_error("Skeleton C playtest profile could not load: %s" % str(load_result["error_code"]))
	_build_ui()
	_render()
	call_deferred("_record_transparency_runtime")
	call_deferred("_apply_playtest_hit_region")

func _build_ui() -> void:
	var box := VBoxContainer.new()
	_panel_box = box
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE, 520)
	box.position = Vector2(80, 60)
	box.size = Vector2(560, 360)
	add_child(box)
	var title := Label.new()
	title.text = "Skeleton C｜NON-AUTHORITATIVE PLAYTEST"
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)
	var profile := Label.new()
	profile.text = "Profile: %s｜FAST: %d 秒｜Save: %s" % [ProgressionScript.PROFILE_ID, ProgressionScript.FAST_DURATION_SECONDS, ProgressionScript.STATE_PATH]
	profile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(profile)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status)
	var tutorial := Button.new()
	tutorial.text = "收取 Tutorial 完成結果"
	tutorial.pressed.connect(func() -> void: _progression.claim_tutorial_completion(); _render())
	box.add_child(tutorial)
	_availability = VBoxContainer.new()
	box.add_child(_availability)
	var reset := Button.new()
	reset.text = "重設此 playtest profile"
	reset.pressed.connect(func() -> void: _progression.reset_playtest(); _render())
	box.add_child(reset)

func _apply_playtest_hit_region() -> void:
	var controller := get_node_or_null("/root/DesktopWindowController")
	if controller == null or not controller.has_method("set_mouse_passthrough_polygon"):
		return
	var rect := _panel_box.get_global_rect()
	controller.set_mouse_passthrough_polygon(PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	]))

func _record_transparency_runtime() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var receipt := {
		"per_pixel_transparency_allowed": bool(ProjectSettings.get_setting("display/window/per_pixel_transparency/allowed", false)),
		"root_viewport_transparent_bg": get_viewport().transparent_bg,
		"window_transparent": get_window().transparent,
	}
	receipt["all_required_values_true"] = bool(receipt["per_pixel_transparency_allowed"]) and bool(receipt["root_viewport_transparent_bg"]) and bool(receipt["window_transparent"])
	DirAccess.make_dir_recursive_absolute(TRANSPARENCY_RECEIPT_PATH.get_base_dir())
	var output := FileAccess.open(TRANSPARENCY_RECEIPT_PATH, FileAccess.WRITE)
	if output == null:
		push_error("Skeleton C transparency receipt could not be written")
		return
	output.store_string(JSON.stringify(receipt))
	output.close()
	if not bool(receipt["all_required_values_true"]):
		push_error("Skeleton C transparency runtime prerequisites are not all true")

func _render() -> void:
	for child in _availability.get_children():
		child.queue_free()
	var available: Array[String] = _progression.get_available_mission_ids()
	_status.text = "可收取任務：%s" % ("無（需先收取 Tutorial）" if available.is_empty() else ", ".join(available))
	var territory_projection: Dictionary = _progression.get_territory_first_touch_projection()
	if bool(territory_projection["is_touched"]):
		_status.text += "\nterritory_03：已觸及｜character.worker02 Unit：已解鎖 ×%d" % int(territory_projection["worker02_unlocked_count"])
	else:
		_status.text += "\nterritory_03：未涉足"
	for mission_id: String in available:
		var claim := Button.new()
		claim.text = "FAST 完成並收取 %s" % mission_id
		claim.pressed.connect(func() -> void: _progression.claim_mission(mission_id); _render())
		_availability.add_child(claim)

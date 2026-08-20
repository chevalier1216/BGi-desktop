extends Control

const StarterMissionFlowPanelScene = preload("res://scenes/starter_mission_flow_panel_v2.tscn")

@onready var crew_indicators: HBoxContainer = %CrewIndicators
@onready var task_window_button: Button = %TaskWindowButton
@onready var territory_entry_button: Button = get_node("BottomPersistentBar/Entries/TerritoryEntry/Button") as Button
@onready var market_entry_button: Button = get_node("BottomPersistentBar/Entries/MarketEntry/Button") as Button
@onready var crew_entry_button: Button = get_node("BottomPersistentBar/Entries/CrewEntry/Button") as Button
@onready var collection_entry_button: Button = get_node("BottomPersistentBar/Entries/CollectionEntry/Button") as Button
@onready var settings_entry_button: Button = get_node("BottomPersistentBar/Entries/SettingsEntry/Button") as Button

const STATUS_COLORS := {
	0: Color("55c993"),
	1: Color("6fa8ff"),
	2: Color("f4c95d"),
}

const STATUS_LABELS := {
	0: "可用",
	1: "派遣中",
	2: "已完成待收取",
}

const POPUP_MARGIN := 24
const POPUP_CASCADE_STEP := Vector2i(36, 30)

var _game_state: Node
var _popup_windows: Dictionary = {}
var _mission_panel: StarterMissionFlowPanel

func _ready() -> void:
	# These are desktop tool windows, not controls inside the 450px bottom-stage viewport.
	# Native windows provide the operating-system title bar, drag surface and close control.
	get_tree().root.gui_embed_subwindows = false
	_game_state = get_node_or_null("/root/GameState")
	if _game_state != null:
		_render_crew_status()
	task_window_button.pressed.connect(_show_tasks)
	territory_entry_button.pressed.connect(_show_territory)
	market_entry_button.pressed.connect(_show_market)
	crew_entry_button.pressed.connect(_show_crew)
	collection_entry_button.pressed.connect(_show_collection)
	settings_entry_button.pressed.connect(_show_settings)

func _show_tasks() -> void:
	var window := _open_popup("tasks", "任務與收取", Vector2i(760, 820))
	if _mission_panel == null:
		_mission_panel = StarterMissionFlowPanelScene.instantiate() as StarterMissionFlowPanel
		window.add_child(_mission_panel)

func _show_territory() -> void:
	var window := _open_popup("territory", "地盤／佈置", Vector2i(520, 560))
	_replace_popup_content(window, _territory_content())

func _show_market() -> void:
	_show_text_popup("market", "黑市", "尚未開放", "")

func _show_crew() -> void:
	var available := 0
	var dispatched := 0
	var pending_claim := 0
	if _game_state != null:
		for crew_member: Dictionary in _game_state.get_crew():
			match int(crew_member.get("status", -1)):
				0: available += 1
				1: dispatched += 1
				2: pending_claim += 1
	_show_text_popup("crew", "角色", "目前人物狀態", "可用：%d\n派遣中：%d\n已完成待收取：%d\n人物的派遣選擇與確認在任務／收取視窗進行。" % [available, dispatched, pending_claim])

func _show_collection() -> void:
	_show_text_popup("collection", "收藏", "尚未取得收藏", "")

func _show_settings() -> void:
	var window := _open_popup("settings", "設定", Vector2i(420, 300))
	var content := _make_content("設定", "桌面偏好")
	var window_controller := get_node_or_null("/root/DesktopWindowController")
	var topmost := CheckButton.new()
	topmost.text = "置頂顯示"
	topmost.button_pressed = bool(window_controller != null and window_controller.is_always_on_top())
	topmost.toggled.connect(func(enabled: bool) -> void:
		if window_controller != null:
			window_controller.set_always_on_top(enabled)
	)
	content.add_child(topmost)
	_replace_popup_content(window, content)

func _territory_content() -> VBoxContainer:
	var content := _make_content("地盤／佈置", "目前地盤")
	var status := _get_territory_status()
	for condition: Dictionary in Array(status["conditions"]):
		var label := Label.new()
		var is_met := bool(condition["is_met"])
		label.text = ("已達成：" if is_met else "未達成：") + str(condition["label"])
		label.add_theme_color_override("font_color", Color("BBFF66") if is_met else Color("FF3333"))
		content.add_child(label)
	if bool(status["can_explore"]):
		var explore := Button.new()
		explore.text = "探索新地盤"
		explore.pressed.connect(func() -> void:
			_show_text_popup("territory_result", "探索新地盤", "目前沒有可探索的新地盤", "")
		)
		content.add_child(explore)
	return content

func _get_territory_status() -> Dictionary:
	if _mission_panel != null:
		return _mission_panel.get_territory_exploration_status()
	return {
		"conditions": [{"label": "完成並保存首次任務收取成果", "is_met": false}],
		"can_explore": false,
	}

func _show_text_popup(key: String, title: String, summary: String, detail: String) -> void:
	var window := _open_popup(key, title, Vector2i(460, 340))
	var content := _make_content(title, summary)
	var label := Label.new()
	label.text = detail
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not detail.is_empty():
		content.add_child(label)
	_replace_popup_content(window, content)

func _open_popup(key: String, title: String, size: Vector2i) -> Window:
	if _popup_windows.has(key) and is_instance_valid(_popup_windows[key]):
		var existing := _popup_windows[key] as Window
		existing.show()
		return existing
	var window := Window.new()
	window.hide()
	window.title = title
	window.size = size
	window.min_size = Vector2i(320, 220)
	window.force_native = true
	window.transient = false
	window.borderless = false
	window.unresizable = false
	window.exclusive = false
	window.position = _initial_popup_position(size)
	window.close_requested.connect(window.hide)
	add_child(window)
	_popup_windows[key] = window
	window.show()
	return window

func _initial_popup_position(size: Vector2i) -> Vector2i:
	var parent_window := get_window()
	var usable_rect := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var cascade_index := _popup_windows.size()
	var preferred := parent_window.position + Vector2i(POPUP_MARGIN, -size.y + POPUP_MARGIN) + POPUP_CASCADE_STEP * cascade_index
	return Vector2i(
		clampi(preferred.x, usable_rect.position.x + POPUP_MARGIN, usable_rect.end.x - size.x - POPUP_MARGIN),
		clampi(preferred.y, usable_rect.position.y + POPUP_MARGIN, usable_rect.end.y - size.y - POPUP_MARGIN)
	)

func _replace_popup_content(window: Window, content: Control) -> void:
	for child in window.get_children():
		if child != _mission_panel:
			child.queue_free()
	if content.get_parent() == null:
		window.add_child(content)

func _make_content(title: String, summary: String) -> VBoxContainer:
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 20
	content.offset_top = 18
	content.offset_right = -20
	content.offset_bottom = -18
	content.add_theme_constant_override("separation", 12)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 20)
	content.add_child(heading)
	var subtitle := Label.new()
	subtitle.text = summary
	content.add_child(subtitle)
	return content

func _render_crew_status() -> void:
	for crew_member: Dictionary in _game_state.get_crew():
		var indicator := Panel.new()
		indicator.custom_minimum_size = Vector2(24, 24)
		indicator.tooltip_text = STATUS_LABELS[crew_member.status]
		var style := StyleBoxFlat.new()
		style.bg_color = STATUS_COLORS[crew_member.status]
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_right = 12
		style.corner_radius_bottom_left = 12
		indicator.add_theme_stylebox_override("panel", style)
		crew_indicators.add_child(indicator)

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
var _is_shutting_down: bool = false

func _ready() -> void:
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
	if _is_shutting_down:
		return
	_ensure_mission_panel()
	var window := _open_popup("tasks", "任務清單", Vector2i(520, 620))
	if not is_instance_valid(window) or window.is_queued_for_deletion():
		return
	_render_task_directory(window)

func _ensure_mission_panel() -> void:
	if _mission_panel != null and is_instance_valid(_mission_panel) and not _mission_panel.is_queued_for_deletion():
		return
	_mission_panel = null
	var detail_window := _open_popup("task_detail", "任務詳情", Vector2i(760, 820))
	if not is_instance_valid(detail_window) or detail_window.is_queued_for_deletion():
		return
	detail_window.hide()
	_mission_panel = StarterMissionFlowPanelScene.instantiate() as StarterMissionFlowPanel
	if _mission_panel == null:
		return
	detail_window.get_node("PopupLayout/Content").add_child(_mission_panel)
	_mission_panel.directory_changed.connect(_on_mission_directory_changed)

func _render_task_directory(window: Control) -> void:
	if not is_instance_valid(window) or window.is_queued_for_deletion():
		return
	if _mission_panel == null or not is_instance_valid(_mission_panel) or _mission_panel.is_queued_for_deletion():
		return
	var content := VBoxContainer.new()
	content.name = "Content"
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 20
	content.offset_top = 18
	content.offset_right = -20
	content.offset_bottom = -18
	content.add_theme_constant_override("separation", 12)
	var heading := Label.new()
	heading.text = "任務清單"
	heading.add_theme_font_size_override("font_size", 20)
	content.add_child(heading)
	var current_missions := VBoxContainer.new()
	current_missions.name = "CurrentMissions"
	content.add_child(current_missions)
	var current_title := Label.new()
	current_title.text = "目前可執行"
	current_missions.add_child(current_title)
	var entries: Dictionary = _mission_panel.get_task_directory_entries()
	for entry: Dictionary in Array(entries["current"]):
		var button := Button.new()
		button.text = "%s（%d 秒）" % [str(entry["title"]), int(entry["duration_seconds"])]
		button.pressed.connect(_show_task_detail.bind(str(entry["task_id"])))
		current_missions.add_child(button)
	if current_missions.get_child_count() == 1:
		var empty := Label.new()
		empty.text = "目前沒有可執行任務"
		current_missions.add_child(empty)
	var completed_missions := VBoxContainer.new()
	completed_missions.name = "CompletedMissions"
	content.add_child(completed_missions)
	var completed_title := Label.new()
	completed_title.text = "已完成任務"
	completed_missions.add_child(completed_title)
	for entry: Dictionary in Array(entries["completed"]):
		var button := Button.new()
		button.text = "%s（%s）" % [str(entry["title"]), "結果已領取" if bool(entry["is_claimed"]) else "可領取結果"]
		button.pressed.connect(_show_task_detail.bind(str(entry["task_id"])))
		completed_missions.add_child(button)
	if completed_missions.get_child_count() == 1:
		var empty := Label.new()
		empty.text = "尚無已完成任務"
		completed_missions.add_child(empty)
	var refresh_info := VBoxContainer.new()
	refresh_info.name = "RefreshInfo"
	content.add_child(refresh_info)
	var refresh_title := Label.new()
	refresh_title.text = "任務刷新"
	refresh_info.add_child(refresh_title)
	var refresh_state: Dictionary = _mission_panel.get_refresh_directory_state()
	for text_value: String in [str(refresh_state["allowance"]), str(refresh_state["next_available"]), str(refresh_state["replaceable"])]:
		var label := Label.new()
		label.text = text_value
		refresh_info.add_child(label)
	var refresh_button := Button.new()
	refresh_button.text = "刷新未接受任務"
	refresh_button.disabled = not bool(refresh_state["can_refresh"])
	refresh_info.add_child(refresh_button)
	_replace_popup_content(window, content)

func _show_task_detail(task_id: String) -> void:
	_ensure_mission_panel()
	if _mission_panel == null or not is_instance_valid(_mission_panel) or _mission_panel.is_queued_for_deletion():
		return
	if not _mission_panel.show_task_detail(task_id):
		return
	var detail_window := _get_popup("task_detail")
	if detail_window == null:
		return
	detail_window.set_meta("title", _mission_panel.task_label.text)
	detail_window.show()

func _on_mission_directory_changed() -> void:
	var tasks_window := _get_popup("tasks")
	if tasks_window != null:
		_render_task_directory(tasks_window)

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
	if not detail.is_empty():
		var label := Label.new()
		label.text = detail
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(label)
	_replace_popup_content(window, content)

func _open_popup(key: String, title: String, size: Vector2i) -> PanelContainer:
	var existing := _get_popup(key)
	if existing != null:
		existing.show()
		return existing as PanelContainer
	var popup := PanelContainer.new()
	popup.name = "Popup_" + key
	popup.custom_minimum_size = Vector2(size)
	popup.set_meta("title", title)
	popup.set_meta("popup_key", key)
	popup.set_anchors_preset(Control.PRESET_CENTER)
	popup.position -= Vector2(size) / 2.0
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	var layout := VBoxContainer.new()
	layout.name = "PopupLayout"
	layout.add_theme_constant_override("separation", 8)
	popup.add_child(layout)
	var header := HBoxContainer.new()
	header.name = "Header"
	layout.add_child(header)
	var heading := Label.new()
	heading.name = "Title"
	heading.text = title
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_font_size_override("font_size", 20)
	header.add_child(heading)
	var close_button := Button.new()
	close_button.name = "CloseButton"
	close_button.text = "關閉"
	close_button.pressed.connect(_on_popup_close_requested.bind(key))
	header.add_child(close_button)
	var body := VBoxContainer.new()
	body.name = "Content"
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.clip_contents = true
	layout.add_child(body)
	add_child(popup)
	_popup_windows[key] = popup
	popup.show()
	return popup
func _get_popup(key: String) -> Control:
	if not _popup_windows.has(key):
		return null
	var popup := _popup_windows[key] as Control
	if popup == null or not is_instance_valid(popup) or popup.is_queued_for_deletion():
		_popup_windows.erase(key)
		return null
	return popup

func _on_popup_close_requested(key: String) -> void:
	var popup := _get_popup(key)
	if popup != null and not _is_shutting_down:
		popup.hide()

func _replace_popup_content(window: Control, content: Control) -> void:
	if not is_instance_valid(window) or window.is_queued_for_deletion() or _is_shutting_down:
		return
	var body := window.get_node_or_null("PopupLayout/Content") as Control
	if body == null:
		return
	for child in body.get_children():
		if child != _mission_panel and is_instance_valid(child) and not child.is_queued_for_deletion():
			child.queue_free()
	if content.get_parent() == null:
		body.add_child(content)

func _exit_tree() -> void:
	_is_shutting_down = true
	for key in _popup_windows.keys():
		var popup := _popup_windows[key] as Control
		if popup != null and is_instance_valid(popup):
			popup.hide()
	_popup_windows.clear()
	_mission_panel = null

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

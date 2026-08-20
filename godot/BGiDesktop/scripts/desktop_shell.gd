extends Control

@onready var topmost_toggle: CheckButton = %TopmostToggle
@onready var layout_button: Button = %LayoutButton
@onready var crew_indicators: HBoxContainer = %CrewIndicators
@onready var mission_list: ItemList = %MissionList
@onready var territory_button: Button = %TerritoryButton
@onready var territory_entry_button: Button = get_node("BottomPersistentBar/Entries/TerritoryEntry/Button") as Button
@onready var market_entry_button: Button = get_node("BottomPersistentBar/Entries/MarketEntry/Button") as Button
@onready var crew_entry_button: Button = get_node("BottomPersistentBar/Entries/CrewEntry/Button") as Button
@onready var collection_entry_button: Button = get_node("BottomPersistentBar/Entries/CollectionEntry/Button") as Button
@onready var settings_entry_button: Button = get_node("BottomPersistentBar/Entries/SettingsEntry/Button") as Button
@onready var secondary_title: Label = %Title
@onready var secondary_summary: Label = %Summary
@onready var secondary_detail: Label = %SecondaryDetail
@onready var settings_actions: HBoxContainer = %SettingsActions
@onready var settings_layout_button: Button = %SettingsLayoutButton
@onready var settings_topmost_toggle: CheckButton = %SettingsTopmostToggle

var _window_controller: Node
var _game_state: Node
var _starter_mission_catalog: Node

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

func _ready() -> void:
	_window_controller = get_node_or_null("/root/DesktopWindowController")
	_game_state = get_node_or_null("/root/GameState")
	_starter_mission_catalog = get_node_or_null("/root/StarterMissionCatalog")
	if _window_controller != null:
		topmost_toggle.button_pressed = bool(_window_controller.is_always_on_top())
		settings_topmost_toggle.button_pressed = topmost_toggle.button_pressed
		topmost_toggle.toggled.connect(_set_always_on_top)
		settings_topmost_toggle.toggled.connect(_set_always_on_top)
		layout_button.pressed.connect(_toggle_layout_density)
		settings_layout_button.pressed.connect(_toggle_layout_density)
	else:
		topmost_toggle.disabled = true
		layout_button.disabled = true
		settings_topmost_toggle.disabled = true
		settings_layout_button.disabled = true
	if _game_state != null:
		_render_crew_status()
	if _starter_mission_catalog != null:
		_render_starter_missions()
	_connect_secondary_navigation()

func _connect_secondary_navigation() -> void:
	territory_button.pressed.connect(_show_territory)
	territory_entry_button.pressed.connect(_show_territory)
	market_entry_button.pressed.connect(_show_market)
	crew_entry_button.pressed.connect(_show_crew)
	collection_entry_button.pressed.connect(_show_collection)
	settings_entry_button.pressed.connect(_show_settings)

func _set_always_on_top(enabled: bool) -> void:
	if _window_controller == null:
		return
	_window_controller.set_always_on_top(enabled)
	topmost_toggle.set_pressed_no_signal(enabled)
	settings_topmost_toggle.set_pressed_no_signal(enabled)

func _toggle_layout_density() -> void:
	if _window_controller != null:
		_window_controller.toggle_layout_density()

func _show_territory() -> void:
	_show_secondary_panel("地盤", "目前地盤：territory_02", "地盤進度：[PLACEHOLDER]\n探索收藏：[PLACEHOLDER]\n環境布置：[PLACEHOLDER]\n首次觸及條件：完成並保存任務收取成果。")

func _show_market() -> void:
	_show_secondary_panel("黑市", "尚未解鎖", "黑市內容、價格、貨幣與解鎖條件均為 [PLACEHOLDER]。\n目前沒有可執行的交易按鈕。")

func _show_crew() -> void:
	var available: int = 0
	var dispatched: int = 0
	var pending_claim: int = 0
	if _game_state != null:
		for crew_member: Dictionary in _game_state.get_crew():
			match int(crew_member.get("status", -1)):
				0:
					available += 1
				1:
					dispatched += 1
				2:
					pending_claim += 1
	_show_secondary_panel("角色", "目前人物狀態", "可用：%d\n派遣中：%d\n已完成待收取：%d\n派遣選擇與確認只在任務區進行。" % [available, dispatched, pending_claim])

func _show_collection() -> void:
	_show_secondary_panel("收藏", "尚未取得收藏", "背景與掛件所有權維持獨立；未擁有項目顯示鎖定。\n取得條件：[PLACEHOLDER]。")

func _show_settings() -> void:
	_show_secondary_panel("設定", "桌面偏好", "可在此調整視窗密度與置頂顯示。\n帳號、雲端同步與 Steam Cloud：後續整合。")

func _show_secondary_panel(title: String, summary: String, detail: String) -> void:
	secondary_title.text = title
	secondary_summary.text = summary
	secondary_detail.text = detail
	settings_actions.visible = title == "設定"

func _render_crew_status() -> void:
	for crew_member in _game_state.get_crew():
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

func _render_starter_missions() -> void:
	for mission: Dictionary in _starter_mission_catalog.get_missions():
		var duration_seconds: int = int(mission["duration_seconds"])
		var accepted_status: String = "已接受" if bool(mission["is_accepted"]) else "未接受"
		mission_list.add_item("%s · %s · %s" % [
			mission["id"],
			_format_duration(duration_seconds),
			accepted_status,
		])

func _format_duration(duration_seconds: int) -> String:
	if duration_seconds < 60:
		return "%d 秒" % duration_seconds
	return "%d 分鐘" % int(duration_seconds / 60.0)

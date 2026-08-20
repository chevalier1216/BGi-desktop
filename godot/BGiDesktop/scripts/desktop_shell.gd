extends Control

@onready var topmost_toggle: CheckButton = %TopmostToggle
@onready var layout_button: Button = %LayoutButton
@onready var crew_indicators: HBoxContainer = %CrewIndicators
@onready var mission_list: ItemList = %MissionList

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
		topmost_toggle.toggled.connect(_window_controller.set_always_on_top)
		layout_button.pressed.connect(_window_controller.toggle_layout_density)
	else:
		topmost_toggle.disabled = true
		layout_button.disabled = true
	if _game_state != null:
		_render_crew_status()
	if _starter_mission_catalog != null:
		_render_starter_missions()

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

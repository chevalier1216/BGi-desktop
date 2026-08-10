extends Control

@onready var topmost_toggle: CheckButton = %TopmostToggle
@onready var layout_button: Button = %LayoutButton
@onready var crew_indicators: HBoxContainer = %CrewIndicators
@onready var mission_list: ItemList = %MissionList

const STATUS_COLORS := {
	GameState.CrewStatus.AVAILABLE: Color("55c993"),
	GameState.CrewStatus.DISPATCHED: Color("6fa8ff"),
	GameState.CrewStatus.COMPLETED: Color("f4c95d"),
}

const STATUS_LABELS := {
	GameState.CrewStatus.AVAILABLE: "可用",
	GameState.CrewStatus.DISPATCHED: "派遣中",
	GameState.CrewStatus.COMPLETED: "已完成待收取",
}

func _ready() -> void:
	topmost_toggle.button_pressed = DesktopWindowController.is_always_on_top()
	topmost_toggle.toggled.connect(DesktopWindowController.set_always_on_top)
	layout_button.pressed.connect(DesktopWindowController.toggle_layout_density)
	_render_crew_status()
	_render_starter_missions()

func _render_crew_status() -> void:
	for crew_member in GameState.get_crew():
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
	for mission: Dictionary in StarterMissionCatalog.get_missions():
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

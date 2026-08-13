class_name StarterMissionFlowPanel
extends PanelContainer

const GameStateScript = preload("res://scripts/game_state.gd")
const MissionAssignmentStateScript = preload("res://scripts/mission_assignment_state.gd")
const AssignmentCoordinatorScript = preload("res://scripts/persistent_mission_assignment_coordinator.gd")
const ValidityQueryScript = preload("res://scripts/mission_execution_validity_query.gd")
const ExpiredReleaseServiceScript = preload("res://scripts/mission_expired_release_service.gd")
const SnapshotCollectionScript = preload("res://scripts/mission_execution_snapshot_collection.gd")
const MissionLifecycleCoordinatorScript = preload("res://scripts/mission_lifecycle_coordinator.gd")

@onready var task_label: Label = %TaskLabel
@onready var requirement_label: Label = %RequirementLabel
@onready var crew_selector: HBoxContainer = %CrewSelector
@onready var status_label: Label = %StatusLabel
@onready var start_button: Button = %StartButton

var _task_id: String = ""
var _duration_seconds: int = 0
var _selected_crew_ids: Array[String] = []
var _game_state: Node
var _starter_mission_catalog: Node
var _lifecycle: RefCounted
var _snapshot_collection: RefCounted
var _is_waiting: bool = false
var _is_completed: bool = false

func _ready() -> void:
	_game_state = get_node("/root/GameState") as Node
	_starter_mission_catalog = get_node("/root/StarterMissionCatalog") as Node
	var assignment_state: RefCounted = MissionAssignmentStateScript.new()
	var assignment_coordinator: RefCounted = AssignmentCoordinatorScript.new(_game_state, assignment_state)
	var validity_query: RefCounted = ValidityQueryScript.new()
	var expired_release_service: RefCounted = ExpiredReleaseServiceScript.new(assignment_coordinator, assignment_state, validity_query)
	_snapshot_collection = SnapshotCollectionScript.new()
	_lifecycle = MissionLifecycleCoordinatorScript.new(assignment_coordinator, expired_release_service, _snapshot_collection)
	_load_first_starter_mission()
	_render_crew_choices()
	start_button.pressed.connect(_on_start_pressed)
	_refresh_selection_state()

func _load_first_starter_mission() -> void:
	var missions: Array[Dictionary] = _starter_mission_catalog.get_missions()
	if missions.is_empty():
		task_label.text = "新手任務：無可用任務"
		status_label.text = "任務資料不可用"
		start_button.disabled = true
		return
	var mission: Dictionary = missions[0]
	_task_id = str(mission["id"])
	_duration_seconds = int(mission["duration_seconds"])
	task_label.text = "新手任務：%s（%d 秒）" % [_task_id, _duration_seconds]
	requirement_label.text = "需要 %d–%d 名小弟" % [DispatchRules.MIN_ASSIGNEES, DispatchRules.MAX_ASSIGNEES]

func _render_crew_choices() -> void:
	for crew_member: Dictionary in _game_state.get_crew():
		var crew_id: String = str(crew_member["id"])
		var choice: CheckButton = CheckButton.new()
		choice.text = "小弟 %s" % crew_id.trim_prefix("crew_")
		choice.tooltip_text = "可用" if int(crew_member["status"]) == GameStateScript.CrewStatus.AVAILABLE else "派遣中"
		choice.disabled = int(crew_member["status"]) != GameStateScript.CrewStatus.AVAILABLE
		choice.toggled.connect(_on_crew_toggled.bind(crew_id))
		crew_selector.add_child(choice)

func _on_crew_toggled(pressed: bool, crew_id: String) -> void:
	if _is_waiting:
		return
	if pressed:
		if not _selected_crew_ids.has(crew_id):
			_selected_crew_ids.append(crew_id)
	else:
		_selected_crew_ids.erase(crew_id)
	_refresh_selection_state()

func _refresh_selection_state() -> void:
	var selected_count: int = _selected_crew_ids.size()
	start_button.disabled = _is_waiting or selected_count < DispatchRules.MIN_ASSIGNEES or selected_count > DispatchRules.MAX_ASSIGNEES
	if not _is_waiting:
		status_label.text = "已選 %d/%d 名小弟" % [selected_count, DispatchRules.MAX_ASSIGNEES]

func _on_start_pressed() -> void:
	var result: Dictionary = _lifecycle.accept_execution(_task_id, _selected_crew_ids, int(Time.get_unix_time_from_system()), _duration_seconds)
	if not bool(result["is_accepted"]):
		status_label.text = "無法開始：%s" % result["error_code"]
		return
	_is_waiting = true
	for choice: CheckButton in crew_selector.get_children():
		choice.disabled = true
	start_button.disabled = true
	status_label.text = "等待中：已派遣 %d 名小弟" % _selected_crew_ids.size()

func _process(_delta: float) -> void:
	refresh_execution_status(int(Time.get_unix_time_from_system()))

## Updates the visual execution state from an injected timestamp for deterministic UI tests.
func refresh_execution_status(current_time_seconds: int) -> void:
	if not _is_waiting:
		return
	var clock: Variant = _snapshot_collection.restore_clock(_task_id)
	if clock == null:
		status_label.text = "等待狀態無法讀取"
		return
	var remaining_seconds: int = clock.get_remaining_seconds(current_time_seconds)
	if remaining_seconds > 0:
		status_label.text = "等待中：剩餘 %d 秒" % remaining_seconds
		return
	var resolution: Dictionary = _lifecycle.resolve_completed_result(_task_id, current_time_seconds)
	if not bool(resolution["is_resolved"]):
		status_label.text = "完成狀態無法讀取"
		return
	_is_waiting = false
	_is_completed = true
	status_label.text = "已完成／保底報酬待定"

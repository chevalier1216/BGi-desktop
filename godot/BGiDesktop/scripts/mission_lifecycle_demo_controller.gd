extends Node

const GameStateScript = preload("res://scripts/game_state.gd")
const MissionAssignmentStateScript = preload("res://scripts/mission_assignment_state.gd")
const AssignmentCoordinatorScript = preload("res://scripts/persistent_mission_assignment_coordinator.gd")
const ValidityQueryScript = preload("res://scripts/mission_execution_validity_query.gd")
const ExpiredReleaseServiceScript = preload("res://scripts/mission_expired_release_service.gd")
const SnapshotCollectionScript = preload("res://scripts/mission_execution_snapshot_collection.gd")
const MissionLifecycleCoordinatorScript = preload("res://scripts/mission_lifecycle_coordinator.gd")

const TEST_TASK_ID: String = "starter_01"
const TEST_STARTED_AT_SECONDS: int = 0
const TEST_DURATION_SECONDS: int = 0

@export var panel_path: NodePath
@onready var panel: MissionLifecyclePanel = get_node(panel_path) as MissionLifecyclePanel

var _game_state: Node
var _lifecycle: RefCounted
var _crew_ids: Array[String] = ["crew_01"]

func _ready() -> void:
	_game_state = GameStateScript.new()
	add_child(_game_state)
	var assignment_state: RefCounted = MissionAssignmentStateScript.new()
	var assignment_coordinator: RefCounted = AssignmentCoordinatorScript.new(_game_state, assignment_state)
	var validity_query: RefCounted = ValidityQueryScript.new()
	var expired_release_service: RefCounted = ExpiredReleaseServiceScript.new(assignment_coordinator, assignment_state, validity_query)
	var snapshot_collection: RefCounted = SnapshotCollectionScript.new()
	_lifecycle = MissionLifecycleCoordinatorScript.new(assignment_coordinator, expired_release_service, snapshot_collection)
	panel.accept_requested.connect(_on_accept_requested)
	panel.completion_check_requested.connect(_on_completion_check_requested)
	panel.claim_requested.connect(_on_claim_requested)
	panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_AVAILABLE, "固定本地測試資料")

func _on_accept_requested() -> void:
	var result: Dictionary = _lifecycle.accept_execution(TEST_TASK_ID, _crew_ids, TEST_STARTED_AT_SECONDS, TEST_DURATION_SECONDS)
	if bool(result["is_accepted"]):
		panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_DISPATCHED, "已派遣 1 名小弟；可執行完成檢查")
		return
	panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_AVAILABLE, "接受失敗：%s" % result["error_code"])

func _on_completion_check_requested() -> void:
	var result: Dictionary = _lifecycle.resolve_completed_result(TEST_TASK_ID, TEST_STARTED_AT_SECONDS)
	if bool(result["is_resolved"]):
		panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_COMPLETED, "結果已鎖定，報酬：[PLACEHOLDER]")
		return
	panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_DISPATCHED, "尚未完成：%s" % result["error_code"])

func _on_claim_requested() -> void:
	var result: Dictionary = _lifecycle.claim_completed_result(TEST_TASK_ID, TEST_STARTED_AT_SECONDS)
	if bool(result["is_claimed"]):
		panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_CLAIMED, "已收取固定結果；小弟已釋放")
		return
	panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_COMPLETED, "收取失敗：%s" % result["error_code"])

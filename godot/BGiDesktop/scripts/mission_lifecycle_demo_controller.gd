extends Node

const GameStateScript = preload("res://scripts/game_state.gd")
const MissionAssignmentStateScript = preload("res://scripts/mission_assignment_state.gd")
const AssignmentCoordinatorScript = preload("res://scripts/persistent_mission_assignment_coordinator.gd")
const ValidityQueryScript = preload("res://scripts/mission_execution_validity_query.gd")
const ExpiredReleaseServiceScript = preload("res://scripts/mission_expired_release_service.gd")
const SnapshotCollectionScript = preload("res://scripts/mission_execution_snapshot_collection.gd")
const ExecutionStateStoreScript = preload("res://scripts/mission_execution_state_store.gd")
const ResultStateSnapshotScript = preload("res://scripts/mission_result_state_snapshot.gd")
const MissionLifecycleCoordinatorScript = preload("res://scripts/mission_lifecycle_coordinator.gd")

const TEST_TASK_ID: String = "starter_01"
const DEFAULT_SNAPSHOT_STORE_PATH: String = "user://mission_lifecycle_demo_state.json"

@export var panel_path: NodePath
@export var snapshot_store_path: String = DEFAULT_SNAPSHOT_STORE_PATH
@export var current_time_override: int = -1
@export var test_duration_seconds: int = 0
@onready var panel: MissionLifecyclePanel = get_node(panel_path) as MissionLifecyclePanel

var _game_state: Node
var _lifecycle: RefCounted
var _assignment_coordinator: RefCounted
var _snapshot_collection: RefCounted
var _snapshot_store: RefCounted
var _result_state: RefCounted
var _crew_ids: Array[String] = ["crew_01"]
var _crew_ids_by_task: Dictionary = {}

func _ready() -> void:
	_game_state = GameStateScript.new()
	add_child(_game_state)
	var assignment_state: RefCounted = MissionAssignmentStateScript.new()
	_assignment_coordinator = AssignmentCoordinatorScript.new(_game_state, assignment_state)
	var validity_query: RefCounted = ValidityQueryScript.new()
	var expired_release_service: RefCounted = ExpiredReleaseServiceScript.new(_assignment_coordinator, assignment_state, validity_query)
	_snapshot_store = ExecutionStateStoreScript.new(snapshot_store_path)
	var load_result: Dictionary = _snapshot_store.load()
	_snapshot_collection = load_result["collection"]
	_result_state = load_result["result_state"]
	_crew_ids_by_task = Dictionary(load_result["crew_ids_by_task"]).duplicate(true)
	_lifecycle = MissionLifecycleCoordinatorScript.new(_assignment_coordinator, expired_release_service, _snapshot_collection)
	_restore_result_state()
	panel.accept_requested.connect(_on_accept_requested)
	panel.completion_check_requested.connect(_on_completion_check_requested)
	panel.claim_requested.connect(_on_claim_requested)
	if not bool(load_result["is_loaded"]):
		panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_AVAILABLE, "快照讀取失敗：%s" % load_result["error_code"])
		return
	_restore_execution()

func _on_accept_requested() -> void:
	var result: Dictionary = _lifecycle.accept_execution(TEST_TASK_ID, _crew_ids, _get_current_time_seconds(), test_duration_seconds)
	if bool(result["is_accepted"]):
		_crew_ids_by_task[TEST_TASK_ID] = _crew_ids.duplicate()
		var save_result: Dictionary = _save_execution_state()
		if bool(save_result["is_saved"]):
			panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_DISPATCHED, "已派遣 1 名小弟；快照已保存")
			return
		_assignment_coordinator.release_assignment(TEST_TASK_ID)
		_snapshot_collection.remove_snapshot(TEST_TASK_ID)
		_crew_ids_by_task.erase(TEST_TASK_ID)
		panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_AVAILABLE, "快照保存失敗：%s" % save_result["error_code"])
		return
	panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_AVAILABLE, "接受失敗：%s" % result["error_code"])

func _on_completion_check_requested() -> void:
	var result: Dictionary = _lifecycle.resolve_completed_result(TEST_TASK_ID, _get_current_time_seconds())
	if bool(result["is_resolved"]):
		var save_result: Dictionary = _save_execution_state()
		if not bool(save_result["is_saved"]):
			panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_COMPLETED, "結果已鎖定，但保存失敗：%s" % save_result["error_code"])
			return
		panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_COMPLETED, "結果已鎖定，報酬：[PLACEHOLDER]")
		return
	panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_DISPATCHED, "尚未完成：%s" % result["error_code"])

func _on_claim_requested() -> void:
	var result: Dictionary = _lifecycle.claim_completed_result(TEST_TASK_ID, _get_current_time_seconds())
	if bool(result["is_claimed"]):
		_crew_ids_by_task.erase(TEST_TASK_ID)
		var save_result: Dictionary = _save_execution_state()
		if bool(save_result["is_saved"]):
			panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_CLAIMED, "已收取固定結果；快照已清除")
			return
		panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_CLAIMED, "已收取；快照清除失敗：%s" % save_result["error_code"])
		return
	panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_COMPLETED, "收取失敗：%s" % result["error_code"])

func _restore_execution() -> void:
	var restored_clock: Variant = _snapshot_collection.restore_clock(TEST_TASK_ID)
	if restored_clock == null:
		panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_AVAILABLE, "固定本地測試資料")
		return
	var restored_crew_ids: Array[String] = _get_saved_crew_ids(TEST_TASK_ID)
	var assignment_result: Dictionary = _assignment_coordinator.accept_assignment(TEST_TASK_ID, restored_crew_ids)
	if not bool(assignment_result["is_accepted"]):
		panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_AVAILABLE, "快照復原失敗：%s" % assignment_result["error_code"])
		return
	if not _result_state.get_locked_result(TEST_TASK_ID).is_empty():
		panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_COMPLETED, "已從保存狀態復原：完成待收取")
		return
	if restored_clock.is_completed(_get_current_time_seconds()):
		var completion_result: Dictionary = _lifecycle.resolve_completed_result(TEST_TASK_ID, _get_current_time_seconds())
		if bool(completion_result["is_resolved"]):
			var save_result: Dictionary = _save_execution_state()
			if not bool(save_result["is_saved"]):
				panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_COMPLETED, "結果已鎖定，但保存失敗：%s" % save_result["error_code"])
				return
			panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_COMPLETED, "已從快照復原：完成待收取")
			return
		panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_DISPATCHED, "快照復原後無法鎖定結果")
		return
	panel.set_task_state(TEST_TASK_ID, MissionLifecyclePanel.STATE_DISPATCHED, "已從快照復原：派遣中")

func _save_execution_state() -> Dictionary:
	_capture_result_state()
	return _snapshot_store.save(_snapshot_collection, _result_state, _crew_ids_by_task)

func _restore_result_state() -> void:
	var result_data: Dictionary = _result_state.to_data()
	_lifecycle._locked_results_by_mission_run_id = result_data["locked_results_by_mission_run_id"].duplicate(true)
	_lifecycle._claimed_mission_run_ids = result_data["claimed_mission_run_ids"].duplicate(true)
	_lifecycle._locked_results_by_task_id = {}
	_lifecycle._claimed_task_ids = {}
	for mission_run_id_variant: Variant in _lifecycle._locked_results_by_mission_run_id:
		var mission_run_id: String = str(mission_run_id_variant)
		var result: Dictionary = Dictionary(_lifecycle._locked_results_by_mission_run_id[mission_run_id])
		var task_id: String = str(result.get("task_id", ""))
		if task_id.is_empty():
			continue
		_lifecycle._locked_results_by_task_id[task_id] = result.duplicate(true)
		if _lifecycle._claimed_mission_run_ids.has(mission_run_id):
			_lifecycle._claimed_task_ids[task_id] = true

func _capture_result_state() -> void:
	_result_state = ResultStateSnapshotScript.new(
		_lifecycle._locked_results_by_mission_run_id,
		_lifecycle._claimed_mission_run_ids
	)

func _get_saved_crew_ids(task_id: String) -> Array[String]:
	var crew_ids: Array[String] = []
	for crew_id_variant: Variant in Array(_crew_ids_by_task.get(task_id, [])):
		crew_ids.append(str(crew_id_variant))
	return crew_ids

func _get_current_time_seconds() -> int:
	if current_time_override >= 0:
		return current_time_override
	return int(Time.get_unix_time_from_system())

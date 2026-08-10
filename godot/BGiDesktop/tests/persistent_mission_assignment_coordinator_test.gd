extends SceneTree

const GameStateScript = preload("res://scripts/game_state.gd")
const MissionAssignmentStateScript = preload("res://scripts/mission_assignment_state.gd")
const CoordinatorScript = preload("res://scripts/persistent_mission_assignment_coordinator.gd")

class FailingGameState extends RefCounted:
	const AVAILABLE := 0
	const ASSIGNED := 1

	var _crew: Array[Dictionary] = [
		{"id": "crew_01", "status": AVAILABLE},
		{"id": "crew_02", "status": AVAILABLE},
	]

	func get_crew() -> Array[Dictionary]:
		return _crew.duplicate(true)

	func set_crew_status(crew_id: String, status: int) -> Dictionary:
		if crew_id == "crew_02" and status == ASSIGNED:
			return {"is_updated": false, "error_code": "injected_failure"}
		for crew_member: Dictionary in _crew:
			if crew_member["id"] == crew_id:
				crew_member["status"] = status
				return {"is_updated": true, "error_code": ""}
		return {"is_updated": false, "error_code": "crew_not_found"}

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := GameStateScript.new()
	root.add_child(game_state)
	var assignment_state := MissionAssignmentStateScript.new()
	var coordinator := CoordinatorScript.new(game_state, assignment_state)

	_expect_result(coordinator.accept_assignment("task_01", ["crew_01", "crew_02"]), "is_accepted", true, "")
	_expect(_status_for(game_state.get_crew(), "crew_01") == GameStateScript.ASSIGNED_STATUS, "成功配置必須持久標示派遣中")
	_expect(_status_for(game_state.get_crew(), "crew_02") == GameStateScript.ASSIGNED_STATUS, "成功配置必須持久標示派遣中")

	var before_rejection: Array[Dictionary] = game_state.get_crew()
	_expect_result(coordinator.accept_assignment("task_02", ["crew_01"]), "is_accepted", false, "crew_not_available")
	_expect(game_state.get_crew() == before_rejection, "規則拒絕後 GameState 不得改變")

	_expect_result(coordinator.release_assignment("task_01"), "is_released", true, "")
	for crew_member: Dictionary in game_state.get_crew():
		_expect(crew_member["status"] == GameStateScript.CrewStatus.AVAILABLE, "釋放後小弟必須回復可用")
	_expect(assignment_state.get_assigned_crew_ids("task_01").is_empty(), "釋放後任務配置必須為空")

	var failing_game_state := FailingGameState.new()
	var failing_assignment_state := MissionAssignmentStateScript.new()
	var failing_coordinator := CoordinatorScript.new(failing_game_state, failing_assignment_state)
	_expect_result(failing_coordinator.accept_assignment("task_02", ["crew_01", "crew_02"]), "is_accepted", false, "crew_state_update_failed")
	for crew_member: Dictionary in failing_game_state.get_crew():
		_expect(crew_member["status"] == FailingGameState.AVAILABLE, "中途失敗後已變更狀態必須回復")
	_expect(failing_assignment_state.get_assigned_crew_ids("task_02").is_empty(), "中途失敗後任務配置必須回復")

	game_state.queue_free()
	quit(1 if _failed else 0)

func _status_for(crew: Array[Dictionary], crew_id: String) -> int:
	for crew_member: Dictionary in crew:
		if crew_member["id"] == crew_id:
			return int(crew_member["status"])
	return -1

func _expect_result(result: Dictionary, result_key: String, expected_value: bool, expected_error: String) -> void:
	_expect(result.get(result_key) == expected_value and result.get("error_code") == expected_error, "Coordinator 結果不符：%s" % result)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("PersistentMissionAssignmentCoordinator 測試失敗：%s" % message)

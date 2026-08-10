extends SceneTree

const GameStateScript = preload("res://scripts/game_state.gd")
const MissionAssignmentStateScript = preload("res://scripts/mission_assignment_state.gd")
const AssignmentCoordinatorScript = preload("res://scripts/persistent_mission_assignment_coordinator.gd")
const MissionAbortServiceScript = preload("res://scripts/mission_abort_service.gd")
const ClockScript = preload("res://scripts/mission_execution_clock.gd")
const ValidityQueryScript = preload("res://scripts/mission_execution_validity_query.gd")
const ExpiredReleaseServiceScript = preload("res://scripts/mission_expired_release_service.gd")

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := GameStateScript.new()
	root.add_child(game_state)
	var assignment_state := MissionAssignmentStateScript.new()
	var assignment_coordinator := AssignmentCoordinatorScript.new(game_state, assignment_state)
	var abort_service := MissionAbortServiceScript.new(assignment_coordinator, assignment_state)
	var expired_release_service := ExpiredReleaseServiceScript.new(assignment_coordinator, assignment_state, ValidityQueryScript.new())
	var clock := ClockScript.new("task_01", 100, 5)

	_expect(assignment_coordinator.accept_assignment("task_01", ["crew_01"])["is_accepted"], "前置派遣必須成功")
	_expect_result(expired_release_service.release_if_expired("task_01", clock, 104), false, "execution_not_completed")
	_expect(_status_for(game_state.get_crew(), "crew_01") == GameStateScript.ASSIGNED_STATUS, "未到期拒絕後小弟必須維持派遣中")
	_expect_result(expired_release_service.release_if_expired("task_01", clock, 105), true, "")
	_expect(assignment_state.get_assigned_crew_ids("task_01").is_empty(), "到期釋放後配置必須為空")
	_expect(_status_for(game_state.get_crew(), "crew_01") == GameStateScript.CrewStatus.AVAILABLE, "到期釋放後小弟必須可用")
	_expect_result(expired_release_service.release_if_expired("task_01", clock, 105), false, "task_not_assigned")

	_expect(assignment_coordinator.accept_assignment("task_02", ["crew_01"])["is_accepted"], "中止前置派遣必須成功")
	_expect(abort_service.abort("task_02")["is_aborted"], "中止前置任務必須成功")
	var aborted_clock := ClockScript.new("task_02", 100, 5)
	_expect_result(expired_release_service.release_if_expired("task_02", aborted_clock, 105), false, "task_not_assigned")

	game_state.queue_free()
	quit(1 if _failed else 0)

func _status_for(crew: Array[Dictionary], crew_id: String) -> int:
	for crew_member: Dictionary in crew:
		if crew_member["id"] == crew_id:
			return int(crew_member["status"])
	return -1

func _expect_result(result: Dictionary, expected_released: bool, expected_error: String) -> void:
	_expect(result.get("is_released") == expected_released and result.get("error_code") == expected_error, "到期釋放結果不符：%s" % result)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionExpiredReleaseService 測試失敗：%s" % message)

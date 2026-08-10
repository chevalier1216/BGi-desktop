extends SceneTree

const StarterMissionCatalogScript = preload("res://scripts/starter_mission_catalog.gd")
const TutorialTaskProgressionScript = preload("res://scripts/tutorial_task_progression.gd")
const GameStateScript = preload("res://scripts/game_state.gd")
const MissionAssignmentStateScript = preload("res://scripts/mission_assignment_state.gd")
const AssignmentCoordinatorScript = preload("res://scripts/persistent_mission_assignment_coordinator.gd")
const ClockScript = preload("res://scripts/mission_execution_clock.gd")
const ValidityQueryScript = preload("res://scripts/mission_execution_validity_query.gd")
const CompletionCoordinatorScript = preload("res://scripts/tutorial_mission_completion_coordinator.gd")
const ExpiredReleaseServiceScript = preload("res://scripts/mission_expired_release_service.gd")

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var catalog := StarterMissionCatalogScript.new()
	var game_state := GameStateScript.new()
	root.add_child(catalog)
	root.add_child(game_state)
	var progression := TutorialTaskProgressionScript.new(catalog.get_missions())
	var assignment_state := MissionAssignmentStateScript.new()
	var assignment_coordinator := AssignmentCoordinatorScript.new(game_state, assignment_state)
	var validity_query := ValidityQueryScript.new()
	var completion_coordinator := CompletionCoordinatorScript.new(progression, assignment_state, validity_query)
	var expired_release_service := ExpiredReleaseServiceScript.new(assignment_coordinator, assignment_state, validity_query)
	var task_id: String = progression.get_current_task()["id"]
	var clock := ClockScript.new(task_id, 100, 5)

	_expect(assignment_coordinator.accept_assignment(task_id, ["crew_01"])["is_accepted"], "派遣必須成功")
	_expect_result(completion_coordinator.complete_current_task(task_id, clock, 104), "is_completed", false, "execution_not_completed")
	_expect_result(expired_release_service.release_if_expired(task_id, clock, 104), "is_released", false, "execution_not_completed")
	_expect(_status_for(game_state.get_crew(), "crew_01") == GameStateScript.ASSIGNED_STATUS, "未到期拒絕後小弟必須維持派遣中")

	_expect_result(completion_coordinator.complete_current_task(task_id, clock, 105), "is_completed", true, "")
	_expect(progression.get_current_task()["id"] == "starter_02", "到期完成後必須推進新手進度")
	_expect_result(expired_release_service.release_if_expired(task_id, clock, 105), "is_released", true, "")
	_expect(_status_for(game_state.get_crew(), "crew_01") == GameStateScript.CrewStatus.AVAILABLE, "到期釋放後小弟必須可用")

	_expect_result(completion_coordinator.complete_current_task(task_id, clock, 105), "is_completed", false, "task_not_current")
	_expect_result(expired_release_service.release_if_expired(task_id, clock, 105), "is_released", false, "task_not_assigned")

	catalog.queue_free()
	game_state.queue_free()
	quit(1 if _failed else 0)

func _status_for(crew: Array[Dictionary], crew_id: String) -> int:
	for crew_member: Dictionary in crew:
		if crew_member["id"] == crew_id:
			return int(crew_member["status"])
	return -1

func _expect_result(result: Dictionary, result_key: String, expected_value: bool, expected_error: String) -> void:
	_expect(result.get(result_key) == expected_value and result.get("error_code") == expected_error, "生命週期結果不符：%s" % result)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("TutorialMissionLifecycle 測試失敗：%s" % message)

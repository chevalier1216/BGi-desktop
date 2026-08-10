extends SceneTree

const StarterMissionCatalogScript = preload("res://scripts/starter_mission_catalog.gd")
const TutorialTaskProgressionScript = preload("res://scripts/tutorial_task_progression.gd")
const GameStateScript = preload("res://scripts/game_state.gd")
const MissionAssignmentStateScript = preload("res://scripts/mission_assignment_state.gd")
const AssignmentCoordinatorScript = preload("res://scripts/persistent_mission_assignment_coordinator.gd")
const MissionAbortServiceScript = preload("res://scripts/mission_abort_service.gd")
const ClockScript = preload("res://scripts/mission_execution_clock.gd")
const ValidityQueryScript = preload("res://scripts/mission_execution_validity_query.gd")
const CompletionCoordinatorScript = preload("res://scripts/tutorial_mission_completion_coordinator.gd")

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
	var abort_service := MissionAbortServiceScript.new(assignment_coordinator, assignment_state)
	var completion_coordinator := CompletionCoordinatorScript.new(progression, assignment_state, ValidityQueryScript.new())
	var task_id: String = progression.get_current_task()["id"]
	var clock := ClockScript.new(task_id, 100, 5)

	_expect(assignment_coordinator.accept_assignment(task_id, ["crew_01"])["is_accepted"], "前置派遣必須成功")
	_expect_result(completion_coordinator.complete_current_task(task_id, clock, 104), false, "execution_not_completed")
	_expect(progression.get_current_task()["id"] == task_id, "未到期不得推進")
	_expect_result(completion_coordinator.complete_current_task("starter_02", clock, 105), false, "task_not_current")

	_expect(abort_service.abort(task_id)["is_aborted"], "中止前置任務必須成功")
	_expect_result(completion_coordinator.complete_current_task(task_id, clock, 105), false, "task_not_assigned")

	_expect(assignment_coordinator.accept_assignment(task_id, ["crew_01"])["is_accepted"], "重新派遣必須成功")
	_expect(assignment_coordinator.release_assignment(task_id)["is_released"], "解除派遣必須成功")
	_expect_result(completion_coordinator.complete_current_task(task_id, clock, 105), false, "task_not_assigned")

	_expect(assignment_coordinator.accept_assignment(task_id, ["crew_01"])["is_accepted"], "完成前派遣必須成功")
	_expect_result(completion_coordinator.complete_current_task(task_id, clock, 105), true, "")
	_expect(progression.get_current_task()["id"] == "starter_02", "時計完成且有效派遣時必須推進下一任務")

	catalog.queue_free()
	game_state.queue_free()
	quit(1 if _failed else 0)

func _expect_result(result: Dictionary, expected_completed: bool, expected_error: String) -> void:
	_expect(result.get("is_completed") == expected_completed and result.get("error_code") == expected_error, "新手完成協調結果不符：%s" % result)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("TutorialMissionCompletionCoordinator 測試失敗：%s" % message)

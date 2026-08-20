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
	root.add_child(catalog)
	var progression := TutorialTaskProgressionScript.new(catalog.get_missions())
	var assignment_state := MissionAssignmentStateScript.new()
	var validity_query := ValidityQueryScript.new()
	var completion_coordinator := CompletionCoordinatorScript.new(progression, assignment_state, validity_query)
	var task_id: String = progression.get_current_task()["id"]

	_expect_result(completion_coordinator.complete_claimed_current_task(task_id, {}), "is_completed", false, "claim_receipt_required")
	_expect(progression.get_current_task()["id"] == "starter_01", "沒有收據時不得推進新手進度")
	var receipt := {
		"claim_receipt_id": "claim_starter_01",
		"mission_run_id": "run_starter_01",
		"result_id": "result_starter_01",
	}
	_expect_result(completion_coordinator.complete_claimed_current_task(task_id, receipt), "is_completed", true, "")
	_expect(progression.get_current_task()["id"] == "starter_02", "成功領取後必須推進新手進度")
	_expect_result(completion_coordinator.complete_claimed_current_task(task_id, receipt), "is_completed", false, "task_not_current")

	catalog.queue_free()
	quit(1 if _failed else 0)

func _expect_result(result: Dictionary, result_key: String, expected_value: bool, expected_error: String) -> void:
	_expect(result.get(result_key) == expected_value and result.get("error_code") == expected_error, "生命週期結果不符：%s" % result)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("TutorialMissionLifecycle 測試失敗：%s" % message)

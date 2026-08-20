extends SceneTree

const StarterMissionCatalogScript = preload("res://scripts/starter_mission_catalog.gd")
const TutorialTaskProgressionScript = preload("res://scripts/tutorial_task_progression.gd")
const MissionAssignmentStateScript = preload("res://scripts/mission_assignment_state.gd")
const ValidityQueryScript = preload("res://scripts/mission_execution_validity_query.gd")
const CompletionCoordinatorScript = preload("res://scripts/tutorial_mission_completion_coordinator.gd")

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var catalog := StarterMissionCatalogScript.new()
	root.add_child(catalog)
	var progression := TutorialTaskProgressionScript.new(catalog.get_missions())
	var assignment_state := MissionAssignmentStateScript.new()
	var completion_coordinator := CompletionCoordinatorScript.new(progression, assignment_state, ValidityQueryScript.new())
	var task_id: String = progression.get_current_task()["id"]

	_expect_result(completion_coordinator.complete_claimed_current_task(task_id, {}), false, "claim_receipt_required")
	_expect(progression.get_current_task()["id"] == task_id, "缺少收據不得推進教學")
	var valid_receipt: Dictionary = {
		"claim_receipt_id": "starter_01:100:claim",
		"mission_run_id": "starter_01:100",
		"result_id": "starter_01:100:result",
	}
	_expect_result(completion_coordinator.complete_claimed_current_task("starter_02", valid_receipt), false, "task_not_current")
	_expect_result(completion_coordinator.complete_claimed_current_task(task_id, valid_receipt), true, "")
	_expect(progression.get_current_task()["id"] == "starter_02", "已保存收據的目前任務必須推進下一任務")
	_expect_result(completion_coordinator.complete_claimed_current_task(task_id, valid_receipt), false, "task_not_current")

	catalog.queue_free()
	quit(1 if _failed else 0)

func _expect_result(result: Dictionary, expected_completed: bool, expected_error: String) -> void:
	_expect(result.get("is_completed") == expected_completed and result.get("error_code") == expected_error, "新手完成協調結果不符：%s" % result)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("TutorialMissionCompletionCoordinator 測試失敗：%s" % message)

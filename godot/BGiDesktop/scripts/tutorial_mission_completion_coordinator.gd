class_name TutorialMissionCompletionCoordinator
extends RefCounted

var _progression: RefCounted
var _assignment_state: RefCounted
var _validity_query: RefCounted

func _init(progression: RefCounted, assignment_state: RefCounted, validity_query: RefCounted) -> void:
	_progression = progression
	_assignment_state = assignment_state
	_validity_query = validity_query

func complete_claimed_current_task(task_id: String, claim_receipt: Dictionary) -> Dictionary:
	var current_task: Dictionary = _progression.get_current_task()
	if current_task.is_empty():
		return _rejected("tutorial_completed")
	if current_task["id"] != task_id:
		return _rejected("task_not_current")
	if str(claim_receipt.get("claim_receipt_id", "")).is_empty() or str(claim_receipt.get("mission_run_id", "")).is_empty() or str(claim_receipt.get("result_id", "")).is_empty():
		return _rejected("claim_receipt_required")

	var progression_result: Dictionary = _progression.complete_current_task(task_id)
	if not bool(progression_result["is_advanced"]):
		return _rejected(str(progression_result["error_code"]))
	return {"is_completed": true, "error_code": ""}

func _rejected(error_code: String) -> Dictionary:
	return {"is_completed": false, "error_code": error_code}

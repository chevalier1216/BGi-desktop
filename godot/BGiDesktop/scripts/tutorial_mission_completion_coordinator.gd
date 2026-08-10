class_name TutorialMissionCompletionCoordinator
extends RefCounted

var _progression: RefCounted
var _assignment_state: RefCounted
var _validity_query: RefCounted

func _init(progression: RefCounted, assignment_state: RefCounted, validity_query: RefCounted) -> void:
	_progression = progression
	_assignment_state = assignment_state
	_validity_query = validity_query

func complete_current_task(task_id: String, clock: RefCounted, current_time_seconds: int) -> Dictionary:
	var current_task: Dictionary = _progression.get_current_task()
	if current_task.is_empty():
		return _rejected("tutorial_completed")
	if current_task["id"] != task_id:
		return _rejected("task_not_current")

	var execution_status: Dictionary = _validity_query.get_status(_assignment_state, task_id, clock, current_time_seconds)
	if not bool(execution_status["is_valid_execution"]):
		return _rejected(str(execution_status["error_code"]))
	if not bool(execution_status["is_completed"]):
		return _rejected("execution_not_completed")

	var progression_result: Dictionary = _progression.complete_current_task(task_id)
	if not bool(progression_result["is_advanced"]):
		return _rejected(str(progression_result["error_code"]))
	return {"is_completed": true, "error_code": ""}

func _rejected(error_code: String) -> Dictionary:
	return {"is_completed": false, "error_code": error_code}

class_name MissionExpiredReleaseService
extends RefCounted

var _coordinator: RefCounted
var _assignment_state: RefCounted
var _validity_query: RefCounted

func _init(coordinator: RefCounted, assignment_state: RefCounted, validity_query: RefCounted) -> void:
	_coordinator = coordinator
	_assignment_state = assignment_state
	_validity_query = validity_query

func mark_completed_if_expired(task_id: String, clock: RefCounted, current_time_seconds: int) -> Dictionary:
	var execution_status: Dictionary = _validity_query.get_status(_assignment_state, task_id, clock, current_time_seconds)
	if not bool(execution_status["is_valid_execution"]):
		return _rejected(str(execution_status["error_code"]))
	if not bool(execution_status["is_completed"]):
		return _rejected("execution_not_completed")
	var completion_result: Dictionary = _coordinator.mark_assignment_completed(task_id)
	if not bool(completion_result["is_completed"]):
		return _rejected(str(completion_result["error_code"]))
	return {"is_completed": true, "error_code": ""}

func _rejected(error_code: String) -> Dictionary:
	return {"is_completed": false, "error_code": error_code}

class_name MissionExpiredReleaseService
extends RefCounted

var _coordinator: RefCounted
var _assignment_state: RefCounted
var _validity_query: RefCounted

func _init(coordinator: RefCounted, assignment_state: RefCounted, validity_query: RefCounted) -> void:
	_coordinator = coordinator
	_assignment_state = assignment_state
	_validity_query = validity_query

func release_if_expired(task_id: String, clock: RefCounted, current_time_seconds: int) -> Dictionary:
	var execution_status: Dictionary = _validity_query.get_status(_assignment_state, task_id, clock, current_time_seconds)
	if not bool(execution_status["is_valid_execution"]):
		return _rejected(str(execution_status["error_code"]))
	if not bool(execution_status["is_completed"]):
		return _rejected("execution_not_completed")
	var release_result: Dictionary = _coordinator.release_assignment(task_id)
	if not bool(release_result["is_released"]):
		return _rejected(str(release_result["error_code"]))
	return {"is_released": true, "error_code": ""}

func _rejected(error_code: String) -> Dictionary:
	return {"is_released": false, "error_code": error_code}

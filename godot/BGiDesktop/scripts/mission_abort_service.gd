class_name MissionAbortService
extends RefCounted

var _coordinator: RefCounted
var _assignment_state: RefCounted

func _init(coordinator: RefCounted, assignment_state: RefCounted) -> void:
	_coordinator = coordinator
	_assignment_state = assignment_state

func abort(task_id: String) -> Dictionary:
	if _assignment_state.get_assigned_crew_ids(task_id).is_empty():
		return {"is_aborted": false, "error_code": "task_not_assigned"}
	var release_result: Dictionary = _coordinator.release_assignment(task_id)
	if not bool(release_result["is_released"]):
		return {"is_aborted": false, "error_code": release_result["error_code"]}
	return {"is_aborted": true, "error_code": ""}

class_name MissionExecutionValidityQuery
extends RefCounted

func get_status(assignment_state: RefCounted, task_id: String, clock: RefCounted, current_time_seconds: int) -> Dictionary:
	if clock.task_id != task_id:
		return _invalid("clock_task_mismatch")
	if assignment_state.get_assigned_crew_ids(task_id).is_empty():
		return _invalid("task_not_assigned")
	return {
		"is_valid_execution": true,
		"remaining_seconds": clock.get_remaining_seconds(current_time_seconds),
		"is_completed": clock.is_completed(current_time_seconds),
		"error_code": "",
	}

func _invalid(error_code: String) -> Dictionary:
	return {"is_valid_execution": false, "error_code": error_code}

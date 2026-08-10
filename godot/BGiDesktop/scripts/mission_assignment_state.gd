class_name MissionAssignmentState
extends RefCounted

var _crew_ids_by_task: Dictionary = {}
var _task_id_by_crew_id: Dictionary = {}

func assign(task_id: String, crew_ids: Array[String]) -> Dictionary:
	if _crew_ids_by_task.has(task_id):
		return _rejected("task_already_assigned")
	var requested_crew_ids: Dictionary = {}
	for crew_id in crew_ids:
		if requested_crew_ids.has(crew_id) or _task_id_by_crew_id.has(crew_id):
			return _rejected("crew_already_assigned")
		requested_crew_ids[crew_id] = true

	_crew_ids_by_task[task_id] = crew_ids.duplicate()
	for crew_id in crew_ids:
		_task_id_by_crew_id[crew_id] = task_id
	return {"is_assigned": true, "error_code": ""}

func get_assigned_crew_ids(task_id: String) -> Array[String]:
	if not _crew_ids_by_task.has(task_id):
		return []
	var crew_ids: Array[String] = _crew_ids_by_task[task_id]
	return crew_ids.duplicate()

func release(task_id: String) -> Array[String]:
	var crew_ids := get_assigned_crew_ids(task_id)
	if crew_ids.is_empty():
		return []
	for crew_id in crew_ids:
		_task_id_by_crew_id.erase(crew_id)
	_crew_ids_by_task.erase(task_id)
	return crew_ids

func _rejected(error_code: String) -> Dictionary:
	return {"is_assigned": false, "error_code": error_code}

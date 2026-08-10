class_name TutorialTaskProgression
extends RefCounted

var _missions: Array[Dictionary] = []
var _current_index := 0

func _init(missions: Array[Dictionary]) -> void:
	_missions = missions.duplicate(true)

func get_current_task() -> Dictionary:
	if _current_index >= _missions.size():
		return {}
	return _missions[_current_index].duplicate(true)

func complete_current_task(task_id: String) -> Dictionary:
	var current_task := get_current_task()
	if current_task.is_empty():
		return {"is_advanced": false, "error_code": "tutorial_completed"}
	if current_task["id"] != task_id:
		return {"is_advanced": false, "error_code": "task_not_current"}
	_current_index += 1
	return {"is_advanced": true, "error_code": ""}

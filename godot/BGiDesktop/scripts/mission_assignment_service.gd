class_name MissionAssignmentService
extends RefCounted

const GameStateScript = preload("res://scripts/game_state.gd")
const DispatchRulesScript = preload("res://scripts/dispatch_rules.gd")

var _assignment_state: RefCounted

func _init(assignment_state: RefCounted) -> void:
	_assignment_state = assignment_state

func accept_assignment(task_id: String, crew: Array[Dictionary], crew_ids: Array[String]) -> Dictionary:
	var validation_result: Dictionary = DispatchRulesScript.validate_assignment(_to_dispatch_rule_crew(crew), crew_ids)
	if not bool(validation_result["is_valid"]):
		return _rejected(str(validation_result["error_code"]))

	var assignment_result: Dictionary = _assignment_state.assign(task_id, crew_ids)
	if not bool(assignment_result["is_assigned"]):
		return _rejected(str(assignment_result["error_code"]))

	var crew_by_id := _crew_by_id(crew)
	for crew_id in crew_ids:
		crew_by_id[crew_id]["status"] = GameStateScript.CrewStatus.DISPATCHED
	return {"is_accepted": true, "error_code": ""}

func release_assignment(task_id: String, crew: Array[Dictionary]) -> Array[String]:
	var released_crew_ids: Array[String] = _assignment_state.release(task_id)
	var crew_by_id := _crew_by_id(crew)
	for crew_id in released_crew_ids:
		if crew_by_id.has(crew_id):
			crew_by_id[crew_id]["status"] = GameStateScript.CrewStatus.AVAILABLE
	return released_crew_ids

func _to_dispatch_rule_crew(crew: Array[Dictionary]) -> Array[Dictionary]:
	var rule_crew: Array[Dictionary] = []
	for crew_member: Dictionary in crew:
		var rule_status := DispatchRulesScript.AVAILABLE_STATUS if crew_member.get("status") == GameStateScript.CrewStatus.AVAILABLE else "unavailable"
		rule_crew.append({"id": crew_member.get("id", ""), "status": rule_status})
	return rule_crew

func _crew_by_id(crew: Array[Dictionary]) -> Dictionary:
	var crew_by_id: Dictionary = {}
	for crew_member: Dictionary in crew:
		crew_by_id[crew_member.get("id", "")] = crew_member
	return crew_by_id

func _rejected(error_code: String) -> Dictionary:
	return {"is_accepted": false, "error_code": error_code}

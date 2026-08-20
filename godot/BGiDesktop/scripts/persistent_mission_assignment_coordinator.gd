class_name PersistentMissionAssignmentCoordinator
extends RefCounted

const GameStateScript = preload("res://scripts/game_state.gd")
const DispatchRulesScript = preload("res://scripts/dispatch_rules.gd")

var _game_state: Object
var _assignment_state: RefCounted

func _init(game_state: Object, assignment_state: RefCounted) -> void:
	_game_state = game_state
	_assignment_state = assignment_state

func accept_assignment(task_id: String, crew_ids: Array[String]) -> Dictionary:
	var validation_result: Dictionary = DispatchRulesScript.validate_assignment(_to_dispatch_rule_crew(_game_state.get_crew()), crew_ids)
	if not bool(validation_result["is_valid"]):
		return _rejected("is_accepted", str(validation_result["error_code"]))

	var assignment_result: Dictionary = _assignment_state.assign(task_id, crew_ids)
	if not bool(assignment_result["is_assigned"]):
		return _rejected("is_accepted", str(assignment_result["error_code"]))

	var updated_crew_ids: Array[String] = []
	for crew_id in crew_ids:
		var state_result: Dictionary = _game_state.set_crew_status(crew_id, GameStateScript.ASSIGNED_STATUS)
		if not bool(state_result["is_updated"]):
			_set_status(updated_crew_ids, GameStateScript.CrewStatus.AVAILABLE)
			_assignment_state.release(task_id)
			return _rejected("is_accepted", "crew_state_update_failed")
		updated_crew_ids.append(crew_id)
	return {"is_accepted": true, "error_code": ""}

func release_assignment(task_id: String) -> Dictionary:
	var assigned_crew_ids: Array[String] = _assignment_state.get_assigned_crew_ids(task_id)
	if assigned_crew_ids.is_empty():
		return _rejected("is_released", "task_not_assigned")

	var restored_crew_ids: Array[String] = []
	for crew_id in assigned_crew_ids:
		var state_result: Dictionary = _game_state.set_crew_status(crew_id, GameStateScript.CrewStatus.AVAILABLE)
		if not bool(state_result["is_updated"]):
			_set_status(restored_crew_ids, GameStateScript.ASSIGNED_STATUS)
			return _rejected("is_released", "crew_state_update_failed")
		restored_crew_ids.append(crew_id)

	var released_crew_ids: Array[String] = _assignment_state.release(task_id)
	if released_crew_ids != assigned_crew_ids:
		_set_status(restored_crew_ids, GameStateScript.ASSIGNED_STATUS)
		return _rejected("is_released", "assignment_release_failed")
	return {"is_released": true, "error_code": ""}

## Keeps an expired assignment occupied while its fixed result awaits a claim.
func mark_assignment_completed(task_id: String) -> Dictionary:
	var assigned_crew_ids: Array[String] = _assignment_state.get_assigned_crew_ids(task_id)
	if assigned_crew_ids.is_empty():
		return _rejected("is_completed", "task_not_assigned")
	var updated_crew_ids: Array[String] = []
	for crew_id: String in assigned_crew_ids:
		var state_result: Dictionary = _game_state.set_crew_status(crew_id, GameStateScript.CrewStatus.COMPLETED)
		if not bool(state_result["is_updated"]):
			_set_status(updated_crew_ids, GameStateScript.ASSIGNED_STATUS)
			return _rejected("is_completed", "crew_state_update_failed")
		updated_crew_ids.append(crew_id)
	return {"is_completed": true, "error_code": ""}

func _to_dispatch_rule_crew(crew: Array[Dictionary]) -> Array[Dictionary]:
	var rule_crew: Array[Dictionary] = []
	for crew_member: Dictionary in crew:
		var rule_status := DispatchRulesScript.AVAILABLE_STATUS if crew_member.get("status") == GameStateScript.CrewStatus.AVAILABLE else "unavailable"
		rule_crew.append({"id": crew_member.get("id", ""), "status": rule_status})
	return rule_crew

func _set_status(crew_ids: Array[String], status: int) -> void:
	for crew_id in crew_ids:
		_game_state.set_crew_status(crew_id, status)

func _rejected(result_key: String, error_code: String) -> Dictionary:
	return {result_key: false, "error_code": error_code}

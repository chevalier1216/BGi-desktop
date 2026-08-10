class_name DispatchRules
extends RefCounted

const AVAILABLE_STATUS := "available"
const MIN_ASSIGNEES := 1
const MAX_ASSIGNEES := 5

static func validate_assignment(crew: Array[Dictionary], assignee_ids: Array[String]) -> Dictionary:
	if assignee_ids.size() < MIN_ASSIGNEES:
		return _rejected("team_too_small")
	if assignee_ids.size() > MAX_ASSIGNEES:
		return _rejected("team_too_large")

	var crew_by_id: Dictionary = {}
	for crew_member: Dictionary in crew:
		crew_by_id[crew_member.get("id", "")] = crew_member

	var assigned_ids: Dictionary = {}
	for assignee_id in assignee_ids:
		if assigned_ids.has(assignee_id):
			return _rejected("duplicate_assignee")
		assigned_ids[assignee_id] = true
		if not crew_by_id.has(assignee_id):
			return _rejected("crew_not_found")
		var crew_member: Dictionary = crew_by_id[assignee_id]
		if crew_member.get("status", "") != AVAILABLE_STATUS:
			return _rejected("crew_not_available")

	return {"is_valid": true, "error_code": ""}

static func _rejected(error_code: String) -> Dictionary:
	return {"is_valid": false, "error_code": error_code}

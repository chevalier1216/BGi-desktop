class_name MissionRefreshService
extends RefCounted

const RefreshableMissionFilterScript = preload("res://scripts/refreshable_mission_filter.gd")
const MissionRefreshReplacementScript = preload("res://scripts/mission_refresh_replacement.gd")

var _allowance: RefCounted

func _init(allowance: RefCounted) -> void:
	_allowance = allowance

func refresh(current_missions: Array[Dictionary], accepted_mission_ids: Array[String], replacements_by_mission_id: Dictionary, current_time_seconds: int) -> Dictionary:
	_allowance.update(current_time_seconds)
	if _allowance.get_allowance() == 0:
		return _rejected(current_missions, "refresh_allowance_unavailable")

	var refreshable_missions: Array[Dictionary] = RefreshableMissionFilterScript.get_refreshable_missions(current_missions, accepted_mission_ids)
	if not _has_replacement(refreshable_missions, replacements_by_mission_id):
		return _rejected(current_missions, "no_refreshable_replacement")
	if not _allowance.consume(current_time_seconds):
		return _rejected(current_missions, "refresh_allowance_unavailable")

	return {
		"is_refreshed": true,
		"missions": MissionRefreshReplacementScript.replace_unaccepted_missions(current_missions, accepted_mission_ids, replacements_by_mission_id),
		"error_code": "",
	}

func _has_replacement(refreshable_missions: Array[Dictionary], replacements_by_mission_id: Dictionary) -> bool:
	for mission: Dictionary in refreshable_missions:
		if replacements_by_mission_id.has(mission["id"]):
			return true
	return false

func _rejected(current_missions: Array[Dictionary], error_code: String) -> Dictionary:
	return {"is_refreshed": false, "missions": current_missions.duplicate(true), "error_code": error_code}

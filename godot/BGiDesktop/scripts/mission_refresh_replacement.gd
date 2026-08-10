class_name MissionRefreshReplacement
extends RefCounted

static func replace_unaccepted_missions(current_missions: Array[Dictionary], accepted_mission_ids: Array[String], replacements_by_mission_id: Dictionary) -> Array[Dictionary]:
	var accepted_ids: Dictionary = {}
	for mission_id in accepted_mission_ids:
		accepted_ids[mission_id] = true

	var refreshed_missions: Array[Dictionary] = []
	for mission: Dictionary in current_missions:
		var mission_id: String = mission["id"]
		if not accepted_ids.has(mission_id) and replacements_by_mission_id.has(mission_id):
			refreshed_missions.append(replacements_by_mission_id[mission_id].duplicate(true))
		else:
			refreshed_missions.append(mission.duplicate(true))
	return refreshed_missions

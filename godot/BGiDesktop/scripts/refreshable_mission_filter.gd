class_name RefreshableMissionFilter
extends RefCounted

static func get_refreshable_missions(missions: Array[Dictionary], accepted_mission_ids: Array[String]) -> Array[Dictionary]:
	var accepted_ids: Dictionary = {}
	for mission_id in accepted_mission_ids:
		accepted_ids[mission_id] = true

	var refreshable_missions: Array[Dictionary] = []
	for mission: Dictionary in missions:
		if not accepted_ids.has(mission["id"]):
			refreshable_missions.append(mission.duplicate(true))
	return refreshable_missions

extends Node

const STARTER_MISSION_DURATIONS: Array[int] = [
	5, 5,
	10, 10, 10,
	30, 30, 30, 30,
	60, 60,
	180, 180, 180, 180,
	600, 600, 600, 600, 600,
	900, 900, 900,
]

const STARTER_MISSION_COUNT := 23
const EXPECTED_DURATION_COUNTS: Dictionary = {
	5: 2,
	10: 3,
	30: 4,
	60: 2,
	180: 4,
	600: 5,
	900: 3,
}

var _missions: Array[Dictionary] = []

func _ready() -> void:
	for index in STARTER_MISSION_DURATIONS.size():
		_missions.append({
			"id": "starter_%02d" % (index + 1),
			"duration_seconds": STARTER_MISSION_DURATIONS[index],
			"is_accepted": false,
		})
	assert(has_fixed_starter_distribution(), "新手固定任務目錄不符合已核准的 23 項時長配置。")

func get_missions() -> Array[Dictionary]:
	return _missions.duplicate(true)

func refresh_unaccepted_missions() -> Array[Dictionary]:
	return get_missions()

func has_fixed_starter_distribution() -> bool:
	if _missions.size() != STARTER_MISSION_COUNT:
		return false
	var actual_duration_counts: Dictionary = {}
	for mission: Dictionary in _missions:
		var duration_seconds: int = int(mission["duration_seconds"])
		actual_duration_counts[duration_seconds] = int(actual_duration_counts.get(duration_seconds, 0)) + 1
	if actual_duration_counts.size() != EXPECTED_DURATION_COUNTS.size():
		return false
	for expected_duration in EXPECTED_DURATION_COUNTS:
		if actual_duration_counts.get(expected_duration, 0) != EXPECTED_DURATION_COUNTS[expected_duration]:
			return false
	return true

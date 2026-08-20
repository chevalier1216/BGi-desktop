class_name MissionExecutionSnapshot
extends RefCounted

const MissionExecutionClockScript = preload("res://scripts/mission_execution_clock.gd")

var task_id: String
var mission_run_id: String
var started_at_seconds: int
var duration_seconds: int

func _init(new_task_id: String, new_started_at_seconds: int, new_duration_seconds: int, new_mission_run_id: String = "") -> void:
	task_id = new_task_id
	mission_run_id = new_mission_run_id
	started_at_seconds = new_started_at_seconds
	duration_seconds = new_duration_seconds

func to_data() -> Dictionary:
	return {
		"task_id": task_id,
		"mission_run_id": mission_run_id,
		"started_at_seconds": started_at_seconds,
		"duration_seconds": duration_seconds,
	}

static func from_data(data: Dictionary) -> Variant:
	var snapshot_script: GDScript = load("res://scripts/mission_execution_snapshot.gd")
	return snapshot_script.new(str(data["task_id"]), int(data["started_at_seconds"]), int(data["duration_seconds"]), str(data.get("mission_run_id", "")))

func restore_clock() -> RefCounted:
	return MissionExecutionClockScript.new(task_id, started_at_seconds, duration_seconds)

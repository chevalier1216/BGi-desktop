class_name MissionExecutionClock
extends RefCounted

var task_id: String
var started_at_seconds: int
var duration_seconds: int

func _init(new_task_id: String, new_started_at_seconds: int, new_duration_seconds: int) -> void:
	task_id = new_task_id
	started_at_seconds = new_started_at_seconds
	duration_seconds = maxi(0, new_duration_seconds)

func get_remaining_seconds(current_time_seconds: int) -> int:
	var elapsed_seconds: int = maxi(0, current_time_seconds - started_at_seconds)
	return clampi(duration_seconds - elapsed_seconds, 0, duration_seconds)

func is_completed(current_time_seconds: int) -> bool:
	return get_remaining_seconds(current_time_seconds) == 0

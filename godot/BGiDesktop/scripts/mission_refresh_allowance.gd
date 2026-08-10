class_name MissionRefreshAllowance
extends RefCounted

const REFILL_INTERVAL_SECONDS := 6 * 60 * 60
const MAX_ALLOWANCE := 1

var _allowance := 0
var _last_refill_check_seconds: int

func _init(started_at_seconds: int) -> void:
	_last_refill_check_seconds = started_at_seconds

func update(current_time_seconds: int) -> int:
	if current_time_seconds - _last_refill_check_seconds >= REFILL_INTERVAL_SECONDS:
		_allowance = mini(MAX_ALLOWANCE, _allowance + 1)
		_last_refill_check_seconds = current_time_seconds
	return _allowance

func get_allowance() -> int:
	return _allowance

func consume(current_time_seconds: int) -> bool:
	update(current_time_seconds)
	if _allowance == 0:
		return false
	_allowance -= 1
	return true

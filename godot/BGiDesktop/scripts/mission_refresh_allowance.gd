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

func to_data() -> Dictionary:
	return {
		"allowance": _allowance,
		"last_refill_check_seconds": _last_refill_check_seconds,
	}

static func from_data(data: Dictionary) -> Dictionary:
	var allowance_variant: Variant = data.get("allowance", -1)
	var last_check_variant: Variant = data.get("last_refill_check_seconds", -1)
	if not _is_integer_number(allowance_variant) or not _is_integer_number(last_check_variant):
		return {"is_valid": false, "error_code": "mission_refresh_state_invalid", "allowance": null}
	var allowance_value: int = int(allowance_variant)
	var last_check_seconds: int = int(last_check_variant)
	if allowance_value < 0 or allowance_value > MAX_ALLOWANCE or last_check_seconds < 0:
		return {"is_valid": false, "error_code": "mission_refresh_state_invalid", "allowance": null}
	var allowance: RefCounted = load("res://scripts/mission_refresh_allowance.gd").new(last_check_seconds)
	allowance._allowance = allowance_value
	return {"is_valid": true, "error_code": "", "allowance": allowance}

static func _is_integer_number(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	return typeof(value) == TYPE_FLOAT and float(value) == floorf(float(value))

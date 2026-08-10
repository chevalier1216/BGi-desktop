class_name MissionCompletionResultLock
extends RefCounted

const PLACEHOLDER_REWARD: String = "[PLACEHOLDER]"

## Returns the existing resolved result unchanged, or creates it once after completion.
static func resolve(clock: RefCounted, current_time_seconds: int, existing_result: Dictionary) -> Dictionary:
	if not existing_result.is_empty():
		if str(existing_result.get("task_id", "")) != clock.task_id:
			return _rejected("result_task_mismatch")
		return {
			"is_resolved": true,
			"did_resolve": false,
			"error_code": "",
			"result": existing_result.duplicate(true),
		}

	if not clock.is_completed(current_time_seconds):
		return _rejected("execution_not_completed")

	var result: Dictionary = {
		"task_id": clock.task_id,
		"resolved_at_seconds": current_time_seconds,
		"guaranteed_reward": PLACEHOLDER_REWARD,
		"extra_reward": PLACEHOLDER_REWARD,
	}
	return {
		"is_resolved": true,
		"did_resolve": true,
		"error_code": "",
		"result": result,
	}

static func _rejected(error_code: String) -> Dictionary:
	return {
		"is_resolved": false,
		"did_resolve": false,
		"error_code": error_code,
		"result": {},
	}

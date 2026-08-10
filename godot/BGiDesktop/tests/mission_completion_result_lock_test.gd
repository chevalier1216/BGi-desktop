extends SceneTree

const MissionCompletionResultLockScript = preload("res://scripts/mission_completion_result_lock.gd")
const MissionExecutionClockScript = preload("res://scripts/mission_execution_clock.gd")

var _failed: bool = false

func _init() -> void:
	var clock: RefCounted = MissionExecutionClockScript.new("starter_01", 100, 5)
	var pending_result: Dictionary = MissionCompletionResultLockScript.resolve(clock, 104, {})
	_expect(not bool(pending_result["is_resolved"]), "unfinished execution must not resolve a result")
	_expect(str(pending_result["error_code"]) == "execution_not_completed", "unfinished execution must report its state")

	var first_result: Dictionary = MissionCompletionResultLockScript.resolve(clock, 105, {})
	var first_snapshot: Dictionary = first_result["result"]
	_expect(bool(first_result["is_resolved"]), "completed execution must resolve a result")
	_expect(bool(first_result["did_resolve"]), "first completed read must create the result snapshot")
	_expect(str(first_snapshot["task_id"]) == "starter_01", "result snapshot must keep its task id")
	_expect(int(first_snapshot["resolved_at_seconds"]) == 105, "result snapshot must keep its first resolution time")
	_expect(str(first_snapshot["guaranteed_reward"]) == "[PLACEHOLDER]", "guaranteed reward remains a placeholder")
	_expect(str(first_snapshot["extra_reward"]) == "[PLACEHOLDER]", "extra reward remains a placeholder")

	var repeat_result: Dictionary = MissionCompletionResultLockScript.resolve(clock, 140, first_snapshot)
	var repeat_snapshot: Dictionary = repeat_result["result"]
	_expect(bool(repeat_result["is_resolved"]), "repeated read must return a resolved result")
	_expect(not bool(repeat_result["did_resolve"]), "repeated read must not resolve again")
	_expect(repeat_snapshot == first_snapshot, "repeated read must preserve the original result snapshot")
	_expect(int(repeat_snapshot["resolved_at_seconds"]) == 105, "repeated read must not change the first resolution time")

	var restored_clock: RefCounted = MissionExecutionClockScript.new("starter_01", 100, 5)
	var restored_result: Dictionary = MissionCompletionResultLockScript.resolve(restored_clock, 200, first_snapshot.duplicate(true))
	_expect(not bool(restored_result["did_resolve"]), "restored execution must not resolve again")
	_expect(restored_result["result"] == first_snapshot, "restored execution must keep the fixed result")

	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionCompletionResultLock test failed: %s" % message)

class_name MissionResultClaimService
extends RefCounted

const MissionCompletionResultLockScript = preload("res://scripts/mission_completion_result_lock.gd")

## Claims one completed, unclaimed task and returns its immutable locked result snapshot.
static func claim(task_id: String, clock: RefCounted, current_time_seconds: int, locked_result: Dictionary, claimed_task_ids: Dictionary) -> Dictionary:
	var saved_claims: Dictionary = claimed_task_ids.duplicate(true)
	if task_id.is_empty():
		return _rejected(saved_claims, "task_id_required")
	if task_id != str(clock.task_id):
		return _rejected(saved_claims, "task_id_mismatch")
	if saved_claims.has(task_id):
		return _rejected(saved_claims, "task_result_already_claimed")

	var resolution: Dictionary = MissionCompletionResultLockScript.resolve(clock, current_time_seconds, locked_result)
	if not bool(resolution["is_resolved"]):
		return _rejected(saved_claims, str(resolution["error_code"]))
	var result_snapshot: Dictionary = Dictionary(resolution["result"]).duplicate(true)
	saved_claims[task_id] = true
	return {
		"is_claimed": true,
		"error_code": "",
		"claimed_task_ids": saved_claims,
		"result": result_snapshot,
	}

static func _rejected(saved_claims: Dictionary, error_code: String) -> Dictionary:
	return {
		"is_claimed": false,
		"error_code": error_code,
		"claimed_task_ids": saved_claims,
		"result": {},
	}

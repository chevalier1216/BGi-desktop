class_name MissionCompletionResultLock
extends RefCounted

const PLACEHOLDER_REWARD: String = "[PLACEHOLDER]"
const ClaimEffectDescriptorScript = preload("res://scripts/claim_effect_descriptor.gd")

## Returns the existing resolved result unchanged, or creates it once after completion.
static func resolve(clock: RefCounted, current_time_seconds: int, existing_result: Dictionary, claim_effect_descriptors: Array = []) -> Dictionary:
	if not existing_result.is_empty():
		if str(existing_result.get("task_id", "")) != clock.task_id:
			return _rejected("result_task_mismatch")
		var existing_descriptors: Dictionary = ClaimEffectDescriptorScript.validate_all(existing_result.get("claim_effect_descriptors", null))
		if not bool(existing_descriptors["is_valid"]):
			return _rejected("claim_effect_descriptor_missing")
		return {"is_resolved": true, "did_resolve": false, "error_code": "", "result": existing_result.duplicate(true)}
	if not clock.is_completed(current_time_seconds):
		return _rejected("execution_not_completed")
	var descriptor_result: Dictionary = ClaimEffectDescriptorScript.validate_all(claim_effect_descriptors)
	if not bool(descriptor_result["is_valid"]):
		return _rejected(str(descriptor_result["error_code"]))
	return {
		"is_resolved": true,
		"did_resolve": true,
		"error_code": "",
		"result": {
			"task_id": clock.task_id,
			"resolved_at_seconds": current_time_seconds,
			"guaranteed_reward": PLACEHOLDER_REWARD,
			"extra_reward": PLACEHOLDER_REWARD,
			"claim_effect_descriptors": Array(descriptor_result["effect_descriptors"]).duplicate(true),
		},
	}

static func _rejected(error_code: String) -> Dictionary:
	return {"is_resolved": false, "did_resolve": false, "error_code": error_code, "result": {}}

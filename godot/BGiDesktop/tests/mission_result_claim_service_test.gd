extends SceneTree

const MissionCompletionResultLockScript = preload("res://scripts/mission_completion_result_lock.gd")
const MissionExecutionClockScript = preload("res://scripts/mission_execution_clock.gd")
const MissionResultClaimServiceScript = preload("res://scripts/mission_result_claim_service.gd")

var _failed: bool = false

func _init() -> void:
	var clock: RefCounted = MissionExecutionClockScript.new("starter_01", 100, 5)
	var pending_claim: Dictionary = MissionResultClaimServiceScript.claim("starter_01", clock, 104, {}, {})
	_expect(not bool(pending_claim["is_claimed"]), "unfinished task must not be claimable")
	_expect(str(pending_claim["error_code"]) == "execution_not_completed", "unfinished task must identify its state")

	var locked_resolution: Dictionary = MissionCompletionResultLockScript.resolve(clock, 105, {})
	var locked_result: Dictionary = locked_resolution["result"]
	var first_claim: Dictionary = MissionResultClaimServiceScript.claim("starter_01", clock, 120, locked_result, {})
	var first_result: Dictionary = first_claim["result"]
	_expect(bool(first_claim["is_claimed"]), "completed unclaimed task must be claimable")
	_expect(first_result == locked_result, "claim must return the fixed locked result snapshot")
	_expect(str(first_result["guaranteed_reward"]) == "[PLACEHOLDER]", "claim must preserve placeholder guaranteed reward")
	_expect(str(first_result["extra_reward"]) == "[PLACEHOLDER]", "claim must preserve placeholder extra reward")
	_expect(bool(first_claim["claimed_task_ids"].get("starter_01", false)), "successful claim must record task id")

	var repeat_claim: Dictionary = MissionResultClaimServiceScript.claim("starter_01", clock, 140, locked_result, first_claim["claimed_task_ids"])
	_expect(not bool(repeat_claim["is_claimed"]), "repeated task claim must be rejected")
	_expect(str(repeat_claim["error_code"]) == "task_result_already_claimed", "repeated claim must be idempotently identified")
	_expect(repeat_claim["claimed_task_ids"] == first_claim["claimed_task_ids"], "repeated claim must not mutate claim state")
	_expect(Dictionary(repeat_claim["result"]).is_empty(), "repeated claim must not return a new reward result")

	var mismatched_claim: Dictionary = MissionResultClaimServiceScript.claim("starter_02", clock, 140, locked_result, {})
	_expect(not bool(mismatched_claim["is_claimed"]), "task id mismatch must be rejected")
	_expect(str(mismatched_claim["error_code"]) == "task_id_mismatch", "task id mismatch must identify its state")

	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionResultClaimService test failed: %s" % message)

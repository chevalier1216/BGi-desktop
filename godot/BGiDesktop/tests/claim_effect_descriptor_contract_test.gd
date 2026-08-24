extends SceneTree

const ResultLockScript = preload("res://scripts/mission_completion_result_lock.gd")
const ClockScript = preload("res://scripts/mission_execution_clock.gd")
const ClaimReceiptScript = preload("res://scripts/claim_receipt.gd")
const CollectibleGrantLedgerScript = preload("res://scripts/collectible_grant_ledger.gd")

var _failed := false

func _init() -> void:
	var clock: RefCounted = ClockScript.new("fixture_task", 100, 5)
	var descriptors: Array = [
		{"effect_type": "territory_first_touch", "territory_id": "fixture_territory", "character_id": "fixture_character"},
		{"effect_type": "collectible_grant", "collectible_id": "fixture_collectible", "quantity": 3},
	]
	var resolved: Dictionary = ResultLockScript.resolve(clock, 105, {}, descriptors)
	_expect(bool(resolved["is_resolved"]), "completed result must accept fixed descriptors")
	_expect(Array(Dictionary(resolved["result"])["claim_effect_descriptors"]) == descriptors, "result must preserve exact fixed descriptors")
	var replay: Dictionary = ResultLockScript.resolve(clock, 200, Dictionary(resolved["result"]), [])
	_expect(bool(replay["is_resolved"]) and Dictionary(replay["result"]) == Dictionary(resolved["result"]), "reload must not derive effects from current input")
	var missing: Dictionary = ResultLockScript.resolve(clock, 200, {"task_id": "fixture_task"})
	_expect(not bool(missing["is_resolved"]) and str(missing["error_code"]) == "claim_effect_descriptor_missing", "legacy fixed result missing descriptors must be rejected")
	var receipt_result: Dictionary = ClaimReceiptScript.create("fixture:claim", "fixture:run", "fixture:result", 105, [], descriptors)
	_expect(bool(receipt_result["is_valid"]), "receipt must persist fixed descriptors")
	var ledger: RefCounted = CollectibleGrantLedgerScript.new()
	var first_grant: Dictionary = ledger.apply_receipt(Dictionary(receipt_result["receipt"]))
	var replay_grant: Dictionary = ledger.apply_receipt(Dictionary(receipt_result["receipt"]))
	_expect(bool(first_grant["did_apply"]), "fixed collectible grant applies once")
	_expect(bool(replay_grant["is_applied"]) and not bool(replay_grant["did_apply"]), "replay must not duplicate collectible grant")
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("ClaimEffectDescriptorContract test failed: %s" % message)

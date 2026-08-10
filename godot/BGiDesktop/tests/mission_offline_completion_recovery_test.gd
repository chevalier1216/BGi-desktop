extends SceneTree

const MissionCompletionResultLockScript = preload("res://scripts/mission_completion_result_lock.gd")
const MissionExecutionSnapshotScript = preload("res://scripts/mission_execution_snapshot.gd")
const SnapshotCollectionScript = preload("res://scripts/mission_execution_snapshot_collection.gd")
const SnapshotStoreScript = preload("res://scripts/mission_execution_snapshot_store.gd")
const MissionResultClaimServiceScript = preload("res://scripts/mission_result_claim_service.gd")
const TEST_FILE_PATH: String = "user://mission_offline_completion_recovery_test.json"

var _failed: bool = false

func _init() -> void:
	var before_close_collection: RefCounted = SnapshotCollectionScript.new()
	var snapshot: RefCounted = MissionExecutionSnapshotScript.new("starter_01", 100, 5)
	_expect(bool(before_close_collection.add_snapshot(snapshot)["is_added"]), "execution snapshot must exist before close")
	var store: RefCounted = SnapshotStoreScript.new(TEST_FILE_PATH)
	_expect(bool(store.save(before_close_collection)["is_saved"]), "execution snapshot must persist before close")

	var after_reopen_load: Dictionary = store.load()
	var after_reopen_collection: RefCounted = after_reopen_load["collection"]
	var restored_clock: RefCounted = after_reopen_collection.restore_clock("starter_01")
	_expect(bool(after_reopen_load["is_loaded"]), "reopened execution must load from user storage")
	_expect(restored_clock.get_remaining_seconds(104) == 1, "reopened unfinished execution must preserve remaining time")
	_expect(restored_clock.is_completed(105), "reopened execution must complete after elapsed time")

	var first_resolution: Dictionary = MissionCompletionResultLockScript.resolve(restored_clock, 105, {})
	var locked_result: Dictionary = first_resolution["result"]
	_expect(bool(first_resolution["is_resolved"]), "completed restored execution must lock its result")
	_expect(bool(first_resolution["did_resolve"]), "first restored completion must resolve once")
	var repeated_resolution: Dictionary = MissionCompletionResultLockScript.resolve(restored_clock, 300, locked_result)
	_expect(not bool(repeated_resolution["did_resolve"]), "later result read must not resolve again")
	_expect(repeated_resolution["result"] == locked_result, "later result read must keep the fixed snapshot")

	var first_claim: Dictionary = MissionResultClaimServiceScript.claim("starter_01", restored_clock, 300, locked_result, {})
	_expect(bool(first_claim["is_claimed"]), "completed restored task must claim once")
	_expect(first_claim["result"] == locked_result, "claim must return the locked restored result")
	var repeated_claim: Dictionary = MissionResultClaimServiceScript.claim("starter_01", restored_clock, 301, locked_result, first_claim["claimed_task_ids"])
	_expect(not bool(repeated_claim["is_claimed"]), "claimed restored task must reject repeat claim")
	_expect(str(repeated_claim["error_code"]) == "task_result_already_claimed", "repeat claim must remain idempotent")

	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionOfflineCompletionRecovery test failed: %s" % message)

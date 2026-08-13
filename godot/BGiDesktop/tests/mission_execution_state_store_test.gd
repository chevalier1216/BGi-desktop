extends SceneTree

const SnapshotScript = preload("res://scripts/mission_execution_snapshot.gd")
const SnapshotCollectionScript = preload("res://scripts/mission_execution_snapshot_collection.gd")
const StateStoreScript = preload("res://scripts/mission_execution_state_store.gd")
const ResultStateSnapshotScript = preload("res://scripts/mission_result_state_snapshot.gd")
const ResultLockScript = preload("res://scripts/mission_completion_result_lock.gd")
const TEST_FILE_PATH: String = "user://mission_execution_state_store_test.json"

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var store: RefCounted = StateStoreScript.new(TEST_FILE_PATH)
	var missing_result: Dictionary = store.load()
	_expect(bool(missing_result["is_loaded"]) and bool(missing_result["was_missing"]), "missing state file must load as empty")

	var collection: RefCounted = SnapshotCollectionScript.new()
	_expect(bool(collection.add_snapshot(SnapshotScript.new("starter_01", 100, 5))["is_added"]), "execution snapshot must be added")
	var pending_clock: RefCounted = collection.restore_clock("starter_01")
	var pending_resolution: Dictionary = ResultLockScript.resolve(pending_clock, 104, {})
	_expect(not bool(pending_resolution["is_resolved"]), "unfinished execution must not resolve before persistence")
	var empty_result_state: RefCounted = ResultStateSnapshotScript.new()
	_expect(bool(store.save(collection, empty_result_state)["is_saved"]), "unfinished execution state must save")
	var restored_pending: Dictionary = store.load()
	var restored_pending_clock: RefCounted = restored_pending["collection"].restore_clock("starter_01")
	_expect(restored_pending_clock.get_remaining_seconds(104) == 1, "reopened unfinished execution must retain its remaining duration")
	_expect(not bool(ResultLockScript.resolve(restored_pending_clock, 104, restored_pending["result_state"].get_locked_result("starter_01"))["is_resolved"]), "reopened unfinished execution must remain unresolved")

	var first_resolution: Dictionary = ResultLockScript.resolve(restored_pending_clock, 105, {})
	_expect(bool(first_resolution["is_resolved"]) and bool(first_resolution["did_resolve"]), "expired execution must resolve once")
	var locked_result: Dictionary = Dictionary(first_resolution["result"]).duplicate(true)
	var locked_result_state: RefCounted = ResultStateSnapshotScript.new({"starter_01": locked_result}, {"starter_01": true})
	_expect(bool(store.save(restored_pending["collection"], locked_result_state)["is_saved"]), "locked execution result must save with its snapshot")
	var restored_locked: Dictionary = store.load()
	var restored_locked_clock: RefCounted = restored_locked["collection"].restore_clock("starter_01")
	var repeated_resolution: Dictionary = ResultLockScript.resolve(restored_locked_clock, 999, restored_locked["result_state"].get_locked_result("starter_01"))
	_expect(bool(repeated_resolution["is_resolved"]) and not bool(repeated_resolution["did_resolve"]), "reopened locked result must not resolve again")
	_expect(int(repeated_resolution["result"]["resolved_at_seconds"]) == int(locked_result["resolved_at_seconds"]), "reopened locked result must retain its original resolution time")
	_expect(str(repeated_resolution["result"]["guaranteed_reward"]) == str(locked_result["guaranteed_reward"]), "reopened locked result must retain its guaranteed reward")
	_expect(str(repeated_resolution["result"]["extra_reward"]) == str(locked_result["extra_reward"]), "reopened locked result must retain its extra reward")
	_expect(restored_locked["result_state"].is_claimed("starter_01"), "claimed task ids must restore with the locked result")

	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionExecutionStateStore test failed: %s" % message)

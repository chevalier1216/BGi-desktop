extends SceneTree

const MissionRefreshStateStoreScript = preload("res://scripts/mission_refresh_state_store.gd")
const TEST_FILE_PATH: String = "user://mission_refresh_state_store_test.json"
const SIX_HOURS: int = 6 * 60 * 60

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var store: RefCounted = MissionRefreshStateStoreScript.new(TEST_FILE_PATH)
	var missing_result: Dictionary = store.load(0)
	var allowance: RefCounted = missing_result["allowance"]
	_expect(bool(missing_result["was_missing"]) and allowance.get_allowance() == 0, "missing refresh state must begin with no allowance before six hours")
	allowance.update(SIX_HOURS - 1)
	_expect(allowance.get_allowance() == 0, "refresh must remain unavailable before six hours")
	allowance.update(SIX_HOURS)
	_expect(allowance.get_allowance() == 1, "refresh must become available exactly at six hours")
	_expect(bool(store.save(allowance)["is_saved"]), "available refresh allowance must save")

	var reopened_result: Dictionary = store.load(0)
	var reopened_allowance: RefCounted = reopened_result["allowance"]
	_expect(bool(reopened_result["is_loaded"]) and reopened_allowance.get_allowance() == 1, "reopened state must retain the unused refresh allowance")
	reopened_allowance.update(SIX_HOURS * 3)
	_expect(reopened_allowance.get_allowance() == 1, "unused refresh allowance must not accumulate beyond one")
	_expect(reopened_allowance.consume(SIX_HOURS * 3), "one available refresh must be consumable")
	_expect(reopened_allowance.get_allowance() == 0, "consumed refresh must become unavailable")
	_expect(bool(store.save(reopened_allowance)["is_saved"]), "consumed refresh state must save")

	var consumed_reopen_result: Dictionary = store.load(0)
	var consumed_reopen_allowance: RefCounted = consumed_reopen_result["allowance"]
	consumed_reopen_allowance.update(SIX_HOURS * 4 - 1)
	_expect(consumed_reopen_allowance.get_allowance() == 0, "reopened consumed state must remain unavailable before the next six-hour boundary")
	consumed_reopen_allowance.update(SIX_HOURS * 4)
	_expect(consumed_reopen_allowance.get_allowance() == 1, "reopened consumed state must restore one refresh at the next six-hour boundary")

	var file: FileAccess = FileAccess.open(TEST_FILE_PATH, FileAccess.WRITE)
	file.store_string("{invalid")
	file.close()
	var invalid_result: Dictionary = store.load(0)
	_expect(not bool(invalid_result["is_loaded"]) and invalid_result["allowance"].get_allowance() == 0, "invalid refresh state must safely fall back without inventing allowance")

	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionRefreshStateStore test failed: %s" % message)

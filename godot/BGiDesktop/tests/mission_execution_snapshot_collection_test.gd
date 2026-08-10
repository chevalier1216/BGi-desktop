extends SceneTree

const MissionExecutionSnapshotScript = preload("res://scripts/mission_execution_snapshot.gd")
const MissionExecutionSnapshotCollectionScript = preload("res://scripts/mission_execution_snapshot_collection.gd")

var _failed: bool = false

func _init() -> void:
	var collection: RefCounted = MissionExecutionSnapshotCollectionScript.new()
	var first_snapshot: RefCounted = MissionExecutionSnapshotScript.new("starter_01", 100, 10)
	var second_snapshot: RefCounted = MissionExecutionSnapshotScript.new("starter_02", 200, 5)

	_expect(bool(collection.add_snapshot(first_snapshot)["is_added"]), "first snapshot must be added")
	_expect(bool(collection.add_snapshot(second_snapshot)["is_added"]), "second snapshot must be added")
	var duplicate_result: Dictionary = collection.add_snapshot(first_snapshot)
	_expect(not bool(duplicate_result["is_added"]), "duplicate task snapshot must be rejected")
	_expect(str(duplicate_result["error_code"]) == "task_snapshot_already_exists", "duplicate rejection must identify its reason")

	var first_clock: RefCounted = collection.restore_clock("starter_01")
	_expect(first_clock != null, "saved task must restore a clock")
	_expect(first_clock.get_remaining_seconds(106) == 4, "restored clock must preserve unfinished remaining time")
	_expect(not first_clock.is_completed(106), "restored unfinished clock must not complete early")
	var second_clock: RefCounted = collection.restore_clock("starter_02")
	_expect(second_clock.is_completed(205), "restored clock must complete at its saved duration")

	var exported_data: Dictionary = collection.to_data()
	exported_data["starter_01"]["duration_seconds"] = 999
	_expect(int(collection.get_snapshot_data("starter_01")["duration_seconds"]) == 10, "exported data must be isolated from collection state")
	var restored_collection: RefCounted = MissionExecutionSnapshotCollectionScript.from_data(collection.to_data())
	_expect(restored_collection.restore_clock("starter_01").get_remaining_seconds(106) == 4, "reconstructed collection must preserve remaining time")
	_expect(restored_collection.restore_clock("starter_02").is_completed(205), "reconstructed collection must preserve completed state")

	_expect(bool(collection.remove_snapshot("starter_01")["is_removed"]), "existing snapshot must be removable")
	_expect(collection.restore_clock("starter_01") == null, "removed snapshot must no longer restore a clock")
	var missing_removal: Dictionary = collection.remove_snapshot("starter_01")
	_expect(not bool(missing_removal["is_removed"]), "missing snapshot removal must be rejected")
	_expect(str(missing_removal["error_code"]) == "task_snapshot_not_found", "missing snapshot rejection must identify its reason")

	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionExecutionSnapshotCollection test failed: %s" % message)

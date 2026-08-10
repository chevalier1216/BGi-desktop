extends SceneTree

const MissionExecutionSnapshotScript = preload("res://scripts/mission_execution_snapshot.gd")
const MissionExecutionSnapshotCollectionScript = preload("res://scripts/mission_execution_snapshot_collection.gd")
const MissionExecutionSnapshotStoreScript = preload("res://scripts/mission_execution_snapshot_store.gd")
const TEST_FILE_PATH: String = "user://mission_execution_snapshot_store_test.json"

var _failed: bool = false

func _init() -> void:
	var store: RefCounted = MissionExecutionSnapshotStoreScript.new(TEST_FILE_PATH)
	var missing_load: Dictionary = store.load()
	_expect(bool(missing_load["is_loaded"]), "missing file must load an empty collection")
	_expect(bool(missing_load["was_missing"]), "missing file state must be explicit")
	_expect(missing_load["collection"].to_data().is_empty(), "missing file must return no snapshots")

	var collection: RefCounted = MissionExecutionSnapshotCollectionScript.new()
	var snapshot: RefCounted = MissionExecutionSnapshotScript.new("starter_01", 100, 10)
	_expect(bool(collection.add_snapshot(snapshot)["is_added"]), "snapshot must be prepared for persistence")
	var save_result: Dictionary = store.save(collection)
	_expect(bool(save_result["is_saved"]), "collection must save to isolated user storage")
	var loaded_result: Dictionary = store.load()
	var loaded_collection: RefCounted = loaded_result["collection"]
	_expect(bool(loaded_result["is_loaded"]), "saved collection must load")
	_expect(not bool(loaded_result["was_missing"]), "saved collection must not report missing")
	_expect(loaded_collection.restore_clock("starter_01").get_remaining_seconds(106) == 4, "loaded snapshot must restore its clock")

	var corrupt_file: FileAccess = FileAccess.open(TEST_FILE_PATH, FileAccess.WRITE)
	corrupt_file.store_string("{corrupt")
	corrupt_file.close()
	var corrupt_result: Dictionary = store.load()
	_expect(not bool(corrupt_result["is_loaded"]), "corrupt data must be rejected safely")
	_expect(str(corrupt_result["error_code"]) == "snapshot_store_data_invalid", "corrupt data must report its state")
	_expect(corrupt_result["collection"].to_data().is_empty(), "corrupt data must return an empty collection")

	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionExecutionSnapshotStore test failed: %s" % message)

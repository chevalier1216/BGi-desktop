class_name MissionExecutionSnapshotStore
extends RefCounted

const MissionExecutionSnapshotCollectionScript = preload("res://scripts/mission_execution_snapshot_collection.gd")
const DEFAULT_FILE_PATH: String = "user://mission_execution_snapshots.json"

var _file_path: String

func _init(file_path: String = DEFAULT_FILE_PATH) -> void:
	_file_path = file_path

## Writes the collection's serializable data to an isolated user storage path.
func save(collection: RefCounted) -> Dictionary:
	if not _file_path.begins_with("user://"):
		return _rejected("snapshot_store_path_invalid")
	var file: FileAccess = FileAccess.open(_file_path, FileAccess.WRITE)
	if file == null:
		return _rejected("snapshot_store_write_failed")
	file.store_string(JSON.stringify(collection.to_data()))
	file.close()
	return {"is_saved": true, "error_code": ""}

## Loads stored snapshots, returning an empty collection when no save file exists.
func load() -> Dictionary:
	if not _file_path.begins_with("user://"):
		return _rejected("snapshot_store_path_invalid")
	if not FileAccess.file_exists(_file_path):
		return _loaded_empty(true)
	var file: FileAccess = FileAccess.open(_file_path, FileAccess.READ)
	if file == null:
		return _rejected("snapshot_store_read_failed")
	var serialized_data: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(serialized_data) != OK:
		return _rejected("snapshot_store_data_invalid")
	if typeof(json.data) != TYPE_DICTIONARY:
		return _rejected("snapshot_store_data_invalid")
	var collection: RefCounted = MissionExecutionSnapshotCollectionScript.from_data(Dictionary(json.data))
	return {
		"is_loaded": true,
		"was_missing": false,
		"error_code": "",
		"collection": collection,
	}

func _loaded_empty(was_missing: bool) -> Dictionary:
	return {
		"is_loaded": true,
		"was_missing": was_missing,
		"error_code": "",
		"collection": MissionExecutionSnapshotCollectionScript.new(),
	}

func _rejected(error_code: String) -> Dictionary:
	return {
		"is_saved": false,
		"is_loaded": false,
		"was_missing": false,
		"error_code": error_code,
		"collection": MissionExecutionSnapshotCollectionScript.new(),
	}

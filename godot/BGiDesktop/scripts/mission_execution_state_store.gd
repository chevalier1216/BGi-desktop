class_name MissionExecutionStateStore
extends RefCounted

const SnapshotCollectionScript = preload("res://scripts/mission_execution_snapshot_collection.gd")
const ResultStateSnapshotScript = preload("res://scripts/mission_result_state_snapshot.gd")
const DEFAULT_FILE_PATH: String = "user://mission_execution_state.json"

var _file_path: String

func _init(file_path: String = DEFAULT_FILE_PATH) -> void:
	_file_path = file_path

## Saves each execution snapshot and its locked result state in one JSON envelope.
func save(snapshot_collection: RefCounted, result_state: RefCounted) -> Dictionary:
	if not _file_path.begins_with("user://"):
		return _rejected("execution_state_store_path_invalid")
	var executions: Dictionary = _to_execution_data(snapshot_collection)
	var payload: Dictionary = {
		"executions": executions,
		"result_state": result_state.to_data(),
	}
	var file: FileAccess = FileAccess.open(_file_path, FileAccess.WRITE)
	if file == null:
		return _rejected("execution_state_store_write_failed")
	file.store_string(JSON.stringify(payload))
	file.close()
	return {"is_saved": true, "error_code": ""}

## Restores execution clocks and their already-locked results without resolving again.
func load() -> Dictionary:
	if not _file_path.begins_with("user://"):
		return _rejected("execution_state_store_path_invalid")
	if not FileAccess.file_exists(_file_path):
		return _loaded_empty(true)
	var file: FileAccess = FileAccess.open(_file_path, FileAccess.READ)
	if file == null:
		return _rejected("execution_state_store_read_failed")
	var serialized_data: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(serialized_data) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return _rejected("execution_state_store_data_invalid")
	var payload: Dictionary = Dictionary(json.data)
	var executions_variant: Variant = payload.get("executions", {})
	var result_state_variant: Variant = payload.get("result_state", {})
	if typeof(executions_variant) != TYPE_DICTIONARY or typeof(result_state_variant) != TYPE_DICTIONARY:
		return _rejected("execution_state_store_data_invalid")
	var snapshots_result: Dictionary = _restore_snapshot_collection(Dictionary(executions_variant))
	if not bool(snapshots_result["is_valid"]):
		return _rejected("execution_state_store_data_invalid")
	var result_state_result: Dictionary = ResultStateSnapshotScript.from_data(Dictionary(result_state_variant))
	if not bool(result_state_result["is_valid"]) or not _has_valid_locked_results(result_state_result["snapshot"]):
		return _rejected("execution_state_store_data_invalid")
	return {
		"is_loaded": true,
		"was_missing": false,
		"error_code": "",
		"collection": snapshots_result["collection"],
		"result_state": result_state_result["snapshot"],
	}

func _to_execution_data(snapshot_collection: RefCounted) -> Dictionary:
	var executions: Dictionary = {}
	for task_id_variant: Variant in snapshot_collection.to_data():
		var task_id: String = str(task_id_variant)
		var snapshot: Dictionary = snapshot_collection.get_snapshot_data(task_id)
		executions[task_id] = {
			"task_id": task_id,
			"started_at_seconds": int(snapshot["started_at_seconds"]),
			"duration_seconds": int(snapshot["duration_seconds"]),
			"expires_at_seconds": int(snapshot["started_at_seconds"]) + int(snapshot["duration_seconds"]),
		}
	return executions

func _restore_snapshot_collection(executions: Dictionary) -> Dictionary:
	var collection_data: Dictionary = {}
	for task_id_variant: Variant in executions:
		var task_id: String = str(task_id_variant)
		var execution: Dictionary = Dictionary(executions[task_id])
		if task_id.is_empty() or str(execution.get("task_id", "")) != task_id:
			return {"is_valid": false, "collection": SnapshotCollectionScript.new()}
		if not execution.has("started_at_seconds") or not execution.has("duration_seconds") or not execution.has("expires_at_seconds"):
			return {"is_valid": false, "collection": SnapshotCollectionScript.new()}
		var started_at_seconds: int = int(execution["started_at_seconds"])
		var duration_seconds: int = int(execution["duration_seconds"])
		if duration_seconds < 0 or int(execution["expires_at_seconds"]) != started_at_seconds + duration_seconds:
			return {"is_valid": false, "collection": SnapshotCollectionScript.new()}
		collection_data[task_id] = {
			"task_id": task_id,
			"started_at_seconds": started_at_seconds,
			"duration_seconds": duration_seconds,
		}
	return {"is_valid": true, "collection": SnapshotCollectionScript.from_data(collection_data)}

func _has_valid_locked_results(result_state: RefCounted) -> bool:
	var result_data: Dictionary = result_state.to_data()
	for task_id_variant: Variant in result_data["locked_results_by_task_id"]:
		var task_id: String = str(task_id_variant)
		var result: Dictionary = Dictionary(result_data["locked_results_by_task_id"][task_id])
		if str(result.get("task_id", "")) != task_id or not result.has("resolved_at_seconds") or not result.has("guaranteed_reward") or not result.has("extra_reward"):
			return false
	return true

func _loaded_empty(was_missing: bool) -> Dictionary:
	return {
		"is_loaded": true,
		"was_missing": was_missing,
		"error_code": "",
		"collection": SnapshotCollectionScript.new(),
		"result_state": ResultStateSnapshotScript.new(),
	}

func _rejected(error_code: String) -> Dictionary:
	return {
		"is_saved": false,
		"is_loaded": false,
		"was_missing": false,
		"error_code": error_code,
		"collection": SnapshotCollectionScript.new(),
		"result_state": ResultStateSnapshotScript.new(),
	}

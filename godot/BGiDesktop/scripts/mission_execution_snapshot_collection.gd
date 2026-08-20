class_name MissionExecutionSnapshotCollection
extends RefCounted

const MissionExecutionSnapshotScript = preload("res://scripts/mission_execution_snapshot.gd")

var _snapshots_by_mission_run_id: Dictionary = {}

## Adds one serialized execution snapshot, rejecting empty or duplicate task IDs.
func add_snapshot(snapshot: RefCounted) -> Dictionary:
	var task_id: String = str(snapshot.task_id)
	var mission_run_id: String = str(snapshot.mission_run_id)
	var storage_key: String = mission_run_id if not mission_run_id.is_empty() else task_id
	if task_id.is_empty() or storage_key.is_empty():
		return _rejected("task_id_required")
	if _snapshots_by_mission_run_id.has(storage_key):
		return _rejected("task_snapshot_already_exists")
	_snapshots_by_mission_run_id[storage_key] = snapshot.to_data().duplicate(true)
	return {"is_added": true, "error_code": ""}

## Restores a fresh clock for the requested task, or returns null when absent.
func restore_clock(mission_run_id_or_task_id: String) -> Variant:
	var snapshot_data: Dictionary = get_snapshot_data(mission_run_id_or_task_id)
	if snapshot_data.is_empty():
		return null
	var snapshot: RefCounted = MissionExecutionSnapshotScript.from_data(snapshot_data)
	return snapshot.restore_clock()

## Returns an isolated serialized snapshot so callers cannot mutate collection state.
func get_snapshot_data(mission_run_id_or_task_id: String) -> Dictionary:
	if _snapshots_by_mission_run_id.has(mission_run_id_or_task_id):
		return Dictionary(_snapshots_by_mission_run_id[mission_run_id_or_task_id]).duplicate(true)
	var matched_snapshot: Dictionary = {}
	for snapshot_variant: Variant in _snapshots_by_mission_run_id.values():
		var snapshot_data: Dictionary = Dictionary(snapshot_variant)
		if str(snapshot_data.get("task_id", "")) != mission_run_id_or_task_id:
			continue
		if not matched_snapshot.is_empty():
			return {}
		matched_snapshot = snapshot_data
	return matched_snapshot.duplicate(true)

func remove_snapshot(mission_run_id_or_task_id: String) -> Dictionary:
	var storage_key: String = mission_run_id_or_task_id
	if not _snapshots_by_mission_run_id.has(storage_key):
		var matched_key: String = ""
		for key_variant: Variant in _snapshots_by_mission_run_id:
			var candidate_key: String = str(key_variant)
			if str(Dictionary(_snapshots_by_mission_run_id[candidate_key]).get("task_id", "")) != mission_run_id_or_task_id:
				continue
			if not matched_key.is_empty():
				return _rejected("task_snapshot_not_found")
			matched_key = candidate_key
		storage_key = matched_key
	if not _snapshots_by_mission_run_id.has(storage_key):
		return _rejected("task_snapshot_not_found")
	_snapshots_by_mission_run_id.erase(storage_key)
	return {"is_removed": true, "error_code": ""}

## Returns an isolated, serializable task ID to snapshot-data map.
func to_data() -> Dictionary:
	return _snapshots_by_mission_run_id.duplicate(true)

static func from_data(data: Dictionary) -> Variant:
	var collection_script: GDScript = load("res://scripts/mission_execution_snapshot_collection.gd")
	var collection: RefCounted = collection_script.new()
	for storage_key_variant: Variant in data:
		var storage_key: String = str(storage_key_variant)
		var snapshot_data: Dictionary = Dictionary(data[storage_key]).duplicate(true)
		var mission_run_id: String = str(snapshot_data.get("mission_run_id", ""))
		var expected_key: String = mission_run_id if not mission_run_id.is_empty() else str(snapshot_data.get("task_id", ""))
		if storage_key != expected_key:
			continue
		collection._snapshots_by_mission_run_id[storage_key] = snapshot_data
	return collection

func _rejected(error_code: String) -> Dictionary:
	return {"is_added": false, "is_removed": false, "error_code": error_code}

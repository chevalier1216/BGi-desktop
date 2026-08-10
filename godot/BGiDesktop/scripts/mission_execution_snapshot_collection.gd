class_name MissionExecutionSnapshotCollection
extends RefCounted

const MissionExecutionSnapshotScript = preload("res://scripts/mission_execution_snapshot.gd")

var _snapshots_by_task_id: Dictionary = {}

## Adds one serialized execution snapshot, rejecting empty or duplicate task IDs.
func add_snapshot(snapshot: RefCounted) -> Dictionary:
	var task_id: String = str(snapshot.task_id)
	if task_id.is_empty():
		return _rejected("task_id_required")
	if _snapshots_by_task_id.has(task_id):
		return _rejected("task_snapshot_already_exists")
	_snapshots_by_task_id[task_id] = snapshot.to_data().duplicate(true)
	return {"is_added": true, "error_code": ""}

## Restores a fresh clock for the requested task, or returns null when absent.
func restore_clock(task_id: String) -> Variant:
	var snapshot_data: Dictionary = get_snapshot_data(task_id)
	if snapshot_data.is_empty():
		return null
	var snapshot: RefCounted = MissionExecutionSnapshotScript.from_data(snapshot_data)
	return snapshot.restore_clock()

## Returns an isolated serialized snapshot so callers cannot mutate collection state.
func get_snapshot_data(task_id: String) -> Dictionary:
	if not _snapshots_by_task_id.has(task_id):
		return {}
	return Dictionary(_snapshots_by_task_id[task_id]).duplicate(true)

func remove_snapshot(task_id: String) -> Dictionary:
	if not _snapshots_by_task_id.has(task_id):
		return _rejected("task_snapshot_not_found")
	_snapshots_by_task_id.erase(task_id)
	return {"is_removed": true, "error_code": ""}

## Returns an isolated, serializable task ID to snapshot-data map.
func to_data() -> Dictionary:
	return _snapshots_by_task_id.duplicate(true)

static func from_data(data: Dictionary) -> Variant:
	var collection_script: GDScript = load("res://scripts/mission_execution_snapshot_collection.gd")
	var collection: RefCounted = collection_script.new()
	for task_id_variant: Variant in data:
		var task_id: String = str(task_id_variant)
		var snapshot_data: Dictionary = Dictionary(data[task_id]).duplicate(true)
		if task_id != str(snapshot_data.get("task_id", "")):
			continue
		collection._snapshots_by_task_id[task_id] = snapshot_data
	return collection

func _rejected(error_code: String) -> Dictionary:
	return {"is_added": false, "is_removed": false, "error_code": error_code}

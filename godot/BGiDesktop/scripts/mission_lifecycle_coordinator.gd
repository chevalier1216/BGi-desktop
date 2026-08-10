class_name MissionLifecycleCoordinator
extends RefCounted

const MissionExecutionSnapshotScript = preload("res://scripts/mission_execution_snapshot.gd")
const MissionCompletionResultLockScript = preload("res://scripts/mission_completion_result_lock.gd")
const MissionResultClaimServiceScript = preload("res://scripts/mission_result_claim_service.gd")

var _assignment_coordinator: RefCounted
var _expired_release_service: RefCounted
var _snapshot_collection: RefCounted
var _locked_results_by_task_id: Dictionary = {}
var _claimed_task_ids: Dictionary = {}

func _init(assignment_coordinator: RefCounted, expired_release_service: RefCounted, snapshot_collection: RefCounted) -> void:
	_assignment_coordinator = assignment_coordinator
	_expired_release_service = expired_release_service
	_snapshot_collection = snapshot_collection

## Accepts an assignment and atomically adds its execution snapshot.
func accept_execution(task_id: String, crew_ids: Array[String], started_at_seconds: int, duration_seconds: int) -> Dictionary:
	var assignment_result: Dictionary = _assignment_coordinator.accept_assignment(task_id, crew_ids)
	if not bool(assignment_result["is_accepted"]):
		return _rejected("is_accepted", str(assignment_result["error_code"]))
	var snapshot: RefCounted = MissionExecutionSnapshotScript.new(task_id, started_at_seconds, duration_seconds)
	var snapshot_result: Dictionary = _snapshot_collection.add_snapshot(snapshot)
	if not bool(snapshot_result["is_added"]):
		_assignment_coordinator.release_assignment(task_id)
		return _rejected("is_accepted", str(snapshot_result["error_code"]))
	return {"is_accepted": true, "error_code": ""}

## Locks the completed result once without releasing the assigned crew.
func resolve_completed_result(task_id: String, current_time_seconds: int) -> Dictionary:
	var clock: Variant = _snapshot_collection.restore_clock(task_id)
	if clock == null:
		return _rejected("is_resolved", "task_execution_not_found")
	var existing_result: Dictionary = Dictionary(_locked_results_by_task_id.get(task_id, {}))
	var resolution: Dictionary = MissionCompletionResultLockScript.resolve(clock, current_time_seconds, existing_result)
	if not bool(resolution["is_resolved"]):
		return _rejected("is_resolved", str(resolution["error_code"]))
	var result_snapshot: Dictionary = Dictionary(resolution["result"]).duplicate(true)
	_locked_results_by_task_id[task_id] = result_snapshot
	return {
		"is_resolved": true,
		"did_resolve": bool(resolution["did_resolve"]),
		"error_code": "",
		"result": result_snapshot.duplicate(true),
	}

## Claims a fixed completed result once, then releases the completed assignment.
func claim_completed_result(task_id: String, current_time_seconds: int) -> Dictionary:
	if _claimed_task_ids.has(task_id):
		return _rejected("is_claimed", "task_result_already_claimed")
	var clock: Variant = _snapshot_collection.restore_clock(task_id)
	if clock == null:
		return _rejected("is_claimed", "task_execution_not_found")
	var resolution: Dictionary = resolve_completed_result(task_id, current_time_seconds)
	if not bool(resolution["is_resolved"]):
		return _rejected("is_claimed", str(resolution["error_code"]))
	var claim_result: Dictionary = MissionResultClaimServiceScript.claim(task_id, clock, current_time_seconds, resolution["result"], _claimed_task_ids)
	if not bool(claim_result["is_claimed"]):
		return _rejected("is_claimed", str(claim_result["error_code"]))
	var release_result: Dictionary = _expired_release_service.release_if_expired(task_id, clock, current_time_seconds)
	if not bool(release_result["is_released"]):
		return _rejected("is_claimed", str(release_result["error_code"]))
	_claimed_task_ids = Dictionary(claim_result["claimed_task_ids"]).duplicate(true)
	_snapshot_collection.remove_snapshot(task_id)
	return {
		"is_claimed": true,
		"error_code": "",
		"result": Dictionary(claim_result["result"]).duplicate(true),
	}

func _rejected(result_key: String, error_code: String) -> Dictionary:
	return {result_key: false, "error_code": error_code, "result": {}}

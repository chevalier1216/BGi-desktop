class_name MissionLifecycleCoordinator
extends RefCounted

const MissionExecutionSnapshotScript = preload("res://scripts/mission_execution_snapshot.gd")
const MissionCompletionResultLockScript = preload("res://scripts/mission_completion_result_lock.gd")
const MissionResultClaimServiceScript = preload("res://scripts/mission_result_claim_service.gd")
const ClaimReceiptScript = preload("res://scripts/claim_receipt.gd")
const ClaimReceiptStoreScript = preload("res://scripts/claim_receipt_store.gd")
const MissionRunRecordScript = preload("res://scripts/mission_run_record.gd")

var _assignment_coordinator: RefCounted
var _expired_release_service: RefCounted
var _snapshot_collection: RefCounted
var _locked_results_by_task_id: Dictionary = {}
var _claimed_task_ids: Dictionary = {}
var _claim_receipt_store: RefCounted
var _mission_runs_by_id: Dictionary = {}
var _active_run_id_by_task_id: Dictionary = {}

func _init(assignment_coordinator: RefCounted, expired_release_service: RefCounted, snapshot_collection: RefCounted, claim_receipt_store: RefCounted = null, persisted_runs: Dictionary = {}) -> void:
	_assignment_coordinator = assignment_coordinator
	_expired_release_service = expired_release_service
	_snapshot_collection = snapshot_collection
	_claim_receipt_store = claim_receipt_store if claim_receipt_store != null else ClaimReceiptStoreScript.new()
	_restore_persisted_runs(persisted_runs)

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
	var mission_run_id: String = "%s:%d" % [task_id, started_at_seconds]
	var run_result: Dictionary = MissionRunRecordScript.create(mission_run_id, task_id, crew_ids, started_at_seconds, started_at_seconds + duration_seconds)
	if not bool(run_result["is_valid"]) or _mission_runs_by_id.has(mission_run_id):
		_snapshot_collection.remove_snapshot(task_id)
		_assignment_coordinator.release_assignment(task_id)
		return _rejected("is_accepted", "mission_run_invalid")
	_mission_runs_by_id[mission_run_id] = Dictionary(run_result["record"]).duplicate(true)
	_active_run_id_by_task_id[task_id] = mission_run_id
	return {"is_accepted": true, "error_code": "", "mission_run_id": mission_run_id}

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
	var mission_run_id: String = str(_active_run_id_by_task_id.get(task_id, ""))
	if not mission_run_id.is_empty():
		result_snapshot["mission_run_id"] = mission_run_id
		result_snapshot["result_id"] = "%s:result" % mission_run_id
		var existing_run: Dictionary = Dictionary(_mission_runs_by_id[mission_run_id]).duplicate(true)
		existing_run["run_state"] = MissionRunRecordScript.COMPLETED_PENDING_CLAIM
		existing_run["result_snapshot"] = result_snapshot.duplicate(true)
		_mission_runs_by_id[mission_run_id] = existing_run
	_locked_results_by_task_id[task_id] = result_snapshot
	var completion_result: Dictionary = _expired_release_service.mark_completed_if_expired(task_id, clock, current_time_seconds)
	if not bool(completion_result["is_completed"]):
		return _rejected("is_resolved", str(completion_result["error_code"]))
	return {
		"is_resolved": true,
		"did_resolve": bool(resolution["did_resolve"]),
		"error_code": "",
		"result": result_snapshot.duplicate(true),
	}

## Claims a fixed completed result once, then releases the completed assignment.
func claim_completed_result(task_id: String, current_time_seconds: int) -> Dictionary:
	var stored_receipt: Dictionary = _claim_receipt_store.get_receipt(task_id)
	if not str(stored_receipt["error_code"]).is_empty():
		return _rejected("is_claimed", str(stored_receipt["error_code"]))
	if bool(stored_receipt["is_found"]):
		return {
			"is_claimed": true,
			"did_claim": false,
			"error_code": "",
			"result": {},
			"receipt": Dictionary(stored_receipt["receipt"]).duplicate(true),
		}
	if _claimed_task_ids.has(task_id):
		return _rejected("is_claimed", "claim_receipt_missing")
	var clock: Variant = _snapshot_collection.restore_clock(task_id)
	if clock == null:
		return _rejected("is_claimed", "task_execution_not_found")
	var resolution: Dictionary = resolve_completed_result(task_id, current_time_seconds)
	if not bool(resolution["is_resolved"]):
		return _rejected("is_claimed", str(resolution["error_code"]))
	var claim_result: Dictionary = MissionResultClaimServiceScript.claim(task_id, clock, current_time_seconds, resolution["result"], _claimed_task_ids)
	if not bool(claim_result["is_claimed"]):
		return _rejected("is_claimed", str(claim_result["error_code"]))
	var mission_run_id: String = "%s:%d" % [task_id, int(clock.started_at_seconds)]
	var result_id: String = "%s:%d" % [mission_run_id, int(Dictionary(claim_result["result"])["resolved_at_seconds"])]
	var receipt_result: Dictionary = ClaimReceiptScript.create(
		"%s:claim" % mission_run_id,
		mission_run_id,
		result_id,
		current_time_seconds
	)
	if not bool(receipt_result["is_valid"]):
		return _rejected("is_claimed", str(receipt_result["error_code"]))
	var save_receipt_result: Dictionary = _claim_receipt_store.save_receipt(task_id, Dictionary(receipt_result["receipt"]))
	if not bool(save_receipt_result["is_saved"]):
		return _rejected("is_claimed", str(save_receipt_result["error_code"]))
	var release_result: Dictionary = _assignment_coordinator.release_assignment(task_id)
	if not bool(release_result["is_released"]):
		return _rejected("is_claimed", str(release_result["error_code"]))
	_claimed_task_ids = Dictionary(claim_result["claimed_task_ids"]).duplicate(true)
	if _mission_runs_by_id.has(mission_run_id):
		var claimed_run: Dictionary = Dictionary(_mission_runs_by_id[mission_run_id]).duplicate(true)
		claimed_run["run_state"] = MissionRunRecordScript.CLAIMED
		claimed_run["claim_receipt_id"] = str(Dictionary(save_receipt_result["receipt"])["claim_receipt_id"])
		_mission_runs_by_id[mission_run_id] = claimed_run
	_snapshot_collection.remove_snapshot(task_id)
	_active_run_id_by_task_id.erase(task_id)
	return {
		"is_claimed": true,
		"did_claim": true,
		"error_code": "",
		"result": Dictionary(claim_result["result"]).duplicate(true),
		"receipt": Dictionary(save_receipt_result["receipt"]).duplicate(true),
	}

func get_persisted_runs() -> Dictionary:
	return {
		"mission_runs_by_id": _mission_runs_by_id.duplicate(true),
		"active_run_id_by_task_id": _active_run_id_by_task_id.duplicate(true),
	}

func _restore_persisted_runs(persisted_runs: Dictionary) -> void:
	var runs_variant: Variant = persisted_runs.get("mission_runs_by_id", {})
	var active_variant: Variant = persisted_runs.get("active_run_id_by_task_id", {})
	if typeof(runs_variant) != TYPE_DICTIONARY or typeof(active_variant) != TYPE_DICTIONARY:
		return
	for run_id_variant: Variant in Dictionary(runs_variant):
		var run_id: String = str(run_id_variant)
		var parsed: Dictionary = MissionRunRecordScript.from_data(Dictionary(Dictionary(runs_variant)[run_id]))
		if not bool(parsed["is_valid"]) or str(Dictionary(parsed["record"])["mission_run_id"]) != run_id:
			return
		var record: Dictionary = Dictionary(parsed["record"]).duplicate(true)
		_mission_runs_by_id[run_id] = record
		var task_id: String = str(record["mission_template_id"])
		if str(record["run_state"]) in [MissionRunRecordScript.COMPLETED_PENDING_CLAIM, MissionRunRecordScript.CLAIMED]:
			_locked_results_by_task_id[task_id] = Dictionary(record["result_snapshot"]).duplicate(true)
		if str(record["run_state"]) == MissionRunRecordScript.CLAIMED:
			_claimed_task_ids[task_id] = true
	for task_id_variant: Variant in Dictionary(active_variant):
		var task_id: String = str(task_id_variant)
		var run_id: String = str(Dictionary(active_variant)[task_id])
		if task_id.is_empty() or not _mission_runs_by_id.has(run_id):
			return
		_active_run_id_by_task_id[task_id] = run_id

func _rejected(result_key: String, error_code: String) -> Dictionary:
	return {result_key: false, "did_claim": false, "error_code": error_code, "result": {}, "receipt": {}}

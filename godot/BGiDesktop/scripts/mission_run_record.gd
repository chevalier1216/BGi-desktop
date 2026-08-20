class_name MissionRunRecord
extends RefCounted

const ACTIVE: String = "active"
const COMPLETED_PENDING_CLAIM: String = "completed_pending_claim"
const CLAIMED: String = "claimed"

static func create(mission_run_id: String, mission_template_id: String, assigned_crew_ids: Array[String], started_at_seconds: int, due_at_seconds: int, run_state: String = ACTIVE, result_snapshot: Dictionary = {}, claim_receipt_id: String = "") -> Dictionary:
	if mission_run_id.is_empty() or mission_template_id.is_empty() or assigned_crew_ids.is_empty() or due_at_seconds < started_at_seconds:
		return _rejected()
	var seen_crew_ids: Dictionary = {}
	for crew_id: String in assigned_crew_ids:
		if crew_id.is_empty() or seen_crew_ids.has(crew_id):
			return _rejected()
		seen_crew_ids[crew_id] = true
	if run_state not in [ACTIVE, COMPLETED_PENDING_CLAIM, CLAIMED]:
		return _rejected()
	if run_state == ACTIVE and (not result_snapshot.is_empty() or not claim_receipt_id.is_empty()):
		return _rejected()
	if run_state == COMPLETED_PENDING_CLAIM and not _is_valid_result(result_snapshot, mission_run_id):
		return _rejected()
	if run_state == CLAIMED and (not _is_valid_result(result_snapshot, mission_run_id) or claim_receipt_id.is_empty()):
		return _rejected()
	return {
		"is_valid": true,
		"record": {
			"mission_run_id": mission_run_id,
			"mission_template_id": mission_template_id,
			"assigned_crew_ids": assigned_crew_ids.duplicate(),
			"crew_reward_multiplier": "[PLACEHOLDER]",
			"started_at_seconds": started_at_seconds,
			"due_at_seconds": due_at_seconds,
			"run_state": run_state,
			"result_snapshot": result_snapshot.duplicate(true),
			"claim_receipt_id": claim_receipt_id,
		}
	}

static func from_data(data: Dictionary) -> Dictionary:
	var crew_ids: Array[String] = []
	for crew_id_variant: Variant in Array(data.get("assigned_crew_ids", [])):
		crew_ids.append(str(crew_id_variant))
	return create(
		str(data.get("mission_run_id", "")),
		str(data.get("mission_template_id", "")),
		crew_ids,
		int(data.get("started_at_seconds", -1)),
		int(data.get("due_at_seconds", -1)),
		str(data.get("run_state", "")),
		Dictionary(data.get("result_snapshot", {})),
		str(data.get("claim_receipt_id", ""))
	)

static func _is_valid_result(result_snapshot: Dictionary, mission_run_id: String) -> bool:
	return str(result_snapshot.get("mission_run_id", "")) == mission_run_id and not str(result_snapshot.get("result_id", "")).is_empty()

static func _rejected() -> Dictionary:
	return {"is_valid": false, "record": {}}

class_name MissionResultStateSnapshot
extends RefCounted

var _locked_results_by_mission_run_id: Dictionary = {}
var _claimed_mission_run_ids: Dictionary = {}

func _init(locked_results_by_mission_run_id: Dictionary = {}, claimed_mission_run_ids: Dictionary = {}) -> void:
	for key_variant: Variant in locked_results_by_mission_run_id:
		var supplied_key: String = str(key_variant)
		var result: Dictionary = Dictionary(locked_results_by_mission_run_id[supplied_key]).duplicate(true)
		var mission_run_id: String = str(result.get("mission_run_id", ""))
		var canonical_key: String = mission_run_id if not mission_run_id.is_empty() else supplied_key
		_locked_results_by_mission_run_id[canonical_key] = result
	for claimed_key_variant: Variant in claimed_mission_run_ids:
		var supplied_claim_key: String = str(claimed_key_variant)
		var canonical_claim_key: String = supplied_claim_key
		if not _locked_results_by_mission_run_id.has(canonical_claim_key):
			for mission_run_id_variant: Variant in _locked_results_by_mission_run_id:
				var candidate_run_id: String = str(mission_run_id_variant)
				var result: Dictionary = Dictionary(_locked_results_by_mission_run_id[candidate_run_id])
				if str(result.get("task_id", "")) == supplied_claim_key:
					canonical_claim_key = candidate_run_id
					break
		_claimed_mission_run_ids[canonical_claim_key] = true

## Returns isolated data for later persistence without recalculating any result.
func to_data() -> Dictionary:
	return {
		"locked_results_by_mission_run_id": _locked_results_by_mission_run_id.duplicate(true),
		"claimed_mission_run_ids": _claimed_mission_run_ids.duplicate(true),
		"locked_results_by_task_id": _legacy_results_by_task_id(),
		"claimed_task_ids": _legacy_claimed_task_ids(),
	}

func _legacy_results_by_task_id() -> Dictionary:
	var legacy_results: Dictionary = {}
	for result_variant: Variant in _locked_results_by_mission_run_id.values():
		var result: Dictionary = Dictionary(result_variant)
		var task_id: String = str(result.get("task_id", ""))
		if not task_id.is_empty():
			legacy_results[task_id] = result.duplicate(true)
	return legacy_results

func _legacy_claimed_task_ids() -> Dictionary:
	var legacy_claims: Dictionary = {}
	for mission_run_id_variant: Variant in _claimed_mission_run_ids:
		var mission_run_id: String = str(mission_run_id_variant)
		var result: Dictionary = Dictionary(_locked_results_by_mission_run_id.get(mission_run_id, {}))
		var task_id: String = str(result.get("task_id", ""))
		if not task_id.is_empty():
			legacy_claims[task_id] = true
	return legacy_claims

func get_locked_result(mission_run_id_or_task_id: String) -> Dictionary:
	if _locked_results_by_mission_run_id.has(mission_run_id_or_task_id):
		return Dictionary(_locked_results_by_mission_run_id[mission_run_id_or_task_id]).duplicate(true)
	var matched_result: Dictionary = {}
	for result_variant: Variant in _locked_results_by_mission_run_id.values():
		var result: Dictionary = Dictionary(result_variant)
		if str(result.get("task_id", "")) != mission_run_id_or_task_id:
			continue
		if not matched_result.is_empty():
			return {}
		matched_result = result
	return matched_result.duplicate(true)

func is_claimed(mission_run_id_or_task_id: String) -> bool:
	if _claimed_mission_run_ids.has(mission_run_id_or_task_id):
		return true
	for run_id_variant: Variant in _claimed_mission_run_ids:
		var run_id: String = str(run_id_variant)
		var result: Dictionary = Dictionary(_locked_results_by_mission_run_id.get(run_id, {}))
		if str(result.get("task_id", "")) == mission_run_id_or_task_id:
			return true
	return false

static func from_data(data: Dictionary) -> Dictionary:
	var snapshot_script: GDScript = load("res://scripts/mission_result_state_snapshot.gd")
	var locked_results_variant: Variant = data.get("locked_results_by_mission_run_id", data.get("locked_results_by_task_id", {}))
	var claimed_run_ids_variant: Variant = data.get("claimed_mission_run_ids", data.get("claimed_task_ids", {}))
	if typeof(locked_results_variant) != TYPE_DICTIONARY or typeof(claimed_run_ids_variant) != TYPE_DICTIONARY:
		return {"is_valid": false, "error_code": "mission_result_state_invalid", "snapshot": snapshot_script.new()}
	var locked_results: Dictionary = Dictionary(locked_results_variant)
	for key_variant: Variant in locked_results:
		var key: String = str(key_variant)
		var result: Dictionary = Dictionary(locked_results[key])
		var mission_run_id: String = str(result.get("mission_run_id", ""))
		var expected_key: String = mission_run_id if not mission_run_id.is_empty() else str(result.get("task_id", ""))
		if key.is_empty() or expected_key != key:
			return {"is_valid": false, "error_code": "mission_result_state_invalid", "snapshot": snapshot_script.new()}
	return {
		"is_valid": true,
		"error_code": "",
		"snapshot": snapshot_script.new(locked_results, Dictionary(claimed_run_ids_variant)),
	}

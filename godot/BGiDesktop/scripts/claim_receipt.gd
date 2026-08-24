class_name ClaimReceipt
extends RefCounted

const ClaimEffectDescriptorScript = preload("res://scripts/claim_effect_descriptor.gd")

## Builds the durable receipt for one already-locked mission result and its fixed effects.
static func create(claim_receipt_id: String, mission_run_id: String, result_id: String, claimed_at_seconds: int, applied_effect_ids: Array[String] = [], effect_descriptors: Array = []) -> Dictionary:
	if claim_receipt_id.is_empty() or mission_run_id.is_empty() or result_id.is_empty() or claimed_at_seconds < 0:
		return {"is_valid": false, "error_code": "claim_receipt_invalid", "receipt": {}}
	var seen_effect_ids: Dictionary = {}
	var saved_effect_ids: Array[String] = []
	for effect_id: String in applied_effect_ids:
		if effect_id.is_empty() or seen_effect_ids.has(effect_id):
			return {"is_valid": false, "error_code": "claim_receipt_invalid", "receipt": {}}
		seen_effect_ids[effect_id] = true
		saved_effect_ids.append(effect_id)
	var descriptor_result: Dictionary = ClaimEffectDescriptorScript.validate_all(effect_descriptors)
	if not bool(descriptor_result["is_valid"]):
		return {"is_valid": false, "error_code": str(descriptor_result["error_code"]), "receipt": {}}
	return {"is_valid": true, "error_code": "", "receipt": {
		"claim_receipt_id": claim_receipt_id,
		"mission_run_id": mission_run_id,
		"result_id": result_id,
		"claimed_at_seconds": claimed_at_seconds,
		"applied_effect_ids": saved_effect_ids,
		"effect_descriptors": Array(descriptor_result["effect_descriptors"]).duplicate(true),
	}}

static func from_data(data: Dictionary) -> Dictionary:
	var effect_ids_variant: Variant = data.get("applied_effect_ids", [])
	if typeof(effect_ids_variant) != TYPE_ARRAY:
		return {"is_valid": false, "error_code": "claim_receipt_invalid", "receipt": {}}
	var effect_ids: Array[String] = []
	for effect_id_variant: Variant in Array(effect_ids_variant):
		effect_ids.append(str(effect_id_variant))
	return create(str(data.get("claim_receipt_id", "")), str(data.get("mission_run_id", "")), str(data.get("result_id", "")), int(data.get("claimed_at_seconds", -1)), effect_ids, Array(data.get("effect_descriptors", [])))

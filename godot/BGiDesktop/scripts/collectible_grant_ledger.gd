class_name CollectibleGrantLedger
extends RefCounted

const ClaimEffectDescriptorScript = preload("res://scripts/claim_effect_descriptor.gd")

var _grants_by_claim_receipt_id: Dictionary = {}

## Records fixed collectible grants once per receipt. Display, placement, and use remain external.
func apply_receipt(receipt: Dictionary) -> Dictionary:
	var receipt_id: String = str(receipt.get("claim_receipt_id", ""))
	var descriptors_result: Dictionary = ClaimEffectDescriptorScript.validate_all(receipt.get("effect_descriptors", []))
	if receipt_id.is_empty() or not bool(descriptors_result["is_valid"]):
		return _rejected("collectible_grant_receipt_invalid")
	var collectible_descriptors: Array[Dictionary] = []
	for descriptor: Dictionary in Array(descriptors_result["effect_descriptors"]):
		if str(descriptor["effect_type"]) == "collectible_grant":
			collectible_descriptors.append(descriptor.duplicate(true))
	if _grants_by_claim_receipt_id.has(receipt_id):
		var existing: Array = Array(_grants_by_claim_receipt_id[receipt_id])
		if existing != collectible_descriptors:
			return _rejected("collectible_grant_already_exists")
		return {"is_applied": true, "did_apply": false, "error_code": "", "grants": existing.duplicate(true)}
	_grants_by_claim_receipt_id[receipt_id] = collectible_descriptors.duplicate(true)
	return {"is_applied": true, "did_apply": not collectible_descriptors.is_empty(), "error_code": "", "grants": collectible_descriptors.duplicate(true)}

func to_data() -> Dictionary:
	return _grants_by_claim_receipt_id.duplicate(true)

func load_data(data: Dictionary) -> Dictionary:
	var restored: Dictionary = {}
	for receipt_id_variant: Variant in data:
		var receipt_id: String = str(receipt_id_variant)
		var descriptors_result: Dictionary = ClaimEffectDescriptorScript.validate_all(Array(data[receipt_id_variant]))
		if receipt_id.is_empty() or not bool(descriptors_result["is_valid"]):
			return _rejected("collectible_grant_store_data_invalid")
		for descriptor: Dictionary in Array(descriptors_result["effect_descriptors"]):
			if str(descriptor["effect_type"]) != "collectible_grant":
				return _rejected("collectible_grant_store_data_invalid")
		restored[receipt_id] = Array(descriptors_result["effect_descriptors"]).duplicate(true)
	_grants_by_claim_receipt_id = restored
	return {"is_loaded": true, "error_code": ""}

func _rejected(error_code: String) -> Dictionary:
	return {"is_applied": false, "did_apply": false, "is_loaded": false, "error_code": error_code, "grants": []}

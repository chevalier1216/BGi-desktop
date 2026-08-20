class_name ClaimReceiptCollection
extends RefCounted

const ClaimReceiptScript = preload("res://scripts/claim_receipt.gd")

var _receipts_by_mission_run_id: Dictionary = {}

func _init(receipts_by_mission_run_id: Dictionary = {}) -> void:
	load_data(receipts_by_mission_run_id)

func save_receipt(receipt: Dictionary) -> Dictionary:
	var parsed: Dictionary = ClaimReceiptScript.from_data(receipt)
	if not bool(parsed["is_valid"]):
		return _rejected("claim_receipt_store_data_invalid")
	var validated: Dictionary = Dictionary(parsed["receipt"]).duplicate(true)
	var mission_run_id: String = str(validated["mission_run_id"])
	if _receipts_by_mission_run_id.has(mission_run_id):
		var existing: Dictionary = Dictionary(_receipts_by_mission_run_id[mission_run_id]).duplicate(true)
		if existing != validated:
			return _rejected("claim_receipt_already_exists")
		return {"is_saved": true, "did_save": false, "error_code": "", "receipt": existing}
	_receipts_by_mission_run_id[mission_run_id] = validated
	return {"is_saved": true, "did_save": true, "error_code": "", "receipt": validated.duplicate(true)}

func get_receipt(mission_run_id: String) -> Dictionary:
	if mission_run_id.is_empty():
		return {"is_found": false, "error_code": "claim_receipt_store_data_invalid", "receipt": {}}
	if not _receipts_by_mission_run_id.has(mission_run_id):
		return {"is_found": false, "error_code": "", "receipt": {}}
	return {"is_found": true, "error_code": "", "receipt": Dictionary(_receipts_by_mission_run_id[mission_run_id]).duplicate(true)}

func to_data() -> Dictionary:
	return _receipts_by_mission_run_id.duplicate(true)

func load_data(receipts_by_mission_run_id: Dictionary) -> Dictionary:
	var validated: Dictionary = {}
	for mission_run_id_variant: Variant in receipts_by_mission_run_id:
		var mission_run_id: String = str(mission_run_id_variant)
		var parsed: Dictionary = ClaimReceiptScript.from_data(Dictionary(receipts_by_mission_run_id[mission_run_id]))
		if mission_run_id.is_empty() or not bool(parsed["is_valid"]):
			return {"is_loaded": false, "error_code": "claim_receipt_store_data_invalid"}
		var receipt: Dictionary = Dictionary(parsed["receipt"])
		if str(receipt["mission_run_id"]) != mission_run_id:
			return {"is_loaded": false, "error_code": "claim_receipt_store_data_invalid"}
		validated[mission_run_id] = receipt.duplicate(true)
	_receipts_by_mission_run_id = validated
	return {"is_loaded": true, "error_code": ""}

func _rejected(error_code: String) -> Dictionary:
	return {"is_saved": false, "did_save": false, "error_code": error_code, "receipt": {}}

class_name ClaimReceiptStore
extends RefCounted

const ClaimReceiptScript = preload("res://scripts/claim_receipt.gd")
const DEFAULT_FILE_PATH: String = "user://mission_claim_receipts.json"

var _file_path: String

func _init(file_path: String = DEFAULT_FILE_PATH) -> void:
	_file_path = file_path

## Saves a receipt once per mission run; an identical replay returns that same persisted receipt.
func save_receipt(receipt: Dictionary) -> Dictionary:
	if not _file_path.begins_with("user://"):
		return _rejected("claim_receipt_store_path_invalid")
	var receipt_result: Dictionary = ClaimReceiptScript.from_data(receipt)
	if not bool(receipt_result["is_valid"]):
		return _rejected("claim_receipt_store_data_invalid")
	var validated_receipt: Dictionary = Dictionary(receipt_result["receipt"])
	var mission_run_id: String = str(validated_receipt["mission_run_id"])
	var loaded: Dictionary = self.load()
	if not bool(loaded["is_loaded"]):
		return _rejected(str(loaded["error_code"]))
	var receipts_by_mission_run_id: Dictionary = Dictionary(loaded["receipts_by_mission_run_id"]).duplicate(true)
	if receipts_by_mission_run_id.has(mission_run_id):
		var existing_result: Dictionary = ClaimReceiptScript.from_data(Dictionary(receipts_by_mission_run_id[mission_run_id]))
		if not bool(existing_result["is_valid"]):
			return _rejected("claim_receipt_store_data_invalid")
		if Dictionary(existing_result["receipt"]) != validated_receipt:
			return _rejected("claim_receipt_already_exists")
		return {"is_saved": true, "did_save": false, "error_code": "", "receipt": Dictionary(existing_result["receipt"]).duplicate(true)}
	receipts_by_mission_run_id[mission_run_id] = validated_receipt.duplicate(true)
	var file: FileAccess = FileAccess.open(_file_path, FileAccess.WRITE)
	if file == null:
		return _rejected("claim_receipt_store_write_failed")
	file.store_string(JSON.stringify({"receipts_by_mission_run_id": receipts_by_mission_run_id}))
	file.close()
	return {"is_saved": true, "did_save": true, "error_code": "", "receipt": validated_receipt.duplicate(true)}

func get_receipt(mission_run_id: String) -> Dictionary:
	if mission_run_id.is_empty():
		return {"is_found": false, "error_code": "claim_receipt_store_data_invalid", "receipt": {}}
	var loaded: Dictionary = self.load()
	if not bool(loaded["is_loaded"]):
		return {"is_found": false, "error_code": str(loaded["error_code"]), "receipt": {}}
	var receipts_by_mission_run_id: Dictionary = Dictionary(loaded["receipts_by_mission_run_id"])
	if not receipts_by_mission_run_id.has(mission_run_id):
		return {"is_found": false, "error_code": "", "receipt": {}}
	var receipt_result: Dictionary = ClaimReceiptScript.from_data(Dictionary(receipts_by_mission_run_id[mission_run_id]))
	if not bool(receipt_result["is_valid"]) or str(Dictionary(receipt_result["receipt"])["mission_run_id"]) != mission_run_id:
		return {"is_found": false, "error_code": "claim_receipt_store_data_invalid", "receipt": {}}
	return {"is_found": true, "error_code": "", "receipt": Dictionary(receipt_result["receipt"]).duplicate(true)}

## Removes one receipt when an enclosing player-save transaction fails to commit.
func remove_receipt(mission_run_id: String) -> Dictionary:
	if mission_run_id.is_empty():
		return {"is_removed": false, "did_remove": false, "error_code": "claim_receipt_store_data_invalid"}
	var loaded: Dictionary = self.load()
	if not bool(loaded["is_loaded"]):
		return {"is_removed": false, "did_remove": false, "error_code": str(loaded["error_code"])}
	var receipts_by_mission_run_id: Dictionary = Dictionary(loaded["receipts_by_mission_run_id"]).duplicate(true)
	if not receipts_by_mission_run_id.has(mission_run_id):
		return {"is_removed": true, "did_remove": false, "error_code": ""}
	receipts_by_mission_run_id.erase(mission_run_id)
	var file: FileAccess = FileAccess.open(_file_path, FileAccess.WRITE)
	if file == null:
		return {"is_removed": false, "did_remove": false, "error_code": "claim_receipt_store_write_failed"}
	file.store_string(JSON.stringify({"receipts_by_mission_run_id": receipts_by_mission_run_id}))
	file.close()
	return {"is_removed": true, "did_remove": true, "error_code": ""}

func load() -> Dictionary:
	if not _file_path.begins_with("user://"):
		return _rejected("claim_receipt_store_path_invalid")
	if not FileAccess.file_exists(_file_path):
		return {"is_loaded": true, "was_missing": true, "error_code": "", "receipts_by_mission_run_id": {}}
	var file: FileAccess = FileAccess.open(_file_path, FileAccess.READ)
	if file == null:
		return _rejected("claim_receipt_store_read_failed")
	var serialized_data: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(serialized_data) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return _rejected("claim_receipt_store_data_invalid")
	var payload: Dictionary = Dictionary(json.data)
	var receipts_variant: Variant = payload.get("receipts_by_mission_run_id", payload.get("receipts_by_task_id", {}))
	if typeof(receipts_variant) != TYPE_DICTIONARY:
		return _rejected("claim_receipt_store_data_invalid")
	var receipts_by_mission_run_id: Dictionary = {}
	for saved_key_variant: Variant in Dictionary(receipts_variant):
		var receipt_result: Dictionary = ClaimReceiptScript.from_data(Dictionary(Dictionary(receipts_variant)[saved_key_variant]))
		if not bool(receipt_result["is_valid"]):
			return _rejected("claim_receipt_store_data_invalid")
		var mission_run_id: String = str(Dictionary(receipt_result["receipt"])["mission_run_id"])
		if mission_run_id.is_empty() or receipts_by_mission_run_id.has(mission_run_id):
			return _rejected("claim_receipt_store_data_invalid")
		receipts_by_mission_run_id[mission_run_id] = Dictionary(receipt_result["receipt"]).duplicate(true)
	return {"is_loaded": true, "was_missing": false, "error_code": "", "receipts_by_mission_run_id": receipts_by_mission_run_id.duplicate(true)}

func _rejected(error_code: String) -> Dictionary:
	return {"is_saved": false, "is_loaded": false, "was_missing": false, "error_code": error_code, "receipt": {}, "receipts_by_mission_run_id": {}}

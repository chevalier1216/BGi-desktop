class_name TerritoryFirstTouchStateStore
extends RefCounted

const DEFAULT_FILE_PATH: String = "user://starter_mission_territory_state.json"

var _file_path: String

func _init(file_path: String = DEFAULT_FILE_PATH) -> void:
	_file_path = file_path

## Saves first-touch ownership, its persisted claim source, and the unlocked crew identity.
func save(touched_territory_ids: Dictionary, unlocked_crew_ids_by_territory: Dictionary, source_claim_receipt_ids_by_territory: Dictionary) -> Dictionary:
	if not _file_path.begins_with("user://"):
		return _rejected("territory_state_store_path_invalid")
	if not _is_valid_state(touched_territory_ids, unlocked_crew_ids_by_territory, source_claim_receipt_ids_by_territory):
		return _rejected("territory_state_store_data_invalid")
	var file: FileAccess = FileAccess.open(_file_path, FileAccess.WRITE)
	if file == null:
		return _rejected("territory_state_store_write_failed")
	file.store_string(JSON.stringify({
		"touched_territory_ids": touched_territory_ids,
		"unlocked_crew_ids_by_territory": unlocked_crew_ids_by_territory,
		"source_claim_receipt_ids_by_territory": source_claim_receipt_ids_by_territory,
	}))
	file.close()
	return {"is_saved": true, "error_code": ""}

## Loads only complete first-touch records; incomplete records are never inferred.
func load() -> Dictionary:
	if not _file_path.begins_with("user://"):
		return _rejected("territory_state_store_path_invalid")
	if not FileAccess.file_exists(_file_path):
		return _loaded_empty(true)
	var file: FileAccess = FileAccess.open(_file_path, FileAccess.READ)
	if file == null:
		return _rejected("territory_state_store_read_failed")
	var serialized_data: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(serialized_data) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return _rejected("territory_state_store_data_invalid")
	var payload: Dictionary = Dictionary(json.data)
	var touched_variant: Variant = payload.get("touched_territory_ids", {})
	var unlocked_variant: Variant = payload.get("unlocked_crew_ids_by_territory", {})
	var receipt_variant: Variant = payload.get("source_claim_receipt_ids_by_territory", {})
	if typeof(touched_variant) != TYPE_DICTIONARY or typeof(unlocked_variant) != TYPE_DICTIONARY or typeof(receipt_variant) != TYPE_DICTIONARY:
		return _rejected("territory_state_store_data_invalid")
	var touched_territory_ids: Dictionary = Dictionary(touched_variant)
	var unlocked_crew_ids_by_territory: Dictionary = Dictionary(unlocked_variant)
	var source_claim_receipt_ids_by_territory: Dictionary = Dictionary(receipt_variant)
	if not _is_valid_state(touched_territory_ids, unlocked_crew_ids_by_territory, source_claim_receipt_ids_by_territory):
		return _rejected("territory_state_store_data_invalid")
	return {
		"is_loaded": true,
		"was_missing": false,
		"error_code": "",
		"touched_territory_ids": touched_territory_ids.duplicate(true),
		"unlocked_crew_ids_by_territory": unlocked_crew_ids_by_territory.duplicate(true),
		"source_claim_receipt_ids_by_territory": source_claim_receipt_ids_by_territory.duplicate(true),
	}

func _is_valid_state(touched_territory_ids: Dictionary, unlocked_crew_ids_by_territory: Dictionary, source_claim_receipt_ids_by_territory: Dictionary) -> bool:
	if touched_territory_ids.size() != unlocked_crew_ids_by_territory.size() or touched_territory_ids.size() != source_claim_receipt_ids_by_territory.size():
		return false
	var seen_crew_ids: Dictionary = {}
	for territory_id_variant: Variant in touched_territory_ids:
		var territory_id: String = str(territory_id_variant)
		if territory_id.is_empty() or not bool(touched_territory_ids[territory_id]) or not unlocked_crew_ids_by_territory.has(territory_id) or not source_claim_receipt_ids_by_territory.has(territory_id):
			return false
		var crew_id: String = str(unlocked_crew_ids_by_territory[territory_id])
		if crew_id.is_empty() or seen_crew_ids.has(crew_id):
			return false
		if str(source_claim_receipt_ids_by_territory[territory_id]).is_empty():
			return false
		seen_crew_ids[crew_id] = true
	return true

func _loaded_empty(was_missing: bool) -> Dictionary:
	return {
		"is_loaded": true,
		"was_missing": was_missing,
		"error_code": "",
		"touched_territory_ids": {},
		"unlocked_crew_ids_by_territory": {},
		"source_claim_receipt_ids_by_territory": {},
	}

func _rejected(error_code: String) -> Dictionary:
	return {
		"is_saved": false,
		"is_loaded": false,
		"was_missing": false,
		"error_code": error_code,
		"touched_territory_ids": {},
		"unlocked_crew_ids_by_territory": {},
		"source_claim_receipt_ids_by_territory": {},
	}

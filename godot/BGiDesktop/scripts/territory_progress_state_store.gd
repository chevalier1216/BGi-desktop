class_name TerritoryProgressStateStore
extends RefCounted

const TerritoryProgressModelScript = preload("res://scripts/territory_progress_model.gd")
const DEFAULT_FILE_PATH: String = "user://starter_mission_territory_progress_state.json"

var _file_path: String

func _init(file_path: String = DEFAULT_FILE_PATH) -> void:
	_file_path = file_path

## Saves the display state without assigning territory progression values.
func save(territory_data: Dictionary) -> Dictionary:
	if not _file_path.begins_with("user://"):
		return _rejected(str(territory_data.get("territory_id", "")), "territory_progress_store_path_invalid")
	if not _is_valid_display_state(territory_data):
		return _rejected(str(territory_data.get("territory_id", "")), "territory_progress_store_data_invalid")
	var file: FileAccess = FileAccess.open(_file_path, FileAccess.WRITE)
	if file == null:
		return _rejected(str(territory_data["territory_id"]), "territory_progress_store_write_failed")
	file.store_string(JSON.stringify({"territory_data": territory_data}))
	file.close()
	return {"is_saved": true, "error_code": ""}

## Loads display data for one territory, falling back to an empty placeholder state on invalid data.
func load(territory_id: String) -> Dictionary:
	var fallback: Dictionary = TerritoryProgressModelScript.create(territory_id)
	if not bool(fallback["is_valid"]):
		return _rejected(territory_id, "territory_id_required")
	if not _file_path.begins_with("user://"):
		return _rejected(territory_id, "territory_progress_store_path_invalid")
	if not FileAccess.file_exists(_file_path):
		return _fallback(fallback, true, "")
	var file: FileAccess = FileAccess.open(_file_path, FileAccess.READ)
	if file == null:
		return _fallback(fallback, false, "territory_progress_store_read_failed")
	var serialized_data: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(serialized_data) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return _fallback(fallback, false, "territory_progress_store_data_invalid")
	var territory_data_variant: Variant = Dictionary(json.data).get("territory_data", {})
	if typeof(territory_data_variant) != TYPE_DICTIONARY:
		return _fallback(fallback, false, "territory_progress_store_data_invalid")
	var territory_data: Dictionary = Dictionary(territory_data_variant)
	if str(territory_data.get("territory_id", "")) != territory_id or not _is_valid_display_state(territory_data):
		return _fallback(fallback, false, "territory_progress_store_data_invalid")
	return {
		"is_loaded": true,
		"was_missing": false,
		"error_code": "",
		"territory_data": territory_data.duplicate(true),
	}

func _is_valid_display_state(territory_data: Dictionary) -> bool:
	if not bool(territory_data.get("is_valid", false)) or str(territory_data.get("territory_id", "")).is_empty() or not TerritoryProgressModelScript.has_required_growth_fields(territory_data):
		return false
	return typeof(territory_data["territory_progress"]) == TYPE_STRING \
		and typeof(territory_data["exploration_collection_count"]) == TYPE_STRING \
		and typeof(territory_data["environment_decoration_owned_count"]) == TYPE_STRING

func _fallback(territory_data: Dictionary, was_missing: bool, error_code: String) -> Dictionary:
	return {
		"is_loaded": error_code.is_empty(),
		"was_missing": was_missing,
		"error_code": error_code,
		"territory_data": territory_data.duplicate(true),
	}

func _rejected(territory_id: String, error_code: String) -> Dictionary:
	return {
		"is_saved": false,
		"is_loaded": false,
		"was_missing": false,
		"error_code": error_code,
		"territory_data": TerritoryProgressModelScript.create(territory_id),
	}

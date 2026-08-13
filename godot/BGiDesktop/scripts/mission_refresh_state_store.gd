class_name MissionRefreshStateStore
extends RefCounted

const MissionRefreshAllowanceScript = preload("res://scripts/mission_refresh_allowance.gd")
const DEFAULT_FILE_PATH: String = "user://starter_mission_refresh_state.json"

var _file_path: String

func _init(file_path: String = DEFAULT_FILE_PATH) -> void:
	_file_path = file_path

func save(allowance: RefCounted) -> Dictionary:
	if not _file_path.begins_with("user://"):
		return _rejected("mission_refresh_store_path_invalid", 0)
	var data: Dictionary = allowance.to_data()
	if not bool(MissionRefreshAllowanceScript.from_data(data)["is_valid"]):
		return _rejected("mission_refresh_store_data_invalid", 0)
	var file: FileAccess = FileAccess.open(_file_path, FileAccess.WRITE)
	if file == null:
		return _rejected("mission_refresh_store_write_failed", 0)
	file.store_string(JSON.stringify(data))
	file.close()
	return {"is_saved": true, "error_code": ""}

func load(initial_last_refill_check_seconds: int) -> Dictionary:
	if not _file_path.begins_with("user://"):
		return _rejected("mission_refresh_store_path_invalid", initial_last_refill_check_seconds)
	if not FileAccess.file_exists(_file_path):
		return _loaded_empty(initial_last_refill_check_seconds, true)
	var file: FileAccess = FileAccess.open(_file_path, FileAccess.READ)
	if file == null:
		return _loaded_empty(initial_last_refill_check_seconds, false, "mission_refresh_store_read_failed")
	var serialized_data: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(serialized_data) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return _loaded_empty(initial_last_refill_check_seconds, false, "mission_refresh_store_data_invalid")
	var parsed_result: Dictionary = MissionRefreshAllowanceScript.from_data(Dictionary(json.data))
	if not bool(parsed_result["is_valid"]):
		return _loaded_empty(initial_last_refill_check_seconds, false, "mission_refresh_store_data_invalid")
	return {
		"is_loaded": true,
		"was_missing": false,
		"error_code": "",
		"allowance": parsed_result["allowance"],
	}

func _loaded_empty(initial_last_refill_check_seconds: int, was_missing: bool, error_code: String = "") -> Dictionary:
	return {
		"is_loaded": error_code.is_empty(),
		"was_missing": was_missing,
		"error_code": error_code,
		"allowance": MissionRefreshAllowanceScript.new(initial_last_refill_check_seconds),
	}

func _rejected(error_code: String, initial_last_refill_check_seconds: int) -> Dictionary:
	return {
		"is_saved": false,
		"is_loaded": false,
		"was_missing": false,
		"error_code": error_code,
		"allowance": MissionRefreshAllowanceScript.new(initial_last_refill_check_seconds),
	}

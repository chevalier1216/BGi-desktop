class_name PlayerSaveEnvelopeStore
extends RefCounted

const CONTRACT_VERSION: String = "full_loop_contract_v1"
const DEFAULT_FILE_PATH: String = "user://player_save_envelope.json"

var _file_path: String

func _init(file_path: String = DEFAULT_FILE_PATH) -> void:
	_file_path = file_path

## Persists the complete playable-loop state in one replacement write.
func save(envelope: Dictionary) -> Dictionary:
	if not _file_path.begins_with("user://"):
		return _rejected("player_save_envelope_path_invalid")
	if not _is_valid(envelope):
		return _rejected("player_save_envelope_data_invalid")
	var file: FileAccess = FileAccess.open(_file_path, FileAccess.WRITE)
	if file == null:
		return _rejected("player_save_envelope_write_failed")
	file.store_string(JSON.stringify(envelope))
	file.close()
	return {"is_saved": true, "error_code": ""}

func load() -> Dictionary:
	if not _file_path.begins_with("user://"):
		return _rejected("player_save_envelope_path_invalid")
	if not FileAccess.file_exists(_file_path):
		return {"is_loaded": true, "was_missing": true, "error_code": "", "envelope": {}}
	var file: FileAccess = FileAccess.open(_file_path, FileAccess.READ)
	if file == null:
		return _rejected("player_save_envelope_read_failed")
	var serialized: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(serialized) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return _rejected("save_data_corrupted")
	var envelope: Dictionary = Dictionary(json.data)
	var validation_error: String = _get_validation_error(envelope)
	if not validation_error.is_empty():
		return _rejected(validation_error)
	return {"is_loaded": true, "was_missing": false, "error_code": "", "envelope": envelope.duplicate(true)}

static func make_envelope(crew_by_id: Array, mission_board: Array, execution_state: Dictionary, claim_receipts_by_mission_run_id: Dictionary, refresh_state: Dictionary, territory_state_by_id: Dictionary, territory_touch_receipts_by_id: Dictionary, progression_summary: Dictionary = {}) -> Dictionary:
	return {
		"contract_version": CONTRACT_VERSION,
		"crew_by_id": crew_by_id.duplicate(true),
		"mission_board": mission_board.duplicate(true),
		"execution_state": execution_state.duplicate(true),
		"claim_receipts_by_mission_run_id": claim_receipts_by_mission_run_id.duplicate(true),
		"refresh_state": refresh_state.duplicate(true),
		"territory_state_by_id": territory_state_by_id.duplicate(true),
		"territory_touch_receipts_by_id": territory_touch_receipts_by_id.duplicate(true),
		"progression_summary": progression_summary.duplicate(true),
	}

static func _is_valid(envelope: Dictionary) -> bool:
	return _get_validation_error(envelope).is_empty()

static func _get_validation_error(envelope: Dictionary) -> String:
	if not envelope.has("contract_version"):
		return "save_required_field_missing"
	if str(envelope.get("contract_version", "")) != CONTRACT_VERSION:
		return "save_contract_unsupported"
	for key: String in ["crew_by_id", "mission_board"]:
		if not envelope.has(key):
			return "save_required_field_missing"
		if typeof(envelope.get(key, null)) != TYPE_ARRAY:
			return "save_data_corrupted"
	for key: String in ["execution_state", "claim_receipts_by_mission_run_id", "refresh_state", "territory_state_by_id", "territory_touch_receipts_by_id", "progression_summary"]:
		if not envelope.has(key):
			return "save_required_field_missing"
		if typeof(envelope.get(key, null)) != TYPE_DICTIONARY:
			return "save_data_corrupted"
	return ""

func _rejected(error_code: String) -> Dictionary:
	return {"is_saved": false, "is_loaded": false, "was_missing": false, "error_code": error_code, "envelope": {}}

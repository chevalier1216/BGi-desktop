class_name RecoveryDiagnosticStore
extends RefCounted

const DEFAULT_FILE_PATH: String = "user://recovery_diagnostic.json"

var _file_path: String

func _init(file_path: String = DEFAULT_FILE_PATH) -> void:
	_file_path = file_path

func save(source_save_path: String, recovery_reason: String, mission_run_id: String = "") -> Dictionary:
	if not _file_path.begins_with("user://") or source_save_path.is_empty() or recovery_reason.is_empty():
		return {"is_saved": false, "error_code": "recovery_diagnostic_invalid"}
	var file: FileAccess = FileAccess.open(_file_path, FileAccess.WRITE)
	if file == null:
		return {"is_saved": false, "error_code": "recovery_diagnostic_write_failed"}
	file.store_string(JSON.stringify({"source_save_path": source_save_path, "recovery_reason": recovery_reason, "mission_run_id": mission_run_id}))
	file.close()
	return {"is_saved": true, "error_code": ""}

func load() -> Dictionary:
	if not _file_path.begins_with("user://") or not FileAccess.file_exists(_file_path):
		return {"is_loaded": false, "error_code": "recovery_diagnostic_missing", "record": {}}
	var file: FileAccess = FileAccess.open(_file_path, FileAccess.READ)
	if file == null:
		return {"is_loaded": false, "error_code": "recovery_diagnostic_read_failed", "record": {}}
	var json := JSON.new()
	var text := file.get_as_text()
	file.close()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {"is_loaded": false, "error_code": "recovery_diagnostic_data_invalid", "record": {}}
	var record := Dictionary(json.data)
	if str(record.get("source_save_path", "")).is_empty() or str(record.get("recovery_reason", "")).is_empty():
		return {"is_loaded": false, "error_code": "recovery_diagnostic_data_invalid", "record": {}}
	return {"is_loaded": true, "error_code": "", "record": record.duplicate(true)}

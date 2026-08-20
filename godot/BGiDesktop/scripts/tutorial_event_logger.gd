class_name TutorialEventLogger
extends RefCounted

const SCHEMA_VERSION: String = "tutorial_events_v1"
const DEFAULT_FILE_PATH: String = "user://tutorial_anonymous_events.json"

var _file_path: String
var _anonymous_save_id: String = ""
var _session_id: String = ""
var _next_sequence: int = 1
var _events: Array = []

func _init(file_path: String = DEFAULT_FILE_PATH) -> void:
	_file_path = file_path
	_session_id = _make_identifier("session")
	_load_or_initialize()

func record(event_name: String, tutorial_step_id: String, timestamp_seconds: int, outcome: String = "", mission_id: String = "", details: Dictionary = {}) -> Dictionary:
	if not event_name.begins_with("tutorial_"):
		return {"is_recorded": false, "error_code": "tutorial_event_name_invalid"}
	var event: Dictionary = {
		"schema_version": SCHEMA_VERSION,
		"anonymous_save_id": _anonymous_save_id,
		"session_id": _session_id,
		"sequence": _next_sequence,
		"event_name": event_name,
		"tutorial_step_id": tutorial_step_id,
		"mission_id": mission_id,
		"timestamp_seconds": timestamp_seconds,
		"outcome": outcome,
		"details": details.duplicate(true),
	}
	_events.append(event)
	_next_sequence += 1
	if not _save():
		_events.pop_back()
		_next_sequence -= 1
		return {"is_recorded": false, "error_code": "tutorial_event_write_failed"}
	return {"is_recorded": true, "error_code": "", "event": event.duplicate(true)}

func get_events() -> Array:
	return _events.duplicate(true)

func _load_or_initialize() -> void:
	if not _file_path.begins_with("user://") or not FileAccess.file_exists(_file_path):
		_anonymous_save_id = _make_identifier("save")
		return
	var file: FileAccess = FileAccess.open(_file_path, FileAccess.READ)
	if file == null:
		_anonymous_save_id = _make_identifier("save")
		return
	var json: JSON = JSON.new()
	var source: String = file.get_as_text()
	file.close()
	if json.parse(source) != OK or typeof(json.data) != TYPE_DICTIONARY:
		_anonymous_save_id = _make_identifier("save")
		return
	var payload: Dictionary = Dictionary(json.data)
	_anonymous_save_id = str(payload.get("anonymous_save_id", _make_identifier("save")))
	_next_sequence = maxi(1, int(payload.get("next_sequence", 1)))
	if typeof(payload.get("events", [])) == TYPE_ARRAY:
		_events = Array(payload["events"]).duplicate(true)

func _save() -> bool:
	if not _file_path.begins_with("user://"):
		return false
	var file: FileAccess = FileAccess.open(_file_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"schema_version": SCHEMA_VERSION, "anonymous_save_id": _anonymous_save_id, "next_sequence": _next_sequence, "events": _events}))
	file.close()
	return true

func _make_identifier(prefix: String) -> String:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.randomize()
	return "%s_%d_%d" % [prefix, Time.get_ticks_usec(), random.randi()]

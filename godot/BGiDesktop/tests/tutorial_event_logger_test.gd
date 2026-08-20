extends SceneTree

const LoggerScript = preload("res://scripts/tutorial_event_logger.gd")
const TEST_PATH: String = "user://tutorial_event_logger_test.json"
var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var logger: RefCounted = LoggerScript.new(TEST_PATH)
	var first: Dictionary = logger.record("tutorial_started", "starter_01", 100, "loaded", "starter_01", {"crew_count": 5})
	_expect(bool(first["is_recorded"]), "anonymous tutorial event must persist")
	var event: Dictionary = Dictionary(first["event"])
	_expect(event.has("schema_version") and event.has("anonymous_save_id") and event.has("session_id") and event.has("sequence"), "event must include required anonymous common fields")
	_expect(not event.has("ip") and not event.has("account") and not event.has("location"), "event must not add prohibited personal fields")
	var restored: RefCounted = LoggerScript.new(TEST_PATH)
	_expect(restored.get_events().size() == 1, "events must remain local and survive a restart")
	_expect(not bool(restored.record("invalid_event", "starter_01", 101)["is_recorded"]), "non tutorial events must be rejected")
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("TutorialEventLogger test failed: %s" % message)

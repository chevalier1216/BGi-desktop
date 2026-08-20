extends SceneTree

const MissionRunRecordScript = preload("res://scripts/mission_run_record.gd")

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var active_result: Dictionary = MissionRunRecordScript.create("starter_01:100", "starter_01", ["crew_01", "crew_02"], 100, 105)
	_expect(bool(active_result["is_valid"]), "active run must accept stable ids, crew, and timestamps")
	var active_record: Dictionary = Dictionary(active_result["record"])
	_expect(str(active_record["run_state"]) == MissionRunRecordScript.ACTIVE, "new run must be active")
	_expect(int(active_record["due_at_seconds"]) == 105, "run must retain the frozen due time")
	var complete_result: Dictionary = MissionRunRecordScript.create("starter_01:100", "starter_01", ["crew_01", "crew_02"], 100, 105, MissionRunRecordScript.COMPLETED_PENDING_CLAIM, {"mission_run_id": "starter_01:100", "result_id": "starter_01:100:result"})
	_expect(bool(complete_result["is_valid"]), "completed run must retain a result identified by its run id")
	var restored_result: Dictionary = MissionRunRecordScript.from_data(Dictionary(complete_result["record"]))
	_expect(bool(restored_result["is_valid"]) and Dictionary(restored_result["record"]) == Dictionary(complete_result["record"]), "serialized run must restore without changing its identity or result")
	var invalid_result: Dictionary = MissionRunRecordScript.create("starter_01:100", "starter_01", ["crew_01"], 100, 105, MissionRunRecordScript.COMPLETED_PENDING_CLAIM, {})
	_expect(not bool(invalid_result["is_valid"]), "completed run must reject a missing fixed result")
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionRunRecord test failed: %s" % message)

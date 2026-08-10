extends SceneTree

const GameStateScript = preload("res://scripts/game_state.gd")
const MissionAssignmentStateScript = preload("res://scripts/mission_assignment_state.gd")
const CoordinatorScript = preload("res://scripts/persistent_mission_assignment_coordinator.gd")
const MissionAbortServiceScript = preload("res://scripts/mission_abort_service.gd")

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := GameStateScript.new()
	root.add_child(game_state)
	var assignment_state := MissionAssignmentStateScript.new()
	var coordinator := CoordinatorScript.new(game_state, assignment_state)
	var abort_service := MissionAbortServiceScript.new(coordinator, assignment_state)

	var before_invalid_abort: Array[Dictionary] = game_state.get_crew()
	_expect_result(abort_service.abort("task_missing"), false, "task_not_assigned")
	_expect(game_state.get_crew() == before_invalid_abort, "無效任務中止不得改變 GameState")

	_expect(coordinator.accept_assignment("task_01", ["crew_01", "crew_02"])["is_accepted"], "測試前置派遣必須成功")
	_expect_result(abort_service.abort("task_01"), true, "")
	_expect(assignment_state.get_assigned_crew_ids("task_01").is_empty(), "中止後任務配置必須為空")
	for crew_member: Dictionary in game_state.get_crew():
		_expect(crew_member["status"] == GameStateScript.CrewStatus.AVAILABLE, "中止後 GameState 小弟必須全數可用")

	game_state.queue_free()
	quit(1 if _failed else 0)

func _expect_result(result: Dictionary, expected_aborted: bool, expected_error: String) -> void:
	_expect(result.get("is_aborted") == expected_aborted and result.get("error_code") == expected_error, "中止結果不符：%s" % result)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionAbortService 測試失敗：%s" % message)

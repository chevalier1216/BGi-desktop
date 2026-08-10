extends SceneTree

const GameStateScript = preload("res://scripts/game_state.gd")
const MissionAssignmentStateScript = preload("res://scripts/mission_assignment_state.gd")
const CoordinatorScript = preload("res://scripts/persistent_mission_assignment_coordinator.gd")
const ClockScript = preload("res://scripts/mission_execution_clock.gd")
const ValidityQueryScript = preload("res://scripts/mission_execution_validity_query.gd")

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := GameStateScript.new()
	root.add_child(game_state)
	var assignment_state := MissionAssignmentStateScript.new()
	var coordinator := CoordinatorScript.new(game_state, assignment_state)
	var clock := ClockScript.new("task_01", 100, 30)
	var validity_query := ValidityQueryScript.new()

	_expect(coordinator.accept_assignment("task_01", ["crew_01"])["is_accepted"], "成功派遣後必須建立任務配置")
	var active_status: Dictionary = validity_query.get_status(assignment_state, "task_01", clock, 110)
	_expect(active_status["is_valid_execution"], "已配置任務的時計必須有效")
	_expect(active_status["remaining_seconds"] == 20, "時計查詢必須回傳正確剩餘秒數")
	_expect(not active_status["is_completed"], "未到期時計不得完成")

	_expect(coordinator.release_assignment("task_01")["is_released"], "解除派遣必須成功")
	var released_status: Dictionary = validity_query.get_status(assignment_state, "task_01", clock, 110)
	_expect(not released_status["is_valid_execution"], "解除派遣後時計不得再視為有效執行中任務")
	_expect(released_status["error_code"] == "task_not_assigned", "解除派遣後必須回報任務未配置")

	game_state.queue_free()
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionExecutionAssignment 整合測試失敗：%s" % message)

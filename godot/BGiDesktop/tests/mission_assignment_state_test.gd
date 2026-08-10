extends SceneTree

const MissionAssignmentStateScript = preload("res://scripts/mission_assignment_state.gd")

var _failed := false

func _init() -> void:
	var assignment_state := MissionAssignmentStateScript.new()

	_expect_result(assignment_state.assign("task_01", ["crew_01", "crew_02"]), true, "")
	_expect(assignment_state.get_assigned_crew_ids("task_01") == ["crew_01", "crew_02"], "任務必須可查詢已配置小弟")
	_expect_result(assignment_state.assign("task_01", ["crew_03"]), false, "task_already_assigned")
	_expect_result(assignment_state.assign("task_02", ["crew_02"]), false, "crew_already_assigned")
	_expect_result(assignment_state.assign("task_03", ["crew_03", "crew_03"]), false, "crew_already_assigned")

	_expect(assignment_state.release("task_01") == ["crew_01", "crew_02"], "釋放必須回傳原配置小弟")
	_expect(assignment_state.get_assigned_crew_ids("task_01").is_empty(), "釋放後任務配置必須清空")
	_expect_result(assignment_state.assign("task_02", ["crew_02"]), true, "")

	quit(1 if _failed else 0)

func _expect_result(result: Dictionary, expected_assigned: bool, expected_error: String) -> void:
	_expect(result.get("is_assigned") == expected_assigned and result.get("error_code") == expected_error, "配置結果不符：%s" % result)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionAssignmentState 測試失敗：%s" % message)

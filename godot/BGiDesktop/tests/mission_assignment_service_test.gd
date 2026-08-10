extends SceneTree

const GameStateScript = preload("res://scripts/game_state.gd")
const MissionAssignmentStateScript = preload("res://scripts/mission_assignment_state.gd")
const MissionAssignmentServiceScript = preload("res://scripts/mission_assignment_service.gd")

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := GameStateScript.new()
	root.add_child(game_state)
	var crew: Array[Dictionary] = game_state.get_crew()
	var assignment_state := MissionAssignmentStateScript.new()
	var service := MissionAssignmentServiceScript.new(assignment_state)

	_expect_result(service.accept_assignment("task_01", crew, ["crew_01", "crew_02"]), true, "")
	_expect(_status_for(crew, "crew_01") == GameStateScript.CrewStatus.DISPATCHED, "接受配置後 crew_01 必須派遣中")
	_expect(_status_for(crew, "crew_02") == GameStateScript.CrewStatus.DISPATCHED, "接受配置後 crew_02 必須派遣中")

	var before_rejection: Array[Dictionary] = crew.duplicate(true)
	_expect_result(service.accept_assignment("task_02", crew, ["crew_01"]), false, "crew_not_available")
	_expect(crew == before_rejection, "規則拒絕後不得改變任一小弟狀態")

	_expect(service.release_assignment("task_01", crew) == ["crew_01", "crew_02"], "釋放必須回傳已配置小弟")
	_expect(_status_for(crew, "crew_01") == GameStateScript.CrewStatus.AVAILABLE, "釋放後 crew_01 必須可用")
	_expect(_status_for(crew, "crew_02") == GameStateScript.CrewStatus.AVAILABLE, "釋放後 crew_02 必須可用")
	_expect_result(service.accept_assignment("task_02", crew, ["crew_01"]), true, "")

	game_state.queue_free()
	quit(1 if _failed else 0)

func _status_for(crew: Array[Dictionary], crew_id: String) -> int:
	for crew_member: Dictionary in crew:
		if crew_member["id"] == crew_id:
			return int(crew_member["status"])
	return -1

func _expect_result(result: Dictionary, expected_accepted: bool, expected_error: String) -> void:
	_expect(result.get("is_accepted") == expected_accepted and result.get("error_code") == expected_error, "Service 結果不符：%s" % result)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionAssignmentService 測試失敗：%s" % message)

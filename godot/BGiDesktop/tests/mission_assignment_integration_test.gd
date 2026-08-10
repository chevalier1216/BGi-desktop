extends SceneTree

const StarterMissionCatalogScript = preload("res://scripts/starter_mission_catalog.gd")
const GameStateScript = preload("res://scripts/game_state.gd")
const MissionAssignmentStateScript = preload("res://scripts/mission_assignment_state.gd")
const MissionAssignmentServiceScript = preload("res://scripts/mission_assignment_service.gd")

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var catalog := StarterMissionCatalogScript.new()
	var game_state := GameStateScript.new()
	root.add_child(catalog)
	root.add_child(game_state)
	var mission := _first_unaccepted_mission(catalog.get_missions())
	_expect(not mission.is_empty(), "必須取得實際未接受的新手任務")

	var crew: Array[Dictionary] = game_state.get_crew()
	var assignment_state := MissionAssignmentStateScript.new()
	var assignment_service := MissionAssignmentServiceScript.new(assignment_state)
	var crew_ids: Array[String] = ["crew_01", "crew_02"]
	var result: Dictionary = assignment_service.accept_assignment(mission["id"], crew, crew_ids)

	_expect(result["is_accepted"], "端到端配置必須成功")
	_expect(assignment_state.get_assigned_crew_ids(mission["id"]) == crew_ids, "任務必須記錄已配置小弟")
	_expect(_status_for(crew, "crew_01") == GameStateScript.CrewStatus.DISPATCHED, "已配置小弟必須派遣中")
	_expect(_status_for(crew, "crew_02") == GameStateScript.CrewStatus.DISPATCHED, "已配置小弟必須派遣中")

	assignment_service.release_assignment(mission["id"], crew)
	_expect(assignment_state.get_assigned_crew_ids(mission["id"]).is_empty(), "釋放後任務配置必須為空")
	for crew_member: Dictionary in crew:
		_expect(crew_member["status"] == GameStateScript.CrewStatus.AVAILABLE, "釋放後全數小弟必須可用")

	catalog.queue_free()
	game_state.queue_free()
	quit(1 if _failed else 0)

func _first_unaccepted_mission(missions: Array[Dictionary]) -> Dictionary:
	for mission: Dictionary in missions:
		if not bool(mission["is_accepted"]):
			return mission
	return {}

func _status_for(crew: Array[Dictionary], crew_id: String) -> int:
	for crew_member: Dictionary in crew:
		if crew_member["id"] == crew_id:
			return int(crew_member["status"])
	return -1

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionAssignment 整合測試失敗：%s" % message)

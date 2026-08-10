extends SceneTree

const GameStateScript = preload("res://scripts/game_state.gd")

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := GameStateScript.new()
	root.add_child(game_state)

	_expect_result(game_state.set_crew_status("crew_01", GameStateScript.ASSIGNED_STATUS), true, "")
	_expect(_status_for(game_state.get_crew(), "crew_01") == GameStateScript.ASSIGNED_STATUS, "指定小弟必須切換為已配置")
	_expect_result(game_state.set_crew_status("crew_01", GameStateScript.CrewStatus.AVAILABLE), true, "")
	_expect(_status_for(game_state.get_crew(), "crew_01") == GameStateScript.CrewStatus.AVAILABLE, "指定小弟必須回復可用")

	var before_rejection: Array[Dictionary] = game_state.get_crew()
	_expect_result(game_state.set_crew_status("crew_99", GameStateScript.ASSIGNED_STATUS), false, "crew_not_found")
	_expect(game_state.get_crew() == before_rejection, "未知 id 拒絕後資料不得改變")
	_expect_result(game_state.set_crew_status("crew_01", GameStateScript.CrewStatus.COMPLETED), false, "unsupported_status")
	_expect(game_state.get_crew() == before_rejection, "不支援狀態拒絕後資料不得改變")

	var crew_copy: Array[Dictionary] = game_state.get_crew()
	crew_copy[0]["status"] = GameStateScript.ASSIGNED_STATUS
	_expect(_status_for(game_state.get_crew(), "crew_01") == GameStateScript.CrewStatus.AVAILABLE, "取得複本仍須與 GameState 隔離")

	game_state.queue_free()
	quit(1 if _failed else 0)

func _status_for(crew: Array[Dictionary], crew_id: String) -> int:
	for crew_member: Dictionary in crew:
		if crew_member["id"] == crew_id:
			return int(crew_member["status"])
	return -1

func _expect_result(result: Dictionary, expected_updated: bool, expected_error: String) -> void:
	_expect(result.get("is_updated") == expected_updated and result.get("error_code") == expected_error, "GameState 更新結果不符：%s" % result)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("GameStateMutation 測試失敗：%s" % message)

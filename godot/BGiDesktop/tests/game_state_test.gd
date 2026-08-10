extends SceneTree

const GameStateScript = preload("res://scripts/game_state.gd")

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state := GameStateScript.new()
	root.add_child(game_state)
	var initial_crew: Array[Dictionary] = game_state.get_crew()

	_expect(initial_crew.size() == 5, "初始小弟必須正好有 5 名")
	for crew_member: Dictionary in initial_crew:
		_expect(crew_member["status"] == GameStateScript.CrewStatus.AVAILABLE, "初始小弟必須全部可用")

	initial_crew[0]["status"] = GameStateScript.CrewStatus.DISPATCHED
	initial_crew.append({"id": "external_copy", "status": GameStateScript.CrewStatus.COMPLETED})
	var unchanged_crew: Array[Dictionary] = game_state.get_crew()

	_expect(unchanged_crew.size() == 5, "修改取得的複本不得改變 GameState 名單")
	for crew_member: Dictionary in unchanged_crew:
		_expect(crew_member["status"] == GameStateScript.CrewStatus.AVAILABLE, "修改取得的複本不得回寫 GameState 狀態")

	game_state.queue_free()
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("GameState 測試失敗：%s" % message)

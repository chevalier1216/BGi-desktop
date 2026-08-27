extends SceneTree

const StarterMissionFlowPanelScene = preload("res://scenes/starter_mission_flow_panel.tscn")

const PLAYER_SAVE_PATH: String = "user://starter_mission_flow_panel_projection_readiness.json"

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var not_ready_panel: StarterMissionFlowPanel = StarterMissionFlowPanelScene.instantiate() as StarterMissionFlowPanel
	var not_ready_refresh: Dictionary = not_ready_panel.get_refresh_directory_state()
	_expect(not bool(not_ready_refresh["is_ready"]), "refresh directory must identify a panel that has not initialized")
	_expect(str(not_ready_refresh["allowance"]) == "刷新額度：資料尚未就緒", "not-ready refresh directory must not fabricate an allowance")
	_expect(not bool(not_ready_refresh["can_refresh"]), "not-ready refresh directory must never enable refresh")
	_expect(Array(not_ready_panel.get_task_directory_entries()["current"]).is_empty(), "not-ready task directory must remain empty")
	_expect(not not_ready_panel.show_task_detail("starter_01"), "not-ready task detail projection must reject access safely")
	var not_ready_territory: Dictionary = not_ready_panel.get_territory_exploration_status()
	_expect(not bool(not_ready_territory["is_ready"]) and not bool(not_ready_territory["can_explore"]), "not-ready territory projection must remain unavailable")
	not_ready_panel.free()

	var malformed_file: FileAccess = FileAccess.open(PLAYER_SAVE_PATH, FileAccess.WRITE)
	malformed_file.store_string("{not valid json")
	malformed_file.close()
	var recovery_panel: StarterMissionFlowPanel = StarterMissionFlowPanelScene.instantiate() as StarterMissionFlowPanel
	recovery_panel.player_save_store_path = PLAYER_SAVE_PATH
	root.add_child(recovery_panel)
	_expect(recovery_panel._is_recovery_hold, "invalid player state must enter recovery hold")
	var recovery_refresh: Dictionary = recovery_panel.get_refresh_directory_state()
	_expect(not bool(recovery_refresh["is_ready"]), "recovery hold refresh directory must identify unavailable state")
	_expect(str(recovery_refresh["allowance"]) == "刷新額度：無法讀取", "recovery hold refresh directory must not fabricate an allowance")
	_expect(not bool(recovery_refresh["can_refresh"]), "recovery hold refresh directory must never enable refresh")
	_expect(not recovery_panel.show_task_detail("starter_01"), "recovery hold task detail projection must reject access safely")
	var recovery_territory: Dictionary = recovery_panel.get_territory_exploration_status()
	_expect(not bool(recovery_territory["is_ready"]) and not bool(recovery_territory["can_explore"]), "recovery hold territory projection must remain unavailable")
	recovery_panel.queue_free()
	await process_frame
	print("StarterMissionFlowPanelProjectionReadiness: PASS" if not _failed else "StarterMissionFlowPanelProjectionReadiness: FAIL")
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("StarterMissionFlowPanelProjectionReadiness test failed: %s" % message)
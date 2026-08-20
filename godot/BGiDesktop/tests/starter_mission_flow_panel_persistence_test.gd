extends SceneTree

const StarterMissionFlowPanelScene = preload("res://scenes/starter_mission_flow_panel.tscn")
const TEST_FILE_PATH: String = "user://starter_mission_flow_panel_persistence_test.json"
const PLAYER_SAVE_PATH: String = "user://starter_mission_flow_panel_persistence_player_save.json"

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var first_panel: StarterMissionFlowPanel = _create_panel(100)
	_select_crew(first_panel, 3)
	first_panel.start_button.emit_signal("pressed")
	_expect(first_panel.status_label.text == "等待中：剩餘 5 秒", "started task must show only its remaining countdown")
	_expect(first_panel._assignment_state.get_assigned_crew_ids(first_panel._task_id) == ["crew_01", "crew_02", "crew_03"], "started task must assign the selected crew ids")
	first_panel.queue_free()
	await process_frame
	_reset_game_state_to_available()

	var waiting_panel: StarterMissionFlowPanel = _create_panel(104)
	_expect(waiting_panel.status_label.text == "等待中：剩餘 1 秒", "reopened unfinished task must restore its waiting state")
	_expect(waiting_panel.refresh_button.disabled, "reopened accepted task must keep refresh unavailable")
	_expect(waiting_panel._selected_crew_ids == ["crew_01", "crew_02", "crew_03"], "reopened task must restore its selected crew ids")
	_expect(waiting_panel._assignment_state.get_assigned_crew_ids(waiting_panel._task_id) == ["crew_01", "crew_02", "crew_03"], "reopened task must restore its assignment state")
	for choice: CheckButton in waiting_panel.crew_selector.get_children():
		_expect(choice.disabled, "waiting restored task must not allow assigned crew selection changes")
	waiting_panel.queue_free()
	await process_frame
	_reset_game_state_to_available()

	var completed_panel: StarterMissionFlowPanel = _create_panel(105)
	_expect(completed_panel.status_label.text == "任務已完成", "expired reopened task must save and show its completion state")
	var locked_result: Dictionary = Dictionary(completed_panel._lifecycle._locked_results_by_task_id[completed_panel._task_id]).duplicate(true)
	completed_panel.queue_free()
	await process_frame
	_reset_game_state_to_available()

	var locked_panel: StarterMissionFlowPanel = _create_panel(999)
	_expect(locked_panel._task_id == "starter_02", "reopened player state must advance the current tutorial task before result claim")
	_expect(locked_panel.show_task_detail("starter_01"), "completed mission must remain available from the completed mission directory")
	_expect(locked_panel.status_label.text == "任務已完成", "reopened locked result must retain its completed presentation")
	var repeated_resolution: Dictionary = locked_panel._lifecycle.resolve_completed_result(locked_panel._task_id, 999)
	_expect(not bool(repeated_resolution["did_resolve"]), "reopened locked result must not resolve again")
	_expect(int(repeated_resolution["result"]["resolved_at_seconds"]) == int(locked_result["resolved_at_seconds"]), "reopened locked result must retain its first resolution time")
	_expect(locked_panel._selected_crew_ids.is_empty(), "completed restoration must not present a stale crew selection")
	for crew_member: Dictionary in locked_panel._game_state.get_crew():
		_expect(int(crew_member["status"]) == 0, "completed restoration must keep all crew available for the next task")
	locked_panel.queue_free()

	quit(1 if _failed else 0)

func _create_panel(current_time_seconds: int) -> StarterMissionFlowPanel:
	var panel: StarterMissionFlowPanel = StarterMissionFlowPanelScene.instantiate() as StarterMissionFlowPanel
	panel.execution_state_store_path = TEST_FILE_PATH
	panel.player_save_store_path = PLAYER_SAVE_PATH
	panel.current_time_override = current_time_seconds
	root.add_child(panel)
	return panel

func _select_crew(panel: StarterMissionFlowPanel, count: int) -> void:
	for index: int in count:
		var choice: CheckButton = panel.crew_selector.get_child(index) as CheckButton
		choice.button_pressed = true
		choice.emit_signal("toggled", true)

func _reset_game_state_to_available() -> void:
	var game_state: Node = root.get_node("GameState") as Node
	for crew_member: Dictionary in game_state.get_crew():
		game_state.set_crew_status(str(crew_member["id"]), 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("StarterMissionFlowPanelPersistence test failed: %s" % message)

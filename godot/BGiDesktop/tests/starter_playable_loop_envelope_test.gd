extends SceneTree

const StarterMissionFlowPanelScene = preload("res://scenes/starter_mission_flow_panel.tscn")
const PlayerSaveEnvelopeStoreScript = preload("res://scripts/player_save_envelope_store.gd")

const EXECUTION_STATE_PATH: String = "user://starter_playable_loop_envelope_execution.json"
const PLAYER_SAVE_PATH: String = "user://starter_playable_loop_envelope.json"

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var dispatched_crew_ids: Array[String] = ["crew_01", "crew_02", "crew_03"]
	var dispatched_panel: StarterMissionFlowPanel = _create_panel("DispatchedPanel", 100)
	_select_crew(dispatched_panel, dispatched_crew_ids)
	dispatched_panel.start_button.emit_signal("pressed")
	_expect(dispatched_panel.status_label.text == "等待中：剩餘 5 秒", "dispatch must visibly enter the countdown state")
	dispatched_panel.queue_free()
	await process_frame
	_reset_game_state_to_available()

	var resumed_panel: StarterMissionFlowPanel = _create_panel("ResumedPanel", 104)
	_expect(resumed_panel.status_label.text == "等待中：剩餘 1 秒", "saved mission run must resume with its controlled countdown")
	_expect(resumed_panel._selected_crew_ids == dispatched_crew_ids, "saved mission run must restore its assigned crew snapshot")
	resumed_panel.queue_free()
	await process_frame
	_reset_game_state_to_available()

	var completed_panel: StarterMissionFlowPanel = _create_panel("CompletedPanel", 105)
	_expect(completed_panel.status_label.text == "任務已完成", "expired saved mission must expose the fixed completed result state")
	var first_result: Dictionary = Dictionary(completed_panel._lifecycle._locked_results_by_task_id["starter_01"]).duplicate(true)
	completed_panel.queue_free()
	await process_frame
	_reset_game_state_to_available()

	var claim_panel: StarterMissionFlowPanel = _create_panel("ClaimPanel", 999)
	var resumed_result: Dictionary = Dictionary(claim_panel._lifecycle._locked_results_by_task_id["starter_01"])
	_expect(str(resumed_result["result_id"]) == str(first_result["result_id"]), "restart must retain the same fixed result id before collection")
	_expect(int(resumed_result["resolved_at_seconds"]) == int(first_result["resolved_at_seconds"]), "restart must retain the original result resolution time before collection")
	_expect(claim_panel._task_id == "starter_02", "restart must make the next tutorial task dispatchable before collection")
	_expect(claim_panel.show_task_detail("starter_01"), "completed task must remain available from the completed mission list")
	_expect(not claim_panel.claim_button.disabled, "fixed result must offer collection after restart")
	claim_panel.claim_button.emit_signal("pressed")
	_expect(claim_panel._task_id == "starter_01", "successful collection must keep the completed task detail open")
	_expect(claim_panel.claim_receipt_label.text.is_empty(), "successful collection must keep receipt history hidden")
	_expect(claim_panel._touched_territory_ids.has("territory_02"), "first saved claim must trigger the authorized territory touch")
	_expect(claim_panel._game_state.get_crew().size() == 6, "first territory touch must unlock exactly one crew member")
	claim_panel.queue_free()
	await process_frame
	_reset_game_state_to_available()

	var stored: Dictionary = PlayerSaveEnvelopeStoreScript.new(PLAYER_SAVE_PATH).load()
	_expect(bool(stored["is_loaded"]), "the playable loop must persist one valid player save envelope")
	var envelope: Dictionary = Dictionary(stored["envelope"])
	var execution_state: Dictionary = Dictionary(envelope["execution_state"])
	_expect(Dictionary(execution_state["executions"]).is_empty(), "claimed mission must not retain an active execution clock")
	_expect(bool(Dictionary(execution_state["result_state"])["claimed_task_ids"].get("starter_01", false)), "claimed mission must remain claimed in the shared envelope")
	_expect(Dictionary(envelope["claim_receipts_by_mission_run_id"]).has("starter_01:100"), "shared envelope must retain the claim receipt by mission run id")
	_expect(Dictionary(envelope["territory_touch_receipts_by_id"]).has("territory_02"), "shared envelope must retain the territory touch receipt")
	_expect(Dictionary(envelope["territory_state_by_id"]).has("territory_02"), "shared envelope must retain territory display state")
	_expect(Dictionary(envelope["refresh_state"]).has("allowance"), "shared envelope must retain refresh state")
	_expect(Array(envelope["crew_by_id"]).size() == 6, "shared envelope must retain the unlocked crew roster")

	var reopened_panel: StarterMissionFlowPanel = _create_panel("ReopenedPanel", 1000)
	_expect(reopened_panel._task_id == "starter_02", "full-loop restart must resume the next tutorial task")
	_expect(reopened_panel.claim_receipt_label.text.is_empty(), "full-loop restart must keep claim history hidden")
	_expect(reopened_panel.status_label.text == "已選 0/5 名小弟", "full-loop restart must offer the next task for a new selection")
	_expect(reopened_panel._game_state.get_crew().size() == 6, "full-loop restart must retain the unlocked roster")
	for crew_member: Dictionary in reopened_panel._game_state.get_crew():
		_expect(int(crew_member["status"]) == 0, "claimed crew must be available after full-loop restart")
	reopened_panel.queue_free()

	quit(1 if _failed else 0)

func _create_panel(panel_name: String, current_time_seconds: int) -> StarterMissionFlowPanel:
	var panel: StarterMissionFlowPanel = StarterMissionFlowPanelScene.instantiate() as StarterMissionFlowPanel
	panel.name = panel_name
	panel.execution_state_store_path = EXECUTION_STATE_PATH
	panel.player_save_store_path = PLAYER_SAVE_PATH
	panel.current_time_override = current_time_seconds
	root.add_child(panel)
	return panel

func _select_crew(panel: StarterMissionFlowPanel, crew_ids: Array[String]) -> void:
	for index: int in range(crew_ids.size()):
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
		push_error("StarterPlayableLoopEnvelope test failed: %s" % message)

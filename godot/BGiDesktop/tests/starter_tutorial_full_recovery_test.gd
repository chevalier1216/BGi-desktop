extends SceneTree

const StarterMissionFlowPanelScene = preload("res://scenes/starter_mission_flow_panel.tscn")
const PlayerSaveEnvelopeStoreScript = preload("res://scripts/player_save_envelope_store.gd")

const EXECUTION_STATE_PATH: String = "user://starter_tutorial_full_recovery_execution.json"
const PLAYER_SAVE_PATH: String = "user://starter_tutorial_full_recovery_player_save.json"
const EXPECTED_DURATIONS: Array[int] = [
	5, 5,
	10, 10, 10,
	30, 30, 30, 30,
	60, 60,
	180, 180, 180, 180,
	600, 600, 600, 600, 600,
	900, 900, 900,
]

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var started_at_seconds: int = 100
	for index: int in range(EXPECTED_DURATIONS.size()):
		var task_id: String = "starter_%02d" % (index + 1)
		var dispatch_panel: StarterMissionFlowPanel = _create_panel("Dispatch_%02d" % index, started_at_seconds)
		_expect(dispatch_panel._task_id == task_id, "tutorial must present every fixed task in order")
		_expect(dispatch_panel._duration_seconds == EXPECTED_DURATIONS[index], "tutorial task must retain its approved fixed duration")
		_select_first_available_crew(dispatch_panel)
		dispatch_panel.start_button.emit_signal("pressed")
		_expect(dispatch_panel.status_label.text.begins_with("等待中：剩餘"), "task dispatch must enter the waiting countdown")
		dispatch_panel.queue_free()
		await process_frame
		_reset_game_state_to_available()

		var completed_at_seconds: int = started_at_seconds + EXPECTED_DURATIONS[index]
		var recovery_panel: StarterMissionFlowPanel = _create_panel("Recovery_%02d" % index, completed_at_seconds)
		_expect(recovery_panel._task_id == task_id, "restart must restore the same active tutorial task before claim")
		_expect(recovery_panel.status_label.text == "任務已完成", "controlled completion after restart must expose a fixed completed result")
		_expect(not recovery_panel.claim_button.disabled, "recovered fixed result must offer one collection action")
		recovery_panel.claim_button.emit_signal("pressed")
		_expect(recovery_panel._result_state.is_claimed(task_id), "collection must mark the recovered task claimed")
		_expect(recovery_panel.claim_receipt_label.text.is_empty(), "collection must keep mission-run receipt history hidden")
		recovery_panel.queue_free()
		await process_frame
		_reset_game_state_to_available()
		started_at_seconds = completed_at_seconds + 1

	var stored: Dictionary = PlayerSaveEnvelopeStoreScript.new(PLAYER_SAVE_PATH).load()
	_expect(bool(stored["is_loaded"]), "all tutorial progress must be written to one player save envelope")
	var envelope: Dictionary = Dictionary(stored["envelope"])
	var execution_state: Dictionary = Dictionary(envelope["execution_state"])
	var claimed_task_ids: Dictionary = Dictionary(Dictionary(execution_state["result_state"])["claimed_task_ids"])
	_expect(claimed_task_ids.size() == EXPECTED_DURATIONS.size(), "all 23 tutorial tasks must remain claimed after repeated recovery")
	_expect(Dictionary(envelope["claim_receipts_by_mission_run_id"]).size() == EXPECTED_DURATIONS.size(), "all 23 tutorial runs must retain one durable receipt each")
	_expect(Dictionary(execution_state["mission_runs"])["mission_runs_by_id"].size() == EXPECTED_DURATIONS.size(), "all 23 tutorial mission runs must remain traceable after recovery")
	_expect(Dictionary(execution_state["executions"]).is_empty(), "completed tutorial sequence must not retain an active execution clock")

	var final_panel: StarterMissionFlowPanel = _create_panel("FinalRecovery", started_at_seconds)
	_expect(final_panel.task_label.text == "新手任務：全部完成", "restart after the final claim must not reopen a completed tutorial task")
	_expect(final_panel.claim_button.disabled, "restart after the final claim must not offer a stale collection action")
	final_panel.queue_free()

	quit(1 if _failed else 0)

func _create_panel(panel_name: String, current_time_seconds: int) -> StarterMissionFlowPanel:
	var panel: StarterMissionFlowPanel = StarterMissionFlowPanelScene.instantiate() as StarterMissionFlowPanel
	panel.name = panel_name
	panel.execution_state_store_path = EXECUTION_STATE_PATH
	panel.player_save_store_path = PLAYER_SAVE_PATH
	panel.current_time_override = current_time_seconds
	root.add_child(panel)
	return panel

func _select_first_available_crew(panel: StarterMissionFlowPanel) -> void:
	for choice: CheckButton in panel.crew_selector.get_children():
		if not choice.disabled:
			choice.button_pressed = true
			choice.emit_signal("toggled", true)
			return
	_expect(false, "every tutorial task must expose one available crew member for its minimum dispatch")

func _reset_game_state_to_available() -> void:
	var game_state: Node = root.get_node("GameState") as Node
	for crew_member: Dictionary in game_state.get_crew():
		game_state.set_crew_status(str(crew_member["id"]), 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("StarterTutorialFullRecovery test failed: %s" % message)

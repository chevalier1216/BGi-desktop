extends SceneTree

const StarterMissionFlowPanelScene = preload("res://scenes/starter_mission_flow_panel.tscn")
const PlayerSaveEnvelopeStoreScript = preload("res://scripts/player_save_envelope_store.gd")
const MissionAssignmentStateScript = preload("res://scripts/mission_assignment_state.gd")
const AssignmentCoordinatorScript = preload("res://scripts/persistent_mission_assignment_coordinator.gd")

const EXECUTION_STATE_PATH: String = "user://starter_mission_flow_panel_claim_execution_test.json"

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var first_panel: StarterMissionFlowPanel = _create_panel("FirstPanel", 100)
	var dispatched_crew_ids: Array[String] = ["crew_01", "crew_02", "crew_03"]
	for index: int in range(dispatched_crew_ids.size()):
		var choice: CheckButton = first_panel.crew_selector.get_child(index) as CheckButton
		choice.button_pressed = true
		choice.emit_signal("toggled", true)
	first_panel.start_button.emit_signal("pressed")
	var clock: RefCounted = first_panel._snapshot_collection.restore_clock(first_panel._task_id)
	first_panel.refresh_execution_status(clock.started_at_seconds + 5)
	_expect(first_panel.status_label.text == "任務已完成", "completed task must show a client-facing completion state")
	_expect(not first_panel.claim_button.disabled, "locked result must enable exactly one claim action")
	_expect(Array(first_panel.get_task_directory_entries()["current"]).is_empty(), "completion must not make the next fixed tutorial task dispatchable before claim")
	for crew_id: String in dispatched_crew_ids:
		_expect(_status_for(first_panel._game_state.get_crew(), crew_id) == 0, "completion must release every dispatched crew member before result claim")
	var locked_result: Dictionary = Dictionary(first_panel._lifecycle._locked_results_by_task_id[first_panel._task_id]).duplicate(true)
	first_panel.current_time_override = clock.started_at_seconds + 5
	first_panel.claim_button.emit_signal("pressed")
	_expect(first_panel._task_id == "starter_01", "claim must keep the completed task detail open")
	_expect(first_panel.claim_receipt_label.text.is_empty(), "claim receipt must remain hidden from the player")
	_expect(first_panel.status_label.text == "結果已領取", "claim must update only the completed task presentation")
	_expect(first_panel.claim_button.disabled, "claimed task must disable repeated claim")
	_expect(first_panel._snapshot_collection.restore_clock("starter_01") == null, "claim must clear the completed task execution clock")
	_expect(first_panel._result_state.is_claimed("starter_01"), "claim must record the claimed task id")
	for crew_id: String in dispatched_crew_ids:
		_expect(_status_for(first_panel._game_state.get_crew(), crew_id) == 0, "claim must return every dispatched crew member to available")
	_expect(first_panel._assignment_state.get_assigned_crew_ids(first_panel._task_id).is_empty(), "completion must clear the original task assignment")
	first_panel.claim_button.emit_signal("pressed")
	_expect(first_panel.status_label.text == "結果已領取", "repeated claim input must not change the completed-task presentation")
	_expect(Dictionary(first_panel._lifecycle._locked_results_by_task_id["starter_01"]) == locked_result, "repeated claim input must not replace the locked result")
	first_panel.queue_free()
	await process_frame

	var stored_state: Dictionary = PlayerSaveEnvelopeStoreScript.new("%s.envelope" % EXECUTION_STATE_PATH).load()
	_expect(bool(stored_state["is_loaded"]), "saved claimed state must load from the player envelope")
	var execution_state: Dictionary = Dictionary(stored_state["envelope"])["execution_state"]
	_expect(Dictionary(execution_state["executions"]).is_empty(), "saved claimed state must not retain an execution clock")
	_expect(bool(Dictionary(execution_state["result_state"])["claimed_task_ids"].get("starter_01", false)), "saved claimed state must retain the claimed task id")
	var saved_envelope: Dictionary = Dictionary(stored_state["envelope"])
	_expect(Dictionary(saved_envelope["claim_receipts_by_mission_run_id"]).has("starter_01:100"), "claimed run receipt must share the player envelope")
	_expect(Dictionary(saved_envelope["territory_touch_receipts_by_id"]).is_empty(), "a mission without a fixed territory descriptor must not infer a territory touch")
	_expect(Dictionary(saved_envelope["territory_state_by_id"]).has("territory_02"), "territory progress state must share the player envelope")
	_expect(Dictionary(saved_envelope["refresh_state"]).has("allowance"), "refresh state must share the player envelope")
	_expect(Array(saved_envelope["crew_by_id"]).size() == 5, "a mission without a fixed character descriptor must not infer an unlock")

	var reopened_panel: StarterMissionFlowPanel = _create_panel("ReopenedPanel", 999)
	_expect(reopened_panel._task_id == "starter_02", "reopened panel must restore the next fixed tutorial task")
	_expect(reopened_panel.claim_receipt_label.text.is_empty(), "reopened panel must keep claim history hidden from the player")
	_expect(reopened_panel.status_label.text == "已選 0/5 名小弟", "reopened panel must offer the next task for crew selection")
	_expect(reopened_panel.claim_button.disabled, "reopened next task must not allow a stale claim")
	_expect(reopened_panel.start_button.disabled, "reopened next task must require a crew selection")
	for choice: CheckButton in reopened_panel.crew_selector.get_children():
		_expect(not choice.disabled, "reopened next task must allow crew reselection")
	for crew_id: String in dispatched_crew_ids:
		_expect(_status_for(reopened_panel._game_state.get_crew(), crew_id) == 0, "reopened claimed task must retain available crew state for later tasks")
	var future_assignment_state: RefCounted = MissionAssignmentStateScript.new()
	var future_assignment_coordinator: RefCounted = AssignmentCoordinatorScript.new(reopened_panel._game_state, future_assignment_state)
	var future_assignment_result: Dictionary = future_assignment_coordinator.accept_assignment("starter_02", dispatched_crew_ids)
	_expect(bool(future_assignment_result["is_accepted"]), "claimed crew members must be assignable to a later task after reopening")
	_expect(bool(future_assignment_coordinator.release_assignment("starter_02")["is_released"]), "later task cleanup must release its reassigned crew")
	reopened_panel.queue_free()

	quit(1 if _failed else 0)

func _create_panel(panel_name: String, current_time_seconds: int) -> StarterMissionFlowPanel:
	var panel: StarterMissionFlowPanel = StarterMissionFlowPanelScene.instantiate() as StarterMissionFlowPanel
	panel.name = panel_name
	panel.execution_state_store_path = EXECUTION_STATE_PATH
	panel.territory_state_store_path = "user://%s_territory_unlock.json" % panel_name
	panel.territory_progress_state_store_path = "user://%s_territory_progress.json" % panel_name
	panel.refresh_state_store_path = "user://%s_refresh.json" % panel_name
	panel.current_time_override = current_time_seconds
	root.add_child(panel)
	return panel

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("StarterMissionFlowPanelClaim test failed: %s" % message)

func _status_for(crew: Array[Dictionary], crew_id: String) -> int:
	for crew_member: Dictionary in crew:
		if str(crew_member["id"]) == crew_id:
			return int(crew_member["status"])
	return -1

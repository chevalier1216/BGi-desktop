extends SceneTree

const StarterMissionFlowPanelScene = preload("res://scenes/starter_mission_flow_panel.tscn")
const ExecutionStateStoreScript = preload("res://scripts/mission_execution_state_store.gd")

const EXECUTION_STATE_PATH: String = "user://starter_mission_flow_panel_claim_execution_test.json"

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var first_panel: StarterMissionFlowPanel = _create_panel("FirstPanel", 100)
	var first_choice: CheckButton = first_panel.crew_selector.get_child(0) as CheckButton
	first_choice.button_pressed = true
	first_choice.emit_signal("toggled", true)
	first_panel.start_button.emit_signal("pressed")
	var clock: RefCounted = first_panel._snapshot_collection.restore_clock(first_panel._task_id)
	first_panel.refresh_execution_status(clock.started_at_seconds + 5)
	_expect(first_panel.status_label.text == "已完成／保底報酬待定", "completed task must keep the guaranteed placeholder presentation")
	_expect(not first_panel.claim_button.disabled, "locked result must enable exactly one claim action")
	var locked_result: Dictionary = Dictionary(first_panel._lifecycle._locked_results_by_task_id[first_panel._task_id]).duplicate(true)
	first_panel.current_time_override = clock.started_at_seconds + 5
	first_panel.claim_button.emit_signal("pressed")
	_expect(first_panel.status_label.text == "已領取／保底報酬待定", "claim must present a claimed guaranteed-result state")
	_expect(first_panel.claim_button.disabled, "claimed task must disable repeated claim")
	_expect(first_panel._snapshot_collection.restore_clock(first_panel._task_id) == null, "claim must clear the task execution clock")
	_expect(first_panel._result_state.is_claimed(first_panel._task_id), "claim must record the claimed task id")
	first_panel.claim_button.emit_signal("pressed")
	_expect(first_panel.status_label.text == "已領取／保底報酬待定", "repeated claim input must not change the claimed presentation")
	_expect(Dictionary(first_panel._lifecycle._locked_results_by_task_id[first_panel._task_id]) == locked_result, "repeated claim input must not replace the locked result")
	first_panel.queue_free()
	await process_frame

	var stored_state: Dictionary = ExecutionStateStoreScript.new(EXECUTION_STATE_PATH).load()
	_expect(stored_state["collection"].restore_clock("starter_01") == null, "saved claimed state must not retain an execution clock")
	_expect(stored_state["result_state"].is_claimed("starter_01"), "saved claimed state must retain the claimed task id")

	var reopened_panel: StarterMissionFlowPanel = _create_panel("ReopenedPanel", 999)
	_expect(reopened_panel.status_label.text == "已領取／保底報酬待定", "reopened claimed task must retain claimed presentation")
	_expect(reopened_panel.claim_button.disabled, "reopened claimed task must not allow another claim")
	_expect(reopened_panel.start_button.disabled, "reopened claimed task must not allow another dispatch")
	for choice: CheckButton in reopened_panel.crew_selector.get_children():
		_expect(choice.disabled, "reopened claimed task must not allow crew reselection")
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

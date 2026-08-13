extends SceneTree

const StarterMissionFlowPanelScene = preload("res://scenes/starter_mission_flow_panel.tscn")

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var panel: StarterMissionFlowPanel = StarterMissionFlowPanelScene.instantiate() as StarterMissionFlowPanel
	root.add_child(panel)
	_expect(panel.crew_selector.get_child_count() == 5, "starter flow must display exactly five crew choices")
	_expect(panel.start_button.disabled, "task must not start without the minimum crew")

	var first_choice: CheckButton = panel.crew_selector.get_child(0) as CheckButton
	first_choice.button_pressed = true
	first_choice.emit_signal("toggled", true)
	_expect(not panel.start_button.disabled, "one selected crew member must satisfy the minimum")
	panel.start_button.emit_signal("pressed")
	_expect(panel.status_label.text.begins_with("等待中："), "started task must display waiting state")
	_expect(panel.start_button.disabled, "waiting task must disable a second start")
	for choice: CheckButton in panel.crew_selector.get_children():
		_expect(choice.disabled, "waiting task must lock all crew choices")
	var clock: RefCounted = panel._snapshot_collection.restore_clock(panel._task_id)
	var started_at_seconds: int = clock.started_at_seconds
	panel.refresh_execution_status(started_at_seconds + 2)
	_expect(panel.status_label.text == "等待中：剩餘 3 秒", "waiting task must show the remaining duration")
	panel.refresh_execution_status(started_at_seconds + 5)
	_expect(panel.status_label.text == "已完成／保底報酬待定", "expired task must show a guaranteed pending reward state")
	var completed_text: String = panel.status_label.text
	var locked_result: Dictionary = Dictionary(panel._lifecycle._locked_results_by_task_id[panel._task_id]).duplicate(true)
	panel.refresh_execution_status(started_at_seconds + 20)
	_expect(panel.status_label.text == completed_text, "repeated completion updates must keep the settled state")
	_expect(Dictionary(panel._lifecycle._locked_results_by_task_id[panel._task_id]) == locked_result, "repeated completion updates must not resolve a second result")

	panel.queue_free()
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("StarterMissionFlowPanel test failed: %s" % message)

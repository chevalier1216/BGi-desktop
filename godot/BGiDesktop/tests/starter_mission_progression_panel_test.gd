extends SceneTree

const StarterMissionFlowPanelScene = preload("res://scenes/starter_mission_flow_panel.tscn")

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var panel: StarterMissionFlowPanel = StarterMissionFlowPanelScene.instantiate() as StarterMissionFlowPanel
	root.add_child(panel)
	_expect(panel.task_label.text == "新手任務 01（5 秒）", "panel must start with a client-readable first tutorial task title")
	var first_choice: CheckButton = panel.crew_selector.get_child(0) as CheckButton
	first_choice.button_pressed = true
	first_choice.emit_signal("toggled", true)
	panel.start_button.emit_signal("pressed")
	var clock: RefCounted = panel._snapshot_collection.restore_clock(panel._task_id)
	panel.refresh_execution_status(clock.started_at_seconds + 5)
	_expect(panel.status_label.text == "任務已完成", "completion must present a completed task state")
	_expect(panel.guaranteed_reward_label.text.is_empty(), "completion must not expose an internal reward placeholder")
	_expect(str(Array(panel.get_task_directory_entries()["current"])[0]["task_id"]) == "starter_02", "completion must make the next tutorial task available before result collection")
	panel.current_time_override = clock.started_at_seconds + 5
	panel.claim_button.emit_signal("pressed")
	_expect(str(Array(panel.get_task_directory_entries()["current"])[0]["task_id"]) == "starter_02", "result collection must not alter the already-available next tutorial task")

	panel.queue_free()
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("StarterMissionProgressionPanel test failed: %s" % message)

extends SceneTree

const StarterMissionFlowPanelScene = preload("res://scenes/starter_mission_flow_panel.tscn")

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var panel: StarterMissionFlowPanel = StarterMissionFlowPanelScene.instantiate() as StarterMissionFlowPanel
	root.add_child(panel)
	_expect(panel.task_label.text == "新手任務：starter_01（5 秒）", "panel must start with the first fixed tutorial task")
	var first_choice: CheckButton = panel.crew_selector.get_child(0) as CheckButton
	first_choice.button_pressed = true
	first_choice.emit_signal("toggled", true)
	panel.start_button.emit_signal("pressed")
	var clock: RefCounted = panel._snapshot_collection.restore_clock(panel._task_id)
	panel.refresh_execution_status(clock.started_at_seconds + 5)
	_expect(panel.status_label.text == "已完成／保底報酬待定", "completion presentation must remain unchanged")
	_expect(panel.guaranteed_reward_label.text == "保底報酬：[PLACEHOLDER]", "completion must retain reward disclosure")
	panel.current_time_override = clock.started_at_seconds + 5
	panel.claim_button.emit_signal("pressed")
	_expect(panel.next_tutorial_task_label.text == "下一個新手任務：starter_02（5 秒）", "first completed task must present the next fixed tutorial task")

	panel.queue_free()
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("StarterMissionProgressionPanel test failed: %s" % message)

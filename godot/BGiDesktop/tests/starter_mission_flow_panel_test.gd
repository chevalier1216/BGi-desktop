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

	panel.queue_free()
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("StarterMissionFlowPanel test failed: %s" % message)

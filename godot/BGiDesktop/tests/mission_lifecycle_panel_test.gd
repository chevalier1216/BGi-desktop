extends SceneTree

const MissionLifecyclePanelScene = preload("res://scenes/mission_lifecycle_panel.tscn")

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var panel: MissionLifecyclePanel = MissionLifecyclePanelScene.instantiate() as MissionLifecyclePanel
	root.add_child(panel)
	_expect(not panel.accept_button.disabled, "available state must enable accept")
	_expect(panel.completion_button.disabled, "available state must disable completion check")
	_expect(panel.claim_button.disabled, "available state must disable claim")

	panel.set_task_state("starter_01", MissionLifecyclePanel.STATE_DISPATCHED)
	_expect(panel.accept_button.disabled, "dispatched state must disable accept")
	_expect(not panel.completion_button.disabled, "dispatched state must enable completion check")
	_expect(panel.claim_button.disabled, "dispatched state must disable claim")

	panel.set_task_state("starter_01", MissionLifecyclePanel.STATE_COMPLETED)
	_expect(panel.completion_button.disabled, "completed state must disable completion check")
	_expect(not panel.claim_button.disabled, "completed state must enable claim")

	panel.set_task_state("starter_01", MissionLifecyclePanel.STATE_CLAIMED)
	_expect(panel.accept_button.disabled and panel.completion_button.disabled and panel.claim_button.disabled, "claimed state must disable all actions")
	_expect(panel.state_label.text == "狀態：已收取", "claimed state must display its text")

	panel.queue_free()
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionLifecyclePanel test failed: %s" % message)

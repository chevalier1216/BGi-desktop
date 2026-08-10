extends SceneTree

const MissionLifecyclePanelScene = preload("res://scenes/mission_lifecycle_panel.tscn")
const MissionLifecycleDemoControllerScript = preload("res://scripts/mission_lifecycle_demo_controller.gd")

var _failed: bool = false
var _panel: MissionLifecyclePanel

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var holder: Node = Node.new()
	holder.name = "LifecycleDemoTestHolder"
	root.add_child(holder)
	_panel = MissionLifecyclePanelScene.instantiate() as MissionLifecyclePanel
	holder.add_child(_panel)
	var controller: Node = MissionLifecycleDemoControllerScript.new()
	controller.panel_path = NodePath("../MissionLifecyclePanel")
	holder.add_child(controller)
	call_deferred("_verify", holder)

func _verify(holder: Node) -> void:
	_expect(not _panel.accept_button.disabled, "connected panel must start with accept enabled")
	_panel.accept_button.emit_signal("pressed")
	_expect(_panel.state_label.text == "狀態：派遣中", "accept action must display dispatched state")
	_expect(not _panel.completion_button.disabled, "accept action must enable completion check")
	_panel.completion_button.emit_signal("pressed")
	_expect(_panel.state_label.text == "狀態：完成待收取", "completion action must display claimable state")
	_expect(not _panel.claim_button.disabled, "completion action must enable claim")
	_panel.claim_button.emit_signal("pressed")
	_expect(_panel.state_label.text == "狀態：已收取", "claim action must display claimed state")
	_expect(_panel.accept_button.disabled and _panel.completion_button.disabled and _panel.claim_button.disabled, "claim action must disable all lifecycle actions")

	holder.queue_free()
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionLifecycleDemoController test failed: %s" % message)

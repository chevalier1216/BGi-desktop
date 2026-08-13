extends SceneTree

const MissionLifecyclePanelScene = preload("res://scenes/mission_lifecycle_panel.tscn")
const MissionLifecycleDemoControllerScript = preload("res://scripts/mission_lifecycle_demo_controller.gd")
const ExecutionStateStoreScript = preload("res://scripts/mission_execution_state_store.gd")
const TEST_FILE_PATH: String = "user://mission_lifecycle_demo_recovery_test.json"

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var first_session: Dictionary = _create_session("FirstSession", 100)
	var first_panel: MissionLifecyclePanel = first_session["panel"]
	first_panel.accept_button.emit_signal("pressed")
	_expect(first_panel.state_label.text == "狀態：派遣中", "dispatch must save and display in-progress state")
	first_session["holder"].queue_free()

	var in_progress_session: Dictionary = _create_session("InProgressSession", 104)
	var in_progress_panel: MissionLifecyclePanel = in_progress_session["panel"]
	_expect(in_progress_panel.state_label.text == "狀態：派遣中", "reopen before expiry must restore in-progress state")
	in_progress_session["holder"].queue_free()

	var completed_session: Dictionary = _create_session("CompletedSession", 105)
	var completed_panel: MissionLifecyclePanel = completed_session["panel"]
	_expect(completed_panel.state_label.text == "狀態：完成待收取", "reopen after expiry must restore claimable state")
	var completed_controller: Node = completed_session["controller"]
	var first_result: Dictionary = Dictionary(completed_controller._lifecycle._locked_results_by_task_id["starter_01"]).duplicate(true)
	completed_session["holder"].queue_free()

	var locked_result_session: Dictionary = _create_session("LockedResultSession", 999)
	var locked_result_panel: MissionLifecyclePanel = locked_result_session["panel"]
	var locked_result_controller: Node = locked_result_session["controller"]
	_expect(locked_result_panel.state_label.text == "狀態：完成待收取", "reopen with locked result must remain claimable")
	var repeated_resolution: Dictionary = locked_result_controller._lifecycle.resolve_completed_result("starter_01", 999)
	_expect(not bool(repeated_resolution["did_resolve"]), "locked result must not resolve again after reopening")
	_expect(int(repeated_resolution["result"]["resolved_at_seconds"]) == int(first_result["resolved_at_seconds"]), "reopened result must retain its first lock time")
	_expect(str(repeated_resolution["result"]["guaranteed_reward"]) == str(first_result["guaranteed_reward"]), "reopened result must retain its guaranteed reward")
	_expect(str(repeated_resolution["result"]["extra_reward"]) == str(first_result["extra_reward"]), "reopened result must retain its extra reward")
	locked_result_panel.claim_button.emit_signal("pressed")
	_expect(locked_result_panel.state_label.text == "狀態：已收取", "claim must complete from recovered locked state")
	var store: RefCounted = ExecutionStateStoreScript.new(TEST_FILE_PATH)
	var after_claim_load: Dictionary = store.load()
	_expect(after_claim_load["collection"].restore_clock("starter_01") == null, "claim must clear the stored task snapshot")
	_expect(after_claim_load["result_state"].is_claimed("starter_01"), "claim state must persist after reopening")
	locked_result_session["holder"].queue_free()

	quit(1 if _failed else 0)

func _create_session(session_name: String, current_time_seconds: int) -> Dictionary:
	var holder: Node = Node.new()
	holder.name = session_name
	root.add_child(holder)
	var panel: MissionLifecyclePanel = MissionLifecyclePanelScene.instantiate() as MissionLifecyclePanel
	holder.add_child(panel)
	var controller: Node = MissionLifecycleDemoControllerScript.new()
	controller.panel_path = NodePath("../MissionLifecyclePanel")
	controller.snapshot_store_path = TEST_FILE_PATH
	controller.current_time_override = current_time_seconds
	controller.test_duration_seconds = 5
	holder.add_child(controller)
	return {"holder": holder, "panel": panel, "controller": controller}

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionLifecycleDemoRecovery test failed: %s" % message)

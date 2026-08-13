extends SceneTree

const StarterMissionFlowPanelScene = preload("res://scenes/starter_mission_flow_panel.tscn")
const TerritoryStateStoreScript = preload("res://scripts/territory_first_touch_state_store.gd")
const GameStateScript = preload("res://scripts/game_state.gd")
const MissionAssignmentStateScript = preload("res://scripts/mission_assignment_state.gd")
const AssignmentCoordinatorScript = preload("res://scripts/persistent_mission_assignment_coordinator.gd")

const TERRITORY_STATE_PATH: String = "user://starter_mission_territory_unlock_persistence_test.json"
const UNLOCKED_CREW_ID: String = "territory_territory_01_crew_01"

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var first_panel: StarterMissionFlowPanel = _create_panel("FirstPanel")
	_expect(first_panel.crew_selector.get_child_count() == 5, "first launch must begin with five crew choices")
	first_panel.explore_territory_button.emit_signal("pressed")
	_expect(first_panel.status_label.text == "首次觸及：已解鎖 1 名新人物", "first touch must unlock one crew member")
	_expect(first_panel.crew_selector.get_child_count() == 6, "first touch must add one selectable crew choice")
	var unlocked_choice: CheckButton = first_panel.crew_selector.get_child(5) as CheckButton
	_expect(not unlocked_choice.disabled, "newly unlocked crew member must be available for selection")
	first_panel.explore_territory_button.emit_signal("pressed")
	_expect(first_panel.status_label.text == "已探索此地盤：不重複解鎖", "repeated touch must not unlock another crew member")
	_expect(first_panel.crew_selector.get_child_count() == 6, "repeated touch must keep the crew pool unchanged")
	first_panel.queue_free()
	await process_frame

	var state_store: RefCounted = TerritoryStateStoreScript.new(TERRITORY_STATE_PATH)
	var restored_state: Dictionary = state_store.load()
	_expect(bool(restored_state["is_loaded"]), "saved territory state must load after reopening")
	_expect(bool(restored_state["touched_territory_ids"].get("territory_01", false)), "saved territory touch must persist")
	_expect(str(restored_state["unlocked_crew_ids_by_territory"]["territory_01"]) == UNLOCKED_CREW_ID, "saved territory state must retain the unlocked crew id")

	var restarted_game_state: Node = GameStateScript.new()
	root.add_child(restarted_game_state)
	var restore_crew_result: Dictionary = restarted_game_state.add_available_crew(UNLOCKED_CREW_ID)
	_expect(bool(restore_crew_result["is_added"]), "restarted crew pool must accept the persisted unlock once")
	var assignment_state: RefCounted = MissionAssignmentStateScript.new()
	var coordinator: RefCounted = AssignmentCoordinatorScript.new(restarted_game_state, assignment_state)
	var unlocked_crew_ids: Array[String] = [UNLOCKED_CREW_ID]
	var assignment_result: Dictionary = coordinator.accept_assignment("starter_01", unlocked_crew_ids)
	_expect(bool(assignment_result["is_accepted"]), "persisted unlocked crew member must be dispatchable in a starter mission")
	restarted_game_state.queue_free()
	await process_frame

	var reopened_panel: StarterMissionFlowPanel = _create_panel("ReopenedPanel")
	_expect(reopened_panel.crew_selector.get_child_count() == 6, "reopened panel must restore exactly one unlocked crew choice")
	_expect(reopened_panel._touched_territory_ids.size() == 1, "reopened panel must retain the first-touch state")
	reopened_panel.queue_free()

	quit(1 if _failed else 0)

func _create_panel(panel_name: String) -> StarterMissionFlowPanel:
	var panel: StarterMissionFlowPanel = StarterMissionFlowPanelScene.instantiate() as StarterMissionFlowPanel
	panel.name = panel_name
	panel.territory_state_store_path = TERRITORY_STATE_PATH
	panel.execution_state_store_path = "user://%s_execution_state.json" % panel_name
	root.add_child(panel)
	return panel

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("StarterMissionTerritoryUnlockPersistence test failed: %s" % message)

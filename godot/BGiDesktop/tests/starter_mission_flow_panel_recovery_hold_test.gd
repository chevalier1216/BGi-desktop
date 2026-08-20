extends SceneTree

const StarterMissionFlowPanelScene = preload("res://scenes/starter_mission_flow_panel.tscn")
const PlayerSaveEnvelopeStoreScript = preload("res://scripts/player_save_envelope_store.gd")

const PLAYER_SAVE_PATH: String = "user://starter_mission_flow_panel_recovery_hold.json"

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var original_payload: String = "{this is not valid json"
	var file: FileAccess = FileAccess.open(PLAYER_SAVE_PATH, FileAccess.WRITE)
	file.store_string(original_payload)
	file.close()
	var panel: StarterMissionFlowPanel = StarterMissionFlowPanelScene.instantiate() as StarterMissionFlowPanel
	panel.player_save_store_path = PLAYER_SAVE_PATH
	root.add_child(panel)
	_expect(panel._is_recovery_hold, "invalid existing envelope must enter recovery hold")
	_expect(panel.task_label.text == "無法安全讀取存檔", "recovery hold must visibly name the safe load error")
	_expect(panel.requirement_label.text == "資料尚未被變更。請重試讀取或保留錯誤代碼供檢查。", "recovery hold must state that the original data remains unchanged")
	_expect(panel.status_label.text == "錯誤：save_data_corrupted", "recovery hold must expose the corruption error code")
	_expect(panel.start_button.disabled and panel.claim_button.disabled and panel.refresh_button.disabled and panel.explore_territory_button.disabled, "recovery hold must disable state-changing actions")
	_expect(not panel.retry_load_button.disabled, "recovery hold must offer retry load")
	var loaded_file: FileAccess = FileAccess.open(PLAYER_SAVE_PATH, FileAccess.READ)
	var preserved_payload: String = loaded_file.get_as_text()
	loaded_file.close()
	_expect(preserved_payload == original_payload, "recovery hold must never overwrite the invalid envelope")
	panel.queue_free()
	await process_frame

	var malformed_execution_state: Dictionary = {"executions": [], "result_state": {}, "mission_runs": {}}
	var envelope: Dictionary = PlayerSaveEnvelopeStoreScript.make_envelope([], [], malformed_execution_state, {}, {}, {}, {})
	var save_result: Dictionary = PlayerSaveEnvelopeStoreScript.new(PLAYER_SAVE_PATH).save(envelope)
	_expect(bool(save_result["is_saved"]), "outer envelope with invalid execution state must remain writable for recovery validation")
	var execution_file: FileAccess = FileAccess.open(PLAYER_SAVE_PATH, FileAccess.READ)
	var original_execution_payload: String = execution_file.get_as_text()
	execution_file.close()
	var execution_panel: StarterMissionFlowPanel = StarterMissionFlowPanelScene.instantiate() as StarterMissionFlowPanel
	execution_panel.player_save_store_path = PLAYER_SAVE_PATH
	root.add_child(execution_panel)
	_expect(execution_panel._is_recovery_hold, "invalid execution state inside a valid envelope must enter recovery hold")
	_expect(execution_panel.status_label.text == "錯誤：execution_state_store_data_invalid", "execution-state recovery hold must expose the validation error")
	_expect(execution_panel.start_button.disabled and execution_panel.claim_button.disabled and execution_panel.refresh_button.disabled and execution_panel.explore_territory_button.disabled, "execution-state recovery hold must disable state-changing actions")
	var loaded_execution_file: FileAccess = FileAccess.open(PLAYER_SAVE_PATH, FileAccess.READ)
	var preserved_execution_payload: String = loaded_execution_file.get_as_text()
	loaded_execution_file.close()
	_expect(preserved_execution_payload == original_execution_payload, "execution-state recovery hold must never overwrite the valid outer envelope")
	execution_panel.queue_free()
	await process_frame

	var valid_execution_state: Dictionary = {"executions": {}, "result_state": {}, "mission_runs": {}}
	var invalid_crew_envelope: Dictionary = PlayerSaveEnvelopeStoreScript.make_envelope([{"id": "crew_01", "status": 99}], [], valid_execution_state, {}, {}, {}, {})
	var crew_save_result: Dictionary = PlayerSaveEnvelopeStoreScript.new(PLAYER_SAVE_PATH).save(invalid_crew_envelope)
	_expect(bool(crew_save_result["is_saved"]), "outer envelope with invalid crew data must remain writable for recovery validation")
	var crew_file: FileAccess = FileAccess.open(PLAYER_SAVE_PATH, FileAccess.READ)
	var original_crew_payload: String = crew_file.get_as_text()
	crew_file.close()
	var crew_panel: StarterMissionFlowPanel = StarterMissionFlowPanelScene.instantiate() as StarterMissionFlowPanel
	crew_panel.player_save_store_path = PLAYER_SAVE_PATH
	root.add_child(crew_panel)
	_expect(crew_panel._is_recovery_hold, "invalid crew data inside a valid envelope must enter recovery hold")
	_expect(crew_panel.status_label.text == "錯誤：crew_restore_invalid", "crew recovery hold must expose the validation error")
	_expect(crew_panel.start_button.disabled and crew_panel.claim_button.disabled and crew_panel.refresh_button.disabled and crew_panel.explore_territory_button.disabled, "crew recovery hold must disable state-changing actions")
	var loaded_crew_file: FileAccess = FileAccess.open(PLAYER_SAVE_PATH, FileAccess.READ)
	var preserved_crew_payload: String = loaded_crew_file.get_as_text()
	loaded_crew_file.close()
	_expect(preserved_crew_payload == original_crew_payload, "crew recovery hold must never overwrite the valid outer envelope")
	crew_panel.queue_free()
	await process_frame

	var valid_crew: Array = []
	for index: int in range(5):
		valid_crew.append({"id": "crew_%02d" % (index + 1), "status": 0})
	var invalid_refresh_envelope: Dictionary = PlayerSaveEnvelopeStoreScript.make_envelope(valid_crew, [], valid_execution_state, {}, {}, {}, {})
	var refresh_save_result: Dictionary = PlayerSaveEnvelopeStoreScript.new(PLAYER_SAVE_PATH).save(invalid_refresh_envelope)
	_expect(bool(refresh_save_result["is_saved"]), "outer envelope with invalid refresh state must remain writable for recovery validation")
	var refresh_file: FileAccess = FileAccess.open(PLAYER_SAVE_PATH, FileAccess.READ)
	var original_refresh_payload: String = refresh_file.get_as_text()
	refresh_file.close()
	var refresh_panel: StarterMissionFlowPanel = StarterMissionFlowPanelScene.instantiate() as StarterMissionFlowPanel
	refresh_panel.player_save_store_path = PLAYER_SAVE_PATH
	root.add_child(refresh_panel)
	_expect(refresh_panel._is_recovery_hold, "invalid refresh state inside a valid envelope must enter recovery hold")
	_expect(refresh_panel.status_label.text == "錯誤：mission_refresh_state_invalid", "refresh recovery hold must expose the validation error")
	var loaded_refresh_file: FileAccess = FileAccess.open(PLAYER_SAVE_PATH, FileAccess.READ)
	var preserved_refresh_payload: String = loaded_refresh_file.get_as_text()
	loaded_refresh_file.close()
	_expect(preserved_refresh_payload == original_refresh_payload, "refresh recovery hold must never overwrite the valid outer envelope")
	refresh_panel.queue_free()
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("StarterMissionFlowPanelRecoveryHold test failed: %s" % message)

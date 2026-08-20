extends SceneTree

const StarterMissionFlowPanelScene = preload("res://scenes/starter_mission_flow_panel.tscn")

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
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("StarterMissionFlowPanelRecoveryHold test failed: %s" % message)

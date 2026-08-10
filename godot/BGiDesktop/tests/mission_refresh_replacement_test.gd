extends SceneTree

const StarterMissionCatalogScript = preload("res://scripts/starter_mission_catalog.gd")
const MissionRefreshReplacementScript = preload("res://scripts/mission_refresh_replacement.gd")

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var catalog := StarterMissionCatalogScript.new()
	root.add_child(catalog)
	var current_missions: Array[Dictionary] = catalog.get_missions()
	var original_missions: Array[Dictionary] = current_missions.duplicate(true)
	var replacement_for_accepted := {"id": "replacement_01", "duration_seconds": 5, "is_accepted": false}
	var replacement_for_unaccepted := {"id": "replacement_02", "duration_seconds": 10, "is_accepted": false}
	var replacements: Dictionary = {
		"starter_01": replacement_for_accepted,
		"starter_02": replacement_for_unaccepted,
	}
	var refreshed_missions: Array[Dictionary] = MissionRefreshReplacementScript.replace_unaccepted_missions(current_missions, ["starter_01"], replacements)

	_expect(refreshed_missions[0] == original_missions[0], "已接受任務必須完全保留")
	_expect(refreshed_missions[1] == replacement_for_unaccepted, "未接受且提供替換資料的任務必須替換")
	_expect(refreshed_missions[2] == original_missions[2], "未提供替換資料的任務必須保留")
	_expect(current_missions == original_missions, "替換規則不得改變目前任務")
	refreshed_missions[1]["id"] = "external_copy"
	_expect(current_missions == original_missions, "替換輸出必須與目前任務資料隔離")

	catalog.queue_free()
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionRefreshReplacement 測試失敗：%s" % message)

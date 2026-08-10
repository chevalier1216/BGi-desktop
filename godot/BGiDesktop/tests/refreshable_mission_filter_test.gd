extends SceneTree

const StarterMissionCatalogScript = preload("res://scripts/starter_mission_catalog.gd")
const RefreshableMissionFilterScript = preload("res://scripts/refreshable_mission_filter.gd")

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var catalog := StarterMissionCatalogScript.new()
	root.add_child(catalog)
	var missions: Array[Dictionary] = catalog.get_missions()
	var original_missions: Array[Dictionary] = missions.duplicate(true)
	var refreshable_missions: Array[Dictionary] = RefreshableMissionFilterScript.get_refreshable_missions(missions, ["starter_01", "starter_03"])

	_expect(refreshable_missions.size() == 21, "已接受兩項時只應保留 21 項可刷新任務")
	for mission: Dictionary in refreshable_missions:
		_expect(mission["id"] != "starter_01" and mission["id"] != "starter_03", "已接受任務必須排除於可刷新清單")
	_expect(missions == original_missions, "篩選不得改變既有任務清單")
	refreshable_missions[0]["id"] = "external_copy"
	_expect(missions == original_missions, "篩選輸出必須與原任務資料隔離")

	catalog.queue_free()
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("RefreshableMissionFilter 測試失敗：%s" % message)

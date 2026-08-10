extends SceneTree

const StarterMissionCatalogScript = preload("res://scripts/starter_mission_catalog.gd")
const AllowanceScript = preload("res://scripts/mission_refresh_allowance.gd")
const RefreshServiceScript = preload("res://scripts/mission_refresh_service.gd")

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var catalog := StarterMissionCatalogScript.new()
	root.add_child(catalog)
	var missions: Array[Dictionary] = catalog.get_missions()
	var replacement := {"id": "explicit_replacement", "duration_seconds": 10, "is_accepted": false}

	var successful_allowance := AllowanceScript.new(0)
	var successful_service := RefreshServiceScript.new(successful_allowance)
	var successful_result: Dictionary = successful_service.refresh(missions, ["starter_01"], {"starter_02": replacement}, 6 * 60 * 60)
	_expect(successful_result["is_refreshed"], "有額度且未接受任務有替換資料時必須刷新")
	_expect(successful_result["missions"][1] == replacement, "刷新後必須採用明確替換資料")
	_expect(successful_allowance.get_allowance() == 0, "成功刷新必須消耗 1 額度")

	var insufficient_allowance := AllowanceScript.new(0)
	var insufficient_result: Dictionary = RefreshServiceScript.new(insufficient_allowance).refresh(missions, [], {"starter_01": replacement}, 0)
	_expect(not insufficient_result["is_refreshed"], "額度不足時不得刷新")
	_expect(insufficient_allowance.get_allowance() == 0, "額度不足時不得改變額度")

	var no_replacement_allowance := AllowanceScript.new(0)
	var no_replacement_result: Dictionary = RefreshServiceScript.new(no_replacement_allowance).refresh(missions, [], {}, 6 * 60 * 60)
	_expect(not no_replacement_result["is_refreshed"], "沒有替換資料時不得刷新")
	_expect(no_replacement_allowance.get_allowance() == 1, "沒有可替換任務時不得消耗額度")

	var accepted_only_allowance := AllowanceScript.new(0)
	var accepted_only_result: Dictionary = RefreshServiceScript.new(accepted_only_allowance).refresh(missions, ["starter_01"], {"starter_01": replacement}, 6 * 60 * 60)
	_expect(not accepted_only_result["is_refreshed"], "只有已接受任務替換資料時不得刷新")
	_expect(accepted_only_allowance.get_allowance() == 1, "只有已接受任務替換資料時不得消耗額度")

	catalog.queue_free()
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionRefreshService 測試失敗：%s" % message)

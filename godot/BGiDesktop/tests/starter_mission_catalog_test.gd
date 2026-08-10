extends SceneTree

const StarterMissionCatalogScript = preload("res://scripts/starter_mission_catalog.gd")
const EXPECTED_DURATION_COUNTS: Dictionary = {
	5: 2,
	10: 3,
	30: 4,
	60: 2,
	180: 4,
	600: 5,
	900: 3,
}

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var catalog := StarterMissionCatalogScript.new()
	root.add_child(catalog)
	var before_refresh: Array[Dictionary] = catalog.get_missions()

	_expect(before_refresh.size() == 23, "固定目錄必須有 23 項")
	_expect(_duration_counts(before_refresh) == EXPECTED_DURATION_COUNTS, "固定時長分布不符")
	for mission: Dictionary in before_refresh:
		_expect(not bool(mission["is_accepted"]), "新手固定任務初始必須未接受")

	var refreshed: Array[Dictionary] = catalog.refresh_unaccepted_missions()
	var after_refresh: Array[Dictionary] = catalog.get_missions()
	_expect(refreshed == before_refresh, "刷新不得替換未接受任務")
	_expect(after_refresh == before_refresh, "刷新不得改變固定目錄")

	catalog.queue_free()
	quit(1 if _failed else 0)

func _duration_counts(missions: Array[Dictionary]) -> Dictionary:
	var counts: Dictionary = {}
	for mission: Dictionary in missions:
		var duration_seconds: int = int(mission["duration_seconds"])
		counts[duration_seconds] = int(counts.get(duration_seconds, 0)) + 1
	return counts

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("StarterMissionCatalog 測試失敗：%s" % message)

extends SceneTree

const StarterMissionCatalogScript = preload("res://scripts/starter_mission_catalog.gd")
const TutorialTaskProgressionScript = preload("res://scripts/tutorial_task_progression.gd")

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var catalog := StarterMissionCatalogScript.new()
	root.add_child(catalog)
	var missions: Array[Dictionary] = catalog.get_missions()
	missions[0]["is_accepted"] = true
	var progression := TutorialTaskProgressionScript.new(missions)

	var first_task: Dictionary = progression.get_current_task()
	_expect(first_task["id"] == "starter_01", "目前任務必須遵循既有目錄的第一項")
	_expect(bool(first_task["is_accepted"]), "已接受任務必須保留為目前任務，不得被替換")
	_expect_result(progression.complete_current_task("starter_02"), false, "task_not_current")
	_expect(progression.get_current_task()["id"] == "starter_01", "非目前任務完成不得推進或替換目前任務")
	_expect_result(progression.complete_current_task("starter_01"), true, "")
	_expect(progression.get_current_task()["id"] == "starter_02", "只有目前任務完成後才可推進下一項")

	catalog.queue_free()
	quit(1 if _failed else 0)

func _expect_result(result: Dictionary, expected_advanced: bool, expected_error: String) -> void:
	_expect(result.get("is_advanced") == expected_advanced and result.get("error_code") == expected_error, "新手進度結果不符：%s" % result)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("TutorialTaskProgression 測試失敗：%s" % message)

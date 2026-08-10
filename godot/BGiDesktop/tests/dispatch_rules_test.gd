extends SceneTree

const DispatchRulesModel = preload("res://scripts/dispatch_rules.gd")

var _failed := false

func _init() -> void:
	var crew: Array[Dictionary] = [
		{"id": "crew_01", "status": "available"},
		{"id": "crew_02", "status": "available"},
		{"id": "crew_03", "status": "available"},
		{"id": "crew_04", "status": "available"},
		{"id": "crew_05", "status": "dispatched"},
	]

	_expect_result(DispatchRulesModel.validate_assignment(crew, ["crew_01", "crew_02"]), true, "")
	_expect_result(DispatchRulesModel.validate_assignment(crew, []), false, "team_too_small")
	_expect_result(DispatchRulesModel.validate_assignment(crew, ["crew_01", "crew_02", "crew_03", "crew_04", "crew_05", "crew_06"]), false, "team_too_large")
	_expect_result(DispatchRulesModel.validate_assignment(crew, ["crew_99"]), false, "crew_not_found")
	_expect_result(DispatchRulesModel.validate_assignment(crew, ["crew_05"]), false, "crew_not_available")
	_expect_result(DispatchRulesModel.validate_assignment(crew, ["crew_01", "crew_01"]), false, "duplicate_assignee")

	quit(1 if _failed else 0)

func _expect_result(result: Dictionary, expected_valid: bool, expected_error: String) -> void:
	if result.get("is_valid") != expected_valid or result.get("error_code") != expected_error:
		_failed = true
		push_error("DispatchRules 測試失敗：%s" % result)

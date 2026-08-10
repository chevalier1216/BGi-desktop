extends SceneTree

const MissionRefreshAllowanceScript = preload("res://scripts/mission_refresh_allowance.gd")

var _failed := false

func _init() -> void:
	var allowance := MissionRefreshAllowanceScript.new(0)
	_expect(allowance.get_allowance() == 0, "初始刷新額度必須為 0")
	_expect(allowance.update(6 * 60 * 60 - 1) == 0, "未滿 6 小時不得補充額度")
	_expect(allowance.update(6 * 60 * 60) == 1, "剛滿 6 小時必須補充 1 次額度")
	_expect(allowance.update(12 * 60 * 60) == 1, "已滿額時不得累積超過上限")
	_expect(allowance.consume(12 * 60 * 60), "有額度時必須可消耗")
	_expect(allowance.get_allowance() == 0, "消耗後額度必須為 0")
	_expect(allowance.update(18 * 60 * 60) == 1, "消耗後再滿 6 小時必須重新補充")

	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionRefreshAllowance 測試失敗：%s" % message)

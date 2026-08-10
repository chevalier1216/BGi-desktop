extends SceneTree

const MissionExecutionClockScript = preload("res://scripts/mission_execution_clock.gd")

var _failed := false

func _init() -> void:
	var short_clock := MissionExecutionClockScript.new("starter_01", 100, 5)
	_expect(short_clock.get_remaining_seconds(100) == 5, "開始時必須保留完整時長")
	_expect(not short_clock.is_completed(100), "開始時不得完成")
	_expect(short_clock.get_remaining_seconds(105) == 0, "剛好到期時剩餘秒數必須為 0")
	_expect(short_clock.is_completed(105), "剛好到期時必須完成")
	_expect(short_clock.get_remaining_seconds(108) == 0, "逾時後剩餘秒數不得為負")
	_expect(short_clock.is_completed(108), "逾時後必須維持完成")

	var long_clock := MissionExecutionClockScript.new("starter_23", 200, 900)
	_expect(long_clock.get_remaining_seconds(200) == 900, "不同任務時長必須保留各自完整時長")
	_expect(long_clock.get_remaining_seconds(650) == 450, "不同任務時長必須正確扣除經過秒數")
	_expect(long_clock.get_remaining_seconds(199) == 900, "開始前查詢必須限制為完整時長")
	_expect(not long_clock.is_completed(1099), "尚未到期時不得完成")
	_expect(long_clock.is_completed(1100), "到期時必須完成")

	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionExecutionClock 測試失敗：%s" % message)

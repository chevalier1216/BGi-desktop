extends SceneTree

const MissionExecutionClockScript = preload("res://scripts/mission_execution_clock.gd")
const MissionExecutionSnapshotScript = preload("res://scripts/mission_execution_snapshot.gd")

var _failed := false

func _init() -> void:
	var before_close_clock := MissionExecutionClockScript.new("starter_01", 100, 5)
	var snapshot := MissionExecutionSnapshotScript.new("starter_01", 100, 5)
	var restored_snapshot: Variant = MissionExecutionSnapshotScript.from_data(snapshot.to_data())
	var restored_clock: Variant = restored_snapshot.restore_clock()

	_expect(restored_snapshot.task_id == "starter_01", "快照必須保存任務 ID")
	_expect(restored_snapshot.started_at_seconds == 100, "快照必須保存開始時間")
	_expect(restored_snapshot.duration_seconds == 5, "快照必須保存任務時長")
	_expect(restored_clock.get_remaining_seconds(104) == before_close_clock.get_remaining_seconds(104), "重建後未到期剩餘秒數必須一致")
	_expect(not restored_clock.is_completed(104), "重建後未到期不得完成")
	_expect(restored_clock.get_remaining_seconds(105) == before_close_clock.get_remaining_seconds(105), "重建後到期剩餘秒數必須一致")
	_expect(restored_clock.is_completed(105), "重建後到期必須完成")

	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionExecutionSnapshot 測試失敗：%s" % message)

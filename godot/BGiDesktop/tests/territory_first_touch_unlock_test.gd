extends SceneTree

const TerritoryFirstTouchUnlockScript = preload("res://scripts/territory_first_touch_unlock.gd")

var _failed: bool = false

func _init() -> void:
	var saved_touches: Dictionary = {}
	var first_touch: Dictionary = TerritoryFirstTouchUnlockScript.touch("territory_01", saved_touches)
	var first_event: Dictionary = first_touch["unlock_event"]
	_expect(bool(first_touch["is_first_touch"]), "first touch must be identified")
	_expect(bool(first_touch["is_unlock_granted"]), "first touch must grant one unlock event")
	_expect(bool(first_touch["touched_territory_ids"].get("territory_01", false)), "first touch must return saved territory state")
	_expect(saved_touches.is_empty(), "input saved state must remain unchanged")
	_expect(str(first_event["territory_id"]) == "territory_01", "unlock event must identify its territory")
	_expect(int(first_event["unlocked_crew_count"]) == 1, "unlock event must grant exactly one crew member")

	var repeat_touch: Dictionary = TerritoryFirstTouchUnlockScript.touch("territory_01", first_touch["touched_territory_ids"])
	_expect(not bool(repeat_touch["is_first_touch"]), "repeated touch must not be first touch")
	_expect(not bool(repeat_touch["is_unlock_granted"]), "repeated touch must not grant another crew member")
	_expect(Dictionary(repeat_touch["unlock_event"]).is_empty(), "repeated touch must not create an unlock event")

	var second_territory_touch: Dictionary = TerritoryFirstTouchUnlockScript.touch("territory_02", repeat_touch["touched_territory_ids"])
	_expect(bool(second_territory_touch["is_unlock_granted"]), "a different territory must grant one unlock event")
	_expect(bool(second_territory_touch["touched_territory_ids"].get("territory_01", false)), "saved state must retain the first territory")
	_expect(bool(second_territory_touch["touched_territory_ids"].get("territory_02", false)), "saved state must retain the new territory")

	var invalid_touch: Dictionary = TerritoryFirstTouchUnlockScript.touch("", second_territory_touch["touched_territory_ids"])
	_expect(str(invalid_touch["error_code"]) == "territory_id_required", "empty territory id must be rejected")
	_expect(not bool(invalid_touch["is_unlock_granted"]), "invalid touch must not grant an unlock")

	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("TerritoryFirstTouchUnlock test failed: %s" % message)

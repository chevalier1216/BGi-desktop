extends SceneTree

const ProgressionScript = preload("res://scripts/skeleton_c_playtest_progression.gd")
var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var progression := ProgressionScript.new()
	_expect(bool(progression.reset_playtest()["is_reset"]), "reset must only target the dedicated playtest state")
	_expect(progression.get_available_mission_ids().is_empty(), "no regular mission is available before the tutorial claim checkpoint")
	_expect(bool(progression.claim_tutorial_completion()["is_saved"]), "tutorial claim checkpoint must persist in the dedicated profile")
	_expect(progression.get_available_mission_ids() == [progression.EXPLORE_001, progression.TERRITORY_001], "tutorial claim must expose only the parallel Skeleton C roots")
	_expect(bool(progression.claim_mission(progression.EXPLORE_001)["is_claimed"]), "explore 001 claim must succeed")
	_expect(progression.get_available_mission_ids() == [progression.TERRITORY_001, progression.EXPLORE_002], "explore 001 claim must unlock only explore 002")
	_expect(not progression.get_available_mission_ids().has(progression.EXPLORE_003), "explore 003 must wait for both required claims")
	var territory_claim := progression.claim_mission(progression.TERRITORY_001)
	_expect(bool(territory_claim["is_claimed"]), "territory claim must succeed")
	_expect(Array(territory_claim["effects"]) == [{"effect_type": "territory_first_touch", "territory_id": "territory_03", "character_type_id": "character.worker02"}], "territory claim must use the existing fixed descriptor")
	_expect(progression.get_territory_first_touch_projection() == {"territory_id": "territory_03", "is_touched": true, "worker02_unlocked_count": 1}, "territory claim must persist the first-touch projection and one worker02 Unit")
	_expect(not progression.get_available_mission_ids().has(progression.EXPLORE_003), "territory claim alone cannot unlock explore 003")
	_expect(bool(progression.claim_mission(progression.EXPLORE_002)["is_claimed"]), "explore 002 claim must succeed")
	_expect(progression.get_available_mission_ids() == [progression.EXPLORE_003], "explore 003 must unlock only after both claims")
	var reopened := ProgressionScript.new()
	_expect(bool(reopened.load()["is_loaded"]), "dedicated playtest state must reopen")
	_expect(reopened.get_available_mission_ids() == [reopened.EXPLORE_003], "reopened profile must preserve claim-driven availability")
	_expect(ProgressionScript.STATE_PATH.begins_with("user://playtest_r01_progression_c/"), "all playtest persistence must stay in the dedicated namespace")
	_expect(ProgressionScript.FAST_DURATION_SECONDS == 1, "FAST timing preset must remain explicitly playtest-only")
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("Skeleton C playtest regression failed: %s" % message)

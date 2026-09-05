class_name SkeletonCPlaytestProgression
extends RefCounted

const PROFILE_ID := "playtest/r01-progression-c"
const STATE_PATH := "user://playtest_r01_progression_c/state.json"
const FAST_DURATION_SECONDS := 1

const EXPLORE_001 := "mission.r01.explore_001"
const EXPLORE_002 := "mission.r01.explore_002"
const EXPLORE_003 := "mission.r01.explore_003"
const TERRITORY_001 := "mission.r01.territory_001"
const TERRITORY_03 := "territory_03"
const TERRITORY_03_WORKER_UNIT_ID := "territory_territory_03_crew_01"

const ClaimEffectMappingScript = preload("res://scripts/tutorial_claim_effect_mapping.gd")

var _state: Dictionary = _initial_state()

func load() -> Dictionary:
	if not STATE_PATH.begins_with("user://playtest_r01_progression_c/"):
		return {"is_loaded": false, "error_code": "playtest_path_invalid"}
	if not FileAccess.file_exists(STATE_PATH):
		return {"is_loaded": true, "was_missing": true}
	var file := FileAccess.open(STATE_PATH, FileAccess.READ)
	if file == null:
		return {"is_loaded": false, "error_code": "playtest_state_unreadable"}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {"is_loaded": false, "error_code": "playtest_state_invalid"}
	var data := Dictionary(parsed)
	if not data.has("tutorial_claimed") or not data.has("claimed_mission_ids") or not data.has("touched_territory_ids") or not data.has("crew"):
		return {"is_loaded": false, "error_code": "playtest_state_invalid"}
	_state = {"tutorial_claimed": bool(data["tutorial_claimed"]), "claimed_mission_ids": Array(data["claimed_mission_ids"]).duplicate(), "touched_territory_ids": Dictionary(data["touched_territory_ids"]).duplicate(true), "crew": Array(data["crew"]).duplicate(true)}
	return {"is_loaded": true, "was_missing": false}

func claim_tutorial_completion() -> Dictionary:
	_state["tutorial_claimed"] = true
	return _save()

func claim_mission(mission_id: String) -> Dictionary:
	if not get_available_mission_ids().has(mission_id):
		return {"is_claimed": false, "error_code": "mission_not_available"}
	var claimed: Array = Array(_state["claimed_mission_ids"])
	if not claimed.has(mission_id):
		claimed.append(mission_id)
		_state["claimed_mission_ids"] = claimed
	var effects: Array = ClaimEffectMappingScript.for_mission_template(mission_id)
	_apply_effects(effects)
	var save_result := _save()
	return {"is_claimed": bool(save_result["is_saved"]), "error_code": str(save_result["error_code"]), "effects": effects}

func get_territory_first_touch_projection() -> Dictionary:
	var touched: Dictionary = Dictionary(_state["touched_territory_ids"])
	return {"territory_id": TERRITORY_03, "is_touched": bool(touched.get(TERRITORY_03, false)), "worker02_unlocked_count": 1 if _has_crew(TERRITORY_03_WORKER_UNIT_ID) else 0}

func get_available_mission_ids() -> Array[String]:
	var available: Array[String] = []
	if not bool(_state["tutorial_claimed"]):
		return available
	var claimed: Array = Array(_state["claimed_mission_ids"])
	if not claimed.has(EXPLORE_001):
		available.append(EXPLORE_001)
	if not claimed.has(TERRITORY_001):
		available.append(TERRITORY_001)
	if claimed.has(EXPLORE_001) and not claimed.has(EXPLORE_002):
		available.append(EXPLORE_002)
	if claimed.has(EXPLORE_002) and claimed.has(TERRITORY_001) and not claimed.has(EXPLORE_003):
		available.append(EXPLORE_003)
	return available

func reset_playtest() -> Dictionary:
	if FileAccess.file_exists(STATE_PATH):
		var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(STATE_PATH))
		if remove_error != OK:
			return {"is_reset": false, "error_code": "playtest_reset_failed"}
	_state = _initial_state()
	return {"is_reset": true, "error_code": ""}

func _save() -> Dictionary:
	var directory := DirAccess.open("user://")
	if directory == null or directory.make_dir_recursive("playtest_r01_progression_c") != OK:
		return {"is_saved": false, "error_code": "playtest_directory_unavailable"}
	var file := FileAccess.open(STATE_PATH, FileAccess.WRITE)
	if file == null:
		return {"is_saved": false, "error_code": "playtest_state_unwritable"}
	file.store_string(JSON.stringify(_state))
	return {"is_saved": true, "error_code": ""}

func _apply_effects(effects: Array) -> void:
	for effect_variant: Variant in effects:
		var effect: Dictionary = Dictionary(effect_variant)
		if str(effect.get("effect_type", "")) != "territory_first_touch" or str(effect.get("territory_id", "")) != TERRITORY_03:
			continue
		var touched: Dictionary = Dictionary(_state["touched_territory_ids"])
		if bool(touched.get(TERRITORY_03, false)):
			continue
		touched[TERRITORY_03] = true
		_state["touched_territory_ids"] = touched
		var crew: Array = Array(_state["crew"])
		crew.append({"id": TERRITORY_03_WORKER_UNIT_ID, "character_type_id": str(effect["character_type_id"]), "status": 0})
		_state["crew"] = crew

func _has_crew(crew_id: String) -> bool:
	for crew_member_variant: Variant in Array(_state["crew"]):
		if str(Dictionary(crew_member_variant).get("id", "")) == crew_id:
			return true
	return false

func _initial_state() -> Dictionary:
	var crew: Array = []
	for index in 5:
		crew.append({"id": "crew_%02d" % (index + 1), "character_type_id": "character.worker01", "status": 0})
	return {"tutorial_claimed": false, "claimed_mission_ids": [], "touched_territory_ids": {}, "crew": crew}

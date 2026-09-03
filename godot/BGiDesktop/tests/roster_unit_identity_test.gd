extends SceneTree

const GameStateScript = preload("res://scripts/game_state.gd")

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state: Node = GameStateScript.new()
	root.add_child(state)
	var initial_crew: Array[Dictionary] = state.get_crew()
	var initial_ids: Dictionary = {}
	_expect(initial_crew.size() == 5, "initial roster must contain five Units")
	for crew_member: Dictionary in initial_crew:
		var unit_id: String = str(crew_member["id"])
		_expect(not unit_id.is_empty() and not initial_ids.has(unit_id), "initial Units must have independent identities")
		initial_ids[unit_id] = true
		_expect(str(crew_member["character_type_id"]) == "character.worker01", "each initial Unit must reference worker01")
		_expect(int(crew_member["status"]) == GameStateScript.CrewStatus.AVAILABLE, "each initial Unit must be dispatchable")
	var claim_add: Dictionary = state.add_available_crew("territory_territory_02_crew_01", "character.worker01")
	_expect(bool(claim_add["is_added"]), "first valid territory claim must add one independent worker Unit")
	var roster_after_claim: Array[Dictionary] = state.get_crew()
	_expect(roster_after_claim.size() == 6, "claim roster must contain six Units")
	_expect(str(roster_after_claim[5]["id"]) == "territory_territory_02_crew_01" and str(roster_after_claim[5]["character_type_id"]) == "character.worker01", "claimed Unit must preserve independent identity and worker type")
	var legacy_roster: Array = []
	for index in 5:
		legacy_roster.append({"id": "legacy_%02d" % index, "status": GameStateScript.CrewStatus.AVAILABLE})
	var legacy_state: Node = GameStateScript.new()
	root.add_child(legacy_state)
	_expect(bool(legacy_state.restore_crew(legacy_roster)["is_restored"]), "legacy roster without type fields must restore")
	for crew_member: Dictionary in legacy_state.get_crew():
		_expect(str(crew_member["character_type_id"]) == "character.worker01", "legacy roster must migrate to worker01 type")
	state.queue_free()
	legacy_state.queue_free()
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("RosterUnitIdentity test failed: %s" % message)

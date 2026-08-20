extends SceneTree

const GameStateScript = preload("res://scripts/game_state.gd")
const MissionAssignmentStateScript = preload("res://scripts/mission_assignment_state.gd")
const AssignmentCoordinatorScript = preload("res://scripts/persistent_mission_assignment_coordinator.gd")
const ValidityQueryScript = preload("res://scripts/mission_execution_validity_query.gd")
const ExpiredReleaseServiceScript = preload("res://scripts/mission_expired_release_service.gd")
const SnapshotCollectionScript = preload("res://scripts/mission_execution_snapshot_collection.gd")
const LifecycleScript = preload("res://scripts/mission_lifecycle_coordinator.gd")
const StateStoreScript = preload("res://scripts/mission_execution_state_store.gd")
const ResultStateSnapshotScript = preload("res://scripts/mission_result_state_snapshot.gd")

const STATE_PATH: String = "user://mission_run_persistence_test.json"
var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var first: Dictionary = _create_context({})
	var crew_ids: Array[String] = ["crew_01", "crew_02"]
	var accepted: Dictionary = first["lifecycle"].accept_execution("starter_01", crew_ids, 100, 5)
	_expect(bool(accepted["is_accepted"]) and str(accepted["mission_run_id"]) == "starter_01:100", "accepted execution must create a stable mission run id")
	var store: RefCounted = StateStoreScript.new(STATE_PATH)
	_expect(bool(store.save(first["collection"], ResultStateSnapshotScript.new(), {"starter_01": crew_ids}, first["lifecycle"].get_persisted_runs())["is_saved"]), "active run must persist with its execution state")
	first["game_state"].queue_free()

	var reopened_state: Dictionary = store.load()
	var reopened: Dictionary = _create_context(Dictionary(reopened_state["mission_runs"]), reopened_state["collection"])
	_expect(bool(reopened["assignment_coordinator"].accept_assignment("starter_01", _to_crew_ids(reopened_state["crew_ids_by_task"]["starter_01"]))["is_accepted"]), "reopened run must restore its frozen crew assignment before offline completion")
	var resolved: Dictionary = reopened["lifecycle"].resolve_completed_result("starter_01", 105)
	_expect(bool(resolved["is_resolved"]), "offline completion must resolve against the restored run")
	if bool(resolved["is_resolved"]):
		_expect(str(resolved["result"]["mission_run_id"]) == "starter_01:100", "offline completion must retain the restored run id")
		_expect(str(resolved["result"]["result_id"]) == "starter_01:100:result", "offline completion must create one stable result id")
	var result_state: RefCounted = ResultStateSnapshotScript.new({"starter_01": Dictionary(resolved["result"])}, {})
	_expect(bool(store.save(reopened_state["collection"], result_state, reopened_state["crew_ids_by_task"], reopened["lifecycle"].get_persisted_runs())["is_saved"]), "completed run and fixed result must persist together")
	reopened["game_state"].queue_free()

	var restored_state: Dictionary = store.load()
	var restored: Dictionary = _create_context(Dictionary(restored_state["mission_runs"]), restored_state["collection"])
	_expect(bool(restored["assignment_coordinator"].accept_assignment("starter_01", _to_crew_ids(restored_state["crew_ids_by_task"]["starter_01"]))["is_accepted"]), "reopened completed run must restore its frozen crew assignment")
	var repeated: Dictionary = restored["lifecycle"].resolve_completed_result("starter_01", 999)
	_expect(bool(repeated["is_resolved"]) and not bool(repeated["did_resolve"]), "reopened completed run must not resolve a second result")
	_expect(str(repeated["result"]["result_id"]) == str(resolved["result"]["result_id"]), "reopened completed run must retain the original result id")
	_expect(int(repeated["result"]["resolved_at_seconds"]) == int(resolved["result"]["resolved_at_seconds"]), "reopened completed run must retain the original resolution time")
	_expect(str(repeated["result"]["guaranteed_reward"]) == str(resolved["result"]["guaranteed_reward"]) and str(repeated["result"]["extra_reward"]) == str(resolved["result"]["extra_reward"]), "reopened completed run must retain the original fixed rewards")
	var run_data: Dictionary = Dictionary(restored["lifecycle"].get_persisted_runs()["mission_runs_by_id"]["starter_01:100"])
	_expect(str(run_data["run_state"]) == "completed_pending_claim", "reopened run must retain completed-pending-claim state")
	restored["game_state"].queue_free()
	quit(1 if _failed else 0)

func _create_context(persisted_runs: Dictionary, restored_collection: RefCounted = null) -> Dictionary:
	var game_state: Node = GameStateScript.new()
	root.add_child(game_state)
	var assignment_state: RefCounted = MissionAssignmentStateScript.new()
	var assignment_coordinator: RefCounted = AssignmentCoordinatorScript.new(game_state, assignment_state)
	var expired_release_service: RefCounted = ExpiredReleaseServiceScript.new(assignment_coordinator, assignment_state, ValidityQueryScript.new())
	var collection: RefCounted = restored_collection if restored_collection != null else SnapshotCollectionScript.new()
	return {
		"game_state": game_state,
		"collection": collection,
		"assignment_coordinator": assignment_coordinator,
		"lifecycle": LifecycleScript.new(assignment_coordinator, expired_release_service, collection, null, persisted_runs),
	}

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionRunPersistence test failed: %s" % message)

func _to_crew_ids(crew_ids_variant: Variant) -> Array[String]:
	var crew_ids: Array[String] = []
	for crew_id_variant: Variant in Array(crew_ids_variant):
		crew_ids.append(str(crew_id_variant))
	return crew_ids

extends SceneTree

const GameStateScript = preload("res://scripts/game_state.gd")
const MissionAssignmentStateScript = preload("res://scripts/mission_assignment_state.gd")
const AssignmentCoordinatorScript = preload("res://scripts/persistent_mission_assignment_coordinator.gd")
const ValidityQueryScript = preload("res://scripts/mission_execution_validity_query.gd")
const ExpiredReleaseServiceScript = preload("res://scripts/mission_expired_release_service.gd")
const SnapshotCollectionScript = preload("res://scripts/mission_execution_snapshot_collection.gd")
const MissionLifecycleCoordinatorScript = preload("res://scripts/mission_lifecycle_coordinator.gd")
const ClaimReceiptStoreScript = preload("res://scripts/claim_receipt_store.gd")
const MissionExecutionStateStoreScript = preload("res://scripts/mission_execution_state_store.gd")
const MissionResultStateSnapshotScript = preload("res://scripts/mission_result_state_snapshot.gd")

const RECEIPT_PATH: String = "user://mission_run_id_state_isolation_receipts.json"

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state: Node = GameStateScript.new()
	root.add_child(game_state)
	var assignment_state: RefCounted = MissionAssignmentStateScript.new()
	var assignment_coordinator: RefCounted = AssignmentCoordinatorScript.new(game_state, assignment_state)
	var lifecycle: RefCounted = MissionLifecycleCoordinatorScript.new(
		assignment_coordinator,
		ExpiredReleaseServiceScript.new(assignment_coordinator, assignment_state, ValidityQueryScript.new()),
		SnapshotCollectionScript.new(),
		ClaimReceiptStoreScript.new(RECEIPT_PATH)
	)
	var crew_ids: Array[String] = ["crew_01"]

	var first_accept: Dictionary = lifecycle.accept_execution("starter_01", crew_ids, 100, 5)
	_expect(bool(first_accept["is_accepted"]), "first template dispatch must be accepted")
	_expect(bool(lifecycle.resolve_completed_result("starter_01", 105)["is_resolved"]), "first run must resolve")
	_expect(bool(lifecycle.claim_completed_result("starter_01", 105)["is_claimed"]), "first run must claim")

	var second_accept: Dictionary = lifecycle.accept_execution("starter_01", crew_ids, 100, 5)
	_expect(bool(second_accept["is_accepted"]), "same template may dispatch again after claim")
	_expect(str(first_accept["mission_run_id"]) != str(second_accept["mission_run_id"]), "each dispatch must receive a distinct mission_run_id")
	_expect(bool(lifecycle.resolve_completed_result("starter_01", 105)["is_resolved"]), "second run must resolve")

	var result_state: RefCounted = MissionResultStateSnapshotScript.new(
		lifecycle._locked_results_by_mission_run_id,
		lifecycle._claimed_mission_run_ids
	)
	var state_data: Dictionary = result_state.to_data()
	_expect(state_data["locked_results_by_mission_run_id"].size() == 2, "two runs of one template must retain separate locked results")
	_expect(bool(state_data["claimed_mission_run_ids"].get(str(first_accept["mission_run_id"]), false)), "first run claim must be keyed by mission_run_id")
	_expect(not bool(state_data["claimed_mission_run_ids"].get(str(second_accept["mission_run_id"]), false)), "second run must remain independently claimable")

	var payload: Dictionary = MissionExecutionStateStoreScript.make_payload(
		lifecycle._snapshot_collection,
		result_state,
		{"starter_01": crew_ids},
		lifecycle.get_persisted_runs()
	)
	_expect(payload.has("executions") and payload["executions"].has(str(second_accept["mission_run_id"])), "active execution persistence must be keyed by mission_run_id")
	_expect(not payload["executions"].has("starter_01"), "new execution persistence must not key an active run by template ID")
	var restored: Dictionary = MissionExecutionStateStoreScript.from_payload(payload)
	_expect(bool(restored["is_loaded"]), "mission_run_id payload must restore")
	_expect(not restored["collection"].get_snapshot_data(str(second_accept["mission_run_id"])).is_empty(), "restored collection must locate its run by mission_run_id")

	game_state.queue_free()
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("Mission run ID state isolation test failed: %s" % message)

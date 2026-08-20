extends SceneTree

const GameStateScript = preload("res://scripts/game_state.gd")
const MissionAssignmentStateScript = preload("res://scripts/mission_assignment_state.gd")
const AssignmentCoordinatorScript = preload("res://scripts/persistent_mission_assignment_coordinator.gd")
const ValidityQueryScript = preload("res://scripts/mission_execution_validity_query.gd")
const ExpiredReleaseServiceScript = preload("res://scripts/mission_expired_release_service.gd")
const SnapshotCollectionScript = preload("res://scripts/mission_execution_snapshot_collection.gd")
const MissionLifecycleCoordinatorScript = preload("res://scripts/mission_lifecycle_coordinator.gd")
const ClaimReceiptStoreScript = preload("res://scripts/claim_receipt_store.gd")

const RECEIPT_PATH: String = "user://mission_lifecycle_coordinator_test_receipts.json"

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state: Node = GameStateScript.new()
	root.add_child(game_state)
	var assignment_state: RefCounted = MissionAssignmentStateScript.new()
	var assignment_coordinator: RefCounted = AssignmentCoordinatorScript.new(game_state, assignment_state)
	var validity_query: RefCounted = ValidityQueryScript.new()
	var expired_release_service: RefCounted = ExpiredReleaseServiceScript.new(assignment_coordinator, assignment_state, validity_query)
	var snapshot_collection: RefCounted = SnapshotCollectionScript.new()
	var lifecycle: RefCounted = MissionLifecycleCoordinatorScript.new(assignment_coordinator, expired_release_service, snapshot_collection, ClaimReceiptStoreScript.new(RECEIPT_PATH))
	var crew_ids: Array[String] = ["crew_01"]

	var accept_result: Dictionary = lifecycle.accept_execution("starter_01", crew_ids, 100, 5)
	_expect(bool(accept_result["is_accepted"]), "execution acceptance must assign crew and add a snapshot")
	_expect(_status_for(game_state.get_crew(), "crew_01") == GameStateScript.ASSIGNED_STATUS, "accepted execution must dispatch crew")
	_expect(not snapshot_collection.get_snapshot_data("starter_01").is_empty(), "accepted execution must retain its snapshot")

	var pending_result: Dictionary = lifecycle.resolve_completed_result("starter_01", 104)
	_expect(not bool(pending_result["is_resolved"]), "unfinished execution must not lock a result")
	_expect(str(pending_result["error_code"]) == "execution_not_completed", "unfinished result resolution must identify its state")

	var resolved_result: Dictionary = lifecycle.resolve_completed_result("starter_01", 105)
	_expect(bool(resolved_result["is_resolved"]), "expired execution must lock a result")
	_expect(bool(resolved_result["did_resolve"]), "first completed resolution must lock the result once")
	_expect(str(resolved_result["result"]["guaranteed_reward"]) == "[PLACEHOLDER]", "locked result must preserve placeholder reward")

	var first_claim: Dictionary = lifecycle.claim_completed_result("starter_01", 105)
	_expect(bool(first_claim["is_claimed"]), "locked completed result must claim once")
	_expect(first_claim["result"] == resolved_result["result"], "claim must return the locked result unchanged")
	_expect(_status_for(game_state.get_crew(), "crew_01") == GameStateScript.CrewStatus.AVAILABLE, "successful claim must release crew")
	_expect(assignment_state.get_assigned_crew_ids("starter_01").is_empty(), "successful claim must release assignment")
	_expect(snapshot_collection.restore_clock("starter_01") == null, "successful claim must remove execution snapshot")
	_expect(not Dictionary(lifecycle.get_persisted_runs()["active_run_id_by_task_id"]).has("starter_01"), "claimed run must no longer remain active")

	var repeated_claim: Dictionary = lifecycle.claim_completed_result("starter_01", 106)
	_expect(bool(repeated_claim["is_claimed"]) and not bool(repeated_claim["did_claim"]), "repeated claim must return the existing receipt without a second transaction")
	_expect(Dictionary(repeated_claim["receipt"]) == Dictionary(first_claim["receipt"]), "repeated claim must preserve the original receipt")

	game_state.queue_free()
	quit(1 if _failed else 0)

func _status_for(crew: Array[Dictionary], crew_id: String) -> int:
	for crew_member: Dictionary in crew:
		if str(crew_member["id"]) == crew_id:
			return int(crew_member["status"])
	return -1

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionLifecycleCoordinator test failed: %s" % message)

extends SceneTree

const GameStateScript = preload("res://scripts/game_state.gd")
const MissionAssignmentStateScript = preload("res://scripts/mission_assignment_state.gd")
const AssignmentCoordinatorScript = preload("res://scripts/persistent_mission_assignment_coordinator.gd")
const ValidityQueryScript = preload("res://scripts/mission_execution_validity_query.gd")
const ExpiredReleaseServiceScript = preload("res://scripts/mission_expired_release_service.gd")
const SnapshotCollectionScript = preload("res://scripts/mission_execution_snapshot_collection.gd")
const LifecycleScript = preload("res://scripts/mission_lifecycle_coordinator.gd")
const ClaimReceiptStoreScript = preload("res://scripts/claim_receipt_store.gd")
const ClaimReceiptScript = preload("res://scripts/claim_receipt.gd")

const RECEIPT_PATH: String = "user://mission_claim_receipt_integration_test.json"
const FAILING_RECEIPT_PATH: String = "user://missing_receipt_directory/receipt.json"
const LEGACY_RECEIPT_PATH: String = "user://mission_claim_receipt_legacy_test.json"

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var first: Dictionary = _create_lifecycle(RECEIPT_PATH)
	var first_crew_ids: Array[String] = ["crew_01"]
	_expect(bool(first["lifecycle"].accept_execution("starter_01", first_crew_ids, 100, 5)["is_accepted"]), "first task must be accepted")
	var initial_claim: Dictionary = first["lifecycle"].claim_completed_result("starter_01", 105)
	_expect(bool(initial_claim["is_claimed"]) and bool(initial_claim["did_claim"]), "first completed claim must create one receipt")
	var receipt: Dictionary = Dictionary(initial_claim["receipt"])
	_expect(str(receipt["claim_receipt_id"]) == "starter_01:100:claim", "receipt id must be deterministic for the mission run")
	_expect(str(receipt["mission_run_id"]) == "starter_01:100", "receipt must retain the mission run id")
	_expect(str(receipt["result_id"]) == "starter_01:100:result", "receipt must reference the fixed result id")
	_expect(int(receipt["claimed_at_seconds"]) == 105, "receipt must retain the first claim time")
	_expect(Array(receipt["applied_effect_ids"]).is_empty(), "new receipt must not invent any effects")
	_expect(first["snapshot_collection"].restore_clock("starter_01") == null, "receipt save before release must permit clock cleanup only after success")

	var repeat_claim: Dictionary = first["lifecycle"].claim_completed_result("starter_01", 999)
	_expect(bool(repeat_claim["is_claimed"]) and not bool(repeat_claim["did_claim"]), "repeated claim must return the existing receipt")
	_expect(Dictionary(repeat_claim["receipt"]) == receipt, "repeated claim must not replace the receipt")

	var reopened: Dictionary = _create_lifecycle(RECEIPT_PATH, first["lifecycle"].get_persisted_runs())
	var reopened_claim: Dictionary = reopened["lifecycle"].claim_completed_result("starter_01", 1200)
	_expect(bool(reopened_claim["is_claimed"]) and not bool(reopened_claim["did_claim"]), "reopened claim must return the persisted receipt")
	_expect(Dictionary(reopened_claim["receipt"]) == receipt, "reopened claim must preserve the same receipt")

	var second_run: Dictionary = _create_lifecycle(RECEIPT_PATH)
	_expect(bool(second_run["lifecycle"].accept_execution("starter_01", first_crew_ids, 200, 5)["is_accepted"]), "same template must allow a later distinct mission run")
	var second_claim: Dictionary = second_run["lifecycle"].claim_completed_result("starter_01", 205)
	_expect(bool(second_claim["is_claimed"]) and bool(second_claim["did_claim"]), "later mission run must create its own receipt")
	_expect(str(Dictionary(second_claim["receipt"])["mission_run_id"]) == "starter_01:200", "later receipt must use the later mission run id")
	_expect(Dictionary(second_claim["receipt"]) != receipt, "two mission runs of one template must not share a receipt")

	var failing: Dictionary = _create_lifecycle(FAILING_RECEIPT_PATH)
	var failing_crew_ids: Array[String] = ["crew_01"]
	_expect(bool(failing["lifecycle"].accept_execution("starter_02", failing_crew_ids, 200, 5)["is_accepted"]), "failing-store task must be accepted")
	var failed_claim: Dictionary = failing["lifecycle"].claim_completed_result("starter_02", 205)
	_expect(not bool(failed_claim["is_claimed"]), "receipt write failure must reject claim")
	_expect(str(failed_claim["error_code"]) == "claim_receipt_store_write_failed", "receipt write failure must be reported")
	_expect(failing["snapshot_collection"].restore_clock("starter_02") != null, "receipt write failure must retain the execution clock")
	_expect(_status_for(failing["game_state"].get_crew(), "crew_01") == GameStateScript.CrewStatus.AVAILABLE, "receipt write failure must keep crew available while the result remains claimable")

	var legacy_receipt_result: Dictionary = ClaimReceiptScript.create("starter_01:300:claim", "starter_01:300", "starter_01:300:result", 305)
	var legacy_file: FileAccess = FileAccess.open(LEGACY_RECEIPT_PATH, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify({"receipts_by_task_id": {"starter_01": legacy_receipt_result["receipt"]}}))
	legacy_file.close()
	var legacy_lookup: Dictionary = ClaimReceiptStoreScript.new(LEGACY_RECEIPT_PATH).get_receipt("starter_01:300")
	_expect(bool(legacy_lookup["is_found"]), "legacy task-key receipt data must restore by its embedded mission run id")
	_expect(Dictionary(legacy_lookup["receipt"]) == Dictionary(legacy_receipt_result["receipt"]), "legacy receipt migration must preserve the original receipt")

	for context: Dictionary in [first, reopened, second_run, failing]:
		context["game_state"].queue_free()
	quit(1 if _failed else 0)

func _create_lifecycle(receipt_path: String, persisted_runs: Dictionary = {}) -> Dictionary:
	var game_state: Node = GameStateScript.new()
	root.add_child(game_state)
	var assignment_state: RefCounted = MissionAssignmentStateScript.new()
	var assignment_coordinator: RefCounted = AssignmentCoordinatorScript.new(game_state, assignment_state)
	var validity_query: RefCounted = ValidityQueryScript.new()
	var expired_release_service: RefCounted = ExpiredReleaseServiceScript.new(assignment_coordinator, assignment_state, validity_query)
	var snapshot_collection: RefCounted = SnapshotCollectionScript.new()
	var receipt_store: RefCounted = ClaimReceiptStoreScript.new(receipt_path)
	return {
		"game_state": game_state,
		"snapshot_collection": snapshot_collection,
		"lifecycle": LifecycleScript.new(assignment_coordinator, expired_release_service, snapshot_collection, receipt_store, persisted_runs),
	}

func _status_for(crew: Array[Dictionary], crew_id: String) -> int:
	for crew_member: Dictionary in crew:
		if str(crew_member["id"]) == crew_id:
			return int(crew_member["status"])
	return -1

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionClaimReceiptIntegration test failed: %s" % message)

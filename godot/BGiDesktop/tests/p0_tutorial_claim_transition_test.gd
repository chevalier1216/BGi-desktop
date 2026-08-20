extends SceneTree

const GameStateScript = preload("res://scripts/game_state.gd")
const StarterMissionCatalogScript = preload("res://scripts/starter_mission_catalog.gd")
const MissionAssignmentStateScript = preload("res://scripts/mission_assignment_state.gd")
const AssignmentCoordinatorScript = preload("res://scripts/persistent_mission_assignment_coordinator.gd")
const ValidityQueryScript = preload("res://scripts/mission_execution_validity_query.gd")
const ExpiredReleaseServiceScript = preload("res://scripts/mission_expired_release_service.gd")
const SnapshotCollectionScript = preload("res://scripts/mission_execution_snapshot_collection.gd")
const LifecycleScript = preload("res://scripts/mission_lifecycle_coordinator.gd")
const ClaimReceiptStoreScript = preload("res://scripts/claim_receipt_store.gd")
const TutorialTaskProgressionScript = preload("res://scripts/tutorial_task_progression.gd")
const TutorialCompletionScript = preload("res://scripts/tutorial_mission_completion_coordinator.gd")

const RECEIPT_PATH: String = "user://p0_tutorial_claim_transition_test.json"
var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var game_state: Node = GameStateScript.new()
	var catalog: Node = StarterMissionCatalogScript.new()
	root.add_child(game_state)
	root.add_child(catalog)
	var assignment_state: RefCounted = MissionAssignmentStateScript.new()
	var assignment_coordinator: RefCounted = AssignmentCoordinatorScript.new(game_state, assignment_state)
	var validity_query: RefCounted = ValidityQueryScript.new()
	var completion_service: RefCounted = ExpiredReleaseServiceScript.new(assignment_coordinator, assignment_state, validity_query)
	var lifecycle: RefCounted = LifecycleScript.new(assignment_coordinator, completion_service, SnapshotCollectionScript.new(), ClaimReceiptStoreScript.new(RECEIPT_PATH))
	var progression: RefCounted = TutorialTaskProgressionScript.new(catalog.get_missions())
	var tutorial: RefCounted = TutorialCompletionScript.new(progression, assignment_state, validity_query)
	var crew_ids: Array[String] = ["crew_01"]

	_expect(bool(lifecycle.accept_execution("starter_01", crew_ids, 100, 5)["is_accepted"]), "tutorial task must be accepted")
	var resolved: Dictionary = lifecycle.resolve_completed_result("starter_01", 105)
	_expect(bool(resolved["is_resolved"]), "expired task must lock a pending result")
	_expect(str(progression.get_current_task()["id"]) == "starter_01", "a fixed result must not advance tutorial progression before collection")
	_expect(_status_for(game_state.get_crew(), "crew_01") == GameStateScript.CrewStatus.COMPLETED, "completion must keep crew unavailable before collection")
	_expect(not assignment_state.get_assigned_crew_ids("starter_01").is_empty(), "completion must retain the resolved task assignment before collection")

	var claim: Dictionary = lifecycle.claim_completed_result("starter_01", 105)
	_expect(bool(claim["is_claimed"]) and bool(claim["did_claim"]), "claim receipt must save before the claim transaction completes")
	_expect(bool(tutorial.complete_claimed_current_task("starter_01", Dictionary(claim["receipt"]))["is_completed"]), "a saved claim receipt must advance tutorial progression")
	_expect(str(progression.get_current_task()["id"]) == "starter_02", "claim must advance to the next fixed tutorial task")
	_expect(_status_for(game_state.get_crew(), "crew_01") == GameStateScript.CrewStatus.AVAILABLE, "successful claim must keep crew available")

	game_state.queue_free()
	catalog.queue_free()
	quit(1 if _failed else 0)

func _status_for(crew: Array[Dictionary], crew_id: String) -> int:
	for crew_member: Dictionary in crew:
		if str(crew_member["id"]) == crew_id:
			return int(crew_member["status"])
	return -1

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("P0TutorialClaimTransition test failed: %s" % message)

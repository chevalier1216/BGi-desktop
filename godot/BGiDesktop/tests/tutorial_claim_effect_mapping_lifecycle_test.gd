extends SceneTree

const GameStateScript = preload("res://scripts/game_state.gd")
const AssignmentStateScript = preload("res://scripts/mission_assignment_state.gd")
const AssignmentCoordinatorScript = preload("res://scripts/persistent_mission_assignment_coordinator.gd")
const ValidityQueryScript = preload("res://scripts/mission_execution_validity_query.gd")
const ExpiredReleaseScript = preload("res://scripts/mission_expired_release_service.gd")
const SnapshotCollectionScript = preload("res://scripts/mission_execution_snapshot_collection.gd")
const LifecycleScript = preload("res://scripts/mission_lifecycle_coordinator.gd")
const ReceiptStoreScript = preload("res://scripts/claim_receipt_store.gd")

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var state: Node = GameStateScript.new()
	root.add_child(state)
	var assignments: RefCounted = AssignmentStateScript.new()
	var coordinator: RefCounted = AssignmentCoordinatorScript.new(state, assignments)
	var lifecycle: RefCounted = LifecycleScript.new(coordinator, ExpiredReleaseScript.new(coordinator, assignments, ValidityQueryScript.new()), SnapshotCollectionScript.new(), ReceiptStoreScript.new("user://tutorial_claim_effect_mapping_lifecycle_test.json"))
	_expect(bool(lifecycle.accept_execution("starter_18", ["crew_01"], 100, 5)["is_accepted"]), "starter_18 must accept")
	var result: Dictionary = lifecycle.resolve_completed_result("starter_18", 105)
	var expected: Dictionary = {"effect_type": "territory_first_touch", "territory_id": "territory_02", "character_id": "character_06"}
	_expect(Array(result["result"]["claim_effect_descriptors"]) == [expected], "completion must snapshot the approved first-touch descriptor")
	var claim: Dictionary = lifecycle.claim_completed_result("starter_18", 105)
	_expect(Array(claim["receipt"]["effect_descriptors"]) == [expected], "claim receipt must copy the fixed descriptor")
	_expect(Array(lifecycle.resolve_completed_result("starter_18", 999)["result"]["claim_effect_descriptors"]) == [expected], "reload path must retain fixed descriptor")
	state.queue_free()
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("TutorialClaimEffectMappingLifecycle test failed: %s" % message)

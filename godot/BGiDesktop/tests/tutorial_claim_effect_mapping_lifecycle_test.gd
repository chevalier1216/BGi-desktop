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
	var crew_ids: Array[String] = ["crew_01"]
	_expect(bool(lifecycle.accept_execution("starter_18", crew_ids, 100, 5)["is_accepted"]), "starter_18 must accept")
	var result: Dictionary = lifecycle.resolve_completed_result("starter_18", 105)
	var expected: Dictionary = {"effect_type": "territory_first_touch", "territory_id": "territory_02", "character_id": "character_06"}
	_expect(Array(result["result"]["claim_effect_descriptors"]) == [expected], "completion must snapshot the approved first-touch descriptor")
	var replayed_result: Dictionary = lifecycle.resolve_completed_result("starter_18", 999)
	_expect(Array(replayed_result["result"]["claim_effect_descriptors"]) == [expected], "reload path must retain fixed descriptor")
	var claim: Dictionary = lifecycle.claim_completed_result("starter_18", 105)
	_expect(Array(claim["receipt"]["effect_descriptors"]) == [expected], "claim receipt must copy the fixed descriptor")
	var explore_lifecycle: RefCounted = LifecycleScript.new(coordinator, ExpiredReleaseScript.new(coordinator, assignments, ValidityQueryScript.new()), SnapshotCollectionScript.new(), ReceiptStoreScript.new("user://explore_poster_claim_effect_mapping_lifecycle_test.json"))
	var explore_expected: Dictionary = {"effect_type": "collectible_grant", "collectible_id": "collectible.r01.poster_001", "quantity": 1}
	_expect(bool(explore_lifecycle.accept_execution("mission.r01.explore_001", crew_ids, 200, 5)["is_accepted"]), "explore_001 must accept")
	var explore_result: Dictionary = explore_lifecycle.resolve_completed_result("mission.r01.explore_001", 205)
	_expect(Array(explore_result["result"]["claim_effect_descriptors"]) == [explore_expected], "completion must snapshot the approved poster descriptor")
	var explore_replayed_result: Dictionary = explore_lifecycle.resolve_completed_result("mission.r01.explore_001", 999)
	_expect(Array(explore_replayed_result["result"]["claim_effect_descriptors"]) == [explore_expected], "reload path must retain the fixed poster descriptor")
	var explore_claim: Dictionary = explore_lifecycle.claim_completed_result("mission.r01.explore_001", 205)
	_expect(Array(explore_claim["receipt"]["effect_descriptors"]) == [explore_expected], "claim receipt must copy the fixed poster descriptor")
	var second_explore_lifecycle: RefCounted = LifecycleScript.new(coordinator, ExpiredReleaseScript.new(coordinator, assignments, ValidityQueryScript.new()), SnapshotCollectionScript.new(), ReceiptStoreScript.new("user://explore_second_poster_claim_effect_mapping_lifecycle_test.json"))
	var second_explore_expected: Dictionary = {"effect_type": "collectible_grant", "collectible_id": "collectible.r01.poster_002", "quantity": 1}
	_expect(bool(second_explore_lifecycle.accept_execution("mission.r01.explore_002", crew_ids, 300, 5)["is_accepted"]), "explore_002 must accept")
	var second_explore_result: Dictionary = second_explore_lifecycle.resolve_completed_result("mission.r01.explore_002", 305)
	_expect(Array(second_explore_result["result"]["claim_effect_descriptors"]) == [second_explore_expected], "completion must snapshot the approved second poster descriptor")
	var second_explore_replayed_result: Dictionary = second_explore_lifecycle.resolve_completed_result("mission.r01.explore_002", 999)
	_expect(Array(second_explore_replayed_result["result"]["claim_effect_descriptors"]) == [second_explore_expected], "reload path must retain the fixed second poster descriptor")
	var second_explore_claim: Dictionary = second_explore_lifecycle.claim_completed_result("mission.r01.explore_002", 305)
	_expect(Array(second_explore_claim["receipt"]["effect_descriptors"]) == [second_explore_expected], "claim receipt must copy the fixed second poster descriptor")
	state.queue_free()
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("TutorialClaimEffectMappingLifecycle test failed: %s" % message)

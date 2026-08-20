class_name MissionAbortService
extends RefCounted

var _coordinator: RefCounted
var _assignment_state: RefCounted

func _init(coordinator: RefCounted, assignment_state: RefCounted) -> void:
	_coordinator = coordinator
	_assignment_state = assignment_state

func abort(task_id: String) -> Dictionary:
	# Player-facing mission cancellation is not supported in the first playable version.
	# Keep this internal compatibility boundary non-mutating so an obsolete caller
	# cannot release an active or claimable assignment outside the claim transaction.
	return {"is_aborted": false, "error_code": "mission_cancel_not_supported"}

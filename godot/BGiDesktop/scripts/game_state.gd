extends Node

enum CrewStatus {
	AVAILABLE,
	DISPATCHED,
	COMPLETED,
}

const INITIAL_CREW_COUNT := 5
const ASSIGNED_STATUS := CrewStatus.DISPATCHED

var _crew: Array[Dictionary] = []

func _ready() -> void:
	for index in INITIAL_CREW_COUNT:
		_crew.append({
			"id": "crew_%02d" % (index + 1),
			"status": CrewStatus.AVAILABLE,
		})

func get_crew() -> Array[Dictionary]:
	return _crew.duplicate(true)

func set_crew_status(crew_id: String, status: int) -> Dictionary:
	if status != CrewStatus.AVAILABLE and status != ASSIGNED_STATUS:
		return _rejected("unsupported_status")
	for crew_member: Dictionary in _crew:
		if crew_member["id"] == crew_id:
			crew_member["status"] = status
			return {"is_updated": true, "error_code": ""}
	return _rejected("crew_not_found")

func _rejected(error_code: String) -> Dictionary:
	return {"is_updated": false, "error_code": error_code}

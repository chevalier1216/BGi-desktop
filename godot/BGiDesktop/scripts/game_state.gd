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

## Restores only a complete, uniquely identified crew set from a saved envelope.
func restore_crew(crew: Array) -> Dictionary:
	var restored: Array[Dictionary] = []
	var seen_ids: Dictionary = {}
	for crew_member_variant: Variant in crew:
		if typeof(crew_member_variant) != TYPE_DICTIONARY:
			return _rejected("crew_restore_invalid")
		var crew_member: Dictionary = Dictionary(crew_member_variant)
		var crew_id: String = str(crew_member.get("id", ""))
		var status: int = int(crew_member.get("status", -1))
		if crew_id.is_empty() or seen_ids.has(crew_id) or (status != CrewStatus.AVAILABLE and status != ASSIGNED_STATUS and status != CrewStatus.COMPLETED):
			return _rejected("crew_restore_invalid")
		seen_ids[crew_id] = true
		restored.append({"id": crew_id, "status": status})
	if restored.size() < INITIAL_CREW_COUNT:
		return _rejected("crew_restore_invalid")
	_crew = restored
	return {"is_restored": true, "error_code": ""}

func set_crew_status(crew_id: String, status: int) -> Dictionary:
	if status != CrewStatus.AVAILABLE and status != ASSIGNED_STATUS and status != CrewStatus.COMPLETED:
		return _rejected("unsupported_status")
	for crew_member: Dictionary in _crew:
		if crew_member["id"] == crew_id:
			crew_member["status"] = status
			return {"is_updated": true, "error_code": ""}
	return _rejected("crew_not_found")

## Adds one uniquely identified crew member in the available state.
func add_available_crew(crew_id: String) -> Dictionary:
	if crew_id.is_empty():
		return _rejected("crew_id_required")
	for crew_member: Dictionary in _crew:
		if str(crew_member["id"]) == crew_id:
			return _rejected("crew_id_already_exists")
	_crew.append({
		"id": crew_id,
		"status": CrewStatus.AVAILABLE,
	})
	return {"is_added": true, "error_code": ""}

func _rejected(error_code: String) -> Dictionary:
	return {"is_updated": false, "error_code": error_code}

extends Node

enum CrewStatus {
	AVAILABLE,
	DISPATCHED,
	COMPLETED,
}

const INITIAL_CREW_COUNT := 5

var _crew: Array[Dictionary] = []

func _ready() -> void:
	for index in INITIAL_CREW_COUNT:
		_crew.append({
			"id": "crew_%02d" % (index + 1),
			"status": CrewStatus.AVAILABLE,
		})

func get_crew() -> Array[Dictionary]:
	return _crew.duplicate(true)

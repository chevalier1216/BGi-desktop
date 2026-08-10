class_name TerritoryFirstTouchUnlock
extends RefCounted

const UNLOCKED_CREW_COUNT: int = 1

## Applies one territory touch without mutating the supplied saved state.
static func touch(territory_id: String, touched_territory_ids: Dictionary) -> Dictionary:
	var saved_touches: Dictionary = touched_territory_ids.duplicate(true)
	if territory_id.is_empty():
		return _rejected(saved_touches, "territory_id_required")

	if saved_touches.has(territory_id):
		return {
			"is_first_touch": false,
			"is_unlock_granted": false,
			"error_code": "",
			"touched_territory_ids": saved_touches,
			"unlock_event": {},
		}

	saved_touches[territory_id] = true
	return {
		"is_first_touch": true,
		"is_unlock_granted": true,
		"error_code": "",
		"touched_territory_ids": saved_touches,
		"unlock_event": {
			"territory_id": territory_id,
			"unlocked_crew_count": UNLOCKED_CREW_COUNT,
		},
	}

static func _rejected(saved_touches: Dictionary, error_code: String) -> Dictionary:
	return {
		"is_first_touch": false,
		"is_unlock_granted": false,
		"error_code": error_code,
		"touched_territory_ids": saved_touches,
		"unlock_event": {},
	}

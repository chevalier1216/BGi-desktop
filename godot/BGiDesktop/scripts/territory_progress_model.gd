class_name TerritoryProgressModel
extends RefCounted

const PLACEHOLDER_VALUE: String = "[PLACEHOLDER]"

## Creates a display-ready long-term territory state without assigning progression values.
static func create(territory_id: String) -> Dictionary:
	if territory_id.is_empty():
		return _rejected("territory_id_required")

	return {
		"is_valid": true,
		"error_code": "",
		"territory_id": territory_id,
		"territory_progress": PLACEHOLDER_VALUE,
		"exploration_collection_count": PLACEHOLDER_VALUE,
		"environment_decoration_owned_count": PLACEHOLDER_VALUE,
	}

## Confirms that all long-term growth fields required by a territory display exist.
static func has_required_growth_fields(territory_data: Dictionary) -> bool:
	return territory_data.has("territory_progress") \
		and territory_data.has("exploration_collection_count") \
		and territory_data.has("environment_decoration_owned_count")

static func _rejected(error_code: String) -> Dictionary:
	return {
		"is_valid": false,
		"error_code": error_code,
	}

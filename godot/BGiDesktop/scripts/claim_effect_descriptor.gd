class_name ClaimEffectDescriptor
extends RefCounted

## Validates only already-fixed effect payloads; it never resolves content mappings.
static func validate_all(effect_descriptors: Variant) -> Dictionary:
	if typeof(effect_descriptors) != TYPE_ARRAY:
		return _rejected("claim_effect_descriptors_invalid")
	var saved: Array[Dictionary] = []
	for descriptor_variant: Variant in Array(effect_descriptors):
		if typeof(descriptor_variant) != TYPE_DICTIONARY:
			return _rejected("claim_effect_descriptor_invalid")
		var parsed: Dictionary = _validate_one(Dictionary(descriptor_variant))
		if not bool(parsed["is_valid"]):
			return _rejected(str(parsed["error_code"]))
		saved.append(Dictionary(parsed["descriptor"]).duplicate(true))
	return {"is_valid": true, "error_code": "", "effect_descriptors": saved}

static func _validate_one(descriptor: Dictionary) -> Dictionary:
	var effect_type: String = str(descriptor.get("effect_type", ""))
	match effect_type:
		"territory_first_touch":
			var territory_id: String = str(descriptor.get("territory_id", ""))
			var character_type_id: String = str(descriptor.get("character_type_id", ""))
			if character_type_id.is_empty() and str(descriptor.get("character_id", "")) == "character_06":
				character_type_id = "character.worker01"
			if territory_id.is_empty() or character_type_id.is_empty():
				return _rejected("territory_first_touch_descriptor_invalid")
			return {"is_valid": true, "error_code": "", "descriptor": {"effect_type": effect_type, "territory_id": territory_id, "character_type_id": character_type_id}}
		"collectible_grant":
			var collectible_id: String = str(descriptor.get("collectible_id", ""))
			var quantity: int = int(descriptor.get("quantity", 0))
			if collectible_id.is_empty() or quantity <= 0:
				return _rejected("collectible_grant_descriptor_invalid")
			return {"is_valid": true, "error_code": "", "descriptor": {"effect_type": effect_type, "collectible_id": collectible_id, "quantity": quantity}}
		_:
			return _rejected("claim_effect_descriptor_type_invalid")

static func _rejected(error_code: String) -> Dictionary:
	return {"is_valid": false, "error_code": error_code, "descriptor": {}, "effect_descriptors": []}

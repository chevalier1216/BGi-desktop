class_name TutorialClaimEffectMapping
extends RefCounted

## Returns only authoritative completion-time descriptors for canonical tutorial IDs.
static func for_mission_template(mission_template_id: String) -> Array[Dictionary]:
	match mission_template_id:
		"starter_18":
			return [{"effect_type": "territory_first_touch", "territory_id": "territory_02", "character_type_id": "character.worker01"}]
		"starter_19":
			return [{"effect_type": "collectible_grant", "collectible_id": "collectible.r01.goldbar_001", "quantity": 1}]
		"starter_20":
			return [{"effect_type": "collectible_grant", "collectible_id": "collectible.r01.gift_001", "quantity": 1}]
		"starter_21":
			return [{"effect_type": "collectible_grant", "collectible_id": "collectible.r01.neon_001", "quantity": 1}]
		"starter_22":
			return [{"effect_type": "collectible_grant", "collectible_id": "collectible.r01.vehicle_001", "quantity": 1}]
		"starter_23":
			return [{"effect_type": "collectible_grant", "collectible_id": "collectible.r01.cityset_001", "quantity": 1}]
		"mission.r01.explore_001":
			return [{"effect_type": "collectible_grant", "collectible_id": "collectible.r01.poster_001", "quantity": 1}]
		"mission.r01.explore_002":
			return [{"effect_type": "collectible_grant", "collectible_id": "collectible.r01.poster_002", "quantity": 1}]
		"mission.r01.territory_001":
			return [{"effect_type": "territory_first_touch", "territory_id": "territory_03", "character_type_id": "character.worker02"}]
		_:
			return []

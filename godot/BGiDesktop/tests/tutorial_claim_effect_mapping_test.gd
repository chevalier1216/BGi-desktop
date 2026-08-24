extends SceneTree

const MappingScript = preload("res://scripts/tutorial_claim_effect_mapping.gd")

var _failed := false

func _init() -> void:
	_expect(Array(MappingScript.for_mission_template("starter_01")).is_empty(), "unapproved tutorial tasks must not infer effects")
	_expect(Array(MappingScript.for_mission_template("starter_18")) == [{"effect_type": "territory_first_touch", "territory_id": "territory_02", "character_id": "character_06"}], "starter_18 must fix the approved territory and character")
	var expected_collectible_ids: Array[String] = ["collectible.r01.goldbar_001", "collectible.r01.gift_001", "collectible.r01.neon_001", "collectible.r01.vehicle_001", "collectible.r01.cityset_001"]
	for offset: int in range(expected_collectible_ids.size()):
		var descriptor: Dictionary = Array(MappingScript.for_mission_template("starter_%d" % (19 + offset)))[0]
		_expect(str(descriptor["effect_type"]) == "collectible_grant", "starter collectible missions must use the common grant contract")
		_expect(str(descriptor["collectible_id"]) == expected_collectible_ids[offset] and int(descriptor["quantity"]) == 1, "starter collectible mapping must preserve its fixed identity and quantity")
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("TutorialClaimEffectMapping test failed: %s" % message)

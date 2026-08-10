extends SceneTree

const TerritoryProgressModelScript = preload("res://scripts/territory_progress_model.gd")

var _failed: bool = false

func _init() -> void:
	var territory_data: Dictionary = TerritoryProgressModelScript.create("territory_01")
	_expect(bool(territory_data["is_valid"]), "territory data with an id must be valid")
	_expect(str(territory_data["territory_id"]) == "territory_01", "territory data must retain its id")
	_expect(TerritoryProgressModelScript.has_required_growth_fields(territory_data), "territory data must expose all long-term growth fields")
	_expect(str(territory_data["territory_progress"]) == "[PLACEHOLDER]", "territory progress must remain a placeholder")
	_expect(str(territory_data["exploration_collection_count"]) == "[PLACEHOLDER]", "exploration collection count must remain a placeholder")
	_expect(str(territory_data["environment_decoration_owned_count"]) == "[PLACEHOLDER]", "decoration owned count must remain a placeholder")

	var invalid_data: Dictionary = TerritoryProgressModelScript.create("")
	_expect(not bool(invalid_data["is_valid"]), "empty territory id must be rejected")
	_expect(str(invalid_data["error_code"]) == "territory_id_required", "empty territory id must identify the validation error")
	_expect(not TerritoryProgressModelScript.has_required_growth_fields(invalid_data), "rejected data must not be treated as display-ready growth data")

	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("TerritoryProgressModel test failed: %s" % message)

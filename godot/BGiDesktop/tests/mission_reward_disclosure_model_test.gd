extends SceneTree

const MissionRewardDisclosureModelScript = preload("res://scripts/mission_reward_disclosure_model.gd")

var _failed: bool = false

func _init() -> void:
	var zero_extra_card: Dictionary = MissionRewardDisclosureModelScript.create("starter_01", false)
	_expect(bool(zero_extra_card["is_valid"]), "card with zero extra reward must remain valid")
	_expect(MissionRewardDisclosureModelScript.has_required_disclosures(zero_extra_card), "every card must disclose guaranteed reward, extra range, and extra probability")
	_expect(str(zero_extra_card["guaranteed_reward"]) == "[PLACEHOLDER]", "guaranteed reward must remain a placeholder")
	_expect(str(zero_extra_card["extra_reward_range"]) == "[PLACEHOLDER]", "extra reward range must remain a placeholder")
	_expect(str(zero_extra_card["extra_reward_probability"]) == "[PLACEHOLDER]", "extra reward probability must remain a placeholder")
	_expect(bool(zero_extra_card["extra_reward_is_zero"]), "zero extra reward must be represented explicitly")
	_expect(str(zero_extra_card["outcome_presentation_key"]) == "guaranteed_reward_received", "zero extra reward must preserve the guaranteed reward presentation")
	_expect(not str(zero_extra_card["outcome_presentation_key"]).contains("failure"), "zero extra reward must not use failure wording")
	_expect(not str(zero_extra_card["outcome_presentation_key"]).contains("empty"), "zero extra reward must not use empty-handed wording")

	var extra_card: Dictionary = MissionRewardDisclosureModelScript.create("starter_02", true)
	_expect(not bool(extra_card["extra_reward_is_zero"]), "extra reward card must record that an extra reward exists")
	_expect(str(extra_card["outcome_presentation_key"]) == "guaranteed_and_extra_reward_received", "extra reward card must use the positive presentation key")

	var invalid_card: Dictionary = MissionRewardDisclosureModelScript.create("", false)
	_expect(not bool(invalid_card["is_valid"]), "empty task id must be rejected")
	_expect(str(invalid_card["error_code"]) == "task_id_required", "empty task id must identify the validation error")

	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionRewardDisclosureModel test failed: %s" % message)

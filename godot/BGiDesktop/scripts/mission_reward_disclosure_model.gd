class_name MissionRewardDisclosureModel
extends RefCounted

const PLACEHOLDER_VALUE: String = "[PLACEHOLDER]"

## Creates disclosure data for one mission card without assigning real rewards or rates.
static func create(task_id: String, has_extra_reward: bool) -> Dictionary:
	if task_id.is_empty():
		return _rejected("task_id_required")

	return {
		"is_valid": true,
		"error_code": "",
		"task_id": task_id,
		"guaranteed_reward": PLACEHOLDER_VALUE,
		"extra_reward_range": PLACEHOLDER_VALUE,
		"extra_reward_probability": PLACEHOLDER_VALUE,
		"extra_reward_is_zero": not has_extra_reward,
		"outcome_presentation_key": _get_presentation_key(has_extra_reward),
	}

## Checks that a card contains all player-facing reward disclosure fields.
static func has_required_disclosures(card_data: Dictionary) -> bool:
	return card_data.has("guaranteed_reward") \
		and card_data.has("extra_reward_range") \
		and card_data.has("extra_reward_probability")

static func _get_presentation_key(has_extra_reward: bool) -> String:
	if has_extra_reward:
		return "guaranteed_and_extra_reward_received"
	return "guaranteed_reward_received"

static func _rejected(error_code: String) -> Dictionary:
	return {
		"is_valid": false,
		"error_code": error_code,
	}

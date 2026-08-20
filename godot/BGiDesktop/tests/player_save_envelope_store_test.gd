extends SceneTree

const StoreScript = preload("res://scripts/player_save_envelope_store.gd")
const ReceiptCollectionScript = preload("res://scripts/claim_receipt_collection.gd")

const TEST_PATH: String = "user://player_save_envelope_store_test.json"

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var receipt_collection: RefCounted = ReceiptCollectionScript.new()
	var receipt: Dictionary = {
		"claim_receipt_id": "starter_01:100:claim",
		"mission_run_id": "starter_01:100",
		"result_id": "starter_01:100:result",
		"claimed_at_seconds": 105,
		"applied_effect_ids": [],
	}
	_expect(bool(receipt_collection.save_receipt(receipt)["is_saved"]), "receipt collection must accept one valid receipt")
	var envelope: Dictionary = StoreScript.make_envelope(
		[{"id": "crew_01", "status": 0}, {"id": "crew_02", "status": 0}, {"id": "crew_03", "status": 0}, {"id": "crew_04", "status": 0}, {"id": "crew_05", "status": 0}],
		[{"mission_template_id": "starter_01", "board_state": "claimed"}],
		{"executions": {}, "result_state": {"locked_results_by_task_id": {}, "claimed_task_ids": {"starter_01": true}}, "mission_runs": {}},
		receipt_collection.to_data(),
		{"allowance": 1, "last_refill_check_seconds": 100},
		{"territory_02": {"territory_id": "territory_02", "territory_progress": "[PLACEHOLDER]", "exploration_collection_count": "[PLACEHOLDER]", "environment_decoration_owned_count": "[PLACEHOLDER]"}},
		{"territory_02": {"territory_id": "territory_02", "source_claim_receipt_id": "starter_01:100:claim", "unlocked_crew_id": "territory_territory_02_crew_01", "touched_at_seconds": 105}},
		{"tutorial_claimed_task_ids": {"starter_01": true}}
	)
	var store: RefCounted = StoreScript.new(TEST_PATH)
	_expect(bool(store.save(envelope)["is_saved"]), "complete envelope must save in one write")
	var loaded: Dictionary = store.load()
	_expect(bool(loaded["is_loaded"]), "complete envelope must load")
	_expect(Dictionary(loaded["envelope"])["contract_version"] == "full_loop_contract_v1", "loaded envelope must retain the contract version")
	var restored_receipts: RefCounted = ReceiptCollectionScript.new(Dictionary(Dictionary(loaded["envelope"])["claim_receipts_by_mission_run_id"]))
	_expect(bool(restored_receipts.get_receipt("starter_01:100")["is_found"]), "loaded envelope must retain the receipt keyed by mission run")
	var invalid_envelope: Dictionary = envelope.duplicate(true)
	invalid_envelope.erase("crew_by_id")
	_expect(not bool(store.save(invalid_envelope)["is_saved"]), "incomplete envelope must not overwrite the saved transaction")
	_expect(bool(store.load()["is_loaded"]), "failed envelope validation must preserve the previous saved transaction")
	var missing_field_file: FileAccess = FileAccess.open("user://player_save_envelope_missing_field.json", FileAccess.WRITE)
	missing_field_file.store_string(JSON.stringify(invalid_envelope))
	missing_field_file.close()
	_expect(StoreScript.new("user://player_save_envelope_missing_field.json").load()["error_code"] == "save_required_field_missing", "missing required envelope fields must be classified without loading")
	var unsupported_envelope: Dictionary = envelope.duplicate(true)
	unsupported_envelope["contract_version"] = "full_loop_contract_v2"
	var unsupported_file: FileAccess = FileAccess.open("user://player_save_envelope_unsupported.json", FileAccess.WRITE)
	unsupported_file.store_string(JSON.stringify(unsupported_envelope))
	unsupported_file.close()
	_expect(StoreScript.new("user://player_save_envelope_unsupported.json").load()["error_code"] == "save_contract_unsupported", "unsupported contract versions must be classified without loading")
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("PlayerSaveEnvelopeStore test failed: %s" % message)

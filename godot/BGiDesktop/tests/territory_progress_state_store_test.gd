extends SceneTree

const TerritoryProgressModelScript = preload("res://scripts/territory_progress_model.gd")
const TerritoryProgressStateStoreScript = preload("res://scripts/territory_progress_state_store.gd")
const TEST_FILE_PATH: String = "user://territory_progress_state_store_test.json"

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var store: RefCounted = TerritoryProgressStateStoreScript.new(TEST_FILE_PATH)
	var missing_result: Dictionary = store.load("territory_01")
	_expect(bool(missing_result["was_missing"]), "missing territory state must fall back to placeholders")
	_expect(str(missing_result["territory_data"]["territory_progress"]) == "[PLACEHOLDER]", "missing territory progress must remain a placeholder")

	var territory_data: Dictionary = TerritoryProgressModelScript.create("territory_01")
	_expect(bool(store.save(territory_data)["is_saved"]), "placeholder territory display state must save")
	var reopened_result: Dictionary = store.load("territory_01")
	_expect(bool(reopened_result["is_loaded"]) and not bool(reopened_result["was_missing"]), "saved territory display state must load after reopening")
	_expect(reopened_result["territory_data"] == territory_data, "reopened territory display state must retain every placeholder field")

	var file: FileAccess = FileAccess.open(TEST_FILE_PATH, FileAccess.WRITE)
	file.store_string("{invalid")
	file.close()
	var invalid_result: Dictionary = store.load("territory_01")
	_expect(not bool(invalid_result["is_loaded"]), "invalid territory file must not be treated as loaded")
	_expect(str(invalid_result["territory_data"]["territory_progress"]) == "[PLACEHOLDER]", "invalid territory file must safely restore placeholder progress")
	_expect(str(invalid_result["territory_data"]["exploration_collection_count"]) == "[PLACEHOLDER]", "invalid territory file must safely restore placeholder collection")
	_expect(str(invalid_result["territory_data"]["environment_decoration_owned_count"]) == "[PLACEHOLDER]", "invalid territory file must safely restore placeholder decorations")

	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("TerritoryProgressStateStore test failed: %s" % message)

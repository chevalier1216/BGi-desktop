class_name StarterMissionFlowPanel
extends PanelContainer

signal directory_changed

const GameStateScript = preload("res://scripts/game_state.gd")
const MissionAssignmentStateScript = preload("res://scripts/mission_assignment_state.gd")
const AssignmentCoordinatorScript = preload("res://scripts/persistent_mission_assignment_coordinator.gd")
const ValidityQueryScript = preload("res://scripts/mission_execution_validity_query.gd")
const ExpiredReleaseServiceScript = preload("res://scripts/mission_expired_release_service.gd")
const SnapshotCollectionScript = preload("res://scripts/mission_execution_snapshot_collection.gd")
const MissionLifecycleCoordinatorScript = preload("res://scripts/mission_lifecycle_coordinator.gd")
const MissionExecutionStateStoreScript = preload("res://scripts/mission_execution_state_store.gd")
const PlayerSaveEnvelopeStoreScript = preload("res://scripts/player_save_envelope_store.gd")
const ClaimReceiptCollectionScript = preload("res://scripts/claim_receipt_collection.gd")
const ClaimReceiptStoreScript = preload("res://scripts/claim_receipt_store.gd")
const MissionResultStateSnapshotScript = preload("res://scripts/mission_result_state_snapshot.gd")
const MissionRefreshAllowanceScript = preload("res://scripts/mission_refresh_allowance.gd")
const MissionRefreshServiceScript = preload("res://scripts/mission_refresh_service.gd")
const MissionRefreshStateStoreScript = preload("res://scripts/mission_refresh_state_store.gd")
const TerritoryFirstTouchUnlockScript = preload("res://scripts/territory_first_touch_unlock.gd")
const TerritoryProgressModelScript = preload("res://scripts/territory_progress_model.gd")
const TerritoryFirstTouchStateStoreScript = preload("res://scripts/territory_first_touch_state_store.gd")
const TerritoryProgressStateStoreScript = preload("res://scripts/territory_progress_state_store.gd")
const MissionRewardDisclosureModelScript = preload("res://scripts/mission_reward_disclosure_model.gd")
const TutorialTaskProgressionScript = preload("res://scripts/tutorial_task_progression.gd")
const TutorialMissionCompletionCoordinatorScript = preload("res://scripts/tutorial_mission_completion_coordinator.gd")
const TutorialEventLoggerScript = preload("res://scripts/tutorial_event_logger.gd")

@onready var task_label: Label = %TaskLabel
@onready var requirement_label: Label = %RequirementLabel
@onready var crew_selector: Container = %CrewSelector
@onready var task_description_label: Label = get_node_or_null("%TaskDescriptionLabel") as Label
@onready var crew_type_label: Label = get_node_or_null("%CrewTypeLabel") as Label
@onready var duration_label: Label = get_node_or_null("%DurationLabel") as Label
@onready var reward_details: Label = get_node_or_null("%RewardDetails") as Label
@onready var status_label: Label = %StatusLabel
@onready var start_button: Button = %StartButton
@onready var refresh_allowance_label: Label = %RefreshAllowanceLabel
@onready var refresh_next_available_label: Label = %RefreshNextAvailableLabel
@onready var refreshable_mission_count_label: Label = %RefreshableMissionCountLabel
@onready var refresh_button: Button = %RefreshButton
@onready var territory_progress_label: Label = %TerritoryProgressLabel
@onready var exploration_collection_label: Label = %ExplorationCollectionLabel
@onready var environment_decoration_label: Label = %EnvironmentDecorationLabel
@onready var explore_territory_button: Button = %ExploreTerritoryButton
@onready var guaranteed_reward_label: Label = %GuaranteedRewardLabel
@onready var extra_reward_range_label: Label = %ExtraRewardRangeLabel
@onready var extra_reward_probability_label: Label = %ExtraRewardProbabilityLabel
@onready var extra_reward_note_label: Label = %ExtraRewardNoteLabel
@onready var claim_receipt_label: Label = %ClaimReceiptLabel
@onready var next_tutorial_task_label: Label = %NextTutorialTaskLabel
@onready var claim_button: Button = %ClaimButton
@onready var retry_load_button: Button = %RetryLoadButton

@export var execution_state_store_path: String = "user://starter_mission_flow_state.json"
@export var player_save_store_path: String = ""
@export var territory_state_store_path: String = "user://starter_mission_territory_state.json"
@export var territory_progress_state_store_path: String = "user://starter_mission_territory_progress_state.json"
@export var refresh_state_store_path: String = "user://starter_mission_refresh_state.json"
@export var current_time_override: int = -1

var _task_id: String = ""
var _duration_seconds: int = 0
var _selected_crew_ids: Array[String] = []
var _current_missions: Array[Dictionary] = []
var _game_state: Node
var _starter_mission_catalog: Node
var _lifecycle: RefCounted
var _assignment_state: RefCounted
var _assignment_coordinator: RefCounted
var _tutorial_progression: RefCounted
var _tutorial_completion_coordinator: RefCounted
var _snapshot_collection: RefCounted
var _execution_state_store: RefCounted
var _player_save_store: RefCounted
var _claim_receipt_collection: RefCounted
var _result_state: RefCounted
var _crew_ids_by_task: Dictionary = {}
var _refresh_allowance: RefCounted
var _refresh_service: RefCounted
var _refresh_state_store: RefCounted
var _touched_territory_ids: Dictionary = {}
var _unlocked_crew_ids_by_territory: Dictionary = {}
var _source_claim_receipt_ids_by_territory: Dictionary = {}
var _territory_touch_receipts_by_id: Dictionary = {}
var _territory_data: Dictionary = {}
var _territory_state_store: RefCounted
var _territory_progress_state_store: RefCounted
var _reward_disclosure_data: Dictionary = {}
var _is_waiting: bool = false
var _is_completed: bool = false
var _is_claimed: bool = false
var _is_player_state_ready: bool = false
var _is_recovery_hold: bool = false
var _tutorial_event_logger: RefCounted

func _ready() -> void:
	_game_state = get_node("/root/GameState") as Node
	_starter_mission_catalog = get_node("/root/StarterMissionCatalog") as Node
	_assignment_state = MissionAssignmentStateScript.new()
	_assignment_coordinator = AssignmentCoordinatorScript.new(_game_state, _assignment_state)
	var validity_query: RefCounted = ValidityQueryScript.new()
	var expired_release_service: RefCounted = ExpiredReleaseServiceScript.new(_assignment_coordinator, _assignment_state, validity_query)
	_execution_state_store = MissionExecutionStateStoreScript.new(execution_state_store_path)
	_player_save_store = PlayerSaveEnvelopeStoreScript.new(_get_player_save_store_path())
	_tutorial_event_logger = TutorialEventLoggerScript.new()
	var player_save_result: Dictionary = _player_save_store.load()
	if not bool(player_save_result.get("is_loaded", false)) and not bool(player_save_result.get("was_missing", false)):
		_record_tutorial_event("tutorial_state_recovery_failed", "", "recovery_hold", "", {"reason": str(player_save_result.get("error_code", "save_data_corrupted"))})
		_enter_recovery_hold(str(player_save_result.get("error_code", "save_data_corrupted")))
		return
	var envelope: Dictionary = Dictionary(player_save_result.get("envelope", {}))
	var has_envelope: bool = bool(player_save_result.get("is_loaded", false)) and not bool(player_save_result.get("was_missing", true))
	var execution_state_result: Dictionary = MissionExecutionStateStoreScript.from_payload(Dictionary(envelope.get("execution_state", {}))) if has_envelope else _execution_state_store.load()
	if has_envelope and not bool(execution_state_result.get("is_loaded", false)):
		var execution_state_error: String = str(execution_state_result.get("error_code", "execution_state_store_data_invalid"))
		_record_tutorial_event("tutorial_state_recovery_failed", "", "recovery_hold", "", {"reason": execution_state_error})
		_enter_recovery_hold(execution_state_error)
		return
	_snapshot_collection = execution_state_result["collection"]
	_result_state = execution_state_result["result_state"]
	_crew_ids_by_task = Dictionary(execution_state_result["crew_ids_by_task"]).duplicate(true)
	if has_envelope:
		var restore_crew_result: Dictionary = _game_state.restore_crew(Array(envelope.get("crew_by_id", [])))
		if not bool(restore_crew_result.get("is_restored", false)):
			var crew_restore_error: String = str(restore_crew_result.get("error_code", "crew_restore_invalid"))
			_record_tutorial_event("tutorial_state_recovery_failed", "", "recovery_hold", "", {"reason": crew_restore_error})
			_enter_recovery_hold(crew_restore_error)
			return
	if has_envelope:
		_claim_receipt_collection = ClaimReceiptCollectionScript.new()
		var receipt_load_result: Dictionary = _claim_receipt_collection.load_data(Dictionary(envelope.get("claim_receipts_by_mission_run_id", {})))
		if not bool(receipt_load_result.get("is_loaded", false)):
			var receipt_error: String = str(receipt_load_result.get("error_code", "claim_receipt_store_data_invalid"))
			_record_tutorial_event("tutorial_state_recovery_failed", "", "recovery_hold", "", {"reason": receipt_error})
			_enter_recovery_hold(receipt_error)
			return
	else:
		var legacy_receipts: Dictionary = ClaimReceiptStoreScript.new().load()
		_claim_receipt_collection = ClaimReceiptCollectionScript.new(Dictionary(legacy_receipts.get("receipts_by_mission_run_id", {})))
	_lifecycle = MissionLifecycleCoordinatorScript.new(_assignment_coordinator, expired_release_service, _snapshot_collection, _claim_receipt_collection, Dictionary(execution_state_result["mission_runs"]))
	_restore_result_state()
	var current_time_seconds: int = _get_current_time_seconds()
	_refresh_state_store = MissionRefreshStateStoreScript.new(refresh_state_store_path)
	var refresh_state_result: Dictionary = _refresh_state_store.load(current_time_seconds - MissionRefreshAllowanceScript.REFILL_INTERVAL_SECONDS)
	if has_envelope:
		var parsed_refresh_state: Dictionary = MissionRefreshAllowanceScript.from_data(Dictionary(envelope.get("refresh_state", {})))
		if not bool(parsed_refresh_state.get("is_valid", false)):
			var refresh_state_error: String = str(parsed_refresh_state.get("error_code", "mission_refresh_state_invalid"))
			_record_tutorial_event("tutorial_state_recovery_failed", "", "recovery_hold", "", {"reason": refresh_state_error})
			_enter_recovery_hold(refresh_state_error)
			return
		_refresh_allowance = parsed_refresh_state["allowance"]
	else:
		_refresh_allowance = refresh_state_result["allowance"]
	_refresh_allowance.update(current_time_seconds)
	if bool(refresh_state_result["was_missing"]):
		_refresh_state_store.save(_refresh_allowance)
	_refresh_service = MissionRefreshServiceScript.new(_refresh_allowance)
	_territory_data = TerritoryProgressModelScript.create("territory_02")
	_territory_progress_state_store = TerritoryProgressStateStoreScript.new(territory_progress_state_store_path)
	var territory_progress_result: Dictionary = _territory_progress_state_store.load(str(_territory_data["territory_id"]))
	_territory_data = Dictionary(Dictionary(envelope.get("territory_state_by_id", {})).get("territory_02", territory_progress_result["territory_data"])).duplicate(true) if has_envelope else Dictionary(territory_progress_result["territory_data"]).duplicate(true)
	if has_envelope and (not bool(_territory_data.get("is_valid", false)) or not TerritoryProgressModelScript.has_required_growth_fields(_territory_data)):
		_record_tutorial_event("tutorial_state_recovery_failed", "", "recovery_hold", "", {"reason": "territory_progress_store_data_invalid"})
		_enter_recovery_hold("territory_progress_store_data_invalid")
		return
	if bool(territory_progress_result["was_missing"]):
		_territory_progress_state_store.save(_territory_data)
	_territory_state_store = TerritoryFirstTouchStateStoreScript.new(territory_state_store_path)
	var territory_state_result: Dictionary = _territory_state_store.load()
	_touched_territory_ids = Dictionary(territory_state_result["touched_territory_ids"]).duplicate(true)
	_unlocked_crew_ids_by_territory = Dictionary(territory_state_result["unlocked_crew_ids_by_territory"]).duplicate(true)
	_source_claim_receipt_ids_by_territory = Dictionary(territory_state_result["source_claim_receipt_ids_by_territory"]).duplicate(true)
	if has_envelope:
		_territory_touch_receipts_by_id = Dictionary(envelope.get("territory_touch_receipts_by_id", {})).duplicate(true)
		if not _restore_territory_touch_maps_from_receipts():
			_record_tutorial_event("tutorial_state_recovery_failed", "", "recovery_hold", "", {"reason": "territory_state_store_data_invalid"})
			_enter_recovery_hold("territory_state_store_data_invalid")
			return
	_restore_unlocked_crew()
	_load_first_starter_mission()
	_record_tutorial_event("tutorial_resumed" if has_envelope else "tutorial_started", _task_id, "loaded", _task_id)
	_record_tutorial_event("tutorial_step_presented", _task_id, "shown", _task_id)
	_tutorial_completion_coordinator = TutorialMissionCompletionCoordinatorScript.new(_tutorial_progression, _assignment_state, validity_query)
	_render_crew_choices()
	start_button.pressed.connect(_on_start_pressed)
	claim_button.pressed.connect(_on_claim_pressed)
	retry_load_button.pressed.connect(_on_retry_load_pressed)
	refresh_button.pressed.connect(_on_refresh_pressed)
	explore_territory_button.pressed.connect(_on_explore_territory_pressed)
	_refresh_selection_state()
	_refresh_refresh_state()
	_refresh_territory_growth_display()
	_refresh_reward_disclosure_display()
	_restore_latest_claim_receipt_display()
	_restore_first_claim_territory_touch()
	explore_territory_button.disabled = true
	_restore_saved_execution(current_time_seconds)
	_is_player_state_ready = true
	if not has_envelope:
		_save_player_state()

func _enter_recovery_hold(error_code: String) -> void:
	_is_recovery_hold = true
	task_label.text = "無法安全讀取存檔"
	requirement_label.text = "資料尚未被變更。請重試讀取或保留錯誤代碼供檢查。"
	status_label.text = "錯誤：%s" % error_code
	for choice: CheckButton in crew_selector.get_children():
		choice.disabled = true
	start_button.disabled = true
	claim_button.disabled = true
	refresh_button.disabled = true
	explore_territory_button.disabled = true
	retry_load_button.disabled = false
	retry_load_button.pressed.connect(_on_retry_load_pressed)

func _on_retry_load_pressed() -> void:
	if not _is_recovery_hold:
		return
	get_tree().reload_current_scene()

func _load_first_starter_mission() -> void:
	_current_missions = _starter_mission_catalog.get_missions()
	_tutorial_progression = TutorialTaskProgressionScript.new(_current_missions)
	_restore_claimed_tutorial_progression()
	var current_task: Dictionary = _tutorial_progression.get_current_task()
	if current_task.is_empty():
		_show_tutorial_completed_state()
		return
	_load_current_mission(current_task)

func _show_tutorial_completed_state() -> void:
	_task_id = ""
	_duration_seconds = 0
	task_label.text = "新手任務：全部完成"
	requirement_label.text = "所有固定新手任務已完成"
	status_label.text = "已完成全部新手任務"
	for choice: CheckButton in crew_selector.get_children():
		choice.disabled = true
	start_button.disabled = true
	claim_button.disabled = true

## Rebuilds fixed tutorial progression from already-saved claim receipts.
func _restore_claimed_tutorial_progression() -> void:
	while true:
		var current_task: Dictionary = _tutorial_progression.get_current_task()
		if current_task.is_empty():
			return
		var current_task_id: String = str(current_task["id"])
		if not _result_state.is_claimed(current_task_id):
			return
		var advance_result: Dictionary = _tutorial_progression.complete_current_task(current_task_id)
		if not bool(advance_result["is_advanced"]):
			return

func _load_current_mission(mission_override: Dictionary = {}) -> void:
	if _current_missions.is_empty():
		task_label.text = "新手任務：無可用任務"
		status_label.text = "任務資料不可用"
		start_button.disabled = true
		return
	var mission: Dictionary = mission_override if not mission_override.is_empty() else _current_missions[0]
	_task_id = str(mission["id"])
	_duration_seconds = int(mission["duration_seconds"])
	_reward_disclosure_data = MissionRewardDisclosureModelScript.create(_task_id, false)
	_refresh_reward_disclosure_display()
	task_label.text = "%s（%d 秒）" % [_client_mission_title(_task_id), _duration_seconds]
	requirement_label.text = "需求人物數量：%d–%d 名" % [DispatchRules.MIN_ASSIGNEES, DispatchRules.MAX_ASSIGNEES]
	if task_description_label != null:
		task_description_label.text = "派遣符合數量要求的人物後，任務將開始倒數。完成後可在此領取任務結果；收取成功後即可繼續下一個任務。"
	if crew_type_label != null:
		crew_type_label.text = "需求人物種類：無限制"
	if duration_label != null:
		duration_label.text = "預計耗時：%d 秒" % _duration_seconds
	_apply_detail_state_visibility()

func get_task_directory_entries() -> Dictionary:
	var current_entries: Array[Dictionary] = []
	var completed_entries: Array[Dictionary] = []
	var current_task: Dictionary = _tutorial_progression.get_current_task()
	var current_task_id := str(current_task.get("id", ""))
	for mission: Dictionary in _current_missions:
		var task_id := str(mission["id"])
		if not _result_state.get_locked_result(task_id).is_empty():
			completed_entries.append({"task_id": task_id, "title": _client_mission_title(task_id), "duration_seconds": int(mission["duration_seconds"]), "is_claimed": _result_state.is_claimed(task_id)})
		elif task_id == current_task_id:
			current_entries.append({"task_id": task_id, "title": _client_mission_title(task_id), "duration_seconds": int(mission["duration_seconds"])})
	return {"current": current_entries, "completed": completed_entries}

func get_refresh_directory_state() -> Dictionary:
	return {
		"allowance": "刷新額度：%d/%d" % [_refresh_allowance.get_allowance(), MissionRefreshAllowanceScript.MAX_ALLOWANCE],
		"next_available": "下次可用：%s" % _get_refresh_next_available_text(),
		"replaceable": "可替換任務：0（新手固定任務）",
		"can_refresh": false,
	}

func show_task_detail(task_id: String) -> bool:
	var mission: Dictionary = {}
	for candidate: Dictionary in _current_missions:
		if str(candidate["id"]) == task_id:
			mission = candidate
			break
	if mission.is_empty():
		return false
	_selected_crew_ids.clear()
	_is_waiting = false
	_is_completed = false
	_is_claimed = false
	_load_current_mission(mission)
	var locked_result: Dictionary = _result_state.get_locked_result(task_id)
	if not locked_result.is_empty():
		_is_completed = not _result_state.is_claimed(task_id)
		_is_claimed = _result_state.is_claimed(task_id)
		claim_button.disabled = _is_claimed
		status_label.text = "結果已領取" if _is_claimed else "任務已完成"
	else:
		_reset_crew_choices_for_selection()
		_restore_saved_execution(_get_current_time_seconds())
	_refresh_selection_state()
	_apply_detail_state_visibility()
	return true

func _apply_detail_state_visibility() -> void:
	var is_waiting_or_completed := _is_waiting or _is_completed or _is_claimed
	for node_name: String in ["TaskDescriptionScroll", "CrewTypeLabel", "RequirementLabel", "DurationLabel", "CrewSelectorTitle", "CrewSelector", "RewardTitle", "RewardSlots", "RewardDetails", "StartButton"]:
		var node := get_node_or_null("Content/%s" % node_name) as Control
		if node != null:
			node.visible = not is_waiting_or_completed
	claim_button.visible = _is_completed and not _is_claimed

func _render_crew_choices() -> void:
	for crew_member: Dictionary in _game_state.get_crew():
		_append_crew_choice(crew_member)

func _append_crew_choice(crew_member: Dictionary) -> void:
	var crew_id: String = str(crew_member["id"])
	var choice: CheckButton = CheckButton.new()
	choice.custom_minimum_size = Vector2(104, 104)
	choice.text = ""
	choice.tooltip_text = "可用" if int(crew_member["status"]) == GameStateScript.CrewStatus.AVAILABLE else "派遣中"
	choice.disabled = int(crew_member["status"]) != GameStateScript.CrewStatus.AVAILABLE
	choice.set_meta("crew_id", crew_id)
	var card := Panel.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("111217")
	card_style.border_width_left = 1
	card_style.border_width_top = 1
	card_style.border_width_right = 1
	card_style.border_width_bottom = 1
	card_style.border_color = Color("b79a34")
	card.add_theme_stylebox_override("panel", card_style)
	choice.add_child(card)
	var card_content := VBoxContainer.new()
	card_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_content.offset_left = 6
	card_content.offset_top = 6
	card_content.offset_right = -6
	card_content.offset_bottom = -6
	card_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(card_content)
	var crew_name := Label.new()
	crew_name.text = "小弟 %02d" % (crew_selector.get_child_count() + 1)
	crew_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_content.add_child(crew_name)
	var icon_placeholder := Label.new()
	icon_placeholder.text = ""
	icon_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_content.add_child(icon_placeholder)
	var selected_overlay := ColorRect.new()
	selected_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	selected_overlay.color = Color(1.0, 0.9, 0.45, 0.25)
	selected_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selected_overlay.visible = false
	card.add_child(selected_overlay)
	var selected_label := Label.new()
	selected_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	selected_label.text = "已選取"
	selected_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selected_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	selected_label.add_theme_color_override("font_color", Color("FF3333"))
	selected_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selected_overlay.add_child(selected_label)
	var unavailable_overlay := ColorRect.new()
	unavailable_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	unavailable_overlay.color = Color(0.5, 0.5, 0.5, 0.15)
	unavailable_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	unavailable_overlay.visible = choice.disabled
	card.add_child(unavailable_overlay)
	var unavailable_symbol := Label.new()
	unavailable_symbol.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	unavailable_symbol.text = "⊘"
	unavailable_symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	unavailable_symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	unavailable_symbol.add_theme_font_size_override("font_size", 52)
	unavailable_symbol.add_theme_color_override("font_color", Color("FF3333"))
	unavailable_symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	unavailable_overlay.add_child(unavailable_symbol)
	choice.set_meta("selected_overlay", selected_overlay)
	choice.set_meta("unavailable_overlay", unavailable_overlay)
	choice.toggled.connect(_on_crew_toggled.bind(crew_id))
	crew_selector.add_child(choice)

func _reset_crew_choices_for_selection() -> void:
	for choice: CheckButton in crew_selector.get_children():
		var crew_id: String = str(choice.get_meta("crew_id", ""))
		choice.button_pressed = false
		choice.disabled = _get_crew_status(crew_id) != GameStateScript.CrewStatus.AVAILABLE
	_refresh_crew_card_overlays()

func _get_crew_status(crew_id: String) -> int:
	for crew_member: Dictionary in _game_state.get_crew():
		if str(crew_member.get("id", "")) == crew_id:
			return int(crew_member.get("status", -1))
	return -1

func _on_crew_toggled(pressed: bool, crew_id: String) -> void:
	if _is_waiting or _is_completed or _is_claimed:
		return
	if pressed:
		if not _selected_crew_ids.has(crew_id):
			_selected_crew_ids.append(crew_id)
	else:
		_selected_crew_ids.erase(crew_id)
	_refresh_selection_state()
	_record_tutorial_event("tutorial_crew_selection_changed", _task_id, "selected" if pressed else "deselected", _task_id, {"crew_count": _selected_crew_ids.size()})

func _refresh_selection_state() -> void:
	var selected_count: int = _selected_crew_ids.size()
	start_button.disabled = _is_waiting or _is_completed or _is_claimed or selected_count < DispatchRules.MIN_ASSIGNEES or selected_count > DispatchRules.MAX_ASSIGNEES
	if not _is_waiting and not _is_completed and not _is_claimed:
		status_label.text = "已選 %d/%d 名小弟" % [selected_count, DispatchRules.MAX_ASSIGNEES]
	_refresh_crew_card_overlays()

func _refresh_crew_card_overlays() -> void:
	for choice: CheckButton in crew_selector.get_children():
		if choice.has_meta("selected_overlay"):
			(choice.get_meta("selected_overlay") as ColorRect).visible = choice.button_pressed and not choice.disabled
		if choice.has_meta("unavailable_overlay"):
			(choice.get_meta("unavailable_overlay") as ColorRect).visible = choice.disabled and not choice.button_pressed

func _on_start_pressed() -> void:
	if _is_waiting or _is_completed or _is_claimed:
		return
	var result: Dictionary = _lifecycle.accept_execution(_task_id, _selected_crew_ids, _get_current_time_seconds(), _duration_seconds)
	if not bool(result["is_accepted"]):
		status_label.text = "無法開始：%s" % result["error_code"]
		return
	_crew_ids_by_task[_task_id] = _selected_crew_ids.duplicate()
	var save_result: Dictionary = _save_execution_state()
	if not bool(save_result["is_saved"]):
		_assignment_coordinator.release_assignment(_task_id)
		_snapshot_collection.remove_snapshot(_task_id)
		_crew_ids_by_task.erase(_task_id)
		status_label.text = "無法開始：保存失敗：%s" % save_result["error_code"]
		return
	_is_waiting = true
	_record_tutorial_event("tutorial_assignment_confirmed", _task_id, "accepted", _task_id, {"crew_count": _selected_crew_ids.size()})
	_record_tutorial_event("tutorial_task_started", _task_id, "active", _task_id)
	for choice: CheckButton in crew_selector.get_children():
		choice.disabled = true
	_refresh_crew_card_overlays()
	start_button.disabled = true
	status_label.text = "等待中：剩餘 %d 秒" % _duration_seconds
	_refresh_refresh_state()
	_apply_detail_state_visibility()

func _on_claim_pressed() -> void:
	if not _is_completed or _is_claimed:
		return
	var claim_result: Dictionary = _lifecycle.claim_completed_result(_task_id, _get_current_time_seconds())
	if not bool(claim_result["is_claimed"]):
		status_label.text = "領取狀態無法讀取"
		return
	var previous_crew: Array[Dictionary] = _game_state.get_crew()
	var previous_touched_territory_ids: Dictionary = _touched_territory_ids.duplicate(true)
	var previous_unlocked_crew_ids: Dictionary = _unlocked_crew_ids_by_territory.duplicate(true)
	var previous_source_receipt_ids: Dictionary = _source_claim_receipt_ids_by_territory.duplicate(true)
	var previous_touch_receipts: Dictionary = _territory_touch_receipts_by_id.duplicate(true)
	var touch_plan: Dictionary = _prepare_first_claim_territory_touch(Dictionary(claim_result["receipt"])) if _task_id == "starter_01" else {"did_touch": false}
	if bool(touch_plan["did_touch"]):
		_apply_territory_touch_plan(touch_plan)
		if not _ensure_unlocked_crew(str(touch_plan["unlocked_crew_id"])):
			_game_state.restore_crew(previous_crew)
			_touched_territory_ids = previous_touched_territory_ids
			_unlocked_crew_ids_by_territory = previous_unlocked_crew_ids
			_source_claim_receipt_ids_by_territory = previous_source_receipt_ids
			_territory_touch_receipts_by_id = previous_touch_receipts
			status_label.text = "收取保存未完成，請重試"
			return
	var tutorial_result: Dictionary = _tutorial_completion_coordinator.complete_claimed_current_task(_task_id, Dictionary(claim_result["receipt"]))
	if not bool(tutorial_result["is_completed"]):
		status_label.text = "收取完成，但教學進度無法更新"
		return
	_crew_ids_by_task.erase(_task_id)
	var save_result: Dictionary = _save_execution_state()
	if not bool(save_result["is_saved"]):
		_game_state.restore_crew(previous_crew)
		_touched_territory_ids = previous_touched_territory_ids
		_unlocked_crew_ids_by_territory = previous_unlocked_crew_ids
		_source_claim_receipt_ids_by_territory = previous_source_receipt_ids
		_territory_touch_receipts_by_id = previous_touch_receipts
		_is_completed = true
		claim_button.disabled = false
		status_label.text = "收取保存未完成，請重試"
		return
	_show_claim_receipt(Dictionary(claim_result["receipt"]))
	if bool(touch_plan["did_touch"]):
		_append_crew_choice({"id": str(touch_plan["unlocked_crew_id"]), "status": GameStateScript.CrewStatus.AVAILABLE})
	for choice: CheckButton in crew_selector.get_children():
		choice.disabled = true
	_refresh_crew_card_overlays()
	start_button.disabled = true
	claim_button.disabled = true
	_refresh_refresh_state()
	status_label.text = "結果已領取"
	_record_tutorial_event("tutorial_reward_claimed", _task_id, "claimed", _task_id)
	_is_completed = false
	_is_claimed = true
	_apply_detail_state_visibility()
	directory_changed.emit()

func _on_refresh_pressed() -> void:
	_record_tutorial_event("tutorial_refresh_attempted", _task_id, "attempted", _task_id)
	refresh_current_mission(_get_current_time_seconds())
	_record_tutorial_event("tutorial_refresh_blocked", _task_id, "fixed_tutorial", _task_id)

func _on_explore_territory_pressed() -> void:
	status_label.text = "地盤會在收取成果後觸及"

func _apply_first_claim_territory_touch(claim_receipt: Dictionary) -> void:
	var touch_plan: Dictionary = _prepare_first_claim_territory_touch(claim_receipt)
	if not bool(touch_plan["did_touch"]):
		var territory_id: String = str(_territory_data["territory_id"])
		if _source_claim_receipt_ids_by_territory.has(territory_id):
			claim_receipt_label.text += "｜地盤已觸及"
		return
	_apply_territory_touch_plan(touch_plan)
	if not _ensure_unlocked_crew(str(touch_plan["unlocked_crew_id"]), true):
		claim_receipt_label.text += "｜新人物還原失敗"
		return
	var save_result: Dictionary = _save_player_state()
	if not bool(save_result["is_saved"]):
		claim_receipt_label.text += "｜地盤觸及保存失敗：%s" % save_result["error_code"]
		return
	claim_receipt_label.text += "｜觸及新地盤：%s｜新人物已加入：%s" % [str(touch_plan["territory_id"]), str(touch_plan["unlocked_crew_id"])]

func _prepare_first_claim_territory_touch(claim_receipt: Dictionary) -> Dictionary:
	var source_claim_receipt_id: String = str(claim_receipt.get("claim_receipt_id", ""))
	var territory_id: String = str(_territory_data["territory_id"])
	if source_claim_receipt_id.is_empty() or _touched_territory_ids.has(territory_id):
		return {"did_touch": false}
	var touch_result: Dictionary = TerritoryFirstTouchUnlockScript.touch(territory_id, _touched_territory_ids)
	if not bool(touch_result["is_unlock_granted"]):
		return {"did_touch": false}
	return {"did_touch": true, "territory_id": territory_id, "source_claim_receipt_id": source_claim_receipt_id, "unlocked_crew_id": _get_unlocked_crew_id(territory_id), "touched_territory_ids": Dictionary(touch_result["touched_territory_ids"]).duplicate(true)}

func _apply_territory_touch_plan(touch_plan: Dictionary) -> void:
	var territory_id: String = str(touch_plan["territory_id"])
	_touched_territory_ids = Dictionary(touch_plan["touched_territory_ids"]).duplicate(true)
	_unlocked_crew_ids_by_territory[territory_id] = str(touch_plan["unlocked_crew_id"])
	_source_claim_receipt_ids_by_territory[territory_id] = str(touch_plan["source_claim_receipt_id"])
	_territory_touch_receipts_by_id[territory_id] = {"territory_id": territory_id, "source_claim_receipt_id": str(touch_plan["source_claim_receipt_id"]), "unlocked_crew_id": str(touch_plan["unlocked_crew_id"]), "touched_at_seconds": _get_current_time_seconds()}

func _restore_first_claim_territory_touch() -> void:
	if _touched_territory_ids.has(str(_territory_data["territory_id"])):
		return
	var runs: Dictionary = Dictionary(_lifecycle.get_persisted_runs()["mission_runs_by_id"])
	for mission_run_id_variant: Variant in runs:
		var mission_run_id: String = str(mission_run_id_variant)
		var run: Dictionary = Dictionary(runs[mission_run_id])
		if str(run.get("mission_template_id", "")) != "starter_01":
			continue
		var receipt_result: Dictionary = _lifecycle.get_claim_receipt(mission_run_id)
		if bool(receipt_result["is_found"]):
			_apply_first_claim_territory_touch(Dictionary(receipt_result["receipt"]))
		return

func _restore_unlocked_crew() -> void:
	for territory_id_variant: Variant in _unlocked_crew_ids_by_territory:
		_ensure_unlocked_crew(str(_unlocked_crew_ids_by_territory[territory_id_variant]))

func _ensure_unlocked_crew(crew_id: String, append_choice: bool = false) -> bool:
	for crew_member: Dictionary in _game_state.get_crew():
		if str(crew_member["id"]) == crew_id:
			return true
	var add_result: Dictionary = _game_state.add_available_crew(crew_id)
	if not bool(add_result["is_added"]):
		return false
	if append_choice:
		_append_crew_choice({"id": crew_id, "status": GameStateScript.CrewStatus.AVAILABLE})
	return true

func _get_unlocked_crew_id(territory_id: String) -> String:
	return "territory_%s_crew_01" % territory_id

func _refresh_territory_growth_display() -> void:
	territory_progress_label.text = "地盤進度：%s" % _territory_data["territory_progress"]
	exploration_collection_label.text = "探索收藏：%s" % _territory_data["exploration_collection_count"]
	environment_decoration_label.text = "環境布置：%s" % _territory_data["environment_decoration_owned_count"]

func _refresh_reward_disclosure_display() -> void:
	var uses_internal_placeholder := str(_reward_disclosure_data.get("guaranteed_reward", "")).contains("[PLACEHOLDER]")
	if not bool(_reward_disclosure_data.get("is_valid", false)) or uses_internal_placeholder:
		guaranteed_reward_label.text = ""
		extra_reward_range_label.text = ""
		extra_reward_probability_label.text = ""
		extra_reward_note_label.text = ""
		if reward_details != null:
			reward_details.text = ""
		return
	guaranteed_reward_label.text = "保底報酬：%s" % _reward_disclosure_data["guaranteed_reward"]
	extra_reward_range_label.text = "額外報酬範圍：%s" % _reward_disclosure_data["extra_reward_range"]
	extra_reward_probability_label.text = "額外機率：%s" % _reward_disclosure_data["extra_reward_probability"]
	extra_reward_note_label.text = "未取得額外獎勵；保底報酬照常顯示" if bool(_reward_disclosure_data["extra_reward_is_zero"]) else "額外報酬依揭露範圍與機率顯示"
	if reward_details != null:
		reward_details.text = "%s｜%s｜%s" % [guaranteed_reward_label.text, extra_reward_range_label.text, extra_reward_probability_label.text]

func get_territory_exploration_status() -> Dictionary:
	var territory_id := str(_territory_data.get("territory_id", "territory_02"))
	var is_first_claim_saved := _touched_territory_ids.has(territory_id)
	return {
		"conditions": [{"label": "完成並保存首次任務收取成果", "is_met": is_first_claim_saved}],
		"can_explore": is_first_claim_saved,
	}

func _restore_latest_claim_receipt_display() -> void:
	var latest_receipt: Dictionary = {}
	var latest_claimed_at_seconds: int = -1
	for mission_run_id_variant: Variant in _lifecycle.get_persisted_runs()["mission_runs_by_id"]:
		var mission_run_id: String = str(mission_run_id_variant)
		var receipt_result: Dictionary = _lifecycle.get_claim_receipt(mission_run_id)
		if not bool(receipt_result["is_found"]):
			continue
		var receipt: Dictionary = Dictionary(receipt_result["receipt"])
		var claimed_at_seconds: int = int(receipt["claimed_at_seconds"])
		if claimed_at_seconds > latest_claimed_at_seconds:
			latest_claimed_at_seconds = claimed_at_seconds
			latest_receipt = receipt
	if not latest_receipt.is_empty():
		_show_claim_receipt(latest_receipt)

func _show_claim_receipt(receipt: Dictionary) -> void:
	claim_receipt_label.text = ""

## Refreshes only the displayed unaccepted mission using an explicit existing catalog entry.
func refresh_current_mission(current_time_seconds: int) -> void:
	if _is_waiting or _is_completed or _is_claimed:
		if not _is_completed:
			status_label.text = "無法刷新：任務已接受"
		_refresh_refresh_state()
		return
	if _current_missions.size() < 2:
		status_label.text = "無法刷新：缺少替換任務"
		return
	# Fixed T01–T23 task identities never change through refresh and consume no allowance.
	status_label.text = "無法刷新：新手固定任務不可替換"
	_refresh_refresh_state()
	return
	var replacements_by_mission_id: Dictionary = {_task_id: _current_missions[1].duplicate(true)}
	var accepted_mission_ids: Array[String] = []
	var refresh_result: Dictionary = _refresh_service.refresh(_current_missions, accepted_mission_ids, replacements_by_mission_id, current_time_seconds)
	_save_refresh_state()
	_refresh_refresh_state()
	if not bool(refresh_result["is_refreshed"]):
		status_label.text = "無法刷新：%s" % refresh_result["error_code"]
		return
	_current_missions = Array(refresh_result["missions"])
	_selected_crew_ids.clear()
	_load_current_mission()
	_refresh_selection_state()
	status_label.text = "任務已刷新"

## Updates the visible allowance with an injected timestamp for deterministic UI tests.
func update_refresh_allowance(current_time_seconds: int) -> void:
	var previous_data: Dictionary = _refresh_allowance.to_data()
	_refresh_allowance.update(current_time_seconds)
	if _refresh_allowance.to_data() != previous_data:
		_save_refresh_state()
	_refresh_refresh_state()

func _refresh_refresh_state() -> void:
	refresh_allowance_label.text = "刷新額度：%d/%d" % [_refresh_allowance.get_allowance(), MissionRefreshAllowanceScript.MAX_ALLOWANCE]
	refresh_next_available_label.text = "下次可用：%s" % _get_refresh_next_available_text()
	refreshable_mission_count_label.text = "可替換任務：0（新手固定任務）"
	refresh_button.disabled = true

func _get_refresh_next_available_text() -> String:
	if _refresh_allowance.get_allowance() >= MissionRefreshAllowanceScript.MAX_ALLOWANCE:
		return "已滿額"
	var refresh_data: Dictionary = _refresh_allowance.to_data()
	return str(int(refresh_data["last_refill_check_seconds"]) + MissionRefreshAllowanceScript.REFILL_INTERVAL_SECONDS)

func _save_refresh_state() -> Dictionary:
	if not _is_player_state_ready:
		return _refresh_state_store.save(_refresh_allowance)
	return _save_player_state()

func _process(_delta: float) -> void:
	if _is_recovery_hold:
		return
	refresh_execution_status(_get_current_time_seconds())
	update_refresh_allowance(_get_current_time_seconds())

## Updates the visual execution state from an injected timestamp for deterministic UI tests.
func refresh_execution_status(current_time_seconds: int) -> void:
	if not _is_waiting:
		return
	var clock: Variant = _snapshot_collection.restore_clock(_task_id)
	if clock == null:
		status_label.text = "等待狀態無法讀取"
		return
	var remaining_seconds: int = clock.get_remaining_seconds(current_time_seconds)
	if remaining_seconds > 0:
		status_label.text = "等待中：剩餘 %d 秒" % remaining_seconds
		return
	var resolution: Dictionary = _lifecycle.resolve_completed_result(_task_id, current_time_seconds)
	if not bool(resolution["is_resolved"]):
		status_label.text = "完成狀態無法讀取"
		return
	var save_result: Dictionary = _save_execution_state()
	if not bool(save_result["is_saved"]):
		status_label.text = "結果已鎖定，但保存失敗：%s" % save_result["error_code"]
		return
	_is_waiting = false
	_is_completed = true
	_record_tutorial_event("tutorial_task_completed", _task_id, "claimable", _task_id)
	_record_tutorial_event("tutorial_result_locked", _task_id, "locked", _task_id, {"result_id": str(Dictionary(resolution["result"]).get("result_id", ""))})
	start_button.disabled = true
	claim_button.disabled = false
	_refresh_refresh_state()
	status_label.text = "任務已完成"
	_apply_detail_state_visibility()
	directory_changed.emit()

func _restore_saved_execution(current_time_seconds: int) -> void:
	if _result_state.is_claimed(_task_id):
		_is_claimed = true
		for choice: CheckButton in crew_selector.get_children():
			choice.disabled = true
		start_button.disabled = true
		claim_button.disabled = true
		_refresh_refresh_state()
		status_label.text = "已領取／保底報酬待定"
		return
	if not _result_state.get_locked_result(_task_id).is_empty():
		# Rebuild the transient assignment so the completed crew stays unavailable and
		# can be released only by the successful claim transaction.
		var completed_crew_ids: Array[String] = _get_saved_crew_ids(_task_id)
		for completed_crew_id: String in completed_crew_ids:
			_game_state.set_crew_status(completed_crew_id, GameStateScript.CrewStatus.AVAILABLE)
		var completed_assignment_result: Dictionary = _assignment_coordinator.accept_assignment(_task_id, completed_crew_ids)
		if not bool(completed_assignment_result["is_accepted"]):
			status_label.text = "完成任務無法還原：%s" % completed_assignment_result["error_code"]
			return
		var completed_state_result: Dictionary = _assignment_coordinator.mark_assignment_completed(_task_id)
		if not bool(completed_state_result["is_completed"]):
			status_label.text = "完成任務無法還原：%s" % completed_state_result["error_code"]
			return
		_is_completed = true
		start_button.disabled = true
		claim_button.disabled = false
		_refresh_refresh_state()
		status_label.text = "任務已完成"
		return
	var clock: Variant = _snapshot_collection.restore_clock(_task_id)
	if clock == null:
		return
	var restored_crew_ids: Array[String] = _get_saved_crew_ids(_task_id)
	# The envelope records authoritative crew status. Rebuild the transient assignment
	# index from the saved task, then let the coordinator mark these crew dispatched.
	for restored_crew_id: String in restored_crew_ids:
		_game_state.set_crew_status(restored_crew_id, GameStateScript.CrewStatus.AVAILABLE)
	var assignment_result: Dictionary = _assignment_coordinator.accept_assignment(_task_id, restored_crew_ids)
	if not bool(assignment_result["is_accepted"]):
		status_label.text = "任務保存無法還原：%s" % assignment_result["error_code"]
		return
	_selected_crew_ids = restored_crew_ids
	for choice: CheckButton in crew_selector.get_children():
		choice.disabled = true
	if clock.is_completed(current_time_seconds):
		_is_waiting = true
		refresh_execution_status(current_time_seconds)
		return
	_is_waiting = true
	start_button.disabled = true
	_refresh_refresh_state()
	status_label.text = "等待中：剩餘 %d 秒" % clock.get_remaining_seconds(current_time_seconds)

func _save_execution_state() -> Dictionary:
	_capture_result_state()
	return _save_player_state()

func _save_player_state() -> Dictionary:
	_capture_result_state()
	var execution_payload: Dictionary = MissionExecutionStateStoreScript.make_payload(_snapshot_collection, _result_state, _crew_ids_by_task, _lifecycle.get_persisted_runs())
	if execution_payload.is_empty():
		return {"is_saved": false, "error_code": "execution_state_store_crew_ids_invalid"}
	var envelope: Dictionary = PlayerSaveEnvelopeStoreScript.make_envelope(
		_game_state.get_crew(),
		_current_missions,
		execution_payload,
		_claim_receipt_collection.to_data(),
		_refresh_allowance.to_data(),
		{str(_territory_data["territory_id"]): _territory_data},
		_territory_touch_receipts_by_id,
		{"tutorial_claimed_task_ids": _lifecycle._claimed_task_ids.duplicate(true), "tutorial_claimed_mission_run_ids": _lifecycle._claimed_mission_run_ids.duplicate(true)}
	)
	return _player_save_store.save(envelope)

func _get_player_save_store_path() -> String:
	if not player_save_store_path.is_empty():
		return player_save_store_path
	return "%s.envelope" % execution_state_store_path

func _restore_territory_touch_maps_from_receipts() -> bool:
	var restored_touched_territory_ids: Dictionary = {}
	var restored_unlocked_crew_ids: Dictionary = {}
	var restored_source_receipt_ids: Dictionary = {}
	for territory_id_variant: Variant in _territory_touch_receipts_by_id:
		var territory_id: String = str(territory_id_variant)
		var receipt: Dictionary = Dictionary(_territory_touch_receipts_by_id[territory_id])
		if str(receipt.get("territory_id", "")) != territory_id or str(receipt.get("source_claim_receipt_id", "")).is_empty() or str(receipt.get("unlocked_crew_id", "")).is_empty():
			return false
		restored_touched_territory_ids[territory_id] = true
		restored_unlocked_crew_ids[territory_id] = str(receipt["unlocked_crew_id"])
		restored_source_receipt_ids[territory_id] = str(receipt["source_claim_receipt_id"])
	_touched_territory_ids = restored_touched_territory_ids
	_unlocked_crew_ids_by_territory = restored_unlocked_crew_ids
	_source_claim_receipt_ids_by_territory = restored_source_receipt_ids
	return true

func _restore_result_state() -> void:
	var result_data: Dictionary = _result_state.to_data()
	_lifecycle._locked_results_by_mission_run_id = result_data["locked_results_by_mission_run_id"].duplicate(true)
	_lifecycle._claimed_mission_run_ids = result_data["claimed_mission_run_ids"].duplicate(true)
	_lifecycle._locked_results_by_task_id = {}
	_lifecycle._claimed_task_ids = {}
	for mission_run_id_variant: Variant in _lifecycle._locked_results_by_mission_run_id:
		var mission_run_id: String = str(mission_run_id_variant)
		var result: Dictionary = Dictionary(_lifecycle._locked_results_by_mission_run_id[mission_run_id])
		var task_id: String = str(result.get("task_id", ""))
		if task_id.is_empty():
			continue
		_lifecycle._locked_results_by_task_id[task_id] = result.duplicate(true)
		if _lifecycle._claimed_mission_run_ids.has(mission_run_id):
			_lifecycle._claimed_task_ids[task_id] = true

func _capture_result_state() -> void:
	_result_state = MissionResultStateSnapshotScript.new(_lifecycle._locked_results_by_mission_run_id, _lifecycle._claimed_mission_run_ids)

func _get_saved_crew_ids(task_id: String) -> Array[String]:
	var crew_ids: Array[String] = []
	for crew_id_variant: Variant in Array(_crew_ids_by_task.get(task_id, [])):
		crew_ids.append(str(crew_id_variant))
	return crew_ids

func _get_current_time_seconds() -> int:
	if current_time_override >= 0:
		return current_time_override
	return int(Time.get_unix_time_from_system())

func _record_tutorial_event(event_name: String, tutorial_step_id: String, outcome: String, mission_id: String, details: Dictionary = {}) -> void:
	if _tutorial_event_logger == null:
		return
	_tutorial_event_logger.record(event_name, tutorial_step_id, _get_current_time_seconds(), outcome, mission_id, details)

func _show_next_tutorial_task() -> void:
	var next_task: Dictionary = _tutorial_progression.get_current_task()
	if next_task.is_empty():
		next_tutorial_task_label.text = "新手任務已完成"
		return
	next_tutorial_task_label.text = "下一個任務：%s（%d 秒）" % [_client_mission_title(str(next_task["id"])), next_task["duration_seconds"]]

func _client_mission_title(task_id: String) -> String:
	if task_id.begins_with("starter_"):
		return "新手任務 %02d" % int(task_id.trim_prefix("starter_"))
	return "任務"

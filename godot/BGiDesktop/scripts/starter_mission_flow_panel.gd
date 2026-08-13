class_name StarterMissionFlowPanel
extends PanelContainer

const GameStateScript = preload("res://scripts/game_state.gd")
const MissionAssignmentStateScript = preload("res://scripts/mission_assignment_state.gd")
const AssignmentCoordinatorScript = preload("res://scripts/persistent_mission_assignment_coordinator.gd")
const ValidityQueryScript = preload("res://scripts/mission_execution_validity_query.gd")
const ExpiredReleaseServiceScript = preload("res://scripts/mission_expired_release_service.gd")
const SnapshotCollectionScript = preload("res://scripts/mission_execution_snapshot_collection.gd")
const MissionLifecycleCoordinatorScript = preload("res://scripts/mission_lifecycle_coordinator.gd")
const MissionExecutionStateStoreScript = preload("res://scripts/mission_execution_state_store.gd")
const MissionResultStateSnapshotScript = preload("res://scripts/mission_result_state_snapshot.gd")
const MissionRefreshAllowanceScript = preload("res://scripts/mission_refresh_allowance.gd")
const MissionRefreshServiceScript = preload("res://scripts/mission_refresh_service.gd")
const TerritoryFirstTouchUnlockScript = preload("res://scripts/territory_first_touch_unlock.gd")
const TerritoryProgressModelScript = preload("res://scripts/territory_progress_model.gd")
const MissionRewardDisclosureModelScript = preload("res://scripts/mission_reward_disclosure_model.gd")
const TutorialTaskProgressionScript = preload("res://scripts/tutorial_task_progression.gd")
const TutorialMissionCompletionCoordinatorScript = preload("res://scripts/tutorial_mission_completion_coordinator.gd")

@onready var task_label: Label = %TaskLabel
@onready var requirement_label: Label = %RequirementLabel
@onready var crew_selector: HBoxContainer = %CrewSelector
@onready var status_label: Label = %StatusLabel
@onready var start_button: Button = %StartButton
@onready var refresh_allowance_label: Label = %RefreshAllowanceLabel
@onready var refresh_button: Button = %RefreshButton
@onready var territory_progress_label: Label = %TerritoryProgressLabel
@onready var exploration_collection_label: Label = %ExplorationCollectionLabel
@onready var environment_decoration_label: Label = %EnvironmentDecorationLabel
@onready var explore_territory_button: Button = %ExploreTerritoryButton
@onready var guaranteed_reward_label: Label = %GuaranteedRewardLabel
@onready var extra_reward_range_label: Label = %ExtraRewardRangeLabel
@onready var extra_reward_probability_label: Label = %ExtraRewardProbabilityLabel
@onready var extra_reward_note_label: Label = %ExtraRewardNoteLabel
@onready var next_tutorial_task_label: Label = %NextTutorialTaskLabel

@export var execution_state_store_path: String = "user://starter_mission_flow_state.json"
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
var _result_state: RefCounted
var _crew_ids_by_task: Dictionary = {}
var _refresh_allowance: RefCounted
var _refresh_service: RefCounted
var _touched_territory_ids: Dictionary = {}
var _territory_data: Dictionary = {}
var _reward_disclosure_data: Dictionary = {}
var _is_waiting: bool = false
var _is_completed: bool = false

func _ready() -> void:
	_game_state = get_node("/root/GameState") as Node
	_starter_mission_catalog = get_node("/root/StarterMissionCatalog") as Node
	_assignment_state = MissionAssignmentStateScript.new()
	_assignment_coordinator = AssignmentCoordinatorScript.new(_game_state, _assignment_state)
	var validity_query: RefCounted = ValidityQueryScript.new()
	var expired_release_service: RefCounted = ExpiredReleaseServiceScript.new(_assignment_coordinator, _assignment_state, validity_query)
	_execution_state_store = MissionExecutionStateStoreScript.new(execution_state_store_path)
	var execution_state_result: Dictionary = _execution_state_store.load()
	_snapshot_collection = execution_state_result["collection"]
	_result_state = execution_state_result["result_state"]
	_crew_ids_by_task = Dictionary(execution_state_result["crew_ids_by_task"]).duplicate(true)
	_lifecycle = MissionLifecycleCoordinatorScript.new(_assignment_coordinator, expired_release_service, _snapshot_collection)
	_restore_result_state()
	var current_time_seconds: int = _get_current_time_seconds()
	_refresh_allowance = MissionRefreshAllowanceScript.new(current_time_seconds - MissionRefreshAllowanceScript.REFILL_INTERVAL_SECONDS)
	_refresh_allowance.update(current_time_seconds)
	_refresh_service = MissionRefreshServiceScript.new(_refresh_allowance)
	_territory_data = TerritoryProgressModelScript.create("territory_01")
	_load_first_starter_mission()
	_tutorial_progression = TutorialTaskProgressionScript.new(_current_missions)
	_tutorial_completion_coordinator = TutorialMissionCompletionCoordinatorScript.new(_tutorial_progression, _assignment_state, validity_query)
	_render_crew_choices()
	start_button.pressed.connect(_on_start_pressed)
	refresh_button.pressed.connect(_on_refresh_pressed)
	explore_territory_button.pressed.connect(_on_explore_territory_pressed)
	_refresh_selection_state()
	_refresh_refresh_state()
	_refresh_territory_growth_display()
	_refresh_reward_disclosure_display()
	_restore_saved_execution(current_time_seconds)

func _load_first_starter_mission() -> void:
	_current_missions = _starter_mission_catalog.get_missions()
	_load_current_mission()

func _load_current_mission() -> void:
	if _current_missions.is_empty():
		task_label.text = "新手任務：無可用任務"
		status_label.text = "任務資料不可用"
		start_button.disabled = true
		return
	var mission: Dictionary = _current_missions[0]
	_task_id = str(mission["id"])
	_duration_seconds = int(mission["duration_seconds"])
	_reward_disclosure_data = MissionRewardDisclosureModelScript.create(_task_id, false)
	_refresh_reward_disclosure_display()
	task_label.text = "新手任務：%s（%d 秒）" % [_task_id, _duration_seconds]
	requirement_label.text = "需要 %d–%d 名小弟" % [DispatchRules.MIN_ASSIGNEES, DispatchRules.MAX_ASSIGNEES]

func _render_crew_choices() -> void:
	for crew_member: Dictionary in _game_state.get_crew():
		var crew_id: String = str(crew_member["id"])
		var choice: CheckButton = CheckButton.new()
		choice.text = "小弟 %s" % crew_id.trim_prefix("crew_")
		choice.tooltip_text = "可用" if int(crew_member["status"]) == GameStateScript.CrewStatus.AVAILABLE else "派遣中"
		choice.disabled = int(crew_member["status"]) != GameStateScript.CrewStatus.AVAILABLE
		choice.toggled.connect(_on_crew_toggled.bind(crew_id))
		crew_selector.add_child(choice)

func _on_crew_toggled(pressed: bool, crew_id: String) -> void:
	if _is_waiting or _is_completed:
		return
	if pressed:
		if not _selected_crew_ids.has(crew_id):
			_selected_crew_ids.append(crew_id)
	else:
		_selected_crew_ids.erase(crew_id)
	_refresh_selection_state()

func _refresh_selection_state() -> void:
	var selected_count: int = _selected_crew_ids.size()
	start_button.disabled = _is_waiting or _is_completed or selected_count < DispatchRules.MIN_ASSIGNEES or selected_count > DispatchRules.MAX_ASSIGNEES
	if not _is_waiting and not _is_completed:
		status_label.text = "已選 %d/%d 名小弟" % [selected_count, DispatchRules.MAX_ASSIGNEES]

func _on_start_pressed() -> void:
	if _is_waiting or _is_completed:
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
	for choice: CheckButton in crew_selector.get_children():
		choice.disabled = true
	start_button.disabled = true
	status_label.text = "等待中：已派遣 %d 名小弟" % _selected_crew_ids.size()
	_refresh_refresh_state()

func _on_refresh_pressed() -> void:
	refresh_current_mission(_get_current_time_seconds())

func _on_explore_territory_pressed() -> void:
	var touch_result: Dictionary = TerritoryFirstTouchUnlockScript.touch(str(_territory_data["territory_id"]), _touched_territory_ids)
	_touched_territory_ids = Dictionary(touch_result["touched_territory_ids"]).duplicate(true)
	if bool(touch_result["is_unlock_granted"]):
		status_label.text = "首次觸及：已解鎖 1 名新人物"
		return
	status_label.text = "已探索此地盤：不重複解鎖"

func _refresh_territory_growth_display() -> void:
	territory_progress_label.text = "地盤進度：%s" % _territory_data["territory_progress"]
	exploration_collection_label.text = "探索收藏：%s" % _territory_data["exploration_collection_count"]
	environment_decoration_label.text = "環境布置：%s" % _territory_data["environment_decoration_owned_count"]

func _refresh_reward_disclosure_display() -> void:
	guaranteed_reward_label.text = "保底報酬：%s" % _reward_disclosure_data["guaranteed_reward"]
	extra_reward_range_label.text = "額外報酬範圍：%s" % _reward_disclosure_data["extra_reward_range"]
	extra_reward_probability_label.text = "額外機率：%s" % _reward_disclosure_data["extra_reward_probability"]
	extra_reward_note_label.text = "額外報酬為 0；保底報酬照常顯示" if bool(_reward_disclosure_data["extra_reward_is_zero"]) else "額外報酬依揭露範圍與機率顯示"

## Refreshes only the displayed unaccepted mission using an explicit existing catalog entry.
func refresh_current_mission(current_time_seconds: int) -> void:
	if _is_waiting or _is_completed:
		if not _is_completed:
			status_label.text = "無法刷新：任務已接受"
		_refresh_refresh_state()
		return
	if _current_missions.size() < 2:
		status_label.text = "無法刷新：缺少替換任務"
		return
	var replacements_by_mission_id: Dictionary = {_task_id: _current_missions[1].duplicate(true)}
	var accepted_mission_ids: Array[String] = []
	var refresh_result: Dictionary = _refresh_service.refresh(_current_missions, accepted_mission_ids, replacements_by_mission_id, current_time_seconds)
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
	_refresh_allowance.update(current_time_seconds)
	_refresh_refresh_state()

func _refresh_refresh_state() -> void:
	refresh_allowance_label.text = "刷新額度：%d/%d" % [_refresh_allowance.get_allowance(), MissionRefreshAllowanceScript.MAX_ALLOWANCE]
	refresh_button.disabled = _is_waiting or _is_completed or _refresh_allowance.get_allowance() == 0

func _process(_delta: float) -> void:
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
	var tutorial_result: Dictionary = _tutorial_completion_coordinator.complete_current_task(_task_id, clock, current_time_seconds)
	if bool(tutorial_result["is_completed"]):
		_show_next_tutorial_task()
	for choice: CheckButton in crew_selector.get_children():
		choice.disabled = true
	start_button.disabled = true
	status_label.text = "已完成／保底報酬待定"

func _restore_saved_execution(current_time_seconds: int) -> void:
	var clock: Variant = _snapshot_collection.restore_clock(_task_id)
	if clock == null:
		return
	var restored_crew_ids: Array[String] = _get_saved_crew_ids(_task_id)
	var assignment_result: Dictionary = _assignment_coordinator.accept_assignment(_task_id, restored_crew_ids)
	if not bool(assignment_result["is_accepted"]):
		status_label.text = "任務保存無法還原：%s" % assignment_result["error_code"]
		return
	_selected_crew_ids = restored_crew_ids
	for choice: CheckButton in crew_selector.get_children():
		choice.disabled = true
	if not _result_state.get_locked_result(_task_id).is_empty():
		_is_completed = true
		start_button.disabled = true
		status_label.text = "已完成／保底報酬待定"
		return
	if clock.is_completed(current_time_seconds):
		_is_waiting = true
		refresh_execution_status(current_time_seconds)
		return
	_is_waiting = true
	start_button.disabled = true
	status_label.text = "等待中：剩餘 %d 秒" % clock.get_remaining_seconds(current_time_seconds)

func _save_execution_state() -> Dictionary:
	_capture_result_state()
	return _execution_state_store.save(_snapshot_collection, _result_state, _crew_ids_by_task)

func _restore_result_state() -> void:
	var result_data: Dictionary = _result_state.to_data()
	_lifecycle._locked_results_by_task_id = result_data["locked_results_by_task_id"].duplicate(true)
	_lifecycle._claimed_task_ids = result_data["claimed_task_ids"].duplicate(true)

func _capture_result_state() -> void:
	_result_state = MissionResultStateSnapshotScript.new(_lifecycle._locked_results_by_task_id, _lifecycle._claimed_task_ids)

func _get_saved_crew_ids(task_id: String) -> Array[String]:
	var crew_ids: Array[String] = []
	for crew_id_variant: Variant in Array(_crew_ids_by_task.get(task_id, [])):
		crew_ids.append(str(crew_id_variant))
	return crew_ids

func _get_current_time_seconds() -> int:
	if current_time_override >= 0:
		return current_time_override
	return int(Time.get_unix_time_from_system())

func _show_next_tutorial_task() -> void:
	var next_task: Dictionary = _tutorial_progression.get_current_task()
	if next_task.is_empty():
		next_tutorial_task_label.text = "新手任務已完成"
		return
	next_tutorial_task_label.text = "下一個新手任務：%s（%d 秒）" % [next_task["id"], next_task["duration_seconds"]]

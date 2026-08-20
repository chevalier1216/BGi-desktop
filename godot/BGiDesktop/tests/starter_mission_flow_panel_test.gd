extends SceneTree

const StarterMissionFlowPanelScene = preload("res://scenes/starter_mission_flow_panel.tscn")

var _failed: bool = false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var panel: StarterMissionFlowPanel = StarterMissionFlowPanelScene.instantiate() as StarterMissionFlowPanel
	root.add_child(panel)
	_expect(panel.crew_selector.get_child_count() == 5, "starter flow must display exactly five crew choices")
	_expect(panel.start_button.disabled, "task must not start without the minimum crew")
	_expect(panel.status_label.text == "已選 0/5 名小弟", "zero selected crew members must be visibly shown and cannot start")
	_expect(panel.territory_progress_label.text == "地盤進度：[PLACEHOLDER]", "territory progress must remain a placeholder")
	_expect(panel.exploration_collection_label.text == "探索收藏：[PLACEHOLDER]", "exploration collection must remain a placeholder")
	_expect(panel.environment_decoration_label.text == "環境布置：[PLACEHOLDER]", "environment decoration must remain a placeholder")
	_expect(panel.guaranteed_reward_label.text == "保底報酬：[PLACEHOLDER]", "card must disclose the guaranteed reward placeholder")
	_expect(panel.extra_reward_range_label.text == "額外報酬範圍：[PLACEHOLDER]", "card must disclose the extra reward range placeholder")
	_expect(panel.extra_reward_probability_label.text == "額外機率：[PLACEHOLDER]", "card must disclose the extra reward probability placeholder")
	_expect(panel.extra_reward_note_label.text == "未取得額外獎勵；保底報酬照常顯示", "zero extra reward must use the specified neutral guaranteed-reward presentation")
	_expect(not panel.extra_reward_note_label.text.contains("失敗") and not panel.extra_reward_note_label.text.contains("空手"), "zero extra reward must not use failure or empty-handed wording")
	_expect(panel.explore_territory_button.disabled, "territory touch must not be directly available before a persisted claim")
	panel.explore_territory_button.emit_signal("pressed")
	_expect(panel.status_label.text == "地盤會在收取成果後觸及", "direct territory input must explain the claim requirement")
	_expect(panel._touched_territory_ids.is_empty(), "direct territory input must not create a touch before a persisted claim")
	_expect(panel.refresh_allowance_label.text == "刷新額度：1/1", "starter flow must show one available refresh")
	_expect(not panel.refresh_button.disabled, "unaccepted task with one allowance must enable refresh")
	var initial_task_id: String = panel._task_id
	var initial_time_seconds: int = int(Time.get_unix_time_from_system())
	panel.refresh_current_mission(initial_time_seconds)
	_expect(panel._task_id == initial_task_id, "refresh must preserve an unaccepted fixed tutorial task id")
	_expect(panel.refresh_allowance_label.text == "刷新額度：1/1", "fixed tutorial refresh must not consume allowance")
	_expect(not panel.refresh_button.disabled, "fixed tutorial refresh must remain available without consuming allowance")
	panel.update_refresh_allowance(initial_time_seconds + 6 * 60 * 60)
	_expect(panel.refresh_allowance_label.text == "刷新額度：1/1", "refresh allowance must refill after six hours without exceeding one")
	_expect(not panel.refresh_button.disabled, "refilled allowance must enable refresh without exceeding one")

	var first_choice: CheckButton = panel.crew_selector.get_child(0) as CheckButton
	first_choice.button_pressed = true
	first_choice.emit_signal("toggled", true)
	_expect(panel.status_label.text == "已選 1/5 名小弟", "one selected crew member must be visibly shown")
	_expect(not panel.start_button.disabled, "one selected crew member must satisfy the minimum")
	for index: int in range(1, 3):
		var choice: CheckButton = panel.crew_selector.get_child(index) as CheckButton
		choice.button_pressed = true
		choice.emit_signal("toggled", true)
	_expect(panel.status_label.text == "已選 3/5 名小弟", "three selected crew members must be visibly shown")
	for index: int in range(3, 5):
		var choice: CheckButton = panel.crew_selector.get_child(index) as CheckButton
		choice.button_pressed = true
		choice.emit_signal("toggled", true)
	_expect(panel.status_label.text == "已選 5/5 名小弟", "five selected crew members must be visibly shown")
	panel.start_button.emit_signal("pressed")
	_expect(panel.status_label.text == "等待中：已派遣 5 名小弟", "started task must retain the selected crew count")
	_expect(panel.start_button.disabled, "waiting task must disable a second start")
	_expect(panel.refresh_button.disabled, "waiting task must disable refresh")
	for choice: CheckButton in panel.crew_selector.get_children():
		_expect(choice.disabled, "waiting task must lock all crew choices")
	panel._on_crew_toggled(false, "crew_01")
	_expect(panel._selected_crew_ids.size() == 5, "waiting task must not allow its dispatched crew count to change")
	var waiting_task_id: String = panel._task_id
	panel.refresh_current_mission(initial_time_seconds + 6 * 60 * 60)
	_expect(panel._task_id == waiting_task_id, "accepted waiting task must not be replaced")
	_expect(panel.refresh_allowance_label.text == "刷新額度：1/1", "rejected waiting refresh must not consume allowance")
	var clock: RefCounted = panel._snapshot_collection.restore_clock(panel._task_id)
	var started_at_seconds: int = clock.started_at_seconds
	panel.refresh_execution_status(started_at_seconds + 2)
	_expect(panel.status_label.text == "等待中：剩餘 3 秒", "waiting task must show the remaining duration")
	panel.refresh_execution_status(started_at_seconds + 5)
	_expect(panel.status_label.text == "已完成／保底報酬待定", "expired task must show a guaranteed pending reward state")
	var completed_text: String = panel.status_label.text
	var locked_result: Dictionary = Dictionary(panel._lifecycle._locked_results_by_task_id[panel._task_id]).duplicate(true)
	_expect(panel.start_button.disabled, "completed task must keep the start control disabled")
	_expect(panel.refresh_button.disabled, "completed task must disable refresh")
	for choice: CheckButton in panel.crew_selector.get_children():
		_expect(choice.disabled, "completed task must keep every crew choice disabled")
	panel._on_crew_toggled(false, "crew_01")
	_expect(panel._selected_crew_ids.size() == 5, "completed task must not allow its dispatched crew count to change")
	var completed_task_id: String = panel._task_id
	panel.refresh_current_mission(initial_time_seconds + 12 * 60 * 60)
	_expect(panel._task_id == completed_task_id, "completed task must not be refreshed")
	_expect(panel.refresh_allowance_label.text == "刷新額度：1/1", "completed refresh attempt must not consume allowance")
	_expect(panel.status_label.text == completed_text, "completed refresh attempt must keep the fixed completed presentation")
	panel.start_button.emit_signal("pressed")
	_expect(panel.status_label.text == completed_text, "completed task must not replace its fixed result after a second start attempt")
	_expect(Dictionary(panel._lifecycle._locked_results_by_task_id[panel._task_id]) == locked_result, "completed task must not resolve a second result after a second start attempt")
	panel.refresh_execution_status(started_at_seconds + 20)
	_expect(panel.status_label.text == completed_text, "repeated completion updates must keep the settled state")
	_expect(Dictionary(panel._lifecycle._locked_results_by_task_id[panel._task_id]) == locked_result, "repeated completion updates must not resolve a second result")

	panel.queue_free()
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("StarterMissionFlowPanel test failed: %s" % message)

extends SceneTree

# Regression reproduction: press a bottom entry in the 450px desktop window. Before the
# fix, the child Window was embedded and clipped, so it had neither a native title bar
# for drag/close nor usable space outside the parent window. Expected: independent native
# window, close event hides it, and a later entry is initially cascaded rather than stacked.

const DesktopShellScene = preload("res://scenes/desktop_shell.tscn")
const KARAT_ROOT: String = "res://assets/third_party/subversionary_24_karat_gui/extracted/24K GUI/game/gui/"
const POPUP_MARGIN := 24

var _failed: bool = false
var _apply_requests: int = 0
var _defer_requests: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await _exercise_visual()
	await process_frame
	print("DesktopShellKaratVisual: PASS" if not _failed else "DesktopShellKaratVisual: FAIL")
	quit(1 if _failed else 0)

func _exercise_visual() -> void:
	var shell = DesktopShellScene.instantiate()
	root.add_child(shell)
	_expect(not (shell.get_node("Margin") as Control).visible, "legacy three-column shell must not remain visible")
	_expect(_resource_path(shell.get_node("TerrainStage/KaratFrameBorder") as TextureRect) == KARAT_ROOT + "frame_border.png", "full terrain stage must use the 24 Karat frame border")
	_expect(shell.get_node("TerrainStage") != null, "desktop must keep a full terrain stage behind the bottom entry bar")
	(shell.get_node("BottomPersistentBar/Entries/TerritoryEntry/Button") as Button).emit_signal("pressed")
	_expect(shell._popup_windows.has("territory"), "territory entry must open an in-app popup overlay")
	var territory_window := shell._popup_windows["territory"] as Control
	_expect(territory_window is PanelContainer and territory_window.has_node("PopupLayout/Header/CloseButton"), "territory entry must use an in-app overlay with close control")
	_expect((territory_window.get_node("PopupLayout/Header") as Control).mouse_filter == Control.MOUSE_FILTER_STOP, "popup header must capture drag input")
	_expect(shell._popup_stack.back() == "territory", "opened popup must be top of popup stack")
	var window_controller := root.get_node_or_null("DesktopWindowController")
	_expect(window_controller != null and not window_controller._mouse_passthrough_polygon.is_empty(), "drawn desktop controls must define a click-through hit region")
	var header := territory_window.get_node("PopupLayout/Header") as Control
	var original_position := territory_window.global_position
	var drag_press := InputEventMouseButton.new()
	drag_press.button_index = MOUSE_BUTTON_LEFT
	drag_press.pressed = true
	drag_press.global_position = original_position + Vector2(20, 20)
	shell._on_popup_header_input(drag_press, territory_window)
	var drag_motion := InputEventMouseMotion.new()
	drag_motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	drag_motion.global_position = original_position + Vector2(100, 20)
	shell._on_popup_header_input(drag_motion, territory_window)
	_expect(territory_window.global_position.x > original_position.x, "dragging a panel header must move the panel within the desktop host")
	_expect(territory_window.global_position.x >= 0.0 and territory_window.global_position.y >= 0.0, "dragged panel must remain inside the desktop host")
	var drag_release := InputEventMouseButton.new()
	drag_release.button_index = MOUSE_BUTTON_LEFT
	drag_release.pressed = false
	shell._on_popup_header_input(drag_release, territory_window)
	shell._on_popup_close_requested("territory")
	_expect(not territory_window.visible, "in-app close action must hide the popup")
	(shell.get_node("BottomPersistentBar/Entries/TerritoryEntry/Button") as Button).emit_signal("pressed")
	_expect(territory_window.visible, "opening the same entry after close must restore the popup")
	(shell.get_node("BottomPersistentBar/Entries/MarketEntry/Button") as Button).emit_signal("pressed")
	_expect(shell._popup_windows.has("market"), "market entry must open an in-app popup overlay")
	_expect((shell._popup_windows["market"] as Control).visible, "market overlay must be visible")
	var escape_event := InputEventKey.new()
	escape_event.keycode = KEY_ESCAPE
	escape_event.pressed = true
	shell._input(escape_event)
	_expect(not (shell._popup_windows["market"] as Control).visible and territory_window.visible, "ESC must close the topmost popup and preserve lower z-order panels")
	(shell.get_node("BottomPersistentBar/Entries/CrewEntry/Button") as Button).emit_signal("pressed")
	_expect(shell._popup_windows.has("crew"), "crew entry must open an in-app popup overlay")
	(shell.get_node("BottomPersistentBar/Entries/CollectionEntry/Button") as Button).emit_signal("pressed")
	_expect(shell._popup_windows.has("collection"), "collection entry must open an in-app popup overlay")
	(shell.get_node("BottomPersistentBar/Entries/SettingsEntry/Button") as Button).emit_signal("pressed")
	_expect(shell._popup_windows.has("settings"), "settings entry must open an in-app popup overlay")
	_expect(not shell.has_node("TerrainStage/Content/SettingsActions"), "layout density controls must not be exposed on the main desktop shell")
	(shell.get_node("TerrainStage/Content/TaskWindowButton") as Button).emit_signal("pressed")
	_expect(shell._mission_panel != null, "task entry must open an task and collection in-app overlays")
	var task_window := shell._popup_windows["tasks"] as Control
	var current_missions := task_window.get_node_or_null("PopupLayout/Content/Content/CurrentMissions") as VBoxContainer
	_expect(current_missions != null and current_missions.get_child_count() > 1, "mission directory must render at least one actual task entry")
	if current_missions != null and current_missions.get_child_count() > 1:
		var first_task := current_missions.get_child(1) as Button
		_expect(first_task != null, "mission directory entry must be actionable")
		if first_task != null:
			first_task.emit_signal("pressed")
			await process_frame
			var detail_popup := shell._popup_windows["task_detail"] as Control
			_expect(detail_popup.visible and not shell._mission_panel.task_label.text.is_empty(), "mission detail must render the selected task content")
			_expect(detail_popup.global_position.y >= POPUP_MARGIN, "an oversized task detail must keep its draggable header within the desktop host")
			var detail_header := detail_popup.get_node("PopupLayout/Header") as Control
			_expect(detail_header.get_global_rect().intersects(shell.get_global_rect()), "task detail header must remain visibly reachable in the desktop host")
			_expect(shell._popup_stack.back() == "task_detail", "opening mission detail must promote it to topmost z-order")
	shell._on_popup_close_requested("tasks")
	await process_frame
	_expect(not task_window.visible, "closing the task directory must hide the in-app popup safely")
	_expect(not task_window.has_focus(), "closing the task directory must release stale popup focus")
	(shell.get_node("TerrainStage/Content/TaskWindowButton") as Button).emit_signal("pressed")
	await process_frame
	_expect(task_window.visible, "reopening the task directory after in-app close must restore the same popup")
	_expect(not window_controller._mouse_passthrough_polygon.is_empty(), "reopening a popup must rebuild the active hit region")
	_expect(shell._mission_panel != null and is_instance_valid(shell._mission_panel), "reopening the task directory must retain a valid mission panel")
	for popup_key: String in ["territory", "market", "crew", "collection", "settings", "tasks"]:
		var popup := shell._popup_windows[popup_key] as Control
		_expect(popup is PanelContainer and popup.has_node("PopupLayout/Header/CloseButton"), "all shared desktop popups must use the in-app Control overlay: %s" % popup_key)
		_expect(not _contains_internal_client_copy(popup), "client popup must not expose internal placeholder or implementation copy: %s" % popup_key)
	_expect(shell._mission_panel.has_node("Content/TaskDescriptionScroll"), "task popup must provide a scrollable mission description area")
	_expect(not shell._mission_panel.has_node("Scroll"), "only the mission description may scroll; the full task window must keep its controls in a fixed layout")
	_expect((shell._popup_windows["task_detail"] as Control).size.x >= 760 and (shell._popup_windows["task_detail"] as Control).size.y >= 820, "task detail popup must reserve enough in-app overlay space for its fixed task, crew and reward sections")
	_expect(shell._mission_panel.crew_selector is HFlowContainer, "task popup must arrange crew as independent icon cards")
	_expect(shell._mission_panel.crew_selector.get_child_count() == 5, "task popup must expose all initial crew cards")
	var first_crew := shell._mission_panel.crew_selector.get_child(0) as CheckButton
	_expect(first_crew.has_meta("selected_overlay") and first_crew.has_meta("unavailable_overlay"), "crew cards must have selected and unavailable overlays")
	first_crew.button_pressed = true
	shell._mission_panel._refresh_crew_card_overlays()
	_expect((first_crew.get_meta("selected_overlay") as ColorRect).visible, "selected crew card must show its selected overlay")
	first_crew.button_pressed = false
	first_crew.disabled = true
	shell._mission_panel._refresh_crew_card_overlays()
	_expect((first_crew.get_meta("unavailable_overlay") as ColorRect).visible, "unavailable crew card must show its prohibition overlay")
	_expect(not (first_crew.get_meta("selected_overlay") as ColorRect).visible, "selected and unavailable overlays must never overlap")
	_expect(_resource_path(shell.get_node("BottomPersistentBar/Entries/TerritoryEntry/KaratButtonFrame") as TextureRect) == KARAT_ROOT + "button/choice_idle_border.png", "bottom entry must use the 24 Karat button border")
	_expect((shell.get_node("BottomPersistentBar/Entries") as HBoxContainer).get_child_count() == 5, "bottom persistent bar must expose five visual entry frames")

	shell.queue_free()
	await shell.tree_exited
	await process_frame

func _resource_path(texture_rect: TextureRect) -> String:
	if texture_rect.texture == null:
		return ""
	return texture_rect.texture.resource_path

func _contains_internal_client_copy(node: Node) -> bool:
	var forbidden_fragments := ["[PLACEHOLDER]", "預留", "尚未定義", "尚未建立", "暫不開放", "緊湊／標準", "starter_", "territory_"]
	if node is Control and not (node as Control).visible:
		return false
	if node is Label or node is Button:
		for fragment: String in forbidden_fragments:
			if fragment in (node as Control).get("text"):
				return true
	for child: Node in node.get_children():
		if _contains_internal_client_copy(child):
			return true
	return false

func _on_apply_requested() -> void:
	_apply_requests += 1

func _on_defer_requested() -> void:
	_defer_requests += 1

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("DesktopShellKaratVisual test failed: %s" % message)

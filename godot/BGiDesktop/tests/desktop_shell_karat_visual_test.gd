extends SceneTree

# Regression reproduction: press a bottom entry in the 450px desktop window. Before the
# fix, the child Window was embedded and clipped, so it had neither a native title bar
# for drag/close nor usable space outside the parent window. Expected: independent native
# window, close event hides it, and a later entry is initially cascaded rather than stacked.

const DesktopShellScene = preload("res://scenes/desktop_shell.tscn")
const KARAT_ROOT: String = "res://assets/third_party/subversionary_24_karat_gui/extracted/24K GUI/game/gui/"

var _failed: bool = false
var _apply_requests: int = 0
var _defer_requests: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var shell = DesktopShellScene.instantiate()
	root.add_child(shell)
	_expect(not (shell.get_node("Margin") as Control).visible, "legacy three-column shell must not remain visible")
	_expect(_resource_path(shell.get_node("TerrainStage/KaratFrameBorder") as TextureRect) == KARAT_ROOT + "frame_border.png", "full terrain stage must use the 24 Karat frame border")
	_expect(shell.get_node("TerrainStage") != null, "desktop must keep a full terrain stage behind the bottom entry bar")
	(shell.get_node("BottomPersistentBar/Entries/TerritoryEntry/Button") as Button).emit_signal("pressed")
	_expect(shell._popup_windows.has("territory"), "territory entry must open an independent popup window")
	var territory_window := shell._popup_windows["territory"] as Window
	_expect(not root.gui_embed_subwindows, "desktop popups must not be embedded or clipped by the 450px main application window")
	_expect(not territory_window.borderless, "desktop popup must retain a native title bar for drag and close controls")
	_expect(not territory_window.transient, "desktop popup must be an independent native window that can extend beyond the main application bounds")
	_expect(not territory_window.unresizable, "desktop popup must remain natively resizable")
	territory_window.close_requested.emit()
	_expect(not territory_window.visible, "native close action must hide the popup")
	(shell.get_node("BottomPersistentBar/Entries/TerritoryEntry/Button") as Button).emit_signal("pressed")
	_expect(territory_window.visible, "opening the same entry after close must restore the popup")
	(shell.get_node("BottomPersistentBar/Entries/MarketEntry/Button") as Button).emit_signal("pressed")
	_expect(shell._popup_windows.has("market"), "market entry must open an independent popup window")
	_expect((shell._popup_windows["market"] as Window).position != territory_window.position, "shared popup windows must start cascaded instead of stacked")
	(shell.get_node("BottomPersistentBar/Entries/CrewEntry/Button") as Button).emit_signal("pressed")
	_expect(shell._popup_windows.has("crew"), "crew entry must open an independent popup window")
	(shell.get_node("BottomPersistentBar/Entries/CollectionEntry/Button") as Button).emit_signal("pressed")
	_expect(shell._popup_windows.has("collection"), "collection entry must open an independent popup window")
	(shell.get_node("BottomPersistentBar/Entries/SettingsEntry/Button") as Button).emit_signal("pressed")
	_expect(shell._popup_windows.has("settings"), "settings entry must open an independent popup window")
	_expect(not shell.has_node("TerrainStage/Content/SettingsActions"), "layout density controls must not be exposed on the main desktop shell")
	(shell.get_node("TerrainStage/Content/TaskWindowButton") as Button).emit_signal("pressed")
	_expect(shell._mission_panel != null, "task entry must open an independent task and collection window")
	var task_window := shell._popup_windows["tasks"] as Window
	task_window.close_requested.emit()
	_expect(not task_window.visible, "closing the task directory must hide the native popup safely")
	(shell.get_node("TerrainStage/Content/TaskWindowButton") as Button).emit_signal("pressed")
	_expect(task_window.visible, "reopening the task directory after native close must restore the same popup")
	_expect(shell._mission_panel != null and is_instance_valid(shell._mission_panel), "reopening the task directory must retain a valid mission panel")
	for popup_key: String in ["territory", "market", "crew", "collection", "settings", "tasks"]:
		var popup := shell._popup_windows[popup_key] as Window
		_expect(popup.force_native and not popup.transient, "all shared desktop popups must use the native independent-window mechanism: %s" % popup_key)
		_expect(not _contains_internal_client_copy(popup), "client popup must not expose internal placeholder or implementation copy: %s" % popup_key)
	_expect(shell._mission_panel.has_node("Content/TaskDescriptionScroll"), "task popup must provide a scrollable mission description area")
	_expect(not shell._mission_panel.has_node("Scroll"), "only the mission description may scroll; the full task window must keep its controls in a fixed layout")
	_expect((shell._popup_windows["task_detail"] as Window).size.x >= 760 and (shell._popup_windows["task_detail"] as Window).size.y >= 820, "task detail popup must reserve enough native-window space for its fixed task, crew and reward sections")
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
	print("DesktopShellKaratVisual: PASS" if not _failed else "DesktopShellKaratVisual: FAIL")
	quit(1 if _failed else 0)

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

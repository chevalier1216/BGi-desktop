extends SceneTree

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
	(shell.get_node("BottomPersistentBar/Entries/MarketEntry/Button") as Button).emit_signal("pressed")
	_expect(shell._popup_windows.has("market"), "market entry must open an independent popup window")
	(shell.get_node("BottomPersistentBar/Entries/CrewEntry/Button") as Button).emit_signal("pressed")
	_expect(shell._popup_windows.has("crew"), "crew entry must open an independent popup window")
	(shell.get_node("BottomPersistentBar/Entries/CollectionEntry/Button") as Button).emit_signal("pressed")
	_expect(shell._popup_windows.has("collection"), "collection entry must open an independent popup window")
	(shell.get_node("BottomPersistentBar/Entries/SettingsEntry/Button") as Button).emit_signal("pressed")
	_expect(shell._popup_windows.has("settings"), "settings entry must open an independent popup window")
	_expect(not shell.has_node("TerrainStage/Content/SettingsActions"), "layout density controls must not be exposed on the main desktop shell")
	(shell.get_node("TerrainStage/Content/TaskWindowButton") as Button).emit_signal("pressed")
	_expect(shell._mission_panel != null, "task entry must open an independent task and collection window")
	_expect(shell._mission_panel.has_node("Scroll/Content/TaskDescriptionScroll"), "task popup must provide a scrollable mission description area")
	_expect(shell._mission_panel.crew_selector is HFlowContainer, "task popup must arrange crew as independent icon cards")
	_expect(shell._mission_panel.crew_selector.get_child_count() == 5, "task popup must expose all initial crew cards")
	var first_crew := shell._mission_panel.crew_selector.get_child(0) as CheckButton
	_expect(first_crew.has_meta("selected_overlay") and first_crew.has_meta("unavailable_overlay"), "crew cards must have selected and unavailable overlays")
	first_crew.button_pressed = true
	shell._mission_panel._refresh_crew_card_overlays()
	_expect((first_crew.get_meta("selected_overlay") as ColorRect).visible, "selected crew card must show its selected overlay")
	first_crew.disabled = true
	shell._mission_panel._refresh_crew_card_overlays()
	_expect((first_crew.get_meta("unavailable_overlay") as ColorRect).visible, "unavailable crew card must show its prohibition overlay")
	_expect(_resource_path(shell.get_node("BottomPersistentBar/Entries/TerritoryEntry/KaratButtonFrame") as TextureRect) == KARAT_ROOT + "button/choice_idle_border.png", "bottom entry must use the 24 Karat button border")
	_expect((shell.get_node("BottomPersistentBar/Entries") as HBoxContainer).get_child_count() == 5, "bottom persistent bar must expose five visual entry frames")

	shell.queue_free()
	print("DesktopShellKaratVisual: PASS" if not _failed else "DesktopShellKaratVisual: FAIL")
	quit(1 if _failed else 0)

func _resource_path(texture_rect: TextureRect) -> String:
	if texture_rect.texture == null:
		return ""
	return texture_rect.texture.resource_path

func _on_apply_requested() -> void:
	_apply_requests += 1

func _on_defer_requested() -> void:
	_defer_requests += 1

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("DesktopShellKaratVisual test failed: %s" % message)

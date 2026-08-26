extends SceneTree

# Regression reproduction from user feedback: opening 任務／收取 showed a single
# overloaded panel. Its crew cards remained visible with both selected and forbidden
# overlays, and refresh/receipt implementation details were mixed into task details.
# Expected: a directory opens first, current and completed entries are separate from a
# task detail window, and a dispatched task shows only its countdown in that detail.

const DesktopShellScene = preload("res://scenes/desktop_shell.tscn")

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var shell = DesktopShellScene.instantiate()
	root.add_child(shell)
	(shell.get_node("TerrainStage/Content/TaskWindowButton") as Button).emit_signal("pressed")
	_expect(shell._popup_windows.has("tasks"), "task entry must open a mission directory window")
	var directory := shell._popup_windows["tasks"] as Control
	_expect(directory.get_meta("title") == "任務清單", "task entry must identify the first window as a mission directory")
	_expect(directory.has_node("PopupLayout/Content/Content/CurrentMissions"), "mission directory must expose a current-mission section")
	_expect(directory.has_node("PopupLayout/Content/Content/CompletedMissions"), "mission directory must expose a completed-mission section")
	_expect(directory.has_node("PopupLayout/Content/Content/RefreshInfo"), "refresh state must live in the mission directory")
	_expect(not directory.has_node("PopupLayout/Content/Content/CrewSelector"), "mission directory must not mix crew selection into its list")
	_expect(not shell._popup_windows.has("task_detail") or not (shell._popup_windows["task_detail"] as Control).visible, "opening the directory must not also force open a task detail window")
	_expect((shell.get_node("TerrainStage/Content/TaskWindowButton") as Button).text.contains("開啟"), "the desktop task entry must visibly communicate that it is a button")
	_expect(not shell.get_node("TerrainStage/Content/CrewIndicators").visible, "unexplained green crew indicators must not remain on the desktop stage")

	shell.queue_free()
	print("MissionTaskDirectoryVisual: PASS" if not _failed else "MissionTaskDirectoryVisual: FAIL")
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("MissionTaskDirectoryVisual test failed: %s" % message)

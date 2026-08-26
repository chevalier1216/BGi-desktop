extends SceneTree

const DesktopShellScene := preload("res://scenes/desktop_shell.tscn")

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scenario := "instantiate"
	var user_args := OS.get_cmdline_user_args()
	if not user_args.is_empty():
		scenario = user_args[0]
	await _exercise(scenario)
	await process_frame
	print("DesktopShellHeadlessPopupIsolation[%s]: PASS" % scenario if not _failed else "DesktopShellHeadlessPopupIsolation[%s]: FAIL" % scenario)
	quit(1 if _failed else 0)

func _exercise(scenario: String) -> void:
	var shell := DesktopShellScene.instantiate()
	root.add_child(shell)
	await process_frame
	var button_path := NodePath()
	match scenario:
		"territory":
			button_path = NodePath("BottomPersistentBar/Entries/TerritoryEntry/Button")
		"market":
			button_path = NodePath("BottomPersistentBar/Entries/MarketEntry/Button")
		"crew":
			button_path = NodePath("BottomPersistentBar/Entries/CrewEntry/Button")
		"collection":
			button_path = NodePath("BottomPersistentBar/Entries/CollectionEntry/Button")
		"settings":
			button_path = NodePath("BottomPersistentBar/Entries/SettingsEntry/Button")
		"tasks":
			button_path = NodePath("TerrainStage/Content/TaskWindowButton")
		"instantiate":
			pass
		_:
			_expect(false, "unknown scenario: %s" % scenario)
	if not button_path.is_empty():
		var button := shell.get_node_or_null(button_path) as Button
		_expect(button != null, "scenario entry must exist: %s" % scenario)
		if button != null:
			button.emit_signal("pressed")
			await process_frame
	shell.queue_free()
	await shell.tree_exited
	await process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("DesktopShellHeadlessPopupIsolation failed: %s" % message)

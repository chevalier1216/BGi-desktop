extends SceneTree

const DesktopShellScene = preload("res://scenes/desktop_shell.tscn")
const KARAT_ROOT: String = "res://assets/third_party/subversionary_24_karat_gui/extracted/24K GUI/game/gui/"

var _failed: bool = false
var _apply_requests: int = 0
var _defer_requests: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var shell: Control = DesktopShellScene.instantiate() as Control
	root.add_child(shell)
	_expect(_resource_path(shell.get_node("Margin/Columns/TerritoryPanel/KaratFrameBorder") as TextureRect) == KARAT_ROOT + "frame_border.png", "territory window must use the 24 Karat frame border")
	_expect(_resource_path(shell.get_node("Margin/Columns/MissionPanel/KaratFrameBackground") as TextureRect) == KARAT_ROOT + "frame_bg.png", "mission window must use the 24 Karat frame background")
	_expect(_resource_path(shell.get_node("BottomPersistentBar/Entries/TerritoryEntry/KaratButtonFrame") as TextureRect) == KARAT_ROOT + "button/choice_idle_border.png", "bottom entry must use the 24 Karat button border")
	_expect((shell.get_node("BottomPersistentBar/Entries") as HBoxContainer).get_child_count() == 5, "bottom persistent bar must expose five visual entry frames")

	var dialog: BackgroundApplyConfirmationDialog = shell.get_node("BackgroundApplyConfirmationDialog") as BackgroundApplyConfirmationDialog
	_expect(not dialog.visible, "background apply confirmation must remain hidden until an external flow requests it")
	dialog.apply_requested.connect(_on_apply_requested)
	dialog.defer_requested.connect(_on_defer_requested)
	dialog.present()
	_expect(dialog.visible, "background apply confirmation must become visible when presented")
	_expect(_resource_path(dialog.get_node("Dialog/FrameBorder") as TextureRect) == KARAT_ROOT + "frame_border.png", "confirmation dialog must use the 24 Karat frame border")
	(dialog.get_node("Dialog/Content/Actions/ConfirmApplyButton") as Button).emit_signal("pressed")
	_expect(_apply_requests == 1 and not dialog.visible, "confirm action must emit once and close the visual shell")
	dialog.present()
	(dialog.get_node("Dialog/Content/Actions/DeferApplyButton") as Button).emit_signal("pressed")
	_expect(_defer_requests == 1 and not dialog.visible, "defer action must emit once and close the visual shell")

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

extends SceneTree

const DesktopShellScene := preload("res://scenes/desktop_shell.tscn")

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for run_index: int in range(3):
		var shell := DesktopShellScene.instantiate()
		root.add_child(shell)
		await process_frame
		_expect(is_instance_valid(shell), "desktop shell must instantiate in headless run %d" % run_index)
		shell.queue_free()
		await shell.tree_exited
		await process_frame
		_expect(not is_instance_valid(shell), "desktop shell must complete deferred teardown before quit in run %d" % run_index)
	print("DesktopShellHeadlessTeardown: PASS" if not _failed else "DesktopShellHeadlessTeardown: FAIL")
	quit(1 if _failed else 0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error("DesktopShellHeadlessTeardown failed: %s" % message)

extends SceneTree

func _init() -> void:
	assert(bool(ProjectSettings.get_setting("display/window/per_pixel_transparency/allowed", false)))
	assert(bool(ProjectSettings.get_setting("display/window/size/transparent", false)))
	assert(bool(ProjectSettings.get_setting("rendering/viewport/transparent_background", false)))
	var playtest_scene: Node = load("res://scenes/skeleton_c_playtest.tscn").instantiate()
	root.add_child(playtest_scene)
	await process_frame
	assert(root.get_viewport().transparent_bg)
	playtest_scene.queue_free()
	print("SkeletonCPlaytestTransparencyConfigTest: PASS")
	quit(0)

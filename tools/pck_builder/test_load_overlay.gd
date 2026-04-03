extends SceneTree


func _initialize() -> void:
	var scene = load("res://mods/card_art_editor/inspect_card_art_editor.tscn")
	if scene == null:
		push_error("Failed to load overlay scene.")
		quit(1)
		return

	var instance = scene.instantiate()
	if instance == null:
		push_error("Failed to instantiate overlay scene.")
		quit(2)
		return

	root.add_child(instance)
	print("Overlay loaded: ", instance.name)
	await process_frame
	print("Children: ", instance.get_child_count())
	quit()

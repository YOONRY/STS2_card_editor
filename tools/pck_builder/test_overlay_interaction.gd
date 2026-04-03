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
	await process_frame
	await process_frame

	var button = instance.get_node_or_null("EditArtButton")
	var popup = instance.get_node_or_null("EditorPopup")
	print("Overlay instance: ", instance.name)
	print("Button exists: ", button != null)
	print("Popup exists: ", popup != null)
	if button != null:
		print("Button disabled: ", button.disabled)
		print("Pressed signal connections: ", button.pressed.get_connections().size())
	if popup != null:
		print("Popup visible: ", popup.visible)

	quit()

extends SceneTree


const RELEASE_PCK := "C:/Users/Administrator/Documents/s_2_mod/build/releases/card_art_editor_2026-04-02/card_art_editor.pck"


func _initialize() -> void:
	var loaded := ProjectSettings.load_resource_pack(RELEASE_PCK, true)
	print("Release pack loaded: ", loaded)
	if !loaded:
		quit(1)
		return

	var script = load("res://mods/card_art_editor/inspect_card_art_editor.gd")
	print("Release script loaded: ", script != null)
	if script != null:
		print("Release script class: ", script.get_instance_base_type())

	var scene = load("res://mods/card_art_editor/inspect_card_art_editor.tscn")
	print("Release scene loaded: ", scene != null)
	if scene == null:
		quit(2)
		return

	var instance = scene.instantiate()
	print("Release instance: ", instance != null)
	if instance == null:
		quit(3)
		return

	root.add_child(instance)
	await process_frame
	await process_frame

	print("Release instance child_count: ", instance.get_child_count())
	print("Release instance script: ", instance.get_script())
	print("Release instance has _on_edit_art_pressed: ", instance.has_method("_on_edit_art_pressed"))
	var button = instance.get_node_or_null("EditArtButton")
	var popup = instance.get_node_or_null("EditorPopup")
	print("Release button exists: ", button != null)
	print("Release popup exists: ", popup != null)
	if button != null:
		print("Release button pressed connections: ", button.pressed.get_connections().size())
	if popup != null:
		print("Release popup visible: ", popup.visible)

	quit()

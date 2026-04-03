extends SceneTree


func _initialize() -> void:
	var manager_script = load("res://mods/card_art_editor/card_art_override_manager.gd")
	var overlay_script = load("res://mods/card_art_editor/inspect_card_art_editor.gd")
	var overlay_scene = load("res://mods/card_art_editor/inspect_card_art_editor.tscn")

	if manager_script == null:
		push_error("Failed to load manager script.")
		quit(1)
		return

	if overlay_script == null:
		push_error("Failed to load overlay script.")
		quit(1)
		return

	if overlay_scene == null:
		push_error("Failed to load overlay scene.")
		quit(1)
		return

	print("Sandbox verification passed.")
	quit()

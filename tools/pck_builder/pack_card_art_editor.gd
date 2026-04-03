extends SceneTree

const FILES := {
	"mods/card_art_editor/card_art_override_manager.gd": "card_art_override_manager.gd",
	"mods/card_art_editor/inspect_card_art_editor.gd": "inspect_card_art_editor.gd",
	"mods/card_art_editor/inspect_card_art_editor.tscn": "inspect_card_art_editor.tscn",
	"mods/card_art_editor/extract_gif_frames.ps1": "extract_gif_frames.ps1",
	"mods/card_art_editor/extract_pck_images.gd": "extract_pck_images.gd"
}


func _initialize() -> void:
	var workspace_root = _workspace_root()
	var build_root = workspace_root.path_join("build/card_art_editor_mod")
	var source_root = _mod_source_root(workspace_root)
	if source_root == "":
		push_error("Could not find mod source directory in the workspace.")
		quit(ERR_FILE_NOT_FOUND)
		return
	var output_pck = build_root.path_join("card_art_editor.pck")

	DirAccess.make_dir_recursive_absolute(build_root)

	var packer = PCKPacker.new()
	var start_error = packer.pck_start(output_pck)
	if start_error != OK:
		push_error("Could not start PCK creation: %s" % start_error)
		quit(start_error)
		return

	for target_path in FILES.keys():
		var source_path = source_root.path_join(FILES[target_path])
		if !FileAccess.file_exists(source_path):
			push_error("Missing source file: %s" % source_path)
			quit(ERR_FILE_NOT_FOUND)
			return

		var add_error = packer.add_file(target_path, source_path)
		if add_error != OK:
			push_error("Could not add %s from %s: %s" % [target_path, source_path, add_error])
			quit(add_error)
			return

	var flush_error = packer.flush()
	if flush_error != OK:
		push_error("Could not finalize PCK creation: %s" % flush_error)
		quit(flush_error)
		return

	var version_error = _force_engine_version_compatibility(output_pck, 4, 5, 1)
	if version_error != OK:
		push_error("Could not rewrite PCK engine version: %s" % version_error)
		quit(version_error)
		return

	print("Created ", output_pck)
	quit()


func _workspace_root() -> String:
	return ProjectSettings.globalize_path("res://../../")


func _mod_source_root(workspace_root: String) -> String:
	var candidates = [
		workspace_root.path_join("source/mods/card_art_editor"),
		workspace_root.path_join("Slay the Spire 2/mods/card_art_editor")
	]

	for candidate in candidates:
		if FileAccess.file_exists(candidate.path_join("inspect_card_art_editor.gd")):
			return candidate

	return ""


func _force_engine_version_compatibility(pck_path: String, major: int, minor: int, patch: int) -> int:
	var file = FileAccess.open(pck_path, FileAccess.READ_WRITE)
	if file == null:
		return FileAccess.get_open_error()

	# Godot 4 PCK header stores engine major/minor/patch at offsets 8/12/16.
	file.seek(8)
	file.store_32(major)
	file.store_32(minor)
	file.store_32(patch)
	file.flush()
	return OK

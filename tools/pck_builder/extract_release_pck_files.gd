extends SceneTree

const PCK_MAGIC := 0x43504447 # GDPC
const HEADER_VERSION_FIELDS := 4
const HEADER_RESERVED_FIELDS := 16


func _initialize() -> void:
	var input_pck := "C:/Users/Administrator/Documents/s_2_mod/build/releases/card_art_editor_2026-04-02/card_art_editor.pck"
	var output_dir := "C:/Users/Administrator/Documents/s_2_mod/build/releases/card_art_editor_2026-04-02_extracted"
	DirAccess.make_dir_recursive_absolute(output_dir)

	var parsed := _parse_pck_entries(input_pck)
	if !bool(parsed.get("ok", false)):
		push_error(String(parsed.get("message", "Could not parse release pck.")))
		quit(1)
		return

	var entries: Array = parsed.get("entries", [])
	print("ENTRY_COUNT=", entries.size())
	for entry in entries:
		var path := String((entry as Dictionary).get("path", ""))
		var rel_path := path.trim_prefix("res://")
		var output_path := output_dir.path_join(rel_path)
		DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
		var bytes := _read_pck_entry_bytes(input_pck, entry)
		var file := FileAccess.open(output_path, FileAccess.WRITE)
		if file == null:
			push_warning("Could not write %s" % output_path)
			continue
		file.store_buffer(bytes)
		print("EXTRACTED=", output_path)

	quit()


func _parse_pck_entries(pck_path: String) -> Dictionary:
	var file = FileAccess.open(pck_path, FileAccess.READ)
	if file == null:
		return {"ok": false, "message": "Could not open PCK file: %s" % pck_path}

	if file.get_length() < 4:
		return {"ok": false, "message": "PCK too small."}

	var magic = file.get_32()
	if magic != PCK_MAGIC:
		return {"ok": false, "message": "Not a supported Godot PCK."}

	for _i in range(HEADER_VERSION_FIELDS):
		file.get_32()
	for _i in range(HEADER_RESERVED_FIELDS):
		file.get_32()

	if file.get_position() + 4 > file.get_length():
		return {"ok": false, "message": "Header ended unexpectedly."}

	var file_count = file.get_32()
	var entries: Array = []
	for _i in range(file_count):
		if file.get_position() + 4 > file.get_length():
			break
		var path_length = file.get_32()
		if path_length <= 0 or file.get_position() + path_length > file.get_length():
			break
		var path = file.get_buffer(path_length).get_string_from_utf8()
		if file.get_position() + 8 + 8 + 16 > file.get_length():
			break
		var offset = file.get_64()
		var size = file.get_64()
		file.get_buffer(16)
		entries.append({
			"path": _normalize_pck_entry_path(path),
			"offset": offset,
			"size": size
		})

	return {"ok": true, "entries": entries}


func _normalize_pck_entry_path(path: String) -> String:
	var normalized = path.replace("\\", "/").strip_edges()
	if normalized.begins_with("res://"):
		return normalized
	return "res://%s" % normalized.trim_prefix("/")


func _read_pck_entry_bytes(pck_path: String, entry: Dictionary) -> PackedByteArray:
	var file = FileAccess.open(pck_path, FileAccess.READ)
	if file == null:
		return PackedByteArray()
	var offset = int(entry.get("offset", 0))
	var size = int(entry.get("size", 0))
	if offset < 0 or size <= 0:
		return PackedByteArray()
	if offset + size > file.get_length():
		return PackedByteArray()
	file.seek(offset)
	return file.get_buffer(size)

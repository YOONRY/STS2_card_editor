extends RefCounted

signal pack_published(pack_directory: String)

const PACK_ID := "cae_saved_art"
const PACK_FILENAME := "cae_saved_art.cardartpack.json"
const PACK_INFO_FILENAME := "cae_pack_info.json"
const CACHE_INDEX_FILENAME := "cae_cache_index.json"
const CACHE_VERSION := 2
const GENERATED_PACK_DIRECTORY := "user://card_art_editor/skin_changer/CAE_Saved_Art"
const SYNC_DELAY_SECONDS := 0.35
const ENTRIES_PER_TICK := 6
const BUILD_TICK_BUDGET_USEC := 8000

var _active := false
var _pack_directory := ""
var _scheduled_manifest: Dictionary = {}
var _sync_pending := false
var _sync_delay := 0.0
var _building := false
var _build_sources: Array = []
var _build_cursor := 0
var _build_file: FileAccess
var _previous_file: FileAccess
var _entry_cache: Dictionary = {}
var _next_entry_cache: Dictionary = {}
var _last_changed_sources := PackedStringArray()
var _published_this_session := false
var _full_art_renderer := Callable()
var _catalog_refresh_pending := false
var _published_fingerprints: Dictionary = {}
var _published_entries: Dictionary = {}
var _published_pack_stamp := ""
var _current_fingerprints: Dictionary = {}
var _cache_index_loaded := false
var _invalidated_sources: Dictionary = {}


func invalidate_source(source: String) -> void:
	_invalidated_sources[source] = true


func configure(skin_changer_root: String, card_art_editor_root: String, full_art_renderer := Callable()) -> bool:
	skin_changer_root = skin_changer_root.replace("\\", "/").trim_suffix("/")
	card_art_editor_root = card_art_editor_root.replace("\\", "/").trim_suffix("/")
	if skin_changer_root == "" or !FileAccess.file_exists(skin_changer_root.path_join("Gurio.SkinChanger.dll")):
		return false
	var next_directory = ProjectSettings.globalize_path(GENERATED_PACK_DIRECTORY)
	var changed = !_active or _pack_directory != next_directory
	if changed:
		_cleanup_legacy_workshop_pack(card_art_editor_root)
	_active = true
	_pack_directory = next_directory
	_full_art_renderer = full_art_renderer
	return changed


func _cleanup_legacy_workshop_pack(card_art_editor_root: String) -> void:
	if card_art_editor_root == "":
		return
	var legacy_directory = card_art_editor_root.path_join("CAE_Saved_Art")
	for file_name in [PACK_FILENAME, PACK_INFO_FILENAME]:
		var legacy_path = legacy_directory.path_join(file_name)
		if FileAccess.file_exists(legacy_path):
			DirAccess.remove_absolute(legacy_path)
	if DirAccess.dir_exists_absolute(legacy_directory):
		DirAccess.remove_absolute(legacy_directory)


func is_active() -> bool:
	return _active


func get_pack_directory() -> String:
	return _pack_directory


func get_pack_path() -> String:
	return _pack_directory.path_join(PACK_FILENAME) if _pack_directory != "" else ""


func get_last_changed_sources_csv() -> String:
	return ";".join(_last_changed_sources)


func is_sync_pending() -> bool:
	return _sync_pending or _building


func schedule_sync(manifest: Dictionary, refresh_catalog := false) -> void:
	if !_active:
		return
	_scheduled_manifest = manifest.duplicate(true)
	_catalog_refresh_pending = _catalog_refresh_pending or refresh_catalog
	_sync_pending = true
	_sync_delay = 0.0
	_building = false
	_build_file = null
	_previous_file = null
	_build_sources.clear()
	_next_entry_cache.clear()


func process(delta: float) -> void:
	if !_active:
		return
	if !_building:
		if !_sync_pending:
			return
		_sync_delay += delta
		if _sync_delay < SYNC_DELAY_SECONDS:
			return
		_start_build()
	var processed := 0
	var started_at = Time.get_ticks_usec()
	while _building and _build_cursor < _build_sources.size() and processed < ENTRIES_PER_TICK:
		_build_source(String(_build_sources[_build_cursor]))
		_build_cursor += 1
		processed += 1
		if Time.get_ticks_usec() - started_at >= BUILD_TICK_BUDGET_USEC:
			break
	if _building and _build_cursor >= _build_sources.size():
		_finish_build()


func flush_for_test() -> void:
	if !_active or (!_sync_pending and !_building):
		return
	if _sync_pending:
		_start_build()
	while _building and _build_cursor < _build_sources.size():
		_build_source(String(_build_sources[_build_cursor]))
		_build_cursor += 1
	if _building:
		_finish_build()


func _start_build() -> void:
	_load_cache_index()
	_current_fingerprints.clear()
	for source in _scheduled_manifest:
		var entry = _scheduled_manifest[source]
		if entry is Dictionary:
			_current_fingerprints[source] = _entry_fingerprint(entry)
	_last_changed_sources.clear()
	_sync_pending = false
	_sync_delay = 0.0
	if _published_pack_stamp != "" and _published_pack_stamp == _file_fingerprint(get_pack_path()):
		if _current_fingerprints == _published_fingerprints and _invalidated_sources.is_empty():
			_write_pack_info()
			if !_published_this_session or _catalog_refresh_pending:
				_published_this_session = true
				_catalog_refresh_pending = false
				pack_published.emit(_pack_directory)
			return
		# The index contains byte ranges, not image payloads. Unchanged cards are
		# copied one at a time without parsing the old multi-hundred-MB bundle.
		_entry_cache = _published_entries.duplicate(true)
		_previous_file = FileAccess.open(get_pack_path(), FileAccess.READ)
	else:
		_entry_cache.clear()
		_previous_file = null
	if DirAccess.make_dir_recursive_absolute(_pack_directory) != OK:
		return
	_build_file = FileAccess.open(get_pack_path() + ".tmp", FileAccess.WRITE)
	if _build_file == null:
		push_warning("Card Art Editor: could not stage the Skin Changer art pack.")
		return
	_build_file.store_string('{"format":"card_art_bundle","version":1,"overrides":[')
	_build_sources = _scheduled_manifest.keys()
	_build_sources.sort()
	_build_cursor = 0
	_next_entry_cache.clear()
	_building = true


func _entry_fingerprint(entry: Dictionary) -> String:
	var override_path = _get_entry_override_path(entry)
	var edit_source_path = _get_entry_edit_source_path(entry, override_path)
	return "%s|%s|%s" % [
		_file_fingerprint(override_path), _file_fingerprint(edit_source_path), JSON.stringify(entry)
	]


func _load_cache_index() -> void:
	if _cache_index_loaded:
		return
	_cache_index_loaded = true
	var path = _pack_directory.path_join(CACHE_INDEX_FILENAME)
	if !FileAccess.file_exists(path):
		return
	var parser = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return
	var index = parser.data
	if !(index is Dictionary) or int(index.get("version", 0)) != CACHE_VERSION:
		return
	var fingerprints = index.get("fingerprints", null)
	if fingerprints is Dictionary:
		_published_fingerprints = fingerprints
		_published_pack_stamp = String(index.get("pack_stamp", ""))
	var entries = index.get("entries", {})
	if entries is Dictionary:
		_published_entries = entries


func _save_cache_index() -> void:
	# Incomplete exports must be retried, never blessed as a valid disk cache.
	if _entry_cache.size() != _current_fingerprints.size():
		_published_pack_stamp = ""
		return
	_published_fingerprints = _current_fingerprints.duplicate()
	_published_entries = _entry_cache.duplicate(true)
	_published_pack_stamp = _file_fingerprint(get_pack_path())
	var file = FileAccess.open(_pack_directory.path_join(CACHE_INDEX_FILENAME), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"version": CACHE_VERSION, "pack_stamp": _published_pack_stamp, "fingerprints": _published_fingerprints, "entries": _published_entries}))


func _build_source(source_path: String) -> void:
	var entry = _scheduled_manifest.get(source_path, null)
	if !(entry is Dictionary):
		return
	var display_mode = String(entry.get("display_mode", "default"))
	var override_path = _get_entry_override_path(entry)
	var edit_source_path = _get_entry_edit_source_path(entry, override_path)
	if override_path == "" and edit_source_path == "":
		return
	var fingerprint = String(_current_fingerprints.get(source_path, ""))
	var cached = _entry_cache.get(source_path, null)
	if cached is Dictionary and _previous_file != null and String(cached.get("fingerprint", "")) == fingerprint and !_invalidated_sources.has(source_path):
		var offset = int(cached.get("offset", -1))
		var length = int(cached.get("length", 0))
		if offset >= 0 and length > 0 and offset + length <= _previous_file.get_length():
			_previous_file.seek(offset)
			var bytes = _previous_file.get_buffer(length)
			if bytes.size() == length:
				_write_entry(source_path, fingerprint, bytes)
				return
	var override_bytes = _read_png(override_path)
	if override_bytes.is_empty():
		override_bytes = _read_png(edit_source_path)
	if override_bytes.is_empty():
		return
	var output_width = int(entry.get("width", 0))
	var output_height = int(entry.get("height", 0))
	if display_mode == "full_art":
		# The saved override may still be a landscape crop. CAE normally builds
		# its full-art texture at display time; export that same render here.
		if !_full_art_renderer.is_valid():
			push_warning("Card Art Editor: full-art bridge renderer is unavailable.")
			return
		var full_art_image = _full_art_renderer.call(source_path, entry)
		if !(full_art_image is Image) or full_art_image.is_empty():
			return
		override_bytes = full_art_image.save_png_to_buffer()
		output_width = full_art_image.get_width()
		output_height = full_art_image.get_height()
	var pack_entry = {
		"source_path": source_path,
		"display_mode": display_mode,
		"type": "static",
		"width": output_width,
		"height": output_height,
		"updated_at": String(entry.get("updated_at", "")),
		"adjust_zoom": float(entry.get("adjust_zoom", 1.0)),
		"adjust_offset_x": float(entry.get("adjust_offset_x", 0.0)),
		"adjust_offset_y": float(entry.get("adjust_offset_y", 0.0)),
		"ancient_text_outside": bool(entry.get("ancient_text_outside", false)),
		# No editor source: the parser falls back to these already-rendered pixels.
		"png_base64": Marshalls.raw_to_base64(override_bytes)
	}
	_write_entry(source_path, fingerprint, JSON.stringify(pack_entry).to_utf8_buffer())
	_last_changed_sources.append(source_path)


func _write_entry(source: String, fingerprint: String, bytes: PackedByteArray) -> void:
	if !_next_entry_cache.is_empty():
		_build_file.store_string(",")
	var offset = _build_file.get_position()
	_build_file.store_buffer(bytes)
	_next_entry_cache[source] = {"fingerprint": fingerprint, "offset": offset, "length": bytes.size()}


func _get_entry_override_path(entry: Dictionary) -> String:
	var entry_type = String(entry.get("type", "static"))
	if entry_type == "animated_gif" or entry.has("frame_paths"):
		var frame_paths = entry.get("frame_paths", [])
		if frame_paths is Array and !frame_paths.is_empty():
			return String(frame_paths[0])
		return ""
	return String(entry.get("override_path", ""))


func _get_entry_edit_source_path(entry: Dictionary, fallback_path: String) -> String:
	var entry_type = String(entry.get("type", "static"))
	if entry_type == "animated_gif" or entry.has("frame_paths"):
		var source_paths = entry.get("source_animation_frame_paths", entry.get("source_frame_paths", []))
		if source_paths is Array and !source_paths.is_empty():
			return String(source_paths[0])
		return fallback_path
	return String(entry.get("edit_source_path", fallback_path))


func _file_fingerprint(path: String) -> String:
	if path == "":
		return ""
	var absolute_path = ProjectSettings.globalize_path(path)
	if !FileAccess.file_exists(absolute_path):
		return ""
	var file = FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		return ""
	return "%s|%d|%d" % [absolute_path, FileAccess.get_modified_time(absolute_path), file.get_length()]


func _read_png(path: String) -> PackedByteArray:
	if path == "":
		return PackedByteArray()
	var bytes = FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(path))
	return bytes if _is_png(bytes) else PackedByteArray()


func _is_png(bytes: PackedByteArray) -> bool:
	return bytes.size() >= 8 \
		and bytes[0] == 137 \
		and bytes[1] == 80 \
		and bytes[2] == 78 \
		and bytes[3] == 71 \
		and bytes[4] == 13 \
		and bytes[5] == 10 \
		and bytes[6] == 26 \
		and bytes[7] == 10


func _finish_build() -> void:
	_building = false
	_previous_file = null
	for previous_source in _published_fingerprints.keys():
		if !_next_entry_cache.has(previous_source):
			_last_changed_sources.append(String(previous_source))
	var destination = get_pack_path()
	var temporary = destination + ".tmp"
	_build_file.store_string('],"count":%d}' % _next_entry_cache.size())
	_build_file.flush()
	var write_error = _build_file.get_error()
	_build_file = null
	if write_error != OK:
		push_warning("Card Art Editor: could not finish the Skin Changer art pack; keeping the previous pack.")
		return
	_write_pack_info()
	if _next_entry_cache.is_empty():
		DirAccess.remove_absolute(temporary)
		if FileAccess.file_exists(destination):
			if DirAccess.remove_absolute(destination) != OK:
				return
		_entry_cache.clear()
		_published_entries.clear()
		_published_fingerprints.clear()
		_published_pack_stamp = ""
		_invalidated_sources.clear()
		if !_published_this_session or !_last_changed_sources.is_empty() or _catalog_refresh_pending:
			_published_this_session = true
			_catalog_refresh_pending = false
			pack_published.emit(_pack_directory)
		return
	if DirAccess.rename_absolute(temporary, destination) != OK:
		push_warning("Card Art Editor: could not publish the Skin Changer art pack; keeping the previous pack.")
		return
	_entry_cache = _next_entry_cache.duplicate(true)
	_next_entry_cache.clear()
	if !_published_this_session:
		# Rebuilding an old bridge format at startup must not reset skin choices.
		_last_changed_sources.clear()
	_save_cache_index()
	_published_this_session = true
	_catalog_refresh_pending = false
	_invalidated_sources.clear()
	pack_published.emit(_pack_directory)


func _write_pack_info() -> void:
	var info_path = _pack_directory.path_join(PACK_INFO_FILENAME)
	var content = JSON.stringify({"id": PACK_ID, "name": "Card Art Editor"})
	if FileAccess.file_exists(info_path) and FileAccess.get_file_as_string(info_path) == content:
		return
	var file = FileAccess.open(info_path, FileAccess.WRITE)
	if file != null:
		file.store_string(content)

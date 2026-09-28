extends RefCounted

signal pack_published(pack_directory: String)

const PACK_ID := "cae_saved_art"
const PACK_FILENAME := "cae_saved_art.cardartpack.json"
const PACK_INFO_FILENAME := "cae_pack_info.json"
const CACHE_INDEX_FILENAME := "cae_cache_index.json"
const CACHE_VERSION := 1
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
var _build_entries: Array = []
var _entry_cache: Dictionary = {}
var _next_entry_cache: Dictionary = {}
var _last_changed_sources := PackedStringArray()
var _published_this_session := false
var _full_art_renderer := Callable()
var _catalog_refresh_pending := false
var _published_fingerprints: Dictionary = {}
var _published_pack_stamp := ""
var _current_fingerprints: Dictionary = {}
var _cache_index_loaded := false


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
	_build_sources.clear()
	_build_entries.clear()
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
	if !_active or !_sync_pending:
		return
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
		if _current_fingerprints == _published_fingerprints:
			_write_pack_info()
			if !_published_this_session or _catalog_refresh_pending:
				_published_this_session = true
				_catalog_refresh_pending = false
				pack_published.emit(_pack_directory)
			return
		# Only hydrate image data if an edit actually needs a new export. Launches
		# compare the small index and file metadata, not the large base64 bundle.
		if _entry_cache.is_empty():
			_load_cached_entries()
	_build_sources = _scheduled_manifest.keys()
	_build_sources.sort()
	_build_cursor = 0
	_build_entries.clear()
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


func _load_cached_entries() -> void:
	var parser = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(get_pack_path())) != OK or !(parser.data is Dictionary):
		return
	var entries = parser.data.get("overrides", [])
	if !(entries is Array):
		return
	for entry in entries:
		if !(entry is Dictionary):
			continue
		var source = String(entry.get("source_path", ""))
		if _published_fingerprints.has(source):
			_entry_cache[source] = {"fingerprint": _published_fingerprints[source], "entry": entry}


func _save_cache_index() -> void:
	# Incomplete exports must be retried, never blessed as a valid disk cache.
	if _entry_cache.size() != _current_fingerprints.size():
		_published_pack_stamp = ""
		return
	_published_fingerprints = _current_fingerprints.duplicate()
	_published_pack_stamp = _file_fingerprint(get_pack_path())
	var file = FileAccess.open(_pack_directory.path_join(CACHE_INDEX_FILENAME), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"version": CACHE_VERSION, "pack_stamp": _published_pack_stamp, "fingerprints": _published_fingerprints}))


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
	if cached is Dictionary and String(cached.get("fingerprint", "")) == fingerprint:
		var cached_entry = cached.get("entry", null)
		if cached_entry is Dictionary:
			_build_entries.append(cached_entry)
			_next_entry_cache[source_path] = cached
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
		"png_base64": Marshalls.raw_to_base64(override_bytes),
		# Skin Changer prefers edit_source and does not apply CAE's adjustment
		# metadata. Give it the rendered pixels, not the uncropped editor source.
		"edit_source_png_base64": Marshalls.raw_to_base64(override_bytes)
	}
	_build_entries.append(pack_entry)
	_next_entry_cache[source_path] = {"fingerprint": fingerprint, "entry": pack_entry}
	_last_changed_sources.append(source_path)


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
	for previous_source in _entry_cache.keys():
		if !_next_entry_cache.has(previous_source):
			_last_changed_sources.append(String(previous_source))
	_entry_cache = _next_entry_cache.duplicate(true)
	_next_entry_cache.clear()
	if _pack_directory == "":
		return
	if DirAccess.make_dir_recursive_absolute(_pack_directory) != OK:
		push_warning("Card Art Editor: could not create the Skin Changer art pack directory.")
		return
	_write_pack_info()
	var destination = get_pack_path()
	if _build_entries.is_empty():
		if FileAccess.file_exists(destination):
			if DirAccess.remove_absolute(destination) != OK:
				return
		if !_published_this_session or !_last_changed_sources.is_empty() or _catalog_refresh_pending:
			_published_this_session = true
			_catalog_refresh_pending = false
			pack_published.emit(_pack_directory)
		return
	var content = JSON.stringify({"format": "card_art_bundle", "version": 1, "count": _build_entries.size(), "overrides": _build_entries})
	if FileAccess.file_exists(destination) and FileAccess.get_file_as_string(destination) == content:
		_save_cache_index()
		if !_published_this_session or _catalog_refresh_pending:
			# Startup catalog registration is not an art change. Preserve the
			# user's per-card Skin Changer selections across game launches.
			_last_changed_sources.clear()
			_published_this_session = true
			_catalog_refresh_pending = false
			pack_published.emit(_pack_directory)
		return
	var temporary = destination + ".tmp"
	var file = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		push_warning("Card Art Editor: could not write the Skin Changer art pack.")
		return
	file.store_string(content)
	file.flush()
	file = null
	if FileAccess.file_exists(destination):
		DirAccess.remove_absolute(destination)
	if DirAccess.rename_absolute(temporary, destination) != OK:
		DirAccess.remove_absolute(temporary)
		push_warning("Card Art Editor: could not publish the Skin Changer art pack.")
		return
	if !_published_this_session:
		# Rebuilding an old bridge format at startup must not reset skin choices.
		_last_changed_sources.clear()
	_save_cache_index()
	_published_this_session = true
	_catalog_refresh_pending = false
	pack_published.emit(_pack_directory)


func _write_pack_info() -> void:
	var info_path = _pack_directory.path_join(PACK_INFO_FILENAME)
	var content = JSON.stringify({"id": PACK_ID, "name": "Card Art Editor"})
	if FileAccess.file_exists(info_path) and FileAccess.get_file_as_string(info_path) == content:
		return
	var file = FileAccess.open(info_path, FileAccess.WRITE)
	if file != null:
		file.store_string(content)

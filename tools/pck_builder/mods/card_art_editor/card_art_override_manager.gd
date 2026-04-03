extends Node

const STORAGE_ROOT := "user://card_art_editor"
const STORAGE_IMAGE_DIR := STORAGE_ROOT + "/overrides"
const STORAGE_MANIFEST_PATH := STORAGE_ROOT + "/manifest.json"
const BUNDLE_VERSION := 1
const MANAGED_TEXTURE_PREFIX := "res://images/packed/card_portraits/"
const CARD_ATLAS_PREFIX := "res://images/atlases/card_atlas.sprites/"
const DEFAULT_LANDSCAPE_SIZE := Vector2i(1000, 760)
const DEFAULT_PORTRAIT_SIZE := Vector2i(606, 852)
const REFRESH_INTERVAL := 0.15

const META_SOURCE_PATH := "_card_art_source_path"
const META_SOURCE_SIZE := "_card_art_source_size"
const META_ORIGINAL_TEXTURE := "_card_art_original_texture"
const META_OVERRIDE_ACTIVE := "_card_art_override_active"

signal overrides_changed(source_path)

var _portrait_refs := []
var _manifest := {}
var _override_texture_cache := {}
var _refresh_accumulator := 0.0
var _session_api_key := ""
var _overlay_scene := preload("res://mods/card_art_editor/inspect_card_art_editor.tscn")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_storage()
	_load_manifest()
	get_tree().node_added.connect(_on_node_added)
	_register_existing(get_tree().root)


func _process(delta: float) -> void:
	_refresh_accumulator += delta
	if _refresh_accumulator < REFRESH_INTERVAL:
		return
	_refresh_accumulator = 0.0
	_refresh_tracked_portraits()


func get_session_api_key() -> String:
	return _session_api_key


func set_session_api_key(api_key: String) -> void:
	_session_api_key = api_key.strip_edges()


func has_override(source_path: String) -> bool:
	return _manifest.has(source_path)


func get_override_count() -> int:
	return _manifest.size()


func get_source_path_for_texture_rect(texture_rect) -> String:
	if texture_rect == null:
		return ""
	_refresh_portrait_node(texture_rect)
	return String(texture_rect.get_meta(META_SOURCE_PATH, ""))


func get_target_size_for_source_path(source_path: String) -> Vector2i:
	if source_path == "":
		return DEFAULT_LANDSCAPE_SIZE

	var manifest_entry = _manifest.get(source_path, null)
	if manifest_entry is Dictionary and manifest_entry.has("width") and manifest_entry.has("height"):
		return Vector2i(int(manifest_entry["width"]), int(manifest_entry["height"]))

	var texture = load(source_path)
	if texture is Texture2D:
		return Vector2i(texture.get_width(), texture.get_height())

	if source_path.contains("ancient"):
		return DEFAULT_PORTRAIT_SIZE

	return DEFAULT_LANDSCAPE_SIZE


func get_generation_size_for_source_path(source_path: String) -> String:
	var target_size = get_target_size_for_source_path(source_path)
	if target_size.x == target_size.y:
		return "1024x1024"
	if target_size.x > target_size.y:
		return "1536x1024"
	return "1024x1536"


func get_source_image_bytes(source_path: String) -> PackedByteArray:
	var image = get_source_image(source_path)
	if image == null:
		return PackedByteArray()
	return image.save_png_to_buffer()


func get_source_image(source_path: String):
	if source_path == "":
		return null

	var texture = load(source_path)
	if texture is Texture2D:
		return texture.get_image()

	return null


func save_override_from_file(source_path: String, import_path: String) -> Dictionary:
	var image = load_image_from_file(import_path)
	if image == null:
		return {
			"ok": false,
			"message": "Could not load the selected image. Some PNG/JPG files use an encoding Godot rejects. Re-save the image in Paint or another editor and try again.\nPath: %s" % import_path
	}
	return save_override_image(source_path, image)


func export_bundle_to_file(export_path: String) -> Dictionary:
	if _manifest.is_empty():
		return {
			"ok": false,
			"message": "There are no custom card images to export yet."
		}

	var overrides: Array = []
	for source_path in _manifest.keys():
		var entry = _manifest[source_path]
		if !(entry is Dictionary) or !entry.has("override_path"):
			continue
		var override_path = String(entry["override_path"])
		var absolute_override_path = ProjectSettings.globalize_path(override_path)
		var image_bytes = FileAccess.get_file_as_bytes(absolute_override_path)
		if image_bytes.is_empty():
			continue
		overrides.append({
			"source_path": source_path,
			"width": int(entry.get("width", 0)),
			"height": int(entry.get("height", 0)),
			"updated_at": String(entry.get("updated_at", "")),
			"png_base64": Marshalls.raw_to_base64(image_bytes)
		})

	if overrides.is_empty():
		return {
			"ok": false,
			"message": "The custom images could not be collected for export."
		}

	var normalized_export_path = export_path
	if !normalized_export_path.to_lower().ends_with(".cardartpack.json"):
		normalized_export_path += ".cardartpack.json"

	var file = FileAccess.open(normalized_export_path, FileAccess.WRITE)
	if file == null:
		return {
			"ok": false,
			"message": "The art pack file could not be created."
		}

	file.store_string(JSON.stringify({
		"format": "card_art_bundle",
		"version": BUNDLE_VERSION,
		"exported_at": Time.get_datetime_string_from_system(),
		"count": overrides.size(),
		"overrides": overrides
	}, "\t"))

	return {
		"ok": true,
		"message": "Exported %d custom card images into one shareable art pack." % overrides.size()
	}


func import_bundle_from_file(import_path: String) -> Dictionary:
	var normalized_import_path = import_path
	if !normalized_import_path.is_absolute_path():
		normalized_import_path = ProjectSettings.globalize_path(import_path)

	var file = FileAccess.open(normalized_import_path, FileAccess.READ)
	if file == null:
		return {
			"ok": false,
			"message": "The selected art pack could not be opened."
		}

	var parsed = JSON.parse_string(file.get_as_text())
	if !(parsed is Dictionary):
		return {
			"ok": false,
			"message": "The selected file is not a valid art pack."
		}

	if String(parsed.get("format", "")) != "card_art_bundle":
		return {
			"ok": false,
			"message": "The selected file is not a supported card art bundle."
		}

	var overrides = parsed.get("overrides", [])
	if !(overrides is Array) or overrides.is_empty():
		return {
			"ok": false,
			"message": "The art pack does not contain any card images."
		}

	var imported_count := 0
	for override_entry in overrides:
		if !(override_entry is Dictionary):
			continue
		var source_path = String(override_entry.get("source_path", ""))
		var png_base64 = String(override_entry.get("png_base64", ""))
		if source_path == "" or png_base64 == "":
			continue
		var image_bytes = Marshalls.base64_to_raw(png_base64)
		if image_bytes.is_empty():
			continue
		var image = Image.new()
		if image.load_png_from_buffer(image_bytes) != OK:
			continue
		var result = save_override_image(source_path, image)
		if bool(result.get("ok", false)):
			imported_count += 1

	if imported_count == 0:
		return {
			"ok": false,
			"message": "No card images from the art pack could be imported."
		}

	refresh_all_portraits()
	return {
		"ok": true,
		"message": "Imported %d card images from the shared art pack." % imported_count
	}


func save_override_image(source_path: String, image) -> Dictionary:
	if source_path == "":
		return {
			"ok": false,
			"message": "No source card art is selected."
		}
	if image == null:
		return {
			"ok": false,
			"message": "No image data was provided."
		}

	var target_size = get_target_size_for_source_path(source_path)
	var normalized_image = normalize_image(image, target_size)
	if normalized_image == null:
		return {
			"ok": false,
			"message": "The image could not be converted to the card art format."
		}
	var override_path = "%s/%s.png" % [STORAGE_IMAGE_DIR, _safe_file_stem(source_path)]
	var absolute_override_path = ProjectSettings.globalize_path(override_path)
	var save_error = normalized_image.save_png(absolute_override_path)
	if save_error != OK:
		return {
			"ok": false,
			"message": "Failed to save the converted card art."
		}

	_manifest[source_path] = {
		"override_path": override_path,
		"width": target_size.x,
		"height": target_size.y,
		"updated_at": Time.get_datetime_string_from_system()
	}
	_override_texture_cache.erase(source_path)
	_save_manifest()
	refresh_all_portraits()
	overrides_changed.emit(source_path)

	return {
		"ok": true,
		"message": "Custom art applied and resized to %dx%d." % [target_size.x, target_size.y]
	}


func remove_override(source_path: String) -> Dictionary:
	if !_manifest.has(source_path):
		return {
			"ok": false,
			"message": "This card is already using its original art."
		}

	var entry = _manifest[source_path]
	if entry is Dictionary and entry.has("override_path"):
		var absolute_override_path = ProjectSettings.globalize_path(String(entry["override_path"]))
		if FileAccess.file_exists(absolute_override_path):
			DirAccess.remove_absolute(absolute_override_path)

	_manifest.erase(source_path)
	_override_texture_cache.erase(source_path)
	_save_manifest()
	refresh_all_portraits()
	overrides_changed.emit(source_path)

	return {
		"ok": true,
		"message": "Restored the original card art."
	}


func remove_all_overrides() -> Dictionary:
	if _manifest.is_empty():
		return {
			"ok": false,
			"message": "All cards are already using their original art."
		}

	for source_path in _manifest.keys():
		var entry = _manifest[source_path]
		if entry is Dictionary and entry.has("override_path"):
			var absolute_override_path = ProjectSettings.globalize_path(String(entry["override_path"]))
			if FileAccess.file_exists(absolute_override_path):
				DirAccess.remove_absolute(absolute_override_path)

	_manifest.clear()
	_override_texture_cache.clear()
	_save_manifest()
	refresh_all_portraits()

	return {
		"ok": true,
		"message": "Restored all card art to the original images."
	}


func load_image_from_file(path: String):
	var image = Image.new()
	var normalized_path = path
	if !path.is_absolute_path():
		normalized_path = ProjectSettings.globalize_path(path)

	var direct_load_error = image.load(normalized_path)
	if direct_load_error == OK:
		return image

	var image_bytes = FileAccess.get_file_as_bytes(normalized_path)
	if image_bytes.is_empty():
		return null

	var extension = normalized_path.get_extension().to_lower()
	var load_error = ERR_FILE_UNRECOGNIZED
	var fallback_attempts = []

	match extension:
		"png":
			load_error = image.load_png_from_buffer(image_bytes)
			fallback_attempts = [
				func (): return image.load_jpg_from_buffer(image_bytes),
				func (): return image.load_webp_from_buffer(image_bytes)
			]
		"jpg", "jpeg":
			load_error = image.load_jpg_from_buffer(image_bytes)
			fallback_attempts = [
				func (): return image.load_png_from_buffer(image_bytes),
				func (): return image.load_webp_from_buffer(image_bytes)
			]
		"webp":
			load_error = image.load_webp_from_buffer(image_bytes)
			fallback_attempts = [
				func (): return image.load_png_from_buffer(image_bytes),
				func (): return image.load_jpg_from_buffer(image_bytes)
			]
		_:
			return null

	if load_error != OK:
		for attempt in fallback_attempts:
			load_error = attempt.call()
			if load_error == OK:
				break
		if load_error != OK:
			return null

	return image


func normalize_image(image, target_size: Vector2i):
	var working_image = image.duplicate()
	if working_image.is_compressed():
		var decompress_error = working_image.decompress()
		if decompress_error != OK:
			return null
	working_image.convert(Image.FORMAT_RGBA8)

	var scale_x = float(target_size.x) / float(max(working_image.get_width(), 1))
	var scale_y = float(target_size.y) / float(max(working_image.get_height(), 1))
	var scale_factor = max(scale_x, scale_y)

	var resized_width = max(target_size.x, int(round(working_image.get_width() * scale_factor)))
	var resized_height = max(target_size.y, int(round(working_image.get_height() * scale_factor)))
	working_image.resize(resized_width, resized_height, Image.INTERPOLATE_LANCZOS)

	var crop_x = max(0, int((resized_width - target_size.x) / 2))
	var crop_y = max(0, int((resized_height - target_size.y) / 2))
	var normalized_image = Image.create(target_size.x, target_size.y, false, Image.FORMAT_RGBA8)
	normalized_image.blit_rect(
		working_image,
		Rect2i(crop_x, crop_y, target_size.x, target_size.y),
		Vector2i.ZERO
	)
	return normalized_image


func refresh_all_portraits() -> void:
	_refresh_tracked_portraits()


func apply_override_to_texture_rect(texture_rect) -> void:
	if texture_rect == null:
		return
	_refresh_portrait_node(texture_rect)


func _on_node_added(node) -> void:
	if _is_portrait_node(node):
		_track_portrait(node)
	elif node is Control and String(node.name) == "InspectCardScreen":
		call_deferred("_attach_overlay", node)


func _register_existing(node) -> void:
	if _is_portrait_node(node):
		_track_portrait(node)
	elif node is Control and String(node.name) == "InspectCardScreen":
		call_deferred("_attach_overlay", node)

	for child in node.get_children():
		_register_existing(child)


func _track_portrait(texture_rect) -> void:
	for ref in _portrait_refs:
		if ref.get_ref() == texture_rect:
			return
	_portrait_refs.append(weakref(texture_rect))
	_refresh_portrait_node(texture_rect)


func _refresh_tracked_portraits() -> void:
	for index in range(_portrait_refs.size() - 1, -1, -1):
		var texture_rect = _portrait_refs[index].get_ref()
		if texture_rect == null:
			_portrait_refs.remove_at(index)
			continue
		_refresh_portrait_node(texture_rect)


func _refresh_portrait_node(texture_rect) -> void:
	var current_texture = texture_rect.texture
	if current_texture == null:
		return

	var current_path = _normalize_source_path(String(current_texture.resource_path))
	var stored_source_path = String(texture_rect.get_meta(META_SOURCE_PATH, ""))

	if current_path != "" and _looks_like_card_art_source(current_path):
		if stored_source_path != current_path:
			texture_rect.set_meta(META_SOURCE_PATH, current_path)
			texture_rect.set_meta(META_SOURCE_SIZE, Vector2i(current_texture.get_width(), current_texture.get_height()))
			texture_rect.set_meta(META_ORIGINAL_TEXTURE, current_texture)
			texture_rect.set_meta(META_OVERRIDE_ACTIVE, false)
			stored_source_path = current_path
		elif !texture_rect.has_meta(META_ORIGINAL_TEXTURE) or bool(texture_rect.get_meta(META_OVERRIDE_ACTIVE, false)):
			texture_rect.set_meta(META_ORIGINAL_TEXTURE, current_texture)
			texture_rect.set_meta(META_SOURCE_SIZE, Vector2i(current_texture.get_width(), current_texture.get_height()))
			texture_rect.set_meta(META_OVERRIDE_ACTIVE, false)
	elif stored_source_path == "":
		return

	var override_texture = _get_override_texture(stored_source_path)
	if override_texture != null:
		if texture_rect.texture != override_texture:
			texture_rect.texture = override_texture
			texture_rect.set_meta(META_OVERRIDE_ACTIVE, true)
		return

	if bool(texture_rect.get_meta(META_OVERRIDE_ACTIVE, false)):
		var original_texture = texture_rect.get_meta(META_ORIGINAL_TEXTURE, null)
		if original_texture is Texture2D:
			texture_rect.texture = original_texture
		texture_rect.set_meta(META_OVERRIDE_ACTIVE, false)


func _get_override_texture(source_path: String):
	if !_manifest.has(source_path):
		return null

	if _override_texture_cache.has(source_path):
		return _override_texture_cache[source_path]

	var entry = _manifest[source_path]
	if !(entry is Dictionary) or !entry.has("override_path"):
		return null

	var override_path = String(entry["override_path"])
	var image = load_image_from_file(ProjectSettings.globalize_path(override_path))
	if image == null:
		_manifest.erase(source_path)
		_save_manifest()
		return null

	var override_texture = ImageTexture.create_from_image(image)
	_override_texture_cache[source_path] = override_texture
	return override_texture


func _attach_overlay(screen) -> void:
	if screen == null or !is_instance_valid(screen):
		return
	if screen.get_node_or_null("CardArtEditorOverlay") != null:
		return

	var overlay = _overlay_scene.instantiate()
	overlay.name = "CardArtEditorOverlay"
	screen.add_child(overlay)


func _is_portrait_node(node) -> bool:
	if !(node is TextureRect):
		return false
	var node_name = String(node.name)
	return node_name == "Portrait" or node_name == "AncientPortrait"


func _looks_like_card_art_source(path: String) -> bool:
	return path.begins_with(MANAGED_TEXTURE_PREFIX) or path.begins_with(CARD_ATLAS_PREFIX)


func _normalize_source_path(path: String) -> String:
	if path == "":
		return ""

	if path.begins_with(MANAGED_TEXTURE_PREFIX):
		return path

	if path.begins_with(CARD_ATLAS_PREFIX) and path.ends_with(".tres"):
		var sprite_path = path.trim_prefix(CARD_ATLAS_PREFIX)
		sprite_path = sprite_path.trim_suffix(".tres")
		var fallback_path = "%s%s.png" % [MANAGED_TEXTURE_PREFIX, sprite_path]
		if ResourceLoader.exists(fallback_path):
			return fallback_path

	return path


func _ensure_storage() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STORAGE_IMAGE_DIR))


func _load_manifest() -> void:
	var absolute_manifest_path = ProjectSettings.globalize_path(STORAGE_MANIFEST_PATH)
	if !FileAccess.file_exists(absolute_manifest_path):
		_manifest = {}
		return

	var file = FileAccess.open(absolute_manifest_path, FileAccess.READ)
	if file == null:
		_manifest = {}
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_manifest = parsed
	else:
		_manifest = {}


func _save_manifest() -> void:
	var absolute_manifest_path = ProjectSettings.globalize_path(STORAGE_MANIFEST_PATH)
	var file = FileAccess.open(absolute_manifest_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_manifest, "\t"))


func _safe_file_stem(source_path: String) -> String:
	var stem = source_path.to_lower()
	stem = stem.replace("res://", "")
	stem = stem.replace("/", "_")
	stem = stem.replace("\\", "_")
	stem = stem.replace(":", "_")
	stem = stem.replace(".", "_")
	return stem

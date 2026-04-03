extends Control

const GEMINI_API_URL_TEMPLATE := "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent"
const DEFAULT_MODEL := "gemini-2.0-flash-preview-image-generation"
const POPUP_SIZE := Vector2i(640, 720)
const STATUS_READY := "이 카드의 이미지를 수정할 준비가 되었습니다."
const FILE_DIALOG_MODE_UPLOAD := "upload"
const FILE_DIALOG_MODE_IMPORT_PACK := "import_pack"
const IMAGE_EXTENSIONS := ["png", "jpg", "jpeg", "webp"]
const THUMBNAIL_SIZE := Vector2i(120, 90)

@onready var _edit_art_button = %EditArtButton
@onready var _editor_popup = %EditorPopup
@onready var _current_card_label = %CurrentCardLabel
@onready var _tab_container = %ModeTabs
@onready var _api_key_input = %ApiKeyInput
@onready var _model_input = %ModelInput
@onready var _quality_select = %QualitySelect
@onready var _prompt_input = %PromptInput
@onready var _generate_button = %GenerateButton
@onready var _choose_image_button = %ChooseImageButton
@onready var _import_pack_button = %ImportPackButton
@onready var _export_pack_button = %ExportPackButton
@onready var _selected_file_label = %SelectedFileLabel
@onready var _restore_button = %RestoreButton
@onready var _restore_all_button = %RestoreAllButton
@onready var _close_button = %CloseButton
@onready var _status_label = %StatusLabel
@onready var _export_file_dialog = %ExportFileDialog
@onready var _file_browser_panel = %FileBrowserPanel
@onready var _file_browser_title = %FileBrowserTitle
@onready var _browser_path_input = %BrowserPathInput
@onready var _browser_pick_folder_button = %BrowserPickFolderButton
@onready var _browser_up_button = %BrowserUpButton
@onready var _browser_refresh_button = %BrowserRefreshButton
@onready var _browser_item_list = %BrowserItemList
@onready var _browser_preview = %BrowserPreview
@onready var _browser_preview_label = %BrowserPreviewLabel
@onready var _browser_open_button = %BrowserOpenButton
@onready var _browser_cancel_button = %BrowserCancelButton
@onready var _folder_dialog = %FolderDialog

var _active_request = null
var _current_source_path := ""
var _current_target_size := Vector2i.ZERO
var _pending_request_source_path := ""
var _selected_upload_path := ""
var _refresh_accumulator := 0.0
var _file_dialog_mode := FILE_DIALOG_MODE_UPLOAD
var _browser_current_dir := ""
var _browser_selected_path := ""
var _browser_selection_is_dir := false
var _thumbnail_cache := {}


func _manager():
	return get_node_or_null("/root/CardArtOverrideManager")


func _ready() -> void:
	_configure_quality_options()
	_configure_file_dialog()
	_bind_signals()
	_api_key_input.secret = true
	var manager = _manager()
	_api_key_input.text = manager.get_session_api_key() if manager != null else ""
	_model_input.text = DEFAULT_MODEL
	_tab_container.set_tab_hidden(0, true)
	_tab_container.current_tab = 1
	_status_label.text = STATUS_READY
	_update_context(true)


func _process(delta: float) -> void:
	_refresh_accumulator += delta
	if _refresh_accumulator < 0.15:
		return
	_refresh_accumulator = 0.0
	_update_context(false)


func _on_edit_art_pressed() -> void:
	if _editor_popup.visible:
		_close_file_browser()
		_editor_popup.hide()
		return
	_update_context(true)
	if _current_source_path == "":
		_set_status("Open a card inspection view first.", true)
		return
	var manager = _manager()
	_api_key_input.text = manager.get_session_api_key() if manager != null else ""
	call_deferred("_open_editor_popup")


func _on_close_pressed() -> void:
	_close_file_browser()
	_editor_popup.hide()


func _on_restore_pressed() -> void:
	var manager = _manager()
	if manager == null:
		_set_status("The card art manager is not available.", true)
		return
	if _current_source_path == "":
		_set_status("No card art is selected.", true)
		return
	var result = manager.remove_override(_current_source_path)
	_set_status(String(result.get("message", "Unknown restore result.")), !bool(result.get("ok", false)))
	_update_context(true)


func _on_restore_all_pressed() -> void:
	var manager = _manager()
	if manager == null:
		_set_status("The card art manager is not available.", true)
		return
	var result = manager.remove_all_overrides()
	_set_status(String(result.get("message", "Unknown restore-all result.")), !bool(result.get("ok", false)))
	_update_context(true)


func _on_choose_image_pressed() -> void:
	if _current_source_path == "":
		_set_status("No card art is selected.", true)
		return
	_set_status("Choose an image file to replace the current card art.", false)
	_open_file_browser(FILE_DIALOG_MODE_UPLOAD)


func _on_import_shared_pressed() -> void:
	var manager = _manager()
	if manager == null:
		_set_status("The card art manager is not available.", true)
		return
	_set_status("Choose a shared art pack file to import all card image changes.", false)
	_open_file_browser(FILE_DIALOG_MODE_IMPORT_PACK)


func _on_export_override_pressed() -> void:
	var manager = _manager()
	if manager == null:
		_set_status("The card art manager is not available.", true)
		return
	if manager.get_override_count() == 0:
		_set_status("Apply at least one custom image first, then export the pack.", true)
		return
	_set_status("Choose where to save a bundle with all current custom card images.", false)
	_export_file_dialog.current_file = "card_art_bundle.cardartpack.json"
	_export_file_dialog.popup_centered_ratio(0.8)


func _apply_import_path(path: String) -> void:
	var manager = _manager()
	if manager == null:
		_set_status("The card art manager is not available.", true)
		return
	_selected_upload_path = path
	_selected_file_label.text = path.get_file()
	var is_import_pack = _file_dialog_mode == FILE_DIALOG_MODE_IMPORT_PACK
	var result = manager.import_bundle_from_file(path) if is_import_pack else manager.save_override_from_file(_current_source_path, path)
	if bool(result.get("ok", false)):
		if is_import_pack:
			manager.refresh_all_portraits()
		else:
			var portrait = _get_active_portrait()
			if portrait != null:
				manager.apply_override_to_texture_rect(portrait)
	_set_status("%s\nFile: %s" % [String(result.get("message", "Unknown upload result.")), path.get_file()], !bool(result.get("ok", false)))
	_update_context(true)


func _on_export_file_selected(path: String) -> void:
	_reopen_editor_popup()
	var manager = _manager()
	if manager == null:
		_set_status("The card art manager is not available.", true)
		return
	var result = manager.export_bundle_to_file(path)
	_set_status("%s\nFile: %s" % [String(result.get("message", "Unknown export result.")), path.get_file()], !bool(result.get("ok", false)))


func _on_export_dialog_canceled() -> void:
	_reopen_editor_popup()


func _on_generate_pressed() -> void:
	var manager = _manager()
	if manager == null:
		_set_status("The card art manager is not available.", true)
		return
	if _active_request != null:
		return
	if _current_source_path == "":
		_set_status("No card art is selected.", true)
		return

	var api_key = _api_key_input.text.strip_edges()
	if api_key == "":
		_set_status("Enter an API key before generating art.", true)
		return

	var prompt = _prompt_input.text.strip_edges()
	if prompt == "":
		_set_status("Enter a prompt for the new art.", true)
		return

	var source_image_bytes = manager.get_source_image_bytes(_current_source_path)
	if source_image_bytes.is_empty():
		_set_status("Could not read the original card art.", true)
		return

	var request_body = JSON.stringify({
		"contents": [{
			"parts": [
				{
					"text": _build_generation_prompt(prompt)
				},
				{
					"inline_data": {
						"mime_type": "image/png",
						"data": Marshalls.raw_to_base64(source_image_bytes)
					}
				}
			]
		}],
		"generationConfig": {
			"responseModalities": ["TEXT", "IMAGE"]
		}
	})

	var request = HTTPRequest.new()
	add_child(request)
	_active_request = request
	_pending_request_source_path = _current_source_path
	request.request_completed.connect(_on_generate_request_completed)

	var request_error = request.request_raw(
		GEMINI_API_URL_TEMPLATE % _get_model_name(),
		PackedStringArray([
			"x-goog-api-key: %s" % api_key,
			"Content-Type: application/json",
			"Accept: application/json"
		]),
		HTTPClient.METHOD_POST,
		request_body.to_utf8_buffer()
	)
	if request_error != OK:
		_active_request.queue_free()
		_active_request = null
		_pending_request_source_path = ""
		_set_status("The HTTP request could not be started.", true)
		return

	manager.set_session_api_key(api_key)
	_set_busy(true, "Generating new art from the current card image. This can take up to 2 minutes.")


func _on_generate_request_completed(_result, response_code: int, _headers, body: PackedByteArray) -> void:
	if _active_request != null:
		_active_request.queue_free()
	_active_request = null

	var source_path = _pending_request_source_path
	_pending_request_source_path = ""

	var response_text = body.get_string_from_utf8()
	if response_code < 200 or response_code >= 300:
		_set_busy(false, _extract_error_message(response_text), true)
		return

	var image_base64 = _extract_generated_image_base64(response_text)
	if image_base64 == "":
		_set_busy(false, "The Gemini response did not include image data.", true)
		return

	var image_bytes = Marshalls.base64_to_raw(image_base64)
	var generated_image = _decode_image_from_bytes(image_bytes)
	if generated_image == null:
		_set_busy(false, "The generated image could not be decoded.", true)
		return

	var manager = _manager()
	if manager == null:
		_set_busy(false, "The card art manager is not available.", true)
		return

	var result = manager.save_override_image(source_path, generated_image)
	_set_busy(false, String(result.get("message", "Unknown generation result.")))
	_update_context(true)


func _update_context(force_refresh: bool) -> void:
	var manager = _manager()
	if manager == null:
		_current_source_path = ""
		_current_target_size = Vector2i.ZERO
		_refresh_card_label()
		_edit_art_button.disabled = true
		_restore_button.disabled = true
		return

	var portrait = _get_active_portrait()
	var next_source_path = ""
	if portrait != null:
		next_source_path = manager.get_source_path_for_texture_rect(portrait)

	if force_refresh or next_source_path != _current_source_path:
		var source_changed = next_source_path != _current_source_path
		_current_source_path = next_source_path
		_current_target_size = manager.get_target_size_for_source_path(_current_source_path) if _current_source_path != "" else Vector2i.ZERO
		if source_changed:
			_selected_upload_path = ""
			_selected_file_label.text = "No image selected."
		_refresh_card_label()

	_edit_art_button.disabled = _current_source_path == ""
	_restore_button.disabled = _current_source_path == "" or !manager.has_override(_current_source_path)
	_export_pack_button.disabled = manager.get_override_count() == 0
	_import_pack_button.disabled = false
	_restore_all_button.disabled = manager.get_override_count() == 0


func _refresh_card_label() -> void:
	if _current_source_path == "":
		_current_card_label.text = "Current card: unavailable"
		return

	var file_name = _current_source_path.get_file().get_basename()
	_current_card_label.text = "Current card: %s\nTarget format: %dx%d PNG" % [
		file_name,
		_current_target_size.x,
		_current_target_size.y
	]


func _get_active_portrait():
	var screen = get_parent()
	if screen == null:
		return null

	var candidates: Array = []
	_collect_portrait_candidates(screen, candidates)
	if candidates.is_empty():
		return null

	var manager = _manager()
	var first_visible = null
	var first_with_source = null

	for candidate in candidates:
		var is_visible = _is_control_visible_in_tree(candidate)
		if is_visible and first_visible == null:
			first_visible = candidate

		if manager != null and first_with_source == null:
			var source_path = manager.get_source_path_for_texture_rect(candidate)
			if source_path != "":
				first_with_source = candidate
				if is_visible:
					return candidate

	if first_with_source != null:
		return first_with_source

	if first_visible != null:
		return first_visible

	return candidates[0]


func _collect_portrait_candidates(node, candidates: Array) -> void:
	for child in node.get_children():
		if child is TextureRect:
			var child_name = String(child.name)
			if (child_name == "Portrait" or child_name == "AncientPortrait") and child.texture != null:
				candidates.append(child)
		_collect_portrait_candidates(child, candidates)


func _is_control_visible_in_tree(control: Control) -> bool:
	var current = control
	while current != null:
		if !current.visible:
			return false
		current = current.get_parent() as Control
	return true


func _configure_quality_options() -> void:
	_quality_select.clear()
	_quality_select.add_item("Auto")
	_quality_select.add_item("Low")
	_quality_select.add_item("Medium")
	_quality_select.add_item("High")
	_quality_select.select(2)


func _configure_file_dialog() -> void:
	_export_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_export_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_export_file_dialog.filters = PackedStringArray([
		"*.cardartpack.json ; Card art bundle"
	])
	_folder_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	_folder_dialog.access = FileDialog.ACCESS_FILESYSTEM


func _bind_signals() -> void:
	_edit_art_button.pressed.connect(_on_edit_art_pressed)
	_close_button.pressed.connect(_on_close_pressed)
	_restore_button.pressed.connect(_on_restore_pressed)
	_restore_all_button.pressed.connect(_on_restore_all_pressed)
	_choose_image_button.pressed.connect(_on_choose_image_pressed)
	_import_pack_button.pressed.connect(_on_import_shared_pressed)
	_export_pack_button.pressed.connect(_on_export_override_pressed)
	_generate_button.pressed.connect(_on_generate_pressed)
	_export_file_dialog.file_selected.connect(_on_export_file_selected)
	_export_file_dialog.canceled.connect(_on_export_dialog_canceled)
	_browser_pick_folder_button.pressed.connect(_on_browser_pick_folder_pressed)
	_browser_up_button.pressed.connect(_on_browser_up_pressed)
	_browser_refresh_button.pressed.connect(_on_browser_refresh_pressed)
	_browser_open_button.pressed.connect(_on_browser_open_pressed)
	_browser_cancel_button.pressed.connect(_on_browser_cancel_pressed)
	_browser_path_input.text_submitted.connect(_on_browser_path_submitted)
	_browser_item_list.item_selected.connect(_on_browser_item_selected)
	_browser_item_list.item_activated.connect(_on_browser_item_activated)
	_folder_dialog.dir_selected.connect(_on_folder_selected)
	_folder_dialog.canceled.connect(_on_folder_dialog_canceled)


func _set_busy(is_busy: bool, message: String, is_error: bool = false) -> void:
	var manager = _manager()
	_generate_button.disabled = is_busy
	_choose_image_button.disabled = is_busy
	_import_pack_button.disabled = is_busy
	_export_pack_button.disabled = is_busy or manager == null or manager.get_override_count() == 0
	_restore_button.disabled = is_busy or _current_source_path == "" or manager == null or !manager.has_override(_current_source_path)
	_restore_all_button.disabled = is_busy or manager == null or manager.get_override_count() == 0
	_close_button.disabled = is_busy
	_edit_art_button.disabled = is_busy or _current_source_path == ""
	_set_status(message, is_error)


func _set_status(message: String, is_error: bool) -> void:
	_status_label.text = message
	_status_label.modulate = Color(1.0, 0.4, 0.4, 1.0) if is_error else Color(0.85, 0.95, 1.0, 1.0)


func _reopen_editor_popup() -> void:
	if _editor_popup.visible:
		return
	call_deferred("_open_editor_popup")


func _open_editor_popup() -> void:
	_editor_popup.show()
	_editor_popup.grab_focus()


func _open_file_browser(mode: String) -> void:
	_file_dialog_mode = mode
	_browser_selected_path = ""
	_browser_selection_is_dir = false
	_browser_open_button.disabled = true
	_browser_preview.texture = null
	_browser_preview_label.text = "미리보기를 표시할 파일을 선택하세요."
	_file_browser_title.text = "이미지 파일 선택" if mode == FILE_DIALOG_MODE_UPLOAD else "아트팩 파일 선택"
	_file_browser_panel.show()
	_refresh_file_browser(_resolve_browser_start_dir())


func _close_file_browser() -> void:
	_file_browser_panel.hide()
	_browser_selected_path = ""
	_browser_selection_is_dir = false
	_browser_open_button.disabled = true
	_browser_preview.texture = null
	_browser_preview_label.text = "미리보기를 표시할 파일을 선택하세요."


func _resolve_browser_start_dir() -> String:
	if _browser_current_dir != "":
		return _browser_current_dir
	if _selected_upload_path != "":
		return _selected_upload_path.get_base_dir()
	var pictures_dir = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	if pictures_dir != "":
		return pictures_dir
	var documents_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if documents_dir != "":
		return documents_dir
	return ProjectSettings.globalize_path("user://")


func _refresh_file_browser(target_dir: String) -> void:
	var dir = DirAccess.open(target_dir)
	if dir == null:
		_set_status("해당 경로를 열 수 없습니다.", true)
		return

	_browser_current_dir = target_dir
	_browser_path_input.text = target_dir
	_browser_item_list.clear()
	_browser_selected_path = ""
	_browser_selection_is_dir = false
	_browser_open_button.disabled = true
	_browser_preview.texture = null
	_browser_preview_label.text = "미리보기를 표시할 파일을 선택하세요."

	var directories: Array = []
	var files: Array = []
	dir.list_dir_begin()
	while true:
		var entry_name = dir.get_next()
		if entry_name == "":
			break
		if entry_name == "." or entry_name == "..":
			continue
		var full_path = target_dir.path_join(entry_name)
		if dir.current_is_dir():
			directories.append({
				"name": entry_name,
				"path": full_path,
				"is_dir": true
			})
		elif _is_browser_supported_file(entry_name):
			files.append({
				"name": entry_name,
				"path": full_path,
				"is_dir": false
			})
	dir.list_dir_end()

	directories.sort_custom(func(a, b): return String(a["name"]).nocasecmp_to(String(b["name"])) < 0)
	files.sort_custom(func(a, b): return String(a["name"]).nocasecmp_to(String(b["name"])) < 0)

	for entry in directories + files:
		var item_text = "[폴더] %s" % String(entry["name"]) if bool(entry["is_dir"]) else String(entry["name"])
		var item_index = _browser_item_list.add_item(item_text)
		_browser_item_list.set_item_metadata(item_index, entry)
		if !bool(entry["is_dir"]):
			var thumbnail = _get_thumbnail_for_browser(String(entry["path"]))
			if thumbnail != null:
				_browser_item_list.set_item_icon(item_index, thumbnail)


func _is_browser_supported_file(file_name: String) -> bool:
	var lower_name = file_name.to_lower()
	if _file_dialog_mode == FILE_DIALOG_MODE_IMPORT_PACK:
		return lower_name.ends_with(".cardartpack.json")
	return IMAGE_EXTENSIONS.has(file_name.get_extension().to_lower())


func _get_thumbnail_for_browser(path: String):
	if _thumbnail_cache.has(path):
		return _thumbnail_cache[path]
	if _file_dialog_mode != FILE_DIALOG_MODE_UPLOAD:
		return null
	var manager = _manager()
	if manager == null:
		return null
	var image = manager.load_image_from_file(path)
	if image == null:
		return null
	var thumbnail_image = image.duplicate()
	if thumbnail_image.is_compressed():
		var decompress_error = thumbnail_image.decompress()
		if decompress_error != OK:
			return null
	thumbnail_image.convert(Image.FORMAT_RGBA8)
	var scale = min(
		float(THUMBNAIL_SIZE.x) / float(max(thumbnail_image.get_width(), 1)),
		float(THUMBNAIL_SIZE.y) / float(max(thumbnail_image.get_height(), 1)),
		1.0
	)
	var resized_size = Vector2i(
		max(1, int(round(thumbnail_image.get_width() * scale))),
		max(1, int(round(thumbnail_image.get_height() * scale)))
	)
	thumbnail_image.resize(resized_size.x, resized_size.y, Image.INTERPOLATE_LANCZOS)
	var texture = ImageTexture.create_from_image(thumbnail_image)
	_thumbnail_cache[path] = texture
	return texture


func _on_browser_pick_folder_pressed() -> void:
	_folder_dialog.current_dir = _browser_current_dir if _browser_current_dir != "" else _resolve_browser_start_dir()
	_folder_dialog.popup_centered_ratio(0.7)


func _on_browser_up_pressed() -> void:
	if _browser_current_dir == "":
		return
	var parent_dir = _browser_current_dir.get_base_dir()
	if parent_dir == "" or parent_dir == _browser_current_dir:
		return
	_refresh_file_browser(parent_dir)


func _on_browser_refresh_pressed() -> void:
	_refresh_file_browser(_browser_current_dir if _browser_current_dir != "" else _resolve_browser_start_dir())


func _on_browser_path_submitted(new_text: String) -> void:
	var normalized = new_text.strip_edges()
	if normalized == "":
		return
	_refresh_file_browser(normalized)


func _on_browser_item_selected(index: int) -> void:
	var entry = _browser_item_list.get_item_metadata(index)
	if !(entry is Dictionary):
		return
	_browser_selected_path = String(entry.get("path", ""))
	_browser_selection_is_dir = bool(entry.get("is_dir", false))
	_browser_open_button.disabled = _browser_selected_path == ""
	if _browser_selection_is_dir:
		_browser_preview.texture = null
		_browser_preview_label.text = "폴더를 열려면 아래 버튼을 누르거나 항목을 한 번 더 선택하세요.\n%s" % _browser_selected_path
		return
	if _file_dialog_mode == FILE_DIALOG_MODE_IMPORT_PACK:
		_browser_preview.texture = null
		_browser_preview_label.text = "선택한 아트팩 파일:\n%s" % _browser_selected_path.get_file()
		return

	var manager = _manager()
	if manager == null:
		return
	var image = manager.load_image_from_file(_browser_selected_path)
	if image == null:
		_browser_preview.texture = null
		_browser_preview_label.text = "이미지를 미리보기로 불러올 수 없습니다."
		return
	_browser_preview.texture = ImageTexture.create_from_image(image)
	_browser_preview_label.text = "%s\n%d x %d" % [
		_browser_selected_path.get_file(),
		image.get_width(),
		image.get_height()
	]


func _on_browser_item_activated(index: int) -> void:
	_on_browser_item_selected(index)
	_on_browser_open_pressed()


func _on_browser_open_pressed() -> void:
	if _browser_selected_path == "":
		return
	if _browser_selection_is_dir:
		_refresh_file_browser(_browser_selected_path)
		return
	_close_file_browser()
	_reopen_editor_popup()
	_apply_import_path(_browser_selected_path)


func _on_browser_cancel_pressed() -> void:
	_close_file_browser()
	_reopen_editor_popup()


func _on_folder_selected(dir_path: String) -> void:
	_refresh_file_browser(dir_path)


func _on_folder_dialog_canceled() -> void:
	_file_browser_panel.grab_focus()


func _get_model_name() -> String:
	var model_name = _model_input.text.strip_edges()
	if model_name == "":
		return DEFAULT_MODEL
	return model_name


func _build_generation_prompt(user_prompt: String) -> String:
	return "Use the supplied card art only as a visual reference. Create a new fantasy illustration for a Slay the Spire 2 card portrait. Keep the central subject and action recognizable. Do not add text, card frames, borders, UI, watermarks, signatures, or letters. %s" % user_prompt


func _decode_image_from_bytes(image_bytes: PackedByteArray):
	var png_image = Image.new()
	if png_image.load_png_from_buffer(image_bytes) == OK:
		return png_image

	var jpg_image = Image.new()
	if jpg_image.load_jpg_from_buffer(image_bytes) == OK:
		return jpg_image

	var webp_image = Image.new()
	if webp_image.load_webp_from_buffer(image_bytes) == OK:
		return webp_image

	return null


func _extract_error_message(response_text: String) -> String:
	var parsed = JSON.parse_string(response_text)
	if parsed is Dictionary and parsed.has("error"):
		var error_entry = parsed["error"]
		if error_entry is Dictionary and error_entry.has("message"):
			return String(error_entry["message"])
	return "Image generation failed."


func _extract_generated_image_base64(response_text: String) -> String:
	var parsed = JSON.parse_string(response_text)
	if !(parsed is Dictionary):
		return ""

	var candidates = parsed.get("candidates", [])
	if !(candidates is Array) or candidates.is_empty():
		return ""

	for candidate in candidates:
		if !(candidate is Dictionary):
			continue
		var content = candidate.get("content", null)
		if !(content is Dictionary):
			continue
		var parts = content.get("parts", [])
		if !(parts is Array):
			continue
		for part in parts:
			if !(part is Dictionary):
				continue
			var inline_data = part.get("inline_data", null)
			if inline_data is Dictionary:
				var mime_type = String(inline_data.get("mime_type", ""))
				var data = String(inline_data.get("data", ""))
				if data != "" and mime_type.begins_with("image/"):
					return data

	return ""

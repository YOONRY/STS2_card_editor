extends Control

const GEMINI_API_URL_TEMPLATE := "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent"
const DEFAULT_MODEL := "gemini-2.0-flash-preview-image-generation"
const POPUP_SIZE := Vector2i(640, 720)
const UI_SETTINGS_PATH := "user://card_art_editor/ui_settings.json"
const STATUS_READY := "카드 이미지를 수정할 준비가 되었습니다."
const FILE_DIALOG_MODE_UPLOAD := "upload"
const FILE_DIALOG_MODE_IMPORT_PACK := "import_pack"
const FILE_DIALOG_MODE_IMPORT_MOD := "import_mod"
const EXPORT_DIALOG_MODE_PACK := "pack"
const EXPORT_DIALOG_MODE_CURRENT_PNG := "current_png"
const IMAGE_EXTENSIONS := ["png", "jpg", "jpeg", "webp", "gif"]
const THUMBNAIL_SIZE := Vector2i(120, 90)
const TRANSLATIONS := {
	"ko": {
		"edit_button": "카드 이미지 수정",
		"title": "카드 이미지 편집기",
		"current_card_unavailable": "현재 카드: 확인 불가",
		"current_card_format": "현재 카드: %s\n대상 포맷: %dx%d PNG",
		"hint": "불러온 이미지는 현재 카드 규격에 맞게 자동으로 중앙 크롭 및 리사이즈됩니다.",
		"upload_tab": "이미지 업로드",
		"upload_hint": "PNG, JPG, WebP, GIF 이미지를 선택할 수 있습니다. 현재 카드 규격에 맞게 자동 변환됩니다.",
		"choose_image": "파일에서 불러오기",
		"import_pack": "아트팩 불러오기",
		"export_pack": "아트팩 내보내기",
		"no_image_selected": "선택한 파일 없음",
		"restore_current": "현재 카드 복원",
		"restore_all": "전체 복원",
		"close": "닫기",
		"status_ready": "카드 이미지를 수정할 준비가 되었습니다.",
		"adjust_button": "이미지 조정",
		"adjust_title": "이미지 조정",
		"adjust_hint": "현재 적용된 이미지를 다시 배치합니다.",
		"adjust_zoom": "확대",
		"adjust_offset_x": "좌우 이동",
		"adjust_offset_y": "상하 이동",
		"cancel": "취소",
		"apply": "적용",
		"adjust_preview_format": "확대 %d%% / X %d / Y %d",
		"adjust_preview_error": "미리보기를 만들지 못했습니다.",
		"browser_preview_default": "미리보기를 표시할 파일을 선택해 주세요.",
		"browser_title_upload": "이미지 파일 선택",
		"browser_title_pack": "아트팩 파일 선택",
		"browser_path_placeholder": "폴더 경로 입력",
		"browser_move": "이동",
		"browser_up": "상위",
		"browser_refresh": "새로고침",
		"browser_open": "열기",
		"browser_directory_label": "[폴더] %s",
		"browser_directory_hint": "폴더를 열려면 아래 버튼을 누르거나 목록에서 다시 선택해 주세요.\n%s",
		"browser_pack_hint": "선택한 아트팩 파일:\n%s",
		"browser_image_error": "이미지를 미리보기로 불러올 수 없습니다.",
		"browser_gif_preview": "\nGIF 미리보기",
		"export_current_png": "PNG로 내보내기",
		"toggle_language": "English",
		"ancient_text_outside_enable": "고대 텍스트 밖으로",
		"ancient_text_outside_disable": "고대 텍스트 원위치"
	},
	"en": {
		"edit_button": "Edit Card Art",
		"title": "Card Art Editor",
		"current_card_unavailable": "Current card: unavailable",
		"current_card_format": "Current card: %s\nTarget format: %dx%d PNG",
		"hint": "Imported images are automatically center-cropped and resized to the current card format.",
		"upload_tab": "Upload Image",
		"upload_hint": "You can choose PNG, JPG, WebP, or GIF images. They are converted to the current card format automatically.",
		"choose_image": "Choose From Files",
		"import_pack": "Import Art Pack",
		"export_pack": "Export Art Pack",
		"no_image_selected": "No image selected.",
		"restore_current": "Restore Current",
		"restore_all": "Restore All",
		"close": "Close",
		"status_ready": "Ready to edit card art.",
		"adjust_button": "Adjust Image",
		"adjust_title": "Adjust Image",
		"adjust_hint": "Reposition the currently applied image.",
		"adjust_zoom": "Zoom",
		"adjust_offset_x": "Offset X",
		"adjust_offset_y": "Offset Y",
		"cancel": "Cancel",
		"apply": "Apply",
		"adjust_preview_format": "Zoom %d%% / X %d / Y %d",
		"adjust_preview_error": "Could not build the preview.",
		"browser_preview_default": "Select a file to preview it here.",
		"browser_title_upload": "Choose Image File",
		"browser_title_pack": "Choose Art Pack File",
		"browser_path_placeholder": "Enter folder path",
		"browser_move": "Go",
		"browser_up": "Up",
		"browser_refresh": "Refresh",
		"browser_open": "Open",
		"browser_directory_label": "[Folder] %s",
		"browser_directory_hint": "To open this folder, use the button below or activate it again in the list.\n%s",
		"browser_pack_hint": "Selected art pack file:\n%s",
		"browser_image_error": "Could not load the image preview.",
		"browser_gif_preview": "\nGIF preview",
		"export_current_png": "Save Current Card PNG",
		"toggle_language": "한국어",
		"ancient_text_outside_enable": "Move Ancient Text Outside",
		"ancient_text_outside_disable": "Restore Ancient Text"
	}
}

@onready var _edit_art_button = %EditArtButton
@onready var _editor_popup = %EditorPopup
@onready var _title_label = _editor_popup.get_node("MarginContainer/RootVBox/TitleLabel")
@onready var _current_card_label = %CurrentCardLabel
@onready var _hint_label = _editor_popup.get_node("MarginContainer/RootVBox/HintLabel")
@onready var _tab_container = %ModeTabs
@onready var _api_key_input = %ApiKeyInput
@onready var _model_input = %ModelInput
@onready var _quality_select = %QualitySelect
@onready var _prompt_input = %PromptInput
@onready var _generate_button = %GenerateButton
@onready var _upload_hint_label = _tab_container.get_node("UploadImage/UploadHintLabel")
@onready var _choose_image_button = %ChooseImageButton
@onready var _import_pack_button = %ImportPackButton
@onready var _import_mod_button = %ImportModButton
@onready var _export_pack_button = %ExportPackButton
@onready var _export_current_png_button = %ExportCurrentPngButton
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

var _active_request = null
var _current_source_path := ""
var _current_target_size := Vector2i.ZERO
var _pending_request_source_path := ""
var _selected_upload_path := ""
var _refresh_accumulator := 0.0
var _file_dialog_mode := FILE_DIALOG_MODE_UPLOAD
var _import_mod_label := "Import Mod Images"
var _export_dialog_mode := EXPORT_DIALOG_MODE_PACK
var _browser_current_dir := ""
var _browser_selected_path := ""
var _browser_selection_is_dir := false
var _browser_last_dirs := {}
var _export_last_dirs := {}
var _favorite_dirs: Array = []
var _thumbnail_cache := {}
var _locale := "ko"
var _language_button: Button
var _gif_settings_button: Button
var _adjust_button: Button
var _display_mode_button: Button
var _infection_effect_button: Button
var _ancient_text_outside_button: Button
var _ancient_text_panel: PanelContainer
var _ancient_text_panel_title: Label
var _ancient_text_panel_body: RichTextLabel
var _favorite_add_button: Button
var _favorites_menu_button: MenuButton
var _adjust_panel: PanelContainer
var _adjust_preview_frame: PanelContainer
var _adjust_preview: TextureRect
var _adjust_preview_label: Label
var _adjust_title_label: Label
var _adjust_zoom_label: Label
var _adjust_x_label: Label
var _adjust_y_label: Label
var _adjust_zoom_slider: HSlider
var _adjust_x_slider: HSlider
var _adjust_y_slider: HSlider
var _adjust_apply_button: Button
var _adjust_cancel_button: Button
var _adjust_reset_button: Button
var _progress_bar: ProgressBar
var _art_pack_panel: PanelContainer
var _art_pack_list_label: Label
var _art_pack_list: ItemList
var _art_pack_apply_all_button: Button
var _art_pack_remove_button: Button
var _art_pack_variant_label: Label
var _art_pack_variant_select: OptionButton
var _art_pack_apply_button: Button
var _art_pack_list_ids: Array = []
var _art_pack_variant_ids: Array = []
var _art_pack_ui_state := ""
var _adjust_source_image = null
var _adjust_source_path := ""
var _adjust_drag_active := false
var _gif_settings_popup: PanelContainer
var _gif_settings_hint_label: Label
var _gif_preset_label: Label
var _gif_preset_fast_button: Button
var _gif_preset_balanced_button: Button
var _gif_preset_quality_button: Button
var _gif_cache_check: CheckBox
var _gif_dedupe_check: CheckBox
var _gif_limit_check: CheckBox
var _gif_limit_spinbox: SpinBox
var _gif_settings_close_button: Button
var _gif_settings_ui_syncing := false
var _gif_processing_settings := {
	"use_cache": true,
	"skip_duplicate_frames": true,
	"use_frame_limit": false,
	"max_frames": 36
}
var _infection_effect_hidden_enabled := true
var _ancient_text_outside_by_source := {}
var _ui_initialized := false


func _manager():
	return get_node_or_null("/root/CardArtOverrideManager")


func _get_inspect_card():
	var screen = get_parent()
	if screen == null:
		return null
	return screen.get_node_or_null("Card")


func _pick_best_source_path(manager, candidates: Array) -> String:
	if manager == null:
		for candidate in candidates:
			var path = String(candidate)
			if path != "":
				return path
		return ""
	for candidate in candidates:
		var path = String(candidate)
		if path != "" and manager.has_override(path):
			return path
	for candidate in candidates:
		var path = String(candidate)
		if path != "":
			return path
	return ""


func _get_effective_source_path() -> String:
	if _current_source_path != "":
		return _current_source_path
	var manager = _manager()
	var candidates: Array = []
	if _current_source_path != "":
		candidates.append(_current_source_path)
	var inspect_card = _get_inspect_card()
	if inspect_card != null:
		if manager != null:
			var card_path = manager.get_source_path_for_card_node(inspect_card)
			var model_path = manager.get_source_path_for_model(inspect_card.get("Model"))
			var portrait = inspect_card.get_node_or_null("CardContainer/PortraitCanvasGroup/Portrait")
			var ancient_portrait = inspect_card.get_node_or_null("CardContainer/PortraitCanvasGroup/AncientPortrait")
			var portrait_path = ""
			if ancient_portrait is TextureRect:
				portrait_path = manager.get_source_path_for_texture_rect(ancient_portrait)
			if portrait_path == "" and portrait is TextureRect:
				portrait_path = manager.get_source_path_for_texture_rect(portrait)
			candidates.append(card_path)
			candidates.append(model_path)
			candidates.append(portrait_path)
	return _pick_best_source_path(manager, candidates)


func _get_context_source_path_fast() -> String:
	var manager = _manager()
	if manager == null:
		return ""
	var inspect_card = _get_inspect_card()
	if inspect_card != null:
		var model = inspect_card.get("Model")
		var model_path = manager.get_source_path_for_model(model)
		if model_path != "":
			return model_path
		if inspect_card.has_meta("_card_art_inspect_source_path"):
			var inspect_meta_path = String(inspect_card.get_meta("_card_art_inspect_source_path", ""))
			if inspect_meta_path != "":
				return inspect_meta_path
	if _current_source_path != "":
		return _current_source_path
	return ""


func _tr(key: String) -> String:
	var locale_table = TRANSLATIONS.get(_locale, TRANSLATIONS["ko"])
	return String(locale_table.get(key, key))


func _load_ui_settings() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(UI_SETTINGS_PATH).get_base_dir())
	if !FileAccess.file_exists(UI_SETTINGS_PATH):
		return
	var file = FileAccess.open(UI_SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		var locale_value = String(parsed.get("locale", "ko"))
		if TRANSLATIONS.has(locale_value):
			_locale = locale_value
		var parsed_browser_dirs = parsed.get("browser_last_dirs", {})
		if parsed_browser_dirs is Dictionary:
			_browser_last_dirs = parsed_browser_dirs.duplicate(true)
		var parsed_export_dirs = parsed.get("export_last_dirs", {})
		if parsed_export_dirs is Dictionary:
			_export_last_dirs = parsed_export_dirs.duplicate(true)
		var parsed_favorites = parsed.get("favorite_dirs", [])
		if parsed_favorites is Array:
			_favorite_dirs.clear()
			for path in parsed_favorites:
				var normalized = _normalize_existing_dir(String(path))
				if normalized != "" and !_favorite_dirs.has(normalized):
					_favorite_dirs.append(normalized)
		var parsed_gif_settings = parsed.get("gif_processing_settings", {})
		if parsed_gif_settings is Dictionary:
			_gif_processing_settings["use_cache"] = bool(parsed_gif_settings.get("use_cache", true))
			_gif_processing_settings["skip_duplicate_frames"] = bool(parsed_gif_settings.get("skip_duplicate_frames", true))
			_gif_processing_settings["use_frame_limit"] = bool(parsed_gif_settings.get("use_frame_limit", false))
			_gif_processing_settings["max_frames"] = clamp(int(parsed_gif_settings.get("max_frames", 36)), 1, 300)
		_infection_effect_hidden_enabled = bool(parsed.get("infection_effect_hidden_enabled", true))
		var parsed_ancient_settings = parsed.get("ancient_text_outside_by_source", {})
		if parsed_ancient_settings is Dictionary:
			_ancient_text_outside_by_source = parsed_ancient_settings.duplicate(true)


func _save_ui_settings() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(UI_SETTINGS_PATH).get_base_dir())
	var file = FileAccess.open(UI_SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return
	var manager = _manager()
	var ancient_settings = manager.get_ancient_text_outside_settings() if manager != null and manager.has_method("get_ancient_text_outside_settings") else _ancient_text_outside_by_source
	file.store_string(JSON.stringify({
		"locale": _locale,
		"browser_last_dirs": _browser_last_dirs,
		"export_last_dirs": _export_last_dirs,
		"favorite_dirs": _favorite_dirs,
		"gif_processing_settings": _gif_processing_settings,
		"infection_effect_hidden_enabled": _infection_effect_hidden_enabled,
		"ancient_text_outside_by_source": ancient_settings
	}))
	file.flush()


func _toggle_locale() -> void:
	_locale = "en" if _locale == "ko" else "ko"
	_save_ui_settings()
	_apply_locale()


func _apply_locale() -> void:
	_edit_art_button.text = _tr("edit_button")
	_title_label.text = _tr("title")
	_hint_label.text = _tr("hint")
	_upload_hint_label.text = _tr("upload_hint")
	_choose_image_button.text = _tr("choose_image")
	_import_pack_button.text = _tr("import_pack")
	_import_mod_label = "\uBAA8\uB4DC\uD329 \uCD94\uCD9C" if _locale == "ko" else "Import Mod Images"
	_import_mod_button.text = _import_mod_label
	_export_pack_button.text = _tr("export_pack")
	_export_current_png_button.text = _tr("export_current_png")
	_restore_button.text = _tr("restore_current")
	_restore_all_button.text = _tr("restore_all")
	_close_button.text = _tr("close")
	_browser_path_input.placeholder_text = _tr("browser_path_placeholder")
	_browser_pick_folder_button.text = _tr("browser_move")
	_browser_up_button.text = _tr("browser_up")
	_browser_refresh_button.text = _tr("browser_refresh")
	_browser_open_button.text = _tr("browser_open")
	_refresh_gif_settings_ui()
	_browser_cancel_button.text = _tr("cancel")
	_file_browser_title.text = _tr("browser_title_upload") if _file_dialog_mode == FILE_DIALOG_MODE_UPLOAD else _tr("browser_title_pack")
	_browser_preview_label.text = _tr("browser_preview_default")
	_configure_export_dialog(_export_dialog_mode)
	_selected_file_label.text = _tr("no_image_selected") if _selected_upload_path == "" else _selected_upload_path.get_file()
	_tab_container.set_tab_title(1, _tr("upload_tab"))
	if _language_button != null:
		_language_button.text = _tr("toggle_language")
	if _adjust_button != null:
		_adjust_button.text = _tr("adjust_button")
	if _display_mode_button != null:
		_display_mode_button.text = _get_display_mode_button_text()
	if _adjust_title_label != null:
		_adjust_title_label.text = _tr("adjust_title")
	if _adjust_preview_label != null and (_adjust_source_image == null or _adjust_preview.texture == null):
		_adjust_preview_label.text = _tr("adjust_hint")
	if _adjust_zoom_label != null:
		_adjust_zoom_label.text = _tr("adjust_zoom")
	if _adjust_x_label != null:
		_adjust_x_label.text = _tr("adjust_offset_x")
	if _adjust_y_label != null:
		_adjust_y_label.text = _tr("adjust_offset_y")
	if _adjust_cancel_button != null:
		_adjust_cancel_button.text = _tr("cancel")
	if _adjust_reset_button != null:
		_adjust_reset_button.text = "Reset"
	if _adjust_apply_button != null:
		_adjust_apply_button.text = _tr("apply")
	if _favorites_menu_button != null:
		_favorites_menu_button.text = "즐겨찾기" if _locale == "ko" else "Favorites"
		_refresh_favorites_menu()
	if _editor_popup.visible or _current_source_path != "":
		_refresh_art_pack_manager_ui()
		_refresh_infection_effect_button()
		_refresh_ancient_text_outside_button()
		_refresh_ancient_text_panel()
		_refresh_card_label()


func _get_display_mode_button_text() -> String:
	var manager = _manager()
	var source_path = _get_effective_source_path()
	var is_full_art = manager != null and source_path != "" and manager.is_full_art_mode(source_path)
	if _locale == "en":
		return "Disable Full Art" if is_full_art else "Enable Full Art"
	return "풀아트 끄기" if is_full_art else "풀아트 켜기"


func _is_current_infection_card() -> bool:
	var inspect_card = _get_inspect_card()
	if inspect_card == null:
		return false
	if inspect_card.has_meta("_card_art_inspect_card_id"):
		var inspect_id = String(inspect_card.get_meta("_card_art_inspect_card_id", ""))
		if inspect_id.to_upper() == "INFECTION":
			return true
	var effective_source_path = _get_effective_source_path()
	if effective_source_path.get_file().get_basename().to_lower() == "infection":
		return true
	var model = inspect_card.get("Model")
	if model == null:
		return false
	var type_name = String(model.get_class())
	if type_name.to_lower().contains("infection"):
		return true
	var id = model.get("Id")
	if id != null:
		var entry = String(id.get("Entry"))
		if entry.to_upper() == "INFECTION":
			return true
	return false


func _refresh_infection_effect_button() -> void:
	if _infection_effect_button == null:
		return
	var manager = _manager()
	var visible = _is_current_infection_card()
	_infection_effect_button.visible = visible
	if !visible or manager == null:
		return
	var hidden_enabled = bool(manager.is_infection_effect_hidden_enabled())
	if _locale == "en":
		_infection_effect_button.text = "Show Infection Effect" if hidden_enabled else "Hide Infection Effect"
	else:
		_infection_effect_button.text = "감염 이펙트 켜기" if hidden_enabled else "감염 이펙트 끄기"


func _is_current_ancient_card() -> bool:
	var inspect_card = _get_inspect_card()
	if inspect_card == null:
		return false
	var ancient_portrait = inspect_card.get_node_or_null("CardContainer/PortraitCanvasGroup/AncientPortrait")
	if ancient_portrait is CanvasItem and (ancient_portrait as CanvasItem).visible:
		return true
	var model = inspect_card.get("Model")
	if model == null:
		return false
	var rarity = model.get("Rarity")
	if rarity != null and String(rarity).to_lower() == "ancient":
		return true
	var effective_source_path = _get_effective_source_path().to_lower()
	return effective_source_path.contains("ancient")


func _is_current_ancient_text_outside_supported_card() -> bool:
	var source_path = _get_effective_source_path()
	if source_path == "":
		return false
	var manager = _manager()
	if manager != null and manager.is_full_art_mode(source_path):
		return true
	return _is_current_ancient_card()


func _refresh_ancient_text_outside_button() -> void:
	if _ancient_text_outside_button == null:
		return
	var manager = _manager()
	var source_path = _get_effective_source_path()
	var visible = _is_current_ancient_text_outside_supported_card() and source_path != ""
	_ancient_text_outside_button.visible = visible
	if !visible or manager == null:
		return
	var enabled = bool(manager.is_ancient_text_outside_enabled(source_path))
	_ancient_text_outside_button.text = _tr("ancient_text_outside_disable") if enabled else _tr("ancient_text_outside_enable")


func _get_current_description_text() -> String:
	var inspect_card = _get_inspect_card()
	if inspect_card == null:
		return ""
	var description_label = inspect_card.get_node_or_null("CardContainer/DescriptionLabel")
	if description_label is RichTextLabel:
		return String((description_label as RichTextLabel).text)
	return ""


func _normalize_ancient_text_panel_bbcode(text: String) -> String:
	var normalized = text.strip_edges()
	normalized = normalized.replace("[center]", "")
	normalized = normalized.replace("[/center]", "")
	var tag_regex := RegEx.new()
	if tag_regex.compile("\\[[^\\]]+\\]") == OK:
		normalized = tag_regex.sub(normalized, "", true)
	normalized = normalized.replace("\r", "")
	var line_regex := RegEx.new()
	if line_regex.compile("\\n{3,}") == OK:
		normalized = line_regex.sub(normalized, "\n\n", true)
	return normalized


func _layout_ancient_text_panel() -> void:
	if _ancient_text_panel == null or !_ancient_text_panel.visible:
		return
	var screen = get_parent()
	if screen == null:
		return
	var hover_tip_rect = screen.get_node_or_null("HoverTipRect")
	if hover_tip_rect is Control:
		var anchor = hover_tip_rect as Control
		var anchor_right = anchor.global_position.x + (anchor.size.x * anchor.scale.x)
		var anchor_top = anchor.global_position.y
		_ancient_text_panel.global_position = Vector2(anchor_right + 10.0, anchor_top + 125.0)


func _update_ancient_text_panel_metrics() -> void:
	if _ancient_text_panel == null or _ancient_text_panel_body == null or !_ancient_text_panel.visible:
		return
	var content_height = _ancient_text_panel_body.get_content_height()
	var panel_height = clampf(content_height + 52.0, 118.0, 260.0)
	_ancient_text_panel.size = Vector2(400.0, panel_height)
	_layout_ancient_text_panel()


func _refresh_ancient_text_panel() -> void:
	if _ancient_text_panel == null:
		return
	_ancient_text_panel.visible = false


func _apply_gif_processing_settings_to_manager() -> void:
	var manager = _manager()
	if manager != null and manager.has_method("set_gif_processing_settings"):
		manager.set_gif_processing_settings(_gif_processing_settings)


func _refresh_gif_settings_ui() -> void:
	if _gif_settings_button == null:
		return
	var is_ko = _locale == "ko"
	_gif_settings_button.text = "GIF 설정" if is_ko else "GIF Settings"
	_gif_settings_button.tooltip_text = "GIF 설정" if is_ko else "GIF Settings"
	if _gif_cache_check == null:
		return
	if _gif_settings_hint_label != null:
		_gif_settings_hint_label.text = "이 옵션은 GIF를 불러오거나 다시 적용할 때만 성능에 영향을 줍니다." if is_ko else "These options only affect performance when importing or reapplying GIFs."
	if _gif_preset_label != null:
		_gif_preset_label.text = "GIF 프리셋" if is_ko else "GIF Presets"
	if _gif_preset_fast_button != null:
		_gif_preset_fast_button.text = "고속" if is_ko else "Fast"
	if _gif_preset_balanced_button != null:
		_gif_preset_balanced_button.text = "균형" if is_ko else "Balanced"
	if _gif_preset_quality_button != null:
		_gif_preset_quality_button.text = "품질" if is_ko else "Quality"
	_gif_cache_check.text = "GIF 캐시 사용" if is_ko else "Use GIF cache"
	_gif_dedupe_check.text = "중복 프레임 건너뛰기" if is_ko else "Skip duplicate frames"
	_gif_limit_check.text = "프레임 제한 사용" if is_ko else "Use frame limit"
	_gif_settings_close_button.text = "닫기" if is_ko else "Close"
	_gif_settings_ui_syncing = true
	_gif_cache_check.button_pressed = bool(_gif_processing_settings.get("use_cache", true))
	_gif_dedupe_check.button_pressed = bool(_gif_processing_settings.get("skip_duplicate_frames", true))
	_gif_limit_check.button_pressed = bool(_gif_processing_settings.get("use_frame_limit", false))
	_gif_limit_spinbox.value = int(_gif_processing_settings.get("max_frames", 36))
	_gif_limit_spinbox.editable = _gif_limit_check.button_pressed
	_gif_settings_ui_syncing = false


func _build_adjust_ui() -> void:
	var footer_row = _restore_button.get_parent()
	_language_button = Button.new()
	_language_button.text = "English"
	footer_row.add_child(_language_button)
	footer_row.move_child(_language_button, 0)
	_gif_settings_button = Button.new()
	_gif_settings_button.text = "GIF Settings"
	_gif_settings_button.tooltip_text = "GIF Settings"
	footer_row.add_child(_gif_settings_button)
	footer_row.move_child(_gif_settings_button, 1)
	_gif_settings_button.visible = true
	_gif_settings_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_adjust_button = Button.new()
	_adjust_button.text = "이미지 조정"
	footer_row.add_child(_adjust_button)
	footer_row.move_child(_adjust_button, 2)

	_display_mode_button = Button.new()
	_display_mode_button.text = "Enable Full Art"
	footer_row.add_child(_display_mode_button)
	footer_row.move_child(_display_mode_button, 3)

	_infection_effect_button = Button.new()
	_infection_effect_button.visible = false
	footer_row.add_child(_infection_effect_button)
	footer_row.move_child(_infection_effect_button, 4)

	_ancient_text_outside_button = Button.new()
	_ancient_text_outside_button.visible = false
	footer_row.add_child(_ancient_text_outside_button)
	footer_row.move_child(_ancient_text_outside_button, 5)

	_ancient_text_panel = PanelContainer.new()
	_ancient_text_panel.name = "AncientTextPanel"
	_ancient_text_panel.visible = false
	_ancient_text_panel.top_level = true
	_ancient_text_panel.z_as_relative = false
	_ancient_text_panel.z_index = 1150
	_ancient_text_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ancient_text_panel.set_anchors_preset(Control.PRESET_CENTER)
	_ancient_text_panel.offset_left = 0
	_ancient_text_panel.offset_top = 0
	_ancient_text_panel.offset_right = 400
	_ancient_text_panel.offset_bottom = 140
	add_child(_ancient_text_panel)

	var hover_tip_texture = load("res://images/ui/hover_tip.png")
	var shadow = NinePatchRect.new()
	shadow.modulate = Color(0, 0, 0, 0.25098)
	shadow.texture = hover_tip_texture
	shadow.region_rect = Rect2(-8, -8, 339, 107)
	shadow.patch_margin_left = 55
	shadow.patch_margin_top = 43
	shadow.patch_margin_right = 91
	shadow.patch_margin_bottom = 32
	shadow.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	shadow.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ancient_text_panel.add_child(shadow)

	var bg = NinePatchRect.new()
	bg.texture = hover_tip_texture
	bg.region_rect = Rect2(0, 0, 339, 107)
	bg.patch_margin_left = 55
	bg.patch_margin_top = 43
	bg.patch_margin_right = 91
	bg.patch_margin_bottom = 32
	bg.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	bg.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ancient_text_panel.add_child(bg)

	var ancient_margin = MarginContainer.new()
	ancient_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	ancient_margin.add_theme_constant_override("margin_left", 22)
	ancient_margin.add_theme_constant_override("margin_top", 16)
	ancient_margin.add_theme_constant_override("margin_right", 45)
	ancient_margin.add_theme_constant_override("margin_bottom", 28)
	_ancient_text_panel.add_child(ancient_margin)

	var ancient_root = VBoxContainer.new()
	ancient_root.add_theme_constant_override("separation", 0)
	ancient_margin.add_child(ancient_root)

	var title_row = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 5)
	ancient_root.add_child(title_row)

	_ancient_text_panel_title = Label.new()
	_ancient_text_panel_title.text = "카드 텍스트"
	_ancient_text_panel_title.add_theme_color_override("font_color", Color(0.937255, 0.784314, 0.317647, 1))
	_ancient_text_panel_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.25098))
	_ancient_text_panel_title.add_theme_constant_override("shadow_offset_x", 3)
	_ancient_text_panel_title.add_theme_constant_override("shadow_offset_y", 2)
	_ancient_text_panel_title.add_theme_font_override("font", load("res://themes/kreon_bold_glyph_space_one.tres"))
	_ancient_text_panel_title.add_theme_font_size_override("font_size", 22)
	title_row.add_child(_ancient_text_panel_title)

	_ancient_text_panel_body = RichTextLabel.new()
	_ancient_text_panel_body.bbcode_enabled = true
	_ancient_text_panel_body.fit_content = true
	_ancient_text_panel_body.scroll_active = false
	_ancient_text_panel_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ancient_text_panel_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ancient_text_panel_body.custom_minimum_size = Vector2(300, 0)
	_ancient_text_panel_body.add_theme_color_override("default_color", Color(1, 0.964706, 0.886275, 1))
	_ancient_text_panel_body.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.25098))
	_ancient_text_panel_body.add_theme_constant_override("line_separation", -2)
	_ancient_text_panel_body.add_theme_constant_override("shadow_offset_x", 3)
	_ancient_text_panel_body.add_theme_constant_override("shadow_offset_y", 2)
	_ancient_text_panel_body.add_theme_font_override("normal_font", load("res://themes/kreon_regular_glyph_space_one.tres"))
	_ancient_text_panel_body.add_theme_font_override("bold_font", load("res://themes/kreon_bold_glyph_space_one.tres"))
	_ancient_text_panel_body.add_theme_font_size_override("normal_font_size", 22)
	ancient_root.add_child(_ancient_text_panel_body)

	_adjust_panel = PanelContainer.new()
	_adjust_panel.name = "AdjustPanel"
	_adjust_panel.visible = false
	_adjust_panel.top_level = true
	_adjust_panel.z_as_relative = false
	_adjust_panel.z_index = 1200
	_adjust_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_adjust_panel.set_anchors_preset(Control.PRESET_CENTER)
	_adjust_panel.offset_left = -360
	_adjust_panel.offset_top = -300
	_adjust_panel.offset_right = 360
	_adjust_panel.offset_bottom = 300
	add_child(_adjust_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_adjust_panel.add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var title = Label.new()
	title.text = "이미지 조정"
	root.add_child(title)
	_adjust_title_label = title

	_adjust_preview_frame = PanelContainer.new()
	_adjust_preview_frame.custom_minimum_size = Vector2(520, 260)
	root.add_child(_adjust_preview_frame)

	_adjust_preview = TextureRect.new()
	_adjust_preview.custom_minimum_size = Vector2(520, 260)
	_adjust_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_adjust_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_adjust_preview.mouse_filter = Control.MOUSE_FILTER_STOP
	_adjust_preview_frame.add_child(_adjust_preview)
	_adjust_preview.set_anchors_preset(Control.PRESET_FULL_RECT)

	_adjust_preview_label = Label.new()
	_adjust_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_adjust_preview_label.text = "Drag the preview to reposition it. Use zoom to crop tighter."
	root.add_child(_adjust_preview_label)

	root.add_child(_make_adjust_slider_row("확대", "_adjust_zoom_slider", 100, 300, 1, 100))
	root.add_child(_make_adjust_slider_row("좌우 이동", "_adjust_x_slider", -100, 100, 1, 0))
	root.add_child(_make_adjust_slider_row("상하 이동", "_adjust_y_slider", -100, 100, 1, 0))

	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	root.add_child(button_row)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_row.add_child(spacer)

	_adjust_reset_button = Button.new()
	_adjust_reset_button.text = "Reset"
	button_row.add_child(_adjust_reset_button)

	_adjust_cancel_button = Button.new()
	_adjust_cancel_button.text = "취소"
	button_row.add_child(_adjust_cancel_button)

	_adjust_apply_button = Button.new()
	_adjust_apply_button.text = "적용"
	button_row.add_child(_adjust_apply_button)

	_adjust_zoom_label = _adjust_zoom_slider.get_parent().get_child(0) as Label
	_adjust_x_label = _adjust_x_slider.get_parent().get_child(0) as Label
	_adjust_y_label = _adjust_y_slider.get_parent().get_child(0) as Label
	_adjust_zoom_slider.get_parent().visible = false
	_adjust_x_slider.get_parent().visible = false
	_adjust_y_slider.get_parent().visible = false

	_gif_settings_popup = PanelContainer.new()
	_gif_settings_popup.name = "GifSettingsPopup"
	_gif_settings_popup.visible = false
	_gif_settings_popup.top_level = true
	_gif_settings_popup.z_as_relative = false
	_gif_settings_popup.z_index = 1210
	_gif_settings_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	_gif_settings_popup.set_anchors_preset(Control.PRESET_CENTER)
	_gif_settings_popup.offset_left = -220
	_gif_settings_popup.offset_top = -120
	_gif_settings_popup.offset_right = 220
	_gif_settings_popup.offset_bottom = 120
	var gif_popup_style = StyleBoxFlat.new()
	gif_popup_style.bg_color = Color(0.10, 0.10, 0.12, 1.0)
	gif_popup_style.border_color = Color(0.72, 0.72, 0.76, 1.0)
	gif_popup_style.border_width_left = 1
	gif_popup_style.border_width_top = 1
	gif_popup_style.border_width_right = 1
	gif_popup_style.border_width_bottom = 1
	gif_popup_style.corner_radius_top_left = 8
	gif_popup_style.corner_radius_top_right = 8
	gif_popup_style.corner_radius_bottom_left = 8
	gif_popup_style.corner_radius_bottom_right = 8
	_gif_settings_popup.add_theme_stylebox_override("panel", gif_popup_style)
	add_child(_gif_settings_popup)

	var gif_margin = MarginContainer.new()
	gif_margin.add_theme_constant_override("margin_left", 16)
	gif_margin.add_theme_constant_override("margin_top", 16)
	gif_margin.add_theme_constant_override("margin_right", 16)
	gif_margin.add_theme_constant_override("margin_bottom", 16)
	_gif_settings_popup.add_child(gif_margin)

	var gif_root = VBoxContainer.new()
	gif_root.add_theme_constant_override("separation", 10)
	gif_margin.add_child(gif_root)

	var gif_title = Label.new()
	gif_title.text = "GIF Settings"
	gif_root.add_child(gif_title)

	_gif_settings_hint_label = Label.new()
	_gif_settings_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_gif_settings_hint_label.add_theme_font_size_override("font_size", 13)
	gif_root.add_child(_gif_settings_hint_label)

	_gif_preset_label = Label.new()
	_gif_preset_label.text = "GIF Presets"
	gif_root.add_child(_gif_preset_label)

	var gif_preset_row = HBoxContainer.new()
	gif_preset_row.add_theme_constant_override("separation", 8)
	gif_root.add_child(gif_preset_row)

	_gif_preset_fast_button = Button.new()
	_gif_preset_fast_button.text = "Fast"
	gif_preset_row.add_child(_gif_preset_fast_button)

	_gif_preset_balanced_button = Button.new()
	_gif_preset_balanced_button.text = "Balanced"
	_gif_preset_balanced_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gif_preset_row.add_child(_gif_preset_balanced_button)

	_gif_preset_quality_button = Button.new()
	_gif_preset_quality_button.text = "Quality"
	gif_preset_row.add_child(_gif_preset_quality_button)

	_gif_cache_check = CheckBox.new()
	gif_root.add_child(_gif_cache_check)

	_gif_dedupe_check = CheckBox.new()
	gif_root.add_child(_gif_dedupe_check)

	_gif_limit_check = CheckBox.new()
	gif_root.add_child(_gif_limit_check)

	var limit_row = HBoxContainer.new()
	limit_row.add_theme_constant_override("separation", 8)
	gif_root.add_child(limit_row)
	var limit_label = Label.new()
	limit_label.text = "Max Frames"
	limit_row.add_child(limit_label)
	_gif_limit_spinbox = SpinBox.new()
	_gif_limit_spinbox.min_value = 1
	_gif_limit_spinbox.max_value = 300
	_gif_limit_spinbox.step = 1
	_gif_limit_spinbox.value = 36
	_gif_limit_spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	limit_row.add_child(_gif_limit_spinbox)

	var gif_button_row = HBoxContainer.new()
	var gif_spacer = Control.new()
	gif_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gif_button_row.add_child(gif_spacer)
	_gif_settings_close_button = Button.new()
	_gif_settings_close_button.text = "Close"
	gif_button_row.add_child(_gif_settings_close_button)
	gif_root.add_child(gif_button_row)
	_refresh_gif_settings_ui()


func _make_adjust_slider_row(label_text: String, slider_property: String, min_value: float, max_value: float, step: float, default_value: float):
	var row = VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var label = Label.new()
	label.text = label_text
	row.add_child(label)

	var slider = HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = default_value
	row.add_child(slider)

	set(slider_property, slider)
	return row


func _ready() -> void:
	_load_ui_settings()
	_edit_art_button.text = _tr("edit_button")
	if !_edit_art_button.pressed.is_connected(_on_edit_art_pressed):
		_edit_art_button.pressed.connect(_on_edit_art_pressed)
	_status_label.text = _tr("status_ready")


func _initialize_editor_ui_once() -> void:
	if _ui_initialized:
		return
	_ui_initialized = true
	_build_adjust_ui()
	_build_progress_ui()
	_build_browser_shortcuts_ui()
	_build_art_pack_manager_ui()
	_configure_quality_options()
	_configure_file_dialog()
	_bind_signals()
	_api_key_input.secret = true
	var manager = _manager()
	_api_key_input.text = manager.get_session_api_key() if manager != null else ""
	_model_input.text = DEFAULT_MODEL
	_tab_container.set_tab_hidden(0, true)
	_tab_container.current_tab = 1
	_apply_locale()
	_apply_gif_processing_settings_to_manager()
	if manager != null and manager.has_method("set_infection_effect_hidden_enabled"):
		manager.set_infection_effect_hidden_enabled(_infection_effect_hidden_enabled)
	_status_label.text = _tr("status_ready")


func _build_browser_shortcuts_ui() -> void:
	var path_row = _file_browser_panel.get_node_or_null("MarginContainer/RootVBox/PathRow")
	if path_row == null or _favorites_menu_button != null:
		return

	_favorite_add_button = Button.new()
	_favorite_add_button.text = "★"
	_favorite_add_button.custom_minimum_size = Vector2(42, 0)
	path_row.add_child(_favorite_add_button)

	_favorites_menu_button = MenuButton.new()
	_favorites_menu_button.text = "즐겨찾기" if _locale == "ko" else "Favorites"
	_favorites_menu_button.custom_minimum_size = Vector2(110, 0)
	path_row.add_child(_favorites_menu_button)

	var popup = _favorites_menu_button.get_popup()
	if !popup.id_pressed.is_connected(_on_favorite_menu_id_pressed):
		popup.id_pressed.connect(_on_favorite_menu_id_pressed)

	_refresh_favorites_menu()


func _build_progress_ui() -> void:
	var root_vbox = _editor_popup.get_node_or_null("MarginContainer/RootVBox")
	if root_vbox == null or _progress_bar != null:
		return

	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 18)
	_progress_bar.min_value = 0
	_progress_bar.max_value = 100
	_progress_bar.value = 0
	_progress_bar.show_percentage = false
	_progress_bar.visible = false
	root_vbox.add_child(_progress_bar)

	var footer_row = root_vbox.get_node_or_null("FooterRow")
	if footer_row != null:
		root_vbox.move_child(_progress_bar, footer_row.get_index())


func _build_art_pack_manager_ui() -> void:
	var upload_tab = _tab_container.get_node_or_null("UploadImage")
	if upload_tab == null or _art_pack_panel != null:
		return

	_art_pack_panel = PanelContainer.new()
	_art_pack_panel.name = "ArtPackManagerPanel"
	upload_tab.add_child(_art_pack_panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_art_pack_panel.add_child(margin)

	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	_art_pack_list_label = Label.new()
	root.add_child(_art_pack_list_label)

	_art_pack_list = ItemList.new()
	_art_pack_list.custom_minimum_size = Vector2(0, 90)
	_art_pack_list.select_mode = ItemList.SELECT_SINGLE
	root.add_child(_art_pack_list)

	var pack_button_row = HBoxContainer.new()
	pack_button_row.add_theme_constant_override("separation", 8)
	root.add_child(pack_button_row)

	var pack_spacer = Control.new()
	pack_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pack_button_row.add_child(pack_spacer)

	_art_pack_remove_button = Button.new()
	pack_button_row.add_child(_art_pack_remove_button)

	_art_pack_apply_all_button = Button.new()
	pack_button_row.add_child(_art_pack_apply_all_button)

	_art_pack_variant_label = Label.new()
	root.add_child(_art_pack_variant_label)

	var variant_row = HBoxContainer.new()
	variant_row.add_theme_constant_override("separation", 8)
	root.add_child(variant_row)

	_art_pack_variant_select = OptionButton.new()
	_art_pack_variant_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	variant_row.add_child(_art_pack_variant_select)

	_art_pack_apply_button = Button.new()
	variant_row.add_child(_art_pack_apply_button)


func _refresh_art_pack_manager_ui() -> void:
	if _art_pack_list == null or _art_pack_variant_select == null or _art_pack_apply_button == null:
		return
	var manager = _manager()
	var is_ko = _locale == "ko"
	_art_pack_list_label.text = "적용된 아트팩 목록" if is_ko else "Imported Art Packs"
	_art_pack_variant_label.text = "현재 카드 아트팩 선택" if is_ko else "Current Card Art Pack"
	_art_pack_remove_button.text = "목록에서 제거" if is_ko else "Remove"
	_art_pack_apply_all_button.text = "선택 팩 전체 적용" if is_ko else "Apply Pack to All"
	_art_pack_apply_button.text = "적용" if is_ko else "Apply"
	var state_parts: Array = []
	state_parts.append(_locale)
	state_parts.append(_get_effective_source_path())
	state_parts.append(JSON.stringify(manager.get_art_pack_list() if manager != null else []))
	state_parts.append(JSON.stringify(manager.get_art_pack_variants_for_source(_get_effective_source_path()) if manager != null and _get_effective_source_path() != "" else []))
	var next_state = "|".join(state_parts)
	if next_state == _art_pack_ui_state:
		return
	_art_pack_ui_state = next_state
	_art_pack_list.clear()
	_art_pack_variant_select.clear()
	_art_pack_list_ids.clear()
	_art_pack_variant_ids.clear()
	if manager == null:
		_art_pack_list.add_item("(none)")
		_art_pack_list.set_item_disabled(0, true)
		_art_pack_remove_button.disabled = true
		_art_pack_apply_all_button.disabled = true
		_art_pack_apply_button.disabled = true
		_art_pack_variant_select.disabled = true
		return

	var packs = manager.get_art_pack_list()
	if packs.is_empty():
		_art_pack_list.add_item("(none)")
		_art_pack_list.set_item_disabled(0, true)
		_art_pack_remove_button.disabled = true
		_art_pack_apply_all_button.disabled = true
	else:
		for pack in packs:
			var pack_name = String(pack.get("name", "Art Pack"))
			var count = int(pack.get("count", 0))
			_art_pack_list.add_item("%s (%d)" % [pack_name, count])
			_art_pack_list_ids.append(String(pack.get("id", "")))
		if _art_pack_list.item_count > 0:
			_art_pack_list.select(0)
		_art_pack_remove_button.disabled = false
		_art_pack_apply_all_button.disabled = false

	var source_path = _get_effective_source_path()
	var variants = manager.get_art_pack_variants_for_source(source_path) if source_path != "" else []
	if variants.is_empty():
		_art_pack_variant_select.add_item("\uC120\uD0DD \uAC00\uB2A5\uD55C \uC544\uD2B8\uD329 \uC5C6\uC74C" if is_ko else "No art pack variants")
		_art_pack_variant_select.disabled = true
		_art_pack_apply_button.disabled = true
		return

	_art_pack_variant_select.disabled = false
	var selected_index = 0
	for index in range(variants.size()):
		var variant = variants[index]
		var label = String(variant.get("pack_name", "Art Pack"))
		if bool(variant.get("active", false)):
			label += " (현재 적용)" if is_ko else " (active)"
			selected_index = index
		_art_pack_variant_select.add_item(label)
		_art_pack_variant_ids.append(String(variant.get("pack_id", "")))
	_art_pack_variant_select.select(selected_index)
	_art_pack_apply_button.disabled = false


func _show_progress(current: int, total: int, label: String = "") -> void:
	if _progress_bar == null:
		return
	var clamped_total = max(total, 1)
	var clamped_current = clamp(current, 0, clamped_total)
	_progress_bar.min_value = 0
	_progress_bar.max_value = clamped_total
	_progress_bar.value = clamped_current
	_progress_bar.visible = true

	var progress_message := label
	if progress_message == "":
		progress_message = "Processing %d / %d..." % [clamped_current, clamped_total]
	elif clamped_current > 0:
		progress_message = "Processing %d / %d: %s" % [clamped_current, clamped_total, label]
	_set_status(progress_message, false)


func _hide_progress() -> void:
	if _progress_bar == null:
		return
	_progress_bar.visible = false
	_progress_bar.value = 0


func _on_import_progress(current: int, total: int, label: String = "") -> void:
	_show_progress(current, total, label)


func _process(delta: float) -> void:
	if !_editor_popup.visible:
		_refresh_accumulator = 0.0
		return
	_refresh_accumulator += delta
	if _refresh_accumulator < 0.35:
		return
	_refresh_accumulator = 0.0
	_update_context(false)


func _on_edit_art_pressed() -> void:
	_initialize_editor_ui_once()
	if _editor_popup.visible:
		_close_adjust_panel()
		_close_file_browser()
		_editor_popup.hide()
		return
	var manager = _manager()
	_api_key_input.text = manager.get_session_api_key() if manager != null else ""
	_open_editor_popup()
	call_deferred("_refresh_editor_context_after_open")


func _on_close_pressed() -> void:
	_close_adjust_panel()
	if _gif_settings_popup != null:
		_gif_settings_popup.hide()
	_close_file_browser()
	_editor_popup.hide()


func _on_gif_settings_pressed() -> void:
	if _gif_settings_popup == null:
		return
	_refresh_gif_settings_ui()
	var popup_rect = _editor_popup.get_global_rect()
	_gif_settings_popup.position = Vector2(
		popup_rect.position.x + popup_rect.size.x - _gif_settings_popup.size.x - 16.0,
		popup_rect.position.y + 54.0
	)
	_gif_settings_popup.show()
	_gif_settings_popup.move_to_front()


func _on_gif_settings_close_pressed() -> void:
	if _gif_settings_popup != null:
		_gif_settings_popup.hide()
	await _reapply_gif_settings_globally()


func _on_gif_settings_changed(_value = null) -> void:
	if _gif_cache_check == null or _gif_settings_ui_syncing:
		return
	_gif_processing_settings["use_cache"] = _gif_cache_check.button_pressed
	_gif_processing_settings["skip_duplicate_frames"] = _gif_dedupe_check.button_pressed
	_gif_processing_settings["use_frame_limit"] = _gif_limit_check.button_pressed
	_gif_processing_settings["max_frames"] = int(_gif_limit_spinbox.value)
	_gif_limit_spinbox.editable = _gif_limit_check.button_pressed
	_apply_gif_processing_settings_to_manager()
	_save_ui_settings()


func _apply_gif_preset(preset_id: String) -> void:
	match preset_id:
		"fast":
			_gif_processing_settings["use_cache"] = true
			_gif_processing_settings["skip_duplicate_frames"] = true
			_gif_processing_settings["use_frame_limit"] = true
			_gif_processing_settings["max_frames"] = 12
		"balanced":
			_gif_processing_settings["use_cache"] = true
			_gif_processing_settings["skip_duplicate_frames"] = true
			_gif_processing_settings["use_frame_limit"] = true
			_gif_processing_settings["max_frames"] = 36
		"quality":
			_gif_processing_settings["use_cache"] = true
			_gif_processing_settings["skip_duplicate_frames"] = false
			_gif_processing_settings["use_frame_limit"] = false
			_gif_processing_settings["max_frames"] = 60
		_:
			return
	_apply_gif_processing_settings_to_manager()
	_save_ui_settings()
	_refresh_gif_settings_ui()


func _on_gif_preset_fast_pressed() -> void:
	_apply_gif_preset("fast")


func _on_gif_preset_balanced_pressed() -> void:
	_apply_gif_preset("balanced")


func _on_gif_preset_quality_pressed() -> void:
	_apply_gif_preset("quality")


func _reapply_gif_settings_globally() -> void:
	var manager = _manager()
	if manager == null or !manager.has_method("rebuild_all_gif_overrides_with_current_settings"):
		return
	_set_busy(true, "GIF 설정 전체 적용 중..." if _locale == "ko" else "Applying GIF settings to all GIF cards...")
	_show_progress(0, 1, "GIF 설정 적용 준비 중..." if _locale == "ko" else "Preparing GIF settings update...")
	var progress_callback := Callable(self, "_on_import_progress")
	var result = await manager.rebuild_all_gif_overrides_with_current_settings(progress_callback)
	_hide_progress()
	if bool(result.get("ok", false)):
		manager.refresh_all_portraits()
	_update_context(true)
	_set_busy(false, String(result.get("message", "Unknown GIF result.")), !bool(result.get("ok", false)))


func _on_restore_pressed() -> void:
	var manager = _manager()
	if manager == null:
		_set_status("The card art manager is not available.", true)
		return
	var source_path = _get_effective_source_path()
	if source_path == "":
		_set_status("No card art is selected.", true)
		return
	_current_source_path = source_path
	var result = manager.remove_override(source_path)
	_set_status(String(result.get("message", "Unknown restore result.")), !bool(result.get("ok", false)))
	if bool(result.get("ok", false)):
		_refresh_inspect_card_after_restore()
	_update_context(true)


func _on_restore_all_pressed() -> void:
	var manager = _manager()
	if manager == null:
		_set_status("The card art manager is not available.", true)
		return
	var result = manager.remove_all_overrides()
	_set_status(String(result.get("message", "Unknown restore-all result.")), !bool(result.get("ok", false)))
	if bool(result.get("ok", false)):
		_refresh_inspect_card_after_restore()
	_update_context(true)


func _refresh_inspect_card_after_restore() -> void:
	var inspect_card = _get_inspect_card()
	if inspect_card != null and inspect_card.has_method("Reload"):
		inspect_card.call_deferred("Reload")
	var screen = get_parent()
	if screen != null and screen.has_method("UpdateCardDisplay"):
		screen.call_deferred("UpdateCardDisplay")


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


func _on_import_mod_pressed() -> void:
	var manager = _manager()
	if manager == null:
		_set_status("The card art manager is not available.", true)
		return
	_set_status("Choose a mod PCK or manifest JSON file to import card images.", false)
	_open_file_browser(FILE_DIALOG_MODE_IMPORT_MOD)


func _on_export_override_pressed() -> void:
	var manager = _manager()
	if manager == null:
		_set_status("The card art manager is not available.", true)
		return
	if manager.get_override_count() == 0:
		_set_status("Apply at least one custom image first, then export the pack.", true)
		return
	_set_status("Choose where to save a bundle with all current custom card images.", false)
	_configure_export_dialog(EXPORT_DIALOG_MODE_PACK)
	_export_file_dialog.current_file = "card_art_bundle.cardartpack.json"
	var export_dir = _get_saved_export_dir(EXPORT_DIALOG_MODE_PACK)
	if export_dir != "":
		_export_file_dialog.current_dir = export_dir
	_export_file_dialog.popup_centered_ratio(0.8)


func _on_export_current_png_pressed() -> void:
	var manager = _manager()
	if manager == null:
		_set_status("The card art manager is not available.", true)
		return
	if _current_source_path == "":
		_set_status("No card art is selected.", true)
		return
	_set_status("Choose where to save the current card image as a PNG.", false)
	_configure_export_dialog(EXPORT_DIALOG_MODE_CURRENT_PNG)
	_export_file_dialog.current_file = "%s.png" % _current_source_path.get_file().get_basename()
	var export_dir = _get_saved_export_dir(EXPORT_DIALOG_MODE_CURRENT_PNG)
	if export_dir != "":
		_export_file_dialog.current_dir = export_dir
	_export_file_dialog.popup_centered_ratio(0.8)


func _apply_import_path(path: String) -> void:
	var manager = _manager()
	if manager == null:
		_set_status("The card art manager is not available.", true)
		return
	_selected_upload_path = path
	_selected_file_label.text = path.get_file()
	var is_import_pack = _file_dialog_mode == FILE_DIALOG_MODE_IMPORT_PACK
	var is_import_mod = _file_dialog_mode == FILE_DIALOG_MODE_IMPORT_MOD
	var result = {}
	if is_import_pack or is_import_mod:
		_set_busy(true, "Preparing import...")
		_show_progress(0, 1, "Preparing import...")
		var progress_callback := Callable(self, "_on_import_progress")
		result = await (manager.import_bundle_from_file(path, progress_callback) if is_import_pack else manager.import_mod_images_from_path(path, progress_callback))
		_hide_progress()
		_set_busy(false, String(result.get("message", "Unknown upload result.")), !bool(result.get("ok", false)))
	else:
		result = manager.save_override_from_file(_current_source_path, path)
	if bool(result.get("ok", false)):
		if is_import_pack or is_import_mod:
			manager.refresh_all_portraits()
		else:
			var portrait = _get_active_portrait()
			if portrait != null:
				manager.apply_override_to_texture_rect(portrait)
	if !(is_import_pack or is_import_mod):
		_set_status("%s\nFile: %s" % [String(result.get("message", "Unknown upload result.")), path.get_file()], !bool(result.get("ok", false)))
	else:
		_set_status("%s\nFile: %s" % [String(result.get("message", "Unknown upload result.")), path.get_file()], !bool(result.get("ok", false)))
	_update_context(true)


func _on_export_file_selected(path: String) -> void:
	_reopen_editor_popup()
	var manager = _manager()
	if manager == null:
		_set_status("The card art manager is not available.", true)
		return
	_save_export_dir(_export_dialog_mode, path.get_base_dir())
	var result = manager.export_bundle_to_file(path)
	if _export_dialog_mode == EXPORT_DIALOG_MODE_CURRENT_PNG:
		result = manager.export_source_image_to_png(_current_source_path, path)
	_set_status("%s\nFile: %s" % [String(result.get("message", "Unknown export result.")), path.get_file()], !bool(result.get("ok", false)))


func _configure_export_dialog(mode: String) -> void:
	_export_dialog_mode = mode
	if _export_file_dialog == null:
		return
	if mode == EXPORT_DIALOG_MODE_CURRENT_PNG:
		_export_file_dialog.title = _tr("export_current_png")
		_export_file_dialog.filters = PackedStringArray([
			"*.png ; PNG image"
		])
		return
	_export_file_dialog.title = _tr("export_pack")
	_export_file_dialog.filters = PackedStringArray([
		"*.cardartpack.json ; Card art bundle"
	])


func _on_export_dialog_canceled() -> void:
	_reopen_editor_popup()


func _on_adjust_pressed() -> void:
	var manager = _manager()
	if manager == null:
		_set_status("The card art manager is not available.", true)
		return
	var source_path = _get_effective_source_path()
	if source_path == "":
		_set_status("No card art is selected.", true)
		return
	if !manager.can_adjust_override(source_path):
		_set_status("The current custom image cannot be adjusted right now.", true)
		return

	_current_source_path = source_path
	_adjust_source_path = source_path
	_adjust_source_image = manager.get_adjustable_override_image(source_path)
	if _adjust_source_image == null:
		_adjust_source_path = ""
		_set_status("The current custom image could not be prepared for adjustment.", true)
		return

	var adjustment_state = manager.get_override_adjustment_state(source_path)
	_adjust_zoom_slider.value = float(adjustment_state.get("zoom", 1.0)) * 100.0
	_adjust_x_slider.value = float(adjustment_state.get("offset_x", 0.0)) * 100.0
	_adjust_y_slider.value = float(adjustment_state.get("offset_y", 0.0)) * 100.0
	_adjust_drag_active = false
	_apply_adjust_preview_frame_style()
	_adjust_panel.show()
	_adjust_panel.move_to_front()
	_update_adjust_preview()


func _on_display_mode_pressed() -> void:
	var manager = _manager()
	if manager == null:
		_set_status("The card art manager is not available.", true)
		return
	var source_path = _get_effective_source_path()
	if source_path == "":
		_set_status("No card art is selected.", true)
		return
	_current_source_path = source_path
	var result = manager.toggle_display_mode(source_path)
	_set_status(String(result.get("message", "Unknown display mode result.")), !bool(result.get("ok", false)))
	_update_context(true)


func _on_adjust_controls_changed(_value: float) -> void:
	if _adjust_panel == null or !_adjust_panel.visible:
		return
	_update_adjust_preview()


func _on_adjust_apply_pressed() -> void:
	var manager = _manager()
	if manager == null:
		_set_status("The card art manager is not available.", true)
		return
	var source_path = _adjust_source_path if _adjust_source_path != "" else _get_effective_source_path()
	var result = manager.save_adjusted_override(
		source_path,
		_adjust_zoom_slider.value / 100.0,
		_adjust_x_slider.value / 100.0,
		_adjust_y_slider.value / 100.0
	)
	_close_adjust_panel()
	_set_status(String(result.get("message", "Unknown adjust result.")), !bool(result.get("ok", false)))
	_update_context(true)


func _on_adjust_cancel_pressed() -> void:
	_close_adjust_panel()


func _on_adjust_reset_pressed() -> void:
	_adjust_zoom_slider.value = 100.0
	_adjust_x_slider.value = 0.0
	_adjust_y_slider.value = 0.0
	_update_adjust_preview()


func _on_art_pack_apply_pressed() -> void:
	var manager = _manager()
	if manager == null:
		_set_status("The card art manager is not available.", true)
		return
	var source_path = _get_effective_source_path()
	if source_path == "":
		_set_status("No card art is selected.", true)
		return
	var selected_index = _art_pack_variant_select.selected
	if selected_index < 0 or selected_index >= _art_pack_variant_ids.size():
		_set_status("No art pack version is selected.", true)
		return
	var pack_id = String(_art_pack_variant_ids[selected_index])
	if pack_id == "":
		_set_status("No art pack version is selected.", true)
		return
	var result = manager.apply_art_pack_variant(source_path, pack_id)
	_set_status(String(result.get("message", "Unknown art pack result.")), !bool(result.get("ok", false)))
	_update_context(true)


func _on_art_pack_apply_all_pressed() -> void:
	var manager = _manager()
	if manager == null:
		_set_status("The card art manager is not available.", true)
		return
	var selected_items = _art_pack_list.get_selected_items()
	if selected_items.is_empty():
		_set_status("적용할 아트팩을 먼저 선택하세요." if _locale == "ko" else "Select an art pack first.", true)
		return
	var selected_index = int(selected_items[0])
	if selected_index < 0 or selected_index >= _art_pack_list_ids.size():
		_set_status("적용할 아트팩을 먼저 선택하세요." if _locale == "ko" else "Select an art pack first.", true)
		return
	var pack_id = String(_art_pack_list_ids[selected_index])
	if pack_id == "":
		_set_status("적용할 아트팩을 먼저 선택하세요." if _locale == "ko" else "Select an art pack first.", true)
		return
	_set_busy(true, "아트팩 전체 적용 중..." if _locale == "ko" else "Applying art pack to all cards...")
	_show_progress(0, 1, "아트팩 전체 적용 준비 중..." if _locale == "ko" else "Preparing art pack application...")
	var progress_callback := Callable(self, "_on_import_progress")
	var result = await manager.apply_art_pack_to_all(pack_id, progress_callback)
	_hide_progress()
	_set_busy(false, String(result.get("message", "Unknown art pack result.")), !bool(result.get("ok", false)))
	_update_context(true)


func _on_art_pack_remove_pressed() -> void:
	var manager = _manager()
	if manager == null:
		_set_status("The card art manager is not available.", true)
		return
	var selected_items = _art_pack_list.get_selected_items()
	if selected_items.is_empty():
		_set_status("제거할 아트팩을 먼저 선택하세요." if _locale == "ko" else "Select an art pack to remove first.", true)
		return
	var selected_index = int(selected_items[0])
	if selected_index < 0 or selected_index >= _art_pack_list_ids.size():
		_set_status("제거할 아트팩을 먼저 선택하세요." if _locale == "ko" else "Select an art pack to remove first.", true)
		return
	var pack_id = String(_art_pack_list_ids[selected_index])
	if pack_id == "":
		_set_status("제거할 아트팩을 먼저 선택하세요." if _locale == "ko" else "Select an art pack to remove first.", true)
		return
	var result = manager.remove_art_pack(pack_id)
	_set_status(String(result.get("message", "Unknown art pack result.")), !bool(result.get("ok", false)))
	_art_pack_ui_state = ""
	_update_context(true)


func _on_infection_effect_pressed() -> void:
	var manager = _manager()
	if manager == null:
		_set_status("The card art manager is not available.", true)
		return
	var next_hidden_enabled = !bool(manager.is_infection_effect_hidden_enabled())
	manager.set_infection_effect_hidden_enabled(next_hidden_enabled)
	_infection_effect_hidden_enabled = next_hidden_enabled
	_save_ui_settings()
	var inspect_card = _get_inspect_card()
	if inspect_card != null and inspect_card.has_method("Reload"):
		inspect_card.call_deferred("Reload")
	var screen = get_parent()
	if screen != null and screen.has_method("UpdateCardDisplay"):
		screen.call_deferred("UpdateCardDisplay")
	_refresh_infection_effect_button()
	if _locale == "ko":
		_set_status("감염 테두리 이펙트를 숨겼습니다." if next_hidden_enabled else "감염 테두리 이펙트를 다시 표시합니다.", false)
	else:
		_set_status("Infection border effect hidden." if next_hidden_enabled else "Infection border effect shown.", false)


func _on_ancient_text_outside_pressed() -> void:
	var manager = _manager()
	if manager == null:
		_set_status("The card art manager is not available.", true)
		return
	var source_path = _get_effective_source_path()
	if source_path == "" or !_is_current_ancient_text_outside_supported_card():
		_set_status("고대 카드 또는 풀아트 카드에서만 사용할 수 있습니다." if _locale == "ko" else "This option is only available for Ancient or full-art cards.", true)
		return
	var next_enabled = !bool(manager.is_ancient_text_outside_enabled(source_path))
	manager.set_ancient_text_outside_enabled(source_path, next_enabled)
	if manager.has_method("get_ancient_text_outside_settings"):
		_ancient_text_outside_by_source = manager.get_ancient_text_outside_settings()
	_save_ui_settings()
	var inspect_card = _get_inspect_card()
	if inspect_card != null and inspect_card.has_method("Reload"):
		inspect_card.call_deferred("Reload")
	var screen = get_parent()
	if screen != null and screen.has_method("UpdateCardDisplay"):
		screen.call_deferred("UpdateCardDisplay")
	_refresh_ancient_text_outside_button()
	_refresh_ancient_text_panel()
	if _locale == "ko":
		_set_status("고대 카드 텍스트를 카드 밖으로 이동했습니다." if next_enabled else "고대 카드 텍스트를 카드 안으로 되돌렸습니다.", false)
	else:
		_set_status("Ancient card text moved outside the card." if next_enabled else "Ancient card text restored inside the card.", false)


func _on_adjust_preview_gui_input(event: InputEvent) -> void:
	if _adjust_panel == null or !_adjust_panel.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_adjust_drag_active = event.pressed
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_adjust_zoom_slider.value = clamp(_adjust_zoom_slider.value + 5.0, _adjust_zoom_slider.min_value, _adjust_zoom_slider.max_value)
			_update_adjust_preview()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_adjust_zoom_slider.value = clamp(_adjust_zoom_slider.value - 5.0, _adjust_zoom_slider.min_value, _adjust_zoom_slider.max_value)
			_update_adjust_preview()
			return
	if event is InputEventMouseMotion and _adjust_drag_active:
		var preview_size = _adjust_preview.size
		if preview_size.x <= 1.0 or preview_size.y <= 1.0:
			return
		var motion = event as InputEventMouseMotion
		var delta_x = -(motion.relative.x / preview_size.x) * 200.0
		var delta_y = -(motion.relative.y / preview_size.y) * 200.0
		_adjust_x_slider.value = clamp(_adjust_x_slider.value + delta_x, _adjust_x_slider.min_value, _adjust_x_slider.max_value)
		_adjust_y_slider.value = clamp(_adjust_y_slider.value + delta_y, _adjust_y_slider.min_value, _adjust_y_slider.max_value)
		_update_adjust_preview()


func _close_adjust_panel() -> void:
	if _adjust_panel != null:
		_adjust_panel.hide()
	if _adjust_preview != null:
		_adjust_preview.texture = null
	if _adjust_preview_label != null:
		_adjust_preview_label.text = "Drag the preview to reposition it. Use zoom to crop tighter."
	_adjust_drag_active = false
	_adjust_source_image = null
	_adjust_source_path = ""


func _apply_adjust_preview_frame_style() -> void:
	if _adjust_preview_frame == null:
		return
	var manager = _manager()
	var preview_source_path = _adjust_source_path if _adjust_source_path != "" else _current_source_path
	var is_full_art = manager != null and preview_source_path != "" and manager.is_full_art_mode(preview_source_path)
	if _adjust_preview != null:
		var preview_size = Vector2(300, 424) if is_full_art else Vector2(520, 260)
		_adjust_preview_frame.custom_minimum_size = preview_size
		_adjust_preview.custom_minimum_size = preview_size
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.07, 0.09, 0.92)
	style.border_color = Color(0.92, 0.92, 0.96, 0.95)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 28 if is_full_art else 8
	style.corner_radius_top_right = 28 if is_full_art else 8
	style.corner_radius_bottom_right = 28 if is_full_art else 8
	style.corner_radius_bottom_left = 28 if is_full_art else 8
	style.expand_margin_left = 4
	style.expand_margin_top = 4
	style.expand_margin_right = 4
	style.expand_margin_bottom = 4
	_adjust_preview_frame.add_theme_stylebox_override("panel", style)


func _update_adjust_preview() -> void:
	var manager = _manager()
	var preview_source_path = _adjust_source_path if _adjust_source_path != "" else _current_source_path
	if manager == null or _adjust_source_image == null or preview_source_path == "":
		return
	_apply_adjust_preview_frame_style()
	var preview_image = manager.build_adjusted_preview(
		preview_source_path,
		_adjust_source_image,
		_adjust_zoom_slider.value / 100.0,
		_adjust_x_slider.value / 100.0,
		_adjust_y_slider.value / 100.0
	)
	if preview_image == null:
		_adjust_preview.texture = null
		_adjust_preview_label.text = "미리보기를 만들지 못했습니다."
		return
	_adjust_preview.texture = ImageTexture.create_from_image(preview_image)
	_adjust_preview_label.text = "Drag preview to reposition.\nZoom %d%% / X %d / Y %d" % [
		int(_adjust_zoom_slider.value),
		int(_adjust_x_slider.value),
		int(_adjust_y_slider.value)
	]


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
		_display_mode_button.disabled = true
		return

	var next_source_path = _get_context_source_path_fast()
	if next_source_path == "":
		var portrait = _get_active_portrait()
		if portrait != null:
			next_source_path = manager.get_source_path_for_texture_rect(portrait)

	if force_refresh or next_source_path != _current_source_path:
		var source_changed = next_source_path != _current_source_path
		_current_source_path = next_source_path
		_current_target_size = manager.get_target_size_for_source_path(_current_source_path) if _current_source_path != "" else Vector2i.ZERO
		if source_changed:
			if _adjust_panel == null or !_adjust_panel.visible:
				_close_adjust_panel()
			_selected_upload_path = ""
			_selected_file_label.text = _tr("no_image_selected")
		_refresh_card_label()

	var effective_source_path = _get_effective_source_path()
	_edit_art_button.disabled = effective_source_path == ""
	_restore_button.disabled = effective_source_path == "" or !manager.has_override(effective_source_path)
	_adjust_button.disabled = effective_source_path == "" or !manager.can_adjust_override(effective_source_path)
	_display_mode_button.disabled = effective_source_path == "" or !manager.has_override(effective_source_path) or !manager.can_toggle_full_art(effective_source_path)
	_display_mode_button.text = _get_display_mode_button_text()
	_export_pack_button.disabled = manager.get_override_count() == 0
	_export_current_png_button.disabled = effective_source_path == ""
	_import_pack_button.disabled = false
	_import_mod_button.disabled = false
	_restore_all_button.disabled = manager.get_override_count() == 0
	_refresh_art_pack_manager_ui()
	_refresh_infection_effect_button()
	_refresh_ancient_text_outside_button()
	_refresh_ancient_text_panel()


func _refresh_editor_context_after_open() -> void:
	_update_context(true)
	if _get_effective_source_path() == "":
		_set_status("Open a card inspection view first.", true)


func _refresh_card_label() -> void:
	if _current_source_path == "":
		_current_card_label.text = _tr("current_card_unavailable")
		return

	var file_name = _current_source_path.get_file().get_basename()
	_current_card_label.text = _tr("current_card_format") % [
		file_name,
		_current_target_size.x,
		_current_target_size.y
	]


func _get_active_portrait():
	var screen = get_parent()
	if screen == null:
		return null

	var inspect_card = screen.get_node_or_null("Card")
	if inspect_card != null:
		var portrait = inspect_card.get_node_or_null("CardContainer/PortraitCanvasGroup/Portrait")
		var ancient_portrait = inspect_card.get_node_or_null("CardContainer/PortraitCanvasGroup/AncientPortrait")
		var manager = _manager()
		if ancient_portrait is TextureRect and manager != null and manager.get_source_path_for_texture_rect(ancient_portrait) != "":
			return ancient_portrait
		if portrait is TextureRect and manager != null and manager.get_source_path_for_texture_rect(portrait) != "":
			return portrait
		if ancient_portrait is TextureRect and ancient_portrait.visible:
			return ancient_portrait
		if portrait is TextureRect and portrait.visible:
			return portrait
		if portrait is TextureRect:
			return portrait
		if ancient_portrait is TextureRect:
			return ancient_portrait

	var card_roots: Array = []
	_collect_card_roots(screen, card_roots)
	if card_roots.is_empty():
		return null

	var manager = _manager()
	var best_root = null
	var best_root_score = INF
	for card_root in card_roots:
		var root_control = card_root as Control
		if root_control == null:
			continue
		var portrait = card_root.get_node_or_null("PortraitCanvasGroup/Portrait")
		var ancient_portrait = card_root.get_node_or_null("PortraitCanvasGroup/AncientPortrait")
		var has_source = false
		if manager != null:
			if portrait is TextureRect:
				has_source = manager.get_source_path_for_texture_rect(portrait) != ""
			if !has_source and ancient_portrait is TextureRect:
				has_source = manager.get_source_path_for_texture_rect(ancient_portrait) != ""
		var is_visible = _is_control_visible_in_tree(root_control)
		if !is_visible and !has_source:
			continue
		var root_score = _get_card_root_score(root_control)
		if root_score < best_root_score:
			best_root = card_root
			best_root_score = root_score

	if best_root == null:
		return null

	var best_ancient = best_root.get_node_or_null("PortraitCanvasGroup/AncientPortrait")
	if best_ancient is TextureRect and manager != null and manager.get_source_path_for_texture_rect(best_ancient) != "":
		return best_ancient
	var best_portrait = best_root.get_node_or_null("PortraitCanvasGroup/Portrait")
	if best_portrait is TextureRect and manager != null and manager.get_source_path_for_texture_rect(best_portrait) != "":
		return best_portrait
	if best_ancient is TextureRect and best_ancient.visible:
		return best_ancient
	if best_portrait is TextureRect and best_portrait.visible:
		return best_portrait
	if best_portrait is TextureRect:
		return best_portrait
	if best_ancient is TextureRect:
		return best_ancient
	return null


func _get_card_root_score(control: Control) -> float:
	var candidate_rect = control.get_global_rect()
	var candidate_center = candidate_rect.position + (candidate_rect.size * 0.5)
	var anchor_rect = _edit_art_button.get_global_rect()
	var anchor_center = anchor_rect.position + (anchor_rect.size * 0.5)
	var center_distance = candidate_center.distance_to(anchor_center)
	var area = max(candidate_rect.size.x * candidate_rect.size.y, 1.0)
	return center_distance - min(area / 100000.0, 50.0)


func _collect_card_roots(node, candidates: Array) -> void:
	for child in node.get_children():
		if child is Control and String(child.name) == "CardContainer":
			candidates.append(child)
		_collect_card_roots(child, candidates)


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
	_configure_export_dialog(EXPORT_DIALOG_MODE_PACK)
	_editor_popup.top_level = true
	_editor_popup.z_as_relative = false
	_editor_popup.z_index = 1000
	_file_browser_panel.top_level = true
	_file_browser_panel.z_as_relative = false
	_file_browser_panel.z_index = 1100


func _bind_signals() -> void:
	_language_button.pressed.connect(_toggle_locale)
	_gif_settings_button.pressed.connect(_on_gif_settings_pressed)
	_close_button.pressed.connect(_on_close_pressed)
	_restore_button.pressed.connect(_on_restore_pressed)
	_restore_all_button.pressed.connect(_on_restore_all_pressed)
	_adjust_button.pressed.connect(_on_adjust_pressed)
	_display_mode_button.pressed.connect(_on_display_mode_pressed)
	_infection_effect_button.pressed.connect(_on_infection_effect_pressed)
	_ancient_text_outside_button.pressed.connect(_on_ancient_text_outside_pressed)
	_choose_image_button.pressed.connect(_on_choose_image_pressed)
	_import_pack_button.pressed.connect(_on_import_shared_pressed)
	_import_mod_button.pressed.connect(_on_import_mod_pressed)
	_export_pack_button.pressed.connect(_on_export_override_pressed)
	_export_current_png_button.pressed.connect(_on_export_current_png_pressed)
	_generate_button.pressed.connect(_on_generate_pressed)
	_export_file_dialog.file_selected.connect(_on_export_file_selected)
	_export_file_dialog.canceled.connect(_on_export_dialog_canceled)
	_browser_pick_folder_button.pressed.connect(_on_browser_pick_folder_pressed)
	_browser_up_button.pressed.connect(_on_browser_up_pressed)
	_browser_refresh_button.pressed.connect(_on_browser_refresh_pressed)
	_browser_open_button.pressed.connect(_on_browser_open_pressed)
	_browser_cancel_button.pressed.connect(_on_browser_cancel_pressed)
	_favorite_add_button.pressed.connect(_on_favorite_add_pressed)
	_browser_path_input.text_submitted.connect(_on_browser_path_submitted)
	_browser_item_list.item_selected.connect(_on_browser_item_selected)
	_browser_item_list.item_activated.connect(_on_browser_item_activated)
	_adjust_zoom_slider.value_changed.connect(_on_adjust_controls_changed)
	_adjust_x_slider.value_changed.connect(_on_adjust_controls_changed)
	_adjust_y_slider.value_changed.connect(_on_adjust_controls_changed)
	_adjust_preview.gui_input.connect(_on_adjust_preview_gui_input)
	_adjust_apply_button.pressed.connect(_on_adjust_apply_pressed)
	_adjust_reset_button.pressed.connect(_on_adjust_reset_pressed)
	_adjust_cancel_button.pressed.connect(_on_adjust_cancel_pressed)
	_gif_cache_check.toggled.connect(_on_gif_settings_changed)
	_gif_dedupe_check.toggled.connect(_on_gif_settings_changed)
	_gif_limit_check.toggled.connect(_on_gif_settings_changed)
	_gif_limit_spinbox.value_changed.connect(_on_gif_settings_changed)
	_gif_preset_fast_button.pressed.connect(_on_gif_preset_fast_pressed)
	_gif_preset_balanced_button.pressed.connect(_on_gif_preset_balanced_pressed)
	_gif_preset_quality_button.pressed.connect(_on_gif_preset_quality_pressed)
	_gif_settings_close_button.pressed.connect(_on_gif_settings_close_pressed)
	_art_pack_remove_button.pressed.connect(_on_art_pack_remove_pressed)
	_art_pack_apply_all_button.pressed.connect(_on_art_pack_apply_all_pressed)
	_art_pack_apply_button.pressed.connect(_on_art_pack_apply_pressed)


func _set_busy(is_busy: bool, message: String, is_error: bool = false) -> void:
	var manager = _manager()
	var effective_source_path = _get_effective_source_path()
	_generate_button.disabled = is_busy
	_choose_image_button.disabled = is_busy
	_import_pack_button.disabled = is_busy
	_import_mod_button.disabled = is_busy
	_export_pack_button.disabled = is_busy or manager == null or manager.get_override_count() == 0
	_export_current_png_button.disabled = is_busy or effective_source_path == ""
	_restore_button.disabled = is_busy or effective_source_path == "" or manager == null or !manager.has_override(effective_source_path)
	_adjust_button.disabled = is_busy or effective_source_path == "" or manager == null or !manager.can_adjust_override(effective_source_path)
	_display_mode_button.disabled = is_busy or effective_source_path == "" or manager == null or !manager.has_override(effective_source_path) or !manager.can_toggle_full_art(effective_source_path)
	if _infection_effect_button != null:
		_infection_effect_button.disabled = is_busy or !_is_current_infection_card()
	if _ancient_text_outside_button != null:
		_ancient_text_outside_button.disabled = is_busy or !_is_current_ancient_text_outside_supported_card() or effective_source_path == ""
	if _art_pack_remove_button != null:
		_art_pack_remove_button.disabled = is_busy or _art_pack_list_ids.is_empty()
	_restore_all_button.disabled = is_busy or manager == null or manager.get_override_count() == 0
	_close_button.disabled = is_busy
	_edit_art_button.disabled = is_busy or effective_source_path == ""
	_set_status(message, is_error)


func _set_status(message: String, is_error: bool) -> void:
	_status_label.text = message
	_status_label.modulate = Color(1.0, 0.4, 0.4, 1.0) if is_error else Color(0.85, 0.95, 1.0, 1.0)


func _reopen_editor_popup() -> void:
	if _editor_popup.visible:
		return
	call_deferred("_open_editor_popup")


func _normalize_existing_dir(path: String) -> String:
	if path.strip_edges() == "":
		return ""
	var normalized = path
	if !normalized.is_absolute_path():
		normalized = ProjectSettings.globalize_path(normalized)
	normalized = normalized.replace("/", "\\")
	if !(normalized.length() == 3 and normalized[1] == ":" and normalized.ends_with("\\")):
		normalized = normalized.trim_suffix("\\")
	return normalized if DirAccess.dir_exists_absolute(normalized) else ""


func _get_browser_settings_key(mode: String) -> String:
	match mode:
		FILE_DIALOG_MODE_IMPORT_PACK:
			return "import_pack"
		FILE_DIALOG_MODE_IMPORT_MOD:
			return "import_mod"
		_:
			return "upload"


func _get_export_settings_key(mode: String) -> String:
	return "current_png" if mode == EXPORT_DIALOG_MODE_CURRENT_PNG else "pack"


func _get_saved_browser_dir(mode: String) -> String:
	return _normalize_existing_dir(String(_browser_last_dirs.get(_get_browser_settings_key(mode), "")))


func _save_browser_dir(mode: String, directory_path: String) -> void:
	var normalized = _normalize_existing_dir(directory_path)
	if normalized == "":
		return
	_browser_last_dirs[_get_browser_settings_key(mode)] = normalized
	_save_ui_settings()


func _get_saved_export_dir(mode: String) -> String:
	return _normalize_existing_dir(String(_export_last_dirs.get(_get_export_settings_key(mode), "")))


func _save_export_dir(mode: String, directory_path: String) -> void:
	var normalized = _normalize_existing_dir(directory_path)
	if normalized == "":
		return
	_export_last_dirs[_get_export_settings_key(mode)] = normalized
	_save_ui_settings()


func _refresh_favorites_menu() -> void:
	if _favorites_menu_button == null:
		return
	var popup = _favorites_menu_button.get_popup()
	popup.clear()
	if _favorite_dirs.is_empty():
		popup.add_item("(empty)" if _locale == "en" else "(\uBE44\uC5B4 \uC788\uC74C)", -1)
		popup.set_item_disabled(0, true)
		return
	for index in range(_favorite_dirs.size()):
		popup.add_item(String(_favorite_dirs[index]), index)


func _on_favorite_add_pressed() -> void:
	var normalized = _normalize_existing_dir(_browser_current_dir)
	if normalized == "":
		_set_status("No folder is open in the browser." if _locale == "en" else "현재 브라우저에서 열린 폴더가 없습니다.", true)
		return
	if _favorite_dirs.has(normalized):
		_set_status("This folder is already in favorites." if _locale == "en" else "이미 즐겨찾기에 등록된 폴더입니다.", false)
		return
	_favorite_dirs.append(normalized)
	_refresh_favorites_menu()
	_save_ui_settings()
	_set_status(("Added to favorites: %s" if _locale == "en" else "즐겨찾기에 추가됨: %s") % normalized, false)


func _on_favorite_menu_id_pressed(id: int) -> void:
	if id < 0 or id >= _favorite_dirs.size():
		return
	var favorite_path = _normalize_existing_dir(String(_favorite_dirs[id]))
	if favorite_path == "":
		return
	_refresh_file_browser(favorite_path)


func _open_editor_popup() -> void:
	_editor_popup.show()
	_editor_popup.move_to_front()
	_editor_popup.grab_focus()


func _open_file_browser(mode: String) -> void:
	_file_dialog_mode = mode
	_browser_selected_path = ""
	_browser_selection_is_dir = false
	_browser_open_button.disabled = true
	_browser_preview.texture = null
	_browser_preview_label.text = "미리보기를 표시할 파일을 선택하세요."
	_file_browser_title.text = "이미지 파일 선택" if mode == FILE_DIALOG_MODE_UPLOAD else "아트팩 파일 선택"
	_browser_preview_label.text = _tr("browser_preview_default")
	if mode == FILE_DIALOG_MODE_UPLOAD:
		_file_browser_title.text = _tr("browser_title_upload")
	elif mode == FILE_DIALOG_MODE_IMPORT_PACK:
		_file_browser_title.text = _tr("browser_title_pack")
	else:
		_file_browser_title.text = "Choose Mod PCK or Manifest"
	_file_browser_panel.show()
	_file_browser_panel.move_to_front()
	_refresh_favorites_menu()
	_refresh_file_browser(_resolve_browser_start_dir())


func _close_file_browser() -> void:
	_file_browser_panel.hide()
	_browser_selected_path = ""
	_browser_selection_is_dir = false
	_browser_open_button.disabled = true
	_browser_preview.texture = null
	_browser_preview_label.text = "미리보기를 표시할 파일을 선택하세요."


func _resolve_browser_start_dir() -> String:
	var saved_dir = _get_saved_browser_dir(_file_dialog_mode)
	if saved_dir != "":
		return saved_dir
	if _browser_current_dir != "":
		return _browser_current_dir
	if _selected_upload_path != "":
		var upload_dir = _normalize_existing_dir(_selected_upload_path.get_base_dir())
		if upload_dir != "":
			return upload_dir
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

	_browser_current_dir = _normalize_existing_dir(target_dir)
	_save_browser_dir(_file_dialog_mode, _browser_current_dir)
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
		var item_text = "[?대뜑] %s" % String(entry["name"]) if bool(entry["is_dir"]) else String(entry["name"])
		_browser_item_list.add_item(item_text)
		var item_index = _browser_item_list.item_count - 1
		_browser_item_list.set_item_metadata(item_index, entry)
		if bool(entry["is_dir"]):
			_browser_item_list.set_item_text(item_index, _tr("browser_directory_label") % String(entry["name"]))
		if !bool(entry["is_dir"]):
			var thumbnail = _get_thumbnail_for_browser(String(entry["path"]))
			if thumbnail != null:
				_browser_item_list.set_item_icon(item_index, thumbnail)
	_browser_preview_label.text = _tr("browser_preview_default")


func _is_browser_supported_file(file_name: String) -> bool:
	var lower_name = file_name.to_lower()
	if _file_dialog_mode == FILE_DIALOG_MODE_IMPORT_PACK:
		return lower_name.ends_with(".cardartpack.json")
	if _file_dialog_mode == FILE_DIALOG_MODE_IMPORT_MOD:
		return lower_name.ends_with(".json") or lower_name.ends_with(".pck")
	return IMAGE_EXTENSIONS.has(file_name.get_extension().to_lower())


func _get_thumbnail_for_browser(path: String):
	if _thumbnail_cache.has(path):
		return _thumbnail_cache[path]
	if _file_dialog_mode != FILE_DIALOG_MODE_UPLOAD:
		return null
	var manager = _manager()
	if manager == null:
		return null
	var image = manager.load_first_gif_frame(path) if path.get_extension().to_lower() == "gif" else manager.load_image_from_file(path)
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
	_on_browser_path_submitted(_browser_path_input.text)


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
	_handle_browser_item_selected(index)
	return
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
	var extension = _browser_selected_path.get_extension().to_lower()
	var image = manager.load_first_gif_frame(_browser_selected_path) if extension == "gif" else manager.load_image_from_file(_browser_selected_path)
	if image == null:
		_browser_preview.texture = null
		_browser_preview_label.text = "이미지를 미리보기로 불러올 수 없습니다."
		return
	_browser_preview.texture = ImageTexture.create_from_image(image)
	_browser_preview_label.text = "%s\n%d x %d%s" % [
		_browser_selected_path.get_file(),
		image.get_width(),
		image.get_height(),
		_tr("browser_gif_preview") if extension == "gif" else ""
	]


func _handle_browser_item_selected(index: int) -> void:
	var entry = _browser_item_list.get_item_metadata(index)
	if !(entry is Dictionary):
		return
	_browser_selected_path = String(entry.get("path", ""))
	_browser_selection_is_dir = bool(entry.get("is_dir", false))
	_browser_open_button.disabled = _browser_selected_path == ""
	if _browser_selection_is_dir:
		_browser_preview.texture = null
		_browser_preview_label.text = "Open this folder or select a file inside it.\n%s" % _browser_selected_path
		return
	if _file_dialog_mode == FILE_DIALOG_MODE_IMPORT_PACK:
		_browser_preview.texture = null
		_browser_preview_label.text = "Selected art pack:\n%s" % _browser_selected_path.get_file()
		return
	if _file_dialog_mode == FILE_DIALOG_MODE_IMPORT_MOD:
		_browser_preview.texture = null
		_browser_preview_label.text = "Selected mod file:\n%s" % _browser_selected_path.get_file()
		return
	var manager = _manager()
	if manager == null:
		return
	var extension = _browser_selected_path.get_extension().to_lower()
	var image = manager.load_first_gif_frame(_browser_selected_path) if extension == "gif" else manager.load_image_from_file(_browser_selected_path)
	if image == null:
		_browser_preview.texture = null
		_browser_preview_label.text = "Could not load the image preview."
		return
	_browser_preview.texture = ImageTexture.create_from_image(image)
	_browser_preview_label.text = "%s\n%d x %d%s" % [
		_browser_selected_path.get_file(),
		image.get_width(),
		image.get_height(),
		_tr("browser_gif_preview") if extension == "gif" else ""
	]


func _on_browser_item_activated(index: int) -> void:
	_on_browser_item_selected(index)
	_on_browser_open_pressed()


func _on_browser_open_pressed() -> void:
	if _browser_selected_path == "":
		var selected_items = _browser_item_list.get_selected_items()
		if !selected_items.is_empty():
			var entry = _browser_item_list.get_item_metadata(int(selected_items[0]))
			if entry is Dictionary:
				_browser_selected_path = String(entry.get("path", ""))
				_browser_selection_is_dir = bool(entry.get("is_dir", false))
	if _browser_selected_path == "":
		_set_status("파일 브라우저에서 선택한 경로를 읽지 못했습니다. 항목을 한 번 클릭한 뒤 다시 열기를 눌러 주세요.", true)
		return
	if _browser_selection_is_dir:
		_refresh_file_browser(_browser_selected_path)
		return
	var selected_path := _browser_selected_path
	_close_file_browser()
	_reopen_editor_popup()
	await _apply_import_path(selected_path)


func _on_browser_cancel_pressed() -> void:
	_close_file_browser()
	_reopen_editor_popup()


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


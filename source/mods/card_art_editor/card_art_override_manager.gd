extends Node

const STORAGE_ROOT := "user://card_art_editor"
const STORAGE_IMAGE_DIR := STORAGE_ROOT + "/overrides"
const STORAGE_EDIT_SOURCE_DIR := STORAGE_ROOT + "/edit_sources"
const STORAGE_GIF_TEMP_DIR := STORAGE_ROOT + "/gif_temp"
const STORAGE_GIF_CACHE_DIR := STORAGE_ROOT + "/gif_cache"
const STORAGE_PCK_TEMP_DIR := STORAGE_ROOT + "/pck_temp"
const STORAGE_MANIFEST_PATH := STORAGE_ROOT + "/manifest.json"
const STORAGE_ART_PACK_DIR := STORAGE_ROOT + "/art_packs"
const STORAGE_ART_PACK_REGISTRY_PATH := STORAGE_ROOT + "/art_pack_registry.json"
const STORAGE_UI_SETTINGS_PATH := STORAGE_ROOT + "/ui_settings.json"
const STEAM_WORKSHOP_APP_ID := "2868840"
const WORKSHOP_ART_PACK_SUFFIX := ".cardartpack.json"
const GIF_TOOL_RES_PATH := "res://mods/card_art_editor/extract_gif_frames.ps1"
const GIF_TOOL_USER_PATH := STORAGE_ROOT + "/tools/extract_gif_frames.ps1"
const PICTURES_EXTRACT_SUBDIR := "card_art_editor_extracted"
const BUNDLE_VERSION := 1
const MANAGED_TEXTURE_PREFIX := "res://images/packed/card_portraits/"
const CARD_ATLAS_PREFIX := "res://images/atlases/card_atlas.sprites/"
const MODDED_CARD_ATLAS_SEGMENT := "/images/atlases/card_atlas.sprites/"
const MODDED_CARD_IMAGE_SEGMENTS := ["/images/card_portraits/", "/images/cards/"]
const DEFAULT_LANDSCAPE_SIZE := Vector2i(1000, 760)
const DEFAULT_PORTRAIT_SIZE := Vector2i(606, 852)
const FULL_ART_TARGET_SIZE := Vector2i(600, 847)
const MOD_IMPORT_IMAGE_EXTENSIONS := ["png", "jpg", "jpeg", "webp", "gif"]
const CARD_PORTRAIT_FOLDERS := ["regent", "silent", "ironclad", "seeker", "defect", "colorless", "status", "token", "curse", "event", "necrobinder"]
const MODDED_CARD_PORTRAIT_FOLDERS := ["guardian", "hermit", "champ", "snecko", "automaton", "awakened", "collector", "slimeboss", "gremlins", "hexaghost", "downfall"]
const ART_PACK_CATEGORY_SORT_ORDER := ["ironclad", "silent", "regent", "necrobinder", "defect", "colorless", "curse", "status", "token", "event", "seeker", "guardian", "hermit", "champ", "snecko", "automaton", "awakened", "collector", "slimeboss", "gremlins", "hexaghost", "downfall", "other"]
const REFRESH_INTERVAL := 0.15
const DISPLAY_MODE_DEFAULT := "default"
const DISPLAY_MODE_FULL_ART := "full_art"
const FULL_ART_STATIC_ZOOM_BOOST := 1.12
const FULL_ART_ANIMATED_ZOOM_BOOST := 1.22
const FULL_ART_MASK_MATERIAL = preload("res://scenes/cards/card_canvas_group_mask_material.tres")
const HOVER_TIP_SCENE = preload("res://scenes/ui/hover_tip.tscn")
const PCK_MAGIC := 0x43504447 # GDPC
const PCK_HEADER_VERSION_FIELDS := 4
const PCK_HEADER_RESERVED_FIELDS := 16

const META_SOURCE_PATH := "_card_art_source_path"
const META_SOURCE_SIZE := "_card_art_source_size"
const META_ORIGINAL_TEXTURE := "_card_art_original_texture"
const META_OVERRIDE_ACTIVE := "_card_art_override_active"
const META_FULL_ART_ACTIVE := "_card_art_full_art_active"
const META_FULL_ART_OWNER_PATH := "_card_art_full_art_owner_path"
const META_FULL_ART_OWNER_CARD_ID := "_card_art_full_art_owner_card_id"
const META_INSPECT_SOURCE_PATH := "_card_art_inspect_source_path"
const META_INSPECT_CARD_ID := "_card_art_inspect_card_id"
const META_PORTRAIT_GROUP_ORIGINAL_MATERIAL := "_card_art_portrait_group_original_material"
const META_ANCIENT_TEXT_LAYOUT_DEFAULTS := "_card_art_ancient_text_layout_defaults"
const META_ANCIENT_TEXT_OUTSIDE_APPLIED := "_card_art_ancient_text_outside_applied"
const META_REFRESH_SIGNATURE := "_card_art_refresh_signature"
const META_NAMED_NODE_CACHE := "_card_art_named_node_cache"
const META_ANCIENT_TEXT_HITBOX_CONNECTED := "_card_art_ancient_text_hitbox_connected"
const META_GIF_PLAYBACK_ACTIVE := "_card_art_gif_playback_active"
const META_GIF_PLAYBACK_SOURCE := "_card_art_gif_playback_source"
const META_FULL_ART_FIRE_ORIGINAL_STATE := "_card_art_full_art_fire_original_state"
const META_FULL_ART_LAYER_INSET := "_card_art_full_art_layer_inset"
const META_SKIP_BACKGROUND_REFRESH := "_card_art_skip_background_refresh"
const META_DEFERRED_CARD_REFRESH_PENDING := "_card_art_deferred_card_refresh_pending"
const META_DEFERRED_CARD_REFRESH_INVALIDATE_MODEL := "_card_art_deferred_card_refresh_invalidate_model"
const META_PROVIDER_RELOAD_PENDING := "_card_art_provider_reload_pending"
const FULL_ART_LAYER_NAME := "CardArtFullArtLayer"
const MULTIPLAYER_EXPANDED_STATE_SCRIPT_PATH := "res://src/Core/Nodes/Multiplayer/NMultiplayerPlayerExpandedState.cs"
const STATIC_OVERRIDE_CACHE_SUFFIX := "::static"
const FULL_ART_HIGHLIGHT_COMMON_COLOR := Color(0.72, 0.74, 0.78, 1.0)
const FULL_ART_HIGHLIGHT_UNCOMMON_COLOR := Color(0.10, 0.22, 0.72, 1.0)
const FULL_ART_HIGHLIGHT_RARE_COLOR := Color(1.0, 0.72, 0.16, 1.0)
const FULL_ART_FIRE_SHADER_CODE := "shader_type canvas_item;\nuniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);\nvoid fragment() {\n\tvec4 tex_color = texture(TEXTURE, UV) * COLOR;\n\tfloat brightness = max(max(tex_color.r, tex_color.g), tex_color.b);\n\tCOLOR = vec4(tint_color.rgb * brightness, tex_color.a * tint_color.a);\n}\n"
const FULL_ART_INSET_STATIC := 0
const FULL_ART_INSET_ANIMATED := 0
const STARTUP_RESCAN_FRAMES := 45
const STARTUP_RESCAN_STEP_INTERVAL := 45
const PORTRAIT_REFRESH_FRAME_BUDGET := 12
const PORTRAIT_NAVIGATION_REFRESH_BUDGET := 72
const PORTRAIT_NAVIGATION_REFRESH_FRAMES := 8
const PORTRAIT_EVENT_NAVIGATION_REFRESH_BUDGET := 8
const PORTRAIT_EVENT_NAVIGATION_REFRESH_FRAMES := 1
const PORTRAIT_VISIBLE_REFRESH_INTERVAL := 0.05
const PORTRAIT_VISIBLE_REFRESH_BUDGET := 18
const PORTRAIT_EVENT_FALLBACK_REFRESH_INTERVAL := 0.5
const PORTRAIT_EVENT_FALLBACK_REFRESH_BUDGET := 6
const MODEL_PORTRAIT_PATH_CACHE_LIMIT := 2048
const ANCIENT_TEXT_HOVER_REFRESH_INTERVAL := 0.08
const ANCIENT_TEXT_CLICK_PENDING_FRAMES := 8
const ANCIENT_TEXT_HOVER_HITBOX_INSET := 12.0
const ANCIENT_TEXT_DRAG_SUPPRESS_DISTANCE := 12.0
const ANCIENT_TEXT_HOVER_MOUSE_MOVE_DISTANCE := 2.0
const GIF_PLAYBACK_REFRESH_INTERVAL := 0.08
const GIF_PLAYBACK_MOUSE_MOVE_DISTANCE := 2.0

signal overrides_changed(source_path)
signal art_packs_changed()

var _portrait_refs: Dictionary = {}
var _portrait_ref_ids := []
var _manifest := {}
var _has_animated_overrides_cached := false
var _animated_overrides_cache_dirty := true
var _art_pack_registry := {"packs": {}}
var _override_texture_cache := {}
var _refresh_accumulator := 0.0
var _ancient_text_hover_refresh_accumulator := 0.0
var _gif_playback_refresh_accumulator := 0.0
var _session_api_key := ""
var _overlay_scene := preload("res://mods/card_art_editor/inspect_card_art_editor.tscn")
var _startup_rescan_frames_remaining := STARTUP_RESCAN_FRAMES
var _infection_effect_hidden_enabled := true
var _full_art_rarity_fire_enabled := false
var _full_art_rarity_fire_by_source := {}
var _ancient_text_outside_by_source := {}
var _needs_full_refresh := true
var _portrait_navigation_refresh_frames_remaining := 0
var _startup_rescan_tick := 0
var _portrait_refresh_cursor := 0
var _visible_portrait_refresh_accumulator := 0.0
var _visible_portrait_refresh_cursor := 0
var _event_driven_portrait_refresh_enabled := false
var _gif_processing_settings := {
	"use_cache": true,
	"skip_duplicate_frames": true,
	"use_frame_limit": false,
	"max_frames": 36,
	"play_on_hover_only": false
}
var _gif_hover_playback_by_source := {}
var _batch_update_depth := 0
var _batch_manifest_dirty := false
var _batch_registry_dirty := false
var _batch_refresh_requested := false
var _batch_art_packs_changed := false
var _batched_override_sources := {}
var _managed_source_index_cache: Dictionary = {}
var _model_portrait_path_cache: Dictionary = {}
var _model_portrait_path_cache_keys_by_source: Dictionary = {}
var _stock_reskin_source_alias_cache: Dictionary = {}
var _art_pack_variants_cache: Dictionary = {}
var _ancient_text_hover_tip: Control
var _ancient_text_hover_tip_title
var _ancient_text_hover_tip_description
var _ancient_text_hover_tip_owner: Node = null
var _ancient_text_hover_tip_last_position := Vector2.INF
var _ancient_text_last_hover_mouse_position := Vector2.INF
var _ancient_text_hover_refresh_requested := true
var _ancient_text_hover_tip_locked := false
var _pending_ancient_text_click_frames := 0
var _pending_ancient_text_click_position := Vector2.INF
var _pending_ancient_text_click_card_root: Node = null
var _pending_ancient_text_click_source_path := ""
var _pending_ancient_text_click_from_hitbox := false
var _ancient_text_left_mouse_down := false
var _ancient_text_press_position := Vector2.INF
var _ancient_text_dragging := false
var _pressed_gif_card_root: Node = null
var _pressed_gif_card_source_path := ""
var _gif_playback_refresh_requested := true
var _gif_last_hover_mouse_position := Vector2.INF
var _gif_last_active_card_root: Node = null
var _gif_last_active_source_path := ""
var _hover_tips_container_cache: Node = null
var _full_art_fire_shader = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Let the game's card UI finish assigning portrait textures before we re-apply overrides.
	process_priority = 1000
	set_process_input(true)
	_ensure_storage()
	_load_persistent_preferences()
	_load_manifest()
	_load_art_pack_registry()
	get_tree().node_added.connect(_on_node_added)
	_register_existing(get_tree().root, true)


func _is_ancient_text_hover_tip_visible() -> bool:
	return _ancient_text_hover_tip != null and is_instance_valid(_ancient_text_hover_tip) and _ancient_text_hover_tip.visible


func _should_poll_ancient_text_hover_tip() -> bool:
	if _ancient_text_outside_by_source.is_empty() and !_is_ancient_text_hover_tip_visible():
		_clear_ancient_text_hover_poll_state()
		return false
	if _ancient_text_hover_refresh_requested:
		return true
	if _is_ancient_text_hover_owner_stale():
		return true
	return false


func _request_ancient_text_hover_refresh(reset_mouse_position: bool = false) -> void:
	_ancient_text_hover_refresh_requested = true
	if reset_mouse_position:
		_ancient_text_last_hover_mouse_position = Vector2.INF


func _clear_ancient_text_hover_poll_state() -> void:
	_ancient_text_hover_refresh_accumulator = 0.0
	_ancient_text_hover_refresh_requested = false
	_ancient_text_last_hover_mouse_position = Vector2.INF


func _track_ancient_text_hover_mouse_position(mouse_position: Vector2) -> void:
	if _ancient_text_outside_by_source.is_empty() and !_is_ancient_text_hover_tip_visible():
		_ancient_text_last_hover_mouse_position = Vector2.INF
		return
	if mouse_position == Vector2.INF:
		_request_ancient_text_hover_refresh(true)
		return
	if _ancient_text_last_hover_mouse_position == Vector2.INF:
		_ancient_text_last_hover_mouse_position = mouse_position
		_request_ancient_text_hover_refresh()
		return
	var move_distance_sq = ANCIENT_TEXT_HOVER_MOUSE_MOVE_DISTANCE * ANCIENT_TEXT_HOVER_MOUSE_MOVE_DISTANCE
	if _ancient_text_last_hover_mouse_position.distance_squared_to(mouse_position) < move_distance_sq:
		return
	_ancient_text_last_hover_mouse_position = mouse_position
	_request_ancient_text_hover_refresh()


func _is_ancient_text_hover_owner_stale() -> bool:
	if !_is_ancient_text_hover_tip_visible():
		return false
	if _ancient_text_hover_tip_owner == null or !is_instance_valid(_ancient_text_hover_tip_owner):
		return true
	if !_is_hover_valid_ancient_text_card_root(_ancient_text_hover_tip_owner):
		return true
	if _ancient_text_hover_tip_locked:
		return false
	var viewport = get_viewport()
	if viewport == null:
		return false
	return !_is_mouse_over_card_root(_ancient_text_hover_tip_owner, viewport.get_mouse_position())


func _request_gif_playback_refresh(reset_mouse_position: bool = false) -> void:
	_gif_playback_refresh_requested = true
	if reset_mouse_position:
		_gif_last_hover_mouse_position = Vector2.INF


func _clear_gif_playback_poll_state() -> void:
	_gif_playback_refresh_accumulator = 0.0
	_gif_playback_refresh_requested = false
	_gif_last_hover_mouse_position = Vector2.INF
	_gif_last_active_card_root = null
	_gif_last_active_source_path = ""


func _mark_animated_overrides_cache_dirty() -> void:
	_animated_overrides_cache_dirty = true


func _track_gif_hover_mouse_position(mouse_position: Vector2) -> void:
	if !_has_gif_hover_playback_rules():
		_gif_last_hover_mouse_position = Vector2.INF
		return
	if mouse_position == Vector2.INF:
		_request_gif_playback_refresh(true)
		return
	if _gif_last_hover_mouse_position == Vector2.INF:
		_gif_last_hover_mouse_position = mouse_position
		_request_gif_playback_refresh()
		return
	var move_distance_sq = GIF_PLAYBACK_MOUSE_MOVE_DISTANCE * GIF_PLAYBACK_MOUSE_MOVE_DISTANCE
	if _gif_last_hover_mouse_position.distance_squared_to(mouse_position) < move_distance_sq:
		return
	_gif_last_hover_mouse_position = mouse_position
	_request_gif_playback_refresh()


func _is_last_gif_active_root_stale() -> bool:
	if _gif_last_active_card_root == null:
		return false
	if !is_instance_valid(_gif_last_active_card_root):
		return true
	if _gif_last_active_source_path == "":
		return false
	if _get_gif_override_source_for_card_root(_gif_last_active_card_root) != _gif_last_active_source_path:
		return true
	if _ancient_text_left_mouse_down and _pressed_gif_card_root == _gif_last_active_card_root:
		return false
	if _is_card_root_inside_visible_inspect_screen(_gif_last_active_card_root):
		return false
	var viewport = get_viewport()
	if viewport == null:
		return false
	return !_is_mouse_over_card_root(_gif_last_active_card_root, viewport.get_mouse_position())


func _process(delta: float) -> void:
	if _startup_rescan_frames_remaining > 0:
		_startup_rescan_tick += 1
		if _startup_rescan_tick >= STARTUP_RESCAN_STEP_INTERVAL:
			_startup_rescan_tick = 0
			_register_existing(get_tree().root, true)
			_request_ancient_text_hover_refresh(true)
		_startup_rescan_frames_remaining -= 1
	if _ancient_text_dragging:
		_clear_pending_ancient_text_click()
		_hide_ancient_text_hover_tip()
	else:
		if _pending_ancient_text_click_frames > 0:
			_pending_ancient_text_click_frames -= 1
			if _try_show_pending_ancient_text_click_tip():
				_pending_ancient_text_click_frames = 0
		if _pending_ancient_text_click_frames <= 0 and _should_poll_ancient_text_hover_tip():
			_ancient_text_hover_refresh_accumulator += delta
			if _ancient_text_hover_refresh_accumulator >= ANCIENT_TEXT_HOVER_REFRESH_INTERVAL:
				_ancient_text_hover_refresh_accumulator = 0.0
				_ancient_text_hover_refresh_requested = false
				_refresh_ancient_text_hover_tip()
		elif _pending_ancient_text_click_frames <= 0:
			_ancient_text_hover_refresh_accumulator = 0.0
	if _has_gif_hover_playback_rules() and _has_animated_overrides():
		if _gif_playback_refresh_requested or _is_last_gif_active_root_stale():
			_gif_playback_refresh_accumulator += delta
			if _gif_playback_refresh_accumulator >= GIF_PLAYBACK_REFRESH_INTERVAL:
				_gif_playback_refresh_accumulator = 0.0
				_gif_playback_refresh_requested = false
				_refresh_gif_playback_state()
		else:
			_gif_playback_refresh_accumulator = 0.0
	else:
		_clear_gif_playback_poll_state()
	if _portrait_navigation_refresh_frames_remaining > 0:
		_portrait_navigation_refresh_frames_remaining -= 1
		var navigation_refresh_budget := PORTRAIT_EVENT_NAVIGATION_REFRESH_BUDGET if _event_driven_portrait_refresh_enabled else PORTRAIT_NAVIGATION_REFRESH_BUDGET
		_refresh_visible_tracked_portraits(navigation_refresh_budget)
	elif _should_poll_visible_portrait_refresh():
		_visible_portrait_refresh_accumulator += delta
		var visible_refresh_interval := PORTRAIT_EVENT_FALLBACK_REFRESH_INTERVAL if _event_driven_portrait_refresh_enabled else PORTRAIT_VISIBLE_REFRESH_INTERVAL
		var visible_refresh_budget := PORTRAIT_EVENT_FALLBACK_REFRESH_BUDGET if _event_driven_portrait_refresh_enabled else PORTRAIT_VISIBLE_REFRESH_BUDGET
		if _visible_portrait_refresh_accumulator >= visible_refresh_interval:
			_visible_portrait_refresh_accumulator = 0.0
			_refresh_visible_tracked_portraits(visible_refresh_budget, true)
	else:
		_visible_portrait_refresh_accumulator = 0.0
	if !_needs_full_refresh:
		return
	if REFRESH_INTERVAL <= 0.0:
		_needs_full_refresh = !_refresh_tracked_portraits(0)
		return
	_refresh_accumulator += delta
	if _refresh_accumulator < REFRESH_INTERVAL:
		return
	_refresh_accumulator = 0.0
	_needs_full_refresh = !_refresh_tracked_portraits()
	if _needs_full_refresh:
		_refresh_accumulator = REFRESH_INTERVAL


func _input(event) -> void:
	if event is InputEventMouseMotion:
		var motion_event = event as InputEventMouseMotion
		var motion_position = _get_current_mouse_position(motion_event.position)
		_track_ancient_text_hover_mouse_position(motion_position)
		_track_gif_hover_mouse_position(motion_position)
		if _ancient_text_left_mouse_down:
			if !_ancient_text_dragging and _ancient_text_press_position != Vector2.INF and _ancient_text_press_position.distance_to(motion_position) >= ANCIENT_TEXT_DRAG_SUPPRESS_DISTANCE:
				_ancient_text_dragging = true
				_clear_pending_ancient_text_click()
				_hide_ancient_text_hover_tip()
		return
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		var click_position = mouse_event.position
		var viewport = get_viewport()
		if viewport != null:
			click_position = viewport.get_mouse_position()
		_track_ancient_text_hover_mouse_position(click_position)
		_track_gif_hover_mouse_position(click_position)
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP or mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN or mouse_event.button_index == MOUSE_BUTTON_WHEEL_LEFT or mouse_event.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
				_request_card_navigation_portrait_refresh()
			_request_ancient_text_hover_refresh()
			_request_gif_playback_refresh()
			return
		if mouse_event.pressed:
			_ancient_text_left_mouse_down = true
			_ancient_text_press_position = click_position
			_ancient_text_dragging = false
			_set_pressed_gif_card(_find_animated_gif_card_root_at_position(click_position))
			_pending_ancient_text_click_position = click_position
			if !_pending_ancient_text_click_from_hitbox:
				_hide_ancient_text_hover_tip()
				_pending_ancient_text_click_card_root = null
				_pending_ancient_text_click_source_path = ""
			_request_ancient_text_hover_refresh()
			_pending_ancient_text_click_frames = 0
		else:
			if _ancient_text_dragging:
				_clear_pending_ancient_text_click()
				_hide_ancient_text_hover_tip()
				_clear_pressed_gif_card()
				call_deferred("_reset_ancient_text_drag_state")
				return
			if !_event_driven_portrait_refresh_enabled:
				_request_card_navigation_portrait_refresh()
			_reset_ancient_text_drag_state()
			_pending_ancient_text_click_position = click_position
			if !_pending_ancient_text_click_from_hitbox:
				var released_card_root = _find_ancient_text_card_root_at_position(click_position)
				if released_card_root != null:
					_set_pending_ancient_text_click_card(released_card_root)
			_pending_ancient_text_click_frames = ANCIENT_TEXT_CLICK_PENDING_FRAMES
			_request_ancient_text_hover_refresh()
			call_deferred("_try_show_pending_ancient_text_click_tip")
			_clear_pressed_gif_card()


func _get_current_mouse_position(fallback_position: Vector2 = Vector2.INF) -> Vector2:
	var viewport = get_viewport()
	if viewport != null:
		return viewport.get_mouse_position()
	return fallback_position


func _clear_pending_ancient_text_click() -> void:
	_pending_ancient_text_click_frames = 0
	_pending_ancient_text_click_position = Vector2.INF
	_pending_ancient_text_click_card_root = null
	_pending_ancient_text_click_source_path = ""
	_pending_ancient_text_click_from_hitbox = false


func _reset_ancient_text_drag_state() -> void:
	_ancient_text_left_mouse_down = false
	_ancient_text_press_position = Vector2.INF
	_ancient_text_dragging = false


func _set_pressed_gif_card(card_root) -> void:
	_pressed_gif_card_root = null
	_pressed_gif_card_source_path = ""
	if card_root == null:
		_refresh_gif_playback_state()
		return
	var source_path = _get_gif_override_source_for_card_root(card_root)
	if source_path == "":
		_refresh_gif_playback_state()
		return
	_pressed_gif_card_root = card_root
	_pressed_gif_card_source_path = source_path
	_refresh_gif_playback_state()


func _clear_pressed_gif_card() -> void:
	if _pressed_gif_card_root == null and _pressed_gif_card_source_path == "":
		return
	_pressed_gif_card_root = null
	_pressed_gif_card_source_path = ""
	_refresh_gif_playback_state()


func _set_pending_ancient_text_click_card(card_root) -> bool:
	if !_is_hover_valid_ancient_text_card_root(card_root):
		return false
	var source_path = _get_ancient_text_layout_source_path(card_root)
	if source_path == "":
		return false
	_pending_ancient_text_click_card_root = card_root
	_pending_ancient_text_click_source_path = source_path
	return true


func _on_ancient_text_card_hitbox_gui_input(event, card_root) -> void:
	if !(event is InputEventMouseButton):
		return
	var mouse_event = event as InputEventMouseButton
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	var click_position = _get_current_mouse_position(mouse_event.position)
	_track_ancient_text_hover_mouse_position(click_position)
	if mouse_event.pressed:
		_hide_ancient_text_hover_tip()
		_pending_ancient_text_click_position = click_position
		_pending_ancient_text_click_from_hitbox = _set_pending_ancient_text_click_card(card_root)
		_request_ancient_text_hover_refresh()
		_pending_ancient_text_click_frames = 0
		return
	if _ancient_text_dragging:
		_clear_pending_ancient_text_click()
		_hide_ancient_text_hover_tip()
		return
	_pending_ancient_text_click_position = click_position
	if _set_pending_ancient_text_click_card(card_root):
		_pending_ancient_text_click_from_hitbox = true
	_pending_ancient_text_click_frames = ANCIENT_TEXT_CLICK_PENDING_FRAMES
	_request_ancient_text_hover_refresh()
	call_deferred("_try_show_pending_ancient_text_click_tip")


func get_session_api_key() -> String:
	return _session_api_key


func set_session_api_key(api_key: String) -> void:
	_session_api_key = api_key.strip_edges()


func get_gif_processing_settings() -> Dictionary:
	return _gif_processing_settings.duplicate(true)


func set_gif_processing_settings(settings: Dictionary) -> void:
	if !(settings is Dictionary):
		return
	var previous_hover_rules = _has_gif_hover_playback_rules()
	_gif_processing_settings["use_cache"] = bool(settings.get("use_cache", true))
	_gif_processing_settings["skip_duplicate_frames"] = bool(settings.get("skip_duplicate_frames", true))
	_gif_processing_settings["use_frame_limit"] = bool(settings.get("use_frame_limit", false))
	_gif_processing_settings["max_frames"] = clamp(int(settings.get("max_frames", 36)), 1, 300)
	_gif_processing_settings["play_on_hover_only"] = bool(settings.get("play_on_hover_only", false))
	if previous_hover_rules != _has_gif_hover_playback_rules():
		_refresh_gif_playback_state()
		_needs_full_refresh = true


func _load_gif_processing_settings_from_dictionary(settings: Dictionary) -> void:
	if !(settings is Dictionary):
		return
	_gif_processing_settings["use_cache"] = bool(settings.get("use_cache", true))
	_gif_processing_settings["skip_duplicate_frames"] = bool(settings.get("skip_duplicate_frames", true))
	_gif_processing_settings["use_frame_limit"] = bool(settings.get("use_frame_limit", false))
	_gif_processing_settings["max_frames"] = clamp(int(settings.get("max_frames", 36)), 1, 300)
	_gif_processing_settings["play_on_hover_only"] = bool(settings.get("play_on_hover_only", false))


func _is_gif_hover_playback_only_enabled() -> bool:
	return bool(_gif_processing_settings.get("play_on_hover_only", false))


func _has_gif_hover_playback_rules() -> bool:
	return _is_gif_hover_playback_only_enabled() or !_gif_hover_playback_by_source.is_empty()


func is_gif_hover_playback_only_enabled() -> bool:
	return _is_gif_hover_playback_only_enabled()


func set_all_gif_hover_playback_only_enabled(enabled: bool) -> void:
	var changed = _is_gif_hover_playback_only_enabled() != enabled or !_gif_hover_playback_by_source.is_empty()
	_gif_processing_settings["play_on_hover_only"] = enabled
	_gif_hover_playback_by_source.clear()
	if !changed:
		return
	_save_persistent_preferences()
	_refresh_gif_playback_state()
	_needs_full_refresh = true


func is_gif_hover_playback_only_enabled_for_source(source_path: String) -> bool:
	source_path = _canonicalize_source_key(source_path)
	if source_path == "":
		return _is_gif_hover_playback_only_enabled()
	if _gif_hover_playback_by_source.has(source_path):
		return bool(_gif_hover_playback_by_source[source_path])
	return _is_gif_hover_playback_only_enabled()


func set_gif_hover_playback_only_enabled_for_source(source_path: String, enabled: bool) -> void:
	source_path = _canonicalize_source_key(source_path)
	if source_path == "":
		return
	if enabled == _is_gif_hover_playback_only_enabled():
		_gif_hover_playback_by_source.erase(source_path)
	else:
		_gif_hover_playback_by_source[source_path] = enabled
	_save_persistent_preferences()
	_refresh_gif_playback_state()
	_needs_full_refresh = true


func has_override(source_path: String) -> bool:
	source_path = _canonicalize_source_key(source_path)
	return _manifest.has(source_path)


func can_toggle_full_art(source_path: String) -> bool:
	source_path = _canonicalize_source_key(source_path)
	if !_manifest.has(source_path):
		return false
	var target_size = get_target_size_for_source_path(source_path)
	return target_size.x > target_size.y


func get_display_mode(source_path: String) -> String:
	source_path = _canonicalize_source_key(source_path)
	var entry = _manifest.get(source_path, null)
	if !(entry is Dictionary):
		return DISPLAY_MODE_DEFAULT
	var mode = String(entry.get("display_mode", DISPLAY_MODE_DEFAULT))
	return mode if mode != "" else DISPLAY_MODE_DEFAULT


func is_full_art_mode(source_path: String) -> bool:
	return get_display_mode(source_path) == DISPLAY_MODE_FULL_ART


func toggle_display_mode(source_path: String) -> Dictionary:
	source_path = _canonicalize_source_key(source_path)
	if !_manifest.has(source_path):
		return {
			"ok": false,
			"message": "No custom image is applied to this card."
		}
	if !can_toggle_full_art(source_path):
		return {
			"ok": false,
			"message": "Full-art mode is only available for regular landscape cards."
		}
	var entry = _manifest.get(source_path, null)
	if !(entry is Dictionary):
		return {
			"ok": false,
			"message": "The current card image could not be updated."
		}
	var next_mode = DISPLAY_MODE_DEFAULT if is_full_art_mode(source_path) else DISPLAY_MODE_FULL_ART
	var rebuild_result = _rebuild_override_for_display_mode(source_path, next_mode, entry)
	if !bool(rebuild_result.get("ok", false)):
		return rebuild_result
	return {
		"ok": true,
		"message": "Full-art style enabled." if next_mode == DISPLAY_MODE_FULL_ART else "Full-art style disabled."
	}


func _get_full_art_capable_override_sources() -> Array:
	var sources: Array = []
	for source_path in _manifest.keys():
		var normalized_source = _canonicalize_source_key(String(source_path))
		if normalized_source != "" and can_toggle_full_art(normalized_source):
			sources.append(normalized_source)
	return sources


func get_full_art_capable_override_count() -> int:
	return _get_full_art_capable_override_sources().size()


func is_all_full_art_mode_enabled() -> bool:
	var sources = _get_full_art_capable_override_sources()
	if sources.is_empty():
		return false
	for source_path in sources:
		if !is_full_art_mode(String(source_path)):
			return false
	return true


func set_all_full_art_mode_enabled(enabled: bool, progress_callback: Callable = Callable()) -> Dictionary:
	var sources = _get_full_art_capable_override_sources()
	if sources.is_empty():
		return {
			"ok": false,
			"message": "There are no applied card images that can use full-art mode."
		}
	var target_mode = DISPLAY_MODE_FULL_ART if enabled else DISPLAY_MODE_DEFAULT
	var changed_count := 0
	var failed_count := 0
	var processed_count := 0
	_begin_batch_updates()
	await _report_import_progress(progress_callback, 0, sources.size(), "Preparing full-art update...")
	for source_path in sources:
		var normalized_source = String(source_path)
		processed_count += 1
		if get_display_mode(normalized_source) == target_mode:
			await _report_import_progress(progress_callback, processed_count, sources.size(), normalized_source.get_file())
			continue
		var entry = _manifest.get(normalized_source, null)
		if !(entry is Dictionary):
			failed_count += 1
			await _report_import_progress(progress_callback, processed_count, sources.size(), normalized_source.get_file())
			continue
		var result = _rebuild_override_for_display_mode(normalized_source, target_mode, entry)
		if bool(result.get("ok", false)):
			changed_count += 1
		else:
			failed_count += 1
		await _report_import_progress(progress_callback, processed_count, sources.size(), normalized_source.get_file())
	_end_batch_updates()
	if changed_count > 0:
		refresh_all_portraits()
	return {
		"ok": failed_count == 0,
		"message": "%s full-art mode for %d cards.%s" % [
			"Enabled" if enabled else "Disabled",
			changed_count,
			" Failed: %d." % failed_count if failed_count > 0 else ""
		],
		"changed_count": changed_count,
		"failed_count": failed_count
	}


func _rebuild_override_for_display_mode(source_path: String, display_mode: String, existing_entry: Dictionary = {}) -> Dictionary:
	var entry = existing_entry if !existing_entry.is_empty() else _manifest.get(source_path, {})
	if !(entry is Dictionary):
		return {
			"ok": false,
			"message": "The current card image could not be rebuilt."
		}

	if _is_animated_entry(entry):
		var source_frames = entry.get("source_animation_frame_paths", entry.get("source_frame_paths", entry.get("frame_paths", [])))
		var frame_delays = entry.get("source_animation_frame_delays", entry.get("frame_delays", []))
		if !(source_frames is Array) or source_frames.is_empty():
			return {
				"ok": false,
				"message": "The current animated card image could not be rebuilt."
			}
		var images: Array = []
		var delays: Array = []
		for index in range(source_frames.size()):
			var frame_image = load_image_from_file(ProjectSettings.globalize_path(String(source_frames[index])))
			if frame_image == null:
				continue
			images.append(frame_image)
			delays.append(max(0.02, float(frame_delays[index]) if index < frame_delays.size() else 0.1))
		if images.is_empty():
			return {
				"ok": false,
				"message": "The current animated card image could not be rebuilt."
			}
		var animated_result = save_animated_override_images(source_path, images, delays, display_mode)
		if bool(animated_result.get("ok", false)):
			var updated_entry = _manifest.get(source_path, null)
			if updated_entry is Dictionary:
				updated_entry["adjust_zoom"] = 1.0
				updated_entry["adjust_offset_x"] = 0.0
				updated_entry["adjust_offset_y"] = 0.0
				_manifest[source_path] = updated_entry
				_save_manifest()
		return animated_result

	var edit_source_path = String(entry.get("edit_source_path", entry.get("override_path", "")))
	if edit_source_path == "":
		return {
			"ok": false,
			"message": "The current card image could not be rebuilt."
		}
	var source_image = load_image_from_file(ProjectSettings.globalize_path(edit_source_path))
	if source_image == null:
		return {
			"ok": false,
			"message": "The current card image could not be rebuilt."
		}
	return save_override_image(source_path, source_image, display_mode)


func can_adjust_override(source_path: String) -> bool:
	source_path = _canonicalize_source_key(source_path)
	if !_manifest.has(source_path):
		return false
	var entry = _manifest.get(source_path, null)
	return entry is Dictionary


func get_override_adjustment_state(source_path: String) -> Dictionary:
	source_path = _canonicalize_source_key(source_path)
	var entry = _manifest.get(source_path, null)
	if !(entry is Dictionary):
		return {
			"zoom": 1.0,
			"offset_x": 0.0,
			"offset_y": 0.0
		}
	return {
		"zoom": float(entry.get("adjust_zoom", 1.0)),
		"offset_x": float(entry.get("adjust_offset_x", 0.0)),
		"offset_y": float(entry.get("adjust_offset_y", 0.0))
	}


func get_adjustable_override_image(source_path: String):
	if !can_adjust_override(source_path):
		return null
	var payload = get_adjustable_override_payload(source_path)
	if payload.is_empty():
		return null
	return payload.get("preview_image", null)


func get_adjustable_override_payload(source_path: String) -> Dictionary:
	source_path = _canonicalize_source_key(source_path)
	if !can_adjust_override(source_path):
		return {}
	var entry = _manifest.get(source_path, null)
	if !(entry is Dictionary):
		return {}
	if _is_animated_entry(entry):
		var images: Array = []
		var delays: Array = []
		var frame_paths = entry.get("source_animation_frame_paths", entry.get("source_frame_paths", entry.get("frame_paths", [])))
		var frame_delays = entry.get("source_animation_frame_delays", entry.get("frame_delays", []))
		if !(frame_paths is Array):
			return {}
		for index in range(frame_paths.size()):
			var image = load_image_from_file(ProjectSettings.globalize_path(String(frame_paths[index])))
			if image == null:
				continue
			images.append(image)
			delays.append(float(frame_delays[index]) if index < frame_delays.size() else 0.1)
		if images.is_empty():
			return {}
		return {
			"type": "animated_gif",
			"images": images,
			"delays": delays,
			"preview_image": images[0]
		}

	var source_path_key = String(entry.get("edit_source_path", entry.get("override_path", "")))
	if source_path_key == "":
		return {}
	var source_image = load_image_from_file(ProjectSettings.globalize_path(source_path_key))
	if source_image == null:
		return {}
	return {
		"type": "static",
		"image": source_image,
		"preview_image": source_image
	}


func get_override_count() -> int:
	return _manifest.size()


func is_infection_effect_hidden_enabled() -> bool:
	return _infection_effect_hidden_enabled


func set_infection_effect_hidden_enabled(enabled: bool) -> void:
	if _infection_effect_hidden_enabled == enabled:
		return
	_infection_effect_hidden_enabled = enabled
	_save_persistent_preferences()
	refresh_all_portraits()


func is_full_art_rarity_fire_enabled() -> bool:
	return _full_art_rarity_fire_enabled


func set_full_art_rarity_fire_enabled(enabled: bool) -> void:
	if _full_art_rarity_fire_enabled == enabled:
		return
	_full_art_rarity_fire_enabled = enabled
	_save_persistent_preferences()
	refresh_all_portraits()


func set_all_full_art_rarity_fire_enabled(enabled: bool) -> void:
	var changed = _full_art_rarity_fire_enabled != enabled or !_full_art_rarity_fire_by_source.is_empty()
	_full_art_rarity_fire_enabled = enabled
	_full_art_rarity_fire_by_source.clear()
	if !changed:
		return
	_save_persistent_preferences()
	refresh_all_portraits()


func is_full_art_rarity_fire_enabled_for_source(source_path: String) -> bool:
	source_path = _canonicalize_source_key(source_path)
	if source_path == "":
		return _full_art_rarity_fire_enabled
	if _full_art_rarity_fire_by_source.has(source_path):
		return bool(_full_art_rarity_fire_by_source[source_path])
	return _full_art_rarity_fire_enabled


func set_full_art_rarity_fire_enabled_for_source(source_path: String, enabled: bool) -> void:
	source_path = _canonicalize_source_key(source_path)
	if source_path == "":
		return
	if enabled == _full_art_rarity_fire_enabled:
		_full_art_rarity_fire_by_source.erase(source_path)
	else:
		_full_art_rarity_fire_by_source[source_path] = enabled
	_save_persistent_preferences()
	refresh_all_portraits()


func reset_card_art_editor_settings() -> void:
	_infection_effect_hidden_enabled = true
	_full_art_rarity_fire_enabled = false
	_full_art_rarity_fire_by_source.clear()
	_gif_hover_playback_by_source.clear()
	_ancient_text_outside_by_source.clear()
	_gif_processing_settings = {
		"use_cache": true,
		"skip_duplicate_frames": true,
		"use_frame_limit": false,
		"max_frames": 36,
		"play_on_hover_only": false
	}
	_save_persistent_preferences()
	_refresh_gif_playback_state()
	_hide_ancient_text_hover_tip()
	refresh_all_portraits()


func is_ancient_text_outside_enabled(source_path: String) -> bool:
	source_path = _canonicalize_source_key(source_path)
	if source_path == "":
		return false
	return bool(_ancient_text_outside_by_source.get(source_path, false))


func set_ancient_text_outside_enabled(source_path: String, enabled: bool) -> void:
	source_path = _canonicalize_source_key(source_path)
	if source_path == "":
		return
	if enabled:
		_ancient_text_outside_by_source[source_path] = true
	else:
		_ancient_text_outside_by_source.erase(source_path)
	_save_persistent_preferences()
	_needs_full_refresh = true
	_request_ancient_text_hover_refresh(true)


func _get_ancient_text_outside_capable_sources() -> Array:
	var sources: Array = []
	for source_path in _manifest.keys():
		var normalized_source = _canonicalize_source_key(String(source_path))
		if normalized_source != "" and is_full_art_mode(normalized_source):
			sources.append(normalized_source)
	return sources


func get_ancient_text_outside_capable_count() -> int:
	return _get_ancient_text_outside_capable_sources().size()


func is_all_ancient_text_outside_enabled() -> bool:
	var sources = _get_ancient_text_outside_capable_sources()
	if sources.is_empty():
		return false
	for source_path in sources:
		if !is_ancient_text_outside_enabled(String(source_path)):
			return false
	return true


func set_all_ancient_text_outside_enabled(enabled: bool) -> Dictionary:
	var sources = _get_ancient_text_outside_capable_sources()
	if sources.is_empty():
		return {
			"ok": false,
			"message": "There are no full-art cards that can move text outside."
		}
	var changed_count := 0
	for source_path in sources:
		var normalized_source = String(source_path)
		var current_enabled = is_ancient_text_outside_enabled(normalized_source)
		if current_enabled == enabled:
			continue
		if enabled:
			_ancient_text_outside_by_source[normalized_source] = true
		else:
			_ancient_text_outside_by_source.erase(normalized_source)
		changed_count += 1
	if changed_count > 0:
		_save_persistent_preferences()
		_hide_ancient_text_hover_tip()
		_request_ancient_text_hover_refresh(true)
		refresh_all_portraits()
	return {
		"ok": true,
		"message": "%s outside text for %d cards." % [
			"Enabled" if enabled else "Disabled",
			changed_count
		],
		"changed_count": changed_count
	}


func _load_persistent_preferences() -> void:
	if !FileAccess.file_exists(STORAGE_UI_SETTINGS_PATH):
		return
	var file = FileAccess.open(STORAGE_UI_SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		var parsed_gif_settings = parsed.get("gif_processing_settings", {})
		if parsed_gif_settings is Dictionary:
			_load_gif_processing_settings_from_dictionary(parsed_gif_settings)
		var parsed_gif_hover_settings = parsed.get("gif_hover_playback_by_source", {})
		if parsed_gif_hover_settings is Dictionary:
			_gif_hover_playback_by_source.clear()
			for source_path in parsed_gif_hover_settings.keys():
				var normalized_gif_path = _canonicalize_source_key(String(source_path))
				if normalized_gif_path != "":
					_gif_hover_playback_by_source[normalized_gif_path] = bool(parsed_gif_hover_settings[source_path])
		_infection_effect_hidden_enabled = bool(parsed.get("infection_effect_hidden_enabled", _infection_effect_hidden_enabled))
		_full_art_rarity_fire_enabled = bool(parsed.get("full_art_rarity_fire_enabled", _full_art_rarity_fire_enabled))
		var parsed_rarity_fire_settings = parsed.get("full_art_rarity_fire_by_source", {})
		if parsed_rarity_fire_settings is Dictionary:
			_full_art_rarity_fire_by_source.clear()
			for source_path in parsed_rarity_fire_settings.keys():
				var normalized_rarity_path = _canonicalize_source_key(String(source_path))
				if normalized_rarity_path != "":
					_full_art_rarity_fire_by_source[normalized_rarity_path] = bool(parsed_rarity_fire_settings[source_path])
		var parsed_ancient_settings = parsed.get("ancient_text_outside_by_source", {})
		if parsed_ancient_settings is Dictionary:
			_ancient_text_outside_by_source.clear()
			for source_path in parsed_ancient_settings.keys():
				if bool(parsed_ancient_settings[source_path]):
					var normalized_path = _canonicalize_source_key(String(source_path))
					if normalized_path != "":
						_ancient_text_outside_by_source[normalized_path] = true
			_request_ancient_text_hover_refresh(true)


func _save_persistent_preferences() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STORAGE_UI_SETTINGS_PATH).get_base_dir())
	var settings: Dictionary = {}
	if FileAccess.file_exists(STORAGE_UI_SETTINGS_PATH):
		var existing_file = FileAccess.open(STORAGE_UI_SETTINGS_PATH, FileAccess.READ)
		if existing_file != null:
			var parsed = JSON.parse_string(existing_file.get_as_text())
			if parsed is Dictionary:
				settings = parsed.duplicate(true)
	settings["infection_effect_hidden_enabled"] = _infection_effect_hidden_enabled
	settings["full_art_rarity_fire_enabled"] = _full_art_rarity_fire_enabled
	settings["full_art_rarity_fire_by_source"] = _full_art_rarity_fire_by_source.duplicate(true)
	settings["gif_hover_playback_by_source"] = _gif_hover_playback_by_source.duplicate(true)
	settings["ancient_text_outside_by_source"] = _ancient_text_outside_by_source.duplicate(true)
	settings["gif_processing_settings"] = _gif_processing_settings.duplicate(true)
	var file = FileAccess.open(STORAGE_UI_SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(settings))
	file.flush()


func get_art_pack_list() -> Array:
	var packs = _art_pack_registry.get("packs", {})
	if !(packs is Dictionary):
		return []
	var result: Array = []
	for pack_id in packs.keys():
		var pack = packs[pack_id]
		if !(pack is Dictionary):
			continue
		result.append({
			"id": String(pack.get("id", pack_id)),
			"name": String(pack.get("name", pack_id)),
			"count": int(pack.get("count", 0)),
			"imported_at": String(pack.get("imported_at", "")),
			"source_file": String(pack.get("source_file", ""))
		})
	result.sort_custom(func(a, b): return String(a.get("imported_at", "")) > String(b.get("imported_at", "")))
	return result


func scan_workshop_art_packs(progress_callback: Callable = Callable()) -> Dictionary:
	var workshop_roots = _get_steam_workshop_content_roots()
	if workshop_roots.is_empty():
		return {
			"ok": false,
			"reason": "workshop_root_not_found",
			"message": "The Steam Workshop content folder could not be found."
		}
	var candidates: Array = _collect_workshop_art_pack_files(workshop_roots)
	var workshop_sources = _art_pack_registry.get("workshop_sources", {})
	if !(workshop_sources is Dictionary):
		workshop_sources = {}
	var found_source_keys := {}
	var imported_count := 0
	var skipped_count := 0
	var failed_count := 0
	var removed_count := 0
	var processed_count := 0
	var candidate_total = max(candidates.size(), 1)
	await _report_import_progress(progress_callback, 0, candidate_total, "Scanning Steam Workshop art packs...")
	for candidate in candidates:
		processed_count += 1
		if !(candidate is Dictionary):
			failed_count += 1
			await _report_import_progress(progress_callback, processed_count, candidate_total, "Invalid Workshop entry")
			continue
		var source_file = String(candidate.get("path", ""))
		if source_file == "" or !FileAccess.file_exists(source_file):
			failed_count += 1
			await _report_import_progress(progress_callback, processed_count, candidate_total, source_file.get_file())
			continue
		var source_key = _external_file_path_key(source_file)
		if source_key == "":
			failed_count += 1
			await _report_import_progress(progress_callback, processed_count, candidate_total, source_file.get_file())
			continue
		found_source_keys[source_key] = true
		var modified_time = int(FileAccess.get_modified_time(source_file))
		var file_size = _get_external_file_size(source_file)
		var previous_state = workshop_sources.get(source_key, {})
		if !(previous_state is Dictionary):
			previous_state = {}
		var previous_pack_id = String(previous_state.get("pack_id", ""))
		var dismissed = bool(previous_state.get("dismissed", false))
		var unchanged = int(previous_state.get("modified_time", -1)) == modified_time and int(previous_state.get("file_size", -1)) == file_size
		var packs = _art_pack_registry.get("packs", {})
		var previous_pack_available = previous_pack_id != "" and packs is Dictionary and packs.has(previous_pack_id)
		if unchanged and (previous_pack_available or dismissed):
			skipped_count += 1
			await _report_import_progress(progress_callback, processed_count, candidate_total, "Skipped %s" % source_file.get_file())
			continue

		# Workshop scans register packs only. Applying them remains an explicit user action.
		var import_result = await import_bundle_from_file(source_file, progress_callback, {})
		if !bool(import_result.get("ok", false)):
			failed_count += 1
			push_warning("Card Art Editor could not import Workshop art pack %s: %s" % [
				source_file,
				String(import_result.get("message", "Unknown import error."))
			])
			await _report_import_progress(progress_callback, processed_count, candidate_total, "Failed %s" % source_file.get_file())
			continue
		var new_pack_id = String(import_result.get("pack_id", ""))
		if new_pack_id == "":
			failed_count += 1
			await _report_import_progress(progress_callback, processed_count, candidate_total, "Failed %s" % source_file.get_file())
			continue
		if previous_pack_id != "" and previous_pack_id != new_pack_id:
			_remove_art_pack_registration(previous_pack_id, false, false)
		packs = _art_pack_registry.get("packs", {})
		if packs is Dictionary and packs.has(new_pack_id):
			var pack_data = packs[new_pack_id]
			if pack_data is Dictionary:
				pack_data["source_type"] = "steam_workshop"
				pack_data["workshop_item_id"] = String(candidate.get("workshop_item_id", ""))
				packs[new_pack_id] = pack_data
				_art_pack_registry["packs"] = packs
		workshop_sources[source_key] = {
			"path": source_file,
			"pack_id": new_pack_id,
			"workshop_item_id": String(candidate.get("workshop_item_id", "")),
			"modified_time": modified_time,
			"file_size": file_size,
			"dismissed": false
		}
		_art_pack_registry["workshop_sources"] = workshop_sources
		_save_art_pack_registry()
		imported_count += 1
		await _report_import_progress(progress_callback, processed_count, candidate_total, "Registered %s" % source_file.get_file())

	var stale_source_keys: Array = []
	for source_key in workshop_sources.keys():
		if found_source_keys.has(source_key):
			continue
		var source_state = workshop_sources.get(source_key, null)
		if !(source_state is Dictionary):
			stale_source_keys.append(source_key)
			continue
		var source_path = String(source_state.get("path", ""))
		if !_is_path_inside_any_root(source_path, workshop_roots):
			continue
		var stale_pack_id = String(source_state.get("pack_id", ""))
		if stale_pack_id != "":
			_remove_art_pack_registration(stale_pack_id, false, true)
			removed_count += 1
		stale_source_keys.append(source_key)
	for source_key in stale_source_keys:
		workshop_sources.erase(source_key)
	if !stale_source_keys.is_empty():
		_art_pack_registry["workshop_sources"] = workshop_sources
		_save_art_pack_registry()
	await _report_import_progress(progress_callback, candidate_total, candidate_total, "Workshop art pack scan complete")
	print("Card Art Editor Workshop scan: registered %d, skipped %d, failed %d, removed %d." % [
		imported_count,
		skipped_count,
		failed_count,
		removed_count
	])
	return {
		"ok": true,
		"scanned_count": candidates.size(),
		"imported_count": imported_count,
		"skipped_count": skipped_count,
		"failed_count": failed_count,
		"removed_count": removed_count,
		"message": "Workshop scan complete. Registered: %d, skipped: %d, failed: %d." % [imported_count, skipped_count, failed_count]
	}


func _get_steam_workshop_content_roots() -> Array:
	var roots_by_key := {}
	var root_override = OS.get_environment("CARD_ART_EDITOR_WORKSHOP_ROOT").strip_edges()
	if root_override != "":
		_add_workshop_content_root(roots_by_key, root_override)
	var path_candidates: Array = [
		OS.get_executable_path().get_base_dir(),
		ProjectSettings.globalize_path("res://")
	]
	var compat_data_path = OS.get_environment("STEAM_COMPAT_DATA_PATH").strip_edges()
	if compat_data_path != "":
		path_candidates.append(compat_data_path)
	for candidate_path in path_candidates:
		var steamapps_path = _find_steamapps_ancestor(String(candidate_path))
		if steamapps_path != "":
			_add_workshop_content_root(roots_by_key, steamapps_path.path_join("workshop/content").path_join(STEAM_WORKSHOP_APP_ID))
	var steam_install_path = OS.get_environment("STEAM_COMPAT_CLIENT_INSTALL_PATH").strip_edges()
	if steam_install_path != "":
		_add_workshop_content_root(roots_by_key, steam_install_path.path_join("steamapps/workshop/content").path_join(STEAM_WORKSHOP_APP_ID))
	var roots: Array = roots_by_key.values()
	roots.sort()
	return roots


func _add_workshop_content_root(roots_by_key: Dictionary, candidate_path: String) -> void:
	var normalized_path = _normalize_external_file_path(candidate_path)
	if normalized_path == "" or !DirAccess.dir_exists_absolute(normalized_path):
		return
	roots_by_key[_external_file_path_key(normalized_path)] = normalized_path


func _find_steamapps_ancestor(start_path: String) -> String:
	var cursor = _normalize_external_file_path(start_path)
	for _index in range(12):
		var folder_name = cursor.get_file().to_lower()
		if folder_name == "steamapps":
			return cursor
		if folder_name == "common":
			return cursor.get_base_dir()
		var parent = cursor.get_base_dir()
		if parent == cursor or parent == "":
			break
		cursor = parent
	return ""


func _collect_workshop_art_pack_files(workshop_roots: Array) -> Array:
	var result: Array = []
	var seen_paths := {}
	for workshop_root_value in workshop_roots:
		var workshop_root = String(workshop_root_value)
		_append_workshop_art_pack_files_from_directory(workshop_root, "", result, seen_paths)
		var root_dir = DirAccess.open(workshop_root)
		if root_dir == null:
			continue
		root_dir.list_dir_begin()
		while true:
			var entry_name = root_dir.get_next()
			if entry_name == "":
				break
			if entry_name == "." or entry_name == ".." or !root_dir.current_is_dir():
				continue
			_append_workshop_art_pack_files_from_directory(
				workshop_root.path_join(entry_name),
				entry_name,
				result,
				seen_paths
			)
		root_dir.list_dir_end()
	result.sort_custom(func(a, b): return String(a.get("path", "")) < String(b.get("path", "")))
	return result


func _append_workshop_art_pack_files_from_directory(directory_path: String, workshop_item_id: String, output: Array, seen_paths: Dictionary) -> void:
	var dir = DirAccess.open(directory_path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var entry_name = dir.get_next()
		if entry_name == "":
			break
		if dir.current_is_dir() or !entry_name.to_lower().ends_with(WORKSHOP_ART_PACK_SUFFIX):
			continue
		var entry_path = directory_path.path_join(entry_name)
		var source_key = _external_file_path_key(entry_path)
		if seen_paths.has(source_key):
			continue
		seen_paths[source_key] = true
		output.append({
			"path": _normalize_external_file_path(entry_path),
			"workshop_item_id": workshop_item_id
		})
	dir.list_dir_end()


func _normalize_external_file_path(path: String) -> String:
	var normalized_path = path.strip_edges().replace("\\", "/")
	if normalized_path == "":
		return ""
	return normalized_path.simplify_path().trim_suffix("/")


func _external_file_path_key(path: String) -> String:
	return _normalize_external_file_path(path).to_lower()


func _get_external_file_size(path: String) -> int:
	var file = FileAccess.open(path, FileAccess.READ)
	return int(file.get_length()) if file != null else -1


func _is_path_inside_any_root(path: String, roots: Array) -> bool:
	var path_key = _external_file_path_key(path)
	for root_value in roots:
		var root_key = _external_file_path_key(String(root_value)).trim_suffix("/")
		if path_key == root_key or path_key.begins_with(root_key + "/"):
			return true
	return false


func get_art_pack_categories(pack_id: String) -> Array:
	var packs = _art_pack_registry.get("packs", {})
	if !(packs is Dictionary) or !packs.has(pack_id):
		return []
	var pack = packs[pack_id]
	if !(pack is Dictionary):
		return []
	var cards = pack.get("cards", {})
	if !(cards is Dictionary):
		return []
	var counts := {}
	for source_path in cards.keys():
		var card_entry = cards[source_path]
		if !(card_entry is Dictionary):
			continue
		var category_id = _get_art_pack_category_id_for_source(String(source_path))
		if category_id == "":
			category_id = "other"
		counts[category_id] = int(counts.get(category_id, 0)) + 1
	var result: Array = []
	for category_id in counts.keys():
		result.append({
			"id": String(category_id),
			"name": _get_art_pack_category_display_name(String(category_id)),
			"count": int(counts[category_id])
		})
	result.sort_custom(func(a, b): return _compare_art_pack_category_entries(a, b))
	return result


func get_art_pack_variants_for_source(source_path: String) -> Array:
	source_path = _canonicalize_source_key(source_path)
	if source_path == "":
		return []
	var active_pack_id = ""
	var active_entry = _manifest.get(source_path, null)
	if active_entry is Dictionary:
		active_pack_id = String(active_entry.get("provider_pack_id", ""))
	var result: Array = []
	var cached_variants = _art_pack_variants_cache.get(source_path, null)
	if cached_variants is Array:
		result = (cached_variants as Array).duplicate(true)
	else:
		var packs = _art_pack_registry.get("packs", {})
		if !(packs is Dictionary):
			return []
		for pack_id in packs.keys():
			var pack = packs[pack_id]
			if !(pack is Dictionary):
				continue
			var cards = pack.get("cards", {})
			if !(cards is Dictionary):
				continue
			var matched_card = _find_art_pack_card_entry(cards, source_path)
			if matched_card.is_empty():
				continue
			var card_entry = matched_card.get("entry", null)
			if !(card_entry is Dictionary):
				continue
			result.append({
				"pack_id": String(pack.get("id", pack_id)),
				"pack_name": String(pack.get("name", pack_id)),
				"display_mode": String(card_entry.get("display_mode", DISPLAY_MODE_DEFAULT)),
				"type": String(card_entry.get("type", "static"))
			})
		result.sort_custom(func(a, b): return String(a.get("pack_name", "")).naturalnocasecmp_to(String(b.get("pack_name", ""))) < 0)
		_art_pack_variants_cache[source_path] = result.duplicate(true)
	for index in range(result.size()):
		var variant = result[index]
		if !(variant is Dictionary):
			continue
		variant["active"] = String(variant.get("pack_id", "")) == active_pack_id
		result[index] = variant
	return result


func apply_art_pack_variant(source_path: String, pack_id: String) -> Dictionary:
	source_path = _canonicalize_source_key(source_path)
	if source_path == "":
		return {
			"ok": false,
			"message": "No card art is selected."
		}
	var packs = _art_pack_registry.get("packs", {})
	if !(packs is Dictionary) or !packs.has(pack_id):
		return {
			"ok": false,
			"message": "The selected art pack could not be found."
		}
	var pack = packs[pack_id]
	if !(pack is Dictionary):
		return {
			"ok": false,
			"message": "The selected art pack could not be read."
		}
	var cards = pack.get("cards", {})
	if !(cards is Dictionary):
		return {
			"ok": false,
			"message": "That art pack does not contain the current card."
		}
	var matched_card = _find_art_pack_card_entry(cards, source_path)
	if matched_card.is_empty():
		return {
			"ok": false,
			"message": "That art pack does not contain the current card."
		}
	var card_entry = matched_card.get("entry", null)
	if !(card_entry is Dictionary):
		return {
			"ok": false,
			"message": "The selected card entry in the art pack is invalid."
	}
	return _activate_registered_art_pack_entry(source_path, card_entry, pack_id, String(pack.get("name", pack_id)))


func _find_art_pack_card_entry(cards: Dictionary, source_path: String) -> Dictionary:
	var canonical_source = _canonicalize_source_key(source_path)
	if canonical_source == "":
		return {}
	if cards.has(canonical_source):
		var exact_entry = cards.get(canonical_source, null)
		if exact_entry is Dictionary:
			return {
				"source_path": canonical_source,
				"entry": exact_entry
			}
	for card_source_path in cards.keys():
		var card_entry = cards.get(card_source_path, null)
		if !(card_entry is Dictionary):
			continue
		var canonical_card_source = _canonicalize_source_key(String(card_source_path))
		if canonical_card_source == canonical_source:
			return {
				"source_path": String(card_source_path),
				"entry": card_entry
			}
	return {}


func _normalize_art_pack_category_id(category_id: String) -> String:
	return _safe_file_stem(category_id).to_lower()


func _is_known_art_pack_category_id(category_id: String) -> bool:
	category_id = _normalize_art_pack_category_id(category_id)
	return CARD_PORTRAIT_FOLDERS.has(category_id) or MODDED_CARD_PORTRAIT_FOLDERS.has(category_id)


func _get_art_pack_category_id_for_source(source_path: String) -> String:
	var normalized = _canonicalize_source_key(source_path).replace("\\", "/").to_lower()
	if normalized == "":
		normalized = _normalize_source_path(source_path).replace("\\", "/").to_lower()
	var parts = normalized.split("/")
	for index in range(parts.size() - 1):
		if String(parts[index]) == "card_portraits":
			var folder = _normalize_art_pack_category_id(String(parts[index + 1]))
			if folder != "":
				return folder
	for part in parts:
		var category_id = _normalize_art_pack_category_id(String(part))
		if _is_known_art_pack_category_id(category_id):
			return category_id
	return "other"


func _get_art_pack_category_display_name(category_id: String) -> String:
	match _normalize_art_pack_category_id(category_id):
		"regent":
			return "Regent"
		"silent":
			return "Silent"
		"ironclad":
			return "Ironclad"
		"seeker":
			return "Seeker"
		"defect":
			return "Defect"
		"colorless":
			return "Colorless"
		"status":
			return "Status"
		"token":
			return "Token"
		"curse":
			return "Curse"
		"event":
			return "Event"
		"necrobinder":
			return "Necrobinder"
		"guardian":
			return "Guardian"
		"hermit":
			return "Hermit"
		"champ":
			return "Champ"
		"snecko":
			return "Snecko"
		"automaton":
			return "Automaton"
		"awakened":
			return "Awakened"
		"collector":
			return "Collector"
		"slimeboss":
			return "Slime Boss"
		"gremlins":
			return "Gremlins"
		"hexaghost":
			return "Hexaghost"
		"downfall":
			return "Downfall"
		_:
			return "Other"


func _get_art_pack_category_sort_index(category_id: String) -> int:
	var index = ART_PACK_CATEGORY_SORT_ORDER.find(_normalize_art_pack_category_id(category_id))
	return index if index >= 0 else ART_PACK_CATEGORY_SORT_ORDER.size()


func _compare_art_pack_category_entries(a, b) -> bool:
	var a_id := ""
	var b_id := ""
	var a_name := ""
	var b_name := ""
	if a is Dictionary:
		var a_entry := a as Dictionary
		a_id = String(a_entry.get("id", ""))
		a_name = String(a_entry.get("name", ""))
	if b is Dictionary:
		var b_entry := b as Dictionary
		b_id = String(b_entry.get("id", ""))
		b_name = String(b_entry.get("name", ""))
	var a_order = _get_art_pack_category_sort_index(a_id)
	var b_order = _get_art_pack_category_sort_index(b_id)
	if a_order == b_order:
		return a_name.naturalnocasecmp_to(b_name) < 0
	return a_order < b_order


func apply_art_pack_to_all(pack_id: String, progress_callback: Callable = Callable()) -> Dictionary:
	var packs = _art_pack_registry.get("packs", {})
	if !(packs is Dictionary) or !packs.has(pack_id):
		return {
			"ok": false,
			"message": "The selected art pack could not be found."
		}
	var pack = packs[pack_id]
	if !(pack is Dictionary):
		return {
			"ok": false,
			"message": "The selected art pack could not be read."
		}
	var cards = pack.get("cards", {})
	if !(cards is Dictionary) or cards.is_empty():
		return {
			"ok": false,
			"message": "That art pack does not contain any card entries."
		}
	var applied_count: int = 0
	var total: int = cards.size()
	var processed: int = 0
	_begin_batch_updates()
	await _report_import_progress(progress_callback, 0, total, "Applying art pack...")
	for source_path in cards.keys():
		var card_entry = cards[source_path]
		processed += 1
		if !(card_entry is Dictionary):
			await _report_import_progress(progress_callback, processed, total, String(source_path).get_file())
			continue
		var result = _activate_registered_art_pack_entry(String(source_path), card_entry, pack_id, String(pack.get("name", pack_id)))
		if bool(result.get("ok", false)):
			applied_count += 1
		await _report_import_progress(progress_callback, processed, total, String(source_path).get_file())
	if applied_count == 0:
		_end_batch_updates()
		return {
			"ok": false,
			"message": "No cards from that art pack could be applied."
		}
	_end_batch_updates()
	return {
		"ok": true,
		"message": "Applied %d cards from \"%s\"." % [applied_count, String(pack.get("name", pack_id))]
	}


func apply_art_pack_to_category(pack_id: String, category_id: String, progress_callback: Callable = Callable()) -> Dictionary:
	category_id = _normalize_art_pack_category_id(category_id)
	if category_id == "":
		return {
			"ok": false,
			"message": "No art pack category is selected."
		}
	var packs = _art_pack_registry.get("packs", {})
	if !(packs is Dictionary) or !packs.has(pack_id):
		return {
			"ok": false,
			"message": "The selected art pack could not be found."
		}
	var pack = packs[pack_id]
	if !(pack is Dictionary):
		return {
			"ok": false,
			"message": "The selected art pack could not be read."
		}
	var cards = pack.get("cards", {})
	if !(cards is Dictionary) or cards.is_empty():
		return {
			"ok": false,
			"message": "That art pack does not contain any card entries."
		}
	var category_sources: Array = []
	for source_path in cards.keys():
		if _get_art_pack_category_id_for_source(String(source_path)) == category_id:
			category_sources.append(source_path)
	if category_sources.is_empty():
		return {
			"ok": false,
			"message": "That art pack does not contain cards in the selected category."
		}
	var category_name = _get_art_pack_category_display_name(category_id)
	var applied_count: int = 0
	var total: int = category_sources.size()
	var processed: int = 0
	_begin_batch_updates()
	await _report_import_progress(progress_callback, 0, total, "Applying %s..." % category_name)
	for source_path in category_sources:
		var card_entry = cards[source_path]
		processed += 1
		if !(card_entry is Dictionary):
			await _report_import_progress(progress_callback, processed, total, String(source_path).get_file())
			continue
		var result = _activate_registered_art_pack_entry(String(source_path), card_entry, pack_id, String(pack.get("name", pack_id)))
		if bool(result.get("ok", false)):
			applied_count += 1
		await _report_import_progress(progress_callback, processed, total, String(source_path).get_file())
	if applied_count == 0:
		_end_batch_updates()
		return {
			"ok": false,
			"message": "No %s cards from that art pack could be applied." % category_name
		}
	_end_batch_updates()
	return {
		"ok": true,
		"message": "Applied %d %s cards from \"%s\"." % [applied_count, category_name, String(pack.get("name", pack_id))]
	}


func remove_art_pack(pack_id: String) -> Dictionary:
	return _remove_art_pack_registration(pack_id, true, true)


func _remove_art_pack_registration(pack_id: String, mark_workshop_dismissed: bool, notify_changed: bool) -> Dictionary:
	var packs = _art_pack_registry.get("packs", {})
	if !(packs is Dictionary) or !packs.has(pack_id):
		return {
			"ok": false,
			"message": "The selected art pack could not be found."
		}
	var pack = packs[pack_id]
	var pack_name = String(pack.get("name", pack_id)) if pack is Dictionary else pack_id
	var pack_dir = _get_art_pack_dir(pack_id)
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(pack_dir)):
		_delete_directory_recursive(pack_dir)
	packs.erase(pack_id)
	_art_pack_registry["packs"] = packs

	for source_path in _manifest.keys():
		var entry = _manifest.get(source_path, null)
		if !(entry is Dictionary):
			continue
		if String(entry.get("provider_pack_id", "")) != pack_id:
			continue
		entry["provider_type"] = ""
		entry["provider_pack_id"] = ""
		entry["provider_pack_name"] = ""
		_manifest[source_path] = entry
	if mark_workshop_dismissed:
		var workshop_sources = _art_pack_registry.get("workshop_sources", {})
		if workshop_sources is Dictionary:
			for source_key in workshop_sources.keys():
				var source_state = workshop_sources.get(source_key, null)
				if !(source_state is Dictionary) or String(source_state.get("pack_id", "")) != pack_id:
					continue
				source_state["pack_id"] = ""
				source_state["dismissed"] = true
				workshop_sources[source_key] = source_state
			_art_pack_registry["workshop_sources"] = workshop_sources

	_save_manifest()
	_save_art_pack_registry()
	if notify_changed:
		_notify_art_packs_changed()
	return {
		"ok": true,
		"message": "Removed \"%s\" from the art pack list." % pack_name
	}


func get_source_path_for_texture_rect(texture_rect) -> String:
	if texture_rect == null:
		return ""
	_refresh_portrait_node(texture_rect)
	return _as_valid_card_art_source(String(texture_rect.get_meta(META_SOURCE_PATH, "")))


func get_source_path_for_card_node(card_node) -> String:
	if card_node == null:
		return ""
	var card_root = card_node.get_node_or_null("CardContainer")
	var active_full_art_owner = _get_current_card_active_full_art_owner_path(card_root)
	if active_full_art_owner != "":
		return active_full_art_owner
	var model_source_path = _get_model_or_inspect_source_path(card_node)
	if model_source_path != "":
		return model_source_path
	var portrait_canvas_group = card_node.get_node_or_null("CardContainer/PortraitCanvasGroup")
	var ancient_portrait = card_node.get_node_or_null("CardContainer/PortraitCanvasGroup/AncientPortrait")
	var portrait = card_node.get_node_or_null("CardContainer/PortraitCanvasGroup/Portrait")
	if ancient_portrait is TextureRect and ancient_portrait.visible:
		var visible_ancient_source = get_source_path_for_texture_rect(ancient_portrait)
		if visible_ancient_source != "":
			return visible_ancient_source
		var direct_ancient_path = _resolve_texture_source_path(ancient_portrait, ancient_portrait.texture)
		if direct_ancient_path != "":
			return direct_ancient_path
	if portrait is TextureRect and portrait.visible:
		var visible_portrait_source = get_source_path_for_texture_rect(portrait)
		if visible_portrait_source != "":
			return visible_portrait_source
		var direct_portrait_path = _resolve_texture_source_path(portrait, portrait.texture)
		if direct_portrait_path != "":
			return direct_portrait_path
	if portrait_canvas_group != null:
		var full_art_layer = portrait_canvas_group.get_node_or_null(FULL_ART_LAYER_NAME)
		if full_art_layer is TextureRect and bool(full_art_layer.get_meta(META_FULL_ART_ACTIVE, false)):
			var full_art_owner = String(full_art_layer.get_meta(META_FULL_ART_OWNER_PATH, ""))
			if full_art_owner != "":
				return full_art_owner
	if ancient_portrait is TextureRect:
		return get_source_path_for_texture_rect(ancient_portrait)
	if portrait is TextureRect:
		return get_source_path_for_texture_rect(portrait)
	return ""


func get_source_path_for_model(model) -> String:
	return _as_valid_card_art_source(_extract_model_portrait_path(model))


func _get_model_or_inspect_source_path(node) -> String:
	var ancestor = node
	while ancestor != null:
		var model = ancestor.get("Model")
		var model_path = _as_valid_card_art_source(_extract_model_portrait_path(model))
		if model_path != "":
			return model_path
		if ancestor.has_meta(META_INSPECT_SOURCE_PATH):
			var inspect_source = _as_valid_card_art_source(String(ancestor.get_meta(META_INSPECT_SOURCE_PATH, "")))
			if inspect_source != "":
				return inspect_source
		ancestor = ancestor.get_parent()
	return ""


func is_valid_card_source_path(source_path: String) -> bool:
	return _as_valid_card_art_source(source_path) != ""


func get_target_size_for_source_path(source_path: String) -> Vector2i:
	source_path = _as_valid_card_art_source(source_path)
	if source_path == "":
		return DEFAULT_LANDSCAPE_SIZE

	var manifest_entry = _manifest.get(_canonicalize_source_key(source_path), null)
	if manifest_entry is Dictionary and manifest_entry.has("width") and manifest_entry.has("height"):
		return Vector2i(int(manifest_entry["width"]), int(manifest_entry["height"]))

	var size_probe_path = _get_preferred_size_probe_path(source_path)
	if size_probe_path != "" and ResourceLoader.exists(size_probe_path):
		var texture = load(size_probe_path)
		if texture is Texture2D:
			return Vector2i(texture.get_width(), texture.get_height())

	if source_path.contains("ancient"):
		return DEFAULT_PORTRAIT_SIZE

	return DEFAULT_LANDSCAPE_SIZE


func _get_preferred_size_probe_path(source_path: String) -> String:
	var normalized = _normalize_source_path(source_path)
	if normalized == "" or !_looks_like_card_art_source(normalized):
		return ""
	if normalized.contains("/card_portraits/big/"):
		return normalized
	if normalized.contains("/card_portraits/") and !normalized.contains("/card_portraits/beta/"):
		var big_candidate = normalized.replace("/card_portraits/", "/card_portraits/big/")
		if ResourceLoader.exists(big_candidate):
			return big_candidate
	return normalized


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


func _load_source_texture(source_path: String):
	source_path = _as_valid_card_art_source(source_path)
	if source_path == "":
		return null
	if source_path.begins_with("res://") and !ResourceLoader.exists(source_path):
		return null
	if source_path.begins_with("user://") and !FileAccess.file_exists(ProjectSettings.globalize_path(source_path)):
		return null
	var texture = load(source_path)
	return texture if texture is Texture2D else null


func export_source_image_to_png(source_path: String, export_path: String) -> Dictionary:
	source_path = _canonicalize_source_key(source_path)
	if source_path == "":
		return {
			"ok": false,
			"message": "No card art is selected."
		}
	var image = null
	var exported_animated_frame = false
	var entry = _manifest.get(source_path, null)
	if entry is Dictionary:
		var display_mode = String(entry.get("display_mode", DISPLAY_MODE_DEFAULT))
		if _is_animated_entry(entry):
			var frame_paths = entry.get("source_frame_paths", entry.get("frame_paths", [])) if display_mode == DISPLAY_MODE_FULL_ART else entry.get("frame_paths", [])
			if frame_paths is Array and !frame_paths.is_empty():
				image = load_image_from_file(ProjectSettings.globalize_path(String(frame_paths[0])))
				if image != null and display_mode == DISPLAY_MODE_FULL_ART:
					image = trim_transparent_margins(image)
					image = build_full_art_preview(source_path, image, Vector2i.ZERO, FULL_ART_ANIMATED_ZOOM_BOOST)
				exported_animated_frame = true
		else:
			var image_path = ""
			if display_mode == DISPLAY_MODE_FULL_ART:
				image_path = String(entry.get("edit_source_path", entry.get("override_path", "")))
			else:
				image_path = String(entry.get("override_path", entry.get("edit_source_path", "")))
			if image_path != "":
				image = load_image_from_file(ProjectSettings.globalize_path(image_path))
				if image != null and display_mode == DISPLAY_MODE_FULL_ART:
					image = build_full_art_preview(source_path, image)
	if image == null:
		image = get_source_image(source_path)
	if image == null:
		return {
			"ok": false,
			"message": "Could not load the current card image."
		}
	var normalized_export_path = export_path
	if !normalized_export_path.to_lower().ends_with(".png"):
		normalized_export_path += ".png"
	if image.save_png(normalized_export_path) != OK:
		return {
			"ok": false,
			"message": "Failed to save the PNG file."
		}
	return {
		"ok": true,
		"message": "Saved the current custom card image as PNG." if !exported_animated_frame else "Saved the first frame of the current custom animated card image as PNG."
	}


func _build_card_source_index() -> Dictionary:
	var exact_map := {}
	var basename_map := {}
	var normalized_map := {}
	var preferred_basename_map := {}
	var sources: Array = []
	var source_paths: Array = []
	_collect_card_source_paths(MANAGED_TEXTURE_PREFIX.trim_suffix("/"), source_paths)
	for source_path in source_paths:
		var normalized_source = String(source_path).replace("\\", "/")
		var key_exact = normalized_source.trim_prefix(MANAGED_TEXTURE_PREFIX).trim_suffix(".png").to_lower()
		if key_exact != "":
			exact_map[key_exact] = normalized_source
		var basename = normalized_source.get_file().get_basename().to_lower()
		if basename == "":
			continue
		if !basename_map.has(basename):
			basename_map[basename] = []
		(basename_map[basename] as Array).append(normalized_source)
		if !preferred_basename_map.has(basename):
			preferred_basename_map[basename] = normalized_source
		elif String(preferred_basename_map[basename]).find("/beta/") >= 0 and normalized_source.find("/beta/") < 0:
			preferred_basename_map[basename] = normalized_source
		var normalized_name = _normalize_card_match_key(basename)
		if normalized_name != "":
			if !normalized_map.has(normalized_name):
				normalized_map[normalized_name] = []
			(normalized_map[normalized_name] as Array).append(normalized_source)
		sources.append({
			"source_path": normalized_source,
			"basename": basename,
			"tokens": _tokenize_card_match_key(basename)
		})
	return {
		"exact": exact_map,
		"basename": basename_map,
		"preferred_basename": preferred_basename_map,
		"normalized": normalized_map,
		"sources": sources
	}


func _get_managed_source_index_cached() -> Dictionary:
	if _managed_source_index_cache.is_empty():
		_managed_source_index_cache = _build_card_source_index()
	return _managed_source_index_cache


func _canonicalize_managed_card_source_path(path: String) -> String:
	if path == "":
		return ""
	var normalized_path = path.replace("\\", "/").to_lower()
	var marker = "/card_portraits/"
	var marker_index = normalized_path.find(marker)
	if marker_index < 0:
		return ""
	var relative_key = normalized_path.substr(marker_index + marker.length())
	relative_key = relative_key.trim_suffix(".png").trim_suffix(".jpg").trim_suffix(".jpeg").trim_suffix(".webp").trim_suffix(".gif")
	if relative_key == "":
		return ""
	var managed_source_path = _resolve_source_path_from_relative_card_key(relative_key)
	if managed_source_path != "":
		return managed_source_path
	if normalized_path.contains("/modchar/") and normalized_path.contains("/card/"):
		var basename = normalized_path.get_file().get_basename()
		var direct_source_path = _resolve_source_path_from_basename(basename)
		if direct_source_path != "":
			return direct_source_path
	return ""


func _resolve_source_path_from_relative_card_key(relative_key: String) -> String:
	if relative_key == "":
		return ""
	var normalized_key = relative_key.replace("\\", "/").to_lower()
	normalized_key = normalized_key.trim_prefix("/")
	normalized_key = normalized_key.trim_suffix(".png").trim_suffix(".jpg").trim_suffix(".jpeg").trim_suffix(".webp").trim_suffix(".gif")
	if normalized_key == "":
		return ""
	var source_index = _get_managed_source_index_cached()
	var exact_map = source_index.get("exact", {})
	if exact_map is Dictionary and (exact_map as Dictionary).has(normalized_key):
		return String((exact_map as Dictionary)[normalized_key])
	var candidates: Array = []
	candidates.append("%s%s.png" % [MANAGED_TEXTURE_PREFIX, normalized_key])
	var slash_index = normalized_key.find("/")
	if slash_index > 0:
		var first_folder = normalized_key.substr(0, slash_index)
		var rest = normalized_key.substr(slash_index + 1)
		if rest.begins_with("beta/"):
			candidates.append("%s%s/%s.png" % [MANAGED_TEXTURE_PREFIX, first_folder, rest.trim_prefix("beta/")])
		else:
			candidates.append("%s%s/beta/%s.png" % [MANAGED_TEXTURE_PREFIX, first_folder, rest])
	for candidate in candidates:
		if ResourceLoader.exists(String(candidate)):
			return String(candidate)
	var basename = normalized_key.get_file().get_basename()
	return _resolve_source_path_from_basename(basename)


func _resolve_source_path_from_imported_texture_path(path: String) -> String:
	var normalized_path = path.replace("\\", "/").to_lower()
	if !normalized_path.begins_with("res://.godot/imported/"):
		return ""
	var file_name = normalized_path.get_file()
	for marker in [".png-", ".jpg-", ".jpeg-", ".webp-", ".gif-"]:
		var marker_index = file_name.find(marker)
		if marker_index < 0:
			continue
		var basename = file_name.substr(0, marker_index).get_basename()
		var source_path = _resolve_source_path_from_basename(basename)
		if source_path != "":
			return source_path
	return ""


func _canonicalize_source_key(source_path: String) -> String:
	if _is_invalid_source_path_text(source_path):
		return ""
	var normalized = _normalize_source_path(source_path)
	if normalized == "":
		return source_path
	var stock_reskin_alias = _resolve_stock_reskin_source_alias(normalized)
	return stock_reskin_alias if stock_reskin_alias != "" else normalized


func _resolve_stock_reskin_source_alias(source_path: String) -> String:
	var normalized_path = source_path.replace("\\", "/")
	var lower_path = normalized_path.to_lower()
	if !lower_path.begins_with("res://") or lower_path.begins_with(MANAGED_TEXTURE_PREFIX):
		return ""
	if _stock_reskin_source_alias_cache.has(lower_path):
		return String(_stock_reskin_source_alias_cache[lower_path])

	var marker := "/card_portraits/"
	var marker_index = lower_path.find(marker)
	if marker_index < 0:
		_remember_stock_reskin_source_alias(lower_path, "")
		return ""
	var relative_path = normalized_path.substr(marker_index + marker.length())
	var path_parts = relative_path.split("/", false)
	if path_parts.size() < 2:
		_remember_stock_reskin_source_alias(lower_path, "")
		return ""

	var category = String(path_parts[0]).to_lower()
	if !CARD_PORTRAIT_FOLDERS.has(category):
		_remember_stock_reskin_source_alias(lower_path, "")
		return ""
	var uses_beta_folder = path_parts.size() >= 3 and String(path_parts[1]).to_lower() == "beta"
	var basename = String(path_parts[path_parts.size() - 1]).get_basename()
	var candidate_names: Array[String] = []
	for candidate_name in [basename.to_lower(), _camel_to_snake_case_match_key(basename)]:
		var normalized_name = String(candidate_name).trim_prefix("_").trim_suffix("_")
		if normalized_name != "" and !candidate_names.has(normalized_name):
			candidate_names.append(normalized_name)

	for candidate_name in candidate_names:
		var relative_candidate = "%s/beta/%s.png" % [category, candidate_name] if uses_beta_folder else "%s/%s.png" % [category, candidate_name]
		var stock_source_path = "%s%s" % [MANAGED_TEXTURE_PREFIX, relative_candidate]
		if ResourceLoader.exists(stock_source_path):
			_remember_stock_reskin_source_alias(lower_path, stock_source_path)
			return stock_source_path
	var unique_basename_alias = _resolve_unique_managed_source_from_basenames(candidate_names)
	if unique_basename_alias != "":
		_remember_stock_reskin_source_alias(lower_path, unique_basename_alias)
		return unique_basename_alias
	_remember_stock_reskin_source_alias(lower_path, "")
	return ""


func _remember_stock_reskin_source_alias(cache_key: String, source_path: String) -> void:
	if _stock_reskin_source_alias_cache.size() >= MODEL_PORTRAIT_PATH_CACHE_LIMIT:
		_stock_reskin_source_alias_cache.clear()
	_stock_reskin_source_alias_cache[cache_key] = source_path


func _resolve_unique_managed_source_from_basenames(candidate_names: Array[String]) -> String:
	for candidate_name in candidate_names:
		var standard_matches: Array[String] = []
		var beta_matches: Array[String] = []
		for category in CARD_PORTRAIT_FOLDERS:
			var standard_candidate = "%s%s/%s.png" % [MANAGED_TEXTURE_PREFIX, category, candidate_name]
			if ResourceLoader.exists(standard_candidate):
				standard_matches.append(standard_candidate)
			var beta_candidate = "%s%s/beta/%s.png" % [MANAGED_TEXTURE_PREFIX, category, candidate_name]
			if ResourceLoader.exists(beta_candidate):
				beta_matches.append(beta_candidate)
		if standard_matches.size() == 1:
			return standard_matches[0]
		if standard_matches.is_empty() and beta_matches.size() == 1:
			return beta_matches[0]
	return ""


func _as_valid_card_art_source(source_path: String) -> String:
	var normalized = _normalize_source_path(source_path)
	if normalized == "" or !_looks_like_card_art_source(normalized):
		return ""
	return normalized


func _collect_card_source_paths(dir_path: String, output: Array) -> void:
	var dir = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var entry_name = dir.get_next()
		if entry_name == "":
			break
		if entry_name == "." or entry_name == "..":
			continue
		var full_path = dir_path.path_join(entry_name)
		if dir.current_is_dir():
			_collect_card_source_paths(full_path, output)
		elif entry_name.get_extension().to_lower() == "png":
			output.append(full_path)
	dir.list_dir_end()


func _collect_mod_image_paths(dir_path: String, output: Array) -> void:
	var dir = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var entry_name = dir.get_next()
		if entry_name == "":
			break
		if entry_name == "." or entry_name == "..":
			continue
		var full_path = dir_path.path_join(entry_name)
		if dir.current_is_dir():
			_collect_mod_image_paths(full_path, output)
		elif MOD_IMPORT_IMAGE_EXTENSIONS.has(entry_name.get_extension().to_lower()):
			output.append(full_path)
	dir.list_dir_end()


func _resolve_mod_pck_path(mod_root: String, mod_id: String, import_path: String) -> String:
	var candidates: Array = []
	if mod_id != "":
		candidates.append(mod_root.path_join("%s.pck" % mod_id))
	var import_basename = import_path.get_file().get_basename()
	if import_basename != "":
		candidates.append(mod_root.path_join("%s.pck" % import_basename))
	var dir = DirAccess.open(mod_root)
	if dir != null:
		dir.list_dir_begin()
		while true:
			var entry_name = dir.get_next()
			if entry_name == "":
				break
			if dir.current_is_dir():
				continue
			if entry_name.get_extension().to_lower() == "pck":
				candidates.append(mod_root.path_join(entry_name))
		dir.list_dir_end()
	for candidate in candidates:
		if FileAccess.file_exists(String(candidate)):
			return String(candidate)
	return ""


func _extract_pck_images(pck_path: String) -> Dictionary:
	var output_result = _prepare_pck_extract_output_dir(pck_path)
	if !bool(output_result.get("ok", false)):
		return output_result
	var output_dir = String(output_result.get("output_dir", ""))
	var save_notice = String(output_result.get("save_notice", ""))

	var parse_result = _parse_pck_entries(pck_path)
	if !bool(parse_result.get("ok", false)):
		return {
			"ok": false,
			"message": String(parse_result.get("message", "PCK image extraction failed."))
		}

	var context = {
		"pck_path": pck_path,
		"output_dir": output_dir,
		"entries": parse_result.get("entries", []),
		"candidate_paths": _collect_candidate_paths_from_pck_binary(pck_path)
	}
	var strategy_result = _run_pck_extract_strategies(context)
	_write_pck_extract_metadata(output_dir, strategy_result, context)

	return {
		"ok": true,
		"temp_dir": output_dir,
		"saved_dir": output_dir,
		"save_notice": save_notice
	}


func _prepare_pck_extract_output_dir(pck_path: String) -> Dictionary:
	var preferred_output_dir = _get_pictures_extract_output_dir(pck_path)
	var output_dir = preferred_output_dir
	var save_notice = ""
	if output_dir != "":
		DirAccess.make_dir_recursive_absolute(output_dir)
		if !DirAccess.dir_exists_absolute(output_dir):
			save_notice = "Could not create the game mod extraction folder: %s" % output_dir
			output_dir = ""
	if output_dir == "":
		output_dir = ProjectSettings.globalize_path("%s/%s_%d" % [
			STORAGE_PCK_TEMP_DIR,
			_safe_file_stem(pck_path.get_file()),
			Time.get_ticks_msec()
		])
		DirAccess.make_dir_recursive_absolute(output_dir)
		if !DirAccess.dir_exists_absolute(output_dir):
			return {
				"ok": false,
				"message": "Failed to create any extraction folder.%s" % (" %s" % save_notice if save_notice != "" else "")
			}
	return {
		"ok": true,
		"output_dir": output_dir,
		"save_notice": save_notice
	}


func _run_pck_extract_strategies(context: Dictionary) -> Dictionary:
	var strategies: Array = [
		{"name": "pck_entries", "callable": Callable(self, "_extract_images_from_pck_entries")},
		{"name": "embedded_webp", "callable": Callable(self, "_extract_images_from_embedded_webp")}
	]
	var exported_files: Array = []
	var strategy_results: Array = []

	for strategy in strategies:
		var strategy_name = String((strategy as Dictionary).get("name", "unknown"))
		var strategy_callable = (strategy as Dictionary).get("callable")
		if !(strategy_callable is Callable):
			continue
		var result = (strategy_callable as Callable).call(context)
		var files = result.get("files", [])
		var exported_count := 0
		if files is Array:
			for file_path in files:
				exported_files.append(String(file_path))
			exported_count = files.size()
		strategy_results.append({
			"name": strategy_name,
			"count": exported_count
		})
		if exported_count > 0:
			break

	return {
		"count": exported_files.size(),
		"files": exported_files,
		"strategies": strategy_results
	}


func _extract_images_from_pck_entries(context: Dictionary) -> Dictionary:
	var pck_path = String(context.get("pck_path", ""))
	var output_dir = String(context.get("output_dir", ""))
	var entries = context.get("entries", [])
	var exported_files: Array = []
	if entries is Array:
		for entry in entries:
			if _export_pck_image_entry(pck_path, entry, output_dir):
				exported_files.append(String((entry as Dictionary).get("path", "")))
	return {
		"files": exported_files
	}


func _extract_images_from_embedded_webp(context: Dictionary) -> Dictionary:
	return _extract_embedded_webp_images(
		String(context.get("pck_path", "")),
		String(context.get("output_dir", ""))
	)


func _write_pck_extract_metadata(output_dir: String, strategy_result: Dictionary, context: Dictionary) -> void:
	var metadata_path = output_dir.path_join("metadata.json")
	var metadata_file = FileAccess.open(metadata_path, FileAccess.WRITE)
	if metadata_file == null:
		return
	var entries = context.get("entries", [])
	var candidate_paths = context.get("candidate_paths", [])
	var exported_files = strategy_result.get("files", [])
	var strategies = strategy_result.get("strategies", [])
	metadata_file.store_string(JSON.stringify({
		"saved_dir": output_dir,
		"count": int(strategy_result.get("count", 0)),
		"entry_count": entries.size() if entries is Array else 0,
		"candidate_count": candidate_paths.size() if candidate_paths is Array else 0,
		"files": exported_files,
		"strategies": strategies,
		"sample_candidates": candidate_paths.slice(0, min(20, candidate_paths.size())) if candidate_paths is Array else []
	}, "\t"))


func _get_pictures_extract_output_dir(pck_path: String) -> String:
	var pictures_dir = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	if pictures_dir == "":
		var user_profile = OS.get_environment("USERPROFILE")
		if user_profile != "":
			pictures_dir = user_profile.path_join("Pictures")
	if pictures_dir == "":
		return ""
	return pictures_dir.path_join(PICTURES_EXTRACT_SUBDIR).path_join("%s_%d" % [
		_safe_file_stem(pck_path.get_file()),
		Time.get_ticks_msec()
	])


func _parse_pck_entries(pck_path: String) -> Dictionary:
	var file = FileAccess.open(pck_path, FileAccess.READ)
	if file == null:
		return {
			"ok": false,
			"message": "Could not open the selected PCK file."
		}
	if file.get_length() < 4:
		return {
			"ok": false,
			"message": "The selected PCK file is too small to be valid."
		}
	if file.get_32() != PCK_MAGIC:
		return {
			"ok": false,
			"message": "The selected file is not a supported Godot PCK archive."
		}

	for _index in range(PCK_HEADER_VERSION_FIELDS):
		file.get_32()
	for _index in range(PCK_HEADER_RESERVED_FIELDS):
		file.get_32()

	if file.get_position() + 4 > file.get_length():
		return {
			"ok": false,
			"message": "The PCK header ended unexpectedly."
		}

	var file_count = file.get_32()
	var entries: Array = []
	for _index in range(file_count):
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

	return {
		"ok": true,
		"entries": entries
	}


func _extract_embedded_webp_images(pck_path: String, output_dir: String) -> Dictionary:
	var bytes = FileAccess.get_file_as_bytes(pck_path)
	if bytes.is_empty():
		return {"count": 0, "files": []}
	var ordered_names = _collect_ordered_card_names_from_pck_binary(bytes)
	var webp_chunks = _collect_embedded_webp_chunks(bytes)
	if webp_chunks.is_empty():
		return {"count": 0, "files": []}
	var export_chunks = _select_webp_chunks_for_export(webp_chunks, ordered_names.size())
	var extracted_files: Array = []
	for chunk_index in range(export_chunks.size()):
		var chunk = export_chunks[chunk_index]
		var index = int((chunk as Dictionary).get("offset", -1))
		var total_size = int((chunk as Dictionary).get("size", 0))
		if index < 0 or total_size <= 12 or index + total_size > bytes.size():
			continue
		var file_name = "embedded_%03d.webp" % chunk_index
		if chunk_index < ordered_names.size():
			var sequential_name = String(ordered_names[chunk_index])
			if sequential_name != "":
				file_name = "%s.webp" % sequential_name
		var output_path = output_dir.path_join(file_name)
		DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
		var out_file = FileAccess.open(output_path, FileAccess.WRITE)
		if out_file != null:
			out_file.store_buffer(bytes.slice(index, index + total_size))
			extracted_files.append(output_path)
	return {
		"count": extracted_files.size(),
		"files": extracted_files
	}


func _collect_embedded_webp_chunks(bytes: PackedByteArray) -> Array:
	var chunks: Array = []
	var index := 0
	while index <= bytes.size() - 12:
		var is_riff = bytes[index] == 0x52 and bytes[index + 1] == 0x49 and bytes[index + 2] == 0x46 and bytes[index + 3] == 0x46
		var is_webp = bytes[index + 8] == 0x57 and bytes[index + 9] == 0x45 and bytes[index + 10] == 0x42 and bytes[index + 11] == 0x50
		if !is_riff or !is_webp:
			index += 1
			continue
		var riff_size = bytes[index + 4] | (bytes[index + 5] << 8) | (bytes[index + 6] << 16) | (bytes[index + 7] << 24)
		var total_size = int(riff_size) + 8
		if total_size <= 12 or index + total_size > bytes.size():
			index += 1
			continue
		chunks.append({
			"offset": index,
			"size": total_size
		})
		index += total_size
	return chunks


func _select_webp_chunks_for_export(chunks: Array, expected_named_count: int) -> Array:
	if chunks.is_empty():
		return []
	if expected_named_count <= 0 or chunks.size() <= expected_named_count:
		return chunks

	var grouped_chunks: Array = []
	var current_group: Array = [chunks[0]]
	var previous_size = int((chunks[0] as Dictionary).get("size", 0))
	for index in range(1, chunks.size()):
		var chunk = chunks[index]
		var chunk_size = int((chunk as Dictionary).get("size", 0))
		if chunk_size > previous_size:
			grouped_chunks.append(current_group)
			current_group = [chunk]
		else:
			current_group.append(chunk)
		previous_size = chunk_size
	if !current_group.is_empty():
		grouped_chunks.append(current_group)

	if grouped_chunks.size() >= expected_named_count and grouped_chunks.size() <= expected_named_count + 4:
		var selected: Array = []
		for group in grouped_chunks:
			if group is Array and !group.is_empty():
				selected.append(group[0])
		return selected

	return chunks


func _collect_ordered_card_names_from_pck_binary(bytes: PackedByteArray) -> Array:
	var ordered: Array = []
	var seen := {}
	var printable_strings = _extract_printable_pck_strings(bytes)
	for strategy in _get_pck_card_name_extract_strategies():
		var regex = _compile_pck_card_name_regex(String((strategy as Dictionary).get("pattern", "")))
		if regex == null:
			continue
		_extract_card_names_from_printable_strings(
			printable_strings,
			regex,
			bool((strategy as Dictionary).get("camel_to_snake", true)),
			ordered,
			seen
		)
	return ordered


func _get_pck_card_name_extract_strategies() -> Array:
	return [
		{
			"name": "megacrit_cards_namespace",
			"pattern": "MegaCrit\\.Sts2\\.Core\\.Models\\.Cards\\.([A-Za-z0-9]+)\\.png",
			"camel_to_snake": true
		},
		{
			"name": "godot_imported_ctex",
			"pattern": "res://\\.godot/imported/([A-Za-z0-9_]+)\\.png-[0-9a-f]+\\.ctex",
			"camel_to_snake": true
		},
		{
			"name": "card_portraits_path",
			"pattern": "res://[^\\s\\x00]*/card_portraits/[^\\s\\x00]*/([A-Za-z0-9_]+)\\.png",
			"camel_to_snake": true
		}
	]


func _compile_pck_card_name_regex(pattern: String) -> Variant:
	if pattern == "":
		return null
	var regex = RegEx.new()
	if regex.compile(pattern) != OK:
		return null
	return regex


func _extract_card_names_from_printable_strings(printable_strings: Array, regex: RegEx, camel_to_snake: bool, ordered: Array, seen: Dictionary) -> void:
	for printable in printable_strings:
		var text = String(printable)
		var local_matches = regex.search_all(text)
		for match in local_matches:
			var raw_name = String(match.get_string(1))
			var resolved_name = _camel_to_snake_case_match_key(raw_name) if camel_to_snake else raw_name.strip_edges().to_lower()
			if resolved_name == "" or seen.has(resolved_name):
				continue
			seen[resolved_name] = true
			ordered.append(resolved_name)


func _normalize_pck_entry_path(path: String) -> String:
	var normalized = path.replace("\\", "/").strip_edges()
	if normalized.begins_with("res://"):
		return normalized
	return "res://%s" % normalized.trim_prefix("/")


func _collect_candidate_paths_from_pck_binary(pck_path: String) -> Array:
	var data = FileAccess.get_file_as_bytes(pck_path)
	if data.is_empty():
		return []
	var strings = _extract_printable_pck_strings(data)
	var paths := {}
	for text in strings:
		var lower_text = text.to_lower()
		for extension in [".png", ".jpg", ".jpeg", ".webp", ".gif", ".png.import", ".jpg.import", ".jpeg.import", ".webp.import", ".gif.import"]:
			if lower_text.ends_with(extension):
				paths[_normalize_pck_entry_path(text)] = true
				break
	return paths.keys()


func _extract_printable_pck_strings(data: PackedByteArray) -> Array:
	var results: Array = []
	var current := PackedByteArray()
	for byte in data:
		var is_printable = (byte >= 48 and byte <= 57) or (byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122) or byte == 46 or byte == 47 or byte == 58 or byte == 95 or byte == 45
		if is_printable:
			current.append(byte)
			continue
		if current.size() >= 8:
			results.append(current.get_string_from_ascii())
		current = PackedByteArray()
	if current.size() >= 8:
		results.append(current.get_string_from_ascii())
	return results


func _export_pck_image_entry(pck_path: String, entry: Dictionary, output_dir: String) -> bool:
	var entry_path = String(entry.get("path", ""))
	if entry_path == "":
		return false
	var extension = entry_path.get_extension().to_lower()
	if !MOD_IMPORT_IMAGE_EXTENSIONS.has(extension):
		return false
	var bytes = _read_pck_entry_bytes(pck_path, entry)
	if bytes.is_empty():
		return false
	var output_path = output_dir.path_join(entry_path.trim_prefix("res://"))
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var out_file = FileAccess.open(output_path, FileAccess.WRITE)
	if out_file == null:
		return false
	out_file.store_buffer(bytes)
	return true


func _read_pck_entry_bytes(pck_path: String, entry: Dictionary) -> PackedByteArray:
	var file = FileAccess.open(pck_path, FileAccess.READ)
	if file == null:
		return PackedByteArray()
	var offset = int(entry.get("offset", 0))
	var size = int(entry.get("size", 0))
	if offset < 0 or size <= 0 or offset + size > file.get_length():
		return PackedByteArray()
	file.seek(offset)
	return file.get_buffer(size)


func _match_card_source_for_mod_image(image_path: String, source_index: Dictionary) -> Dictionary:
	var original_path = image_path.replace("\\", "/")
	var normalized_path = original_path.to_lower()
	var exact_map = source_index.get("exact", {})
	var basename_map = source_index.get("basename", {})
	var preferred_basename_map = source_index.get("preferred_basename", {})
	var normalized_map = source_index.get("normalized", {})
	var sources = source_index.get("sources", [])
	var card_portraits_marker = "/card_portraits/"
	var marker_index = normalized_path.find(card_portraits_marker)
	if marker_index >= 0:
		var relative_key = normalized_path.substr(marker_index + card_portraits_marker.length()).trim_suffix(".png").trim_suffix(".jpg").trim_suffix(".jpeg").trim_suffix(".webp").trim_suffix(".gif")
		if exact_map is Dictionary and (exact_map as Dictionary).has(relative_key):
			return {"source_path": (exact_map as Dictionary)[relative_key], "ambiguous": false}
	var basename = original_path.get_file().get_basename().to_lower()
	var original_basename = original_path.get_file().get_basename()
	if preferred_basename_map is Dictionary and (preferred_basename_map as Dictionary).has(basename):
		return {"source_path": (preferred_basename_map as Dictionary)[basename], "ambiguous": false}
	var direct_source_path = _resolve_source_path_from_basename(basename)
	if direct_source_path != "":
		return {"source_path": direct_source_path, "ambiguous": false}
	if basename_map is Dictionary and (basename_map as Dictionary).has(basename):
		var matches = (basename_map as Dictionary)[basename]
		if matches is Array and !matches.is_empty():
			return {"source_path": _pick_preferred_source_match(matches, _tokenize_card_match_key(original_basename)), "ambiguous": false}
	var basename_tail = basename.get_slice(".", basename.get_slice_count(".") - 1).to_lower()
	var original_basename_tail = original_basename.get_slice(".", original_basename.get_slice_count(".") - 1)
	if basename_tail != "" and basename_map is Dictionary and (basename_map as Dictionary).has(basename_tail):
		var tail_matches = (basename_map as Dictionary)[basename_tail]
		if tail_matches is Array and !tail_matches.is_empty():
			return {"source_path": _pick_preferred_source_match(tail_matches, _tokenize_card_match_key(original_basename_tail)), "ambiguous": false}
	var direct_snake_tail = _camel_to_snake_case_match_key(original_basename_tail)
	if direct_snake_tail != "" and basename_map is Dictionary and (basename_map as Dictionary).has(direct_snake_tail):
		var direct_tail_matches = (basename_map as Dictionary)[direct_snake_tail]
		if direct_tail_matches is Array and !direct_tail_matches.is_empty():
			return {"source_path": _pick_preferred_source_match(direct_tail_matches, _tokenize_card_match_key(direct_snake_tail)), "ambiguous": false}
	var direct_snake_full = _camel_to_snake_case_match_key(original_basename)
	if direct_snake_full != "" and basename_map is Dictionary and (basename_map as Dictionary).has(direct_snake_full):
		var direct_full_matches = (basename_map as Dictionary)[direct_snake_full]
		if direct_full_matches is Array and !direct_full_matches.is_empty():
			return {"source_path": _pick_preferred_source_match(direct_full_matches, _tokenize_card_match_key(direct_snake_full)), "ambiguous": false}
	var snake_case_candidates: Array = []
	snake_case_candidates.append(_camel_to_snake_case_match_key(original_basename))
	if original_basename_tail != "" and original_basename_tail.to_lower() != original_basename.to_lower():
		snake_case_candidates.append(_camel_to_snake_case_match_key(original_basename_tail))
	for candidate_basename in snake_case_candidates:
		if candidate_basename == "":
			continue
		if basename_map is Dictionary and (basename_map as Dictionary).has(candidate_basename):
			var snake_matches = (basename_map as Dictionary)[candidate_basename]
			if snake_matches is Array and snake_matches.size() == 1:
				return {"source_path": snake_matches[0], "ambiguous": false}
			if snake_matches is Array and snake_matches.size() > 1:
				return {"source_path": "", "ambiguous": true}
	var normalized_candidates: Array = []
	normalized_candidates.append(_normalize_card_match_key(basename))
	if basename_tail != "" and basename_tail != basename:
		normalized_candidates.append(_normalize_card_match_key(basename_tail))
	for candidate_basename in snake_case_candidates:
		if candidate_basename != "":
			normalized_candidates.append(_normalize_card_match_key(candidate_basename))
	for candidate_key in normalized_candidates:
		if candidate_key == "":
			continue
		if normalized_map is Dictionary and (normalized_map as Dictionary).has(candidate_key):
			var normalized_matches = (normalized_map as Dictionary)[candidate_key]
			if normalized_matches is Array and normalized_matches.size() == 1:
				return {"source_path": normalized_matches[0], "ambiguous": false}
			if normalized_matches is Array and normalized_matches.size() > 1:
				return {"source_path": "", "ambiguous": true}
	var token_candidates: Array = []
	token_candidates.append_array(_tokenize_card_match_key(original_basename))
	token_candidates.append_array(_tokenize_card_match_key(original_basename_tail))
	for candidate_basename in snake_case_candidates:
		token_candidates.append_array(_tokenize_card_match_key(candidate_basename))
	var best_score := 0.0
	var best_source_path := ""
	var best_count := 0
	if sources is Array:
		for source_entry in sources:
			if !(source_entry is Dictionary):
				continue
			var source_tokens = source_entry.get("tokens", [])
			if !(source_tokens is Array):
				continue
			var score = _compute_token_match_score(token_candidates, source_tokens)
			if score > best_score + 0.001:
				best_score = score
				best_source_path = String((source_entry as Dictionary).get("source_path", ""))
				best_count = 1
			elif abs(score - best_score) <= 0.001 and score > 0.0:
				best_count += 1
	if best_score >= 0.99 and best_count == 1:
		return {"source_path": best_source_path, "ambiguous": false}
	if best_score >= 0.99 and best_count > 1:
		return {"source_path": "", "ambiguous": true}
	return {"source_path": "", "ambiguous": false}


func _pick_preferred_source_match(matches: Array, preferred_tokens: Array) -> String:
	if matches.is_empty():
		return ""
	var best_path = String(matches[0])
	var best_score := -1000
	for match_path in matches:
		var path = String(match_path)
		var score := 0
		if path.find("/beta/") < 0:
			score += 10
		for token in preferred_tokens:
			if path.to_lower().find("/%s/" % String(token).to_lower()) >= 0:
				score += 5
		if score > best_score:
			best_score = score
			best_path = path
	return best_path


func _resolve_source_path_from_basename(basename: String) -> String:
	if basename == "":
		return ""
	var direct_candidates: Array = []
	direct_candidates.append("%s%s.png" % [MANAGED_TEXTURE_PREFIX, basename])
	for folder in CARD_PORTRAIT_FOLDERS:
		direct_candidates.append("%s%s/%s.png" % [MANAGED_TEXTURE_PREFIX, folder, basename])
		direct_candidates.append("%s%s/beta/%s.png" % [MANAGED_TEXTURE_PREFIX, folder, basename])
	for candidate in direct_candidates:
		if ResourceLoader.exists(String(candidate)):
			return String(candidate)
	return ""


func _normalize_card_match_key(value: String) -> String:
	var lower_value = value.to_lower()
	var result = ""
	for index in range(lower_value.length()):
		var char_code = lower_value.unicode_at(index)
		var is_digit = char_code >= 48 and char_code <= 57
		var is_lower = char_code >= 97 and char_code <= 122
		if is_digit or is_lower:
			result += char(lower_value.unicode_at(index))
	return result


func _camel_to_snake_case_match_key(value: String) -> String:
	if value == "":
		return ""
	var source = value.replace("-", "_").replace(" ", "_")
	var result = ""
	for index in range(source.length()):
		var character = source.substr(index, 1)
		var char_code = source.unicode_at(index)
		var is_upper = char_code >= 65 and char_code <= 90
		var is_lower = char_code >= 97 and char_code <= 122
		var is_digit = char_code >= 48 and char_code <= 57
		if character == ".":
			result += "_"
			continue
		if character == "_":
			if !result.ends_with("_"):
				result += "_"
			continue
		if is_upper:
			var previous_is_word = index > 0 and (source.unicode_at(index - 1) >= 97 and source.unicode_at(index - 1) <= 122 or source.unicode_at(index - 1) >= 48 and source.unicode_at(index - 1) <= 57)
			var next_is_lower = index + 1 < source.length() and (source.unicode_at(index + 1) >= 97 and source.unicode_at(index + 1) <= 122)
			if result != "" and !result.ends_with("_") and (previous_is_word or next_is_lower):
				result += "_"
			result += character.to_lower()
			continue
		if is_lower or is_digit:
			result += character
			continue
	if result.begins_with("_"):
		result = result.trim_prefix("_")
	while result.find("__") >= 0:
		result = result.replace("__", "_")
	return result.trim_suffix("_")


func _tokenize_card_match_key(value: String) -> Array:
	var snake = _camel_to_snake_case_match_key(value)
	if snake == "":
		return []
	var token_map := {}
	for token in snake.split("_", false):
		var clean = String(token).strip_edges().to_lower()
		if clean != "":
			token_map[clean] = true
	return token_map.keys()


func _compute_token_match_score(candidate_tokens: Array, source_tokens: Array) -> float:
	if candidate_tokens.is_empty() or source_tokens.is_empty():
		return 0.0
	var candidate_map := {}
	for token in candidate_tokens:
		var text = String(token).strip_edges().to_lower()
		if text != "":
			candidate_map[text] = true
	var source_map := {}
	for token in source_tokens:
		var text = String(token).strip_edges().to_lower()
		if text != "":
			source_map[text] = true
	if candidate_map.is_empty() or source_map.is_empty():
		return 0.0
	var intersection := 0
	for token in candidate_map.keys():
		if source_map.has(token):
			intersection += 1
	var denominator = max(candidate_map.size(), source_map.size())
	return float(intersection) / float(denominator) if denominator > 0 else 0.0


func save_override_from_file(source_path: String, import_path: String) -> Dictionary:
	source_path = _canonicalize_source_key(source_path)
	if import_path.strip_edges() == "":
		return {
			"ok": false,
			"message": "No file path was received from the file browser."
		}
	var extension = import_path.get_extension().to_lower()
	if extension == "gif":
		return save_gif_override_from_file(source_path, import_path)
	var image = load_image_from_file(import_path)
	if image == null:
		return {
			"ok": false,
			"message": "Could not load the selected image. Some PNG/JPG files use an encoding Godot rejects. Re-save the image in Paint or another editor and try again.\nPath: %s" % import_path
	}
	return save_override_image(source_path, image)


func _build_art_pack_id(pack_name: String) -> String:
	var base = _safe_file_stem(pack_name if pack_name != "" else "art_pack")
	var initial_id = "%s_%s" % [base, str(Time.get_unix_time_from_system())]
	var candidate_id = initial_id
	var suffix := 2
	var packs = _art_pack_registry.get("packs", {})
	while (packs is Dictionary and packs.has(candidate_id)) or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_get_art_pack_dir(candidate_id))):
		candidate_id = "%s_%d" % [initial_id, suffix]
		suffix += 1
	return candidate_id


func _get_art_pack_dir(pack_id: String) -> String:
	return "%s/%s" % [STORAGE_ART_PACK_DIR, pack_id]


func _register_art_pack_static_entry(pack_id: String, source_path: String, image, display_mode: String, edit_source_image = null, adjust_zoom: float = 1.0, adjust_offset_x: float = 0.0, adjust_offset_y: float = 0.0) -> Dictionary:
	var pack_dir = _get_art_pack_dir(pack_id)
	var safe_stem = _safe_file_stem(source_path)
	var override_path = "%s/%s.png" % [pack_dir, safe_stem]
	var edit_source_path = "%s/%s_source.png" % [pack_dir, safe_stem]
	var absolute_override_path = ProjectSettings.globalize_path(override_path)
	var absolute_edit_source_path = ProjectSettings.globalize_path(edit_source_path)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pack_dir))
	if image.save_png(absolute_override_path) != OK:
		return {}
	var image_to_save = edit_source_image if edit_source_image != null else image
	if image_to_save.save_png(absolute_edit_source_path) != OK:
		return {}
	return {
		"type": "static",
		"override_path": override_path,
		"edit_source_path": edit_source_path,
		"display_mode": display_mode,
		"adjust_zoom": adjust_zoom,
		"adjust_offset_x": adjust_offset_x,
		"adjust_offset_y": adjust_offset_y,
		"updated_at": Time.get_datetime_string_from_system()
	}


func _register_art_pack_animated_entry(pack_id: String, source_path: String, images: Array, delays: Array, display_mode: String, source_images: Array = [], source_delays: Array = [], adjust_zoom: float = 1.0, adjust_offset_x: float = 0.0, adjust_offset_y: float = 0.0) -> Dictionary:
	var pack_dir = _get_art_pack_dir(pack_id)
	var safe_stem = _safe_file_stem(source_path)
	var frame_paths: Array = []
	var source_frame_paths: Array = []
	var frame_delays: Array = []
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pack_dir))
	for index in range(images.size()):
		var image = images[index]
		if image == null:
			continue
		var frame_path = "%s/%s_anim_%03d.png" % [pack_dir, safe_stem, index]
		var source_frame_path = "%s/%s_anim_source_%03d.png" % [pack_dir, safe_stem, index]
		if image.save_png(ProjectSettings.globalize_path(frame_path)) != OK:
			continue
		var source_image = source_images[index] if index < source_images.size() and source_images[index] != null else image
		if source_image.save_png(ProjectSettings.globalize_path(source_frame_path)) != OK:
			continue
		frame_paths.append(frame_path)
		source_frame_paths.append(source_frame_path)
		frame_delays.append(max(0.02, float(source_delays[index]) if index < source_delays.size() else float(delays[index]) if index < delays.size() else 0.1))
	if frame_paths.is_empty():
		return {}
	return {
		"type": "animated_gif",
		"frame_paths": frame_paths,
		"source_frame_paths": source_frame_paths,
		"frame_delays": frame_delays,
		"display_mode": display_mode,
		"adjust_zoom": adjust_zoom,
		"adjust_offset_x": adjust_offset_x,
		"adjust_offset_y": adjust_offset_y,
		"updated_at": Time.get_datetime_string_from_system()
	}


func _activate_registered_art_pack_entry(source_path: String, card_entry: Dictionary, pack_id: String, pack_name: String) -> Dictionary:
	source_path = _canonicalize_source_key(source_path)
	var result := {}
	var display_mode = String(card_entry.get("display_mode", DISPLAY_MODE_DEFAULT))
	var adjust_zoom = float(card_entry.get("adjust_zoom", 1.0))
	var adjust_offset_x = float(card_entry.get("adjust_offset_x", 0.0))
	var adjust_offset_y = float(card_entry.get("adjust_offset_y", 0.0))
	if String(card_entry.get("type", "static")) == "animated_gif":
		var frame_paths = card_entry.get("source_frame_paths", card_entry.get("frame_paths", []))
		var frame_delays = card_entry.get("frame_delays", [])
		var images: Array = []
		for frame_path in frame_paths:
			var image = load_image_from_file(ProjectSettings.globalize_path(String(frame_path)))
			if image != null:
				images.append(image)
		result = save_animated_override_images(source_path, images, frame_delays, display_mode)
	else:
		var edit_source_path = String(card_entry.get("edit_source_path", card_entry.get("override_path", "")))
		var source_image = load_image_from_file(ProjectSettings.globalize_path(edit_source_path))
		if source_image == null:
			return {
				"ok": false,
				"message": "The selected art pack image could not be loaded."
			}
		result = save_override_image(source_path, source_image, display_mode)
	if bool(result.get("ok", false)) and (absf(adjust_zoom - 1.0) > 0.001 or absf(adjust_offset_x) > 0.001 or absf(adjust_offset_y) > 0.001):
		result = save_adjusted_override(source_path, adjust_zoom, adjust_offset_x, adjust_offset_y)
	if bool(result.get("ok", false)) and _manifest.has(source_path):
		var manifest_entry = _manifest.get(source_path, null)
		if manifest_entry is Dictionary:
			manifest_entry["provider_type"] = "art_pack"
			manifest_entry["provider_pack_id"] = pack_id
			manifest_entry["provider_pack_name"] = pack_name
			_manifest[source_path] = manifest_entry
			_save_manifest()
	return result


func _begin_batch_updates() -> void:
	_batch_update_depth += 1


func _end_batch_updates() -> void:
	if _batch_update_depth <= 0:
		return
	_batch_update_depth -= 1
	if _batch_update_depth > 0:
		return
	if _batch_manifest_dirty:
		_batch_manifest_dirty = false
		_save_manifest_now()
	if _batch_registry_dirty:
		_batch_registry_dirty = false
		_save_art_pack_registry_now()
	if _batch_refresh_requested:
		_batch_refresh_requested = false
		_needs_full_refresh = true
		_refresh_accumulator = REFRESH_INTERVAL
		_request_ancient_text_hover_refresh(true)
		_request_gif_playback_refresh(true)
	if _batch_art_packs_changed:
		_batch_art_packs_changed = false
		art_packs_changed.emit()
	for source_path in _batched_override_sources.keys():
		overrides_changed.emit(String(source_path))
	_batched_override_sources.clear()


func _notify_override_changed(source_path: String) -> void:
	if _batch_update_depth > 0:
		_batched_override_sources[source_path] = true
		return
	overrides_changed.emit(source_path)


func _clear_art_pack_variants_cache() -> void:
	_art_pack_variants_cache.clear()


func _notify_art_packs_changed() -> void:
	_clear_art_pack_variants_cache()
	if _batch_update_depth > 0:
		_batch_art_packs_changed = true
		return
	art_packs_changed.emit()


func export_bundle_to_file(export_path: String) -> Dictionary:
	if _manifest.is_empty():
		return {
			"ok": false,
			"message": "There are no custom card images to export yet."
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

	var exported_count := 0
	file.store_string("{\"format\":\"card_art_bundle\",\"version\":%d,\"exported_at\":%s,\"overrides\":[" % [
		BUNDLE_VERSION,
		JSON.stringify(Time.get_datetime_string_from_system())
	])
	for source_path in _manifest.keys():
		var entry = _manifest[source_path]
		if !(entry is Dictionary):
			continue
		var bundle_entry = _build_bundle_export_entry(String(source_path), entry)
		if bundle_entry.is_empty():
			continue
		if exported_count > 0:
			file.store_string(",")
		file.store_string(JSON.stringify(bundle_entry))
		exported_count += 1
	file.store_string("],\"count\":%d}" % exported_count)
	file.flush()

	if exported_count <= 0:
		file = null
		DirAccess.remove_absolute(normalized_export_path)
		return {
			"ok": false,
			"message": "The custom images could not be collected for export."
		}

	return {
		"ok": true,
		"message": "Exported %d custom card images into one shareable art pack." % exported_count
	}


func _build_bundle_export_entry(source_path: String, entry: Dictionary) -> Dictionary:
	var bundle_entry = {
		"source_path": source_path,
		"width": int(entry.get("width", 0)),
		"height": int(entry.get("height", 0)),
		"updated_at": String(entry.get("updated_at", "")),
		"type": String(entry.get("type", "static")),
		"display_mode": String(entry.get("display_mode", DISPLAY_MODE_DEFAULT)),
		"adjust_zoom": float(entry.get("adjust_zoom", 1.0)),
		"adjust_offset_x": float(entry.get("adjust_offset_x", 0.0)),
		"adjust_offset_y": float(entry.get("adjust_offset_y", 0.0))
	}
	if _is_animated_entry(entry):
		var frame_paths = entry.get("source_animation_frame_paths", entry.get("source_frame_paths", entry.get("frame_paths", [])))
		var frame_delays = entry.get("source_animation_frame_delays", entry.get("frame_delays", []))
		var frames: Array = []
		for index in range(frame_paths.size()):
			var frame_path = String(frame_paths[index])
			var absolute_frame_path = ProjectSettings.globalize_path(frame_path)
			var image_bytes = FileAccess.get_file_as_bytes(absolute_frame_path)
			if image_bytes.is_empty():
				continue
			frames.append({
				"png_base64": Marshalls.raw_to_base64(image_bytes),
				"delay": float(frame_delays[index]) if index < frame_delays.size() else 0.1
			})
		if frames.is_empty():
			return {}
		bundle_entry["frames"] = frames
		return bundle_entry

	var edit_source_path = String(entry.get("edit_source_path", ""))
	var absolute_edit_source_path = ProjectSettings.globalize_path(edit_source_path)
	var edit_source_bytes = FileAccess.get_file_as_bytes(absolute_edit_source_path)
	if edit_source_bytes.is_empty() and entry.has("override_path"):
		edit_source_path = String(entry["override_path"])
		absolute_edit_source_path = ProjectSettings.globalize_path(edit_source_path)
		edit_source_bytes = FileAccess.get_file_as_bytes(absolute_edit_source_path)
	if edit_source_bytes.is_empty():
		return {}
	bundle_entry["edit_source_png_base64"] = Marshalls.raw_to_base64(edit_source_bytes)
	if entry.has("override_path"):
		var override_path = String(entry["override_path"])
		var absolute_override_path = ProjectSettings.globalize_path(override_path)
		var image_bytes = FileAccess.get_file_as_bytes(absolute_override_path)
		if !image_bytes.is_empty():
			bundle_entry["png_base64"] = Marshalls.raw_to_base64(image_bytes)
	return bundle_entry


func import_bundle_from_file(import_path: String, progress_callback: Callable = Callable(), activation_sources = null) -> Dictionary:
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

	var pack_name = normalized_import_path.get_file().get_basename().trim_suffix(".cardartpack")
	var pack_id = _build_art_pack_id(pack_name)
	var pack_cards := {}
	var registered_count := 0
	var applied_count := 0
	var processed_count := 0
	_begin_batch_updates()
	await _report_import_progress(progress_callback, 0, overrides.size(), "Reading art pack...")
	for override_entry in overrides:
		if !(override_entry is Dictionary):
			continue
		processed_count += 1
		var source_path = _canonicalize_source_key(String(override_entry.get("source_path", "")))
		if source_path == "":
			await _report_import_progress(progress_callback, processed_count, overrides.size(), "")
			continue
		if override_entry.has("frames"):
			var frames = override_entry.get("frames", [])
			if !(frames is Array) or frames.is_empty():
				continue
			var imported_images: Array = []
			var imported_delays: Array = []
			for frame_entry in frames:
				if !(frame_entry is Dictionary):
					continue
				var png_base64 = String(frame_entry.get("png_base64", ""))
				if png_base64 == "":
					continue
				var image_bytes = Marshalls.base64_to_raw(png_base64)
				if image_bytes.is_empty():
					continue
				var image = Image.new()
				if image.load_png_from_buffer(image_bytes) != OK:
					continue
				imported_images.append(image)
				imported_delays.append(float(frame_entry.get("delay", 0.1)))
			var registered_entry = _register_art_pack_animated_entry(
				pack_id,
				source_path,
				imported_images,
				imported_delays,
				String(override_entry.get("display_mode", DISPLAY_MODE_DEFAULT)),
				imported_images,
				imported_delays,
				float(override_entry.get("adjust_zoom", 1.0)),
				float(override_entry.get("adjust_offset_x", 0.0)),
				float(override_entry.get("adjust_offset_y", 0.0))
			)
			if !registered_entry.is_empty():
				pack_cards[source_path] = registered_entry
				registered_count += 1
				if _should_activate_imported_art_pack_source(source_path, activation_sources):
					var animated_result = _activate_registered_art_pack_entry(
						source_path,
						registered_entry,
						pack_id,
						pack_name
					)
					if bool(animated_result.get("ok", false)):
						applied_count += 1
			await _report_import_progress(progress_callback, processed_count, overrides.size(), source_path.get_file())
		else:
			var png_base64 = String(override_entry.get("edit_source_png_base64", override_entry.get("png_base64", "")))
			if png_base64 == "":
				continue
			var image_bytes = Marshalls.base64_to_raw(png_base64)
			if image_bytes.is_empty():
				continue
			var image = Image.new()
			if image.load_png_from_buffer(image_bytes) != OK:
				continue
			var registered_entry = _register_art_pack_static_entry(
				pack_id,
				source_path,
				image,
				String(override_entry.get("display_mode", DISPLAY_MODE_DEFAULT)),
				image,
				float(override_entry.get("adjust_zoom", 1.0)),
				float(override_entry.get("adjust_offset_x", 0.0)),
				float(override_entry.get("adjust_offset_y", 0.0))
			)
			if !registered_entry.is_empty():
				pack_cards[source_path] = registered_entry
				registered_count += 1
				if _should_activate_imported_art_pack_source(source_path, activation_sources):
					var result = _activate_registered_art_pack_entry(
						source_path,
						registered_entry,
						pack_id,
						pack_name
					)
					if bool(result.get("ok", false)):
						applied_count += 1
			await _report_import_progress(progress_callback, processed_count, overrides.size(), source_path.get_file())

	if pack_cards.is_empty():
		_end_batch_updates()
		return {
			"ok": false,
			"message": "No card images from the art pack could be imported."
		}

	var packs = _art_pack_registry.get("packs", {})
	if !(packs is Dictionary):
		packs = {}
	packs[pack_id] = {
		"id": pack_id,
		"name": pack_name,
		"source_file": normalized_import_path,
		"imported_at": Time.get_datetime_string_from_system(),
		"count": pack_cards.size(),
		"cards": pack_cards
	}
	_art_pack_registry["packs"] = packs
	_save_art_pack_registry()
	_notify_art_packs_changed()
	if applied_count > 0:
		refresh_all_portraits()
	_end_batch_updates()
	return {
		"ok": true,
		"message": "Imported %d card images from the shared art pack and registered \"%s\"." % [registered_count, pack_name],
		"pack_id": pack_id,
		"registered_count": registered_count,
		"applied_count": applied_count
	}


func _should_activate_imported_art_pack_source(source_path: String, activation_sources) -> bool:
	if activation_sources == null:
		return true
	return activation_sources is Dictionary and activation_sources.has(source_path)


func import_mod_images_from_path(import_path: String, progress_callback: Callable = Callable()) -> Dictionary:
	if import_path.strip_edges() == "":
		return {
			"ok": false,
			"message": "No mod path was selected."
		}

	var import_extension = import_path.get_extension().to_lower()
	var is_direct_pck = import_extension == "pck"
	var mod_root = import_path if DirAccess.dir_exists_absolute(import_path) else import_path.get_base_dir()
	if !DirAccess.dir_exists_absolute(mod_root):
		return {
			"ok": false,
			"message": "The selected mod folder could not be found."
		}

	var selected_name = import_path.get_file().to_lower()
	var has_pck_declared = false
	var mod_id = ""
	var direct_pck_path = import_path if is_direct_pck and FileAccess.file_exists(import_path) else ""
	if selected_name.ends_with(".json"):
		var manifest_file = FileAccess.open(import_path, FileAccess.READ)
		if manifest_file != null:
			var parsed = JSON.parse_string(manifest_file.get_as_text())
			if parsed is Dictionary:
				has_pck_declared = bool((parsed as Dictionary).get("has_pck", false))
				mod_id = String((parsed as Dictionary).get("id", "")).strip_edges()

	var source_index = _build_card_source_index()
	if source_index.is_empty():
		return {
			"ok": false,
			"message": "Could not build the card source index."
		}

	var image_paths: Array = []
	if !is_direct_pck:
		_collect_mod_image_paths(mod_root, image_paths)
	var extracted_temp_dir = ""
	var extracted_saved_dir = ""
	var extract_save_notice = ""
	var extract_debug := {}
	if image_paths.is_empty() and (has_pck_declared or direct_pck_path != ""):
		var pck_path = direct_pck_path if direct_pck_path != "" else _resolve_mod_pck_path(mod_root, mod_id, import_path)
		if pck_path != "":
			var extract_result = _extract_pck_images(pck_path)
			if bool(extract_result.get("ok", false)):
				extracted_temp_dir = String(extract_result.get("temp_dir", ""))
				extracted_saved_dir = String(extract_result.get("saved_dir", extracted_temp_dir))
				extract_save_notice = String(extract_result.get("save_notice", ""))
				extract_debug = _read_extract_metadata(extracted_temp_dir)
				_collect_mod_image_paths(extracted_temp_dir, image_paths)
			elif String(extract_result.get("message", "")) != "":
				return extract_result
	if image_paths.is_empty():
		var debug_suffix = ""
		if !extract_debug.is_empty():
			debug_suffix = " PCK debug: entries=%d, candidates=%d, exported=%d, saved_dir=%s." % [
				int(extract_debug.get("entry_count", 0)),
				int(extract_debug.get("candidate_count", 0)),
				int(extract_debug.get("count", 0)),
				String(extract_debug.get("saved_dir", extracted_saved_dir))
			]
		return {
			"ok": false,
			"message": "No card image files were found in that mod folder or PCK.%s%s" % [
				debug_suffix,
				"%s%s" % [
					" Extracted files folder: %s." % extracted_saved_dir if extracted_saved_dir != "" else "",
					" %s" % extract_save_notice if extract_save_notice != "" else ""
				]
			]
		}

	var imported_count := 0
	var ambiguous_count := 0
	var unmatched_count := 0
	var imported_sources := {}
	var pack_name = import_path.get_file().get_basename()
	if pack_name == "":
		pack_name = mod_root.get_file().get_basename()
	if pack_name == "":
		pack_name = "Imported Mod Pack"
	var pack_id = _build_art_pack_id(pack_name)
	var pack_cards := {}
	var debug_matches: Array = []
	_begin_batch_updates()
	await _report_import_progress(progress_callback, 0, image_paths.size(), "Matching extracted images...")
	for image_path in image_paths:
		var match = _match_card_source_for_mod_image(String(image_path), source_index)
		if bool(match.get("ambiguous", false)):
			ambiguous_count += 1
			if debug_matches.size() < 10:
				debug_matches.append("%s -> AMBIGUOUS" % String(image_path).get_file())
			await _report_import_progress(progress_callback, imported_count + unmatched_count + ambiguous_count, image_paths.size(), String(image_path).get_file())
			continue
		var source_path = String(match.get("source_path", ""))
		if source_path == "":
			unmatched_count += 1
			if debug_matches.size() < 10:
				debug_matches.append("%s -> NO_MATCH" % String(image_path).get_file())
			await _report_import_progress(progress_callback, imported_count + unmatched_count + ambiguous_count, image_paths.size(), String(image_path).get_file())
			continue
		if imported_sources.has(source_path):
			if debug_matches.size() < 10:
				debug_matches.append("%s -> DUPLICATE %s" % [String(image_path).get_file(), source_path.get_file()])
			await _report_import_progress(progress_callback, imported_count + unmatched_count + ambiguous_count, image_paths.size(), String(image_path).get_file())
			continue
		if debug_matches.size() < 10:
			debug_matches.append("%s -> %s" % [String(image_path).get_file(), source_path.get_file()])
		var result := {}
		var extension = String(image_path).get_extension().to_lower()
		if extension == "gif":
			var extract_result = _extract_gif_frames(String(image_path))
			if bool(extract_result.get("ok", false)):
				var registered_entry = _register_art_pack_animated_entry(
					pack_id,
					source_path,
					Array(extract_result.get("images", [])),
					Array(extract_result.get("delays", [])),
					DISPLAY_MODE_DEFAULT
				)
				if !registered_entry.is_empty():
					pack_cards[source_path] = registered_entry
					result = _activate_registered_art_pack_entry(source_path, registered_entry, pack_id, pack_name)
				var temp_dir = String(extract_result.get("temp_dir", ""))
				if temp_dir != "":
					_delete_directory_recursive(temp_dir)
		else:
			var image = load_image_from_file(String(image_path))
			if image != null:
				var registered_entry = _register_art_pack_static_entry(
					pack_id,
					source_path,
					image,
					DISPLAY_MODE_DEFAULT
				)
				if !registered_entry.is_empty():
					pack_cards[source_path] = registered_entry
					result = _activate_registered_art_pack_entry(source_path, registered_entry, pack_id, pack_name)
		if result.is_empty():
			result = save_override_from_file(source_path, String(image_path))
		if bool(result.get("ok", false)):
			imported_sources[source_path] = true
			imported_count += 1
		await _report_import_progress(progress_callback, imported_count + unmatched_count + ambiguous_count, image_paths.size(), String(image_path).get_file())

	if imported_count == 0:
		_end_batch_updates()
		return {
			"ok": false,
			"message": "No matching card images were imported from that mod. Unmatched: %d, ambiguous: %d.%s" % [
				unmatched_count,
				ambiguous_count,
				"%s%s" % [
					" Extracted files saved to: %s" % extracted_saved_dir if extracted_saved_dir != "" else " Import source: direct PCK mode.",
					" %s" % extract_save_notice if extract_save_notice != "" else ""
			]
			] + ("\nMatches:\n%s" % "\n".join(debug_matches) if !debug_matches.is_empty() else "")
		}

	if !pack_cards.is_empty():
		var packs = _art_pack_registry.get("packs", {})
		if !(packs is Dictionary):
			packs = {}
		packs[pack_id] = {
			"id": pack_id,
			"name": pack_name,
			"source_file": import_path,
			"imported_at": Time.get_datetime_string_from_system(),
			"count": pack_cards.size(),
			"cards": pack_cards
		}
		_art_pack_registry["packs"] = packs
		_save_art_pack_registry()
		_notify_art_packs_changed()
	_end_batch_updates()

	return {
		"ok": true,
		"message": "Imported %d card images from the selected mod folder and registered \"%s\". Unmatched: %d, ambiguous: %d.%s" % [
			imported_count,
			pack_name,
			unmatched_count,
			ambiguous_count,
			"%s%s" % [
				" Extracted files saved to: %s" % extracted_saved_dir if extracted_saved_dir != "" else " Import source: direct PCK mode.",
				" %s" % extract_save_notice if extract_save_notice != "" else ""
			]
		] + ("\nMatches:\n%s" % "\n".join(debug_matches) if !debug_matches.is_empty() else "")
	}


func _read_extract_metadata(temp_dir: String) -> Dictionary:
	if temp_dir == "":
		return {}
	var metadata_path = temp_dir.path_join("metadata.json")
	var metadata_file = FileAccess.open(metadata_path, FileAccess.READ)
	if metadata_file == null:
		return {}
	var parsed = JSON.parse_string(metadata_file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _report_import_progress(progress_callback: Callable, current: int, total: int, label: String = "") -> void:
	if progress_callback.is_valid():
		progress_callback.call(current, total, label)
	await get_tree().process_frame


func save_override_image(source_path: String, image, display_mode: String = DISPLAY_MODE_DEFAULT) -> Dictionary:
	source_path = _canonicalize_source_key(source_path)
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

	var normalized_image = normalize_image(image, get_target_size_for_source_path(source_path))
	if normalized_image == null:
		return {
			"ok": false,
			"message": "The image could not be converted to the card art format."
		}
	return _save_static_override_data(source_path, normalized_image, image, 1.0, 0.0, 0.0, display_mode)


func save_adjusted_override(source_path: String, zoom: float, offset_x: float, offset_y: float) -> Dictionary:
	source_path = _canonicalize_source_key(source_path)
	var payload = get_adjustable_override_payload(source_path)
	if payload.is_empty():
		return {
			"ok": false,
			"message": "The current custom image cannot be adjusted."
		}

	if String(payload.get("type", "static")) == "animated_gif":
		var source_images = payload.get("images", [])
		var delays = payload.get("delays", [])
		if !(source_images is Array) or source_images.is_empty():
			return {
				"ok": false,
				"message": "The current GIF could not be adjusted."
			}
		var adjusted_images: Array = []
		for source_image in source_images:
			var adjusted_frame = build_adjusted_preview(source_path, source_image, zoom, offset_x, offset_y)
			if adjusted_frame == null:
				continue
			adjusted_images.append(adjusted_frame)
		if adjusted_images.is_empty():
			return {
				"ok": false,
				"message": "The adjusted GIF frames could not be generated."
			}
		var result = save_animated_override_images(source_path, adjusted_images, delays, get_display_mode(source_path), source_images)
		if bool(result.get("ok", false)):
			var entry = _manifest.get(source_path, null)
			if entry is Dictionary:
				entry["adjust_zoom"] = zoom
				entry["adjust_offset_x"] = offset_x
				entry["adjust_offset_y"] = offset_y
				_manifest[source_path] = entry
				_save_manifest()
		return result

	var source_image = payload.get("image", null)
	var adjusted_image = build_adjusted_preview(source_path, source_image, zoom, offset_x, offset_y)
	if adjusted_image == null:
		return {
			"ok": false,
			"message": "The adjusted image could not be generated."
		}

	return _save_static_override_data(source_path, adjusted_image, source_image, zoom, offset_x, offset_y, get_display_mode(source_path))


func build_adjusted_preview(source_path: String, source_image, zoom: float, offset_x: float, offset_y: float):
	source_path = _canonicalize_source_key(source_path)
	if source_image == null:
		return null
	if is_full_art_mode(source_path):
		var prepared_image = trim_transparent_margins(source_image)
		if prepared_image == null:
			return null
		return normalize_image_with_adjustment(
			prepared_image,
			FULL_ART_TARGET_SIZE,
			float(zoom) * FULL_ART_STATIC_ZOOM_BOOST,
			offset_x,
			offset_y
		)
	var target_size = get_target_size_for_source_path(source_path)
	return normalize_image_with_adjustment(source_image, target_size, zoom, offset_x, offset_y)


func save_gif_override_from_file(source_path: String, import_path: String, display_mode: String = DISPLAY_MODE_DEFAULT) -> Dictionary:
	source_path = _canonicalize_source_key(source_path)
	if source_path == "":
		return {
			"ok": false,
			"message": "No source card art is selected."
		}

	var extract_result = _extract_gif_frames(import_path)
	if !bool(extract_result.get("ok", false)):
		return extract_result

	var processed_images = Array(extract_result.get("images", []))
	var processed_delays = Array(extract_result.get("delays", []))
	var original_frame_count = int(extract_result.get("original_frame_count", processed_images.size()))
	var processed_frame_count = int(extract_result.get("processed_frame_count", processed_images.size()))
	var source_frame_files = Array(extract_result.get("source_frame_files", []))
	var source_frame_delays = Array(extract_result.get("source_frame_delays", []))

	if processed_images.size() == 1:
		var static_result = save_override_image(source_path, processed_images[0], display_mode)
		if bool(static_result.get("ok", false)):
			_attach_source_animation_backup(source_path, source_frame_files, source_frame_delays)
			static_result["message"] = "GIF applied as a single frame (%d -> %d frame)." % [original_frame_count, processed_frame_count]
		var static_temp_dir = String(extract_result.get("temp_dir", ""))
		if static_temp_dir != "":
			_delete_directory_recursive(static_temp_dir)
		return static_result

	var save_result = save_animated_override_images(
		source_path,
		processed_images,
		processed_delays,
		display_mode
	)
	if bool(save_result.get("ok", false)):
		_attach_source_animation_backup(source_path, source_frame_files, source_frame_delays)
		save_result["message"] = "Animated GIF applied with %d frames (%d -> %d)." % [processed_images.size(), original_frame_count, processed_frame_count]
	var temp_dir = String(extract_result.get("temp_dir", ""))
	if temp_dir != "":
		_delete_directory_recursive(temp_dir)
	return save_result


func rebuild_animated_override_with_current_settings(source_path: String) -> Dictionary:
	source_path = _canonicalize_source_key(source_path)
	var entry = _manifest.get(source_path, null)
	if !(entry is Dictionary):
		return {
			"ok": false,
			"message": "No custom animated image is applied to this card."
		}
	var settings = get_gif_processing_settings()
	var use_frame_limit = bool(settings.get("use_frame_limit", false))
	var provider_pack_id = String(entry.get("provider_pack_id", ""))
	if provider_pack_id != "":
		var pack_entry = _get_registered_art_pack_card_entry(provider_pack_id, source_path)
		if pack_entry is Dictionary and !pack_entry.is_empty():
			if !use_frame_limit:
				var pack_name = String(entry.get("provider_pack_name", provider_pack_id))
				return _activate_registered_art_pack_entry(source_path, pack_entry, provider_pack_id, pack_name)
			var pack_frame_paths = pack_entry.get("source_frame_paths", pack_entry.get("frame_paths", []))
			var pack_frame_delays = pack_entry.get("frame_delays", [])
			if pack_frame_paths is Array and !pack_frame_paths.is_empty():
				var pack_images: Array = []
				var pack_delays: Array = []
				for index in range(pack_frame_paths.size()):
					var frame_image = load_image_from_file(ProjectSettings.globalize_path(String(pack_frame_paths[index])))
					if frame_image == null:
						continue
					pack_images.append(frame_image)
					pack_delays.append(max(0.02, float(pack_frame_delays[index]) if index < pack_frame_delays.size() else 0.1))
				if !pack_images.is_empty():
					var pack_original_count = pack_images.size()
					if bool(settings.get("skip_duplicate_frames", true)):
						var pack_deduped = _dedupe_gif_frames(pack_images, pack_delays)
						pack_images = Array(pack_deduped.get("images", pack_images))
						pack_delays = Array(pack_deduped.get("delays", pack_delays))
					var pack_limited = _limit_gif_frames(pack_images, pack_delays, int(settings.get("max_frames", 36)))
					pack_images = Array(pack_limited.get("images", pack_images))
					pack_delays = Array(pack_limited.get("delays", pack_delays))
					var display_mode = String(entry.get("display_mode", DISPLAY_MODE_DEFAULT))
					if pack_images.size() <= 1:
						var static_result = save_override_image(source_path, pack_images[0], display_mode)
						if bool(static_result.get("ok", false)):
							static_result["message"] = "Animated image rebuilt as a single frame (%d -> %d frame)." % [pack_original_count, pack_images.size()]
						return static_result
					var pack_result = save_animated_override_images(source_path, pack_images, pack_delays, display_mode)
					if bool(pack_result.get("ok", false)):
						pack_result["message"] = "Animated image rebuilt with %d frames (%d -> %d)." % [pack_images.size(), pack_original_count, pack_images.size()]
					return pack_result
	if !use_frame_limit and provider_pack_id != "":
		var pack_entry = _get_registered_art_pack_card_entry(provider_pack_id, source_path)
		if pack_entry is Dictionary and !pack_entry.is_empty():
			var pack_name = String(entry.get("provider_pack_name", provider_pack_id))
			return _activate_registered_art_pack_entry(source_path, pack_entry, provider_pack_id, pack_name)
	var frame_paths = entry.get("source_animation_frame_paths", entry.get("source_frame_paths", entry.get("frame_paths", [])))
	var frame_delays = entry.get("source_animation_frame_delays", entry.get("frame_delays", []))
	if (!(frame_paths is Array) or frame_paths.is_empty()) and String(entry.get("provider_pack_id", "")) != "":
		var fallback_entry = _get_registered_art_pack_card_entry(String(entry.get("provider_pack_id", "")), source_path)
		if fallback_entry is Dictionary:
			frame_paths = fallback_entry.get("source_frame_paths", fallback_entry.get("frame_paths", []))
			frame_delays = fallback_entry.get("frame_delays", [])
	if !(frame_paths is Array) or frame_paths.is_empty():
		return {
			"ok": false,
			"message": "The original animated frames are not available for this card."
		}
	var images: Array = []
	var delays: Array = []
	for index in range(frame_paths.size()):
		var frame_image = load_image_from_file(ProjectSettings.globalize_path(String(frame_paths[index])))
		if frame_image == null:
			continue
		images.append(frame_image)
		delays.append(max(0.02, float(frame_delays[index]) if index < frame_delays.size() else 0.1))
	if images.is_empty():
		return {
			"ok": false,
			"message": "The original animated frames could not be loaded."
		}
	var original_frame_count = images.size()
	if use_frame_limit and bool(settings.get("skip_duplicate_frames", true)):
		var deduped = _dedupe_gif_frames(images, delays)
		images = Array(deduped.get("images", images))
		delays = Array(deduped.get("delays", delays))
	if use_frame_limit:
		var limited = _limit_gif_frames(images, delays, int(settings.get("max_frames", 36)))
		images = Array(limited.get("images", images))
		delays = Array(limited.get("delays", delays))
	var processed_frame_count = images.size()
	var display_mode = String(entry.get("display_mode", DISPLAY_MODE_DEFAULT))
	if processed_frame_count <= 1:
		var static_result = save_override_image(source_path, images[0], display_mode)
		if bool(static_result.get("ok", false)):
			static_result["message"] = "Animated image rebuilt as a single frame (%d -> %d frame)." % [original_frame_count, processed_frame_count]
		return static_result
	var animated_result = save_animated_override_images(source_path, images, delays, display_mode)
	if bool(animated_result.get("ok", false)):
		animated_result["message"] = "Animated image rebuilt with %d frames (%d -> %d)." % [processed_frame_count, original_frame_count, processed_frame_count]
	return animated_result


func _get_registered_art_pack_card_entry(pack_id: String, source_path: String) -> Dictionary:
	source_path = _canonicalize_source_key(source_path)
	var packs = _art_pack_registry.get("packs", {})
	if !(packs is Dictionary) or !packs.has(pack_id):
		return {}
	var pack = packs.get(pack_id, null)
	if !(pack is Dictionary):
		return {}
	var cards = pack.get("cards", {})
	if !(cards is Dictionary):
		return {}
	var card_entry = cards.get(source_path, null)
	return card_entry if card_entry is Dictionary else {}


func rebuild_all_gif_overrides_with_current_settings(progress_callback: Callable = Callable()) -> Dictionary:
	var gif_sources: Array = []
	for source_path in _manifest.keys():
		var entry = _manifest.get(source_path, null)
		if !(entry is Dictionary):
			continue
		var backup_frames = entry.get("source_animation_frame_paths", [])
		var current_frames = entry.get("source_frame_paths", entry.get("frame_paths", []))
		if (backup_frames is Array and !backup_frames.is_empty()) or (current_frames is Array and !current_frames.is_empty()):
			gif_sources.append(String(source_path))
	if gif_sources.is_empty():
		return {
			"ok": false,
			"message": "There are no GIF-based card images to rebuild."
		}
	_begin_batch_updates()
	var applied := 0
	var total := gif_sources.size()
	for index in range(total):
		var source_path = String(gif_sources[index])
		await _report_import_progress(progress_callback, index + 1, total, source_path.get_file().get_basename())
		var result = rebuild_animated_override_with_current_settings(source_path)
		if bool(result.get("ok", false)):
			applied += 1
	_end_batch_updates()
	return {
		"ok": applied > 0,
		"message": "Rebuilt GIF settings for %d / %d cards." % [applied, total]
	}


func save_animated_override_images(source_path: String, images: Array, delays: Array, display_mode: String = DISPLAY_MODE_DEFAULT, source_images: Array = []) -> Dictionary:
	source_path = _canonicalize_source_key(source_path)
	if source_path == "":
		return {
			"ok": false,
			"message": "No source card art is selected."
		}
	if images.is_empty():
		return {
			"ok": false,
			"message": "The GIF did not contain any readable frames."
		}

	var target_size = get_target_size_for_source_path(source_path)
	var safe_stem = _safe_file_stem(source_path)
	var frame_paths: Array = []
	var source_frame_paths: Array = []
	var frame_delays: Array = []
	var previous_entry = _manifest.get(source_path, null)
	var backup_frame_paths: Array = []
	var backup_frame_delays: Array = []
	var provider_type := ""
	var provider_pack_id := ""
	var provider_pack_name := ""
	if previous_entry is Dictionary:
		var previous_backup_paths = previous_entry.get("source_animation_frame_paths", [])
		var previous_backup_delays = previous_entry.get("source_animation_frame_delays", [])
		provider_type = String(previous_entry.get("provider_type", ""))
		provider_pack_id = String(previous_entry.get("provider_pack_id", ""))
		provider_pack_name = String(previous_entry.get("provider_pack_name", ""))
		if previous_backup_paths is Array:
			backup_frame_paths = previous_backup_paths.duplicate(true)
		if previous_backup_delays is Array:
			backup_frame_delays = previous_backup_delays.duplicate(true)
		if backup_frame_paths.is_empty():
			var previous_source_paths = previous_entry.get("source_frame_paths", previous_entry.get("frame_paths", []))
			var previous_frame_delays = previous_entry.get("frame_delays", [])
			if previous_source_paths is Array:
				backup_frame_paths = previous_source_paths.duplicate(true)
			if previous_frame_delays is Array:
				backup_frame_delays = previous_frame_delays.duplicate(true)

	_remove_entry_files(_manifest.get(source_path, null), false)

	for index in range(images.size()):
		var source_image = images[index]
		var normalized_image = normalize_image(source_image, target_size)
		if normalized_image == null:
			continue
		var frame_path = "%s/%s_anim_%03d.png" % [STORAGE_IMAGE_DIR, safe_stem, index]
		var source_frame_path = "%s/%s_anim_source_%03d.png" % [STORAGE_EDIT_SOURCE_DIR, safe_stem, index]
		var absolute_frame_path = ProjectSettings.globalize_path(frame_path)
		var absolute_source_frame_path = ProjectSettings.globalize_path(source_frame_path)
		var save_error = normalized_image.save_png(absolute_frame_path)
		if save_error != OK:
			continue
		var original_source_image = source_images[index] if index < source_images.size() and source_images[index] != null else source_image
		if original_source_image != null and original_source_image.save_png(absolute_source_frame_path) == OK:
			source_frame_paths.append(source_frame_path)
		else:
			source_frame_paths.append(frame_path)
		frame_paths.append(frame_path)
		frame_delays.append(max(0.02, float(delays[index]) if index < delays.size() else 0.1))

	if frame_paths.is_empty():
		return {
			"ok": false,
			"message": "The GIF frames could not be converted to card art."
		}
	if backup_frame_paths.is_empty():
		backup_frame_paths = source_frame_paths.duplicate(true)
		backup_frame_delays = frame_delays.duplicate(true)

	_manifest[source_path] = {
		"type": "animated_gif",
		"frame_paths": frame_paths,
		"source_frame_paths": source_frame_paths,
		"frame_delays": frame_delays,
		"source_animation_frame_paths": backup_frame_paths,
		"source_animation_frame_delays": backup_frame_delays,
		"width": target_size.x,
		"height": target_size.y,
		"display_mode": display_mode,
		"provider_type": provider_type,
		"provider_pack_id": provider_pack_id,
		"provider_pack_name": provider_pack_name,
		"updated_at": Time.get_datetime_string_from_system()
	}
	_erase_override_texture_cache(source_path)
	_save_manifest()
	refresh_all_portraits()
	_notify_override_changed(source_path)

	return {
		"ok": true,
		"message": "Animated GIF applied with %d frames." % frame_paths.size()
	}


func _save_static_override_data(source_path: String, normalized_image, edit_source_image, zoom: float, offset_x: float, offset_y: float, display_mode: String = DISPLAY_MODE_DEFAULT) -> Dictionary:
	source_path = _canonicalize_source_key(source_path)
	var target_size = get_target_size_for_source_path(source_path)
	var safe_stem = _safe_file_stem(source_path)
	var override_path = "%s/%s.png" % [STORAGE_IMAGE_DIR, safe_stem]
	var edit_source_path = "%s/%s_source.png" % [STORAGE_EDIT_SOURCE_DIR, safe_stem]
	var absolute_override_path = ProjectSettings.globalize_path(override_path)
	var absolute_edit_source_path = ProjectSettings.globalize_path(edit_source_path)
	var previous_entry = _manifest.get(source_path, null)
	var backup_frame_paths: Array = []
	var backup_frame_delays: Array = []
	var provider_type := ""
	var provider_pack_id := ""
	var provider_pack_name := ""
	if previous_entry is Dictionary:
		var previous_backup_paths = previous_entry.get("source_animation_frame_paths", [])
		var previous_backup_delays = previous_entry.get("source_animation_frame_delays", [])
		provider_type = String(previous_entry.get("provider_type", ""))
		provider_pack_id = String(previous_entry.get("provider_pack_id", ""))
		provider_pack_name = String(previous_entry.get("provider_pack_name", ""))
		if previous_backup_paths is Array:
			backup_frame_paths = previous_backup_paths.duplicate(true)
		if previous_backup_delays is Array:
			backup_frame_delays = previous_backup_delays.duplicate(true)
		if backup_frame_paths.is_empty():
			var previous_source_paths = previous_entry.get("source_frame_paths", previous_entry.get("frame_paths", []))
			var previous_frame_delays = previous_entry.get("frame_delays", [])
			if previous_source_paths is Array:
				backup_frame_paths = previous_source_paths.duplicate(true)
			if previous_frame_delays is Array:
				backup_frame_delays = previous_frame_delays.duplicate(true)

	_remove_entry_files(_manifest.get(source_path, null), false)

	if normalized_image.save_png(absolute_override_path) != OK:
		return {
			"ok": false,
			"message": "Failed to save the converted card art."
		}

	var edit_image_to_save = edit_source_image if edit_source_image != null else normalized_image
	if edit_image_to_save.save_png(absolute_edit_source_path) != OK:
		return {
			"ok": false,
			"message": "Failed to save the adjustable source image."
		}

	_manifest[source_path] = {
		"override_path": override_path,
		"edit_source_path": edit_source_path,
		"source_animation_frame_paths": backup_frame_paths,
		"source_animation_frame_delays": backup_frame_delays,
		"width": target_size.x,
		"height": target_size.y,
		"display_mode": display_mode,
		"adjust_zoom": zoom,
		"adjust_offset_x": offset_x,
		"adjust_offset_y": offset_y,
		"provider_type": provider_type,
		"provider_pack_id": provider_pack_id,
		"provider_pack_name": provider_pack_name,
		"updated_at": Time.get_datetime_string_from_system()
	}
	_erase_override_texture_cache(source_path)
	_save_manifest()
	refresh_all_portraits()
	_notify_override_changed(source_path)

	return {
		"ok": true,
		"message": "Custom art applied and resized to %dx%d." % [target_size.x, target_size.y]
	}


func remove_override(source_path: String) -> Dictionary:
	source_path = _canonicalize_source_key(source_path)
	if !_manifest.has(source_path):
		return {
			"ok": false,
			"message": "This card is already using its original art."
		}

	_remove_entry_files(_manifest[source_path])

	_manifest.erase(source_path)
	_erase_override_texture_cache(source_path)
	_save_manifest()
	_clear_source_overrides_from_tracked_portraits(source_path)
	_clear_source_overrides_in_tree(get_tree().root, source_path)
	refresh_all_portraits()
	_notify_override_changed(source_path)

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

	var source_paths := _manifest.keys()
	for source_path in _manifest.keys():
		_remove_entry_files(_manifest[source_path])

	_manifest.clear()
	_override_texture_cache.clear()
	_save_manifest()
	for source_path in source_paths:
		_clear_source_overrides_in_tree(get_tree().root, String(source_path))
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


func load_first_gif_frame(path: String):
	var extract_result = _extract_gif_frames(path)
	if !bool(extract_result.get("ok", false)):
		return null
	var images = extract_result.get("images", [])
	var temp_dir = String(extract_result.get("temp_dir", ""))
	if temp_dir != "":
		_delete_directory_recursive(temp_dir)
	if images is Array and !images.is_empty():
		return images[0]
	return null


func _extract_gif_frames(import_path: String) -> Dictionary:
	var tool_path = _ensure_gif_tool_script()
	if tool_path == "":
		return {
			"ok": false,
			"message": "The bundled GIF extraction tool could not be prepared."
		}

	var normalized_import_path = import_path
	if !normalized_import_path.is_absolute_path():
		normalized_import_path = ProjectSettings.globalize_path(import_path)

	var output_dir = ProjectSettings.globalize_path("%s/%s_%d" % [
		STORAGE_GIF_TEMP_DIR,
		_safe_file_stem(import_path.get_file()),
		Time.get_ticks_msec()
	])
	var settings = get_gif_processing_settings()
	var use_cache = bool(settings.get("use_cache", true))
	var output_metadata = {}
	var is_cache_hit := false
	if use_cache:
		var cached_dir = _get_gif_cache_dir(normalized_import_path)
		var cached_metadata = _read_gif_metadata(cached_dir)
		if !cached_metadata.is_empty():
			output_dir = cached_dir
			output_metadata = cached_metadata
			is_cache_hit = true
	if !is_cache_hit:
		DirAccess.make_dir_recursive_absolute(output_dir)

		var command_output: Array = []
		var exit_code = OS.execute(
			"powershell.exe",
			[
				"-ExecutionPolicy",
				"Bypass",
				"-File",
				tool_path,
				"-InputPath",
				normalized_import_path,
				"-OutputDir",
				output_dir
			],
			command_output,
			true
		)
		if exit_code != 0:
			return {
				"ok": false,
				"message": "GIF frame extraction failed.\n%s" % "\n".join(command_output)
			}
		output_metadata = _read_gif_metadata(output_dir)
		if output_metadata.is_empty():
			return {
				"ok": false,
				"message": "GIF extraction metadata was invalid."
			}

	var frame_files = output_metadata.get("frames", [])
	var frame_delays = output_metadata.get("delays", [])
	if !(frame_files is Array) or frame_files.is_empty():
		return {
			"ok": false,
			"message": "The GIF did not produce any frames."
		}

	var images: Array = []
	var delays: Array = []
	for index in range(frame_files.size()):
		var frame_file = String(frame_files[index])
		var frame_image = load_image_from_file(frame_file)
		if frame_image == null:
			continue
		images.append(frame_image)
		delays.append(max(0.02, float(frame_delays[index]) if index < frame_delays.size() else 0.1))

	if images.is_empty():
		return {
			"ok": false,
			"message": "The extracted GIF frames could not be loaded."
		}

	var original_frame_count = images.size()
	var use_frame_limit = bool(settings.get("use_frame_limit", false))

	if use_frame_limit and bool(settings.get("skip_duplicate_frames", true)):
		var deduped = _dedupe_gif_frames(images, delays)
		images = Array(deduped.get("images", images))
		delays = Array(deduped.get("delays", delays))

	if use_frame_limit:
		var limited = _limit_gif_frames(images, delays, int(settings.get("max_frames", 36)))
		images = Array(limited.get("images", images))
		delays = Array(limited.get("delays", delays))

	return {
		"ok": true,
		"images": images,
		"delays": delays,
		"source_frame_files": frame_files,
		"source_frame_delays": frame_delays,
		"original_frame_count": original_frame_count,
		"processed_frame_count": images.size(),
		"temp_dir": "" if use_cache else output_dir
	}


func _attach_source_animation_backup(source_path: String, source_frame_files: Array, source_frame_delays: Array) -> void:
	var entry = _manifest.get(source_path, null)
	if !(entry is Dictionary):
		return
	if !(source_frame_files is Array) or source_frame_files.is_empty():
		return
	var safe_stem = _safe_file_stem(source_path)
	var backup_paths: Array = []
	var backup_delays: Array = []
	for index in range(source_frame_files.size()):
		var frame_file = String(source_frame_files[index])
		var frame_image = load_image_from_file(frame_file)
		if frame_image == null:
			continue
		var backup_path = "%s/%s_anim_backup_%03d.png" % [STORAGE_EDIT_SOURCE_DIR, safe_stem, index]
		var absolute_backup_path = ProjectSettings.globalize_path(backup_path)
		if frame_image.save_png(absolute_backup_path) != OK:
			continue
		backup_paths.append(backup_path)
		backup_delays.append(max(0.02, float(source_frame_delays[index]) if index < source_frame_delays.size() else 0.1))
	if backup_paths.is_empty():
		return
	entry["source_animation_frame_paths"] = backup_paths
	entry["source_animation_frame_delays"] = backup_delays
	entry["updated_at"] = Time.get_datetime_string_from_system()
	_manifest[source_path] = entry
	_save_manifest()


func _read_gif_metadata(output_dir: String) -> Dictionary:
	var metadata_path = output_dir.path_join("metadata.json")
	var metadata_file = FileAccess.open(metadata_path, FileAccess.READ)
	if metadata_file == null:
		return {}
	var parsed = JSON.parse_string(metadata_file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _get_file_size_bytes(path: String) -> int:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 0
	return int(file.get_length())


func _get_gif_cache_dir(import_path: String) -> String:
	var modified_time = FileAccess.get_modified_time(import_path)
	var file_size = _get_file_size_bytes(import_path)
	var settings = get_gif_processing_settings()
	var cache_signature = "%s_%s_%s_%s" % [
		str(bool(settings.get("skip_duplicate_frames", true))),
		str(bool(settings.get("use_frame_limit", false))),
		str(int(settings.get("max_frames", 36))),
		str(bool(settings.get("use_cache", true)))
	]
	var cache_key = _safe_file_stem("%s_%s_%s_%s" % [import_path.get_file(), str(modified_time), str(file_size), cache_signature])
	var cache_dir = ProjectSettings.globalize_path("%s/%s" % [STORAGE_GIF_CACHE_DIR, cache_key])
	DirAccess.make_dir_recursive_absolute(cache_dir)
	return cache_dir


func _dedupe_gif_frames(images: Array, delays: Array) -> Dictionary:
	if images.size() <= 1:
		return {"images": images, "delays": delays}
	var filtered_images: Array = []
	var filtered_delays: Array = []
	var previous_bytes := PackedByteArray()
	for index in range(images.size()):
		var image = images[index]
		if !(image is Image):
			continue
		var current_bytes = (image as Image).get_data()
		if !previous_bytes.is_empty() and current_bytes == previous_bytes:
			if !filtered_delays.is_empty():
				filtered_delays[filtered_delays.size() - 1] = float(filtered_delays[filtered_delays.size() - 1]) + float(delays[index]) if index < delays.size() else 0.1
			continue
		filtered_images.append(image)
		filtered_delays.append(max(0.02, float(delays[index]) if index < delays.size() else 0.1))
		previous_bytes = current_bytes
	return {"images": filtered_images, "delays": filtered_delays}


func _limit_gif_frames(images: Array, delays: Array, max_frames: int) -> Dictionary:
	if max_frames <= 0 or images.size() <= max_frames:
		return {"images": images, "delays": delays}
	var filtered_images: Array = []
	var filtered_delays: Array = []
	var source_count = images.size()
	if max_frames == 1:
		filtered_images.append(images[0])
		filtered_delays.append(max(0.02, float(delays[0]) if !delays.is_empty() else 0.1))
		return {"images": filtered_images, "delays": filtered_delays}
	for index in range(max_frames):
		var source_index = int(round(float(index) * float(source_count - 1) / float(max_frames - 1)))
		filtered_images.append(images[source_index])
		filtered_delays.append(max(0.02, float(delays[source_index]) if source_index < delays.size() else 0.1))
	return {"images": filtered_images, "delays": filtered_delays}


func _ensure_gif_tool_script() -> String:
	var source_file = FileAccess.open(GIF_TOOL_RES_PATH, FileAccess.READ)
	if source_file == null:
		return ""
	var script_text = source_file.get_as_text()
	var absolute_tool_path = ProjectSettings.globalize_path(GIF_TOOL_USER_PATH)
	DirAccess.make_dir_recursive_absolute(absolute_tool_path.get_base_dir())
	var existing_text = ""
	if FileAccess.file_exists(absolute_tool_path):
		var existing_file = FileAccess.open(absolute_tool_path, FileAccess.READ)
		if existing_file != null:
			existing_text = existing_file.get_as_text()
	if existing_text != script_text:
		var tool_file = FileAccess.open(absolute_tool_path, FileAccess.WRITE)
		if tool_file == null:
			return ""
		tool_file.store_string(script_text)
	return absolute_tool_path


func _is_animated_entry(entry) -> bool:
	return entry is Dictionary and entry.has("frame_paths")


func _remove_entry_files(entry, remove_backup: bool = true) -> void:
	if !(entry is Dictionary):
		return
	if _is_animated_entry(entry):
		for frame_path in entry.get("frame_paths", []):
			var absolute_frame_path = ProjectSettings.globalize_path(String(frame_path))
			if FileAccess.file_exists(absolute_frame_path):
				DirAccess.remove_absolute(absolute_frame_path)
		for source_frame_path in entry.get("source_frame_paths", []):
			var absolute_source_frame_path = ProjectSettings.globalize_path(String(source_frame_path))
			if FileAccess.file_exists(absolute_source_frame_path):
				DirAccess.remove_absolute(absolute_source_frame_path)
		if remove_backup:
			for backup_frame_path in entry.get("source_animation_frame_paths", []):
				var absolute_backup_frame_path = ProjectSettings.globalize_path(String(backup_frame_path))
				if FileAccess.file_exists(absolute_backup_frame_path):
					DirAccess.remove_absolute(absolute_backup_frame_path)
		return
	if entry.has("override_path"):
		var absolute_override_path = ProjectSettings.globalize_path(String(entry["override_path"]))
		if FileAccess.file_exists(absolute_override_path):
			DirAccess.remove_absolute(absolute_override_path)
	if entry.has("edit_source_path"):
		var absolute_edit_source_path = ProjectSettings.globalize_path(String(entry["edit_source_path"]))
		if FileAccess.file_exists(absolute_edit_source_path):
			DirAccess.remove_absolute(absolute_edit_source_path)
	if remove_backup:
		for backup_frame_path in entry.get("source_animation_frame_paths", []):
			var absolute_backup_frame_path = ProjectSettings.globalize_path(String(backup_frame_path))
			if FileAccess.file_exists(absolute_backup_frame_path):
				DirAccess.remove_absolute(absolute_backup_frame_path)


func _delete_directory_recursive(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var entry_name = dir.get_next()
		if entry_name == "":
			break
		if entry_name == "." or entry_name == "..":
			continue
		var entry_path = path.path_join(entry_name)
		if dir.current_is_dir():
			_delete_directory_recursive(entry_path)
		else:
			DirAccess.remove_absolute(entry_path)
	dir.list_dir_end()
	DirAccess.remove_absolute(path)


func normalize_image(image, target_size: Vector2i):
	return normalize_image_with_adjustment(image, target_size, 1.0, 0.0, 0.0)


func normalize_image_with_adjustment(image, target_size: Vector2i, zoom: float, offset_x: float, offset_y: float):
	var working_image = image.duplicate()
	if working_image.is_compressed():
		var decompress_error = working_image.decompress()
		if decompress_error != OK:
			return null
	working_image.convert(Image.FORMAT_RGBA8)

	var scale_x = float(target_size.x) / float(max(working_image.get_width(), 1))
	var scale_y = float(target_size.y) / float(max(working_image.get_height(), 1))
	var scale_factor = max(scale_x, scale_y) * max(1.0, zoom)

	var resized_width = max(target_size.x, int(round(working_image.get_width() * scale_factor)))
	var resized_height = max(target_size.y, int(round(working_image.get_height() * scale_factor)))
	working_image.resize(resized_width, resized_height, Image.INTERPOLATE_LANCZOS)

	var extra_width = max(0, resized_width - target_size.x)
	var extra_height = max(0, resized_height - target_size.y)
	var crop_x = clamp(int(round(extra_width * 0.5 + (clamp(offset_x, -1.0, 1.0) * extra_width * 0.5))), 0, extra_width)
	var crop_y = clamp(int(round(extra_height * 0.5 + (clamp(offset_y, -1.0, 1.0) * extra_height * 0.5))), 0, extra_height)
	var normalized_image = Image.create(target_size.x, target_size.y, false, Image.FORMAT_RGBA8)
	normalized_image.blit_rect(
		working_image,
		Rect2i(crop_x, crop_y, target_size.x, target_size.y),
		Vector2i.ZERO
	)
	return normalized_image


func trim_transparent_margins(image):
	if image == null:
		return null
	var working_image = image.duplicate()
	if working_image.is_compressed():
		var decompress_error = working_image.decompress()
		if decompress_error != OK:
			return image
	working_image.convert(Image.FORMAT_RGBA8)
	var used_rect = working_image.get_used_rect()
	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
		return working_image
	if used_rect.position == Vector2i.ZERO and used_rect.size == Vector2i(working_image.get_width(), working_image.get_height()):
		return working_image
	var trimmed_image = Image.create(used_rect.size.x, used_rect.size.y, false, Image.FORMAT_RGBA8)
	trimmed_image.blit_rect(working_image, used_rect, Vector2i.ZERO)
	return trimmed_image


func build_full_art_preview(source_path: String, source_image, target_size_override: Vector2i = Vector2i.ZERO, zoom_boost: float = FULL_ART_STATIC_ZOOM_BOOST):
	if source_image == null:
		return null
	var target_size = target_size_override
	if target_size.x <= 0 or target_size.y <= 0:
		target_size = FULL_ART_TARGET_SIZE
	var adjustment = get_override_adjustment_state(source_path)
	return normalize_image_with_adjustment(
		source_image,
		target_size,
		float(adjustment.get("zoom", 1.0)) * max(zoom_boost, 1.0),
		float(adjustment.get("offset_x", 0.0)),
		float(adjustment.get("offset_y", 0.0))
	)


func refresh_all_portraits() -> void:
	if _batch_update_depth > 0:
		_batch_refresh_requested = true
		return
	_portrait_refresh_cursor = 0
	_visible_portrait_refresh_cursor = 0
	_needs_full_refresh = true
	_refresh_accumulator = REFRESH_INTERVAL
	_request_ancient_text_hover_refresh(true)
	_request_gif_playback_refresh(true)


func _request_card_navigation_portrait_refresh() -> void:
	if _manifest.is_empty():
		return
	var refresh_frames := PORTRAIT_EVENT_NAVIGATION_REFRESH_FRAMES if _event_driven_portrait_refresh_enabled else PORTRAIT_NAVIGATION_REFRESH_FRAMES
	_portrait_navigation_refresh_frames_remaining = max(_portrait_navigation_refresh_frames_remaining, refresh_frames)
	if !_event_driven_portrait_refresh_enabled:
		_needs_full_refresh = true
		_refresh_accumulator = REFRESH_INTERVAL


func _should_poll_visible_portrait_refresh() -> bool:
	return !_manifest.is_empty() and !_portrait_ref_ids.is_empty()


func set_event_driven_portrait_refresh_enabled(enabled: bool) -> void:
	_event_driven_portrait_refresh_enabled = enabled
	_visible_portrait_refresh_accumulator = 0.0


func _refresh_visible_tracked_portraits(max_items: int = PORTRAIT_NAVIGATION_REFRESH_BUDGET, use_cursor: bool = false) -> void:
	if max_items <= 0 or _portrait_ref_ids.is_empty():
		return
	if use_cursor:
		_refresh_visible_tracked_portraits_from_cursor(max_items)
		return
	var processed := 0
	for index in range(_portrait_ref_ids.size() - 1, -1, -1):
		var texture_rect = _get_tracked_portrait_at(index)
		if texture_rect == null:
			_remove_tracked_portrait_at(index)
			continue
		var card_root = _find_card_root(texture_rect)
		if card_root == null or !is_instance_valid(card_root) or !_is_node_visible_in_tree(card_root):
			continue
		if _is_multiplayer_expanded_deck_card_root(card_root):
			continue
		if texture_rect is CanvasItem and !(texture_rect as CanvasItem).is_visible_in_tree():
			continue
		_refresh_portrait_node(texture_rect)
		processed += 1
		if processed >= max_items:
			break


func _refresh_visible_tracked_portraits_from_cursor(max_items: int) -> void:
	if max_items <= 0 or _portrait_ref_ids.is_empty():
		_visible_portrait_refresh_cursor = 0
		return
	var processed := 0
	var scanned := 0
	var scan_limit = min(_portrait_ref_ids.size(), max(max_items * 4, max_items))
	while processed < max_items and scanned < scan_limit and !_portrait_ref_ids.is_empty():
		if _visible_portrait_refresh_cursor >= _portrait_ref_ids.size():
			_visible_portrait_refresh_cursor = 0
		var texture_rect = _get_tracked_portrait_at(_visible_portrait_refresh_cursor)
		if texture_rect == null:
			_remove_tracked_portrait_at(_visible_portrait_refresh_cursor)
			if _visible_portrait_refresh_cursor >= _portrait_ref_ids.size():
				_visible_portrait_refresh_cursor = 0
			continue
		_visible_portrait_refresh_cursor += 1
		scanned += 1
		var card_root = _find_card_root(texture_rect)
		if card_root == null or !is_instance_valid(card_root) or !_is_node_visible_in_tree(card_root):
			continue
		if _is_multiplayer_expanded_deck_card_root(card_root):
			continue
		if texture_rect is CanvasItem and !(texture_rect as CanvasItem).is_visible_in_tree():
			continue
		_refresh_portrait_node(texture_rect)
		processed += 1


func apply_override_to_texture_rect(texture_rect) -> void:
	if texture_rect == null:
		return
	_refresh_portrait_node(texture_rect)


func queue_card_override_refresh(card_node, invalidate_model_cache := false) -> void:
	if card_node == null or !is_instance_valid(card_node):
		return
	if invalidate_model_cache:
		card_node.set_meta(META_DEFERRED_CARD_REFRESH_INVALIDATE_MODEL, true)
	if bool(card_node.get_meta(META_DEFERRED_CARD_REFRESH_PENDING, false)):
		return
	card_node.set_meta(META_DEFERRED_CARD_REFRESH_PENDING, true)
	_apply_queued_card_override_refresh.call_deferred(card_node)


func _apply_queued_card_override_refresh(card_node) -> void:
	if card_node == null or !is_instance_valid(card_node):
		return
	var invalidate_model_cache = bool(card_node.get_meta(META_DEFERRED_CARD_REFRESH_INVALIDATE_MODEL, false))
	card_node.remove_meta(META_DEFERRED_CARD_REFRESH_PENDING)
	card_node.remove_meta(META_DEFERRED_CARD_REFRESH_INVALIDATE_MODEL)
	if invalidate_model_cache:
		invalidate_card_model_portrait_path_cache(card_node)
	if !card_needs_override_refresh(card_node):
		return
	var card_root = _get_card_refresh_root(card_node)
	if card_root == null:
		return
	for portrait_path in [
		"PortraitCanvasGroup/Portrait",
		"PortraitCanvasGroup/AncientPortrait"
	]:
		var portrait = card_root.get_node_or_null(portrait_path)
		if portrait is TextureRect:
			_refresh_portrait_node(portrait)


func _get_card_refresh_root(card_node):
	if card_node == null or !is_instance_valid(card_node):
		return null
	if _is_supported_card_root(card_node):
		return card_node
	var card_root = card_node.get_node_or_null("CardContainer")
	return card_root if _is_supported_card_root(card_root) else null


func card_needs_override_refresh(card_node) -> bool:
	var card_root = _get_card_refresh_root(card_node)
	if card_root == null:
		return false
	if bool(card_root.get_meta(META_ANCIENT_TEXT_OUTSIDE_APPLIED, false)):
		return true
	var full_art_layer = _get_full_art_layer(card_root)
	if full_art_layer is TextureRect and bool(full_art_layer.get_meta(META_FULL_ART_ACTIVE, false)):
		return true
	var portraits: Array = []
	for portrait_path in ["PortraitCanvasGroup/Portrait", "PortraitCanvasGroup/AncientPortrait"]:
		var portrait = card_root.get_node_or_null(portrait_path)
		if !(portrait is TextureRect):
			continue
		portraits.append(portrait)
		if bool(portrait.get_meta(META_OVERRIDE_ACTIVE, false)) or bool(portrait.get_meta(META_FULL_ART_ACTIVE, false)):
			return true
	if _manifest.is_empty():
		return false
	var source_key = _canonicalize_source_key(_get_card_root_source_path(card_root))
	if source_key != "" and _manifest.has(source_key):
		return true
	for portrait in portraits:
		var stored_source_key = _canonicalize_source_key(String(portrait.get_meta(META_SOURCE_PATH, "")))
		if stored_source_key != "" and _manifest.has(stored_source_key):
			return true
	return false


func _clear_source_overrides_from_tracked_portraits(source_path: String) -> void:
	var source_key = _canonicalize_source_key(source_path)
	for index in range(_portrait_ref_ids.size() - 1, -1, -1):
		var texture_rect = _get_tracked_portrait_at(index)
		if texture_rect == null:
			_remove_tracked_portrait_at(index)
			continue
		var card_root = _find_card_root(texture_rect)
		var tracked_source = String(texture_rect.get_meta(META_SOURCE_PATH, ""))
		var full_art_owner = ""
		if card_root != null:
			var full_art_layer = _get_full_art_layer(card_root)
			if full_art_layer is TextureRect:
				full_art_owner = String(full_art_layer.get_meta(META_FULL_ART_OWNER_PATH, ""))
		if _canonicalize_source_key(tracked_source) != source_key and _canonicalize_source_key(full_art_owner) != source_key:
			continue
		_clear_custom_full_art_layer(card_root)
		var restore_source = tracked_source if _canonicalize_source_key(tracked_source) == source_key else full_art_owner
		_restore_texture_rect_to_provider(texture_rect, restore_source)


func _clear_source_overrides_in_tree(node, source_path: String) -> void:
	if node == null:
		return
	if String(node.name) == "CardContainer":
		var card_root = node
		var full_art_owner := ""
		var full_art_layer = _get_full_art_layer(card_root)
		if full_art_layer is TextureRect:
			full_art_owner = String(full_art_layer.get_meta(META_FULL_ART_OWNER_PATH, ""))
		var root_source_path = _get_card_root_source_path(card_root)
		var source_key = _canonicalize_source_key(source_path)
		if _canonicalize_source_key(full_art_owner) == source_key or _canonicalize_source_key(root_source_path) == source_key:
			var restore_source = full_art_owner if _canonicalize_source_key(full_art_owner) == source_key else root_source_path
			var portrait = _find_named_descendant(card_root, "Portrait")
			var ancient_portrait = _find_named_descendant(card_root, "AncientPortrait")
			if portrait is TextureRect:
				_clear_custom_full_art_layer(card_root)
				var portrait_source = String(portrait.get_meta(META_SOURCE_PATH, ""))
				_restore_texture_rect_to_provider(portrait, portrait_source if _canonicalize_source_key(portrait_source) == source_key else restore_source)
			if ancient_portrait is TextureRect:
				var ancient_source = String(ancient_portrait.get_meta(META_SOURCE_PATH, ""))
				_restore_texture_rect_to_provider(ancient_portrait, ancient_source if _canonicalize_source_key(ancient_source) == source_key else restore_source)
			_queue_card_provider_reload(card_root)
	for child in node.get_children():
		_clear_source_overrides_in_tree(child, source_path)


func _restore_texture_rect_to_provider(texture_rect, source_path: String = "") -> void:
	if !(texture_rect is TextureRect):
		return
	var provider_source = _as_valid_card_art_source(source_path)
	if provider_source == "":
		provider_source = _as_valid_card_art_source(String(texture_rect.get_meta(META_SOURCE_PATH, "")))
	var restore_texture = _load_source_texture(provider_source) if provider_source != "" else null
	if !(restore_texture is Texture2D):
		restore_texture = texture_rect.get_meta(META_ORIGINAL_TEXTURE, null) if texture_rect.has_meta(META_ORIGINAL_TEXTURE) else null
	if restore_texture is Texture2D:
		texture_rect.texture = restore_texture
		texture_rect.set_meta(META_ORIGINAL_TEXTURE, restore_texture)
		texture_rect.set_meta(META_SOURCE_SIZE, Vector2i(restore_texture.get_width(), restore_texture.get_height()))
	if provider_source != "":
		texture_rect.set_meta(META_SOURCE_PATH, provider_source)
	texture_rect.set_meta(META_OVERRIDE_ACTIVE, false)
	texture_rect.set_meta(META_REFRESH_SIGNATURE, "")


func _queue_card_provider_reload(card_root) -> void:
	var card_node = card_root
	while card_node != null and !card_node.has_method("Reload"):
		card_node = card_node.get_parent()
	if card_node == null or bool(card_node.get_meta(META_PROVIDER_RELOAD_PENDING, false)):
		return
	card_node.set_meta(META_PROVIDER_RELOAD_PENDING, true)
	_reload_card_provider_deferred.call_deferred(card_node)


func _reload_card_provider_deferred(card_node) -> void:
	if card_node == null or !is_instance_valid(card_node):
		return
	card_node.remove_meta(META_PROVIDER_RELOAD_PENDING)
	if card_node.has_method("Reload"):
		card_node.call("Reload")


func _find_named_descendant_raw(node: Node, target_name: String):
	if node == null:
		return null
	for child in node.get_children():
		if String(child.name) == target_name:
			return child
		var nested = _find_named_descendant_raw(child, target_name)
		if nested != null:
			return nested
	return null


func _get_named_node_cache(node: Node) -> Dictionary:
	if node == null:
		return {}
	if node.has_meta(META_NAMED_NODE_CACHE):
		var cached = node.get_meta(META_NAMED_NODE_CACHE, {})
		if cached is Dictionary:
			return cached
	var cache: Dictionary = {}
	node.set_meta(META_NAMED_NODE_CACHE, cache)
	return cache


func _find_named_descendant(node: Node, target_name: String):
	if node == null:
		return null
	var cache = _get_named_node_cache(node)
	if cache.has(target_name):
		var cached_node = cache[target_name]
		if cached_node != null and is_instance_valid(cached_node):
			return cached_node
		cache.erase(target_name)
	var found = _find_named_descendant_raw(node, target_name)
	if found != null:
		cache[target_name] = found
		node.set_meta(META_NAMED_NODE_CACHE, cache)
	return found


func _is_supported_card_root(node) -> bool:
	return node != null and String(node.name) == "CardContainer" and node.get_node_or_null("PortraitCanvasGroup") != null


func _is_multiplayer_expanded_deck_card_root(card_root) -> bool:
	if card_root == null:
		return false
	if card_root.has_meta(META_SKIP_BACKGROUND_REFRESH):
		return bool(card_root.get_meta(META_SKIP_BACKGROUND_REFRESH, false))
	var current = card_root.get_parent()
	while current != null:
		var script = current.get_script()
		if script != null and String(script.resource_path).replace("\\", "/") == MULTIPLAYER_EXPANDED_STATE_SCRIPT_PATH:
			card_root.set_meta(META_SKIP_BACKGROUND_REFRESH, true)
			return true
		var deck_container = current.get_node_or_null("ScreenContents/Container/Cards/MarginContainer/CardContainer")
		var player_name = current.get_node_or_null("ScreenContents/Container/MarginContainer/PlayerNameLabel")
		if deck_container == card_root.get_parent() and player_name != null:
			card_root.set_meta(META_SKIP_BACKGROUND_REFRESH, true)
			return true
		current = current.get_parent()
	card_root.set_meta(META_SKIP_BACKGROUND_REFRESH, false)
	return false


func _find_card_root(texture_rect):
	var current = texture_rect
	var portrait_group = null
	while current != null:
		if String(current.name) == "PortraitCanvasGroup":
			portrait_group = current
		elif String(current.name) == "CardContainer":
			if portrait_group != null and portrait_group.get_parent() == current:
				return current
			return null
		current = current.get_parent()
	return null


func _is_card_root_inside_visible_inspect_screen(card_root) -> bool:
	var current = card_root
	while current != null:
		if String(current.name) == "InspectCardScreen":
			return _is_node_visible_in_tree(current)
		current = current.get_parent()
	return false


func _configure_full_art_layer(card_root, layer: TextureRect, inset: int = FULL_ART_INSET_STATIC) -> void:
	var reference_node = _find_named_descendant(card_root, "AncientPortrait")
	if reference_node == null:
		reference_node = _find_named_descendant(card_root, "Portrait")
	if reference_node == null:
		reference_node = _find_named_descendant(card_root, "AncientBorder")
	if reference_node == null:
		reference_node = _find_named_descendant(card_root, "AncientHighlight")
	if reference_node is TextureRect:
		var reference := reference_node as TextureRect
		layer.layout_mode = reference.layout_mode
		layer.anchor_left = reference.anchor_left
		layer.anchor_top = reference.anchor_top
		layer.anchor_right = reference.anchor_right
		layer.anchor_bottom = reference.anchor_bottom
		layer.offset_left = reference.offset_left + inset
		layer.offset_top = reference.offset_top + inset
		layer.offset_right = reference.offset_right - inset
		layer.offset_bottom = reference.offset_bottom - inset
		layer.expand_mode = reference.expand_mode
		layer.stretch_mode = reference.stretch_mode
		layer.scale = reference.scale
		layer.pivot_offset = reference.pivot_offset
		layer.rotation = reference.rotation
		layer.clip_contents = false
	else:
		layer.layout_mode = 1
		layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		layer.offset_left = inset
		layer.offset_top = inset
		layer.offset_right = -inset
		layer.offset_bottom = -inset
		layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		layer.stretch_mode = TextureRect.STRETCH_SCALE
		layer.scale = Vector2.ONE
		layer.pivot_offset = Vector2.ZERO
		layer.clip_contents = false
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	layer.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	layer.set_meta(META_FULL_ART_LAYER_INSET, inset)


func _get_or_create_full_art_layer(card_root, inset: int = FULL_ART_INSET_STATIC):
	if card_root == null:
		return null
	var host = _find_named_descendant(card_root, "PortraitCanvasGroup")
	if host == null:
		host = card_root
	var existing = host.get_node_or_null(FULL_ART_LAYER_NAME)
	if existing is TextureRect:
		if int((existing as TextureRect).get_meta(META_FULL_ART_LAYER_INSET, -9999)) != inset:
			_configure_full_art_layer(card_root, existing, inset)
		return existing
	var layer := TextureRect.new()
	layer.name = FULL_ART_LAYER_NAME
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_configure_full_art_layer(card_root, layer, inset)
	layer.visible = false
	host.add_child(layer)
	host.move_child(layer, 0)
	return layer


func _get_full_art_layer(card_root):
	if card_root == null:
		return null
	var host = _find_named_descendant(card_root, "PortraitCanvasGroup")
	if host == null:
		host = card_root
	var layer = host.get_node_or_null(FULL_ART_LAYER_NAME)
	return layer if layer is TextureRect else null


func _sync_active_custom_full_art_layer(card_root) -> void:
	if card_root == null:
		return
	var full_art_layer = _get_full_art_layer(card_root)
	if !(full_art_layer is TextureRect):
		return
	var layer := full_art_layer as TextureRect
	if !bool(layer.get_meta(META_FULL_ART_ACTIVE, false)):
		return
	var source_path = _canonicalize_source_key(String(layer.get_meta(META_FULL_ART_OWNER_PATH, "")))
	if source_path == "":
		return
	if layer.texture == null:
		var restored_texture = _get_override_texture(source_path, _should_animate_gif_card(card_root, source_path))
		if restored_texture == null:
			return
		layer.texture = restored_texture
	var entry = _manifest.get(source_path, null)
	var full_art_inset = FULL_ART_INSET_ANIMATED if _is_animated_entry(entry) else FULL_ART_INSET_STATIC
	_configure_full_art_layer(card_root, layer, full_art_inset)
	var portrait_canvas_group = _find_named_descendant(card_root, "PortraitCanvasGroup")
	_apply_full_art_portrait_mask(portrait_canvas_group)
	layer.visible = true
	layer.self_modulate = Color(1, 1, 1, 1)
	layer.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	_hide_base_portraits_for_custom_full_art(card_root)
	_sync_full_art_fire_rarity_color(card_root, source_path)


func _hide_base_portraits_for_custom_full_art(card_root) -> void:
	if card_root == null:
		return
	var portrait = _find_named_descendant(card_root, "Portrait")
	if portrait is CanvasItem:
		(portrait as CanvasItem).visible = false
		(portrait as CanvasItem).self_modulate = Color(1, 1, 1, 0)
	var ancient_portrait = _find_named_descendant(card_root, "AncientPortrait")
	if ancient_portrait is CanvasItem:
		(ancient_portrait as CanvasItem).visible = false
		(ancient_portrait as CanvasItem).self_modulate = Color(1, 1, 1, 0)


func _apply_full_art_portrait_mask(portrait_canvas_group) -> void:
	if !(portrait_canvas_group is CanvasGroup):
		return
	var canvas_group := portrait_canvas_group as CanvasGroup
	if !canvas_group.has_meta(META_PORTRAIT_GROUP_ORIGINAL_MATERIAL):
		canvas_group.set_meta(META_PORTRAIT_GROUP_ORIGINAL_MATERIAL, canvas_group.material)
	canvas_group.visible = true
	canvas_group.material = FULL_ART_MASK_MATERIAL


func _restore_full_art_portrait_mask(portrait_canvas_group) -> void:
	if !(portrait_canvas_group is CanvasGroup):
		return
	var canvas_group := portrait_canvas_group as CanvasGroup
	if !canvas_group.has_meta(META_PORTRAIT_GROUP_ORIGINAL_MATERIAL):
		return
	var original_material = canvas_group.get_meta(META_PORTRAIT_GROUP_ORIGINAL_MATERIAL, null)
	canvas_group.material = original_material if original_material is Material else null
	canvas_group.remove_meta(META_PORTRAIT_GROUP_ORIGINAL_MATERIAL)


func _ensure_ancient_portrait_mask(card_root) -> void:
	if !_is_card_root_ancient_layout(card_root):
		return
	var portrait_canvas_group = _find_named_descendant(card_root, "PortraitCanvasGroup")
	if !(portrait_canvas_group is CanvasGroup):
		return
	var canvas_group := portrait_canvas_group as CanvasGroup
	if canvas_group.material == null:
		canvas_group.material = FULL_ART_MASK_MATERIAL


func _is_card_root_ancient_layout(card_root) -> bool:
	if card_root == null:
		return false
	var ancient_portrait = _find_named_descendant(card_root, "AncientPortrait")
	var portrait = _find_named_descendant(card_root, "Portrait")
	return ancient_portrait is CanvasItem and (ancient_portrait as CanvasItem).visible and !(portrait is CanvasItem and (portrait as CanvasItem).visible)


func _get_texture_rect_known_source_path(texture_rect) -> String:
	if !(texture_rect is TextureRect):
		return ""
	if texture_rect.has_meta(META_SOURCE_PATH):
		var stored_source = _canonicalize_source_key(String(texture_rect.get_meta(META_SOURCE_PATH, "")))
		if stored_source != "":
			return stored_source
	var texture = (texture_rect as TextureRect).texture
	if texture is Texture2D:
		return _canonicalize_source_key(_resolve_texture_source_path(texture_rect, texture))
	return ""


func _get_ancient_text_layout_source_path(card_root) -> String:
	if card_root == null:
		return ""
	var source_path = _canonicalize_source_key(_get_card_root_source_path(card_root))
	if source_path != "":
		return source_path
	var full_art_layer = _get_full_art_layer(card_root)
	if full_art_layer is TextureRect and bool(full_art_layer.get_meta(META_FULL_ART_ACTIVE, false)):
		source_path = _canonicalize_source_key(String(full_art_layer.get_meta(META_FULL_ART_OWNER_PATH, "")))
		if source_path != "":
			return source_path
	var ancient_portrait = _find_named_descendant(card_root, "AncientPortrait")
	source_path = _get_texture_rect_known_source_path(ancient_portrait)
	if source_path != "":
		return source_path
	var portrait = _find_named_descendant(card_root, "Portrait")
	return _get_texture_rect_known_source_path(portrait)


func _store_ancient_text_layout_defaults(card_root, description_label, ancient_text_bg) -> Dictionary:
	if card_root == null:
		return {}
	if card_root.has_meta(META_ANCIENT_TEXT_LAYOUT_DEFAULTS):
		var stored_defaults = card_root.get_meta(META_ANCIENT_TEXT_LAYOUT_DEFAULTS, {})
		return stored_defaults if stored_defaults is Dictionary else {}
	if !(description_label is Control):
		return {}
	var is_ancient_layout = _is_card_root_ancient_layout(card_root)
	var full_art_layer = _get_full_art_layer(card_root)
	var custom_full_art_active = full_art_layer is TextureRect and bool(full_art_layer.get_meta(META_FULL_ART_ACTIVE, false)) and !is_ancient_layout
	var default_description_visible: bool = bool(description_label.visible)
	if custom_full_art_active:
		default_description_visible = true
	var default_ancient_text_bg_visible: bool = false
	if ancient_text_bg is CanvasItem:
		default_ancient_text_bg_visible = (ancient_text_bg as CanvasItem).visible
	if is_ancient_layout:
		default_ancient_text_bg_visible = true
	if custom_full_art_active:
		default_ancient_text_bg_visible = false
	var defaults := {
		"offset_left": description_label.offset_left,
		"offset_top": description_label.offset_top,
		"offset_right": description_label.offset_right,
		"offset_bottom": description_label.offset_bottom,
		"z_index": description_label.z_index,
		"description_visible": default_description_visible,
		"ancient_text_bg_visible": default_ancient_text_bg_visible
	}
	var type_plaque = _find_named_descendant(card_root, "TypePlaque")
	if type_plaque is CanvasItem:
		defaults["type_plaque_visible"] = true if is_ancient_layout or custom_full_art_active else type_plaque.visible
	card_root.set_meta(META_ANCIENT_TEXT_LAYOUT_DEFAULTS, defaults)
	return defaults


func _restore_ancient_text_layout(card_root, description_label, ancient_text_bg, defaults: Dictionary) -> void:
	if !(description_label is Control):
		return
	description_label.offset_left = float(defaults.get("offset_left", description_label.offset_left))
	description_label.offset_top = float(defaults.get("offset_top", description_label.offset_top))
	description_label.offset_right = float(defaults.get("offset_right", description_label.offset_right))
	description_label.offset_bottom = float(defaults.get("offset_bottom", description_label.offset_bottom))
	description_label.z_index = int(defaults.get("z_index", description_label.z_index))
	description_label.visible = bool(defaults.get("description_visible", description_label.visible))
	if ancient_text_bg is CanvasItem:
		ancient_text_bg.visible = bool(defaults.get("ancient_text_bg_visible", ancient_text_bg.visible))
	var type_plaque = _find_named_descendant(card_root, "TypePlaque")
	if type_plaque is CanvasItem:
		type_plaque.visible = bool(defaults.get("type_plaque_visible", type_plaque.visible))


func _is_custom_full_art_card_root_active(card_root) -> bool:
	if card_root == null or _is_card_root_ancient_layout(card_root):
		return false
	var full_art_layer = _get_full_art_layer(card_root)
	return full_art_layer is TextureRect and bool(full_art_layer.get_meta(META_FULL_ART_ACTIVE, false))


func _enforce_custom_full_art_layer_visibility(card_root) -> void:
	if !_is_custom_full_art_card_root_active(card_root):
		return
	_sync_active_custom_full_art_layer(card_root)
	for node_name in ["PortraitBorder", "Frame", "TitleBanner"]:
		var hidden_layer = _find_named_descendant(card_root, node_name)
		if hidden_layer is CanvasItem:
			hidden_layer.visible = false
	for node_name in ["AncientHighlight", "AncientBorder", "AncientBanner"]:
		var visible_layer = _find_named_descendant(card_root, node_name)
		if visible_layer is CanvasItem:
			visible_layer.visible = true
	_sync_full_art_fire_rarity_color(card_root)


func _is_card_root_ancient_text_outside_eligible(card_root, source_path: String = "", is_ancient_layout := false) -> bool:
	if card_root == null:
		return false
	var resolved_source_path = _canonicalize_source_key(source_path)
	if resolved_source_path == "":
		resolved_source_path = _get_ancient_text_layout_source_path(card_root)
	if is_ancient_layout:
		return true
	return resolved_source_path != "" and is_full_art_mode(resolved_source_path)


func _apply_ancient_text_outside_layout(card_root) -> void:
	if card_root == null:
		return
	var was_moved_outside = bool(card_root.get_meta(META_ANCIENT_TEXT_OUTSIDE_APPLIED, false))
	if _ancient_text_outside_by_source.is_empty() and !was_moved_outside:
		return
	var description_label = _find_named_descendant(card_root, "DescriptionLabel")
	if !(description_label is RichTextLabel):
		return
	var ancient_text_bg = _find_named_descendant(card_root, "AncientTextBg")
	var defaults = _store_ancient_text_layout_defaults(card_root, description_label, ancient_text_bg)
	if defaults.is_empty():
		return
	var source_path = _get_ancient_text_layout_source_path(card_root)
	var is_ancient_layout = _is_card_root_ancient_layout(card_root)
	var should_move_outside = _is_card_root_ancient_text_outside_eligible(card_root, source_path, is_ancient_layout) and is_ancient_text_outside_enabled(source_path)
	if should_move_outside:
		card_root.set_meta(META_ANCIENT_TEXT_OUTSIDE_APPLIED, true)
		description_label.visible = false
		if ancient_text_bg is CanvasItem:
			ancient_text_bg.visible = false
		var type_plaque = _find_named_descendant(card_root, "TypePlaque")
		if type_plaque is CanvasItem:
			type_plaque.visible = false
		_enforce_custom_full_art_layer_visibility(card_root)
		return
	_restore_ancient_text_layout(card_root, description_label, ancient_text_bg, defaults)
	if was_moved_outside:
		card_root.set_meta(META_ANCIENT_TEXT_OUTSIDE_APPLIED, false)
	_enforce_custom_full_art_layer_visibility(card_root)
	if _is_card_root_ancient_text_outside_eligible(card_root, source_path, is_ancient_layout) and ancient_text_bg is CanvasItem:
		_apply_full_art_card_type_style(card_root, ancient_text_bg)
		ancient_text_bg.visible = true


func _get_control_rect_global(control) -> Rect2:
	if !(control is Control):
		return Rect2()
	var casted = control as Control
	if casted.has_method("get_global_rect"):
		var rect = casted.get_global_rect()
		if rect is Rect2:
			return rect
	return Rect2(casted.global_position, casted.size * casted.scale)


func _get_card_visual_rect_global(card_root) -> Rect2:
	if card_root == null:
		return Rect2()
	var reference_nodes = [
		_get_full_art_layer(card_root),
		_find_named_descendant(card_root, "AncientBorder"),
		_find_named_descendant(card_root, "AncientPortrait"),
		_find_named_descendant(card_root, "Portrait"),
		_find_named_descendant(card_root, "Frame")
	]
	var merged_rect = Rect2()
	var has_rect := false
	for reference_node in reference_nodes:
		if reference_node is Control and (!(reference_node is CanvasItem) or (reference_node as CanvasItem).is_visible_in_tree()):
			var reference_rect = _get_control_rect_global(reference_node)
			if reference_rect.size.x > 0.0 and reference_rect.size.y > 0.0:
				merged_rect = reference_rect if !has_rect else merged_rect.merge(reference_rect)
				has_rect = true
	if has_rect:
		return merged_rect
	if card_root is Control and (!(card_root is CanvasItem) or (card_root as CanvasItem).is_visible_in_tree()):
		return _get_control_rect_global(card_root)
	return Rect2()


func _inset_rect(rect: Rect2, inset: float) -> Rect2:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return rect
	var safe_inset = min(inset, min(rect.size.x, rect.size.y) * 0.2)
	return Rect2(rect.position + Vector2(safe_inset, safe_inset), rect.size - Vector2(safe_inset * 2.0, safe_inset * 2.0))


func _get_card_hover_rect_global(card_root) -> Rect2:
	if card_root == null:
		return Rect2()
	var anchor_control = _get_card_hover_anchor_control(card_root)
	if anchor_control is Control:
		var anchor_rect = _get_control_rect_global(anchor_control)
		if anchor_rect.size.x > 0.0 and anchor_rect.size.y > 0.0:
			return _inset_rect(anchor_rect, ANCIENT_TEXT_HOVER_HITBOX_INSET)
	var visual_rect = _get_card_visual_rect_global(card_root)
	return _inset_rect(visual_rect, ANCIENT_TEXT_HOVER_HITBOX_INSET)


func _normalize_ancient_text_tooltip_text(text: String) -> String:
	var normalized = text.strip_edges()
	normalized = normalized.replace("[center]", "")
	normalized = normalized.replace("[/center]", "")
	normalized = normalized.replace("\r", "")
	while normalized.contains("\n\n\n"):
		normalized = normalized.replace("\n\n\n", "\n\n")
	return normalized.strip_edges()


func _get_card_description_text(card_root) -> String:
	if card_root == null:
		return ""
	var model = _get_card_model_from_root(card_root)
	if model != null:
		var pile_type = 0
		var current = card_root
		while current != null:
			var displaying_pile = current.get("DisplayingPile")
			if displaying_pile != null:
				pile_type = int(displaying_pile)
				break
			current = current.get_parent()
		if model.has_method("GetDescriptionForPile"):
			var model_description = String(model.call("GetDescriptionForPile", pile_type, null))
			if model_description.strip_edges() != "":
				return model_description
		if model.has_method("get_description_for_pile"):
			var snake_model_description = String(model.call("get_description_for_pile", pile_type, null))
			if snake_model_description.strip_edges() != "":
				return snake_model_description
	var description_label = _find_named_descendant(card_root, "DescriptionLabel")
	if description_label is RichTextLabel:
		if description_label.has_method("get_parsed_text"):
			return String(description_label.call("get_parsed_text"))
		return String((description_label as RichTextLabel).text)
	return ""


func _get_hover_tips_container():
	if _hover_tips_container_cache != null and is_instance_valid(_hover_tips_container_cache):
		return _hover_tips_container_cache
	var root = get_tree().root if get_tree() != null else null
	if root == null:
		return null
	_hover_tips_container_cache = root.find_child("HoverTipsContainer", true, false)
	return _hover_tips_container_cache


func _get_ancient_text_tip_parent():
	var hover_tips_container = _get_hover_tips_container()
	if hover_tips_container != null:
		return hover_tips_container
	var tree = get_tree()
	if tree == null:
		return null
	return tree.root


func _is_mouse_over_card_root(card_root, mouse_position: Vector2) -> bool:
	var card_rect = _get_card_hover_rect_global(card_root)
	return card_rect.size.x > 0.0 and card_rect.size.y > 0.0 and card_rect.has_point(mouse_position)


func _is_node_visible_in_tree(node) -> bool:
	if node is CanvasItem:
		return (node as CanvasItem).is_visible_in_tree()
	return node != null and is_instance_valid(node)


func _is_hover_valid_ancient_text_card_root(card_root) -> bool:
	if card_root == null or !is_instance_valid(card_root):
		return false
	if !_is_node_visible_in_tree(card_root):
		return false
	var source_path = _get_ancient_text_layout_source_path(card_root)
	if source_path == "":
		return false
	if !_is_card_root_ancient_text_outside_eligible(card_root, source_path, _is_card_root_ancient_layout(card_root)):
		return false
	return is_ancient_text_outside_enabled(source_path)


func _has_animated_overrides() -> bool:
	if !_animated_overrides_cache_dirty:
		return _has_animated_overrides_cached
	_has_animated_overrides_cached = false
	for source_path in _manifest.keys():
		if _is_animated_entry(_manifest.get(source_path, null)):
			_has_animated_overrides_cached = true
			break
	_animated_overrides_cache_dirty = false
	return _has_animated_overrides_cached


func _is_animated_override_source(source_path: String) -> bool:
	source_path = _canonicalize_source_key(source_path)
	if source_path == "" or !_manifest.has(source_path):
		return false
	return _is_animated_entry(_manifest.get(source_path, null))


func _get_gif_override_source_for_card_root(card_root) -> String:
	if card_root == null or !is_instance_valid(card_root):
		return ""
	if !_is_node_visible_in_tree(card_root):
		return ""
	var source_path = _canonicalize_source_key(_get_ancient_text_layout_source_path(card_root))
	if _is_animated_override_source(source_path):
		return source_path
	return ""


func _is_valid_gif_card_root(card_root) -> bool:
	return _get_gif_override_source_for_card_root(card_root) != ""


func _find_animated_gif_card_root_at_position(mouse_position: Vector2):
	var best_root = null
	var best_area: float = INF
	var seen_roots := {}
	for index in range(_portrait_ref_ids.size() - 1, -1, -1):
		var texture_rect = _get_tracked_portrait_at(index)
		if texture_rect == null:
			_remove_tracked_portrait_at(index)
			continue
		var card_root = _find_card_root(texture_rect)
		if card_root == null or seen_roots.has(card_root):
			continue
		seen_roots[card_root] = true
		if !_is_valid_gif_card_root(card_root):
			continue
		var card_rect = _get_card_hover_rect_global(card_root)
		if card_rect.size.x <= 0.0 or card_rect.size.y <= 0.0 or !card_rect.has_point(mouse_position):
			continue
		var area = card_rect.size.x * card_rect.size.y
		if area < best_area:
			best_area = area
			best_root = card_root
	return best_root


func _get_active_gif_card_root():
	if _ancient_text_left_mouse_down and _pressed_gif_card_root != null and is_instance_valid(_pressed_gif_card_root):
		if _get_gif_override_source_for_card_root(_pressed_gif_card_root) == _pressed_gif_card_source_path:
			return _pressed_gif_card_root
	var tree = get_tree()
	if tree != null:
		var inspect_card_root = _find_visible_gif_inspect_card_root(tree.root)
		if inspect_card_root != null:
			return inspect_card_root
	var viewport = get_viewport()
	if viewport == null:
		return null
	return _find_animated_gif_card_root_at_position(viewport.get_mouse_position())


func _should_animate_gif_card(card_root, source_path: String, active_root = null) -> bool:
	source_path = _canonicalize_source_key(source_path)
	if source_path == "" or !_is_animated_override_source(source_path):
		return false
	if !is_gif_hover_playback_only_enabled_for_source(source_path):
		return true
	if card_root == null or !is_instance_valid(card_root):
		return false
	if active_root == null:
		active_root = _get_active_gif_card_root()
	return active_root != null and is_instance_valid(active_root) and card_root == active_root


func _find_gif_card_root_in_node(node):
	if node == null or !is_instance_valid(node):
		return null
	if String(node.name) == "CardContainer" and _is_valid_gif_card_root(node):
		return node
	var children = node.get_children()
	for index in range(children.size() - 1, -1, -1):
		var found = _find_gif_card_root_in_node(children[index])
		if found != null:
			return found
	return null


func _find_visible_gif_inspect_card_root(node):
	if node == null or !is_instance_valid(node):
		return null
	if String(node.name) == "InspectCardScreen" and _is_node_visible_in_tree(node):
		var screen_card = _find_gif_card_root_in_node(node)
		if screen_card != null:
			return screen_card
	var children = node.get_children()
	for index in range(children.size() - 1, -1, -1):
		var found = _find_visible_gif_inspect_card_root(children[index])
		if found != null:
			return found
	return null


func _apply_gif_texture_to_target(target, source_path: String, texture, animate: bool) -> void:
	if !(target is TextureRect) or !(texture is Texture2D):
		return
	var texture_rect = target as TextureRect
	if texture_rect.texture == texture and String(texture_rect.get_meta(META_GIF_PLAYBACK_SOURCE, "")) == source_path and bool(texture_rect.get_meta(META_GIF_PLAYBACK_ACTIVE, false)) == animate:
		return
	if texture_rect.texture != texture:
		texture_rect.texture = texture
	texture_rect.set_meta(META_GIF_PLAYBACK_ACTIVE, animate)
	texture_rect.set_meta(META_GIF_PLAYBACK_SOURCE, source_path)


func _sync_gif_texture_for_portrait(texture_rect, active_root) -> void:
	if !(texture_rect is TextureRect):
		return
	var card_root = _find_card_root(texture_rect)
	if card_root == null or !is_instance_valid(card_root) or !_is_node_visible_in_tree(card_root):
		return
	var source_path = _get_gif_override_source_for_card_root(card_root)
	if source_path == "":
		return
	var entry = _manifest.get(source_path, null)
	if !(entry is Dictionary):
		return
	var display_mode = String(entry.get("display_mode", DISPLAY_MODE_DEFAULT))
	var should_animate = _should_animate_gif_card(card_root, source_path, active_root)
	var override_texture = _get_override_texture(source_path, should_animate)
	if override_texture == null:
		return
	var node_name = String(texture_rect.name)
	if display_mode == DISPLAY_MODE_FULL_ART:
		if node_name != "Portrait":
			return
		var full_art_layer = _get_full_art_layer(card_root)
		if full_art_layer is TextureRect and bool(full_art_layer.get_meta(META_FULL_ART_ACTIVE, false)) and String(full_art_layer.get_meta(META_FULL_ART_OWNER_PATH, "")) == source_path:
			_apply_gif_texture_to_target(full_art_layer, source_path, override_texture, should_animate)
		return
	if node_name != "Portrait" and node_name != "AncientPortrait":
		return
	if texture_rect is CanvasItem and !(texture_rect as CanvasItem).is_visible_in_tree():
		return
	_apply_gif_texture_to_target(texture_rect, source_path, override_texture, should_animate)


func _refresh_gif_playback_state() -> void:
	if !_has_animated_overrides():
		_gif_last_active_card_root = null
		_gif_last_active_source_path = ""
		_gif_playback_refresh_requested = false
		return
	var active_root = _get_active_gif_card_root()
	if active_root != null and is_instance_valid(active_root):
		_gif_last_active_card_root = active_root
		_gif_last_active_source_path = _get_gif_override_source_for_card_root(active_root)
	else:
		_gif_last_active_card_root = null
		_gif_last_active_source_path = ""
	for index in range(_portrait_ref_ids.size() - 1, -1, -1):
		var texture_rect = _get_tracked_portrait_at(index)
		if texture_rect == null:
			_remove_tracked_portrait_at(index)
			continue
		_sync_gif_texture_for_portrait(texture_rect, active_root)
	_gif_playback_refresh_requested = false


func _find_ancient_text_card_root_at_position(mouse_position: Vector2):
	var best_root = null
	var best_area: float = INF
	var seen_roots := {}
	for index in range(_portrait_ref_ids.size() - 1, -1, -1):
		var texture_rect = _get_tracked_portrait_at(index)
		if texture_rect == null:
			_remove_tracked_portrait_at(index)
			continue
		var card_root = _find_card_root(texture_rect)
		if card_root == null or seen_roots.has(card_root):
			continue
		seen_roots[card_root] = true
		if !_is_hover_valid_ancient_text_card_root(card_root):
			continue
		var card_rect = _get_card_hover_rect_global(card_root)
		if card_rect.size.x <= 0.0 or card_rect.size.y <= 0.0 or !card_rect.has_point(mouse_position):
			continue
		var area = card_rect.size.x * card_rect.size.y
		if area < best_area:
			best_area = area
			best_root = card_root
	return best_root


func _find_ancient_text_card_root_in_node(node):
	if node == null or !is_instance_valid(node):
		return null
	if String(node.name) == "CardContainer" and _is_hover_valid_ancient_text_card_root(node):
		return node
	var children = node.get_children()
	for index in range(children.size() - 1, -1, -1):
		var found = _find_ancient_text_card_root_in_node(children[index])
		if found != null:
			return found
	return null


func _find_ancient_text_card_root_in_node_for_source(node, source_path: String):
	if node == null or !is_instance_valid(node):
		return null
	if String(node.name) == "CardContainer" and _is_hover_valid_ancient_text_card_root(node):
		var node_source = _get_ancient_text_layout_source_path(node)
		if source_path == "" or node_source == source_path:
			return node
	var children = node.get_children()
	for index in range(children.size() - 1, -1, -1):
		var found = _find_ancient_text_card_root_in_node_for_source(children[index], source_path)
		if found != null:
			return found
	return null


func _find_visible_ancient_text_inspect_card_root_for_source(node, source_path: String):
	if node == null or !is_instance_valid(node):
		return null
	if String(node.name) == "InspectCardScreen" and _is_node_visible_in_tree(node):
		var screen_card = _find_ancient_text_card_root_in_node_for_source(node, source_path)
		if screen_card != null:
			return screen_card
	var children = node.get_children()
	for index in range(children.size() - 1, -1, -1):
		var found = _find_visible_ancient_text_inspect_card_root_for_source(children[index], source_path)
		if found != null:
			return found
	return null


func _try_show_pending_ancient_text_click_tip() -> bool:
	if _ancient_text_dragging:
		_clear_pending_ancient_text_click()
		_hide_ancient_text_hover_tip()
		return false
	if _pending_ancient_text_click_position == Vector2.INF:
		return false
	var tree = get_tree()
	var card_root = null
	if tree != null and _pending_ancient_text_click_source_path != "":
		card_root = _find_visible_ancient_text_inspect_card_root_for_source(tree.root, _pending_ancient_text_click_source_path)
	if card_root == null:
		card_root = _pending_ancient_text_click_card_root
	if !_is_hover_valid_ancient_text_card_root(card_root):
		card_root = _find_ancient_text_card_root_at_position(_pending_ancient_text_click_position)
		if card_root != null and _pending_ancient_text_click_source_path != "" and _get_ancient_text_layout_source_path(card_root) != _pending_ancient_text_click_source_path:
			card_root = null
	if card_root != null and _show_ancient_text_tip_for_card(card_root, true):
		_pending_ancient_text_click_frames = 0
		_pending_ancient_text_click_position = Vector2.INF
		_pending_ancient_text_click_card_root = null
		_pending_ancient_text_click_source_path = ""
		_pending_ancient_text_click_from_hitbox = false
		return true
	if _pending_ancient_text_click_frames <= 0:
		_pending_ancient_text_click_position = Vector2.INF
		_pending_ancient_text_click_card_root = null
		_pending_ancient_text_click_source_path = ""
		_pending_ancient_text_click_from_hitbox = false
		_hide_ancient_text_hover_tip()
	return false


func _find_hovered_ancient_text_card_root():
	var viewport = get_viewport()
	if viewport == null:
		return null
	var mouse_position = viewport.get_mouse_position()
	var card_root = _find_ancient_text_card_root_at_position(mouse_position)
	if card_root != null:
		return card_root
	if _is_hover_valid_ancient_text_card_root(_ancient_text_hover_tip_owner) and _is_mouse_over_card_root(_ancient_text_hover_tip_owner, mouse_position):
		return _ancient_text_hover_tip_owner
	return null


func _get_hover_tip_candidate_control(node):
	if !(node is Control):
		return null
	if node == _ancient_text_hover_tip:
		return null
	if node is CanvasItem and !(node as CanvasItem).is_visible_in_tree():
		return null
	var root_control = node as Control
	var text_container = root_control.get_node_or_null("textHoverTipContainer")
	if text_container is Control and (text_container as CanvasItem).is_visible_in_tree():
		return text_container
	return root_control if root_control.is_visible_in_tree() else null


func _get_card_hover_anchor_control(card_root):
	var current = card_root
	while current != null:
		var direct_hitbox = current.get_node_or_null("Hitbox") if current is Node else null
		if direct_hitbox is Control and _is_node_visible_in_tree(direct_hitbox):
			return direct_hitbox
		current = current.get_parent()
	if card_root is Control:
		return card_root
	return null


func _track_ancient_text_card_hitbox(card_root) -> void:
	if card_root == null or !is_instance_valid(card_root):
		return
	var hitbox = _find_named_descendant(card_root, "Hitbox")
	if !(hitbox is Control):
		hitbox = _get_card_hover_anchor_control(card_root)
	if !(hitbox is Control):
		return
	if bool(hitbox.get_meta(META_ANCIENT_TEXT_HITBOX_CONNECTED, false)):
		return
	var input_callable = Callable(self, "_on_ancient_text_card_hitbox_gui_input").bind(card_root)
	if !(hitbox as Control).gui_input.is_connected(input_callable):
		(hitbox as Control).gui_input.connect(input_callable)
	hitbox.set_meta(META_ANCIENT_TEXT_HITBOX_CONNECTED, true)


func _get_original_hover_tip_position(card_root, tooltip_size: Vector2) -> Vector2:
	var viewport_rect = _get_viewport_visible_rect()
	var viewport_right = viewport_rect.position.x + viewport_rect.size.x
	var viewport_bottom = viewport_rect.position.y + viewport_rect.size.y
	var anchor_control = _get_card_hover_anchor_control(card_root)
	var anchor_rect = _get_control_rect_global(anchor_control)
	if anchor_rect.size.x <= 0.0 or anchor_rect.size.y <= 0.0:
		anchor_rect = _get_card_visual_rect_global(card_root)
	if anchor_rect.size.x <= 0.0 or anchor_rect.size.y <= 0.0:
		return Vector2.INF
	var margin := 8.0
	var prefers_right = anchor_rect.position.x < viewport_rect.position.x + viewport_rect.size.x * 0.75
	var right_position = Vector2(anchor_rect.position.x + anchor_rect.size.x + 10.0, anchor_rect.position.y)
	var left_position = Vector2(anchor_rect.position.x - tooltip_size.x - 10.0, anchor_rect.position.y)
	var next_position = right_position if prefers_right else left_position
	if next_position.x + tooltip_size.x > viewport_right - margin:
		next_position = left_position
	elif next_position.x < viewport_rect.position.x + margin:
		next_position = right_position
	next_position.x = clamp(next_position.x, viewport_rect.position.x + margin, viewport_right - tooltip_size.x - margin)
	if next_position.y + tooltip_size.y > viewport_bottom:
		next_position.y = viewport_bottom - tooltip_size.y
	next_position.y = max(next_position.y, viewport_rect.position.y + margin)
	return next_position


func _find_existing_hover_tip_rect_for_card(card_root) -> Rect2:
	var hover_tips_container = _get_hover_tips_container()
	if hover_tips_container == null:
		return Rect2()
	var expected_position = _get_original_hover_tip_position(card_root, Vector2(360.0, 118.0))
	if expected_position == Vector2.INF:
		return Rect2()
	var best_rect = Rect2()
	var best_distance: float = INF
	for child in hover_tips_container.get_children():
		if child == _ancient_text_hover_tip:
			continue
		var candidate_control = _get_hover_tip_candidate_control(child)
		if !(candidate_control is Control):
			continue
		var candidate_rect = _get_control_rect_global(candidate_control)
		if candidate_rect.size.x <= 0.0 or candidate_rect.size.y <= 0.0:
			continue
		var delta = candidate_rect.position - expected_position
		if abs(delta.x) > 140.0 or abs(delta.y) > 180.0:
			continue
		var distance = delta.length_squared()
		if distance < best_distance:
			best_distance = distance
			best_rect = candidate_rect
	return best_rect


func _get_viewport_visible_rect() -> Rect2:
	var viewport = get_viewport()
	if viewport == null:
		return Rect2(Vector2.ZERO, DisplayServer.window_get_size())
	var visible_rect = viewport.get_visible_rect()
	if visible_rect.size.x <= 0.0 or visible_rect.size.y <= 0.0:
		return Rect2(Vector2.ZERO, DisplayServer.window_get_size())
	return visible_rect


func _get_ancient_text_hover_tip_size() -> Vector2:
	if _ancient_text_hover_tip == null or !is_instance_valid(_ancient_text_hover_tip):
		return Vector2(400.0, 118.0)
	if _ancient_text_hover_tip.has_method("reset_size"):
		_ancient_text_hover_tip.reset_size()
	var min_size = _ancient_text_hover_tip.get_combined_minimum_size()
	var current_size = _ancient_text_hover_tip.size
	return Vector2(
		max(max(min_size.x, current_size.x), 320.0),
		max(max(min_size.y, current_size.y), 90.0)
	)


func _ensure_ancient_text_hover_tip() -> void:
	if _ancient_text_hover_tip != null and is_instance_valid(_ancient_text_hover_tip):
		return
	var instance = HOVER_TIP_SCENE.instantiate()
	if !(instance is Control):
		return
	_ancient_text_hover_tip = instance as Control
	_ancient_text_hover_tip.name = "CardArtAncientTextHoverTip"
	_ancient_text_hover_tip.visible = false
	_ancient_text_hover_tip.top_level = true
	_ancient_text_hover_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ancient_text_hover_tip.z_as_relative = false
	_ancient_text_hover_tip.z_index = 5000
	_ancient_text_hover_tip_title = _ancient_text_hover_tip.get_node_or_null("%Title")
	var icon = _ancient_text_hover_tip.get_node_or_null("%Icon")
	if icon is CanvasItem:
		(icon as CanvasItem).visible = false
	_ancient_text_hover_tip_description = _ancient_text_hover_tip.get_node_or_null("%Description")
	var tip_parent = _get_ancient_text_tip_parent()
	if tip_parent != null:
		tip_parent.add_child(_ancient_text_hover_tip)


func _hide_ancient_text_hover_tip() -> void:
	if _ancient_text_hover_tip == null or !is_instance_valid(_ancient_text_hover_tip):
		return
	_ancient_text_hover_tip.visible = false
	_ancient_text_hover_tip_owner = null
	_ancient_text_hover_tip_last_position = Vector2.INF
	_ancient_text_hover_tip_locked = false


func _get_ancient_text_hover_tip_position(card_root) -> Vector2:
	var viewport_rect = _get_viewport_visible_rect()
	var tooltip_size = _get_ancient_text_hover_tip_size()
	var margin := 8.0
	var viewport_bottom = viewport_rect.position.y + viewport_rect.size.y
	var viewport_right = viewport_rect.position.x + viewport_rect.size.x
	var next_position = Vector2.INF
	var existing_tip_rect = _find_existing_hover_tip_rect_for_card(card_root)
	if existing_tip_rect.size.x > 0.0 and existing_tip_rect.size.y > 0.0:
		next_position = existing_tip_rect.position + Vector2(0.0, existing_tip_rect.size.y + 5.0)
	else:
		next_position = _get_original_hover_tip_position(card_root, tooltip_size)
	if next_position == Vector2.INF:
		return Vector2.INF
	next_position.x = clamp(next_position.x, viewport_rect.position.x + margin, viewport_right - tooltip_size.x - margin)
	next_position.y = clamp(next_position.y, viewport_rect.position.y + margin, viewport_bottom - tooltip_size.y - margin)
	return next_position


func _position_ancient_text_hover_tip(card_root) -> void:
	if _ancient_text_hover_tip == null or !is_instance_valid(_ancient_text_hover_tip):
		return
	var next_position = _get_ancient_text_hover_tip_position(card_root)
	if next_position == Vector2.INF:
		return
	if _ancient_text_hover_tip_last_position.is_equal_approx(next_position):
		return
	_ancient_text_hover_tip.global_position = next_position
	_ancient_text_hover_tip_last_position = next_position


func _show_ancient_text_tip_for_card(card_root, locked: bool) -> bool:
	if _ancient_text_dragging:
		return false
	if !_is_hover_valid_ancient_text_card_root(card_root):
		return false
	var description_text = _normalize_ancient_text_tooltip_text(_get_card_description_text(card_root))
	if description_text == "":
		return false
	_ensure_ancient_text_hover_tip()
	if _ancient_text_hover_tip == null or !is_instance_valid(_ancient_text_hover_tip):
		return false
	var tip_parent = _get_ancient_text_tip_parent()
	if tip_parent == null:
		return false
	if _ancient_text_hover_tip.get_parent() != tip_parent:
		var current_parent = _ancient_text_hover_tip.get_parent()
		if current_parent != null:
			current_parent.remove_child(_ancient_text_hover_tip)
		tip_parent.add_child(_ancient_text_hover_tip)
	if _ancient_text_hover_tip_title != null:
		_ancient_text_hover_tip_title.text = ""
		_ancient_text_hover_tip_title.visible = false
	if _ancient_text_hover_tip_description != null:
		_ancient_text_hover_tip_description.text = description_text
	_position_ancient_text_hover_tip(card_root)
	_ancient_text_hover_tip.visible = true
	_ancient_text_hover_tip_owner = card_root
	_ancient_text_hover_tip_locked = locked
	return true


func _refresh_ancient_text_hover_tip() -> void:
	if _ancient_text_dragging:
		_hide_ancient_text_hover_tip()
		return
	var card_root = _find_hovered_ancient_text_card_root()
	if _ancient_text_hover_tip_locked:
		if _is_hover_valid_ancient_text_card_root(_ancient_text_hover_tip_owner):
			if !_show_ancient_text_tip_for_card(_ancient_text_hover_tip_owner, true):
				_hide_ancient_text_hover_tip()
			return
		_hide_ancient_text_hover_tip()
		return
	if card_root == null:
		_hide_ancient_text_hover_tip()
		return
	if !_show_ancient_text_tip_for_card(card_root, false):
		_hide_ancient_text_hover_tip()


func _get_card_model_from_root(card_root):
	var current = card_root
	while current != null:
		var model = current.get("Model")
		if model != null:
			return model
		current = current.get_parent()
	return null


func _get_card_id_from_model(model) -> String:
	if model == null:
		return ""
	var id = model.get("Id")
	if id != null:
		var entry = String(id.get("Entry")).strip_edges()
		if entry != "":
			return entry
	var type_name = String(model.get_class()).strip_edges()
	return type_name


func _get_card_id_from_ancestor(node) -> String:
	var current = node
	while current != null:
		if current.has_meta(META_INSPECT_CARD_ID):
			var inspect_card_id = String(current.get_meta(META_INSPECT_CARD_ID, "")).strip_edges()
			if inspect_card_id != "":
				return inspect_card_id
		current = current.get_parent()
	return ""


func _get_card_root_card_id(card_root) -> String:
	if card_root == null:
		return ""
	var ancestor_card_id = _get_card_id_from_ancestor(card_root)
	if ancestor_card_id != "":
		return ancestor_card_id
	return _get_card_id_from_model(_get_card_model_from_root(card_root))


func _is_custom_full_art_owner_current_card(card_root, full_art_layer) -> bool:
	if card_root == null or !(full_art_layer is TextureRect):
		return false
	var owner_card_id = String((full_art_layer as TextureRect).get_meta(META_FULL_ART_OWNER_CARD_ID, "")).strip_edges()
	var current_card_id = _get_card_root_card_id(card_root)
	return owner_card_id != "" and current_card_id != "" and owner_card_id.to_upper() == current_card_id.to_upper()


func _get_current_card_active_full_art_owner_path(card_root) -> String:
	if card_root == null:
		return ""
	var full_art_layer = _get_full_art_layer(card_root)
	if !(full_art_layer is TextureRect) or !bool((full_art_layer as TextureRect).get_meta(META_FULL_ART_ACTIVE, false)):
		return ""
	if !_is_custom_full_art_owner_current_card(card_root, full_art_layer):
		return ""
	var owner_path = String((full_art_layer as TextureRect).get_meta(META_FULL_ART_OWNER_PATH, ""))
	var owner_source_key = _canonicalize_source_key(owner_path)
	if owner_source_key == "" or !is_full_art_mode(owner_source_key):
		return ""
	return owner_path


func _is_full_art_layer_ready_for_source(card_root, source_path: String) -> bool:
	if card_root == null:
		return false
	source_path = _canonicalize_source_key(source_path)
	if source_path == "" or !is_full_art_mode(source_path):
		return false
	var full_art_layer = _get_full_art_layer(card_root)
	if !(full_art_layer is TextureRect):
		return false
	var layer := full_art_layer as TextureRect
	if !bool(layer.get_meta(META_FULL_ART_ACTIVE, false)):
		return false
	if _canonicalize_source_key(String(layer.get_meta(META_FULL_ART_OWNER_PATH, ""))) != source_path:
		return false
	var owner_card_id = String(layer.get_meta(META_FULL_ART_OWNER_CARD_ID, "")).strip_edges()
	if owner_card_id != "" and !_is_custom_full_art_owner_current_card(card_root, layer):
		return false
	return layer.texture != null


func _normalize_card_rarity_name(raw_value) -> String:
	if raw_value == null:
		return ""
	match typeof(raw_value):
		TYPE_INT, TYPE_FLOAT:
			match int(raw_value):
				0:
					return "basic"
				1:
					return "common"
				2:
					return "uncommon"
				3:
					return "rare"
				_:
					return ""
	var normalized := String(raw_value).strip_edges().to_lower()
	if normalized == "":
		return ""
	if normalized.ends_with(".basic") or normalized == "basic" or normalized == "starter":
		return "basic"
	if normalized.ends_with(".common") or normalized == "common" or normalized == "일반":
		return "common"
	if normalized.ends_with(".uncommon") or normalized == "uncommon" or normalized == "고급":
		return "uncommon"
	if normalized.ends_with(".rare") or normalized == "rare" or normalized == "희귀" or normalized == "진귀":
		return "rare"
	if normalized.contains("uncommon"):
		return "uncommon"
	if normalized.contains("common"):
		return "common"
	if normalized.contains("rare"):
		return "rare"
	return normalized


func _get_card_rarity_name_from_model(model) -> String:
	if model == null:
		return ""
	return _normalize_card_rarity_name(model.get("Rarity"))


func _get_rarity_name_from_material(material) -> String:
	if material == null:
		return ""
	var material_path = String(material.resource_path).to_lower() if material is Resource else ""
	var material_name = String(material.resource_name).to_lower() if material is Resource else ""
	var combined := "%s %s %s" % [material_path, material_name, String(material).to_lower()]
	if combined.contains("uncommon"):
		return "uncommon"
	if combined.contains("rare"):
		return "rare"
	if combined.contains("common"):
		return "common"
	return ""


func _get_card_rarity_name_from_visuals(card_root) -> String:
	if card_root == null:
		return ""
	for node_name in ["TitleBanner", "PortraitBorder", "Frame"]:
		var node = _find_named_descendant(card_root, node_name)
		if node is CanvasItem:
			var rarity_name = _get_rarity_name_from_material((node as CanvasItem).material)
			if rarity_name != "":
				return rarity_name
	return ""


func _get_full_art_highlight_color_for_card(card_root) -> Color:
	var rarity_name = _get_card_rarity_name_from_visuals(card_root)
	if rarity_name == "":
		rarity_name = _get_card_rarity_name_from_model(_get_card_model_from_root(card_root))
	match rarity_name:
		"rare":
			return FULL_ART_HIGHLIGHT_RARE_COLOR
		"uncommon":
			return FULL_ART_HIGHLIGHT_UNCOMMON_COLOR
		"basic", "common":
			return FULL_ART_HIGHLIGHT_COMMON_COLOR
		_:
			return FULL_ART_HIGHLIGHT_COMMON_COLOR


func _find_ancient_fire_node(card_root):
	if card_root == null:
		return null
	var ancient_banner = _find_named_descendant(card_root, "AncientBanner")
	if ancient_banner != null:
		var fire = _find_named_descendant(ancient_banner, "Fire")
		if fire != null:
			return fire
	return _find_named_descendant(card_root, "Fire")


func _get_full_art_fire_shader():
	if _full_art_fire_shader is Shader:
		return _full_art_fire_shader
	var shader := Shader.new()
	shader.code = FULL_ART_FIRE_SHADER_CODE
	_full_art_fire_shader = shader
	return _full_art_fire_shader


func _store_full_art_fire_original_state(fire) -> void:
	if !(fire is CanvasItem):
		return
	if fire.has_meta(META_FULL_ART_FIRE_ORIGINAL_STATE):
		return
	var canvas_item = fire as CanvasItem
	fire.set_meta(META_FULL_ART_FIRE_ORIGINAL_STATE, {
		"material": canvas_item.material,
		"self_modulate": canvas_item.self_modulate
	})


func _restore_full_art_fire_rarity_color(card_root) -> void:
	var fire = _find_ancient_fire_node(card_root)
	if !(fire is CanvasItem):
		return
	var canvas_item = fire as CanvasItem
	if fire.has_meta(META_FULL_ART_FIRE_ORIGINAL_STATE):
		var state = fire.get_meta(META_FULL_ART_FIRE_ORIGINAL_STATE)
		if state is Dictionary:
			canvas_item.material = state.get("material", null)
			var original_modulate = state.get("self_modulate", null)
			if original_modulate is Color:
				canvas_item.self_modulate = original_modulate
		fire.remove_meta(META_FULL_ART_FIRE_ORIGINAL_STATE)


func _apply_full_art_fire_rarity_color(card_root, source_path: String = "") -> void:
	var fire = _find_ancient_fire_node(card_root)
	if !(fire is CanvasItem):
		return
	if !is_full_art_rarity_fire_enabled_for_source(source_path):
		_restore_full_art_fire_rarity_color(card_root)
		return
	_store_full_art_fire_original_state(fire)
	var shader = _get_full_art_fire_shader()
	if !(shader is Shader):
		return
	var canvas_item = fire as CanvasItem
	var tint_color = _get_full_art_highlight_color_for_card(card_root)
	var current_material = canvas_item.material
	if current_material is ShaderMaterial and (current_material as ShaderMaterial).shader == shader:
		var current_shader_material := current_material as ShaderMaterial
		var current_tint = current_shader_material.get_shader_parameter("tint_color")
		if !(current_tint is Color) or current_tint != tint_color:
			current_shader_material.set_shader_parameter("tint_color", tint_color)
		canvas_item.self_modulate = Color(1, 1, 1, 1)
		canvas_item.visible = true
		return
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("tint_color", tint_color)
	canvas_item.material = material
	canvas_item.self_modulate = Color(1, 1, 1, 1)
	canvas_item.visible = true


func _sync_full_art_fire_rarity_color(card_root, source_path: String = "") -> void:
	if card_root == null:
		return
	var resolved_source = _canonicalize_source_key(source_path)
	if resolved_source == "":
		resolved_source = _get_current_card_active_full_art_owner_path(card_root)
	if resolved_source == "":
		var full_art_layer = _get_full_art_layer(card_root)
		if full_art_layer is TextureRect and bool((full_art_layer as TextureRect).get_meta(META_FULL_ART_ACTIVE, false)):
			resolved_source = _canonicalize_source_key(String((full_art_layer as TextureRect).get_meta(META_FULL_ART_OWNER_PATH, "")))
	if resolved_source == "" or !is_full_art_mode(resolved_source):
		return
	_apply_full_art_fire_rarity_color(card_root, resolved_source)


func _get_effective_ancient_card_type_name(model) -> String:
	if model == null:
		return ""
	var raw_type = model.get("Type")
	if raw_type == null:
		return ""
	var normalized := ""
	match typeof(raw_type):
		TYPE_INT, TYPE_FLOAT:
			match int(raw_type):
				0:
					normalized = "none"
				1:
					normalized = "attack"
				2:
					normalized = "skill"
				3:
					normalized = "power"
				4:
					normalized = "status"
				5:
					normalized = "curse"
				6:
					normalized = "quest"
				_:
					normalized = ""
		_:
			normalized = String(raw_type).to_lower()
	if normalized == "":
		return ""
	match normalized:
		"none", "status", "curse":
			return "skill"
		"attack", "skill", "power", "quest":
			return normalized
		_:
			return normalized


func _normalize_card_type_name(raw_value) -> String:
	if raw_value == null:
		return ""
	var normalized := String(raw_value).strip_edges().to_lower()
	if normalized == "":
		return ""
	match normalized:
		"attack", "공격":
			return "attack"
		"skill", "스킬", "none", "status", "curse", "상태", "저주":
			return "skill"
		"power", "파워", "능력":
			return "power"
		"quest", "퀘스트":
			return "quest"
	if normalized.ends_with("attack") or normalized.contains(".attack"):
		return "attack"
	if normalized.ends_with("skill") or normalized.contains(".skill"):
		return "skill"
	if normalized.ends_with("power") or normalized.contains(".power"):
		return "power"
	if normalized.ends_with("status") or normalized.ends_with("curse"):
		return "skill"
	if normalized.ends_with("quest"):
		return "quest"
	return normalized


func _get_card_type_name_from_type_label(card_root) -> String:
	if card_root == null:
		return ""
	var type_label = _find_named_descendant(card_root, "TypeLabel")
	if type_label == null:
		return ""
	var label_text := ""
	if type_label is Label:
		label_text = String((type_label as Label).text)
	else:
		label_text = String(type_label.get("text"))
	return _normalize_card_type_name(label_text)


func _get_effective_ancient_card_type_name_for_card(card_root) -> String:
	var type_name = _get_card_type_name_from_type_label(card_root)
	if type_name != "":
		return type_name
	var model = _get_card_model_from_root(card_root)
	return _get_effective_ancient_card_type_name(model)


func _get_ancient_text_bg_texture_for_type_name(type_name: String):
	if type_name == "":
		return null
	var texture_path = "res://images/atlases/compressed.sprites/card_template/ancient_card_text_bg_%s.tres" % type_name
	if !ResourceLoader.exists(texture_path):
		return null
	var texture = load(texture_path)
	return texture if texture is Texture2D else null


func _apply_full_art_card_type_style(card_root, ancient_text_bg) -> void:
	if !(ancient_text_bg is TextureRect):
		return
	var type_name = _get_effective_ancient_card_type_name_for_card(card_root)
	var ancient_text_bg_texture = _get_ancient_text_bg_texture_for_type_name(type_name)
	if ancient_text_bg_texture is Texture2D:
		(ancient_text_bg as TextureRect).texture = ancient_text_bg_texture


func _apply_full_art_state(texture_rect, source_path: String, override_texture) -> bool:
	var card_root = _find_card_root(texture_rect)
	if card_root == null:
		return false
	var entry = _manifest.get(_canonicalize_source_key(source_path), null)
	var full_art_inset = FULL_ART_INSET_ANIMATED if _is_animated_entry(entry) else FULL_ART_INSET_STATIC
	var full_art_layer = _get_or_create_full_art_layer(card_root, full_art_inset)
	if !(full_art_layer is TextureRect):
		return false
	var portrait_canvas_group = _find_named_descendant(card_root, "PortraitCanvasGroup")
	var ancient_portrait = _find_named_descendant(card_root, "AncientPortrait")
	var ancient_highlight = _find_named_descendant(card_root, "AncientHighlight")
	var portrait_border = _find_named_descendant(card_root, "PortraitBorder")
	var frame = _find_named_descendant(card_root, "Frame")
	var title_banner = _find_named_descendant(card_root, "TitleBanner")
	var ancient_border = _find_named_descendant(card_root, "AncientBorder")
	var ancient_text_bg = _find_named_descendant(card_root, "AncientTextBg")
	var ancient_banner = _find_named_descendant(card_root, "AncientBanner")
	var type_plaque = _find_named_descendant(card_root, "TypePlaque")
	var description_label = _find_named_descendant(card_root, "DescriptionLabel")
	_store_ancient_text_layout_defaults(card_root, description_label, ancient_text_bg)
	if override_texture == null:
		return false
	var layer = full_art_layer as TextureRect
	var layer_active = bool(layer.get_meta(META_FULL_ART_ACTIVE, false))
	var layer_owner = String(layer.get_meta(META_FULL_ART_OWNER_PATH, ""))
	var already_same = layer_active and layer_owner == source_path and layer.texture == override_texture
	if !already_same:
		layer.texture = override_texture
	layer.visible = true
	layer.set_meta(META_FULL_ART_ACTIVE, true)
	layer.set_meta(META_FULL_ART_OWNER_PATH, source_path)
	var owner_card_id = _get_card_root_card_id(card_root)
	if owner_card_id != "":
		layer.set_meta(META_FULL_ART_OWNER_CARD_ID, owner_card_id)
	else:
		layer.remove_meta(META_FULL_ART_OWNER_CARD_ID)
	_sync_active_custom_full_art_layer(card_root)
	texture_rect.visible = false
	texture_rect.self_modulate = Color(1, 1, 1, 0)
	_apply_full_art_portrait_mask(portrait_canvas_group)
	if ancient_portrait is TextureRect:
		(ancient_portrait as TextureRect).visible = false
		(ancient_portrait as TextureRect).self_modulate = Color(1, 1, 1, 0)
	if portrait_border is CanvasItem:
		portrait_border.visible = false
	if frame is CanvasItem:
		frame.visible = false
	if title_banner is CanvasItem:
		title_banner.visible = false
	if type_plaque is CanvasItem:
		type_plaque.visible = true
	if ancient_highlight is CanvasItem:
		ancient_highlight.visible = true
	if ancient_border is CanvasItem:
		ancient_border.visible = true
	if ancient_text_bg is CanvasItem:
		_apply_full_art_card_type_style(card_root, ancient_text_bg)
		ancient_text_bg.visible = true
	if ancient_banner is CanvasItem:
		ancient_banner.visible = true
	_apply_full_art_fire_rarity_color(card_root, source_path)
	texture_rect.set_meta(META_FULL_ART_ACTIVE, true)
	_apply_ancient_text_outside_layout(card_root)
	return true


func _clear_custom_full_art_layer(card_root) -> void:
	if card_root == null:
		return
	var portrait_canvas_group = _find_named_descendant(card_root, "PortraitCanvasGroup")
	var full_art_layer = _get_full_art_layer(card_root)
	var portrait = _find_named_descendant(card_root, "Portrait")
	var ancient_portrait = _find_named_descendant(card_root, "AncientPortrait")
	var portrait_border = _find_named_descendant(card_root, "PortraitBorder")
	var frame = _find_named_descendant(card_root, "Frame")
	var title_banner = _find_named_descendant(card_root, "TitleBanner")
	var ancient_highlight = _find_named_descendant(card_root, "AncientHighlight")
	var ancient_border = _find_named_descendant(card_root, "AncientBorder")
	var ancient_text_bg = _find_named_descendant(card_root, "AncientTextBg")
	var ancient_banner = _find_named_descendant(card_root, "AncientBanner")
	var is_ancient_layout = ancient_portrait is CanvasItem and (ancient_portrait as CanvasItem).visible and !(portrait is CanvasItem and (portrait as CanvasItem).visible)

	if full_art_layer is TextureRect:
		full_art_layer.visible = false
		full_art_layer.texture = null
		full_art_layer.set_meta(META_FULL_ART_ACTIVE, false)
		full_art_layer.remove_meta(META_FULL_ART_OWNER_PATH)
		full_art_layer.remove_meta(META_FULL_ART_OWNER_CARD_ID)
	if portrait_canvas_group is CanvasItem:
		portrait_canvas_group.visible = true
	_restore_full_art_portrait_mask(portrait_canvas_group)
	if is_ancient_layout:
		_ensure_ancient_portrait_mask(card_root)
	if portrait is TextureRect:
		(portrait as TextureRect).self_modulate = Color(1, 1, 1, 1)
	if ancient_portrait is TextureRect:
		(ancient_portrait as TextureRect).self_modulate = Color(1, 1, 1, 1)
	_restore_full_art_fire_rarity_color(card_root)
	if is_ancient_layout:
		if portrait_border is CanvasItem:
			portrait_border.visible = false
		if frame is CanvasItem:
			frame.visible = false
		if title_banner is CanvasItem:
			title_banner.visible = false
		if ancient_highlight is CanvasItem:
			ancient_highlight.visible = true
		if ancient_border is CanvasItem:
			ancient_border.visible = true
		if ancient_text_bg is CanvasItem:
			ancient_text_bg.visible = true
		if ancient_banner is CanvasItem:
			ancient_banner.visible = true
	else:
		if portrait_border is CanvasItem:
			portrait_border.visible = true
		if frame is CanvasItem:
			frame.visible = true
		if title_banner is CanvasItem:
			title_banner.visible = true
		if ancient_highlight is CanvasItem:
			ancient_highlight.visible = false
		if ancient_border is CanvasItem:
			ancient_border.visible = false
		if ancient_text_bg is CanvasItem:
			ancient_text_bg.visible = false
		if ancient_banner is CanvasItem:
			ancient_banner.visible = false
	_apply_ancient_text_outside_layout(card_root)


func _on_node_added(node) -> void:
	if _is_portrait_node(node):
		_track_portrait(node, true)
	elif _is_supported_card_root(node):
		_track_ancient_text_card_hitbox(node)
	elif node is Control and String(node.name) == "InspectCardScreen":
		call_deferred("_attach_overlay", node)


func _register_existing(node, defer_refresh: bool = false) -> void:
	if _is_portrait_node(node):
		_track_portrait(node, defer_refresh)
	elif _is_supported_card_root(node):
		_track_ancient_text_card_hitbox(node)
	elif node is Control and String(node.name) == "InspectCardScreen":
		call_deferred("_attach_overlay", node)

	for child in node.get_children():
		_register_existing(child, defer_refresh)


func _get_tracked_portrait_at(index: int):
	if index < 0 or index >= _portrait_ref_ids.size():
		return null
	var instance_id = int(_portrait_ref_ids[index])
	var portrait_ref = _portrait_refs.get(instance_id, null)
	return portrait_ref.get_ref() if portrait_ref is WeakRef else null


func _remove_tracked_portrait_at(index: int) -> void:
	if index < 0 or index >= _portrait_ref_ids.size():
		return
	var instance_id = int(_portrait_ref_ids[index])
	_portrait_refs.erase(instance_id)
	_portrait_ref_ids.remove_at(index)
	if index < _portrait_refresh_cursor:
		_portrait_refresh_cursor -= 1
	if index < _visible_portrait_refresh_cursor:
		_visible_portrait_refresh_cursor -= 1
	_portrait_refresh_cursor = clampi(_portrait_refresh_cursor, 0, _portrait_ref_ids.size())
	_visible_portrait_refresh_cursor = clampi(_visible_portrait_refresh_cursor, 0, _portrait_ref_ids.size())


func _on_tracked_portrait_tree_exiting(instance_id: int) -> void:
	var index = _portrait_ref_ids.find(instance_id)
	if index >= 0:
		_remove_tracked_portrait_at(index)
	else:
		_portrait_refs.erase(instance_id)


func _track_portrait(texture_rect, defer_refresh: bool = false) -> void:
	if !_is_portrait_node(texture_rect):
		return
	var instance_id = int(texture_rect.get_instance_id())
	if _portrait_refs.has(instance_id):
		return
	_portrait_refs[instance_id] = weakref(texture_rect)
	_portrait_ref_ids.append(instance_id)
	var exit_callback = Callable(self, "_on_tracked_portrait_tree_exiting").bind(instance_id)
	if !texture_rect.tree_exiting.is_connected(exit_callback):
		texture_rect.tree_exiting.connect(exit_callback, Object.CONNECT_ONE_SHOT)
	var card_root = _find_card_root(texture_rect)
	if card_root != null:
		_track_ancient_text_card_hitbox(card_root)
	if defer_refresh:
		queue_card_override_refresh(card_root, true)
		_request_ancient_text_hover_refresh(true)
		_request_gif_playback_refresh(true)
		return
	if card_needs_override_refresh(card_root):
		_refresh_portrait_node(texture_rect)
	_request_ancient_text_hover_refresh(true)
	_request_gif_playback_refresh(true)


func _refresh_tracked_portraits(max_items: int = PORTRAIT_REFRESH_FRAME_BUDGET) -> bool:
	if _portrait_ref_ids.is_empty():
		_portrait_refresh_cursor = 0
		return true
	var limit = _portrait_ref_ids.size() if max_items <= 0 else max_items
	var processed := 0
	var completed_cycle := false
	while processed < limit and !_portrait_ref_ids.is_empty():
		if _portrait_refresh_cursor >= _portrait_ref_ids.size():
			_portrait_refresh_cursor = 0
			completed_cycle = true
			break
		var texture_rect = _get_tracked_portrait_at(_portrait_refresh_cursor)
		if texture_rect == null:
			_remove_tracked_portrait_at(_portrait_refresh_cursor)
			if _portrait_refresh_cursor >= _portrait_ref_ids.size():
				_portrait_refresh_cursor = 0
				completed_cycle = true
			continue
		var card_root = _find_card_root(texture_rect)
		if !_is_multiplayer_expanded_deck_card_root(card_root):
			_refresh_portrait_node(texture_rect)
		processed += 1
		_portrait_refresh_cursor += 1
		if _portrait_refresh_cursor >= _portrait_ref_ids.size():
			_portrait_refresh_cursor = 0
			completed_cycle = true
			break
	return completed_cycle or _portrait_ref_ids.is_empty()


func _get_card_root_source_path(card_root) -> String:
	if card_root == null:
		return ""
	var active_full_art_owner = _get_current_card_active_full_art_owner_path(card_root)
	if active_full_art_owner != "":
		return active_full_art_owner
	var model_source_path = _get_model_or_inspect_source_path(card_root)
	if model_source_path != "":
		return model_source_path
	var ancient_portrait = _find_named_descendant(card_root, "AncientPortrait")
	var portrait = _find_named_descendant(card_root, "Portrait")
	var ancient_visible = ancient_portrait is CanvasItem and (ancient_portrait as CanvasItem).visible
	var portrait_visible = portrait is CanvasItem and (portrait as CanvasItem).visible
	if ancient_visible and ancient_portrait is TextureRect and ancient_portrait.texture is Texture2D:
		var ancient_path = _resolve_texture_source_path(ancient_portrait, ancient_portrait.texture)
		if ancient_path != "":
			return ancient_path
	if portrait_visible and portrait is TextureRect and portrait.texture is Texture2D:
		var portrait_path = _resolve_texture_source_path(portrait, portrait.texture)
		if portrait_path != "":
			return portrait_path
	var full_art_layer = _get_full_art_layer(card_root)
	if full_art_layer is TextureRect and bool(full_art_layer.get_meta(META_FULL_ART_ACTIVE, false)):
		var full_art_owner = String(full_art_layer.get_meta(META_FULL_ART_OWNER_PATH, ""))
		if full_art_owner != "":
			return full_art_owner
	if ancient_visible:
		return ""
	if portrait_visible:
		return ""
	if ancient_portrait is TextureRect and ancient_portrait.texture is Texture2D:
		var ancient_hidden_path = _resolve_texture_source_path(ancient_portrait, ancient_portrait.texture)
		if ancient_hidden_path != "":
			return ancient_hidden_path
	if portrait is TextureRect and portrait.texture is Texture2D:
		var portrait_hidden_path = _resolve_texture_source_path(portrait, portrait.texture)
		if portrait_hidden_path != "":
			return portrait_hidden_path
	return ""


func _build_refresh_signature(texture_rect, current_texture, stored_source_path: String, current_path: String, card_root, portrait_visible: bool, ancient_visible: bool) -> String:
	var node_name = String(texture_rect.name)
	var texture_size := Vector2i.ZERO
	var texture_path := ""
	var texture_instance_id := 0
	if current_texture is Texture2D:
		texture_size = Vector2i(current_texture.get_width(), current_texture.get_height())
		texture_path = _get_texture_resource_source_path(current_texture)
		texture_instance_id = int(current_texture.get_instance_id())
	var full_art_active := false
	var full_art_owner := ""
	var full_art_owner_card_id := ""
	var card_root_card_id := ""
	if card_root != null:
		card_root_card_id = _get_card_root_card_id(card_root)
		var full_art_layer = _get_full_art_layer(card_root)
		if full_art_layer is TextureRect:
			full_art_active = bool(full_art_layer.get_meta(META_FULL_ART_ACTIVE, false))
			full_art_owner = String(full_art_layer.get_meta(META_FULL_ART_OWNER_PATH, ""))
			full_art_owner_card_id = String(full_art_layer.get_meta(META_FULL_ART_OWNER_CARD_ID, ""))
	var tracked_source_path = current_path if current_path != "" else stored_source_path
	var manifest_source_path = _canonicalize_source_key(tracked_source_path)
	var has_override_for_path = manifest_source_path != "" and _manifest.has(manifest_source_path)
	var rarity_fire_source_path = full_art_owner if full_art_owner != "" else tracked_source_path
	var gif_hover_source_path = full_art_owner if full_art_owner != "" else tracked_source_path
	var display_mode = DISPLAY_MODE_DEFAULT
	var entry_type = "static"
	var entry_updated_at = ""
	var frame_count = 0
	if has_override_for_path:
		var entry = _manifest.get(manifest_source_path, null)
		if entry is Dictionary:
			display_mode = String(entry.get("display_mode", DISPLAY_MODE_DEFAULT))
			entry_type = String(entry.get("type", "static"))
			entry_updated_at = String(entry.get("updated_at", ""))
			var entry_frame_paths = entry.get("frame_paths", [])
			if entry_frame_paths is Array:
				frame_count = entry_frame_paths.size()
	return "|".join([
		node_name,
		tracked_source_path,
		stored_source_path,
		"1" if has_override_for_path else "0",
		display_mode,
		entry_type,
		entry_updated_at,
		str(frame_count),
		"1" if portrait_visible else "0",
		"1" if ancient_visible else "0",
		card_root_card_id,
		"1" if full_art_active else "0",
		full_art_owner,
		full_art_owner_card_id,
		"1" if _full_art_rarity_fire_enabled else "0",
		rarity_fire_source_path,
		"1" if is_full_art_rarity_fire_enabled_for_source(rarity_fire_source_path) else "0",
		"1" if _is_gif_hover_playback_only_enabled() else "0",
		gif_hover_source_path,
		"1" if is_gif_hover_playback_only_enabled_for_source(gif_hover_source_path) else "0",
		texture_path,
		str(texture_instance_id),
		str(texture_size.x),
		str(texture_size.y),
		"1" if bool(texture_rect.get_meta(META_OVERRIDE_ACTIVE, false)) else "0"
	])


func _refresh_portrait_node(texture_rect) -> void:
	var current_texture = texture_rect.texture

	var card_root = _find_card_root(texture_rect)
	var node_name = String(texture_rect.name)
	var portrait_visible := false
	var ancient_visible := false
	if card_root != null:
		var portrait = _find_named_descendant(card_root, "Portrait")
		var ancient_portrait = _find_named_descendant(card_root, "AncientPortrait")
		portrait_visible = portrait is CanvasItem and (portrait as CanvasItem).visible
		ancient_visible = ancient_portrait is CanvasItem and (ancient_portrait as CanvasItem).visible
		if ancient_visible and !portrait_visible:
			_ensure_ancient_portrait_mask(card_root)
		if node_name == "Portrait" and !portrait_visible and ancient_visible:
			var original_texture = texture_rect.get_meta(META_ORIGINAL_TEXTURE, null) if texture_rect.has_meta(META_ORIGINAL_TEXTURE) else null
			if original_texture is Texture2D:
				texture_rect.texture = original_texture
			texture_rect.set_meta(META_SOURCE_PATH, "")
			texture_rect.set_meta(META_OVERRIDE_ACTIVE, false)
			texture_rect.set_meta(META_REFRESH_SIGNATURE, "")
			return
		if node_name == "AncientPortrait" and !ancient_visible:
			var original_texture = texture_rect.get_meta(META_ORIGINAL_TEXTURE, null) if texture_rect.has_meta(META_ORIGINAL_TEXTURE) else null
			if original_texture is Texture2D:
				texture_rect.texture = original_texture
			texture_rect.set_meta(META_SOURCE_PATH, "")
			texture_rect.set_meta(META_OVERRIDE_ACTIVE, false)
			texture_rect.set_meta(META_REFRESH_SIGNATURE, "")
			return
		var full_art_layer = _get_full_art_layer(card_root)
		if full_art_layer is TextureRect and bool(full_art_layer.get_meta(META_FULL_ART_ACTIVE, false)):
			if ancient_visible and !portrait_visible:
				_clear_custom_full_art_layer(card_root)
			else:
				var owner_path = String(full_art_layer.get_meta(META_FULL_ART_OWNER_PATH, ""))
				var card_root_source_path = _get_card_root_source_path(card_root)
				if owner_path == "" or (card_root_source_path != "" and card_root_source_path != owner_path):
					_clear_custom_full_art_layer(card_root)

	if node_name == FULL_ART_LAYER_NAME and bool(texture_rect.get_meta(META_FULL_ART_ACTIVE, false)):
		var owner_path = String(texture_rect.get_meta(META_FULL_ART_OWNER_PATH, ""))
		var resolved_card_path = _resolve_texture_source_path(texture_rect, current_texture)
		if owner_path == "" or (resolved_card_path != "" and resolved_card_path != owner_path):
			var mismatch_root = _find_card_root(texture_rect)
			_clear_custom_full_art_layer(mismatch_root)
			return

	var card_root_source_path = _get_card_root_source_path(card_root)
	var current_path = card_root_source_path if card_root_source_path != "" else _resolve_texture_source_path(texture_rect, current_texture)
	var stored_source_path = String(texture_rect.get_meta(META_SOURCE_PATH, ""))
	var refresh_signature = _build_refresh_signature(texture_rect, current_texture, stored_source_path, current_path, card_root, portrait_visible, ancient_visible)
	if String(texture_rect.get_meta(META_REFRESH_SIGNATURE, "")) == refresh_signature:
		var expected_full_art_path = _canonicalize_source_key(current_path if current_path != "" else stored_source_path)
		if node_name == "Portrait" and expected_full_art_path != "" and is_full_art_mode(expected_full_art_path) and !_is_full_art_layer_ready_for_source(card_root, expected_full_art_path):
			texture_rect.set_meta(META_REFRESH_SIGNATURE, "")
		else:
			_sync_active_custom_full_art_layer(card_root)
			_enforce_custom_full_art_layer_visibility(card_root)
			_apply_ancient_text_outside_layout(card_root)
			return

	if current_path != "" and _looks_like_card_art_source(current_path):
		var current_root = _find_card_root(texture_rect)
		var full_art_layer = _get_full_art_layer(current_root)
		if full_art_layer is TextureRect and bool(full_art_layer.get_meta(META_FULL_ART_ACTIVE, false)):
			var owner_path = String(full_art_layer.get_meta(META_FULL_ART_OWNER_PATH, ""))
			if owner_path != "" and owner_path != current_path:
				_clear_custom_full_art_layer(current_root)
		if stored_source_path != current_path:
			var source_texture = current_texture if _is_current_provider_texture_for_source(current_texture, current_path, stored_source_path) else _load_source_texture(current_path)
			if String(texture_rect.name) == "Portrait":
				if _get_current_card_active_full_art_owner_path(current_root) == current_path:
					_enforce_custom_full_art_layer_visibility(current_root)
				else:
					_clear_custom_full_art_layer(current_root)
			if source_texture is Texture2D:
				texture_rect.texture = source_texture
				current_texture = source_texture
				texture_rect.set_meta(META_SOURCE_SIZE, Vector2i(source_texture.get_width(), source_texture.get_height()))
				texture_rect.set_meta(META_ORIGINAL_TEXTURE, source_texture)
			elif current_texture is Texture2D and !bool(texture_rect.get_meta(META_OVERRIDE_ACTIVE, false)):
				texture_rect.set_meta(META_SOURCE_SIZE, Vector2i(current_texture.get_width(), current_texture.get_height()))
				texture_rect.set_meta(META_ORIGINAL_TEXTURE, current_texture)
			texture_rect.set_meta(META_SOURCE_PATH, current_path)
			texture_rect.set_meta(META_OVERRIDE_ACTIVE, false)
			texture_rect.set_meta(META_REFRESH_SIGNATURE, "")
			stored_source_path = current_path
		elif current_texture is Texture2D and !texture_rect.has_meta(META_ORIGINAL_TEXTURE) and !bool(texture_rect.get_meta(META_OVERRIDE_ACTIVE, false)):
			texture_rect.set_meta(META_ORIGINAL_TEXTURE, current_texture)
			texture_rect.set_meta(META_SOURCE_SIZE, Vector2i(current_texture.get_width(), current_texture.get_height()))
			texture_rect.set_meta(META_OVERRIDE_ACTIVE, false)
	elif stored_source_path == "":
		_apply_ancient_text_outside_layout(card_root)
		texture_rect.set_meta(META_REFRESH_SIGNATURE, refresh_signature)
		return

	var manifest_source_path = _canonicalize_source_key(stored_source_path)
	var override_texture = _get_override_texture(manifest_source_path, _should_animate_gif_card(card_root, manifest_source_path))
	if override_texture != null:
		_synchronize_provider_original_texture(texture_rect, current_texture, override_texture, stored_source_path)
		var entry = _manifest.get(manifest_source_path, null)
		var display_mode = String(entry.get("display_mode", DISPLAY_MODE_DEFAULT)) if entry is Dictionary else DISPLAY_MODE_DEFAULT
		if card_root != null and node_name == "AncientPortrait":
			var current_ancient = _find_named_descendant(card_root, "AncientPortrait")
			if current_ancient is CanvasItem and !(current_ancient as CanvasItem).visible:
				return
		if card_root != null and node_name == "Portrait":
			var current_portrait = _find_named_descendant(card_root, "Portrait")
			var current_full_art_layer = _get_full_art_layer(card_root)
			var current_full_art_active = current_full_art_layer is TextureRect and bool(current_full_art_layer.get_meta(META_FULL_ART_ACTIVE, false))
			if current_portrait is CanvasItem and !(current_portrait as CanvasItem).visible and !current_full_art_active and display_mode != DISPLAY_MODE_FULL_ART:
				return
		if display_mode == DISPLAY_MODE_FULL_ART and node_name == "Portrait":
			if _apply_full_art_state(texture_rect, stored_source_path, override_texture):
				texture_rect.set_meta(META_OVERRIDE_ACTIVE, true)
				texture_rect.set_meta(META_REFRESH_SIGNATURE, _build_refresh_signature(texture_rect, texture_rect.texture, stored_source_path, current_path, card_root, portrait_visible, ancient_visible))
				return
			_clear_custom_full_art_layer(card_root)
		if node_name == "Portrait":
			_clear_custom_full_art_layer(card_root)
		if texture_rect.texture != override_texture:
			texture_rect.texture = override_texture
			texture_rect.set_meta(META_OVERRIDE_ACTIVE, true)
		_apply_ancient_text_outside_layout(card_root)
		texture_rect.set_meta(META_REFRESH_SIGNATURE, _build_refresh_signature(texture_rect, texture_rect.texture, stored_source_path, current_path, card_root, portrait_visible, ancient_visible))
		return

	if node_name == "Portrait":
		_clear_custom_full_art_layer(card_root)

	if bool(texture_rect.get_meta(META_OVERRIDE_ACTIVE, false)):
		_restore_texture_rect_to_provider(texture_rect, stored_source_path)
	_apply_ancient_text_outside_layout(card_root)
	texture_rect.set_meta(META_REFRESH_SIGNATURE, _build_refresh_signature(texture_rect, texture_rect.texture, stored_source_path, current_path, card_root, portrait_visible, ancient_visible))


func _synchronize_provider_original_texture(texture_rect, current_texture, override_texture, source_path: String) -> void:
	if !(texture_rect is TextureRect) or !(current_texture is Texture2D):
		return
	if !bool(texture_rect.get_meta(META_OVERRIDE_ACTIVE, false)) or current_texture == override_texture:
		return
	var provider_texture = _load_source_texture(source_path)
	if !(provider_texture is Texture2D):
		provider_texture = current_texture
	texture_rect.set_meta(META_ORIGINAL_TEXTURE, provider_texture)
	texture_rect.set_meta(META_SOURCE_SIZE, Vector2i(provider_texture.get_width(), provider_texture.get_height()))


func _is_current_provider_texture_for_source(current_texture, current_path: String, previous_source_path: String) -> bool:
	if !(current_texture is Texture2D):
		return false
	var previous_source_key = _canonicalize_source_key(previous_source_path)
	for cache_key in [previous_source_key, _get_override_texture_cache_key(previous_source_key, false)]:
		if cache_key != "" and _override_texture_cache.get(cache_key, null) == current_texture:
			return false
	var texture_source_path = _get_texture_resource_source_path(current_texture)
	if texture_source_path == "":
		return false
	return texture_source_path.to_lower() == _normalize_source_path(current_path).to_lower()


func _get_override_texture_cache_key(source_path: String, animate: bool = true) -> String:
	return source_path if animate else "%s%s" % [source_path, STATIC_OVERRIDE_CACHE_SUFFIX]


func _erase_override_texture_cache(source_path: String) -> void:
	_override_texture_cache.erase(source_path)
	_override_texture_cache.erase(_get_override_texture_cache_key(source_path, false))


func _get_override_texture(source_path: String, animate: bool = true):
	source_path = _canonicalize_source_key(source_path)
	if !_manifest.has(source_path):
		return null

	var entry = _manifest[source_path]
	if !(entry is Dictionary):
		return null
	var display_mode = String(entry.get("display_mode", DISPLAY_MODE_DEFAULT))

	if _is_animated_entry(entry):
		var animated_cache_key = _get_override_texture_cache_key(source_path, animate)
		if _override_texture_cache.has(animated_cache_key):
			return _override_texture_cache[animated_cache_key]
		var frame_paths = entry.get("source_frame_paths", entry.get("frame_paths", [])) if display_mode == DISPLAY_MODE_FULL_ART else entry.get("frame_paths", [])
		var frame_delays = entry.get("frame_delays", [])
		if !(frame_paths is Array) or frame_paths.is_empty():
			return null

		var loaded_frames: Array = []
		for index in range(frame_paths.size()):
			var frame_path = String(frame_paths[index])
			var frame_image = load_image_from_file(ProjectSettings.globalize_path(frame_path))
			if frame_image == null:
				continue
			if display_mode == DISPLAY_MODE_FULL_ART:
				frame_image = trim_transparent_margins(frame_image)
				frame_image = build_full_art_preview(source_path, frame_image, Vector2i.ZERO, FULL_ART_ANIMATED_ZOOM_BOOST)
				if frame_image == null:
					continue
			loaded_frames.append({
				"texture": ImageTexture.create_from_image(frame_image),
				"delay": max(0.02, float(frame_delays[index]) if index < frame_delays.size() else 0.1)
			})
			if !animate:
				break

		if loaded_frames.is_empty():
			_remove_entry_files(entry)
			_manifest.erase(source_path)
			_erase_override_texture_cache(source_path)
			_save_manifest()
			return null

		if !animate:
			var static_texture = loaded_frames[0]["texture"]
			_override_texture_cache[animated_cache_key] = static_texture
			return static_texture

		var animated_texture := AnimatedTexture.new()
		animated_texture.frames = loaded_frames.size()
		animated_texture.speed_scale = 1.0
		for index in range(loaded_frames.size()):
			var frame_entry = loaded_frames[index]
			animated_texture.set_frame_texture(index, frame_entry["texture"])
			animated_texture.set_frame_duration(index, frame_entry["delay"])

		_override_texture_cache[animated_cache_key] = animated_texture
		return animated_texture

	if _override_texture_cache.has(source_path):
		return _override_texture_cache[source_path]

	if !entry.has("override_path"):
		return null

	var override_path = String(entry["override_path"])
	var image_source_path = String(entry.get("edit_source_path", override_path)) if display_mode == DISPLAY_MODE_FULL_ART else override_path
	var image = load_image_from_file(ProjectSettings.globalize_path(image_source_path))
	if image == null:
		_manifest.erase(source_path)
		_save_manifest()
		return null
	if display_mode == DISPLAY_MODE_FULL_ART:
		image = build_full_art_preview(source_path, image)
		if image == null:
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
	if node_name != "Portrait" and node_name != "AncientPortrait":
		return false
	return _find_card_root(node) != null


func _looks_like_modded_card_atlas_source(path: String) -> bool:
	var normalized = path.replace("\\", "/").to_lower()
	return normalized.begins_with("res://") and normalized.contains(MODDED_CARD_ATLAS_SEGMENT) and normalized.ends_with(".tres")


func _looks_like_modded_card_portrait_image_source(path: String) -> bool:
	var normalized = path.replace("\\", "/").to_lower()
	if !normalized.begins_with("res://") or normalized.begins_with(MANAGED_TEXTURE_PREFIX):
		return false
	if !MOD_IMPORT_IMAGE_EXTENSIONS.has(normalized.get_extension()):
		return false
	for segment in MODDED_CARD_IMAGE_SEGMENTS:
		if normalized.contains(segment):
			return true
	return false


func _looks_like_card_art_source(path: String) -> bool:
	if path == "":
		return false
	if path.begins_with(MANAGED_TEXTURE_PREFIX) or path.begins_with(CARD_ATLAS_PREFIX):
		return true
	if _looks_like_modded_card_atlas_source(path):
		return true
	if _looks_like_modded_card_portrait_image_source(path):
		return true
	if path.begins_with("res://") and (
		path.contains("/card_portraits/")
		or path.ends_with(".png")
		or path.ends_with(".jpg")
		or path.ends_with(".jpeg")
		or path.ends_with(".webp")
		or path.ends_with(".gif")
	):
		return true
	return false


func _get_texture_resource_source_path(texture) -> String:
	if !(texture is Texture2D):
		return ""
	var texture_path = _normalize_source_path(String(texture.resource_path))
	if texture_path != "":
		return texture_path
	if texture is AtlasTexture and texture.atlas is Texture2D:
		return _normalize_source_path(String(texture.atlas.resource_path))
	return ""


func _resolve_texture_source_path(texture_rect, current_texture: Texture2D) -> String:
	var card_root = _find_card_root(texture_rect)
	var active_full_art_owner = _get_current_card_active_full_art_owner_path(card_root)
	if active_full_art_owner != "":
		return active_full_art_owner

	var model_source_path = _get_model_or_inspect_source_path(texture_rect)
	if model_source_path != "":
		return model_source_path

	var current_path = _get_texture_resource_source_path(current_texture)
	if current_path != "" and _looks_like_card_art_source(current_path):
		return current_path

	var ancestor = texture_rect
	while ancestor != null:
		if ancestor.has_meta(META_INSPECT_SOURCE_PATH):
			var inspect_source = _normalize_source_path(String(ancestor.get_meta(META_INSPECT_SOURCE_PATH, "")))
			if inspect_source != "" and _looks_like_card_art_source(inspect_source):
				return inspect_source
		if ancestor.has_meta(META_SOURCE_PATH):
			var ancestor_source = _normalize_source_path(String(ancestor.get_meta(META_SOURCE_PATH, "")))
			if ancestor_source != "" and _looks_like_card_art_source(ancestor_source):
				return ancestor_source
		ancestor = ancestor.get_parent()

	if texture_rect != null and texture_rect.has_meta(META_SOURCE_PATH):
		var stored_source = _normalize_source_path(String(texture_rect.get_meta(META_SOURCE_PATH, "")))
		if stored_source != "" and _looks_like_card_art_source(stored_source):
			return stored_source

	return current_path if current_path != "" and _looks_like_card_art_source(current_path) else ""


func _get_model_portrait_path_cache_key(model) -> String:
	if model == null or !(model is Object) or !is_instance_valid(model):
		return ""
	return str(model.get_instance_id())


func _remember_model_portrait_path(cache_key: String, source_path: String) -> void:
	if cache_key == "" or source_path == "":
		return
	if _model_portrait_path_cache.size() >= MODEL_PORTRAIT_PATH_CACHE_LIMIT:
		_model_portrait_path_cache.clear()
		_model_portrait_path_cache_keys_by_source.clear()
	elif _model_portrait_path_cache.has(cache_key):
		_forget_model_portrait_path_cache_key(cache_key)
	_model_portrait_path_cache[cache_key] = source_path
	var source_key = _canonicalize_source_key(source_path)
	if source_key == "":
		return
	var cache_keys = _model_portrait_path_cache_keys_by_source.get(source_key, {})
	if !(cache_keys is Dictionary):
		cache_keys = {}
	cache_keys[cache_key] = true
	_model_portrait_path_cache_keys_by_source[source_key] = cache_keys


func _forget_model_portrait_path_cache_key(cache_key: String) -> void:
	if cache_key == "" or !_model_portrait_path_cache.has(cache_key):
		return
	var source_key = _canonicalize_source_key(String(_model_portrait_path_cache.get(cache_key, "")))
	_model_portrait_path_cache.erase(cache_key)
	var cache_keys = _model_portrait_path_cache_keys_by_source.get(source_key, null)
	if !(cache_keys is Dictionary):
		return
	cache_keys.erase(cache_key)
	if cache_keys.is_empty():
		_model_portrait_path_cache_keys_by_source.erase(source_key)
	else:
		_model_portrait_path_cache_keys_by_source[source_key] = cache_keys


func invalidate_model_portrait_path_cache(model = null) -> void:
	if model == null:
		_model_portrait_path_cache.clear()
		_model_portrait_path_cache_keys_by_source.clear()
		return
	var cache_key = _get_model_portrait_path_cache_key(model)
	invalidate_model_portrait_path_cache_key(cache_key)


func invalidate_model_portrait_path_cache_key(cache_key: String) -> void:
	_forget_model_portrait_path_cache_key(cache_key)


func invalidate_card_model_portrait_path_cache(card_node) -> void:
	if card_node == null or !is_instance_valid(card_node):
		return
	var model = _get_card_model_from_root(card_node)
	if model != null:
		invalidate_model_portrait_path_cache(model)


func invalidate_model_portrait_path_cache_for_source(source_path: String) -> void:
	var source_key = _canonicalize_source_key(source_path)
	if source_key == "":
		return
	var cache_keys = _model_portrait_path_cache_keys_by_source.get(source_key, null)
	if !(cache_keys is Dictionary):
		return
	for cache_key in cache_keys.keys():
		_model_portrait_path_cache.erase(cache_key)
	_model_portrait_path_cache_keys_by_source.erase(source_key)


func _extract_model_portrait_path(model) -> String:
	if model == null:
		return ""

	var cache_key = _get_model_portrait_path_cache_key(model)
	if cache_key != "" and _model_portrait_path_cache.has(cache_key):
		return String(_model_portrait_path_cache[cache_key])

	var custom_portrait_path_variant = model.get("CustomPortraitPath")
	if custom_portrait_path_variant != null:
		var custom_portrait_path = _normalize_source_path(String(custom_portrait_path_variant))
		if custom_portrait_path != "" and _looks_like_card_art_source(custom_portrait_path):
			_remember_model_portrait_path(cache_key, custom_portrait_path)
			return custom_portrait_path

	var portrait_path_variant = model.get("PortraitPath")
	if portrait_path_variant != null:
		var portrait_path = _normalize_source_path(String(portrait_path_variant))
		if portrait_path != "" and _looks_like_card_art_source(portrait_path):
			_remember_model_portrait_path(cache_key, portrait_path)
			return portrait_path

	var all_portrait_paths = model.get("AllPortraitPaths")
	if all_portrait_paths is Array:
		for portrait_entry in all_portrait_paths:
			var normalized_path = _normalize_source_path(String(portrait_entry))
			if normalized_path != "" and _looks_like_card_art_source(normalized_path):
				_remember_model_portrait_path(cache_key, normalized_path)
				return normalized_path

	return ""


func _normalize_source_path(path: String) -> String:
	if _is_invalid_source_path_text(path):
		return ""

	path = path.replace("\\", "/")

	if !path.begins_with("res://") and !path.begins_with("user://"):
		var res_candidate = "res://%s" % path.trim_prefix("/")
		if ResourceLoader.exists(res_candidate):
			path = res_candidate

	if _looks_like_modded_card_portrait_image_source(path):
		return path

	if path.begins_with(MANAGED_TEXTURE_PREFIX):
		var canonical_managed_path = _canonicalize_managed_card_source_path(path)
		if canonical_managed_path != "":
			return canonical_managed_path
		if ResourceLoader.exists(path):
			return path
		var managed_basename_path = _resolve_source_path_from_basename(path.get_file().get_basename())
		if managed_basename_path != "":
			return managed_basename_path
		return path

	if path.begins_with(CARD_ATLAS_PREFIX) and path.ends_with(".tres"):
		var sprite_path = path.trim_prefix(CARD_ATLAS_PREFIX)
		sprite_path = sprite_path.trim_suffix(".tres")
		var fallback_path = "%s%s.png" % [MANAGED_TEXTURE_PREFIX, sprite_path]
		var canonical_atlas_path = _resolve_source_path_from_relative_card_key(sprite_path)
		if canonical_atlas_path != "":
			return canonical_atlas_path
		if ResourceLoader.exists(fallback_path):
			return fallback_path

	var imported_texture_path = _resolve_source_path_from_imported_texture_path(path)
	if imported_texture_path != "":
		return imported_texture_path

	var canonical_card_path = _canonicalize_managed_card_source_path(path)
	if canonical_card_path != "":
		return canonical_card_path

	if path.begins_with("res://") and MOD_IMPORT_IMAGE_EXTENSIONS.has(path.get_extension().to_lower()):
		var image_basename_path = _resolve_source_path_from_basename(path.get_file().get_basename())
		if image_basename_path != "":
			return image_basename_path

	return path


func _is_invalid_source_path_text(path: String) -> bool:
	var normalized_text = path.strip_edges().to_lower()
	if normalized_text == "":
		return true
	if normalized_text.contains("instance base is null"):
		return true
	if normalized_text.contains("null instance"):
		return true
	return false


func _ensure_storage() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STORAGE_IMAGE_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STORAGE_EDIT_SOURCE_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STORAGE_GIF_TEMP_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STORAGE_GIF_CACHE_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STORAGE_PCK_TEMP_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STORAGE_ART_PACK_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(GIF_TOOL_USER_PATH.get_base_dir()))


func _load_manifest() -> void:
	var absolute_manifest_path = ProjectSettings.globalize_path(STORAGE_MANIFEST_PATH)
	if !FileAccess.file_exists(absolute_manifest_path):
		_manifest = {}
		_mark_animated_overrides_cache_dirty()
		return

	var file = FileAccess.open(absolute_manifest_path, FileAccess.READ)
	if file == null:
		_manifest = {}
		_mark_animated_overrides_cache_dirty()
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_manifest = parsed
		_sanitize_manifest_for_missing_sources()
	else:
		_manifest = {}
	_mark_animated_overrides_cache_dirty()


func _sanitize_manifest_for_missing_sources() -> void:
	if _manifest.is_empty():
		return
	var removed_any := false
	var rekeyed_any := false
	var invalid_sources: Array = []
	var rekey_sources := {}
	for source_path in _manifest.keys():
		var normalized_source = _canonicalize_source_key(String(source_path))
		if !_is_manifest_source_still_valid(normalized_source):
			invalid_sources.append(String(source_path))
		elif normalized_source != String(source_path):
			rekey_sources[String(source_path)] = normalized_source
	for source_path in invalid_sources:
		var entry = _manifest.get(source_path, null)
		if entry is Dictionary:
			_remove_entry_files(entry)
		_manifest.erase(source_path)
		_erase_override_texture_cache(source_path)
		removed_any = true
	for source_path in rekey_sources.keys():
		if !_manifest.has(source_path):
			continue
		var normalized_source = String(rekey_sources[source_path])
		var entry = _manifest.get(source_path, null)
		_manifest.erase(source_path)
		_erase_override_texture_cache(source_path)
		if !_manifest.has(normalized_source):
			_manifest[normalized_source] = entry
		_erase_override_texture_cache(normalized_source)
		rekeyed_any = true
	if removed_any or rekeyed_any:
		_save_manifest_now()


func _is_manifest_source_still_valid(source_path: String) -> bool:
	if source_path == "":
		return false
	if _is_invalid_source_path_text(source_path):
		return false
	if source_path.begins_with(MANAGED_TEXTURE_PREFIX) or source_path.begins_with(CARD_ATLAS_PREFIX):
		return true
	if _looks_like_modded_card_atlas_source(source_path):
		return true
	if _looks_like_modded_card_portrait_image_source(source_path):
		return true
	if source_path.begins_with("res://"):
		return ResourceLoader.exists(source_path)
	if source_path.begins_with("user://"):
		return FileAccess.file_exists(ProjectSettings.globalize_path(source_path))
	return false


func _load_art_pack_registry() -> void:
	_clear_art_pack_variants_cache()
	var absolute_registry_path = ProjectSettings.globalize_path(STORAGE_ART_PACK_REGISTRY_PATH)
	if !FileAccess.file_exists(absolute_registry_path):
		_art_pack_registry = {"packs": {}}
		return
	var file = FileAccess.open(absolute_registry_path, FileAccess.READ)
	if file == null:
		_art_pack_registry = {"packs": {}}
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary and parsed.has("packs") and parsed["packs"] is Dictionary:
		_art_pack_registry = parsed
		_sanitize_art_pack_registry_for_missing_sources()
	else:
		_art_pack_registry = {"packs": {}}


func _sanitize_art_pack_registry_for_missing_sources() -> void:
	var packs = _art_pack_registry.get("packs", {})
	if !(packs is Dictionary) or packs.is_empty():
		return
	var removed_any := false
	var empty_pack_ids: Array = []
	for pack_id in packs.keys():
		var pack_data = packs.get(pack_id, null)
		if !(pack_data is Dictionary):
			empty_pack_ids.append(pack_id)
			removed_any = true
			continue
		var cards = pack_data.get("cards", {})
		if !(cards is Dictionary):
			pack_data["cards"] = {}
			packs[pack_id] = pack_data
			empty_pack_ids.append(pack_id)
			removed_any = true
			continue
		var invalid_sources: Array = []
		var rekey_sources := {}
		for source_path in cards.keys():
			var normalized_source = _normalize_source_path(String(source_path))
			if !_is_manifest_source_still_valid(normalized_source):
				invalid_sources.append(String(source_path))
			elif normalized_source != String(source_path):
				rekey_sources[String(source_path)] = normalized_source
		for source_path in invalid_sources:
			cards.erase(source_path)
			removed_any = true
		for source_path in rekey_sources.keys():
			if !cards.has(source_path):
				continue
			var normalized_source = String(rekey_sources[source_path])
			var card_entry = cards.get(source_path, null)
			cards.erase(source_path)
			if !cards.has(normalized_source):
				cards[normalized_source] = card_entry
			removed_any = true
		pack_data["cards"] = cards
		packs[pack_id] = pack_data
		if cards.is_empty():
			empty_pack_ids.append(pack_id)
	for pack_id in empty_pack_ids:
		packs.erase(pack_id)
		removed_any = true
	_art_pack_registry["packs"] = packs
	if removed_any:
		_save_art_pack_registry_now()


func _save_manifest() -> void:
	_mark_animated_overrides_cache_dirty()
	if _batch_update_depth > 0:
		_batch_manifest_dirty = true
		return
	_save_manifest_now()


func _save_manifest_now() -> void:
	_mark_animated_overrides_cache_dirty()
	var absolute_manifest_path = ProjectSettings.globalize_path(STORAGE_MANIFEST_PATH)
	var file = FileAccess.open(absolute_manifest_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_manifest, "\t"))


func _save_art_pack_registry() -> void:
	_clear_art_pack_variants_cache()
	if _batch_update_depth > 0:
		_batch_registry_dirty = true
		return
	_save_art_pack_registry_now()


func _save_art_pack_registry_now() -> void:
	_clear_art_pack_variants_cache()
	var absolute_registry_path = ProjectSettings.globalize_path(STORAGE_ART_PACK_REGISTRY_PATH)
	var file = FileAccess.open(absolute_registry_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_art_pack_registry, "\t"))


func _safe_file_stem(source_path: String) -> String:
	var stem = source_path.to_lower()
	stem = stem.replace("res://", "")
	stem = stem.replace("/", "_")
	stem = stem.replace("\\", "_")
	stem = stem.replace(":", "_")
	stem = stem.replace(".", "_")
	return stem

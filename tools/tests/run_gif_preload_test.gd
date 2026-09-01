extends SceneTree

const SOURCE_A := "res://images/packed/card_portraits/ironclad/strike_ironclad.png"
const SOURCE_B := "res://images/packed/card_portraits/ironclad/defend_ironclad.png"
const SOURCE_C := "res://images/packed/card_portraits/ironclad/bash.png"
var _failures := 0
var _checks := 0
var _frames: Array = []


func _initialize() -> void:
	_run.call_deferred()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if !condition:
		_failures += 1
		push_error(message)


func _entry(full_art: bool = false) -> Dictionary:
	return {"type": "animated_gif", "frame_paths": _frames.duplicate(), "source_frame_paths": _frames.duplicate(), "frame_delays": [0.1, 0.2, 0.3], "width": 16, "height": 12, "display_mode": "full_art" if full_art else "default"}


func _drain(manager) -> void:
	for tick in range(100):
		if !manager._gif_preload_requested and !manager._gif_preload_active:
			return
		manager._process_gif_preload()
	_expect(false, "Preloading did not finish within the test tick budget.")


func _run() -> void:
	# Refuse to touch real game settings: tests require an isolated APPDATA directory.
	if !OS.get_environment("APPDATA").replace("\\", "/").contains("build/gif_preload_test_appdata"):
		push_error("Set APPDATA to <workspace>/build/gif_preload_test_appdata before running.")
		quit(1)
		return
	var workspace = get_script().resource_path.get_base_dir().get_base_dir().get_base_dir()
	var game_pack = "C:/Program Files (x86)/Steam/steamapps/common/Slay the Spire 2/SlayTheSpire2.pck"
	if !ProjectSettings.load_resource_pack(game_pack) or !ProjectSettings.load_resource_pack(workspace.path_join("build/card_art_editor_mod/card_art_editor.pck")):
		push_error("Build the mod PCK before running this test.")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	var script = load("res://mods/card_art_editor/card_art_override_manager.gd")
	var manager = script.new()
	manager.name = "CardArtOverrideManager"
	_expect(!manager.get_gif_processing_settings().get("preload_enabled", true), "Preloading must default to OFF.")
	root.add_child(manager)
	manager.set_process(false)
	manager.cancel_gif_preload()
	manager._manifest.clear()
	manager._override_texture_cache.clear()
	manager._gif_preload_failed_sources.clear()
	var fixture_dir = "user://gif_preload_fixtures"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(fixture_dir))
	for index in range(3):
		var path = fixture_dir.path_join("frame_%d.png" % index)
		var picture = Image.create(16, 12, false, Image.FORMAT_RGBA8)
		picture.fill([Color.RED, Color.GREEN, Color.BLUE][index])
		_expect(picture.save_png(path) == OK, "Could not create test frame.")
		_frames.append(path)
	manager._manifest = {SOURCE_A: _entry(), SOURCE_B: _entry(true), SOURCE_C: {"override_path": _frames[0]}}
	manager.set_gif_processing_settings({"preload_enabled": false})
	manager.request_gif_preload(true)
	_expect(!manager._gif_preload_requested, "Disabled setting queued preload work.")
	var estimate = manager.get_gif_preload_estimate()
	_expect(estimate.cards == 2 and estimate.frames == 6, "Estimate must include only applied GIFs, not static cards.")
	_expect(estimate.bytes == 16 * 12 * 4 * 3 + 600 * 847 * 4 * 3, "Estimate used the wrong full-art dimensions.")
	manager.set_gif_processing_settings({"preload_enabled": true, "play_on_hover_only": true})
	_expect(manager._gif_preload_requested, "Enabling preload did not queue work immediately.")
	_expect(manager._get_override_texture(SOURCE_A) == null, "Pending preload synchronously decoded a GIF.")
	manager._begin_batch_updates()
	manager._process_gif_preload()
	_expect(!manager._gif_preload_active, "Preload started during a batch rewrite.")
	manager._end_batch_updates()
	var native_ancient_root = Control.new()
	native_ancient_root.name = "CardContainer"
	var native_ancient_group = CanvasGroup.new()
	native_ancient_group.name = "PortraitCanvasGroup"
	var native_ancient_portrait = TextureRect.new()
	native_ancient_portrait.name = "AncientPortrait"
	native_ancient_portrait.set_meta(manager.META_SOURCE_PATH, SOURCE_C)
	native_ancient_portrait.set_meta(manager.META_REFRESH_SIGNATURE, "native-ancient-untouched")
	native_ancient_group.add_child(native_ancient_portrait)
	native_ancient_root.add_child(native_ancient_group)
	var native_ancient_id = native_ancient_portrait.get_instance_id()
	manager._portrait_refs[native_ancient_id] = weakref(native_ancient_portrait)
	manager._portrait_ref_ids.append(native_ancient_id)
	manager._needs_full_refresh = false
	manager._refresh_portraits_after_gif_preload()
	_expect(native_ancient_portrait.get_meta(manager.META_REFRESH_SIGNATURE) == "native-ancient-untouched" and !manager._needs_full_refresh and native_ancient_group.material == null, "Preload completion touched an unedited native Ancient card.")
	manager._portrait_refs.erase(native_ancient_id)
	manager._portrait_ref_ids.erase(native_ancient_id)
	native_ancient_root.free()
	manager._process_gif_preload()
	_expect(manager._gif_preload_active and manager._gif_preload_processed_frames == 0, "Preload setup must get a tick before loading frames.")
	_expect(!is_instance_valid(manager._gif_preload_popup), "Automatic preload displayed a startup progress popup.")
	manager.request_gif_preload(false, true)
	_expect(is_instance_valid(manager._gif_preload_popup), "Explicit preload did not display its progress popup.")
	_expect(!paused, "Preloading must not pause the game or multiplayer tree.")
	var card_root = Control.new()
	card_root.name = "CardContainer"
	var portrait_group = CanvasGroup.new()
	portrait_group.name = "PortraitCanvasGroup"
	var portrait = TextureRect.new()
	portrait.name = "Portrait"
	portrait.texture = ImageTexture.create_from_image(Image.load_from_file(_frames[0]))
	portrait.texture.resource_path = SOURCE_A
	portrait_group.add_child(portrait)
	card_root.add_child(portrait_group)
	root.add_child(card_root)
	manager.apply_override_to_texture_rect(portrait)
	await process_frame
	manager._process_gif_preload()
	_expect(manager._gif_preload_processed_frames == 1 and !manager._override_texture_cache.has(SOURCE_A), "Preload must process one frame per tick and not publish partial jobs.")
	_drain(manager)
	await process_frame
	var animation = manager._override_texture_cache.get(SOURCE_A)
	_expect(animation is AnimatedTexture, "No animated texture was cached.")
	if !(animation is AnimatedTexture):
		quit(1)
		return
	_expect(animation.frames == 3 and animation.pause, "Unused preloaded animations must remain paused.")
	_expect(portrait.texture == animation.get_frame_texture(0) and bool(portrait.get_meta(manager.META_OVERRIDE_ACTIVE, false)), "A card seen during preload was stuck on its original image after completion.")
	card_root.free()
	_expect(is_equal_approx(animation.get_frame_duration(1), 0.2), "Frame timing changed.")
	_expect(manager._get_override_texture(SOURCE_A, false) == animation.get_frame_texture(0), "Hover-only first frame was loaded twice.")
	_expect(animation.pause, "Static retrieval started animation playback.")
	_expect(manager._get_override_texture(SOURCE_A) == animation and !animation.pause, "Animated retrieval failed to resume the cached animation.")
	var full_art = manager._override_texture_cache[SOURCE_B]
	_expect(full_art.get_width() == 600 and full_art.get_height() == 847, "Full-art preload used incorrect dimensions.")
	manager.request_gif_preload(true)
	_drain(manager)
	_expect(manager._gif_preload_total_frames == 0 and manager._override_texture_cache[SOURCE_A] == animation, "Completed GIFs were unnecessarily loaded again.")

	manager._erase_override_texture_cache(SOURCE_A)
	manager._process_gif_preload()
	manager._process_gif_preload()
	manager.cancel_gif_preload()
	_expect(!manager._gif_preload_active and !manager._override_texture_cache.has(SOURCE_A), "Cancel published an incomplete GIF.")
	_expect(manager._override_texture_cache[SOURCE_B] == full_art, "Cancel discarded a completed GIF.")
	manager.request_gif_preload()
	_expect(!manager._gif_preload_requested, "Session cancellation was ignored.")
	manager.request_gif_preload(true)
	_drain(manager)
	_expect(manager._override_texture_cache.has(SOURCE_A), "Explicit retry did not restart cancelled work.")

	manager._erase_override_texture_cache(SOURCE_A)
	manager._process_gif_preload()
	manager._process_gif_preload()
	var replacement = _entry()
	replacement.frame_delays = [0.4, 0.5, 0.6]
	manager._manifest[SOURCE_A] = replacement
	manager._erase_override_texture_cache(SOURCE_A)
	manager._process_gif_preload()
	_expect(!manager._override_texture_cache.has(SOURCE_A), "A stale job was published after a card was changed.")
	_drain(manager)
	_expect(is_equal_approx(manager._override_texture_cache[SOURCE_A].get_frame_duration(0), 0.4), "Replacement entry was not preloaded.")
	manager._erase_override_texture_cache(SOURCE_A)
	manager._process_gif_preload()
	manager._manifest.erase(SOURCE_A)
	_drain(manager)
	_expect(!manager._override_texture_cache.has(SOURCE_A), "Restored card was republished by an old job.")

	var broken = _entry()
	broken.frame_paths = [_frames[0], fixture_dir.path_join("missing_%d.png" % Time.get_ticks_usec())]
	manager._manifest[SOURCE_A] = broken
	manager._erase_override_texture_cache(SOURCE_A)
	_drain(manager)
	_expect(manager._gif_preload_failed_sources.has(SOURCE_A), "Missing frames were not reported.")
	_expect(manager._manifest.has(SOURCE_A) and FileAccess.file_exists(_frames[0]), "Preload failure deleted user art.")
	var repaired_image = Image.create(16, 12, false, Image.FORMAT_RGBA8)
	repaired_image.fill(Color.WHITE)
	repaired_image.save_png(broken.frame_paths[1])
	manager.request_gif_preload(true)
	_drain(manager)
	_expect(manager._override_texture_cache[SOURCE_A].frames == 2 and manager._gif_preload_failed_sources.is_empty(), "Retry reused an incomplete cache instead of repaired frames.")

	var long_entry = _entry()
	long_entry.frame_paths = []
	long_entry.frame_delays = []
	for index in range(300):
		long_entry.frame_paths.append("%d.png" % index)
		long_entry.frame_delays.append(0.1)
	var plan = manager._get_gif_frame_plan(long_entry)
	var duration := 0.0
	for frame in plan:
		duration += frame.delay
	_expect(plan.size() == 256 and is_equal_approx(duration, 30.0) and int(plan.back().path.get_basename()) >= 298, "Long GIF sampling lost its duration or sequence tail.")

	manager._manifest = {SOURCE_A: _entry()}
	manager._save_manifest()
	manager._save_persistent_preferences()
	manager.free()
	manager = script.new()
	manager.name = "CardArtOverrideManager"
	root.add_child(manager)
	manager.set_process(false)
	_expect(manager._gif_preload_requested and manager.get_gif_processing_settings().preload_enabled, "Launch did not restore preload preference and queue GIFs.")
	_drain(manager)
	_expect(manager._override_texture_cache.has(SOURCE_A), "Launch preload failed.")
	_expect(!is_instance_valid(manager._gif_preload_popup), "Successful launch preload must remain silent.")
	await process_frame

	var overlay = load("res://mods/card_art_editor/inspect_card_art_editor.tscn").instantiate()
	root.add_child(overlay)
	overlay.set_process(false)
	overlay._editor_popup.show()
	for locale in ["en", "ko", "zh", "ja"]:
		overlay._locale = locale
		overlay._on_gif_settings_pressed()
		for tick in range(4):
			await process_frame
		var popup = overlay._gif_settings_popup
		_expect(popup.visible and popup.position.y >= 0 and popup.get_global_rect().end.y <= root.size.y, "GIF settings overflowed the screen in " + locale)
		var expected_gif_height = minf(overlay._gif_settings_content.get_combined_minimum_size().y + 34, minf(520, root.size.y - 48))
		_expect(absf(popup.size.y - expected_gif_height) <= 2, "GIF settings retained unnecessary blank height in " + locale)
		_expect(overlay._gif_preload_check.text != "option", "Preload translation missing in " + locale)
	overlay._on_gif_settings_close_pressed()
	overlay._on_settings_pressed()
	for tick in range(2):
		await process_frame
	var expected_settings_height = minf(overlay._settings_content.get_combined_minimum_size().y + 28, minf(500, root.size.y - 24))
	_expect(absf(overlay._settings_panel.size.y - expected_settings_height) <= 2, "Settings panel retained unnecessary blank height (actual %.1f, expected %.1f, content %.1f)." % [overlay._settings_panel.size.y, expected_settings_height, overlay._settings_content.get_combined_minimum_size().y])
	_expect(overlay._settings_panel.get_global_rect().end.y <= root.size.y, "Settings panel overflowed the screen.")
	_expect(!overlay._gif_settings_require_rebuild({"preload_enabled": false}, {"preload_enabled": true}), "Preload toggle must not reprocess original GIF files.")
	overlay._gif_preload_check.button_pressed = false
	overlay._on_gif_settings_apply_pressed()
	_expect(!manager.get_gif_processing_settings().preload_enabled, "Applying the checkbox did not disable preload.")
	overlay._on_gif_settings_pressed()
	overlay._gif_preload_check.button_pressed = true
	overlay._on_gif_settings_close_pressed()
	_expect(!manager.get_gif_processing_settings().preload_enabled, "Closing without Apply saved a draft preference.")
	overlay._on_gif_settings_pressed()
	overlay._gif_preload_check.button_pressed = true
	overlay._on_gif_settings_apply_pressed()
	_expect(manager._gif_preload_requested and manager._gif_preload_show_progress, "UI Apply did not start a visible preload.")
	overlay._on_reset_settings_pressed()
	_expect(!manager.get_gif_processing_settings().preload_enabled and !overlay._gif_preload_check.button_pressed, "Reset must restore the default OFF preference.")
	overlay.free()
	manager.free()
	print("GIF preloading regression: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)

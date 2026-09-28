extends SceneTree

class CardId extends Resource:
	var Entry := ""

class CardModel extends Resource:
	var PortraitPath := ""
	var Id = null
	var Rarity := 2

class TestCard extends Control:
	var Model = null

const SOURCE := "res://images/packed/card_portraits/ironclad/strike_ironclad.png"
var _failures := 0


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error(message)


func _write_empty_file(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_8(0)


func _texture(color: Color) -> ImageTexture:
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if !OS.get_environment("APPDATA").replace("\\", "/").contains("build/skin_changer_bridge_test_appdata"):
		push_error("Set APPDATA to <workspace>/build/skin_changer_bridge_test_appdata before running.")
		quit(1)
		return
	var workspace = get_script().resource_path.get_base_dir().get_base_dir().get_base_dir()
	var game_pack = "C:/Program Files (x86)/Steam/steamapps/common/Slay the Spire 2/SlayTheSpire2.pck"
	if !ProjectSettings.load_resource_pack(game_pack) or !ProjectSettings.load_resource_pack(workspace.path_join("build/card_art_editor_mod/card_art_editor.pck")):
		push_error("Build the mod PCK before running this test.")
		quit(1)
		return

	var fixture_root = ProjectSettings.globalize_path("user://skin_changer_bridge_fixture")
	var skin_root = fixture_root.path_join("skin_changer")
	var cae_root = fixture_root.path_join("card_art_editor")
	DirAccess.make_dir_recursive_absolute(skin_root)
	DirAccess.make_dir_recursive_absolute(cae_root)
	var generated_pack_dir = cae_root.path_join("CAE_Saved_Art")
	DirAccess.make_dir_recursive_absolute(generated_pack_dir)
	_write_empty_file(generated_pack_dir.path_join("cae_saved_art.cardartpack.json"))
	_write_empty_file(generated_pack_dir.path_join("cae_pack_info.json"))
	_write_empty_file(skin_root.path_join("Gurio.SkinChanger.dll"))
	_write_empty_file(cae_root.path_join("card_art_editor.dll"))
	_write_empty_file(cae_root.path_join("card_art_editor.pck"))
	var image_path = "user://skin_changer_bridge_fixture/override.png"
	var image = Image.create(24, 18, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.6, 0.9, 1.0))
	_expect(image.save_png(image_path) == OK, "Could not create the bridge fixture image.")
	var edit_source_path = "user://skin_changer_bridge_fixture/edit_source.png"
	var edit_source_image = Image.create(30, 40, false, Image.FORMAT_RGBA8)
	edit_source_image.fill(Color(0.8, 0.3, 0.1, 0.65))
	_expect(edit_source_image.save_png(edit_source_path) == OK, "Could not create the bridge edit-source fixture image.")

	var manager = load("res://mods/card_art_editor/card_art_override_manager.gd").new()
	manager.name = "CardArtOverrideManager"
	root.add_child(manager)
	manager.set_process(false)
	manager.cancel_gif_preload()
	manager._manifest = {
		SOURCE: {
			"override_path": image_path,
			"edit_source_path": edit_source_path,
			"display_mode": "full_art",
			"type": "static",
			"adjust_zoom": 1.2,
			"adjust_offset_x": 3.0,
			"adjust_offset_y": -4.0,
			"updated_at": "skin-bridge-test"
		}
	}
	manager._art_pack_registry = {
		"packs": {
			"registered-workshop-pack": {"id": "registered-workshop-pack", "cards": {SOURCE: {}}}
		},
		"workshop_sources": {
			"registered": {
				"path": "C:/Steam/workshop/FULL_BBC.cardartpack.json",
				"pack_id": "registered-workshop-pack",
				"dismissed": false
			},
			"removed": {
				"path": "C:/Steam/workshop/keep-visible.cardartpack.json",
				"pack_id": "",
				"dismissed": true
			}
		}
	}
	manager._override_texture_cache = {SOURCE: _texture(Color.RED)}
	_expect(manager.get_skin_changer_bridge_imported_pack_paths() == PackedStringArray(["C:/Steam/workshop/FULL_BBC.cardartpack.json"]), "Only registered Workshop pack sources should be deduplicated.")

	var card_id = CardId.new()
	card_id.Entry = "STRIKE_IRONCLAD"
	var model = CardModel.new()
	model.Id = card_id
	model.PortraitPath = SOURCE
	var card = TestCard.new()
	card.Model = model
	var card_root = Control.new()
	card_root.name = "CardContainer"
	var group = CanvasGroup.new()
	group.name = "PortraitCanvasGroup"
	var portrait = TextureRect.new()
	portrait.name = "Portrait"
	portrait.texture = _texture(Color.BLUE)
	var ancient_portrait = TextureRect.new()
	ancient_portrait.name = "AncientPortrait"
	ancient_portrait.visible = false
	ancient_portrait.texture = _texture(Color.GREEN)
	group.add_child(portrait)
	group.add_child(ancient_portrait)
	card_root.add_child(group)
	for node_name in ["PortraitBorder", "Frame", "TitleBanner", "AncientHighlight", "AncientBorderGlassOverlay", "AncientBorder", "AncientTextBg", "AncientBanner", "TypePlaque"]:
		var visual = TextureRect.new()
		visual.name = node_name
		visual.visible = node_name in ["PortraitBorder", "Frame", "TitleBanner"]
		card_root.add_child(visual)
	card.add_child(card_root)
	root.add_child(card)

	manager._refresh_portrait_node(portrait, true)
	var full_art_layer = group.get_node_or_null("CardArtFullArtLayer")
	_expect(full_art_layer is TextureRect and bool(full_art_layer.get_meta(manager.META_FULL_ART_ACTIVE, false)), "The test card did not enter CAE full-art mode before bridge activation.")
	await process_frame
	_expect(manager.configure_skin_changer_bridge(skin_root, cae_root), "The Skin Changer bridge did not activate.")
	_expect(!FileAccess.file_exists(generated_pack_dir.path_join("cae_saved_art.cardartpack.json")), "The legacy Workshop-generated pack was not removed.")
	_expect(!FileAccess.file_exists(generated_pack_dir.path_join("cae_pack_info.json")), "The legacy Workshop-generated pack metadata was not removed.")
	_expect(manager._skin_changer_bridge.get_pack_path().contains("build/skin_changer_bridge_test_appdata"), "The generated Skin Changer pack was not moved to user data.")
	manager._refresh_portrait_node(portrait, true)
	full_art_layer = group.get_node_or_null("CardArtFullArtLayer")
	_expect(full_art_layer == null or !bool(full_art_layer.get_meta(manager.META_FULL_ART_ACTIVE, false)), "CAE kept a competing full-art layer after Skin Changer became active.")
	_expect(manager.has_override(SOURCE), "Bridge activation hid the saved override from the editor UI.")
	_expect(manager._get_override_texture(SOURCE) == null, "CAE continued direct rendering while Skin Changer owned presentation.")

	var published_directories: Array = []
	manager.skin_changer_pack_published.connect(func(directory): published_directories.append(directory))
	manager._skin_changer_bridge.schedule_sync(manager._manifest)
	manager._skin_changer_bridge.flush_for_test()
	var pack_path = manager._skin_changer_bridge.get_pack_path()
	_expect(FileAccess.file_exists(pack_path), "The Skin Changer bridge did not publish an art pack.")
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(pack_path))
	_expect(parsed is Dictionary and parsed.get("format", "") == "card_art_bundle", "The generated Skin Changer pack has an invalid envelope.")
	var entries = parsed.get("overrides", []) if parsed is Dictionary else []
	_expect(entries is Array and entries.size() == 1, "The generated Skin Changer pack has the wrong number of cards.")
	if entries is Array and entries.size() == 1:
		_expect(entries[0].get("source_path", "") == SOURCE, "The generated pack lost the canonical source path.")
		_expect(entries[0].get("display_mode", "") == "full_art", "The generated pack lost its full-art mode.")
		_expect(String(entries[0].get("png_base64", "")) != "", "The generated pack lost its rendered portrait image.")
		_expect(entries[0].get("edit_source_png_base64", "") == entries[0].get("png_base64", ""), "Skin Changer would load the unadjusted editor source instead of rendered pixels.")
		var rendered = Image.new()
		_expect(rendered.load_png_from_buffer(Marshalls.base64_to_raw(entries[0]["png_base64"])) == OK, "Full-art output is not PNG.")
		_expect(rendered.get_size() == manager.FULL_ART_TARGET_SIZE, "A landscape storage crop was exported as full art.")
		_expect(int(entries[0]["width"]) == rendered.get_width() and int(entries[0]["height"]) == rendered.get_height(), "Full-art dimensions do not match the rendered pixels.")
		var expected = manager.build_full_art_preview(SOURCE, edit_source_image)
		_expect(rendered.get_data() == expected.get_data(), "Bridge full art does not match CAE's adjusted rendering.")
		_expect(is_equal_approx(float(entries[0].get("adjust_zoom", 0.0)), 1.2), "The generated pack lost its full-art adjustment metadata.")
	_expect(manager.get_skin_changer_bridge_changed_sources_csv() == "", "Initial publication must preserve skin choices.")
	_expect(published_directories.size() == 1, "The manager did not announce the generated Skin Changer pack update.")
	var restarted_bridge = load("res://mods/card_art_editor/skin_changer_bridge.gd").new()
	var restart_publications: Array = []
	restarted_bridge.pack_published.connect(func(directory): restart_publications.append(directory))
	_expect(restarted_bridge.configure(skin_root, cae_root, Callable(manager, "build_skin_changer_full_art_image")), "A restarted bridge did not activate.")
	restarted_bridge.schedule_sync(manager._manifest)
	restarted_bridge.flush_for_test()
	_expect(restart_publications.size() == 1, "A restarted bridge did not register its existing pack with Skin Changer.")
	_expect(restarted_bridge.get_last_changed_sources_csv() == "", "Startup registration incorrectly reset user card selections.")
	_expect(restarted_bridge._entry_cache.is_empty() and restarted_bridge._build_entries.is_empty(), "An unchanged startup decoded or rendered the entire pack instead of reusing the disk index.")
	manager._skin_changer_bridge.schedule_sync(manager._manifest)
	manager._skin_changer_bridge.flush_for_test()
	_expect(published_directories.size() == 1, "An unchanged Skin Changer pack triggered an unnecessary catalog refresh.")
	manager._skin_changer_bridge.schedule_sync(manager._manifest, true)
	manager._skin_changer_bridge.flush_for_test()
	_expect(published_directories.size() == 2, "Changing imported pack registration did not refresh the catalog.")
	_expect(manager.get_skin_changer_bridge_changed_sources_csv() == "", "Changing the pack list changed individual card selections.")
	manager._manifest[SOURCE]["adjust_zoom"] = 1.5
	manager._skin_changer_bridge.schedule_sync(manager._manifest)
	manager._skin_changer_bridge.flush_for_test()
	_expect(manager.get_skin_changer_bridge_changed_sources_csv() == SOURCE, "Editing a card did not invalidate its provider cache.")
	manager._manifest[SOURCE]["display_mode"] = "default"
	manager._skin_changer_bridge.schedule_sync(manager._manifest)
	manager._skin_changer_bridge.flush_for_test()
	parsed = JSON.parse_string(FileAccess.get_file_as_string(pack_path))
	var normal_image = Image.new()
	normal_image.load_png_from_buffer(Marshalls.base64_to_raw(parsed["overrides"][0]["png_base64"]))
	_expect(normal_image.get_size() == image.get_size(), "Disabling full art kept the full-art output or used the tall editor source.")
	manager._skin_changer_bridge.schedule_sync({})
	manager._skin_changer_bridge.flush_for_test()
	_expect(published_directories.size() == 5 and !FileAccess.file_exists(pack_path), "Removing every override did not announce removal of the unified Skin Changer pack.")

	# Missing or invalid cache data must rebuild rather than suppress current art.
	var cold_bridge = load("res://mods/card_art_editor/skin_changer_bridge.gd").new()
	cold_bridge.configure(skin_root, cae_root, Callable(manager, "build_skin_changer_full_art_image"))
	cold_bridge.schedule_sync(manager._manifest)
	cold_bridge.flush_for_test()
	_expect(FileAccess.file_exists(pack_path) and !cold_bridge._entry_cache.is_empty(), "A missing generated pack incorrectly hit the startup cache.")
	var edited_bridge = load("res://mods/card_art_editor/skin_changer_bridge.gd").new()
	edited_bridge.configure(skin_root, cae_root, Callable(manager, "build_skin_changer_full_art_image"))
	edited_bridge.schedule_sync(manager._manifest)
	edited_bridge.flush_for_test()
	_expect(edited_bridge._entry_cache.is_empty(), "Restart unnecessarily loaded image payloads.")
	var edited_manifest = manager._manifest.duplicate(true)
	edited_manifest[SOURCE]["display_mode"] = "full_art"
	edited_bridge.schedule_sync(edited_manifest)
	edited_bridge.flush_for_test()
	_expect(edited_bridge.get_last_changed_sources_csv() == SOURCE, "An edit after a cache-only startup was lost.")
	parsed = JSON.parse_string(FileAccess.get_file_as_string(pack_path))
	_expect(parsed["overrides"][0]["display_mode"] == "full_art", "Cached normal art survived a full-art edit.")
	var corrupt_index = FileAccess.open(edited_bridge.get_pack_directory().path_join(edited_bridge.CACHE_INDEX_FILENAME), FileAccess.WRITE)
	corrupt_index.store_string("not-json")
	corrupt_index = null
	var recovery_bridge = load("res://mods/card_art_editor/skin_changer_bridge.gd").new()
	recovery_bridge.configure(skin_root, cae_root, Callable(manager, "build_skin_changer_full_art_image"))
	recovery_bridge.schedule_sync(edited_manifest)
	recovery_bridge.flush_for_test()
	_expect(!recovery_bridge._entry_cache.is_empty(), "An invalid cache index prevented rebuilding the current pack.")
	recovery_bridge.schedule_sync({})
	recovery_bridge.flush_for_test()

	# Skin Changer is allowed to choose a non-native presentation. CAE must not
	# replace that layout or restore stale provider pixels after selection/reuse.
	manager._manifest.clear()
	card_id.Entry = "BREAK"
	model.PortraitPath = "res://images/packed/card_portraits/event/neows_fury.png"
	model.Rarity = 5
	portrait.visible = true
	ancient_portrait.visible = false
	(card_root.get_node("Frame") as CanvasItem).visible = true
	(card_root.get_node("TitleBanner") as CanvasItem).visible = true
	(card_root.get_node("AncientBorder") as CanvasItem).visible = false
	var provider_texture = _texture(Color.YELLOW)
	portrait.texture = provider_texture
	portrait.set_meta(manager.META_OVERRIDE_ACTIVE, true)
	portrait.set_meta(manager.META_ORIGINAL_TEXTURE, _texture(Color.MAGENTA))
	manager.capture_card_provider_after_visual_update(card, true)
	manager.apply_card_override_after_visual_update(card)
	manager.queue_card_override_refresh(card)
	manager.queue_card_provider_capture(card)
	manager.register_inspect_card_provider_pin(card)
	manager._restore_external_provider_texture(card)
	manager._clear_source_overrides_in_tree(card, SOURCE)
	manager._refresh_portrait_node(portrait, true)
	await process_frame
	_expect(portrait.texture == provider_texture, "CAE replaced Skin Changer's selected portrait with stale pixels.")
	_expect(portrait.visible and !ancient_portrait.visible, "CAE changed Skin Changer's chosen portrait layout.")
	_expect((card_root.get_node("Frame") as CanvasItem).visible, "CAE hid Skin Changer's selected frame.")
	_expect(!manager.card_needs_override_refresh(card), "Passive bridge mode scheduled another competing refresh.")

	card.free()
	manager.free()
	if _failures == 0:
		print("Skin Changer bridge regression passed.")
	quit(1 if _failures > 0 else 0)

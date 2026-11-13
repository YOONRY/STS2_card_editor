extends SceneTree

const ROOT := "res://images/packed/card_portraits/"
const IRONCLAD := ROOT + "ironclad/strike_ironclad.png"
const ANCIENT := ROOT + "ironclad/corruption.png"
const SILENT := ROOT + "silent/the_gambit.png"
const COLORLESS := ROOT + "colorless/the_gambit.png"
const QUEST := ROOT + "quest/dowsing.png"
const MODDED := "res://ExampleMod/art/custom_card.png"
var _checks := 0
var _failures := 0
var _folder := ""


func _initialize() -> void:
	_run.call_deferred()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if !condition:
		_failures += 1
		push_error(message)


func _read_pack(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	_expect(parsed is Dictionary, "Export is not a JSON object: " + path)
	return parsed if parsed is Dictionary else {}


func _card(path: String, id: String = "", base_game: bool = true) -> Dictionary:
	return {"source_path": path, "card_id": id, "is_base_game_model": base_game}


func _run() -> void:
	if !OS.get_environment("APPDATA").replace("\\", "/").ends_with("build/export_regression_test_appdata"):
		push_error("Use isolated build/export_regression_test_appdata APPDATA.")
		quit(1)
		return
	var workspace = get_script().resource_path.get_base_dir().get_base_dir().get_base_dir()
	if !ProjectSettings.load_resource_pack("C:/Program Files (x86)/Steam/steamapps/common/Slay the Spire 2/SlayTheSpire2.pck") or !ProjectSettings.load_resource_pack(workspace.path_join("build/card_art_editor_mod/card_art_editor.pck")):
		quit(1)
		return
	_folder = ProjectSettings.globalize_path("user://export_%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(_folder)
	var png = _folder.path_join("source.png")
	var image = Image.create(16, 12, false, Image.FORMAT_RGBA8)
	image.fill(Color.RED)
	_expect(image.save_png(png) == OK, "Fixture PNG failed.")
	var manager = load("res://mods/card_art_editor/card_art_override_manager.gd").new()
	manager.name = "CardArtOverrideManager"
	root.add_child(manager)
	manager.set_process(false)
	manager.cancel_gif_preload()
	manager._manifest.clear()
	var entry = {"type": "static", "override_path": png, "edit_source_path": png, "width": 16, "height": 12, "display_mode": "default"}
	for path in [IRONCLAD, ANCIENT, SILENT, COLORLESS, QUEST, MODDED]:
		manager._manifest[path] = entry.duplicate(true)
	manager._manifest[ANCIENT] = {"type": "animated_gif", "frame_paths": [png, png], "frame_delays": [0.1, 0.2], "width": 16, "height": 12, "display_mode": "full_art", "adjust_zoom": 1.25}
	var manifest_before = manager._manifest.duplicate(true)
	var aliases_before = manager._provider_source_alias_cache.duplicate(true)
	var sources = manager.get_library_export_sources([
		_card(IRONCLAD, "STRIKE_IRONCLAD"),
		_card("res://images/atlases/card_atlas.sprites/ironclad/corruption.tres", "CORRUPTION"),
		_card(ANCIENT, "CORRUPTION")])
	_expect(sources.size() == 2 and sources.has(IRONCLAD) and sources.has(ANCIENT), "Character selection missed Ancient art or duplicated atlas aliases.")
	var path = _folder.path_join("ironclad.cardartpack.json")
	_expect(manager.export_bundle_to_file(path, sources).ok, "Category export failed.")
	var pack = _read_pack(path)
	_expect(pack.get("count") == 2 and pack.overrides.size() == 2, "Category export leaked other characters.")
	for exported in pack.overrides:
		_expect(sources.has(exported.source_path), "Unexpected source in filtered pack.")
		if exported.source_path == ANCIENT:
			_expect(exported.frames.size() == 2 and exported.frames[1].delay == 0.2, "GIF frames/delays were lost.")
			_expect(exported.display_mode == "full_art" and exported.adjust_zoom == 1.25, "Full-art adjustment was lost.")
	var quest_sources = manager.get_library_export_sources([_card(QUEST, "DOWSING")])
	_expect(quest_sources == [QUEST], "Quest source was dropped because its folder is not a character.")
	var mod_sources = manager.get_library_export_sources([_card(MODDED, "CUSTOM_CARD", false)])
	_expect(mod_sources == [MODDED], "Modded category relied on a known folder or character name.")
	_expect(manager.get_library_export_sources([_card(SILENT, "THE_GAMBIT")]) == [SILENT], "Same-name card leaked across pools.")
	_expect(manager.get_library_export_sources([_card(COLORLESS, "THE_GAMBIT")]) == [COLORLESS], "Colorless source was merged with Silent.")
	_expect(manager.get_library_export_sources([]).is_empty(), "Empty category became all cards.")
	_expect(manager._manifest == manifest_before and manager._provider_source_alias_cache == aliases_before, "Export selection mutated live card state.")
	for selection in [[], ["res://missing.png"], [""]]:
		var empty_path = _folder.path_join("empty.cardartpack.json")
		_expect(!manager.export_bundle_to_file(empty_path, selection).ok, "Empty category exported all images.")
		_expect(!FileAccess.file_exists(empty_path), "Empty category created a file.")
	var saved_bytes = FileAccess.get_file_as_bytes(path)
	_expect(!manager.export_bundle_to_file(path, []).ok and FileAccess.get_file_as_bytes(path) == saved_bytes, "Empty selection overwrote an existing pack.")
	path = _folder.path_join("all.cardartpack.json")
	_expect(manager.export_bundle_to_file(path).ok, "All-card export regressed.")
	_expect(_read_pack(path).count == 6, "All-card export scope changed.")

	# Exercise the real popup callback, not only the PNG manager method.
	var editor = load("res://mods/card_art_editor/inspect_card_art_editor.tscn").instantiate()
	root.add_child(editor)
	editor.set_process(false)
	editor._editor_popup.show()
	editor._current_source_path = IRONCLAD
	editor._configure_export_dialog(editor.EXPORT_DIALOG_MODE_CURRENT_PNG)
	path = _folder.path_join("single.png")
	editor._on_export_file_selected(path)
	_expect(FileAccess.file_exists(path), "Popup failed to export PNG.")
	_expect(!FileAccess.file_exists(path + ".cardartpack.json"), "PNG popup still exported a sidecar art pack.")
	var result_image = Image.load_from_file(path)
	_expect(result_image != null and result_image.get_pixel(0, 0) == Color.RED, "Wrong PNG pixels.")
	# Error path must not fall back to whole-pack export either.
	path = _folder.path_join("missing_dir/failure.png")
	editor._on_export_file_selected(path)
	_expect(!FileAccess.file_exists(path + ".cardartpack.json"), "Failed PNG exported JSON.")
	for locale in ["ko", "en", "zh", "ja"]:
		editor._locale = locale
		editor._apply_locale()
		_expect(editor._export_library_pack_button.text != "export_library_pack" and !editor._export_library_pack_button.tooltip_text.is_empty(), "Missing category export localization: " + locale)
	editor._locale = "en"
	editor._on_export_library_pack_pressed()
	_expect(editor._export_library_sources.is_empty() and !editor._export_file_dialog.visible, "Outside compendium exported all cards.")
	var fixture = {"name": "Ironclad", "cards": [_card(IRONCLAD), _card(ANCIENT)]}
	editor.library_export_context_requested.connect(func():
		editor.set_meta("_card_art_export_library_cards", fixture.cards)
		editor.set_meta("_card_art_export_library_name", fixture.name))
	editor._on_export_library_pack_pressed()
	_expect(editor._export_dialog_mode == editor.EXPORT_DIALOG_MODE_LIBRARY and editor._export_library_sources.size() == 2, "Category button did not snapshot scope.")
	_expect(editor._export_file_dialog.visible, "Category button did not open save dialog.")
	editor._export_file_dialog.hide()
	fixture.cards = [_card(SILENT)]
	path = _folder.path_join("ui_category.cardartpack.json")
	editor._on_export_file_selected(path)
	pack = _read_pack(path)
	_expect(pack.count == 2 and pack.overrides[0].source_path == IRONCLAD, "Selection changed while save dialog was open.")
	_expect(editor._export_library_sources.is_empty(), "Completed export kept stale selection.")
	editor._on_export_library_pack_pressed()
	_expect(editor._export_library_sources == [SILENT], "Second export retained previous category.")
	editor._export_file_dialog.hide()
	editor._on_export_dialog_canceled()
	_expect(editor._export_library_sources.is_empty(), "Cancel retained stale selection.")
	fixture.cards = [_card(ROOT + "ironclad/bash.png")]
	editor._on_export_library_pack_pressed()
	_expect(editor._export_library_sources.is_empty() and !editor._export_file_dialog.visible, "Unmodified category opened export dialog.")
	editor._configure_export_dialog(editor.EXPORT_DIALOG_MODE_PACK)
	path = _folder.path_join("ui_all.cardartpack.json")
	editor._on_export_file_selected(path)
	_expect(_read_pack(path).count == 6, "Popup all-card export regressed after category export.")
	editor.free()
	manager.free()
	print("Export regression: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures else 0)

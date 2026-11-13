extends SceneTree

const PNG_ROOT := "res://images/packed/card_portraits/"
const ATLAS_ROOT := "res://images/atlases/card_atlas.sprites/"
var _checks := 0
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if !condition:
		_failures += 1
		if _failures <= 20:
			push_error(message)


func _run() -> void:
	if !OS.get_environment("APPDATA").replace("\\", "/").ends_with("build/category_update_test_appdata"):
		push_error("Use isolated build/category_update_test_appdata APPDATA.")
		quit(1)
		return
	var workspace = get_script().resource_path.get_base_dir().get_base_dir().get_base_dir()
	if !ProjectSettings.load_resource_pack("C:/Program Files (x86)/Steam/steamapps/common/Slay the Spire 2/SlayTheSpire2.pck") or !ProjectSettings.load_resource_pack(workspace.path_join("build/card_art_editor_mod/card_art_editor.pck")):
		quit(1)
		return
	var script = load("res://mods/card_art_editor/card_art_override_manager.gd")
	var manager = script.new()
	root.add_child(manager)
	manager.set_process(false)
	manager.cancel_gif_preload()
	manager._manifest.clear()
	manager._ensure_storage()
	var image = Image.create(8, 6, false, Image.FORMAT_RGBA8)
	image.fill(Color.CYAN)
	var image_path := "user://category_fixture.png"
	_expect(image.save_png(image_path) == OK, "Fixture PNG creation failed.")
	var entry = {"type": "static", "width": 8, "height": 6, "override_path": image_path, "edit_source_path": image_path}
	var paths: Array = []
	manager._collect_card_source_paths(PNG_ROOT.trim_suffix("/"), paths)
	_expect(!paths.is_empty(), "Game portrait index is empty.")
	var folders := {}
	var new_sources: Array = []
	var cards := {}
	var atlas_count := 0
	var ambiguous_ids := {}
	var name_sources := {}
	for path in paths:
		var relative = String(path).trim_prefix(PNG_ROOT)
		var category = relative.get_slice("/", 0) if relative.contains("/") else "other"
		folders[category] = int(folders.get(category, 0)) + 1
		_expect(manager._canonicalize_source_key(path) == path, "PNG resolves to a different card: " + path)
		var atlas = ATLAS_ROOT + relative.trim_suffix(".png") + ".tres"
		if ResourceLoader.exists(atlas):
			atlas_count += 1
			_expect(manager._canonicalize_source_key(atlas) == path, "Atlas/PNG identity mismatch: " + relative)
		_expect(manager._get_art_pack_category_id_for_source(path) == category, "Wrong category: " + relative)
		if relative.get_file().get_basename() in ["beta", "ancient_beta"]:
			continue
		if relative.contains("/beta/") and category != "fool":
			continue
		var id = relative.get_file().get_basename().to_upper()
		if !relative.contains("/beta/") or !ResourceLoader.exists(String(path).replace("/beta/", "/")):
			if !name_sources.has(id):
				name_sources[id] = []
			name_sources[id].append(path)
		cards[path] = entry.duplicate(true)
		if category == "fool":
			new_sources.append(path)
			_expect(manager._is_known_art_pack_category_id(category), "New character not recognized by category fallback.")
			_expect(manager._get_art_pack_category_display_name(category) == "Fool", "New character displayed as Other.")
			var provider = "res://TestReskin/images/card_portraits/" + relative
			_expect(manager._canonicalize_source_key(provider) == path, "Reskin path failed for new character: " + relative)
			manager._manifest[path] = entry.duplicate(true)
			var model_atlas = atlas.replace("/beta/", "/")
			var expected_model_source = String(path).replace("/beta/", "/") if ResourceLoader.exists(String(path).replace("/beta/", "/")) else path
			_expect(manager._canonicalize_source_key(model_atlas) == expected_model_source, "Beta-only card's model path failed to find its PNG: " + relative)
			var preview = manager.get_source_image(model_atlas)
			_expect(preview is Image and !preview.is_empty() and !preview.is_compressed(), "Beta-only source preview cannot load: " + relative)
			_expect(manager._load_source_texture(model_atlas) is Texture2D, "Cannot restore native beta-only portrait: " + relative)
			_expect(manager._get_override_texture(atlas, false) is Texture2D, "New character override not renderable: " + relative)
			_expect(manager.get_library_export_sources([{"source_path": atlas, "card_id": id, "is_base_game_model": true}]) == [path], "New character missing from category export: " + relative)
	for id in name_sources:
		var matches: Array = name_sources[id]
		var resolved = manager._resolve_managed_source_from_card_id(id)
		if matches.size() > 1:
			ambiguous_ids[id] = matches
			_expect(resolved == "", "Ambiguous ID resolved to an arbitrary card: " + id)
		else:
			_expect(resolved == matches[0], "Unique card ID could not resolve: " + id)
	_expect(new_sources.size() >= 90, "Fool portraits are missing from the current game.")
	for folder in folders:
		if folder != "other":
			_expect(manager._get_card_portrait_folders().has(folder), "Runtime folder discovery missed " + folder)
	_expect(manager._get_art_pack_category_display_name("future_character") == "Future Character", "Unknown categories are hidden behind Other.")
	manager._art_pack_registry = {"packs": {"audit": {"id": "audit", "name": "Category audit", "cards": cards}}}
	var categories = manager.get_art_pack_categories("audit")
	var ids: Array = []
	for category in categories:
		ids.append(category.id)
		_expect(category.name != "Other" or category.id == "other", "Known resource category displayed as Other: " + category.id)
	_expect(ids.has("fool"), "New character missing from category dropdown data.")
	_expect(ids.find("defect") < ids.find("fool") and ids.find("fool") < ids.find("colorless"), "New character sort order is incorrect.")
	manager._manifest.clear()
	var applied = await manager.apply_art_pack_to_category("audit", "fool")
	_expect(applied.ok, "New character category could not be applied.")
	_expect(manager._manifest.size() == new_sources.size(), "Category apply changed cards outside the selected character.")
	manager._save_manifest_now()
	manager._save_art_pack_registry_now()
	manager.free()
	var restored = script.new()
	restored._load_manifest()
	restored._load_art_pack_registry()
	_expect(restored._manifest.size() == new_sources.size(), "New character overrides were lost on restart.")
	for path in new_sources:
		_expect(restored.has_override(path), "Missing saved new-character art: " + path)
		var variants = restored.get_art_pack_variants_for_source(path)
		_expect(variants.size() == 1 and variants[0].active, "Applied pack state lost on restart: " + path)
	# Per-state artwork must keep separate keys, even when cards share a model ID.
	for variants in [["status/wither1", "status/wither2", "status/wither3"], ["event/mad_science_attack", "event/mad_science_skill", "event/mad_science_power"], ["event/dingy_dagger", "event/fine_dagger", "event/pristine_dagger"]]:
		var keys := {}
		for variant in variants:
			var png = PNG_ROOT + variant + ".png"
			var atlas = ATLAS_ROOT + variant + ".tres"
			_expect(ResourceLoader.exists(png) and ResourceLoader.exists(atlas), "Variant resource missing: " + variant)
			keys[restored._canonicalize_source_key(atlas)] = true
		_expect(keys.size() == variants.size(), "Different state artwork was merged.")
	var model_source := ATLAS_ROOT + "fool/foolish_shot.tres"
	var actual_source := PNG_ROOT + "fool/beta/foolish_shot.png"
	_expect(!restored.get_source_image_bytes(model_source).is_empty(), "Native preview cannot encode beta-only art.")
	_expect(restored.save_override_from_file(model_source, ProjectSettings.globalize_path(image_path)).ok, "Single-file import failed on beta-only model path.")
	_expect(restored.has_override(actual_source) and restored._get_override_texture(model_source, false) is Texture2D, "Single-file import saved under the wrong beta-only key.")
	_expect(restored.export_source_image_to_png(model_source, "user://fool_export.png").ok, "New character PNG export failed.")
	restored.free()
	print("Portrait folders (PNG including beta): ", folders)
	print("Duplicate filenames retained as separate paths: ", ambiguous_ids)
	print("Audited %d PNGs, %d matching atlases, %d Fool portraits" % [paths.size(), atlas_count, new_sources.size()])
	print("Category update regression: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures else 0)

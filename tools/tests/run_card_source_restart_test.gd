extends SceneTree

class CardId extends Resource:
	var Entry := ""

class CardModel extends Resource:
	var Id = null
	var PortraitPath := ""

const PNG_ROOT := "res://images/packed/card_portraits/"
const ATLAS_ROOT := "res://images/atlases/card_atlas.sprites/"
const CASES := [
	"colorless/the_gambit", "silent/the_gambit", "quest/byrdonis_egg",
	"quest/lantern_key", "quest/spoils_map", "quest/dowsing",
	"event/abundance", "ironclad/strike_ironclad"
]
var _checks := 0
var _failures := 0
var _script
var _image_path := "user://restart_fixture.png"
var _second_image_path := "user://restart_fixture_new.png"


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if !condition:
		_failures += 1
		push_error(message)


func _entry(path: String = "", updated_at: String = "2026-09-28T01:00:00") -> Dictionary:
	return {"type": "static", "override_path": _image_path if path == "" else path,
		"width": 8, "height": 8, "updated_at": updated_at, "provider_pack_id": "restart_fixture"}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if !OS.get_environment("APPDATA").replace("\\", "/").ends_with("build/card_source_restart_test_appdata"):
		push_error("Set an isolated APPDATA ending in build/card_source_restart_test_appdata.")
		quit(1)
		return
	var workspace = get_script().resource_path.get_base_dir().get_base_dir().get_base_dir()
	if !ProjectSettings.load_resource_pack("C:/Program Files (x86)/Steam/steamapps/common/Slay the Spire 2/SlayTheSpire2.pck") or !ProjectSettings.load_resource_pack(workspace.path_join("build/card_art_editor_mod/card_art_editor.pck")):
		quit(1)
		return
	_script = load("res://mods/card_art_editor/card_art_override_manager.gd")
	var before = _script.new()
	before._ensure_storage()
	var image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.RED)
	_expect(image.save_png(_image_path) == OK, "Could not create original fixture.")
	image.fill(Color.BLUE)
	_expect(image.save_png(_second_image_path) == OK, "Could not create second fixture.")

	var paths: Array = []
	before._collect_card_source_paths(PNG_ROOT.trim_suffix("/"), paths)
	_expect(!paths.is_empty(), "Exported PCK image index is empty.")
	var seen := {}
	for path in paths:
		seen[path] = true
	_expect(seen.size() == paths.size(), "Source index contains duplicate PNG/import/remap entries.")
	var pack_cards := {}
	for relative in CASES:
		var png = PNG_ROOT + relative + ".png"
		var atlas = ATLAS_ROOT + relative + ".tres"
		var card_id = relative.get_file().to_upper()
		_expect(ResourceLoader.exists(atlas) and ResourceLoader.exists(png), "Missing game fixture: " + relative)
		_expect(paths.has(png), "PCK enumeration missed " + png)
		_expect(before._canonicalize_source_key(atlas) == png, "Cold atlas lookup did not normalize " + relative)
		_expect(before.register_runtime_provider_source(atlas, card_id, true) == atlas, "Registration changed the visible provider path.")
		var key = before._canonicalize_source_key(atlas)
		_expect(key == png, "Runtime registration changed the saved key for " + relative)
		before._manifest[key] = _entry()
		pack_cards[atlas] = _entry()
		_expect(before._get_override_texture(atlas, false) is Texture2D, "Initial override lookup failed for " + relative)
	before._art_pack_registry = {"packs": {"restart_fixture": {"id": "restart_fixture", "name": "Restart fixture", "cards": pack_cards}}}
	before._save_manifest_now()
	before._save_art_pack_registry_now()
	before.free()

	for restart in range(2):
		var after = _script.new()
		after._load_manifest()
		after._load_art_pack_registry()
		_expect(after._manifest.size() == CASES.size(), "Restart lost or merged unrelated cards.")
		for relative in CASES:
			var png = PNG_ROOT + relative + ".png"
			var atlas = ATLAS_ROOT + relative + ".tres"
			var card_id = relative.get_file().to_upper()
			_expect(after.has_override(atlas), "Cold restart lookup failed for " + relative)
			after.register_runtime_provider_source(atlas, card_id, true)
			_expect(after._canonicalize_source_key(atlas) == png, "Warm restart changed key for " + relative)
			_expect(after._get_override_texture(atlas, false) is Texture2D, "Restart could not render " + relative)
			var model = CardModel.new()
			model.Id = CardId.new()
			model.Id.Entry = card_id
			model.PortraitPath = atlas
			model.set_meta(after.META_MODEL_IS_BASE_GAME, true)
			_expect(after.get_source_path_for_model(model) == atlas, "Model lookup replaced the rendering resource.")
			_expect(after._canonicalize_source_key(atlas) == png and after.has_override(atlas), "GDScript model registration diverged from C# registration.")
			var variants = after.get_art_pack_variants_for_source(atlas)
			_expect(variants.size() == 1 and variants[0].get("active", false), "Applied pack state differs from renderer for " + relative)
			after._save_manifest_now()
		after.free()

	_test_legacy_manifest()
	_test_provider_isolation()
	_expect(FileAccess.file_exists(_image_path) and FileAccess.file_exists(_second_image_path), "Migration deleted existing artwork.")
	print("Card source restart regression: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures else 0)


func _test_legacy_manifest() -> void:
	var old = _script.new()
	for relative in CASES:
		old._manifest[ATLAS_ROOT + relative + ".tres"] = _entry()
	old._save_manifest_now()
	old.free()
	var migrated = _script.new()
	migrated._load_manifest()
	for relative in CASES:
		var atlas = ATLAS_ROOT + relative + ".tres"
		var png = PNG_ROOT + relative + ".png"
		migrated.register_runtime_provider_source(atlas, relative.get_file().to_upper(), true)
		_expect(migrated._manifest.has(png) and !migrated._manifest.has(atlas), "Legacy key not migrated for " + relative)
		_expect(migrated._get_override_texture(atlas, false) is Texture2D, "Legacy edit stopped rendering for " + relative)
	migrated.free()

	var relative = "quest/lantern_key"
	var png = PNG_ROOT + relative + ".png"
	var atlas = ATLAS_ROOT + relative + ".tres"
	for newer_atlas in [true, false]:
		var writer = _script.new()
		writer._manifest[png] = _entry(_image_path, "2026-09-28T01:00:00" if newer_atlas else "2026-09-28T03:00:00")
		writer._manifest[atlas] = _entry(_second_image_path, "2026-09-28T02:00:00")
		writer._save_manifest_now()
		writer.free()
		var reader = _script.new()
		reader._load_manifest()
		_expect(reader._manifest.size() == 1, "Duplicate atlas/PNG entries were not consolidated.")
		_expect(reader._manifest[png].override_path == (_second_image_path if newer_atlas else _image_path), "Migration discarded the newest edit.")
		reader.register_runtime_provider_source(atlas, "LANTERN_KEY", true)
		_expect(reader._get_override_texture(atlas, false) is Texture2D, "Consolidated edit is not renderable.")
		reader.free()


func _test_provider_isolation() -> void:
	var manager = _script.new()
	for relative in CASES:
		if relative.begins_with("quest/"):
			_expect(manager._resolve_managed_source_from_card_id(relative.get_file().to_upper()) == PNG_ROOT + relative + ".png", "Quest ID fallback failed.")
	_expect(manager._resolve_managed_source_from_card_id("THE_GAMBIT") == "", "Ambiguous filenames must not guess a category.")
	var external = "res://TestProvider/images/card_portraits/quest/lantern_key.png"
	manager.register_runtime_provider_source(external, "LANTERN_KEY", false)
	_expect(manager._canonicalize_source_key(external) == external, "Custom character was merged into a stock card.")
	manager.register_runtime_provider_source(external, "LANTERN_KEY", true)
	_expect(manager._canonicalize_source_key(external) == PNG_ROOT + "quest/lantern_key.png", "Stock-card reskin no longer resolves by ID.")
	_expect(manager.register_runtime_provider_source("", "STRIKE_IRONCLAD", true) == PNG_ROOT + "ironclad/strike_ironclad.png", "Pathless stock-card fallback regressed.")
	manager.free()

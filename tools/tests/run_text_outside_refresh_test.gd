extends SceneTree

class CardId extends Resource:
	var Entry := ""

class CardModel extends Resource:
	var PortraitPath := ""
	var Id = CardId.new()
	var Rarity := 2
	var Type := 1

class TestCard extends Control:
	var Model = CardModel.new()

const SOURCE := "res://images/packed/card_portraits/ironclad/strike_ironclad.png"
const OTHER := "res://images/packed/card_portraits/ironclad/defend_ironclad.png"
const ANCIENT := "res://images/packed/card_portraits/event/neows_fury.png"
var _checks := 0
var _failures := 0

func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if !condition:
		_failures += 1
		push_error(message)

func _initialize() -> void:
	_run.call_deferred()

func _card(manager, source: String, id: String, native := false) -> TestCard:
	var card = TestCard.new()
	card.Model.PortraitPath = source
	card.Model.Id.Entry = id
	card.Model.Rarity = 5 if native else 2
	var container = Control.new()
	container.name = "CardContainer"
	card.add_child(container)
	var group = CanvasGroup.new()
	group.name = "PortraitCanvasGroup"
	container.add_child(group)
	var pixels = Image.create(16, 24, false, Image.FORMAT_RGBA8)
	pixels.fill(Color.BLUE)
	var texture = ImageTexture.create_from_image(pixels)
	for node_name in ["Portrait", "AncientPortrait"]:
		var portrait = TextureRect.new()
		portrait.name = node_name
		portrait.texture = texture
		portrait.visible = (node_name == "AncientPortrait") == native
		portrait.set_meta(manager.META_SOURCE_PATH, source)
		group.add_child(portrait)
	for node_name in ["Frame", "TitleBanner", "PortraitBorder", "AncientBorder", "AncientTextBg", "AncientBanner", "TypePlaque"]:
		var node = TextureRect.new()
		node.name = node_name
		node.texture = texture
		container.add_child(node)
	var description = RichTextLabel.new()
	description.name = "DescriptionLabel"
	description.text = "Card description"
	container.add_child(description)
	root.add_child(card)
	if !native:
		manager._manifest[source] = {"display_mode": "full_art"}
		manager._override_texture_cache[source] = texture
	for portrait in group.get_children():
		manager._track_portrait(portrait)
	var active = group.get_node("AncientPortrait" if native else "Portrait")
	manager._refresh_portrait_node(active, true)
	manager._refresh_portrait_node(active, true)
	return card

func _assert_layout(card: TestCard, outside: bool) -> void:
	var container = card.get_node("CardContainer")
	_expect(container.get_node("DescriptionLabel").visible == !outside, "Description visibility did not change without a reload.")
	_expect(container.get_node("AncientTextBg").visible == !outside, "Text background did not change without a reload.")
	_expect(container.get_node("TypePlaque").visible == !outside, "Type plaque did not change without a reload.")
	_expect(!container.get_node("Frame").visible, "Text toggle exposed the normal card frame.")

func _run() -> void:
	if !OS.get_environment("APPDATA").replace("\\", "/").contains("build/text_outside_refresh_test_appdata"):
		push_error("Use isolated build/text_outside_refresh_test_appdata.")
		quit(1)
		return
	var workspace = get_script().resource_path.get_base_dir().get_base_dir().get_base_dir()
	if !ProjectSettings.load_resource_pack("C:/Program Files (x86)/Steam/steamapps/common/Slay the Spire 2/SlayTheSpire2.pck") or !ProjectSettings.load_resource_pack(workspace.path_join("build/card_art_editor_mod/card_art_editor.pck")):
		quit(1)
		return
	var manager = load("res://mods/card_art_editor/card_art_override_manager.gd").new()
	var grid = _card(manager, SOURCE, "STRIKE_IRONCLAD")
	var inspect = _card(manager, SOURCE, "STRIKE_IRONCLAD")
	var unrelated = _card(manager, OTHER, "DEFEND_IRONCLAD")
	var native = _card(manager, ANCIENT, "NEOWS_FURY", true)
	var portrait = grid.get_node("CardContainer/PortraitCanvasGroup/Portrait")
	var art = grid.get_node("CardContainer/PortraitCanvasGroup/CardArtFullArtLayer").texture
	var signature = String(portrait.get_meta(manager.META_REFRESH_SIGNATURE))
	manager._needs_full_refresh = false
	# The public setter must update both representations without an inspect
	# Reload, pointer motion, a polling frame, or a portrait texture reload.
	manager.set_ancient_text_outside_enabled(SOURCE, true)
	_assert_layout(grid, true)
	_assert_layout(inspect, true)
	_assert_layout(unrelated, false)
	_expect(!manager._needs_full_refresh, "A text-only toggle scheduled a global image refresh.")
	var changed_signature = manager._build_refresh_signature(portrait, portrait.texture, SOURCE, SOURCE, grid.get_node("CardContainer"), false, false)
	_expect(signature != changed_signature, "The portrait signature omitted Move Text Outside.")
	manager.set_ancient_text_outside_enabled(SOURCE, false)
	_assert_layout(grid, false)
	_assert_layout(inspect, false)
	# Bulk settings and offscreen cards must use the same event path.
	grid.visible = false
	manager.set_all_ancient_text_outside_enabled(true)
	_assert_layout(grid, true)
	_assert_layout(unrelated, true)
	manager.set_all_ancient_text_outside_enabled(false)
	grid.visible = true
	_assert_layout(grid, false)
	_expect(grid.get_node("CardContainer/PortraitCanvasGroup/CardArtFullArtLayer").texture == art, "Text-only changes rebuilt the full-art texture.")
	manager.set_ancient_text_outside_enabled(ANCIENT, true)
	_assert_layout(native, true)
	for _tick in range(3):
		manager._refresh_tracked_portraits(0)
	_assert_layout(native, true)
	manager.set_ancient_text_outside_enabled(ANCIENT, false)
	_assert_layout(native, false)
	# A cache miss must also notice a changed preference, without force=true.
	manager._ancient_text_outside_by_source[SOURCE] = true
	manager.refresh_all_portraits()
	manager._refresh_tracked_portraits(0)
	_assert_layout(grid, true)
	manager._ancient_text_outside_by_source.clear()
	manager.refresh_all_portraits()
	manager._refresh_tracked_portraits(0)
	_assert_layout(grid, false)
	for card in [grid, inspect, unrelated, native]:
		card.free()
	manager.free()
	print("Text outside refresh regression: %d checks, %d failures." % [_checks, _failures])
	quit(1 if _failures else 0)

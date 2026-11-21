extends SceneTree

class CardId extends Resource:
	var Entry := "STRIKE_IRONCLAD"

class CardModel extends Resource:
	var Id = CardId.new()
	var PortraitPath := "res://images/packed/card_portraits/ironclad/strike_ironclad.png"
	var Rarity := 2
	var Type := 1

class TestCard extends Control:
	var Model = CardModel.new()

const SOURCE := "res://images/packed/card_portraits/ironclad/strike_ironclad.png"
var _checks := 0
var _failures := 0


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if !condition:
		_failures += 1
		push_error(message)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if !OS.get_environment("APPDATA").replace("\\", "/").contains("build/full_art_frame_test_appdata"):
		push_error("Set APPDATA to <workspace>/build/full_art_frame_test_appdata before running.")
		quit(1)
		return
	var workspace = get_script().resource_path.get_base_dir().get_base_dir().get_base_dir()
	var game_pack = "C:/Program Files (x86)/Steam/steamapps/common/Slay the Spire 2/SlayTheSpire2.pck"
	if !ProjectSettings.load_resource_pack(game_pack) or !ProjectSettings.load_resource_pack(workspace.path_join("build/card_art_editor_mod/card_art_editor.pck")):
		push_error("Build the mod PCK before running this test.")
		quit(1)
		return
	var manager = load("res://mods/card_art_editor/card_art_override_manager.gd").new()
	var expected := {}
	for card_type in ["attack", "skill", "power", "quest"]:
		var texture = manager._get_ancient_text_bg_texture_for_type_name(card_type)
		_expect(texture is Texture2D, "Missing full-art background for " + card_type)
		var path = "res://images/atlases/compressed_atlas.sprites/ancient_text_bg_%s.tres" % card_type
		if card_type == "quest" and !ResourceLoader.exists(path):
			path = "res://images/atlases/compressed_atlas.sprites/ancient_text_bg_skill.tres"
		_expect(texture == load(path), "Wrong current-game background for " + card_type)
		_expect(texture == manager._get_ancient_text_bg_texture_for_type_name(card_type), "Background must be shared from the cache.")
		expected[card_type] = texture
	_expect(expected.attack != expected.skill and expected.skill != expected.power and expected.attack != expected.power, "Attack, Skill and Power must use distinct shapes.")
	var border_texture = manager._get_ancient_border_texture()
	_expect(border_texture == load("res://images/atlases/compressed_atlas.sprites/ancient_card_border.tres"), "The border must use the current game resource.")
	_expect(manager._get_ancient_text_bg_texture_for_type_name("unsupported") == null, "Unknown card types must not be loaded as atlas paths.")
	_expect(manager._full_art_frame_texture_cache.size() == 5, "Only known frame styles should enter the cache.")
	for value in [0, 2, 4, 5, "None", "Status", "Curse"]:
		_expect(manager._normalize_card_type_name(value) == "skill", "Status/Curse/None must use the game's Skill background.")

	var card = TestCard.new()
	card.set_meta("_card_art_inspect_card_id", "STRIKE_IRONCLAD")
	card.set_meta("_card_art_model_rarity", 2)
	var container = Control.new()
	container.name = "CardContainer"
	card.add_child(container)
	var group = CanvasGroup.new()
	group.name = "PortraitCanvasGroup"
	container.add_child(group)
	var placeholder = load("res://images/powers/missing_power.png")
	for node_name in ["Portrait", "AncientPortrait"]:
		var portrait_node = TextureRect.new()
		portrait_node.name = node_name
		portrait_node.texture = placeholder
		portrait_node.visible = node_name == "Portrait"
		group.add_child(portrait_node)
	for node_name in ["Frame", "TitleBanner", "PortraitBorder", "AncientBorder", "AncientTextBg", "AncientBanner", "TypePlaque"]:
		var visual = TextureRect.new()
		visual.name = node_name
		visual.texture = placeholder
		container.add_child(visual)
	var label = Label.new()
	label.name = "TypeLabel"
	container.add_child(label)
	var description = RichTextLabel.new()
	description.name = "DescriptionLabel"
	container.add_child(description)
	root.add_child(card)
	var portrait = group.get_node("Portrait")
	var ancient_portrait = group.get_node("AncientPortrait")
	var bg = container.get_node("AncientTextBg")
	var border = container.get_node("AncientBorder")
	manager._manifest = {SOURCE: {"display_mode": "full_art"}}
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLUE)
	var art = ImageTexture.create_from_image(image)
	manager._override_texture_cache = {SOURCE: art}

	for card_type in ["Attack", "Skill", "Power", "Quest", "Curse"]:
		# Real NCard.Model is not readable from GDScript. The bootstrap stamp must
		# work independently of the language or a provider's custom plaque label.
		card.Model = null
		card.set_meta("_card_art_model_type", card_type)
		label.text = "unrecognized localized type"
		bg.texture = placeholder
		border.texture = placeholder
		var key = "skill" if card_type == "Curse" else card_type.to_lower()
		_expect(manager._apply_full_art_state(portrait, SOURCE, art), "Full art failed for " + card_type)
		_expect(bg.texture == expected[key], "Metadata did not select the correct type background for " + card_type)
		_expect(border.texture == border_texture, "A stale/missing border texture survived full-art conversion.")
		_expect(bg.visible and border.visible, "The full-art frame must be visible.")
		_expect(!container.get_node("Frame").visible and !portrait.visible, "Full art must not expose the regular frame or portrait.")

	card.set_meta("_card_art_model_type", "Power")
	bg.texture = placeholder
	border.texture = placeholder
	manager._enforce_custom_full_art_layer_visibility(container, false)
	_expect(bg.texture == expected.power and border.texture == border_texture, "An event refresh must repair frames even when the portrait signature is unchanged.")
	bg.visible = false
	manager._enforce_custom_full_art_layer_visibility(container, false)
	_expect(!bg.visible, "Refreshing the frame must not undo Move Text Outside visibility.")

	card.Model = CardModel.new()
	card.Model.Id.Entry = "DEFEND_IRONCLAD"
	card.Model.Type = 2
	card.set_meta("_card_art_model_type", "Power")
	label.text = "Attack"
	_expect(manager._get_effective_ancient_card_type_name_for_card(container) == "skill", "A recycled slot must not use the previous card's type stamp or label.")
	card.set_meta("_card_art_inspect_card_id", "DEFEND_IRONCLAD")
	card.set_meta("_card_art_model_type", "Skill")
	manager._apply_full_art_card_type_style(container, bg)
	_expect(bg.texture == expected.skill, "A pooled slot did not update its frame for the new card type.")
	card.Model = null
	card.remove_meta("_card_art_model_type")
	label.text = "Power"
	_expect(manager._get_effective_ancient_card_type_name_for_card(container) == "power", "Legacy label fallback stopped working.")
	label.text = "unknown"
	manager._apply_full_art_card_type_style(container, bg)
	_expect(bg.texture == null, "An unknown type must not retain the previous card's background.")
	card.set_meta("_card_art_model_type", "Attack")

	# Moving text outside hides the type background but restoring it must use
	# the same current-game Attack style, not revive a stale texture.
	manager._ancient_text_outside_by_source = {SOURCE: true}
	manager._apply_ancient_text_outside_layout(container)
	_expect(!bg.visible and !description.visible, "Move Text Outside did not hide the background and text.")
	_expect(border.visible, "Move Text Outside must keep the full-art border.")
	manager._ancient_text_outside_by_source.clear()
	manager._apply_ancient_text_outside_layout(container)
	_expect(bg.visible and bg.texture == expected.attack and description.visible, "Restoring text did not restore the correct frame.")

	card.Model = CardModel.new()
	card.set_meta("_card_art_inspect_card_id", "STRIKE_IRONCLAD")
	manager._clear_custom_full_art_layer(container)
	_expect(container.get_node("Frame").visible and portrait.visible, "Disabling full art must restore the regular layout.")
	_expect(!bg.visible and !border.visible, "Disabling full art must hide its frame nodes.")
	_expect(container.get_node("Frame").texture == placeholder, "The normal frame texture must not be replaced.")

	# A native/provider Ancient layout owns its frame textures, even when its
	# text is temporarily moved outside. Do not overwrite those custom assets.
	card.Model.Rarity = 5
	card.set_meta("_card_art_model_rarity", 5)
	portrait.visible = false
	ancient_portrait.visible = true
	bg.texture = art
	border.texture = art
	manager._apply_full_art_card_type_style(container, bg)
	_expect(bg.texture == art and border.texture == art, "Native Ancient/provider textures must be preserved.")

	var fixture_path = "user://frame_fallback.tres"
	_expect(ResourceSaver.save(art, fixture_path) == OK, "Could not write isolated fallback fixture.")
	var missing_path = "res://images/atlases/nonexistent_test_atlas.sprites/missing.tres"
	_expect(manager._load_full_art_frame_texture("fallback-test", [missing_path, fixture_path]) is Texture2D, "Valid fallback resource was not loaded.")
	_expect(manager._load_full_art_frame_texture("missing-test", [missing_path]) == null, "Missing atlas must not produce a placeholder.")
	_expect(manager._full_art_frame_texture_cache.has("missing-test"), "Failed lookups must also be cached to avoid repeated warnings.")
	card.free()
	manager.free()
	print("Full-art frame regression: %d checks, %d failures." % [_checks, _failures])
	quit(1 if _failures else 0)

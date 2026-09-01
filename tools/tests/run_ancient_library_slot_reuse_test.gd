extends SceneTree

class CardId extends Resource:
	var Entry := ""

class CardModel extends Resource:
	var PortraitPath := ""
	var Id = null
	var Rarity := 2

class TestCard extends Control:
	var Model = null


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _texture(color: Color) -> ImageTexture:
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


func _force_regular_layout(card_root, portrait: TextureRect, ancient_portrait: TextureRect) -> void:
	portrait.visible = true
	ancient_portrait.visible = false
	(card_root.get_node("Frame") as CanvasItem).visible = true
	(card_root.get_node("TitleBanner") as CanvasItem).visible = true
	(card_root.get_node("AncientBorder") as CanvasItem).visible = false


func _initialize() -> void:
	var workspace = get_script().resource_path.get_base_dir().get_base_dir().get_base_dir()
	if !ProjectSettings.load_resource_pack("C:/Program Files (x86)/Steam/steamapps/common/Slay the Spire 2/SlayTheSpire2.pck") or !ProjectSettings.load_resource_pack(workspace.path_join("build/card_art_editor_mod/card_art_editor.pck")):
		_fail("Build the mod PCK before running this test.")
		return
	var manager = load("res://mods/card_art_editor/card_art_override_manager.gd").new()
	root.add_child(manager)
	await process_frame
	var regular_source = "res://images/packed/card_portraits/ironclad/strike_ironclad.png"
	var ancient_source = "res://images/packed/card_portraits/event/neows_fury.png"
	var card_id = CardId.new()
	card_id.Entry = "STRIKE_IRONCLAD"
	var model = CardModel.new()
	model.Id = card_id
	model.PortraitPath = regular_source
	var card = TestCard.new()
	card.Model = model
	card.set_meta("_card_art_inspect_card_id", "STRIKE_IRONCLAD")
	card.set_meta("_card_art_model_rarity", 2)
	var card_root = Control.new()
	card_root.name = "CardContainer"
	var group = CanvasGroup.new()
	group.name = "PortraitCanvasGroup"
	var portrait = TextureRect.new()
	portrait.name = "Portrait"
	portrait.texture = _texture(Color.BLUE)
	var ancient_portrait = TextureRect.new()
	ancient_portrait.name = "AncientPortrait"
	ancient_portrait.texture = _texture(Color.GREEN)
	ancient_portrait.visible = false
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
	manager._manifest = {regular_source: {"display_mode": "full_art", "updated_at": "library-slot-reuse"}}
	manager._override_texture_cache = {regular_source: _texture(Color.RED)}
	manager._refresh_portrait_node(portrait, true)
	var full_art_layer = group.get_node_or_null("CardArtFullArtLayer")
	if !(full_art_layer is TextureRect) or !full_art_layer.visible:
		_fail("The initial regular card did not enter custom full-art mode.")
		return

	# NCardLibrary first assigns the new model while the recycled slot can still
	# retain the previous card's full-art state and bootstrap metadata. Card Art
	# Editor must not apply the previous regular card's rarity to the new model.
	card_id.Entry = "NEOWS_FURY"
	model.PortraitPath = ancient_source
	model.Rarity = 5
	manager._refresh_portrait_node(portrait, true)

	if portrait.visible or !ancient_portrait.visible:
		_fail("Clearing the recycled slot restored the previous regular portrait state.")
		return
	if (card_root.get_node("Frame") as CanvasItem).visible or (card_root.get_node("TitleBanner") as CanvasItem).visible:
		_fail("A native Ancient card was restored inside the regular card frame.")
		return
	if !(card_root.get_node("AncientBorderGlassOverlay") as CanvasItem).visible or !(card_root.get_node("AncientBorder") as CanvasItem).visible:
		_fail("The native Ancient border layers were not preserved.")
		return
	if group.material == null:
		_fail("The native Ancient portrait mask was not restored.")
		return

	# The library can also expose a freshly assigned Ancient model through the
	# regular layout without carrying any previous custom full-art metadata.
	manager._manifest.clear()
	portrait.visible = true
	ancient_portrait.visible = false
	(card_root.get_node("PortraitBorder") as CanvasItem).visible = true
	(card_root.get_node("Frame") as CanvasItem).visible = true
	(card_root.get_node("TitleBanner") as CanvasItem).visible = true
	(card_root.get_node("AncientBorderGlassOverlay") as CanvasItem).visible = false
	(card_root.get_node("AncientBorder") as CanvasItem).visible = false
	(card_root.get_node("AncientTextBg") as CanvasItem).visible = false
	(card_root.get_node("AncientBanner") as CanvasItem).visible = false
	if !manager.apply_card_override_after_visual_update(card):
		_fail("The event-driven refresh did not repair a native Ancient layout mismatch.")
		return
	if portrait.visible or !ancient_portrait.visible or (card_root.get_node("Frame") as CanvasItem).visible:
		_fail("A native Ancient card remained inside the regular frame without stale full-art metadata.")
		return

	# The real C# bootstrap stamps CardRarity on NCard so GDScript does not have
	# to depend on enum conversion across the C#/GDScript boundary.
	model.Rarity = 2
	card.set_meta("_card_art_inspect_card_id", "NEOWS_FURY")
	card.set_meta("_card_art_model_rarity", 5)
	portrait.visible = true
	ancient_portrait.visible = false
	(card_root.get_node("Frame") as CanvasItem).visible = true
	if !manager.apply_card_override_after_visual_update(card):
		_fail("The strongly typed rarity stamp did not trigger Ancient layout synchronization.")
		return
	if portrait.visible or !ancient_portrait.visible or (card_root.get_node("Frame") as CanvasItem).visible:
		_fail("A C# Ancient rarity stamp was ignored in favor of an incompatible dynamic enum value.")
		return

	# Mixed character grids can perform one final pooled-slot visibility reset
	# after the immediate deferred refresh. The Ancient-only stabilization must
	# repair that late reset without enabling continuous portrait polling.
	manager.queue_card_override_refresh(card)
	_force_regular_layout.bind(card_root, portrait, ancient_portrait).call_deferred()
	await process_frame
	await process_frame
	await process_frame
	if portrait.visible or !ancient_portrait.visible or (card_root.get_node("Frame") as CanvasItem).visible:
		_fail("A late character-grid visibility reset escaped Ancient layout stabilization.")
		return

	# A category-wide full-art batch can leave an active layer on a pooled slot
	# while the slot becomes a native Ancient card. Native rarity must win even
	# when the stale layer was accidentally stamped with the new card ID.
	model.Rarity = 2
	model.PortraitPath = regular_source
	card_id.Entry = "STRIKE_IRONCLAD"
	card.set_meta("_card_art_inspect_card_id", "STRIKE_IRONCLAD")
	card.set_meta("_card_art_model_rarity", 2)
	manager._manifest = {regular_source: {"display_mode": "full_art", "updated_at": "stale-category-layer"}}
	manager._override_texture_cache = {regular_source: _texture(Color.RED)}
	_force_regular_layout(card_root, portrait, ancient_portrait)
	manager._refresh_portrait_node(portrait, true)
	full_art_layer = group.get_node_or_null("CardArtFullArtLayer")
	if !(full_art_layer is TextureRect) or !bool(full_art_layer.get_meta("_card_art_full_art_active", false)):
		_fail("The stale category layer setup did not enter full-art mode.")
		return
	card_id.Entry = "BREAK"
	model.PortraitPath = ancient_source
	model.Rarity = 5
	card.set_meta("_card_art_inspect_card_id", "BREAK")
	card.set_meta("_card_art_model_rarity", 5)
	full_art_layer.set_meta("_card_art_full_art_owner_card_id", "BREAK")
	_force_regular_layout(card_root, portrait, ancient_portrait)
	manager._refresh_visible_tracked_portraits(4)
	if portrait.visible or !ancient_portrait.visible or (card_root.get_node("Frame") as CanvasItem).visible:
		_fail("The visible grid refresh skipped a hidden native Ancient portrait.")
		return
	card.free()
	manager.free()
	print("Ancient card-library slot reuse regression passed.")
	quit()

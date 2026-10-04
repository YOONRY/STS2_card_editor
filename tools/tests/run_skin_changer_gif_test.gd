extends SceneTree

class TestCard extends Control:
	var model_token := 1

const SOURCE := "res://images/packed/card_portraits/ironclad/strike_ironclad.png"
const FULL_SOURCE := "res://images/packed/card_portraits/ironclad/corruption.png"
var _failures := 0
var _checks := 0


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if !condition:
		_failures += 1
		push_error(message)


func _initialize() -> void:
	_run.call_deferred()


func _card(texture: Texture2D, full_art: bool = false) -> TestCard:
	var card = TestCard.new()
	card.size = Vector2(200, 300)
	root.add_child(card)
	for node_name in ["Portrait", "AncientPortrait", "Frame"]:
		var target = TextureRect.new()
		target.name = node_name
		card.add_child(target)
		target.owner = card
		target.unique_name_in_owner = true
		target.visible = (node_name == "AncientPortrait") == full_art if node_name != "Frame" else !full_art
		target.texture = texture
		target.size = card.size
	var hitbox = Control.new()
	hitbox.name = "Hitbox"
	hitbox.size = card.size
	card.add_child(hitbox)
	return card


func _drain(player) -> void:
	for _tick in range(600):
		if player._jobs.is_empty():
			return
		player.process()
	_expect(false, "GIF jobs exceeded the bounded test budget.")


func _run() -> void:
	if !OS.get_environment("APPDATA").replace("\\", "/").contains("build/skin_changer_bridge_test_appdata"):
		push_error("Use the isolated build/skin_changer_bridge_test_appdata APPDATA directory.")
		quit(1)
		return
	var workspace = get_script().resource_path.get_base_dir().get_base_dir().get_base_dir()
	if !ProjectSettings.load_resource_pack("C:/Program Files (x86)/Steam/steamapps/common/Slay the Spire 2/SlayTheSpire2.pck") or !ProjectSettings.load_resource_pack(workspace.path_join("build/card_art_editor_mod/card_art_editor.pck")):
		quit(1)
		return
	var folder = ProjectSettings.globalize_path("user://skin_changer_gif_test")
	DirAccess.make_dir_recursive_absolute(folder)
	var frames: Array = []
	for index in range(3):
		var image = Image.create(16, 12, false, Image.FORMAT_RGBA8)
		image.fill([Color.RED, Color.GREEN, Color.BLUE][index])
		var path = folder.path_join("frame_%d.png" % index)
		_expect(image.save_png(path) == OK, "Fixture image could not be written.")
		frames.append(path)
	var dll = FileAccess.open(folder.path_join("Gurio.SkinChanger.dll"), FileAccess.WRITE)
	dll.store_8(0)
	dll = null
	var manager = load("res://mods/card_art_editor/card_art_override_manager.gd").new()
	root.add_child(manager)
	manager.set_process(false)
	manager.cancel_gif_preload()
	manager._manifest.clear()
	manager._gif_processing_settings["preload_enabled"] = false
	var entry = {"type": "animated_gif", "frame_paths": frames.duplicate(), "source_frame_paths": frames.duplicate(),
		"frame_delays": [0.1, 0.2, 0.3], "width": 16, "height": 12, "display_mode": "default"}
	manager._manifest[SOURCE] = entry
	manager._manifest[FULL_SOURCE] = entry.duplicate(true)
	manager._manifest[FULL_SOURCE]["display_mode"] = "full_art"
	_expect(manager.configure_skin_changer_bridge(folder, folder), "Could not activate GIF bridge.")
	var player = manager._skin_changer_gifs
	var fallback = ImageTexture.create_from_image(Image.load_from_file(frames[0]))
	manager.tag_skin_changer_gif_texture(SOURCE, fallback)
	var provider = fallback
	_expect(provider is ImageTexture and provider.get_meta(player.SOURCE_META) == SOURCE, "The cached static preview was replaced or not tagged.")
	_expect(player._jobs.is_empty(), "Skin Changer's static preloading eagerly queued GIF decoding.")
	_expect(player._assets[SOURCE]["index"] == 0, "First appearance synchronously decoded GIF frames.")
	_expect(manager._get_override_texture(SOURCE) == null, "GIF bridge re-enabled CAE's competing renderer.")
	# Native NCard.Model is a plain CLR CardModel, not a Godot property.
	var native_like_card: Control = _card(provider)
	native_like_card.set_script(null)
	_expect(native_like_card.get("Model") == null, "Native-card fixture exposes a script Model property.")
	_expect(manager.bind_skin_changer_gif_card(native_like_card, SOURCE, 100), "Native-card token was rejected.")
	_expect(native_like_card.get_node("%Portrait").texture is AnimatedTexture, "A native card with no GDScript Model property cannot bind its GIF.")
	native_like_card.free()
	player.process()
	_expect(player._jobs.is_empty() and player._assets[SOURCE]["index"] == 0, "A freed native-card fixture kept decoding.")
	var hidden_card = _card(provider)
	hidden_card.hide()
	manager.bind_skin_changer_gif_card(hidden_card, SOURCE, hidden_card.model_token)
	_expect(player._jobs.is_empty(), "A hidden card queued GIF decoding.")
	hidden_card.show()
	_expect(player._jobs.has(SOURCE), "A newly visible card did not demand its GIF.")
	hidden_card.hide()
	player.process()
	_expect(player._jobs.is_empty(), "Hidden cards continued on-demand decoding.")
	hidden_card.free()
	var atlas := AtlasTexture.new()
	atlas.atlas = provider
	atlas.region = Rect2(0, 0, 16, 12)
	var card_a = _card(atlas)
	var card_b = _card(atlas)
	var portrait_a = card_a.get_node("%Portrait")
	var portrait_b = card_b.get_node("%Portrait")
	manager.bind_skin_changer_gif_card(card_a, SOURCE, card_a.model_token)
	manager.bind_skin_changer_gif_card(card_b, SOURCE, card_b.model_token)
	var animated_a = portrait_a.texture.atlas
	var animated_b = portrait_b.texture.atlas
	_expect(animated_a is AnimatedTexture and animated_b is AnimatedTexture and animated_a != animated_b, "Card instances share pause/hover state.")
	_expect(portrait_a.texture.region == atlas.region, "Skin Changer's atlas clipping changed.")
	_expect(player._bindings.size() == 2, "Hidden Ancient portraits were also animated.")
	manager._begin_batch_updates()
	player.process()
	_expect(player._assets[SOURCE]["index"] == 0, "Frame decoding ran during an art rewrite.")
	manager._end_batch_updates()
	player.process()
	_expect(player._assets[SOURCE]["index"] == 1, "The frame decode budget is not one frame per tick.")
	_drain(player)
	_expect(animated_a.frames == 3 and animated_b.frames == 3, "Existing card textures did not gain the loaded animation.")
	_expect(animated_a.get_frame_texture(1) == animated_b.get_frame_texture(1), "Duplicate cards decoded duplicate image textures.")
	_expect(is_equal_approx(animated_a.get_frame_duration(1), 0.2), "Frame timing was lost.")
	_expect(!animated_a.pause, "Visible GIF did not start playing.")
	var observed_frames := {}
	for _tick in range(50):
		await create_timer(0.02).timeout
		RenderingServer.force_draw(false)
		observed_frames[animated_a.current_frame] = true
	_expect(observed_frames.size() > 1, "The engine did not advance the bound GIF playhead.")
	animated_a.current_frame = 1
	portrait_a.texture = atlas
	manager.bind_skin_changer_gif_card(card_a, SOURCE, card_a.model_token)
	_expect(portrait_a.texture.atlas == animated_a and animated_a.current_frame == 1, "Card visual refresh restarted the GIF or rebuilt its texture.")
	_expect(provider is ImageTexture and provider.get_image().get_pixel(0, 0) == Color.RED, "The static cache was mutated into animation frames.")
	_expect(card_a.get_node("Frame").visible and card_a.get_node("Frame").texture == atlas, "GIF binding touched the card frame.")
	manager.set_all_gif_hover_playback_only_enabled(true)
	card_a.get_node("Hitbox").mouse_exited.emit()
	card_b.get_node("Hitbox").mouse_exited.emit()
	_expect(animated_a.pause and animated_b.pause, "Hover-only setting was ignored.")
	card_a.get_node("Hitbox").mouse_entered.emit()
	_expect(!animated_a.pause and animated_b.pause, "Hovering one card animated another copy.")
	card_a.get_node("Hitbox").mouse_exited.emit()
	_expect(animated_a.pause and animated_a.current_frame == 0, "Leaving hover did not restore the first frame.")
	card_b.get_node("Hitbox").focus_entered.emit()
	_expect(!animated_b.pause, "Controller focus did not enable GIF playback.")
	card_b.hide()
	_expect(animated_b.pause, "Hidden card kept playing.")
	card_b.show()
	card_b.get_node("Hitbox").focus_exited.emit()
	manager.set_gif_hover_playback_only_enabled_for_source(SOURCE, false)
	_expect(!animated_a.pause, "Per-card hover setting did not update the bridge.")
	# Selection changes and pooled model reuse must never write the old GIF back.
	var other = ImageTexture.create_from_image(Image.load_from_file(frames[2]))
	portrait_a.texture = other
	_expect(!manager.bind_skin_changer_gif_card(card_a, "", card_a.model_token), "A different selected skin retained an active binding.")
	_expect(portrait_a.texture == other and animated_a.pause, "Switching skins was overwritten by the GIF player.")
	card_b.model_token = 2
	manager.bind_skin_changer_gif_card(card_b, FULL_SOURCE, card_b.model_token)
	_expect(animated_b.pause and player._bindings.is_empty(), "A pooled card retained another card's animation.")
	# The provider itself can be an AtlasTexture; never tag its shared backing
	# atlas or apply the atlas region a second time to individual GIF frames.
	var shared_atlas = ImageTexture.create_from_image(Image.load_from_file(frames[0]))
	var atlas_provider = AtlasTexture.new()
	atlas_provider.atlas = shared_atlas
	atlas_provider.region = Rect2(3, 2, 8, 6)
	manager.tag_skin_changer_gif_texture(SOURCE, atlas_provider)
	var atlas_card = _card(atlas_provider)
	_expect(manager.bind_skin_changer_gif_card(atlas_card, SOURCE, 101), "Tagged AtlasTexture did not bind.")
	var atlas_animation = atlas_card.get_node("%Portrait").texture
	_expect(atlas_animation is AnimatedTexture and atlas_animation.frames == 3, "Provider atlas cropping was incorrectly reapplied to GIF frames.")
	_expect(!shared_atlas.has_meta(player.SOURCE_META) and atlas_provider.atlas == shared_atlas, "GIF tagging contaminated a shared atlas.")
	var sibling = AtlasTexture.new()
	sibling.atlas = shared_atlas
	sibling.region = Rect2(0, 0, 3, 2)
	var sibling_card = _card(sibling)
	_expect(!manager.bind_skin_changer_gif_card(sibling_card, SOURCE, 102), "An untagged sibling region inherited another card's animation.")
	manager.release_skin_changer_gif_card(atlas_card)
	_expect(atlas_animation.pause and atlas_card.get_node("%Portrait").texture == atlas_provider, "Pool release failed to restore the static atlas preview.")
	_expect(!atlas_card.has_meta(player.MODEL_META), "Released card retained a model identity token.")
	_expect(!manager.bind_skin_changer_gif_card(atlas_card, SOURCE, 0), "Missing model identity was allowed to animate.")
	_expect(manager.bind_skin_changer_gif_card(atlas_card, SOURCE, 103), "Reused card failed to bind a new model token.")
	var reused_animation = atlas_card.get_node("%Portrait").texture
	atlas_card.set_meta(player.MODEL_META, 104)
	player.refresh_settings()
	_expect(reused_animation.pause and !player._bindings.has(atlas_card.get_node("%Portrait").get_instance_id()), "A mismatched model token retained playback.")
	_expect(atlas_card.get_node("%Portrait").texture == reused_animation, "Stale binding wrote its old fallback onto a different model.")
	atlas_card.free()
	sibling_card.free()
	var full_provider = ImageTexture.create_from_image(Image.load_from_file(frames[0]))
	manager.tag_skin_changer_gif_texture(FULL_SOURCE, full_provider)
	var full_card = _card(full_provider, true)
	manager.bind_skin_changer_gif_card(full_card, FULL_SOURCE, full_card.model_token)
	_drain(player)
	var full_animation = full_card.get_node("%AncientPortrait").texture
	_expect(full_animation is AnimatedTexture and full_animation.frames == 3, "Full-art/native Ancient portrait did not animate.")
	_expect(full_animation.get_frame_texture(0).get_size() == Vector2(manager.FULL_ART_TARGET_SIZE), "GIF full-art frame was not cropped to CAE dimensions.")
	_expect(!full_card.get_node("Frame").visible, "GIF playback restored a normal card frame.")
	manager._manifest.erase(FULL_SOURCE)
	player.synchronize_manifest()
	_expect(full_animation.pause and !player._assets.has(FULL_SOURCE), "Restoring a card retained its animation/job.")
	var reloaded_provider = ImageTexture.create_from_image(Image.load_from_file(frames[0]))
	manager.tag_skin_changer_gif_texture(SOURCE, reloaded_provider)
	portrait_a.texture = reloaded_provider
	manager.bind_skin_changer_gif_card(card_a, SOURCE, card_a.model_token)
	var reloaded_animation = portrait_a.texture
	_expect(reloaded_animation is AnimatedTexture and reloaded_animation.frames == 3 and player._jobs.is_empty(), "Cache eviction decoded the same GIF again.")
	reloaded_animation.current_frame = 2
	portrait_a.texture = provider
	manager.bind_skin_changer_gif_card(card_a, SOURCE, card_a.model_token)
	_expect(portrait_a.texture == reloaded_animation and reloaded_animation.current_frame == 2, "Multiple cached previews for one source lost the playhead.")
	# In-place edits invalidate cached frames even if the first frame is unchanged.
	manager._manifest[SOURCE]["frame_delays"] = [0.3, 0.4, 0.5]
	player.synchronize_manifest()
	portrait_a.texture = provider
	manager.bind_skin_changer_gif_card(card_a, SOURCE, card_a.model_token)
	_expect(portrait_a.texture == provider and player._bindings.is_empty(), "A stale generation was allowed to animate.")
	var updated = ImageTexture.create_from_image(Image.load_from_file(frames[0]))
	manager.tag_skin_changer_gif_texture(SOURCE, updated)
	portrait_a.texture = updated
	manager.bind_skin_changer_gif_card(card_a, SOURCE, card_a.model_token)
	_drain(player)
	_expect(is_equal_approx(portrait_a.texture.get_frame_duration(1), 0.4), "Changed GIF timing used an old cached animation.")
	manager._manifest[FULL_SOURCE] = entry.duplicate(true)
	manager._gif_processing_settings["preload_enabled"] = true
	manager.request_gif_preload(true, true)
	_expect(player._assets.has(FULL_SOURCE) and player._assets[FULL_SOURCE]["index"] == 0, "Preloading did not queue unseen applied GIFs.")
	_expect(is_instance_valid(player._progress), "Explicit preload did not open progress.")
	manager.cancel_gif_preload()
	_expect(!player._jobs.has(FULL_SOURCE), "Cancelled preload kept decoding unseen GIFs.")
	manager.request_gif_preload(true)
	_drain(player)
	_expect(player._assets[FULL_SOURCE]["loaded"].size() == 3, "Preload retry failed.")
	manager._manifest[FULL_SOURCE]["frame_paths"] = [folder.path_join("missing.png")]
	player.synchronize_manifest()
	_drain(player)
	_expect(manager._manifest.has(FULL_SOURCE) and player._assets[FULL_SOURCE]["failed"], "Failed GIF loading deleted art or retried forever.")
	# Enforce the same 256-frame ceiling and preserve whole-sequence duration.
	var long_entry = entry.duplicate(true)
	long_entry["frame_paths"] = []
	long_entry["frame_delays"] = []
	for index in range(300):
		long_entry["frame_paths"].append(frames[index % 3])
		long_entry["frame_delays"].append(0.1)
	manager._manifest[FULL_SOURCE] = long_entry
	player.synchronize_manifest()
	_drain(player)
	var long_frames = player._assets[FULL_SOURCE]["loaded"]
	var duration := 0.0
	for frame in long_frames:
		duration += frame["delay"]
	_expect(long_frames.size() == 256 and is_equal_approx(duration, 30.0), "Long GIF limit or duration changed.")
	portrait_a.texture = updated
	manager.bind_skin_changer_gif_card(card_a, SOURCE, card_a.model_token)
	card_a.free()
	_expect(player._bindings.is_empty(), "Freed card retained animation event subscriptions.")
	card_b.free()
	full_card.free()
	var final_card = _card(updated)
	manager.bind_skin_changer_gif_card(final_card, SOURCE, final_card.model_token)
	var final_animation = final_card.get_node("%Portrait").texture
	manager.free()
	_expect(player._bindings.is_empty() and final_animation.pause, "Manager shutdown retained GIF event bindings.")
	_expect(final_card.get_node("%Portrait").texture == updated, "Manager shutdown left its animation on a live card.")
	final_card.free()
	print("Skin Changer GIF regression: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)

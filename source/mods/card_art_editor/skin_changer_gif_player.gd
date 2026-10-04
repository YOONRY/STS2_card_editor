extends RefCounted

const SOURCE_META := "_cae_skin_changer_gif_source"
const GENERATION_META := "_cae_skin_changer_gif_generation"
const MODEL_META := "_cae_skin_changer_gif_model_token"
const PROGRESS = preload("res://mods/card_art_editor/gif_preload_progress.gd")

var _manager: WeakRef
var _assets: Dictionary = {}
var _jobs: Array = []
var _bindings: Dictionary = {}
var _dirty_bindings: Dictionary = {}
var _preload_cancelled := false
var _progress = null
var _generation := 0


func configure(manager: Node) -> void:
	_manager = weakref(manager)


func _asset(source: String) -> Dictionary:
	var manager = _manager.get_ref()
	var entry = manager._manifest.get(source, null)
	if !(entry is Dictionary) or !manager._is_animated_entry(entry):
		return {}
	if _assets.has(source) and _assets[source]["entry"] != entry:
		invalidate(source)
	if !_assets.has(source):
		var plan = manager._get_gif_frame_plan(entry)
		if plan.is_empty():
			return {}
		_generation += 1
		_assets[source] = {"source": source, "entry": entry.duplicate(true), "plan": plan,
			"generation": _generation, "loaded": [], "index": 0, "failed": false}
	return _assets[source]


func tag_texture(source: String, fallback: Texture2D) -> void:
	var asset = _asset(source)
	if asset.is_empty() or fallback == null:
		return
	# Skin Changer preloads static previews. Tagging must not decode GIFs or
	# replace its cached texture: only a visible card demands animation frames.
	fallback.set_meta(SOURCE_META, source)
	fallback.set_meta(GENERATION_META, asset["generation"])


func _queue(asset: Dictionary, urgent: bool = false) -> void:
	if int(asset["index"]) >= asset["plan"].size():
		return
	var source: String = asset["source"]
	if _jobs.has(source):
		if !urgent:
			return
		_jobs.erase(source)
	if urgent:
		_jobs.push_front(source)
	else:
		_jobs.append(source)


func request_preload(retry: bool = false, show_progress: bool = false) -> void:
	if retry:
		_preload_cancelled = false
		for source in _assets.keys():
			var asset: Dictionary = _assets[source]
			if asset["failed"]:
				asset["index"] = 0
				asset["loaded"] = []
				asset["failed"] = false
	if _preload_cancelled:
		return
	var manager = _manager.get_ref()
	for source in manager._manifest:
		var asset = _asset(source)
		if !asset.is_empty():
			_queue(asset)
	if show_progress:
		if !is_instance_valid(_progress):
			_progress = PROGRESS.new()
			_progress.cancelled.connect(cancel_preload)
			manager.add_child(_progress)
			_progress.show_estimate(manager.get_gif_preload_estimate())
		_update_progress()


func cancel_preload() -> void:
	_preload_cancelled = true
	for source in _jobs.duplicate():
		if !_has_visible_binding(source):
			_jobs.erase(source)
	if is_instance_valid(_progress):
		_progress.queue_free()
	_progress = null


func process() -> void:
	for id in _dirty_bindings.keys():
		if _bindings.has(id):
			_refresh_anchor(_bindings[id], id)
			_refresh_hover(_bindings[id])
		_update_playback(id)
	_dirty_bindings.clear()
	var manager = _manager.get_ref()
	if manager == null or manager._batch_update_depth > 0 or _jobs.is_empty():
		return
	var source: String = _jobs[0]
	if (_preload_cancelled or !bool(manager._gif_processing_settings.get("preload_enabled", false))) and !_has_visible_binding(source):
		_jobs.pop_front()
		_update_progress()
		return
	var asset: Dictionary = _assets[source]
	if manager._manifest.get(source, null) != asset["entry"]:
		invalidate(source)
		return
	var index: int = asset["index"]
	var frame: Dictionary = asset["plan"][index]
	# One frame per tick, even on demand: never synchronously decode a whole GIF.
	var texture = manager._load_gif_frame_texture(source, asset["entry"], frame)
	if texture is Texture2D:
		asset["loaded"].append({"texture": texture, "delay": frame["delay"]})
	else:
		asset["failed"] = true
	asset["index"] = index + 1
	if int(asset["index"]) == asset["plan"].size():
		_jobs.pop_front()
		for id in _bindings.keys():
			if _bindings[id]["source"] == source:
				_fill_animation(_bindings[id]["animation"], asset["loaded"])
				_update_playback(id)
	_update_progress(source)


func _fill_animation(animation: AnimatedTexture, frames: Array) -> void:
	animation.pause = true
	if frames.is_empty():
		return
	animation.frames = frames.size()
	for index in range(frames.size()):
		animation.set_frame_texture(index, frames[index]["texture"])
		animation.set_frame_duration(index, frames[index]["delay"])
	animation.current_frame = 0


func _update_progress(source: String = "") -> void:
	if !is_instance_valid(_progress):
		return
	var total := 0
	var loaded := 0
	var completed := 0
	var failed := 0
	for asset in _assets.values():
		total += asset["plan"].size()
		loaded += int(asset["index"])
		completed += int(int(asset["index"]) == asset["plan"].size())
		failed += int(bool(asset["failed"]))
	_progress.update_progress(loaded, total, completed, _assets.size(), source.get_file().get_basename())
	if _jobs.is_empty():
		_progress.finish(failed)


func _provider(texture):
	for _depth in range(5):
		if !(texture is Texture2D) or texture is AnimatedTexture:
			return null
		if texture.has_meta(SOURCE_META):
			var source = String(texture.get_meta(SOURCE_META))
			return texture if _assets.has(source) and _assets[source]["generation"] == texture.get_meta(GENERATION_META, -1) else null
		if !(texture is AtlasTexture):
			break
		texture = texture.atlas
	return null


func bind_card(card: Node, selected_source: String, model_token: int) -> bool:
	if card == null or !is_instance_valid(card):
		return false
	if model_token <= 0 or selected_source == "":
		release_card(card)
		return false
	# NCard.Model is not a Godot property. Identity is supplied by the C# hook;
	# its model/pool lifecycle hook releases bindings before card reuse.
	card.set_meta(MODEL_META, model_token)
	var bound := false
	for path in ["%Portrait", "%AncientPortrait"]:
		var target = card.get_node_or_null(path)
		if !(target is TextureRect):
			continue
		var id = target.get_instance_id()
		var previous: Dictionary = _bindings.get(id, {})
		if !target.visible:
			_release(id)
			continue
		if !previous.is_empty() and previous["source"] == selected_source and previous["model_token"] == model_token and target.texture == previous["texture"]:
			_refresh_anchor(previous, id)
			_update_playback(id)
			bound = true
			continue
		var provider = _provider(target.texture)
		if provider != null and String(provider.get_meta(SOURCE_META)) == selected_source and !previous.is_empty() and previous["source"] == selected_source and previous["model_token"] == model_token:
			# Visual refreshes reassign the provider; keep this card's playhead.
			# A new atlas wrapper may change the crop, so rebuild that binding.
			if target.texture is AtlasTexture and target.texture != previous["fallback"]:
				_release(id)
			else:
				previous["fallback"] = target.texture
				target.texture = previous["texture"]
				_refresh_anchor(previous, id)
				_update_playback(id)
				bound = true
				continue
		_release(id)
		if provider == null:
			continue
		var source = String(provider.get_meta(SOURCE_META))
		if source != selected_source:
			continue
		var asset: Dictionary = _assets[source]
		var animation := AnimatedTexture.new()
		animation.frames = 1
		animation.pause = true
		animation.set_meta(SOURCE_META, source)
		animation.set_meta(GENERATION_META, asset["generation"])
		animation.set_frame_texture(0, provider)
		_fill_animation(animation, asset["loaded"] if int(asset["index"]) == asset["plan"].size() else [])
		var fallback: Texture2D = target.texture
		var displayed: Texture2D = animation
		if fallback is AtlasTexture:
			displayed = _wrap_animation(fallback, provider, animation)
		var binding = {"source": source, "target": weakref(target), "card": weakref(card),
			"model_token": model_token, "anchor": null,
			"fallback": fallback, "texture": displayed, "animation": animation,
			"hovered": false, "focused": false, "connections": []}
		_bindings[id] = binding
		target.texture = displayed
		_refresh_anchor(binding, id)
		_update_playback(id)
		bound = true
	return bound


func _wrap_animation(texture: Texture2D, provider: Texture2D, animation: AnimatedTexture) -> Texture2D:
	if texture == provider:
		return animation
	if texture is AtlasTexture:
		var wrapper = texture.duplicate()
		wrapper.atlas = _wrap_animation(texture.atlas, provider, animation)
		return wrapper
	return animation


func _refresh_anchor(binding: Dictionary, id: int) -> void:
	var card = binding["card"].get_ref()
	var target = binding["target"].get_ref()
	if card == null or target == null:
		return
	var anchor = _manager.get_ref()._get_card_hover_anchor_control(card)
	var previous = binding["anchor"].get_ref() if binding["anchor"] != null else null
	if anchor == previous and !binding["connections"].is_empty():
		return
	_disconnect(binding)
	binding["anchor"] = weakref(anchor) if anchor != null else null
	binding["focused"] = false
	_connect(binding, target, "visibility_changed", Callable(self, "_visibility_changed").bind(id))
	_connect(binding, card, "tree_exiting", Callable(self, "_release").bind(id))
	if anchor is Control:
		_connect(binding, anchor, "mouse_entered", Callable(self, "_set_activity").bind(id, "hovered", true))
		_connect(binding, anchor, "mouse_exited", Callable(self, "_set_activity").bind(id, "hovered", false))
		_connect(binding, anchor, "focus_entered", Callable(self, "_set_activity").bind(id, "focused", true))
		_connect(binding, anchor, "focus_exited", Callable(self, "_set_activity").bind(id, "focused", false))
		_connect(binding, anchor, "item_rect_changed", Callable(self, "_queue_hover_refresh").bind(id))
		binding["focused"] = anchor.has_focus()
	_refresh_hover(binding)


func _disconnect(binding: Dictionary) -> void:
	for connection in binding["connections"]:
		var node = connection[0].get_ref()
		if node != null and node.is_connected(connection[1], connection[2]):
			node.disconnect(connection[1], connection[2])
	binding["connections"].clear()


func _connect(binding: Dictionary, node: Node, signal_name: String, callback: Callable) -> void:
	node.connect(signal_name, callback)
	binding["connections"].append([weakref(node), signal_name, callback])


func release_card(card: Node) -> void:
	for path in ["%Portrait", "%AncientPortrait"]:
		var target = card.get_node_or_null(path)
		if target != null:
			_release(target.get_instance_id())
	if card.has_meta(MODEL_META):
		card.remove_meta(MODEL_META)


func _release(id: int) -> void:
	var binding: Dictionary = _bindings.get(id, {})
	if binding.is_empty():
		return
	_bindings.erase(id)
	_dirty_bindings.erase(id)
	binding["animation"].pause = true
	var target = binding["target"].get_ref()
	var card = binding["card"].get_ref()
	if target != null and target.texture == binding["texture"] and card != null and card.get_meta(MODEL_META, 0) == binding["model_token"]:
		# Never restore over an image that Skin Changer has already replaced.
		target.texture = binding["fallback"]
	_disconnect(binding)


func _set_activity(id: int, key: String, active: bool) -> void:
	if _bindings.has(id):
		_bindings[id][key] = active
		_update_playback(id)


func _visibility_changed(id: int) -> void:
	if _bindings.has(id):
		_dirty_bindings[id] = true
		_refresh_hover(_bindings[id])
		_update_playback(id)


func _queue_hover_refresh(id: int) -> void:
	if _bindings.has(id):
		_dirty_bindings[id] = true
		_refresh_hover(_bindings[id])


func _refresh_hover(binding: Dictionary) -> void:
	var anchor = binding["anchor"].get_ref() if binding["anchor"] != null else null
	if !(anchor is Control) or !anchor.is_inside_tree():
		binding["hovered"] = false
		return
	var hovered = anchor.get_viewport().gui_get_hovered_control()
	binding["hovered"] = hovered != null and (hovered == anchor or anchor.is_ancestor_of(hovered))


func _update_playback(id: int) -> void:
	var binding: Dictionary = _bindings.get(id, {})
	if binding.is_empty():
		return
	var target = binding["target"].get_ref()
	var card = binding["card"].get_ref()
	if target == null or card == null or card.get_meta(MODEL_META, 0) != binding["model_token"] or target.texture != binding["texture"]:
		_release(id)
		return
	var manager = _manager.get_ref()
	var active = target.is_visible_in_tree() and card.is_visible_in_tree()
	if active and _assets.has(binding["source"]):
		_queue(_assets[binding["source"]], true)
	if active and manager.is_gif_hover_playback_only_enabled_for_source(binding["source"]):
		active = binding["hovered"] or binding["focused"] or manager._is_card_root_inside_visible_inspect_screen(card)
	binding["animation"].pause = !active
	if !active:
		binding["animation"].current_frame = 0


func _has_visible_binding(source: String) -> bool:
	for binding in _bindings.values():
		if binding["source"] != source:
			continue
		var target = binding["target"].get_ref()
		if target != null and target.is_visible_in_tree() and target.texture == binding["texture"]:
			return true
	return false


func dispose() -> void:
	for id in _bindings.keys():
		_release(id)
	cancel_preload()
	_jobs.clear()
	_assets.clear()


func refresh_settings() -> void:
	for id in _bindings.keys():
		_update_playback(id)


func invalidate(source: String) -> void:
	for id in _bindings.keys():
		if _bindings[id]["source"] == source:
			_release(id)
	_jobs.erase(source)
	_assets.erase(source)


func synchronize_manifest() -> void:
	var manager = _manager.get_ref()
	for source in _assets.keys():
		if manager._manifest.get(source, null) != _assets[source]["entry"]:
			invalidate(source)
	if bool(manager._gif_processing_settings.get("preload_enabled", false)):
		request_preload()

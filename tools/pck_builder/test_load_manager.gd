extends SceneTree

func _init() -> void:
	var script = load("res://mods/card_art_editor/card_art_override_manager.gd")
	if script == null:
		print("Manager script load failed: null")
		quit(1)
		return
	print("Manager script class: %s" % [script.get_class()])
	var instance = script.new()
	if instance == null:
		print("Manager instance is null")
		quit(2)
		return
	print("Manager instance class: %s" % [instance.get_class()])
	print("Manager is Node: %s" % [str(instance is Node)])
	quit()

extends SceneTree
func _initialize() -> void:
	var art:=load("res://world/Scripts/Lab3D/models.gd")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://world/Models/Lab3D"))
	for kind in ["nico","wolf","largato","urso","jose","oliver","technician","mutant","lizard","guardian","cherry","drone","syringe","terminal_heat","terminal_cold","injector","lever","crate","tank","egg","flag","wagon","keycard"]:
		var model:Node3D
		if kind=="guardian":model=art.guardian()
		elif kind in ["nico","wolf","largato","urso","jose","oliver","technician","mutant","lizard"]:model=art.character(kind)
		else:model=art.prop(kind)
		_own(model,model)
		var scene:=PackedScene.new();var packed:=scene.pack(model)
		if packed!=OK or ResourceSaver.save(scene,"res://world/Models/Lab3D/"+kind+".tscn")!=OK:printerr("MODEL_SAVE_FAILED ",kind);quit(1);return
		print("MODEL_3D_SAVED ",kind," nodes=",model.find_children("*","",true,false).size());model.free()
	var expansion:=load("res://world/Scripts/Lab3D/expansion_models.gd")
	for kind in ["power_cell","power_socket","thermal_relay","piston_bridge","ventilation_fan","security_scanner","archive_console","blast_gate","cargo_cart","specimen_tree"]:
		var model:Node3D=expansion.make(kind,art)
		_own(model,model)
		var scene:=PackedScene.new();var packed:=scene.pack(model)
		if packed!=OK or ResourceSaver.save(scene,"res://world/Models/Lab3D/"+kind+".tscn")!=OK:printerr("MODEL_SAVE_FAILED ",kind);quit(1);return
		print("MODEL_3D_SAVED ",kind," nodes=",model.find_children("*","",true,false).size());model.free()
	var precision:=load("res://world/Scripts/Lab3D/precision_props.gd")
	for kind in ["supply_crate","bounce_crate"]:
		var model:Node3D=precision.crate(kind=="bounce_crate");_own(model,model)
		var scene:=PackedScene.new()
		if scene.pack(model)!=OK or ResourceSaver.save(scene,"res://world/Models/Lab3D/"+kind+".tscn")!=OK:printerr("MODEL_SAVE_FAILED ",kind);quit(1);return
		print("MODEL_3D_SAVED ",kind);model.free()
	var puzzles:=load("res://world/Scripts/Lab3D/puzzle_models.gd")
	for kind in ["card_dispenser","puzzle_plate","spin_fuse"]:
		var model:Node3D=puzzles.make(kind);_own(model,model)
		var scene:=PackedScene.new()
		if scene.pack(model)!=OK or ResourceSaver.save(scene,"res://world/Models/Lab3D/"+kind+".tscn")!=OK:printerr("MODEL_SAVE_FAILED ",kind);quit(1);return
		print("MODEL_3D_SAVED ",kind);model.free()
	print("MODELS_3D_COMPLETE 38");quit()
func _own(node:Node,root_node:Node) -> void:
	for child in node.get_children():child.owner=root_node;_own(child,root_node)

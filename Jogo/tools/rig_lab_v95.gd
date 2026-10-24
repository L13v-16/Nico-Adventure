extends SceneTree
## Rebuild the playable, skinned derivatives without altering the supplied GLBs.
const DIR:="res://world/Models/ImportedV95/"
const Motion=preload("res://world/Scripts/Lab3D/lab_antagonist_motion.gd")
var statistics:Dictionary={}
func _initialize() -> void:run.call_deferred()
func run() -> void:
	for kind in ["wolf","largato"]:build(kind)
	var file:=FileAccess.open(DIR+"rig-report.json",FileAccess.WRITE);file.store_string(JSON.stringify(statistics,"\t"));file.close()
	print("LAB_V95_RIGS_COMPLETE ",JSON.stringify(statistics));quit()

func build(kind:String) -> void:
	var source:Node3D=load((DIR if kind=="wolf" else "res://world/Models/ImportedV81/")+kind+"_source.glb").instantiate();root.add_child(source)
	var original:MeshInstance3D=source.find_children("*","MeshInstance3D",true,false)[0]
	var original_mesh:ArrayMesh=original.mesh
	var arrays:Array=original_mesh.surface_get_arrays(0)
	var importer:=ImporterMesh.new()
	importer.add_surface(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},original_mesh.surface_get_material(0))
	importer.generate_lods(60.0,60.0,[])
	var chosen:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	var lods:=[]
	for i in importer.get_surface_lod_count(0):
		var indices:PackedInt32Array=importer.get_surface_lod_indices(0,i);lods.append(indices.size()/3)
		# Keep the finest generated LOD below 65k triangles: silhouette and UV seams
		# remain the imported mesh's own vertices, not averaged texture coordinates.
		if chosen.size()/3>65000:chosen=indices
	var map:Dictionary={};var order:Array[int]=[];var remapped:=PackedInt32Array()
	for index in chosen:
		if not map.has(index):map[index]=order.size();order.append(index)
		remapped.append(map[index])
	var vertices:=PackedVector3Array();var normals:=PackedVector3Array();var uv:=PackedVector2Array();var tangents:=PackedFloat32Array()
	var transform:Transform3D=original.global_transform
	var bounds:AABB=transform*original_mesh.get_aabb()
	var target_height:=2.38 if kind=="wolf" else 2.24
	var factor:float=target_height/bounds.size.y
	var anchor:=Vector3(0,bounds.position.y,.35) if kind=="wolf" else Vector3(.035,bounds.position.y,.30)
	var rotation:=Basis(Vector3.UP,PI)
	for old_index in order:
		vertices.append(rotation*((transform*arrays[Mesh.ARRAY_VERTEX][old_index]-anchor)*factor))
		normals.append((rotation*transform.basis.inverse().transposed()*arrays[Mesh.ARRAY_NORMAL][old_index]).normalized())
		if arrays[Mesh.ARRAY_TEX_UV]!=null:uv.append(arrays[Mesh.ARRAY_TEX_UV][old_index])
		if arrays[Mesh.ARRAY_TANGENT]!=null:
			var t:Vector3=rotation*Vector3(arrays[Mesh.ARRAY_TANGENT][old_index*4],arrays[Mesh.ARRAY_TANGENT][old_index*4+1],arrays[Mesh.ARRAY_TANGENT][old_index*4+2])
			tangents.append_array(PackedFloat32Array([t.x,t.y,t.z,arrays[Mesh.ARRAY_TANGENT][old_index*4+3]]))
	var actor:=Node3D.new();actor.name=kind.capitalize();actor.set_meta("model_kind",kind);actor.set_meta("meshy_rig",true);actor.set_meta("model_revision",95)
	var rig:=Node3D.new();rig.name="Rig";actor.add_child(rig);rig.owner=actor
	var skeleton:=Skeleton3D.new();skeleton.name="Skeleton3D";rig.add_child(skeleton);skeleton.owner=actor
	var bones:Array=Motion.bones(kind,target_height)
	var skin:=Skin.new()
	for i in bones.size():
		var bone:Dictionary=bones[i];skeleton.add_bone(bone.name)
		if bone.parent>=0:skeleton.set_bone_parent(i,bone.parent)
		var relative:Vector3=bone.at-(bones[bone.parent].at if bone.parent>=0 else Vector3.ZERO)
		skeleton.set_bone_rest(i,Transform3D(Basis.IDENTITY,relative))
		skin.add_bind(i,Transform3D(Basis.IDENTITY,-bone.at))
	skeleton.reset_bone_poses()
	var material:StandardMaterial3D=original_mesh.surface_get_material(0).duplicate(true)
	var color_map:Image=material.albedo_texture.get_image()
	if color_map.is_compressed():color_map.decompress()
	var weights:=PackedFloat32Array();var joints:=PackedInt32Array()
	for vertex_index in vertices.size():
		var vertex:Vector3=vertices[vertex_index]
		var p:Vector3=vertex/target_height
		var texcoord:Vector2=uv[vertex_index]*Vector2(material.uv1_scale.x,material.uv1_scale.y)+Vector2(material.uv1_offset.x,material.uv1_offset.y)
		var color:Color=color_map.get_pixel(clampi(int(fposmod(texcoord.x,1)*color_map.get_width()),0,color_map.get_width()-1),clampi(int(fposmod(texcoord.y,1)*color_map.get_height()),0,color_map.get_height()-1))
		var influences:Dictionary=Motion.weights(kind,p,color)
		var ids:Array=influences.keys();ids.sort_custom(func(a,b):return influences[a]>influences[b])
		var total:=0.0
		for i in mini(4,ids.size()):total+=float(influences[ids[i]])
		for i in 4:
			joints.append(int(ids[i]) if i<ids.size() else 0)
			weights.append(float(influences[ids[i]])/total if i<ids.size() else 0.0)
	var output:Array=[];output.resize(Mesh.ARRAY_MAX)
	output[Mesh.ARRAY_VERTEX]=vertices;output[Mesh.ARRAY_NORMAL]=normals;output[Mesh.ARRAY_INDEX]=remapped
	output[Mesh.ARRAY_BONES]=joints;output[Mesh.ARRAY_WEIGHTS]=weights
	if not uv.is_empty():output[Mesh.ARRAY_TEX_UV]=uv
	if not tangents.is_empty():output[Mesh.ARRAY_TANGENT]=tangents
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,output)
	material.roughness=.82;material.metallic=0
	# Textures extracted by the importer are regular project resources. Keep
	# these references rather than bundling the GLB's internal subresource IDs.
	mesh.surface_set_material(0,material)
	assert(ResourceSaver.save(mesh,DIR+kind+"_skin.res",ResourceSaver.FLAG_COMPRESS)==OK)
	var display:=MeshInstance3D.new();display.name="CharacterMesh";display.mesh=load(DIR+kind+"_skin.res");display.skin=skin;display.skeleton=NodePath("..");display.custom_aabb=AABB(Vector3(-2,-.4,-2),Vector3(4,4,4));skeleton.add_child(display);display.owner=actor
	var player:=AnimationPlayer.new();player.name="Animations";actor.add_child(player);player.owner=actor
	player.add_animation_library("",Motion.library(kind,bones));player.autoplay="idle";player.playback_default_blend_time=.12
	var packed:=PackedScene.new();assert(packed.pack(actor)==OK);assert(ResourceSaver.save(packed,DIR+kind+".tscn")==OK)
	statistics[kind]={"source_vertices":arrays[Mesh.ARRAY_VERTEX].size(),"source_triangles":arrays[Mesh.ARRAY_INDEX].size()/3,"lod_triangles":lods,"vertices":vertices.size(),"triangles":remapped.size()/3,"bones":bones.size(),"height":target_height,"animations":player.get_animation_list(),"bounds_position":str(mesh.get_aabb().position),"bounds_size":str(mesh.get_aabb().size)}
	actor.free();source.queue_free()

extends SceneTree
## Rebuild the two supplied NPC models. Original GLBs are never rewritten.
## Run after importing: Godot --headless --path . --script res://tools/rig_friend_models.gd
const DIR:="res://world/Models/ImportedV83/"
const NAMES:=["Root","Hips","Spine","Head","ArmL","ForearmL","HandL","ArmR","ForearmR","HandR","LegL","ShinL","FootL","LegR","ShinR","FootR","Tail","TailTip"]
var statistics:Dictionary={}
func _initialize() -> void:run.call_deferred()
func run() -> void:
	for kind in ["oliver","urso"]:build(kind)
	var file:=FileAccess.open(DIR+"rig-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(statistics,"\t"));file.close()
	print("FRIEND_RIGS_COMPLETE ",JSON.stringify(statistics));quit()

func build(kind:String) -> void:
	var source:Node3D=load(DIR+kind+"_source.glb").instantiate();root.add_child(source)
	var instances:Array=source.find_children("*","MeshInstance3D",true,false)
	assert(instances.size()==1,"Expected one supplied source mesh")
	var original:MeshInstance3D=instances[0]
	var original_mesh:ArrayMesh=original.mesh
	assert(original_mesh.get_surface_count()==1,"Expected one supplied material")
	var arrays:Array=original_mesh.surface_get_arrays(0)
	var importer:=ImporterMesh.new()
	importer.add_surface(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},original_mesh.surface_get_material(0))
	importer.generate_lods(60.0,60.0,[])
	var chosen:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	var lods:=[]
	for i in importer.get_surface_lod_count(0):
		var indices:PackedInt32Array=importer.get_surface_lod_indices(0,i)
		lods.append(indices.size()/3)
		# Select original vertices, preserving the source UV seams and normals.
		if chosen.size()/3>65000:chosen=indices
	var remap:Dictionary={};var order:Array[int]=[];var remapped:=PackedInt32Array()
	for index in chosen:
		if not remap.has(index):remap[index]=order.size();order.append(index)
		remapped.append(remap[index])
	var vertices:=PackedVector3Array();var normals:=PackedVector3Array();var uv:=PackedVector2Array();var tangents:=PackedFloat32Array()
	var transform:Transform3D=original.global_transform
	var bounds:AABB=transform*original_mesh.get_aabb()
	var target_height:=2.1 if kind=="oliver" else 2.4
	var factor:float=target_height/bounds.size.y
	# Anchor under the standing feet, not the middle of Oliver's long tail.
	var anchor:=Vector3(0,bounds.position.y,.10 if kind=="oliver" else -.04)
	var rotation:=Basis(Vector3.UP,PI)
	var normal_transform:Basis=rotation*transform.basis.inverse().transposed()
	for old_index in order:
		vertices.append(rotation*((transform*arrays[Mesh.ARRAY_VERTEX][old_index]-anchor)*factor))
		normals.append((normal_transform*arrays[Mesh.ARRAY_NORMAL][old_index]).normalized())
		if arrays[Mesh.ARRAY_TEX_UV]!=null:uv.append(arrays[Mesh.ARRAY_TEX_UV][old_index])
		if arrays[Mesh.ARRAY_TANGENT]!=null:
			var tangent:Vector3=(normal_transform*Vector3(arrays[Mesh.ARRAY_TANGENT][old_index*4],arrays[Mesh.ARRAY_TANGENT][old_index*4+1],arrays[Mesh.ARRAY_TANGENT][old_index*4+2])).normalized()
			tangents.append_array(PackedFloat32Array([tangent.x,tangent.y,tangent.z,arrays[Mesh.ARRAY_TANGENT][old_index*4+3]]))
	var actor:=Node3D.new();actor.name=kind.capitalize()
	actor.set_meta("model_kind",kind);actor.set_meta("meshy_rig",true);actor.set_meta("friend_model_revision",83)
	var rig:=Node3D.new();rig.name="Rig";actor.add_child(rig);rig.owner=actor
	var skeleton:=Skeleton3D.new();skeleton.name="Skeleton3D";rig.add_child(skeleton);skeleton.owner=actor
	var bones:Array=bone_data(kind,target_height)
	var skin:=Skin.new()
	for i in bones.size():
		var bone:Dictionary=bones[i];skeleton.add_bone(bone.name)
		if bone.parent>=0:skeleton.set_bone_parent(i,bone.parent)
		var relative:Vector3=bone.at-(bones[bone.parent].at if bone.parent>=0 else Vector3.ZERO)
		skeleton.set_bone_rest(i,Transform3D(Basis.IDENTITY,relative))
		skin.add_bind(i,Transform3D(Basis.IDENTITY,-bone.at))
	skeleton.reset_bone_poses()
	var material:StandardMaterial3D=original_mesh.surface_get_material(0).duplicate(true)
	var weights:=PackedFloat32Array();var joints:=PackedInt32Array()
	for vertex in vertices:
		var influences:Dictionary=vertex_weights(kind,vertex/target_height)
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
	# Matte response suits the existing laboratory lighting. All three supplied
	# texture maps and their original UV scale/offset remain on the material.
	material.roughness=.82;material.metallic=0
	mesh.surface_set_material(0,material)
	assert(ResourceSaver.save(mesh,DIR+kind+"_skin.res",ResourceSaver.FLAG_COMPRESS)==OK)
	var display:=MeshInstance3D.new();display.name="CharacterMesh";display.mesh=load(DIR+kind+"_skin.res")
	display.skin=skin;display.skeleton=NodePath("..");display.custom_aabb=AABB(Vector3(-2.3,-.15,-2),Vector3(4.6,4,4.6))
	skeleton.add_child(display);display.owner=actor
	var player:=AnimationPlayer.new();player.name="Animations";actor.add_child(player);player.owner=actor
	player.add_animation_library("",animation_library(kind));player.autoplay="idle";player.playback_default_blend_time=.16
	var packed:=PackedScene.new();assert(packed.pack(actor)==OK);assert(ResourceSaver.save(packed,DIR+kind+".tscn")==OK)
	var normalized_bounds:AABB=mesh.get_aabb()
	statistics[kind]={"source_vertices":arrays[Mesh.ARRAY_VERTEX].size(),"source_triangles":arrays[Mesh.ARRAY_INDEX].size()/3,"lod_triangles":lods,"vertices":vertices.size(),"triangles":remapped.size()/3,"bones":bones.size(),"height":target_height,"front":"-Z","foot_y":0,"anchor_source":str(anchor),"bounds_position":str(normalized_bounds.position),"bounds_size":str(normalized_bounds.size),"animations":player.get_animation_list()}
	actor.free();source.queue_free()

static func bone_data(kind:String,h:float) -> Array:
	var points:=[Vector3.ZERO,Vector3(0,.19,0),Vector3(0,.34,0),Vector3(0,.49,-.04),Vector3(-.19,.35,-.02),Vector3(-.22,.27,-.02),Vector3(-.22,.22,-.03),Vector3(.19,.35,-.02),Vector3(.22,.27,-.02),Vector3(.22,.22,-.03),Vector3(-.11,.18,0),Vector3(-.11,.10,-.01),Vector3(-.11,.035,-.045),Vector3(.11,.18,0),Vector3(.11,.10,-.01),Vector3(.11,.035,-.045),Vector3(0,.22,.16),Vector3(-.10,.25,.40)]
	if kind=="urso":
		points[3]=Vector3(0,.49,-.04)
		points[4]=Vector3(-.22,.38,-.01);points[5]=Vector3(-.25,.29,-.02);points[6]=Vector3(-.25,.23,-.03)
		points[7]=Vector3(.22,.38,-.01);points[8]=Vector3(.25,.29,-.02);points[9]=Vector3(.25,.23,-.03)
		points[16]=Vector3(0,.22,.24);points[17]=Vector3(0,.23,.35)
	var parents:=[-1,0,1,2,2,4,5,2,7,8,1,10,11,1,13,14,1,16]
	var result:=[]
	for i in NAMES.size():result.append({"name":NAMES[i],"parent":parents[i],"at":points[i]*h})
	return result

static func vertex_weights(kind:String,p:Vector3) -> Dictionary:
	var head:float=smoothstep(.45,.55,p.y)
	var tail:=0.0
	if kind=="oliver":tail=smoothstep(.20,.34,p.z)*(1-smoothstep(.36,.45,p.y))*smoothstep(.09,.16,p.y)
	# The arms are tucked against the original body. Small blended motions keep
	# the jacket/fur from tearing at their fused shoulder and belly seams.
	var arm:float=smoothstep(.15,.21,absf(p.x))*smoothstep(.15,.22,p.y)*(1-smoothstep(.37,.45,p.y))*(1-smoothstep(.16,.25,p.z))*(1-head)*(1-tail)
	if kind=="urso":arm=smoothstep(.20,.26,absf(p.x))*smoothstep(.14,.23,p.y)*(1-smoothstep(.41,.49,p.y))*(1-smoothstep(.10,.18,p.z))*(1-head)
	var leg:float=(1-smoothstep(.14,.22,p.y))*(1-tail)*(1-arm)
	var spine:float=smoothstep(.20,.34,p.y)*(1-head)*(1-tail)*(1-arm)*(1-leg)
	var w:Dictionary={1:maxf(.001,1-head-tail-arm-leg-spine)}
	if spine>0:w[2]=spine
	if head>0:w[3]=head
	if tail>0:
		var tip:float=smoothstep(.33,.46,p.z)
		w[16]=tail*(1-tip);w[17]=tail*tip
	if arm>0:
		var upper:int=4 if p.x<0 else 7
		var elbow:float=1-smoothstep(.25,.34,p.y)
		w[upper]=arm*(1-elbow);w[upper+1]=arm*elbow*.7;w[upper+2]=arm*elbow*.3
	if leg>0:
		var hip:int=10 if p.x<0 else 13
		var knee:float=1-smoothstep(.06,.12,p.y)
		w[hip]=leg*(1-knee);w[hip+1]=leg*knee*.7;w[hip+2]=leg*knee*.3
	return w

static func animation_library(kind:String) -> AnimationLibrary:
	var lib:=AnimationLibrary.new()
	for action in ["RESET","idle","talk","celebrate","run","operate","hurt","jump","attack","tail"]:
		var animation:=Animation.new()
		animation.length=.8 if action=="run" else (.55 if action in ["hurt","jump","attack"] else 2.4)
		animation.loop_mode=Animation.LOOP_LINEAR if action in ["idle","talk","celebrate","run","operate"] else Animation.LOOP_NONE
		for bone in NAMES:
			var track:=animation.add_track(Animation.TYPE_ROTATION_3D)
			animation.track_set_path(track,NodePath("Rig/Skeleton3D:"+bone))
			animation.track_set_interpolation_type(track,Animation.INTERPOLATION_CUBIC)
			for key in 25:
				var t:=float(key)/24
				animation.track_insert_key(track,t*animation.length,Quaternion.from_euler(pose(kind,action,bone,t)))
		# Feet stay fixed at y=0. Breathing only stretches the upper body .3%.
		var breathing:=animation.add_track(Animation.TYPE_SCALE_3D)
		animation.track_set_path(breathing,NodePath("Rig/Skeleton3D:Spine"))
		for key in 25:
			var t:=float(key)/24
			animation.track_insert_key(breathing,t*animation.length,Vector3(1,1+(1-cos(t*TAU))*.0015 if action in ["idle","talk"] else 1,1))
		lib.add_animation(action,animation)
	return lib

static func pose(kind:String,action:String,bone:String,t:float) -> Vector3:
	var r:=Vector3.ZERO
	if action=="RESET":return r
	var wave:=sin(t*TAU);var pulse:=sin(t*PI);var side:float=-1 if bone.ends_with("L") else 1
	if bone=="Head":r.z=wave*.012
	if bone=="Tail" and kind=="oliver":r.y=wave*.045
	if bone=="TailTip" and kind=="oliver":r.y=sin(t*TAU+.4)*.035
	if action in ["talk","operate"]:
		if bone=="Head":r.x=wave*.035;r.y=sin(t*TAU)*.025
		elif bone.begins_with("Arm"):r.x=wave*.035;r.z=side*(1-cos(t*TAU))*.012
		elif bone=="Spine":r.y=wave*.008
	elif action=="celebrate":
		if bone.begins_with("Arm"):r.x=(1-cos(t*TAU))*.045;r.z=side*(1-cos(t*TAU))*.035
		elif bone=="Head":r.x=wave*.045;r.z=wave*.025
		elif bone=="Spine":r.x=wave*.012
	elif action=="run":
		if bone.begins_with("Leg"):r.x=wave*side*.16
		elif bone.begins_with("Shin"):r.x=maxf(0,-wave*side)*-.12
		elif bone.begins_with("Arm"):r.x=-wave*side*.075
		elif bone=="Head":r.z=wave*.018
	elif action=="hurt":
		if bone=="Spine":r.x=pulse*.05
		elif bone=="Head":r.x=-pulse*.06
	elif action in ["jump","attack"]:
		if bone.begins_with("Arm"):r.x=pulse*.08;r.z=side*pulse*.05
		elif bone=="Head":r.x=-pulse*.025
	elif action=="tail" and kind=="oliver":
		if bone=="Tail":r.y=pulse*.12
		elif bone=="TailTip":r.y=pulse*.08
	return r

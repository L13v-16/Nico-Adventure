extends RefCounted
const Art=preload("res://world/Scripts/general_art.gd")
## Small noncolliding details, placed against the real terrain after sync.
const POINTS={
	"fase_1":[Vector2(120,48),Vector2(310,48),Vector2(485,48),Vector2(780,48),Vector2(1040,48),Vector2(1370,48),Vector2(1670,48),Vector2(1980,48)],
	"fase_2":[Vector2(180,64),Vector2(390,64),Vector2(650,64),Vector2(980,64),Vector2(1320,64),Vector2(1690,64),Vector2(2280,64),Vector2(2390,64)],
	"fase_3":[Vector2(580,100),Vector2(900,-64),Vector2(1120,-64),Vector2(1470,64),Vector2(1780,64),Vector2(2350,64),Vector2(3220,32),Vector2(3960,-112)],
	"fase_4":[Vector2(580,100),Vector2(850,100),Vector2(1420,100),Vector2(1930,100),Vector2(2700,36),Vector2(2920,36),Vector2(5550,100),Vector2(6250,100)],
	"fase_6":[Vector2(430,100),Vector2(970,100),Vector2(2390,-70),Vector2(2810,-250),Vector2(4320,100),Vector2(4930,100),Vector2(6580,100),Vector2(7070,30)]}
static func install(level:Node2D) -> void:
	if not POINTS.has(level.level_id):return
	await level.get_tree().physics_frame
	if not is_instance_valid(level):return
	var id:String=level.level_id;var theme:String={"fase_1":"forest","fase_2":"beach","fase_3":"magic","fase_4":"underworld","fase_6":"industrial"}[id]
	var root:=Node2D.new();root.name="GeneralDetails90";root.z_index=-1;level.add_child(root)
	for i in 8:
		var hint:Vector2=POINTS[id][i]
		var ray:=PhysicsRayQueryParameters2D.create(hint+Vector2(0,-55),hint+Vector2(0,100),1)
		var hit:=level.get_world_2d().direct_space_state.intersect_ray(ray)
		if hit.is_empty() or hit.normal.y>-.7:continue
		var prop:=Sprite2D.new();prop.name=theme+str(i);prop.texture=Art.cell(theme,i);prop.centered=false;prop.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;prop.material=Art.material()
		var width:float=[28,42,30,30,26,26,24,38][i]
		if theme=="industrial":width=24
		var ratio:=minf(width/prop.texture.get_width(),32.0/prop.texture.get_height())
		prop.scale=Vector2.ONE*ratio;prop.position=hit.position+Vector2(-prop.texture.get_width()*ratio/2,-prop.texture.get_height()*ratio+2)
		prop.set_meta("ground_surface",hit.position);prop.set_meta("theme",theme);prop.set_meta("index",i);prop.add_to_group("general_details90");root.add_child(prop)
static func install_lab(level:Node3D) -> void:
	# Flat signs belong on walls in the 3D level; they are not fake 3D crates.
	for room in 3:
		for i in 4:
			var index:int=[3,4,5,7][i];var side:float=-1 if i%2 else 1
			var panel:=Sprite3D.new();panel.name="General90Wall"+str(i);panel.texture=Art.cell("industrial",index);panel.pixel_size=2.0/panel.texture.get_width();panel.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST;panel.shaded=false;panel.double_sided=false;panel.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD;panel.alpha_scissor_threshold=.78
			panel.position=Vector3(side*10.10,2.7,-12-i/2*16);panel.rotation.y=-side*PI/2
			panel.set_meta("index",index);panel.add_to_group("general_details90");level.sectors[room].add_child(panel)

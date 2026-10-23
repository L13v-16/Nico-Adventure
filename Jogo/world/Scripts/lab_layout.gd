extends RefCounted
# Legacy IDs are retained even though their physical route has been redesigned.
const GROUND:=[Vector3(-128,100,1228),Vector3(1228,100,1132),Vector3(2490,100,970),Vector3(3680,100,1320),Vector3(5128,100,2472)]
const ARENA_Y:=-1290.0
const SECRETS:=[Vector2(950,-150),Vector2(1650,-880),Vector2(4640,-1360)]
# Walkable shelves, in the order in which the player discovers them.
const SHELVES:=[Vector3(-128,100,1178),Vector3(760,-80,270),Vector3(470,-260,290),Vector3(430,-330,330),Vector3(1500,-330,340),Vector3(2140,-330,440),Vector3(1920,-525,310),Vector3(1540,-745,440),Vector3(1510,-810,300),Vector3(3650,-810,1120),Vector3(4050,-990,270),Vector3(3650,-1180,520),Vector3(4230,-1290,510),Vector3(5480,ARENA_Y,2120)]
static func build(level:Node2D) -> void:
	var terrain:=Node2D.new();terrain.name="Level";level.add_child(terrain)
	for i in SHELVES.size():
		var s:Vector3=SHELVES[i];var variant:=0 if i<4 else (1 if i<9 else (2 if i<13 else 3))
		ground(terrain,Vector2(s.x,s.y),s.z,100 if i in [0,4,5,9,13] else 18,i not in [0,4,5,9,13],variant)
	for s in [Vector3(6400,ARENA_Y-64,120),Vector3(6780,ARENA_Y-64,120)]:ground(terrain,Vector2(s.x,s.y),s.z,18,true,3)
	var boss:=preload("res://world/Scripts/largato_boss.gd").new();boss.name="Boss";boss.position=Vector2(6770,ARENA_Y);level.add_child(boss)
	# First room: safe elevators and a card, without combat or a wall of crates.
	lift(level,Vector2(700,100),180);lift(level,Vector2(850,-80),180)
	device(level,"card",Vector2(950,-80),24)
	device(level,"gate",Vector2(600,-330),100)
	device(level,"gate",Vector2(1550,-330),100)
	# Second room: one isolated poison gap, then practice on a single enemy.
	var pool:Node2D=level.spawn_pool(Vector2(1990,-330),"toxic",-1,300);pool.name="TeachingPoison"
	lift(level,Vector2(2300,-330),195);lift(level,Vector2(2110,-525),220)
	device(level,"gate",Vector2(1730,-810),100)
	var first:Node2D=level.spawn_enemy(Vector2(2030,-525),"specimen");first.patrol_width=90
	var second:Node2D=level.spawn_enemy(Vector2(1860,-745),"lizard");second.patrol_width=80
	wall_sign(level,Vector2(1770,-370),0);wall_sign(level,Vector2(2175,-370),1)
	# Third room: circuit, then press, then an optional sensor guarding cherries.
	device(level,"gate",Vector2(3700,-810),100)
	device(level,"lever",Vector2(3870,-810),48,"C")
	device(level,"conveyor",Vector2(4070,-810),170,"C")
	lift(level,Vector2(4400,-810),180,"C",false)
	device(level,"press",Vector2(4130,-990),86)
	lift(level,Vector2(4070,-990),190);lift(level,Vector2(4150,-1180),110)
	device(level,"camera",Vector2(3790,-1180),42)
	device(level,"gate",Vector2(4540,-1290),100)
	var tech:Node2D=level.spawn_enemy(Vector2(4430,-1290),"technician");tech.patrol_width=70
	wall_sign(level,Vector2(3880,-865),2);wall_sign(level,Vector2(4160,-1040),3);wall_sign(level,Vector2(3710,-1225),1)
	# Research is on the highest floor. Machinery belongs to the boss arena.
	device(level,"gate",Vector2(5530,ARENA_Y),100)
	device(level,"record",Vector2(5770,ARENA_Y),40)
	var drone:Node2D=level.spawn_enemy(Vector2(5930,ARENA_Y-60),"drone");drone.patrol_width=90
	for info in [["heat",6280,66,"LabHeat"],["injector",6370,90,"LabInjector"],["cold",6900,66,"LabCold"],["rescue",7180,132,"UrsoChamber"]]:
		var node:Node2D=device(level,info[0],Vector2(info[1],ARENA_Y),info[2]);node.name=info[3]
	device(level,"mover",Vector2(6500,ARENA_Y),95,"arena")
	for at in [Vector2(350,100),Vector2(950,-80),Vector2(520,-330),Vector2(1630,-330),Vector2(2430,-330),Vector2(1630,-810),Vector2(3790,-810),Vector2(4240,-990),Vector2(4630,-1290),Vector2(6080,ARENA_Y)]:preload("res://world/Scripts/magic_layout.gd")._checkpoint(level.get_node("Checkpoints"),at)
	var caravan:=preload("res://prefabs/caravan_shop.tscn").instantiate();caravan.position=Vector2(50,100);caravan.travel_offset=Vector2(4,0);level.add_child(caravan)
	cherries(level)
	level.get_node("Finish").position=Vector2(7480,ARENA_Y-38);level.finish_floor_y=ARENA_Y
static func device(level:Node2D,kind:String,at:Vector2,width:float,circuit:String="") -> Node2D:
	var node:=preload("res://world/Scripts/lab_device.gd").new();node.kind=kind;node.position=at;node.width=width;node.circuit=circuit
	# Names must exist before _ready, because terminal sprites inspect Boss state.
	if kind in ["heat","cold","injector","rescue"]:node.name={"heat":"LabHeat","cold":"LabCold","injector":"LabInjector","rescue":"UrsoChamber"}[kind]
	level.add_child(node);return node
static func lift(level:Node2D,at:Vector2,rise:float,circuit:String="",enabled:bool=true) -> void:
	var node:=preload("res://world/Scripts/lab_lift.gd").new();node.position=at;node.rise=rise;node.circuit=circuit;node.enabled=enabled;level.add_child(node)
static func wall_sign(level:Node2D,at:Vector2,index:int) -> void:
	var node:=Sprite2D.new();node.texture=load("res://world/Arte/Lab/V72/sign_%02d.tres"%index);node.centered=false;node.z_index=-2
	node.material=preload("res://world/Scripts/magic_art.gd").material();node.material.set_shader_parameter("alpha_cutoff",.94)
	var ratio:=38.0/float(node.texture.get_meta("visible_width",200));node.scale=Vector2.ONE*ratio;node.position=at-Vector2(node.texture.get_width()*.5,float(node.texture.get_meta("surface_y",300)))*ratio
	level.add_child(node)
static func cherries(level:Node2D) -> void:
	var ids:Array[String]=[]
	for s in GROUND:
		for x in range(int(s.x+95),int(s.x+s.z-60),95):
			if x>=490 and x<=6020:ids.append("lab:floor:%d"%x)
	for i in 3:
		for j in 4:ids.append("lab:bonus:%d:%d"%[i,j])
	var trails:=[Vector3(470,590,100),Vector3(780,990,-80),Vector3(490,710,-260),Vector3(1600,1780,-330),Vector3(2180,2470,-330),Vector3(1940,2200,-525),Vector3(1570,1770,-745),Vector3(3900,4230,-810),Vector3(4060,4300,-990),Vector3(3680,3940,-1180),Vector3(4290,4690,-1290),Vector3(5630,6000,ARENA_Y)]
	var per_trail:=ceili(float(ids.size())/trails.size());var scene:=preload("res://prefabs/item.tscn")
	for i in ids.size():
		var trail:Vector3=trails[mini(i/per_trail,trails.size()-1)];var slot:=i%per_trail
		var node:=scene.instantiate();node.cherry_id=ids[i];node.position=Vector2(lerpf(trail.x,trail.y,float(slot)/maxi(1,per_trail-1)),trail.z-15);level.get_node("items").add_child(node)
static func ground(parent:Node,at:Vector2,width:float,depth:float,one_way:bool,variant:int) -> void:
	var floor:=preload("res://world/Scripts/lab_terrain.gd").new();floor.position=at;floor.width=width;floor.depth=depth;floor.platform=one_way;floor.variant=variant;parent.add_child(floor)

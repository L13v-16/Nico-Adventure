extends RefCounted
const NAMES:=["Saguão Executivo","Torre Administrativa","Complexo de Armamentos","Centro de Controle","Cobertura · O Robô Gigante"]
const BOUNDS:=[Rect2(0,-200,1450,520),Rect2(2000,-670,1400,990),Rect2(4000,-230,1500,550),Rect2(6000,-240,1500,560),Rect2(8100,-420,1400,740)]
const LANDINGS:=[Vector2(180,89),Vector2(2100,89),Vector2(4100,89),Vector2(6120,89),Vector2(8350,89)]
static func build(level:Node2D) -> void:
	var terrain:=Node2D.new();terrain.name="Level";level.add_child(terrain)
	for i in 5:
		floor_at(level,Vector2(i*2000,100),1450 if i!=1 else 500,100,false)
	# Broad shelves sit beside the lift at both endpoints; no pixel-perfect jumps.
	for s in [Vector3(2220,-70,330),Vector3(2550,-250,380),Vector3(2880,-430,460)]:floor_at(level,Vector2(s.x,s.y),s.z,20,true)
	lift(level,Vector2(2310,100),170);lift(level,Vector2(2660,-70),180);lift(level,Vector2(3000,-250),180)
	for s in [Vector3(650,30,230),Vector3(4460,35,220),Vector3(4740,-25,230),Vector3(6520,30,240),Vector3(6860,30,230)]:floor_at(level,Vector2(s.x,s.y),s.z,16,true)
	# Reception: one camera, a nearby off switch, then a shield guard.
	device(level,0,"camera",Vector2(500,-25),38)
	device(level,0,"security",Vector2(355,100),40)
	device(level,0,"security",Vector2(1200,100),40)
	device(level,0,"record",Vector2(780,30),36,"forest")
	device(level,0,"secret",Vector2(1090,100),40)
	enemy(level,0,0,Vector2(870,100))
	device(level,0,"door",Vector2(1360,100),60,"",1)
	# Exterior climb: windows break with the same basic attack as early islands.
	device(level,1,"glass",Vector2(2460,-70),35)
	device(level,1,"record",Vector2(2770,-250),36,"underworld")
	device(level,1,"door",Vector2(3260,-430),60,"",2)
	enemy(level,1,1,Vector2(2780,-325))
	# Weapon factory: reversing conveyors moves the robot arm into a safe bridge.
	device(level,2,"lever",Vector2(4220,100),38,"factory")
	device(level,2,"conveyor",Vector2(4400,100),180,"factory")
	device(level,2,"press",Vector2(4570,100),75)
	device(level,2,"reactor_fire",Vector2(4730,100),42,"factory")
	device(level,2,"reactor_ice",Vector2(4850,100),42,"factory")
	device(level,2,"turret",Vector2(5070,-15),38)
	device(level,2,"record",Vector2(4810,-25),36,"lab")
	device(level,2,"door",Vector2(5400,100),60,"",3)
	enemy(level,2,2,Vector2(5100,100))
	# Control room must be crossed in both directions after the lockdown.
	device(level,3,"door",Vector2(6075,100),60,"",2)
	device(level,3,"camera",Vector2(6410,-30),38)
	device(level,3,"security",Vector2(6270,100),40)
	device(level,3,"prototype",Vector2(6660,20),36,"prototype")
	device(level,3,"office",Vector2(7000,20),38,"office")
	device(level,3,"lockdown",Vector2(7310,100),48)
	device(level,3,"press",Vector2(6810,100),70)
	enemy(level,3,3,Vector2(7010,100))
	var silhouette:=preload("res://world/Scripts/Corp2D/art.gd").sprite("robot",0,170,2)
	silhouette.position+=Vector2(7100,-45);silhouette.modulate=Color(.16,.23,.32,.6);silhouette.z_index=-3;level.add_child(silhouette)
	# Final arena: the controls sit on the floor and can be reached from safety.
	device(level,4,"reactor_fire",Vector2(8550,100),45,"boss")
	device(level,4,"reactor_ice",Vector2(9150,100),45,"boss")
	var boss:=preload("res://world/Scripts/Corp2D/boss.gd").new();boss.name="Boss";boss.level=level;boss.position=Vector2(8870,100);level.add_child(boss)
	for at in [Vector2(300,100),Vector2(1150,100),Vector2(2310,-70),Vector2(2700,-250),Vector2(3150,-430),Vector2(4190,100),Vector2(4940,100),Vector2(6140,100),Vector2(7180,100),Vector2(8350,100)]:preload("res://world/Scripts/magic_layout.gd")._checkpoint(level.get_node("Checkpoints"),at)
	var caravan:=preload("res://prefabs/caravan_shop.tscn").instantiate();caravan.position=Vector2(160,100);caravan.travel_offset=Vector2(4,0);level.add_child(caravan)
	# Every cherry belongs to a shelf within standing/jump reach.
	var trails:=[Vector3(400,1120,100),Vector3(2250,2490,-70),Vector3(2590,2870,-250),Vector3(3060,3190,-430),Vector3(4150,4500,100),Vector3(4770,4850,-25),Vector3(4910,5290,100),Vector3(6170,7280,100)]
	var index:=0
	for trail in trails:
		for x in range(int(trail.x),int(trail.y),75):
			var item:=preload("res://prefabs/item.tscn").instantiate();item.position=Vector2(x,trail.z-17);item.cherry_id="corp:%03d"%index;index+=1;level.get_node("items").add_child(item)
	level.get_node("Finish").position=Vector2(9470,65)
	for data in [[0,650,"SUA SEGURANÇA É NOSSA 17ª PRIORIDADE"],[2,4400,"INOVAÇÃO EXIGE VÍTIMAS · DIGO, METAS"],[3,6650,"A FAMÍLIA CORPORATIVA VEM PRIMEIRO"]]:
		var label:=Label.new();label.text=data[2];label.position=Vector2(int(data[0])*2000+int(data[1])%2000-100,-60);label.add_theme_font_size_override("font_size",8);label.modulate=Color("bdad8a");label.z_index=-1;level.add_child(label)
static func floor_at(level:Node2D,at:Vector2,width:float,depth:float,platform:bool) -> Node2D:
	var node:=preload("res://world/Scripts/Corp2D/terrain.gd").new();node.position=at;node.width=width;node.depth=depth;node.platform=platform;node.variant=1 if platform else 0;level.get_node("Level").add_child(node);return node
static func lift(level:Node2D,at:Vector2,rise:float) -> void:
	var node:=preload("res://world/Scripts/Corp2D/lift.gd").new();node.position=at;node.rise=rise;node.width=136;level.add_child(node)
static func device(level:Node2D,sector:int,kind:String,at:Vector2,width:float,link:String="",destination:int=-1) -> Node2D:
	var node:=preload("res://world/Scripts/Corp2D/device.gd").new();node.level=level;node.sector=sector;node.kind=kind;node.position=at;node.width=width;node.link=link;node.destination=destination;level.add_child(node);return node
static func enemy(level:Node2D,sector:int,species:int,at:Vector2) -> Node2D:
	var node:=preload("res://world/Scripts/Corp2D/enemy.gd").new();node.level=level;node.sector=sector;node.species=species;node.position=at;level.add_child(node);return node

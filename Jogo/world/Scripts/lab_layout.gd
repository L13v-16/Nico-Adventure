extends RefCounted
const GROUND:=[Vector3(-128,100,1228),Vector3(1228,100,1132),Vector3(2490,100,970),Vector3(3680,100,1320),Vector3(5128,100,2472)]
static func build(level:Node2D) -> void:
	var backdrop:=preload("res://world/Scripts/lab_backdrop.gd").new();backdrop.name="LabBackdrop";level.add_child(backdrop)
	for gap in [Vector2(1100,128),Vector2(2360,130),Vector2(3460,220),Vector2(5000,128)]:
		var void_mask:=Polygon2D.new();void_mask.z_index=-10;void_mask.color=Color("14212b")
		void_mask.polygon=PackedVector2Array([Vector2(gap.x,100),Vector2(gap.x+gap.y,100),Vector2(gap.x+gap.y,430),Vector2(gap.x,430)]);level.add_child(void_mask)
	var terrain:=Node2D.new();terrain.name="Level";level.add_child(terrain)
	for info in GROUND:ground(terrain,Vector2(info.x,info.y),info.z,256,false,clampi(int(maxf(0,info.x)/1536),0,3))
	for info in [Vector3(1020,28,100),Vector3(2670,-40,150),Vector3(3250,-15,130),Vector3(4780,5,135),Vector3(6400,12,120),Vector3(6780,12,120)]:ground(terrain,Vector2(info.x,info.y),info.z,18,true,1)
	var boss:=preload("res://world/Scripts/largato_boss.gd").new();boss.name="Boss";boss.position=Vector2(6770,100);level.add_child(boss)
	for info in [["conveyor",350,220,"A"],["cover",620,68,""],["camera",680,55,"A"],["card",790,38,""],["lever",900,48,"A"],["laser",1000,55,"A"],["gate",1430,100,""],["tank",1720,112,""],["lever",1810,48,"B"],["conveyor",1915,190,"B"],["tank",2180,108,""],["mover",2420,94,"B"],["lever",3000,48,"C"],["press",3135,110,"C"],["mover",3540,100,"C"],["conveyor",4070,240,"D"],["press",4275,115,"D"],["lever",4400,48,"D"],["camera",4500,55,"D"],["record",4720,62,""],["gate",5400,100,""],["tank",5580,112,""],["record",5820,62,""],["heat",6280,66,""],["injector",6370,90,""],["mover",6500,95,"arena"],["cold",6900,66,""],["rescue",7180,132,""]]:
		var device:=preload("res://world/Scripts/lab_device.gd").new();device.kind=info[0];device.position=Vector2(info[1],100);device.width=info[2];device.circuit=info[3]
		if device.kind=="injector":device.name="LabInjector"
		elif device.kind=="heat":device.name="LabHeat"
		elif device.kind=="cold":device.name="LabCold"
		elif device.kind=="rescue":device.name="UrsoChamber"
		if device.kind=="conveyor" and device.position.x>1500:device.reversed=true
		level.add_child(device)
	for info in [[2090,"toxic",112],[2425,"toxic",130],[2710,"bounce",100],[3340,"slip",112],[4630,"toxic",132],[5055,"toxic",145],[5700,"slip",108]]:level.spawn_pool(Vector2(info[0],100),info[1],-1,info[2])
	for info in [[1040,"technician"],[1560,"specimen"],[2010,"drone"],[2890,"lizard"],[3310,"technician"],[3840,"specimen"],[4180,"drone"],[4550,"lizard"],[5310,"technician"],[5790,"lizard"]]:level.spawn_enemy(Vector2(info[0],35 if info[1]=="drone" else 100),info[1])
	for x in [260,1030,1510,2250,2930,3370,3970,4880,5500,6080]:preload("res://world/Scripts/magic_layout.gd")._checkpoint(level.get_node("Checkpoints"),Vector2(x,100))
	var caravan:=preload("res://prefabs/caravan_shop.tscn").instantiate();caravan.position=Vector2(400,100);caravan.travel_offset=Vector2(4,0);level.add_child(caravan)
	var item_scene:=preload("res://prefabs/item.tscn")
	for info in GROUND:
		for x in range(int(info.x+95),int(info.x+info.z-60),95):
			if x<490 or x>6020:continue
			var item:=item_scene.instantiate();item.cherry_id="lab:floor:%d"%x;item.position=Vector2(x,68);level.get_node("items").add_child(item)
	for i in 3:
		for j in 4:
			var item:=item_scene.instantiate();item.cherry_id="lab:bonus:%d:%d"%[i,j];item.position=Vector2([1040,2690,4790][i]+j*26,[-1,-68,-23][i]);level.get_node("items").add_child(item)
static func ground(parent:Node,at:Vector2,width:float,depth:float,one_way:bool,variant:int) -> void:
	var floor:=preload("res://world/Scripts/lab_terrain.gd").new();floor.position=at;floor.width=width;floor.depth=depth;floor.platform=one_way;floor.variant=variant;parent.add_child(floor)

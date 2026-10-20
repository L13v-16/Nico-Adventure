extends RefCounted
## Coordenadas editáveis: x, topo, largura. Os props usam sempre o topo físico.
const Art := preload("res://world/Scripts/magic_art.gd")
const GROUND := [
	Vector3(-128,100,960), Vector3(832,-64,336), Vector3(1392,64,448),
	Vector3(2144,64,432), Vector3(3040,32,544), Vector3(3696,-112,432),
	Vector3(4496,64,1760),
]
const CHECKPOINTS := [Vector2(450,100),Vector2(1050,-64),Vector2(1510,64),Vector2(2240,64),Vector2(3130,32),Vector2(3890,-112),Vector2(4550,64),Vector2(5050,64)]
const SPRINGS := [Vector2(650,100),Vector2(2460,64),Vector2(3500,32),Vector2(5210,12),Vector2(5830,12)]
const VINES := [
	{"name":"CanopyVine","at":Vector2(1280,-272),"length":194.0},
	{"name":"PlantVine","at":Vector2(2056,-200),"length":200.0,"offset":Vector2(-112,0)},
	{"name":"WanderingVine","at":Vector2(2776,-218),"length":230.0,"travel":72.0},
	{"name":"LastVine","at":Vector2(4330,-360),"length":238.0,"offset":Vector2(-70,0)},
]

static func build(level: Node2D) -> void:
	var terrain:=Node2D.new()
	terrain.name="Level"
	level.add_child(terrain)
	for info in GROUND:
		var island:=preload("res://world/Scripts/magic_terrain.gd").new()
		island.position=Vector2(info.x,info.y)
		island.width=info.z
		terrain.add_child(island)
	var scenery:=Node2D.new()
	scenery.name="Scenery"
	scenery.z_index=-1
	level.add_child(scenery)
	var trees:=[Vector2(50,100),Vector2(365,100),Vector2(960,-64),Vector2(1550,64),Vector2(1720,64),Vector2(2240,64),Vector2(3120,32),Vector2(3370,32),Vector2(3790,-112),Vector2(4620,64),Vector2(4960,64),Vector2(5990,64),Vector2(6190,64)]
	for i in trees.size():
		var tree_width:=160.0+(i%3)*16
		var surface:Vector2=trees[i]
		for island in GROUND:
			if is_equal_approx(surface.y,island.y) and surface.x>=island.x and surface.x<=island.x+island.z:
				surface.x=clampf(surface.x,island.x+tree_width*0.5+2,island.x+island.z-tree_width*0.5-2)
				break
		var tree:=Art.planted_tree(StringName("tree%d"%(i%4)),tree_width,surface)
		tree.name="MagicTree%02d"%i
		scenery.add_child(tree)
	for info in GROUND:
		for i in range(1,int(info.z/96)):
			var decor_x:float=info.x+i*96+16
			if absf(decor_x-160)<56 or (decor_x>5184 and decor_x<5900) or (decor_x>6032 and decor_x<6160):continue
			var prop:=Art.prop(&"crystal" if i%3==0 else &"mushrooms",26+i%3*5)
			prop.position+=Vector2(info.x+i*96+16,info.y)
			scenery.add_child(prop)
	for info in VINES:
		var vine:=preload("res://world/Scripts/living_vine.gd").new()
		vine.name=info.name
		vine.position=info.at
		vine.length=info.length
		vine.automatic_travel=float(info.get("travel",0))
		vine.plant_offset=info.get("offset",Vector2.ZERO)
		level.add_child(vine)
	for point in [Vector2(1740,64),Vector2(3990,-112)]:
		var plant:=preload("res://world/Scripts/vine_plant.gd").new()
		plant.position=point
		plant.vine_paths=[NodePath("../PlantVine" if point.x<2000 else "../LastVine")]
		level.add_child(plant)
	for point in SPRINGS:
		var spring:=preload("res://world/Scripts/spring_mushroom.gd").new()
		spring.position=point
		if point.x>5000:spring.launch_speed=610
		level.add_child(spring)
	for point in CHECKPOINTS:_checkpoint(level.get_node("Checkpoints"),point)
	var enemy_spots:=[Vector3(380,100,170),Vector3(1580,64,150),Vector3(2300,64,170),Vector3(3280,32,150),Vector3(4650,64,140)]
	for info in enemy_spots:
		var enemy:=preload("res://world/Scripts/magic_enemy.gd").new()
		enemy.position=Vector2(info.x,info.y)
		enemy.patrol_width=info.z
		level.add_child(enemy)
	for point in [Vector2(1630,-35),Vector2(2390,-55),Vector2(3410,-58),Vector2(3960,-190),Vector2(4760,-40)]:
		var moth:=preload("res://world/Scripts/magic_enemy.gd").new()
		moth.species="moth"
		moth.position=point
		moth.phase=point.x/100
		moth.patrol_width=100
		level.add_child(moth)
	var item_scene:=preload("res://prefabs/item.tscn")
	for info in GROUND:
		for x in range(int(info.x+64),int(info.x+info.z-32),64):
			if x<140 or x>5080:continue
			var item:=item_scene.instantiate()
			item.cherry_id="ground:%d:%d"%[int(info.x),x]
			item.position=Vector2(x,info.y-25)
			level.get_node("items").add_child(item)
	for point in [Vector2(850,-180),Vector2(920,-220),Vector2(1000,-190),Vector2(3590,-175),Vector2(3670,-190)]:
		var item:=item_scene.instantiate()
		item.cherry_id="bonus:%d:%d"%[int(point.x),int(point.y)]
		item.position=point
		level.get_node("items").add_child(item)
	for info in VINES:
		var vine=level.get_node(String(info.name))
		var angles:=[-0.72,-0.36,0.0,0.36,0.72]
		for index in angles.size():
			var a:float=angles[index]
			var item:=item_scene.instantiate()
			item.cherry_id="vine:"+String(info.name)+":"+str(index)
			level.get_node("items").add_child(item)
			vine.add_path_cherry(item,a)
	var ring:=preload("res://world/Scripts/hyena_ring.gd").new()
	ring.name="HyenaRing"
	ring.position=Vector2(5184,64)
	level.add_child(ring)
	var boss:=preload("res://world/Scripts/hyena_boss.gd").new()
	boss.name="Boss"
	boss.z_index=3
	boss.position=Vector2(5616,64)
	level.add_child(boss)
	var caravan:=preload("res://prefabs/caravan_shop.tscn").instantiate()
	caravan.position=Vector2(4880,64)
	caravan.travel_offset=Vector2(12,0)
	level.add_child(caravan)
	for point in [Vector2(2340,30),Vector2(5030,30)]:
		var acai:=preload("res://world/Scripts/acai_power.gd").new()
		acai.position=point
		level.add_child(acai)
	var cage:=preload("res://world/Scripts/rescue_cage.gd").new()
	cage.name="RescueCage"
	cage.position=Vector2(6096,64)
	cage.guardian_name="HIENA HaHa"
	cage.collision_layer=5
	cage.collision_mask=0
	var collider:=CollisionShape2D.new()
	collider.name="CollisionShape2D"
	var shape:=RectangleShape2D.new()
	shape.size=Vector2(70,54)
	collider.shape=shape
	collider.position.y=-26
	cage.add_child(collider)
	var remi:=Art.actor(preload("res://world/Arte/Magic/remi.tres"),32)
	remi.name="Remi"
	remi.material.set_shader_parameter("alpha_cutoff",0.94)
	Art.reanchor(remi)
	remi.z_index=-1
	remi.play(&"idle")
	cage.add_child(remi)
	level.add_child(cage)
	var arara:=Art.actor(preload("res://world/Arte/Amigos/arara_minas.tres"),64)
	arara.name="AraraMinas"
	arara.position+=Vector2(160,100)
	arara.play(&"idle")
	scenery.add_child(arara)

static func _checkpoint(parent: Node, point: Vector2) -> void:
	var checkpoint:=preload("res://world/Scripts/checkpoint.gd").new()
	checkpoint.position=point
	checkpoint.collision_layer=0
	checkpoint.collision_mask=2
	var collider:=CollisionShape2D.new()
	var shape:=RectangleShape2D.new()
	shape.size=Vector2(40,48)
	collider.shape=shape
	collider.position=Vector2(8,-24)
	checkpoint.add_child(collider)
	var spawn:=Marker2D.new()
	spawn.name="Spawn"
	spawn.position=Vector2(0,-18)
	checkpoint.add_child(spawn)
	var flag:=AnimatedSprite2D.new()
	flag.name="FlagSprite"
	flag.position=Vector2(-10,-46)
	flag.centered=false
	checkpoint.add_child(flag)
	parent.add_child(checkpoint)

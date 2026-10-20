extends RefCounted
const Art=preload("res://world/Scripts/underworld_art.gd")
const Terrain=preload("res://world/Scripts/underworld_terrain.gd")
const GROUND:=[Vector3(-128,100,1032),Vector3(1320,100,880),Vector3(2540,36,640),Vector3(3376,-40,400),Vector3(3904,100,1040),Vector3(5200,100,704),Vector3(6144,100,1888)]
static func build(level:Node2D) -> void:
	var terrain:=Node2D.new()
	terrain.name="Level"
	level.add_child(terrain)
	for info in GROUND:_ground(terrain,Vector2(info.x,info.y),info.z,440,false)
	_ground(terrain,Vector2(-80,-154),176,14,true)
	_ground(terrain,Vector2(6590,28),110,14,true)
	_ground(terrain,Vector2(6740,-62),110,14,true)
	_ground(terrain,Vector2(6895,-160),500,18,true)
	var scenery:=Node2D.new()
	scenery.name="Scenery"
	scenery.z_index=-1
	level.add_child(scenery)
	var cannon:=Art.actor("scenery",142)
	cannon.name="CorporateCannon"
	cannon.position+=Vector2(27,-152)
	cannon.play(&"cannon_idle")
	scenery.add_child(cannon)
	var cage:=Art.actor("scenery",80)
	cage.position+=Vector2(250,104)
	cage.play(&"cage")
	scenery.add_child(cage)
	var temple:=Art.actor("scenery",210)
	temple.name="Temple"
	temple.position+=Vector2(3555,-36)
	temple.play(&"temple_ready" if Save.has_story_flag("elemental_mastery") else &"temple_dormant")
	scenery.add_child(temple)
	for info in GROUND:
		for x in range(int(info.x+70),int(info.x+info.z-40),180):
			if x<350 or x>6370 or (x>3360 and x<3800) or (x>3900 and x<4944):continue
			var size:=Vector2(18,42+(x%3)*12)
			scenery.add_child(Art.prop(7,size,Vector2(x,info.y-size.y+6)))
	var jose:=preload("res://world/Scripts/jose_companion.gd").new()
	jose.name="Jose"
	jose.position=Vector2(275,100)
	level.add_child(jose)
	for info in [[Vector2(1000,84),"follow",50.0],[Vector2(1190,84),"repel",45.0],[Vector2(2320,40),"shuttle",45.0],[Vector2(2465,36),"follow",30.0],[Vector2(5070,82),"follow",38.0],[Vector2(5530,42),"repel",50.0]]:
		var rock:=preload("res://world/Scripts/gravity_rock.gd").new()
		rock.position=info[0]
		rock.behavior=info[1]
		rock.travel=info[2]
		level.add_child(rock)
	for info in [[Vector2(700,100),false,0.0],[Vector2(1530,100),false,1.5],[Vector2(2100,100),true,0.3],[Vector2(2830,36),false,2.0],[Vector2(3070,36),true,1.2],[Vector2(5360,100),false,2.3],[Vector2(6530,100),true,0.0]]:
		var geyser:=preload("res://world/Scripts/lava_geyser.gd").new()
		geyser.position=info[0]
		geyser.launch_geyser=info[1]
		geyser.phase=info[2]
		level.add_child(geyser)
	for info in [[Vector2(530,100),"wall"],[Vector2(1810,100),"pillar"],[Vector2(3970,100),"block"],[Vector2(5840,100),"pillar"]]:
		var obstacle:=preload("res://world/Scripts/underworld_obstacle.gd").new()
		obstacle.position=info[0]
		obstacle.kind=info[1]
		if obstacle.kind=="block":
			obstacle.name="ForgeWeight"
			obstacle.push_offset=Vector2(130,0)
		level.add_child(obstacle)
	for point in [Vector2(760,100),Vector2(1670,100),Vector2(2750,36),Vector2(4610,100),Vector2(5680,100),Vector2(6320,100)]:
		var enemy:=preload("res://world/Scripts/underworld_enemy.gd").new()
		enemy.position=point
		enemy.patrol_width=104
		level.add_child(enemy)
	for point in [Vector2(1410,13),Vector2(2650,-45),Vector2(5290,14),Vector2(5710,30),Vector2(6160,10)]:
		var enemy:=preload("res://world/Scripts/underworld_enemy.gd").new()
		enemy.species="imp"
		enemy.position=point
		enemy.patrol_width=66
		level.add_child(enemy)
	for point in [Vector2(602,100),Vector2(2615,36),Vector2(5250,100)]:
		var fruit:=preload("res://world/Scripts/dragon_fruit.gd").new()
		fruit.position=point
		level.add_child(fruit)
	for point in [Vector2(610,100),Vector2(1390,100),Vector2(2030,100),Vector2(2630,36),Vector2(3440,-40),Vector2(3940,100),Vector2(4850,100),Vector2(5240,100),Vector2(6200,100),Vector2(6385,100)]:
		preload("res://world/Scripts/magic_layout.gd")._checkpoint(level.get_node("Checkpoints"),point)
	var forge:=preload("res://world/Scripts/inverted_forge.gd").new()
	forge.name="Forge"
	forge.position=Vector2(4410,100)
	level.add_child(forge)
	var gate:=StaticBody2D.new()
	gate.name="ForgeGate"
	gate.collision_layer=1
	gate.collision_mask=0
	gate.position=Vector2(4910,-70)
	var shape:=RectangleShape2D.new()
	shape.size=Vector2(24,420)
	var collider:=CollisionShape2D.new()
	collider.shape=shape
	gate.add_child(collider)
	gate.add_child(Art.prop(6,Vector2(24,270),Vector2(-12,-100)))
	level.add_child(gate)
	forge.gate=gate
	for info in [[Vector2(4150,100),0.0],[Vector2(4670,100),1.8]]:
		var steam:=preload("res://world/Scripts/underworld_steam.gd").new()
		steam.position=info[0]
		steam.phase=info[1]
		level.add_child(steam)
	for info in [[Vector2(4060,12),Vector2(160,-28)],[Vector2(4540,0),Vector2(190,-24)]]:
		var moving:=preload("res://world/Scripts/underworld_platform.gd").new()
		moving.position=info[0]
		moving.travel_offset=info[1]
		moving.travel_time=2.5
		moving.endpoint_pause=0.35
		moving.collision_layer=1
		moving.collision_mask=0
		var collision:=CollisionShape2D.new()
		var rect:=RectangleShape2D.new()
		rect.size=Vector2(86,12)
		collision.shape=rect
		collision.position.y=6
		collision.one_way_collision=true
		moving.add_child(collision)
		level.add_child(moving)
	for info in [[Vector2(6555,-235),260.0],[Vector2(6870,-325),270.0]]:
		var chain:=preload("res://world/Scripts/underworld_chain.gd").new()
		chain.position=info[0]
		chain.length=info[1]
		level.add_child(chain)
	var boss:=preload("res://world/Scripts/depth_warden.gd").new()
	boss.name="Boss"
	boss.position=Vector2(7100,100)
	boss.z_index=3
	level.add_child(boss)
	var key:=preload("res://world/Scripts/depth_key.gd").new()
	key.name="DepthKey"
	level.add_child(key)
	var exit:=preload("res://world/Scripts/underworld_exit.gd").new()
	exit.name="ExitPortal"
	exit.position=Vector2(7820,100)
	level.add_child(exit)
	var caravan:=preload("res://prefabs/caravan_shop.tscn").instantiate()
	caravan.position=Vector2(6250,100)
	caravan.travel_offset=Vector2(8,0)
	level.add_child(caravan)
	var item_scene:=preload("res://prefabs/item.tscn")
	for info in GROUND:
		for x in range(int(info.x+70),int(info.x+info.z-35),85):
			if x<350 or x>6350:continue
			var item:=item_scene.instantiate()
			item.cherry_id="depth:ground:%d"%x
			item.position=Vector2(x,info.y-28)
			level.get_node("items").add_child(item)
	for i in 6:
		var rock:Node2D=level.get_tree().get_nodes_in_group("gravity_rocks")[i]
		var item:=item_scene.instantiate()
		item.cherry_id="depth:rock:%d"%i
		item.position=rock.position+Vector2(0,-28)
		level.get_node("items").add_child(item)
		rock.set_meta("cherry",weakref(item))
static func _ground(parent:Node,at:Vector2,width:float,depth:float,one_way:bool) -> void:
	var ground:=Terrain.new()
	ground.position=at
	ground.width=width
	ground.depth=depth
	ground.one_way=one_way
	ground.platform=one_way
	parent.add_child(ground)

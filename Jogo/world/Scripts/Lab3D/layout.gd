extends RefCounted
const Art=preload("res://world/Scripts/Lab3D/models.gd")
const ORIGINS:=[Vector3(0,0,0),Vector3(0,6,-74),Vector3(0,14,-148),Vector3(0,26,-224),Vector3(70,18,-74),Vector3(70,22,-148),Vector3(70,26,-224)]
const NAMES:=["RECEPÇÃO E SEGURANÇA","SETOR DE CONTENÇÃO","FÁBRICA DE MODIFICAÇÕES","COBERTURA · PESQUISA AVANÇADA","ARQUIVO E LOGÍSTICA","JARDIM BIOTÉRMICO","OBSERVATÓRIO DE SEGURANÇA"]
const ROUTE:=[0,1,2,4,5,6,3]
static func landing(index:int,backwards:bool) -> Vector3:
	if not backwards:return Vector3(0,.08,-3)
	if index>=4:return Vector3(0,.08,-58)
	return Vector3(0,[3.08,5.08,8.08,0.08][index],-39.6)
static func solid(parent:Node3D,at:Vector3,size:Vector3,color:String="435669",metal:float=.3) -> StaticBody3D:
	var body:=StaticBody3D.new();body.position=at;body.collision_layer=1;body.collision_mask=0;parent.add_child(body)
	var shape:=BoxShape3D.new();shape.size=size;var col:=CollisionShape3D.new();col.shape=shape;body.add_child(col)
	Art.box(body,"Mesh",Vector3.ZERO,size,color,metal);return body
static func floor_piece(parent:Node3D,x:float,z:float,width:float,length:float,y:float=0) -> void:
	solid(parent,Vector3(x,y-.3,z),Vector3(width,.6,length),"4b6373")
	var mesh:=BoxMesh.new();mesh.size=Vector3(1.92,.035,1.92)
	var multimesh:=MultiMesh.new();multimesh.transform_format=MultiMesh.TRANSFORM_3D;multimesh.mesh=mesh
	var nx:=int(width/2);var nz:=int(length/2);multimesh.instance_count=nx*nz
	for i in nx:
		for j in nz:multimesh.set_instance_transform(i*nz+j,Transform3D(Basis.IDENTITY,Vector3(x-width*.5+1+i*2,y+.025,z-length*.5+1+j*2)))
	var tiles:=MultiMeshInstance3D.new();tiles.multimesh=multimesh;tiles.material_override=Art.material("829ba2",.22);parent.add_child(tiles)
	for side in [-1.0,1.0]:Art.box(parent,"FloorGuide",Vector3(x+side*(width*.5-.45),y+.06,z),Vector3(.07,.04,length-.2),"69c2bd",0,.3)
static func device(level:Node3D,sector:int,kind:String,at:Vector3,options:Dictionary={}) -> Node3D:
	var node:=preload("res://world/Scripts/Lab3D/device.gd").new();node.kind=kind;node.sector=sector;node.level=level;node.position=at
	for key in options:node.set(key,options[key])
	level.sectors[sector].add_child(node);return node
static func room(level:Node3D,index:int) -> Node3D:
	var root:=Node3D.new();root.name="Sector"+str(index);root.position=ORIGINS[index];level.add_child(root);level.sectors.append(root)
	var accent:String=["c5a65e","63c7ac","d5a26e","89bada"][index]
	if index==3:return root
	var height:=10.0+index*4;var exit_height:float=[3,5,8][index]
	for side in [-1.0,1.0]:
		solid(root,Vector3(side*11,height*.5-.2,-17),Vector3(.5,height,54),"566f7b")
		for z in range(-40,9,8):
			Art.box(root,"WallPanel",Vector3(side*10.68,3.2,z),Vector3(.11,4.5,6.8),"bcc4b5",.25)
			var display:=Art.box(root,"WallInset",Vector3(side*10.58,3.35,z),Vector3(.09,1.7,5.3),"1a3a4f",.25);Art.screen(display)
			Art.box(root,"LightStrip",Vector3(side*10.45,height-2.15,z),Vector3(.10,.12,6),accent,0,.6)
			Art.cylinder(root,"Pipe",Vector3(side*10.35,height-1.3,z),.19,7.8,"4b6772",-1,.5).rotation.x=PI/2
			Art.box(root,"Pillar",Vector3(side*10.5,height*.5-.2,z+3.8),Vector3(.6,height-.6,.42),"3b5363",.4)
	# A high ceiling leaves the follow camera free; the entrance is an actual gap.
	solid(root,Vector3(0,height,-17),Vector3(22,.4,54),"263c4b")
	for x in [-7.1,7.1]:solid(root,Vector3(x,height*.5,-44),Vector3(8.2,height,.5),"5d7480")
	solid(root,Vector3(0,exit_height*.5,-44),Vector3(6,exit_height,.5),"526c7b")
	var above:=height-exit_height-4.5
	solid(root,Vector3(0,height-above*.5,-44),Vector3(6,above,.5),"455f71")
	if index in [1,2]:
		for x in [-7.1,7.1]:solid(root,Vector3(x,height*.5,4),Vector3(8.2,height,.5),"536b79")
	Art.box(root,"DoorLintel",Vector3(0,exit_height+4.8,-43.8),Vector3(6,.8,.7),"334c5e",.4)
	Art.label(root,NAMES[index],Vector3(0,exit_height+5.8,-43.4),45,accent)
	for z in [-4,-20,-35]:
		Art.box(root,"CeilingLamp",Vector3(0,7.7,z),Vector3(7,.06,.3),"c6e4df",0,.7)
		for x in [-3,3]:Art.cylinder(root,"LampHanger",Vector3(x,(height+7.7)*.5,z),.035,height-7.7,"536b79",-1,.5)
		var lamp:=OmniLight3D.new();lamp.position=Vector3(0,5.8,z);lamp.light_color=Color("dce3ce");lamp.light_energy=2.5;lamp.omni_range=15;root.add_child(lamp)
		var spot:=SpotLight3D.new();spot.position=Vector3(0,7.5,z);spot.rotation.x=-PI/2;spot.spot_range=14;spot.spot_angle=65;spot.light_energy=1.2;spot.shadow_enabled=true;root.add_child(spot)
	return root
static func build(level:Node3D) -> void:
	for i in 4:room(level,i)
	var first:Node3D=level.sectors[0]
	floor_piece(first,0,-14,22,56)
	floor_piece(first,0,21,34,14)
	floor_piece(first,0,-39,20,10,3)
	device(level,0,"lift",Vector3(0,0,-32),{"rise":3.0})
	device(level,0,"keycard",Vector3(0,0,-25))
	device(level,0,"door",Vector3(0,3,-42),{"destination":1})
	device(level,0,"checkpoint",Vector3(3,0,-23))
	device(level,0,"fragment",Vector3(-7,0,-28))
	device(level,0,"boost",Vector3(0,0,-11))
	Art.label(first,"SHIFT · CORRER\nESPAÇO · PULAR",Vector3(0,.12,-8),28,"254c5c").rotation.x=-PI/2
	Art.label(first,"Sua segurança é nossa 17ª prioridade.",Vector3(-6,3,-3),24,"e9c785")
	# Forecourt, facade and two independent leaves used by the breach cinematic.
	level.front_door=Node3D.new();level.front_door.name="ServiceDoor";level.front_door.position=Vector3(0,0,8);first.add_child(level.front_door)
	for side in [-1.0,1.0]:
		var leaf:=solid(level.front_door,Vector3(side*1.35,2.4,0),Vector3(2.7,4.8,.35),"718994",.4);leaf.name="LeafL" if side<0 else "LeafR"
		Art.bevel(leaf,"DoorInset",Vector3(0,0,.23),Vector3(2.35,3.9,.18),"b5bda9",.12)
		Art.box(leaf,"Grip",Vector3(-side*.8,-.15,.4),Vector3(.12,.8,.1),"354b59",.5)
		for i in 5:Art.box(leaf,"Caution",Vector3(-1.0+i*.46,-2.15,.2),Vector3(.23,.2,.06),"d9b464" if i%2 else "233544")
		solid(first,Vector3(side*7.3,3.7,8),Vector3(8.8,7.4,.8),"5a7179")
		Art.box(first,"FrontColumn",Vector3(side*3.15,3.1,8.5),Vector3(.5,6.2,.7),"2b4354",.5)
	Art.box(first,"CorporateSign",Vector3(0,6.0,8.6),Vector3(6.5,1.9,.18),"1c3042",.4)
	solid(first,Vector3(0,8.7,8),Vector3(6.3,2.6,.8),"546c78")
	Art.label(first,"CORPORAÇÃO\nLABORATÓRIO DOS EXECUTIVOS",Vector3(0,6.1,8.75),31,"e9ca7e")
	Art.badge(first,Vector3(-2.7,6.2,8.8),4).rotation.y=PI
	for side in [-1.0,1.0]:
		Art.box(first,"Seawall",Vector3(side*16.7,.65,20),Vector3(.4,1.3,15),"526b77")
		var planter:=solid(first,Vector3(side*12,.5,12),Vector3(2.8,1,2.8),"455f6b")
		Art.cylinder(planter,"TreeTrunk",Vector3(0,1.2,0),.18,2,"79654e")
		Art.ball(planter,"TreeCrown",Vector3(0,2.6,0),Vector3(2.5,2.8,2.5),"548b78")
	var merchant:=Art.instantiate("wagon");merchant.name="OliverWagon";merchant.position=Vector3(-6,0,2);first.add_child(merchant);level.wagon=merchant
	var oliver:=Art.instantiate("oliver");oliver.position=Vector3(0,.55,.25);oliver.scale=Vector3.ONE*.8;oliver.rotation.y=PI;merchant.add_child(oliver)
	Art.label(merchant,"OLIVER GANCHO · E",Vector3(0,3.25,0),25,"f3d991")
	for i in 3:
		var desk:=solid(first,Vector3(7,.75,-8-i*6),Vector3(3.2,1.5,2),"47606c")
		Art.box(desk,"Monitor",Vector3(0,1.25,-.4),Vector3(1.5,1,.18),"223a50",.4);Art.screen(Art.box(desk,"Screen",Vector3(0,1.25,-.29),Vector3(1.3,.77,.03),"5899ab",0,.3))
	var containment:Node3D=level.sectors[1]
	floor_piece(containment,0,-4.5,22,17)
	floor_piece(containment,0,-32.5,22,23)
	floor_piece(containment,0,-39,20,10,5)
	device(level,1,"pool",Vector3(0,0,-17),{"width":22.0,"depth":8.0})
	Art.label(containment,"VERDE: VENENO\nK: GELO FORMA UMA PONTE",Vector3(0,2.3,-11),32,"d8f0b4")
	device(level,1,"checkpoint",Vector3(3,0,-25))
	device(level,1,"lift",Vector3(0,0,-32),{"rise":5.0})
	device(level,1,"door",Vector3(0,5,-42),{"destination":2})
	device(level,1,"door",Vector3(0,0,4),{"destination":0})
	floor_piece(containment,-8,-28,4,4,4)
	device(level,1,"spring",Vector3(-8,0,-24))
	device(level,1,"fragment",Vector3(-8,4,-28))
	level.spawn_enemy(ORIGINS[1]+Vector3(-3,0,-26),"mutant",1)
	level.spawn_enemy(ORIGINS[1]+Vector3(5,2.8,-30),"drone",1)
	for x in [-8.0,8.0]:
		for z in [-5.0,-28.0]:
			var tank:=device(level,1,"tank",Vector3(x,0,z));tank.rotation.y=PI/2 if x<0 else -PI/2
	var factory:Node3D=level.sectors[2]
	floor_piece(factory,0,-11,22,30)
	floor_piece(factory,0,-39,22,10)
	floor_piece(factory,0,-42,20,6,8)
	device(level,2,"lever",Vector3(-3,0,-13),{"circuit":"factory"})
	device(level,2,"conveyor",Vector3(0,0,-13),{"width":3.5,"depth":8.0,"circuit":"factory"})
	device(level,2,"press",Vector3(0,0,-21))
	device(level,2,"ferry",Vector3(0,0,-26),{"enabled":false,"circuit":"factory","travel":Vector3(0,0,-8)})
	device(level,2,"checkpoint",Vector3(3,0,-24))
	device(level,2,"lift",Vector3(0,0,-37),{"rise":8.0})
	device(level,2,"door",Vector3(0,8,-42.7),{"destination":4})
	device(level,2,"door",Vector3(0,0,4),{"destination":1})
	device(level,2,"fragment",Vector3(8,0,-19.5))
	device(level,2,"laser",Vector3(7,0,-18),{"width":4.0})
	device(level,2,"camera",Vector3(-7,1.0,-25))
	level.spawn_enemy(ORIGINS[2]+Vector3(5,0,-9),"technician",2)
	level.spawn_enemy(ORIGINS[2]+Vector3(-6,0,-20),"lizard",2)
	Art.label(factory,"E: LIGAR CIRCUITO",Vector3(-3,2.2,-13),28,"eccc85")
	Art.label(factory,"A PLATAFORMA ESPERA VOCÊ EMBARCAR",Vector3(0,3,-25),24,"afe8de")
	for z in [-6,-18,-30]:
		for side in [-1.0,1.0]:
			var machine:=solid(factory,Vector3(side*8,1.3,z),Vector3(3,2.6,3.4),"365063",.45)
			Art.cylinder(machine,"Valve",Vector3(-side*.6,1.7,0),.5,.16,"c69752",-1,.5)
	# Broad rooftop arena: no mandatory stack of tiny platforms.
	var roof:Node3D=level.sectors[3]
	floor_piece(roof,0,-15,30,38)
	Art.ring(roof,"ArenaMark",Vector3(0,.055,-17),6.5,"b7ae7c").scale.y=.035
	Art.label(roof,"C",Vector3(0,.085,-17),180,"c9c8a6").rotation.x=-PI/2
	for x in [-11,11]:
		for z in [-9,-25]:
			var housing:=solid(roof,Vector3(x,.35,z),Vector3(2.5,.7,3.0),"345266")
			for i in 4:Art.box(housing,"RoofVent",Vector3(-.8+i*.52,.37,0),Vector3(.11,.05,2.6),"8fa7ab",.4)
	Art.box(roof,"BuildingShell",Vector3(0,-13.8,-15),Vector3(32,27,40),"385566",.3)
	for side in [-1.0,1.0]:
		solid(roof,Vector3(side*15,.55,-15),Vector3(.4,1.1,38),"6b8790")
		for z in range(-32,4,4):
			Art.box(roof,"RailPost",Vector3(side*14.8,1.3,z),Vector3(.12,1.5,.12),"a2bfc1",.5)
		Art.box(roof,"Rail",Vector3(side*14.8,1.8,-15),Vector3(.1,.12,38),"abbebf",.5)
	for z in [-34.0,4.0]:solid(roof,Vector3(0,.55,z),Vector3(30,1.1,.4),"5b7987")
	for x in [-5.5,5.5]:
		var vent:=solid(roof,Vector3(x,.45,-21),Vector3(3.2,.9,3.2),"778e93",.5)
		for i in 5:Art.box(vent,"Grille",Vector3(-1.1+i*.55,.48,0),Vector3(.18,.05,2.5),"334e63")
	device(level,3,"checkpoint",Vector3(4,0,0))
	device(level,3,"door",Vector3(10,0,1),{"destination":6})
	device(level,3,"heat",Vector3(-10,0,-17))
	device(level,3,"cold",Vector3(10,0,-17))
	device(level,3,"injector",Vector3(-9,0,-3))
	level.rescue_chamber=device(level,3,"rescue",Vector3(0,0,-30))
	device(level,3,"record",Vector3(8,0,-3))
	for side in [-1.0,1.0]:
		Art.cylinder(roof,"Antenna",Vector3(side*12,3.0,-31),.08,6,"7b959f",-1,.6)
		Art.ball(roof,"Beacon",Vector3(side*12,6,-31),Vector3(.22,.22,.22),"edbe7c",1)
	Art.label(roof,"PESQUISA AVANÇADA\nPROCEDIMENTOS PERFEITAMENTE APROVADOS",Vector3(0,3.5,-33.5),31,"eccc8a")
	_cherries(level)
	load("res://world/Scripts/Lab3D/expansion_layout.gd").build(level)
static func _cherries(level:Node3D) -> void:
	var ids:Array[String]=[]
	for s in preload("res://world/Scripts/lab_layout.gd").GROUND:
		for x in range(int(s.x+95),int(s.x+s.z-60),95):
			if x>=490 and x<=6020:ids.append("lab:floor:%d"%x)
	for i in 3:
		for j in 4:ids.append("lab:bonus:%d:%d"%[i,j])
	level.total_gems=ids.size()
	level.cherry_ids=ids
	var paths:=[Vector3(0,0,-9),Vector3(0,0,-15),Vector3(0,0,-21),Vector3(0,3,-39),Vector3(1,0,-4),Vector3(1,0,-10),Vector3(1,0,-25),Vector3(1,5,-39),Vector3(2,0,-5),Vector3(2,0,-16),Vector3(2,0,-24),Vector3(2,8,-41),Vector3(3,0,-3)]
	for i in ids.size():
		var path:Vector3=paths[mini(int(float(i)/ids.size()*paths.size()),paths.size()-1)]
		device(level,int(path.x),"cherry",Vector3((i%3-1)*.6,path.y+.05,path.z-(i%4)*.65),{"cherry_id":ids[i]})

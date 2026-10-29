extends RefCounted
## Three full-scale chambers between the factory and the rooftop. Props use
## ground origins; only the optional record balconies require extra jumps.
const Art=preload("res://world/Scripts/Lab3D/models.gd")
const ExpansionArt=preload("res://world/Scripts/Lab3D/expansion_models.gd")

static func build(level:Node3D) -> void:
	var layout:Script=load("res://world/Scripts/Lab3D/layout.gd")
	for index in [4,5,6]:_chamber(level,index,layout)
	_archive(level,layout)
	_biothermal(level,layout)
	_observatory(level,layout)
	_cherries(level,layout)

static func _device(level:Node3D,index:int,kind:String,at:Vector3,options:Dictionary={}) -> Node3D:
	var script:Script=load("res://world/Scripts/Lab3D/expansion_device.gd")
	var node:Node3D=script.new()
	node.kind=kind;node.level=level;node.sector=index;node.position=at
	for key in options:node.set(key,options[key])
	level.sectors[index].add_child(node)
	return node

static func _prop(parent:Node3D,kind:String,at:Vector3,angle:float=PI) -> Node3D:
	var prop:Node3D=Art.instantiate(kind) if ResourceLoader.exists("res://world/Models/Lab3D/"+kind+".tscn") else ExpansionArt.make(kind,Art)
	prop.position=at;prop.rotation.y=angle;parent.add_child(prop)
	return prop

static func _blocker(parent:Node3D,at:Vector3,size:Vector3) -> void:
	var body:=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;body.position=at;parent.add_child(body)
	var shape:=BoxShape3D.new();shape.size=size
	var collision:=CollisionShape3D.new();collision.shape=shape;body.add_child(collision)

static func _chamber(level:Node3D,index:int,layout:Script) -> void:
	var root:=Node3D.new();root.name="Sector"+str(index);root.position=layout.ORIGINS[index]
	level.add_child(root);level.sectors.append(root)
	var accent:String={4:"e4bb75",5:"9bd6bc",6:"88c5e6"}[index]
	var wall_tint:String={4:"a9b5af",5:"8ea89f",6:"889eae"}[index]
	for side in [-1.0,1.0]:
		layout.solid(root,Vector3(side*12,4.9,-30),Vector3(.5,10.2,72),"455c6b")
		for z in range(-60,5,10):
			Art.box(root,"WallPanel",Vector3(side*11.68,3.1,z),Vector3(.12,5.6,9.2),wall_tint,.25)
			Art.box(root,"StructuralRib",Vector3(side*11.45,4.8,z-4.75),Vector3(.45,9.6,.32),"2c465a",.45)
			Art.box(root,"CircuitLight",Vector3(side*11.5,6.35,z),Vector3(.09,.1,8.6),accent,0,.55)
			Art.cylinder(root,"CableRun",Vector3(side*11.24,8.0,z),.12,9.8,"425d6d",-1,.4).rotation.x=PI/2
			if index==6:
				var glass:=Art.box(root,"ObservationWindow",Vector3(side*11.55,3.4,z),Vector3(.08,3.6,6.8),"213c56",.15,.12)
				Art.screen(glass)
				for offset in [-2.3,0.0,2.3]:Art.box(root,"WindowMullion",Vector3(side*11.42,3.4,z+offset),Vector3(.14,3.8,.08),"7795a6",.5)
			else:
				Art.box(root,"WallDado",Vector3(side*11.5,.45,z),Vector3(.14,.5,9.2),"344d5e",.35)
	# The only wall openings are the paired doors. Solid lintels close all sky gaps.
	for z in [4.0,-62.0]:
		for side in [-1.0,1.0]:layout.solid(root,Vector3(side*7.5,5,z),Vector3(9,10,.5),"526d78")
		layout.solid(root,Vector3(0,7.4,z),Vector3(6,5.2,.5),"3b5667")
		for side in [-1.0,1.0]:Art.box(root,"DoorFrame",Vector3(side*2.9,2.3,z+.12),Vector3(.28,4.6,.55),"d1c6a3",.4)
		Art.box(root,"DoorCrown",Vector3(0,4.65,z+.12),Vector3(6.1,.3,.55),accent,.35,.15)
	layout.solid(root,Vector3(0,10,-30),Vector3(24,.4,72),"253c4e")
	for z in [-3,-18,-35,-52]:
		Art.box(root,"CeilingTruss",Vector3(0,9.45,z),Vector3(23,.3,.35),"4b6777",.5)
		Art.box(root,"CeilingLamp",Vector3(0,8.65,z),Vector3(8,.08,.45),"d4e7dd",0,.65)
		for side in [-1.0,1.0]:Art.cylinder(root,"LampSuspension",Vector3(side*3,9.08,z),.035,.8,"7d969f",-1,.5)
		var lamp:=OmniLight3D.new();lamp.position=Vector3(0,6.0,z);lamp.light_color=Color("deeadb");lamp.light_energy=1.8;lamp.omni_range=14;root.add_child(lamp)
	Art.label(root,layout.NAMES[index],Vector3(0,5.5,-61.6),37,accent)
	Art.label(root,"0%d"%index,Vector3(8.3,3.6,-61.62),110,accent)
	var previous:int={4:2,5:4,6:5}[index]
	var next:int={4:5,5:6,6:3}[index]
	var back:Node3D=layout.device(level,index,"door",Vector3(0,0,4),{"destination":previous});back.rotation.y=PI
	layout.device(level,index,"door",Vector3(0,0,-62),{"destination":next})
	if index!=5:layout.floor_piece(root,0,-31,24,70)

static func _archive(level:Node3D,layout:Script) -> void:
	var root:Node3D=level.sectors[4]
	# A safe workshop introduces carrying before any scanners or enemies appear.
	_device(level,4,"power_cell",Vector3(-4,0,-10),{"circuit":"archive"})
	_device(level,4,"power_socket",Vector3(4,0,-22),{"circuit":"archive"})
	_device(level,4,"blast_gate",Vector3(0,0,-27),{"circuit":"archive","width":23.5})
	_sign(root,"LOGÍSTICA · ENERGIA AUXILIAR",Vector3(0,2.8,-6),"e4bb75")
	_floor_arrow(root,Vector3(-4,.12,-14),"e4bb75")
	_floor_arrow(root,Vector3(4,.12,-24),"e4bb75")
	for side in [-1.0,1.0]:
		for z in [-13,-39,-55]:
			if side<0 and z==-55:continue
			_shelf(root,layout,Vector3(side*9.2,0,z),side)
	for at in [Vector3(6.6,0,-15),Vector3(-6.3,0,-39)]:
		_prop(root,"cargo_cart",at,PI/2)
		_blocker(root,at+Vector3(0,.65,0),Vector3(2.0,1.3,1.65))
	layout.device(level,4,"checkpoint",Vector3(3,0,-34))
	_device(level,4,"security_scanner",Vector3(-7,0,-45),{"width":5.0,"depth":9.0})
	level.spawn_enemy(layout.ORIGINS[4]+Vector3(4,0,-43),"technician",4)
	level.spawn_enemy(layout.ORIGINS[4]+Vector3(-3,2.7,-52),"drone",4)
	_record_balcony(level,4,Vector3(-7.5,0,-53),layout,"LOGÍSTICA: os executivos requisitaram amostras vivas. Urso foi transferido para a cobertura.")
	_sign(root,"ELEVADOR DE CARGA → BIOTERMIA",Vector3(0,3,-59),"e4bb75")

static func _biothermal(level:Node3D,layout:Script) -> void:
	var root:Node3D=level.sectors[5]
	layout.floor_piece(root,0,-9.5,24,27)
	layout.floor_piece(root,0,-52.5,24,27)
	_device(level,5,"thermal_relay",Vector3(-3,0,-14),{"circuit":"cryo"})
	_device(level,5,"piston_bridge",Vector3(0,0,-31),{"circuit":"cryo","width":4.0,"depth":16.0})
	_sign(root,"ESTUFA BIOTÉRMICA",Vector3(0,3.2,-7),"a6e4c1")
	layout.device(level,5,"checkpoint",Vector3(3,0,-19))
	layout.device(level,5,"checkpoint",Vector3(3,0,-43))
	# Rails frame the abyss; the central four-metre docking lane stays open.
	for side in [-1.0,1.0]:
		for z in [-22.8,-39.2]:
			layout.solid(root,Vector3(side*7,.48,z),Vector3(9.5,.96,.22),"4b6d72",.4)
			Art.box(root,"RimSignal",Vector3(side*7,1.01,z),Vector3(9.2,.06,.12),"9ad7be",0,.4)
		Art.box(root,"BridgeDock",Vector3(side*2.25,-.15,-31),Vector3(.32,.3,16.2),"2b4757",.5)
		for z in [-7.0,-17.0,-45.0,-57.0]:
			_prop(root,"specimen_tree",Vector3(side*8.8,0,z),side*.4)
			_blocker(root,Vector3(side*8.8,.4,z),Vector3(1.6,.8,1.6))
	Art.box(root,"ServiceChasm",Vector3(0,-7,-31),Vector3(23,.4,15.5),"102d3e",.2)
	for z in [-25.0,-29.0,-33.0,-37.0]:
		Art.box(root,"BridgeGuide",Vector3(0,-.3,z),Vector3(.14,.06,1.7),"80cdb7",0,.3)
	_device(level,5,"ventilation_fan",Vector3(-5,0,-48),{"width":6.0,"depth":10.0,"push_direction":Vector3.RIGHT})
	_sign(root,"VENTILAÇÃO LATERAL\nGELO: PARAR O ROTOR",Vector3(-6.5,3.0,-43),"9adce6")
	level.spawn_enemy(layout.ORIGINS[5]+Vector3(4,0,-51),"mutant",5)
	level.spawn_enemy(layout.ORIGINS[5]+Vector3(-2,2.8,-58),"drone",5)
	_device(level,5,"archive_console",Vector3(8,0,-53),{"secret_record":true,"record_text":"BIOTERMIA: uma célula precisa de calor para despertar e de frio para estabilizar. As duas fases mantêm a ponte erguida."})
	_prop(root,"cargo_cart",Vector3(8.2,0,-48))
	_sign(root,"OBSERVATÓRIO · CONTROLE DE SEGURANÇA",Vector3(0,3,-59),"a6e4c1")

static func _observatory(level:Node3D,layout:Script) -> void:
	var root:Node3D=level.sectors[6]
	_sign(root,"ANEXO DE SEGURANÇA",Vector3(0,3.1,-6),"a4d8f2")
	_device(level,6,"power_cell",Vector3(-4,0,-9),{"circuit":"security"})
	_device(level,6,"power_socket",Vector3(4,0,-20),{"circuit":"security"})
	_device(level,6,"blast_gate",Vector3(0,0,-28),{"circuit":"security","width":23.5})
	layout.device(level,6,"checkpoint",Vector3(3,0,-32))
	_device(level,6,"security_scanner",Vector3(-6,0,-37),{"width":5.0,"depth":8.0})
	_device(level,6,"security_scanner",Vector3(6,0,-48),{"width":5.0,"depth":8.0})
	_device(level,6,"ventilation_fan",Vector3(-5,0,-44),{"width":6.0,"depth":8.0,"push_direction":Vector3.RIGHT})
	# Alternating cover leaves broad lanes and a direct, readable exit approach.
	for at in [Vector3(-8,0,-17),Vector3(7,0,-34),Vector3(-1.2,0,-40),Vector3(7,0,-51)]:
		var cover:Node3D=Art.instantiate("crate");cover.position=at;root.add_child(cover)
		_blocker(root,at+Vector3(0,.85,0),Vector3(1.7,1.7,1.7))
	for side in [-1.0,1.0]:
		var bank:StaticBody3D=layout.solid(root,Vector3(side*8,1.0,-7),Vector3(3,2,2),"3b576b",.45)
		var screen:=Art.box(bank,"SecurityScreen",Vector3(0,1.3,.05),Vector3(2.6,.9,.16),"1a3e51",.3)
		Art.screen(screen)
		Art.box(root,"ObservationRail",Vector3(side*9.5,1.05,-45),Vector3(.08,.15,25),"92b2bd",.5)
	level.spawn_enemy(layout.ORIGINS[6]+Vector3(4,0,-40),"technician",6)
	level.spawn_enemy(layout.ORIGINS[6]+Vector3(-4,0,-53),"lizard",6)
	_record_balcony(level,6,Vector3(-7.5,0,-54),layout,"PESQUISA: o LG-17 mantém o enxerto de Largato estável. O próprio injetor é capaz de inverter o fluxo.")
	_floor_arrow(root,Vector3(0,.12,-56),"a4d8f2")
	_sign(root,"COBERTURA\nPESQUISA AVANÇADA",Vector3(0,3.2,-59),"f0d399")

static func _shelf(root:Node3D,layout:Script,at:Vector3,side:float) -> void:
	var rack:=Node3D.new();rack.name="ArchiveRack";rack.position=at;root.add_child(rack)
	for x in [-1.35,1.35]:
		for z in [-2.1,2.1]:Art.box(rack,"Upright",Vector3(x,2.2,z),Vector3(.14,4.4,.14),"4b6576",.5)
	for y in [.15,1.65,3.15]:
		layout.solid(rack,Vector3(0,y,0),Vector3(2.8,.12,4.4),"677e87",.4)
		for z in [-1.25,1.25]:
			Art.bevel(rack,"DocumentCase",Vector3(0,y+.48,z),Vector3(2.25,.85,1.7),"c3bea6",.08)
			Art.box(rack,"CaseLatch",Vector3(-side*1.16,y+.48,z),Vector3(.06,.22,.35),"d7a65f",.4)
	Art.label(rack,"LG · ARQUIVO",Vector3(-side*1.45,3.9,0),22,"efce87").rotation.y=-side*PI/2

static func _record_balcony(level:Node3D,index:int,at:Vector3,layout:Script,record_text:String) -> void:
	var root:Node3D=level.sectors[index]
	layout.floor_piece(root,at.x,at.z,4,5,2.0)
	for side in [-1.0,1.0]:Art.box(root,"BalconySupport",at+Vector3(side*1.7,1.0,0),Vector3(.22,2,.22),"547184",.5)
	layout.device(level,index,"spring",at+Vector3(0,0,5.3))
	_device(level,index,"archive_console",at+Vector3(0,2.0,0),{"secret_record":true,"record_text":record_text})
	Art.label(root,"ARQUIVO RESTRITO",at+Vector3(0,3.9,-1),25,"ead199")

static func _sign(root:Node3D,text:String,at:Vector3,color:String) -> void:
	Art.box(root,"WayfindingPanel",at+Vector3(0,0,-.05),Vector3(6.5,1.15,.12),"233d50",.35)
	Art.label(root,text,at+Vector3(0,0,.04),27,color)

static func _floor_arrow(root:Node3D,at:Vector3,color:String) -> void:
	for side in [-1.0,1.0]:
		var stroke:=Art.box(root,"RouteChevron",at+Vector3(side*.3,0,0),Vector3(.12,.025,.85),color,0,.2)
		stroke.rotation.y=side*-.65

static func _cherries(level:Node3D,layout:Script) -> void:
	var routes:Dictionary={
		4:[Vector3(0,0,-7),Vector3(-4,0,-10),Vector3(0,0,-17),Vector3(4,0,-22),Vector3(0,0,-33),Vector3(0,0,-39),Vector3(2,0,-47),Vector3(0,0,-57)],
		5:[Vector3(0,0,-6),Vector3(-3,0,-14),Vector3(0,0,-20),Vector3(3,0,-43),Vector3(0,0,-46),Vector3(5,0,-50),Vector3(0,0,-54),Vector3(0,0,-59)],
		6:[Vector3(0,0,-6),Vector3(-4,0,-9),Vector3(4,0,-20),Vector3(0,0,-25),Vector3(2,0,-33),Vector3(2,0,-41),Vector3(0,0,-50),Vector3(0,0,-58)]
	}
	for index in [4,5,6]:
		var route:Array=routes[index]
		for i in route.size():
			var id:="lab:exp77:%d:%d"%[index,i]
			level.cherry_ids.append(id);level.total_gems+=1
			layout.device(level,index,"cherry",route[i]+Vector3(0,.05,0),{"cherry_id":id})

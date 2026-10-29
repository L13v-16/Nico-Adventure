extends RefCounted
const Layout=preload("res://world/Scripts/Lab3D/layout.gd")
const Art=preload("res://world/Scripts/Lab3D/models.gd")
static func box(level:Node3D,sector:int,at:Vector3,spring:bool=false) -> Node3D:
	var crate:=preload("res://world/Scripts/Lab3D/precision_crate.gd").new();crate.level=level;crate.sector=sector;crate.spring=spring;crate.position=at
	level.sectors[sector].add_child(crate);return crate
static func build(level:Node3D) -> void:
	# Each move is introduced on solid ground before it appears near a hazard.
	box(level,0,Vector3(0,0,-9))
	box(level,0,Vector3(-1.6,0,-17));box(level,0,Vector3(1.6,0,-17))
	for i in 3:
		var z:float=-13.5-i*3.1;var height:float=.65+i*.65
		Layout.floor_piece(level.sectors[0],-4.6,z,2.4,2.4,height)
		Art.box(level.sectors[0],"StepSupport",Vector3(-4.6,height*.5,z),Vector3(.8,height,1.1),"334f63",.4)
	Art.label(level.sectors[0],"PULO DUPLO\nESPAÇO + ESPAÇO",Vector3(-4.6,3.6,-18),23,"ead18d")
	# An optional low route teaches the slide without trapping a battery carrier.
	Layout.solid(level.sectors[0],Vector3(4.0,1.65,-19),Vector3(3.5,.75,.65),"c29e58")
	for x in [2.35,5.65]:Layout.solid(level.sectors[0],Vector3(x,.7,-19),Vector3(.18,1.4,.65),"375568")
	Art.label(level.sectors[0],"SHIFT / CTRL · DESLIZE",Vector3(4.0,2.6,-19),20,"c6eee6")
	box(level,1,Vector3(-5,0,-26));box(level,1,Vector3(3,0,-27))
	box(level,2,Vector3(-2,0,-7));box(level,2,Vector3(2,0,-15))
	box(level,4,Vector3(0,0,-37));box(level,4,Vector3(-2,0,-42))
	box(level,4,Vector3(-7.5,0,-47.7),true)
	box(level,5,Vector3(4,0,-13));box(level,5,Vector3(4,0,-45))
	box(level,6,Vector3(-4,0,-34));box(level,6,Vector3(-7.5,0,-48.7),true)
	# Move a few EXISTING IDs onto the optional steps; wallet rules stay intact.
	var step:=0
	for cherry in level.get_tree().get_nodes_in_group("lab3d_devices"):
		if cherry.kind=="cherry" and cherry.sector==0 and cherry.position.z<-14 and cherry.position.z>-18 and step<3:
			cherry.position=Vector3(-4.6,.70+step*.65,-13.5-step*3.1);step+=1

extends RefCounted
const Art=preload("res://world/Scripts/Lab3D/models.gd")
static func make(kind:String) -> Node3D:
	var root:=Node3D.new();root.name=kind.to_pascal_case()
	if kind=="card_dispenser":
		Art.bevel(root,"Foot",Vector3(0,.12,0),Vector3(1.9,.24,1.45),"344f62",.06)
		Art.bevel(root,"Pedestal",Vector3(0,.62,0),Vector3(1.5,1,1.15),"b2bcb3",.10)
		Art.box(root,"Display",Vector3(0,.65,.59),Vector3(1.17,.48,.08),"183a4c")
		Art.box(root,"Status",Vector3(0,.7,.65),Vector3(.8,.08,.03),"e7b26b",0,.4)
		Art.box(root,"Tray",Vector3(0,1.13,.2),Vector3(1.5,.08,1.2),"4d7381",.5)
		var lid:=Art.bevel(root,"Lid",Vector3(0,1.75,-.27),Vector3(1.65,1.25,.16),"5a7888",.07)
		Art.box(lid,"LidInset",Vector3(0,0,.095),Vector3(1.35,.95,.04),"243f51",.4)
		for side in [-1.0,1.0]:
			Art.cylinder(root,"Hinge",Vector3(side*.78,1.15,-.3),.1,.22,"d4ac65",-1,.5).rotation.z=PI/2
			Art.box(root,"Guard",Vector3(side*.72,1.45,.40),Vector3(.08,.6,.08),"d4ac65",.5)
		Art.box(root,"Lock",Vector3(0,1.2,.67),Vector3(.35,.28,.15),"dcb266",.5)
	elif kind=="puzzle_plate":
		Art.bevel(root,"Socket",Vector3(0,.08,0),Vector3(1.5,.16,1.5),"304d62",.06)
		Art.cylinder(root,"Button",Vector3(0,.15,0),.55,.15,"8fcfdb",-1,.3)
		Art.ring(root,"Status",Vector3(0,.235,0),.54,"e5b96d",.45).scale.y=.13
		for side in [-1.0,1.0]:
			var mark:=Art.box(root,"JumpMark",Vector3(side*.14,.236,0),Vector3(.08,.02,.33),"1b3f52");mark.rotation.y=side*.65
	else:
		Art.bevel(root,"Base",Vector3(0,.12,0),Vector3(1.25,.24,1),"304d62",.07)
		Art.bevel(root,"Housing",Vector3(0,.85,0),Vector3(.95,1.4,.75),"b8beb0",.08)
		Art.cylinder(root,"Axle",Vector3(0,.93,.5),.25,.3,"3d596c",-1,.6).rotation.x=PI/2
		var wheel:=Art.pivot(root,"Wheel",Vector3(0,.93,.67))
		Art.ring(wheel,"Rim",Vector3.ZERO,.48,"ddba72").rotation.x=PI/2
		for i in 3:
			var spoke:=Art.box(wheel,"Spoke",Vector3.ZERO,Vector3(.08,.80,.08),"ddba72",.5);spoke.rotation.z=i*TAU/3
		Art.ball(root,"Status",Vector3(0,1.45,.41),Vector3(.17,.17,.08),"e5b96d",.6)
	return root

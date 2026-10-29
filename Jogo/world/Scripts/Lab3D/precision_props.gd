extends RefCounted
const Art=preload("res://world/Scripts/Lab3D/models.gd")
static func crate(spring:bool=false) -> Node3D:
	var root:=Node3D.new();root.name="BounceCrate" if spring else "SupplyCrate"
	var frame:="407e8b" if spring else "ad774c"
	Art.bevel(root,"Core",Vector3(0,.7,0),Vector3(1.38,1.4,1.38),"233d50",.09)
	for side in [-1.0,1.0]:
		Art.box(root,"PanelX",Vector3(side*.7,.7,0),Vector3(.08,1.13,1.14),frame)
		Art.box(root,"PanelZ",Vector3(0,.7,side*.7),Vector3(1.14,1.13,.08),frame)
		for x in [-.61,.61]:
			Art.bevel(root,"Corner",Vector3(x,.7,side*.65),Vector3(.17,1.43,.17),"d4b276" if not spring else "9ad6d4",.035)
		var brace:=Art.box(root,"Brace",Vector3(0,.7,side*.765),Vector3(.13,1.25,.06),"ecd2a0" if not spring else "b1eee3");brace.rotation.z=side*.72
		for x in [-.54,.54]:
			for y in [.18,1.22]:Art.ball(root,"Rivet",Vector3(x,y,side*.8),Vector3(.065,.065,.04),"213547")
	Art.bevel(root,"Lid",Vector3(0,1.38,0),Vector3(1.45,.16,1.45),"d4b276" if not spring else "6ed6cc",.04)
	if spring:
		Art.cylinder(root,"BouncePlate",Vector3(0,1.50,0),.52,.12,"ecc775",-1,.4)
		for side in [-1.0,1.0]:
			var arrow:=Art.box(root,"Arrow",Vector3(side*.13,1.57,0),Vector3(.13,.025,.39),"254554");arrow.rotation.y=side*.65
	return root

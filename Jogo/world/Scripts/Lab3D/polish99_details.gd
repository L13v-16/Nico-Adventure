extends RefCounted
const Art=preload("res://world/Scripts/Lab3D/models.gd")
static func install(room:Node3D,index:int) -> void:
	var root:=Node3D.new();root.name="ResearchWallDetails99";room.add_child(root)
	for side in [-1.0,1.0]:
		Art.box(root,"CableTray",Vector3(side*10.45,4.7,-18),Vector3(.14,.18,36),"506773",.5)
		for z in [-10.0,-26.0,-38.0]:
			var station:=Node3D.new();station.name="WallStation";station.position=Vector3(side*10.4,0,z);root.add_child(station)
			Art.bevel(station,"Cabinet",Vector3(0,1.8,0),Vector3(.65,2.8,2.3),"6a8186",.10)
			var monitor:=Art.box(station,"Monitor",Vector3(-side*.37,2.2,0),Vector3(.06,.95,1.8),"376d65",.2,.4);Art.screen(monitor)
			var keyboard:=Art.box(station,"Keyboard",Vector3(-side*.55,1.4,0),Vector3(.5,.12,1.7),"96aaa4",.35);keyboard.rotation.z=side*.12
			for i in 4:
				Art.box(station,"KeyboardRow",Vector3(-side*.64,1.48,-.55+i*.35),Vector3(.20,.025,.25),"30434b")
				Art.box(station,"CoolingSlot",Vector3(-side*.34,.9,-.60+i*.4),Vector3(.025,.09,.2),"263c47")
			Art.cylinder(station,"Cable",Vector3(.1,3.6,.8),.05,2.1,"b49361",-1,.5)
			var body:=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;station.add_child(body)
			var col:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(.8,2.8,2.3);col.shape=shape;col.position=Vector3(0,1.8,0);body.add_child(col)
			for i in 3:
				Art.ball(station,"StatusLamp",Vector3(-side*.38,3.0,-.45+i*.45),Vector3(.08,.08,.08),"71d4a7" if i!=index else "edc57e",.7)

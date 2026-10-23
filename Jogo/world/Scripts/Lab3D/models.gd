extends RefCounted
## Editable, fully volumetric low-poly models. The generator packs these rigs
## into native scenes; no character is a billboard or a sprite facing camera.
static var _materials:Dictionary={}
static func material(color:String,metal:float=0.0,glow:float=0.0) -> StandardMaterial3D:
	var key:=color+str(metal)+str(glow)
	if _materials.has(key):return _materials[key]
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color(color);mat.metallic=metal;mat.roughness=.68
	if glow>0:mat.emission_enabled=true;mat.emission=Color(color);mat.emission_energy_multiplier=glow
	_materials[key]=mat;return mat
static func piece(parent:Node3D,name:String,at:Vector3,mesh:Mesh,color:String,metal:float=0.0,glow:float=0.0) -> MeshInstance3D:
	var node:=MeshInstance3D.new();node.name=name;node.mesh=mesh;node.material_override=material(color,metal,glow);node.position=at;parent.add_child(node,true);return node
static func box(parent:Node3D,name:String,at:Vector3,size:Vector3,color:String,metal:float=0,glow:float=0) -> MeshInstance3D:
	var mesh:=BoxMesh.new();mesh.size=size;return piece(parent,name,at,mesh,color,metal,glow)
static func bevel(parent:Node3D,name:String,at:Vector3,size:Vector3,color:String,b:float=.08) -> MeshInstance3D:
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h:=size*.5;b=minf(b,minf(h.x,minf(h.y,h.z))*.7)
	var axes:=[Vector3.RIGHT,Vector3.UP,Vector3.BACK]
	for axis in 3:
		var u:int=(axis+1)%3;var v:int=(axis+2)%3
		for sign_value in [-1.0,1.0]:
			var center:Vector3=axes[axis]*h[axis]*sign_value
			_quad(surface,[center-axes[u]*(h[u]-b)-axes[v]*(h[v]-b),center+axes[u]*(h[u]-b)-axes[v]*(h[v]-b),center+axes[u]*(h[u]-b)+axes[v]*(h[v]-b),center-axes[u]*(h[u]-b)+axes[v]*(h[v]-b)],axes[axis]*sign_value)
	for a in 3:
		for c in range(a+1,3):
			var rem:=3-a-c
			for sa in [-1.0,1.0]:
				for sc in [-1.0,1.0]:
					var p:Vector3=axes[a]*h[a]*sa+axes[c]*(h[c]-b)*sc
					var q:Vector3=axes[a]*(h[a]-b)*sa+axes[c]*h[c]*sc
					_quad(surface,[p-axes[rem]*(h[rem]-b),p+axes[rem]*(h[rem]-b),q+axes[rem]*(h[rem]-b),q-axes[rem]*(h[rem]-b)],(axes[a]*sa+axes[c]*sc).normalized())
	for sx in [-1.0,1.0]:
		for sy in [-1.0,1.0]:
			for sz in [-1.0,1.0]:_triangle(surface,[Vector3(h.x*sx,(h.y-b)*sy,(h.z-b)*sz),Vector3((h.x-b)*sx,h.y*sy,(h.z-b)*sz),Vector3((h.x-b)*sx,(h.y-b)*sy,h.z*sz)],Vector3(sx,sy,sz).normalized())
	return piece(parent,name,at,surface.commit(),color,.25)
static func _quad(surface:SurfaceTool,points:Array,normal:Vector3) -> void:
	_triangle(surface,[points[0],points[1],points[2]],normal);_triangle(surface,[points[0],points[2],points[3]],normal)
static func _triangle(surface:SurfaceTool,points:Array,normal:Vector3) -> void:
	if (points[1]-points[0]).cross(points[2]-points[0]).dot(normal)>0:
		var swap:Vector3=points[1];points[1]=points[2];points[2]=swap
	for p:Vector3 in points:surface.set_normal(normal);surface.add_vertex(p)
static func ball(parent:Node3D,name:String,at:Vector3,size:Vector3,color:String,glow:float=0) -> MeshInstance3D:
	var mesh:=SphereMesh.new();mesh.radial_segments=20;mesh.rings=10
	var node:=piece(parent,name,at,mesh,color,0,glow);node.scale=size;return node
static func cylinder(parent:Node3D,name:String,at:Vector3,radius:float,height:float,color:String,top:float=-1,metal:float=0) -> MeshInstance3D:
	var mesh:=CylinderMesh.new();mesh.radial_segments=12;mesh.rings=1;mesh.bottom_radius=radius;mesh.top_radius=radius if top<0 else top;mesh.height=height
	return piece(parent,name,at,mesh,color,metal)
static func ring(parent:Node3D,name:String,at:Vector3,radius:float,color:String,glow:float=0) -> MeshInstance3D:
	var mesh:=TorusMesh.new();mesh.inner_radius=radius*.85;mesh.outer_radius=radius;mesh.rings=20;mesh.ring_segments=6
	return piece(parent,name,at,mesh,color,.35,glow)
static func pivot(parent:Node3D,name:String,at:Vector3) -> Node3D:
	var node:=Node3D.new();node.name=name;node.position=at;parent.add_child(node,true);return node
static func label(parent:Node3D,text:String,at:Vector3,size:int=36,color:String="e9e6cf") -> Label3D:
	var node:=Label3D.new();node.text=text;node.position=at;node.font_size=size;node.pixel_size=.009;node.modulate=Color(color);node.outline_modulate=Color("0d1a27");node.outline_size=6;node.no_depth_test=false;parent.add_child(node);return node
static func screen(node:MeshInstance3D) -> void:
	var shader:=ShaderMaterial.new();shader.shader=preload("res://world/Scripts/Lab3D/monitor.gdshader");node.material_override=shader
static func badge(parent:Node3D,at:Vector3,scale:float=1.0) -> Node3D:
	var root:=pivot(parent,"GoldBadge",at);root.scale=Vector3.ONE*scale
	var outer:=cylinder(root,"Shield",Vector3.ZERO,.15,.055,"dfb65e",-1,.5);outer.rotation.x=PI/2;outer.scale.x=.8
	var inner:=cylinder(root,"Inset",Vector3(0,0,-.033),.105,.018,"122b30");inner.rotation.x=PI/2
	label(root,"C",Vector3(0,-.01,-.06),20,"ffe6a0").rotation.y=PI;return root
static func character(kind:String) -> Node3D:
	var root:=Node3D.new();root.name=kind.capitalize();root.set_meta("model_kind",kind)
	var rig:=pivot(root,"Rig",Vector3.ZERO)
	var fur:="718394";var cream:="f1d7a3";var body:="657787"
	if kind=="wolf":fur="5b596b";cream="bcb9b3";body="25313f"
	elif kind=="largato":fur="86b93b";cream="d7e491";body="e2e0d2"
	elif kind=="urso":fur="88603e";cream="ceab77";body="88603e"
	elif kind=="jose":fur="dfbc78";cream="fff1be";body="bca16e"
	elif kind=="oliver":fur="a78b7a";cream="e6c19b";body="8e3a40"
	elif kind=="technician":fur="799097";cream="d7dfd3";body="35777e"
	elif kind=="mutant":fur="a264ae";cream="d6a1da";body="794e99"
	elif kind=="lizard":fur="64a188";cream="d3d999";body="64a188"
	var torso:=pivot(rig,"Torso",Vector3(0,1.0,0));ball(torso,"Body",Vector3.ZERO,Vector3(.78,.91,.6),body)
	ball(torso,"Chest",Vector3(0,.03,-.235),Vector3(.52,.6,.13),cream if kind in ["nico","urso","jose","lizard","mutant"] else body)
	var head:=pivot(rig,"Head",Vector3(0,1.68,-.06));ball(head,"Fur",Vector3.ZERO,Vector3(.9,.83,.78),fur)
	ball(head,"Muzzle",Vector3(0,-.19,-.37),Vector3(.57,.36,.33),cream)
	ball(head,"Nose",Vector3(0,-.12,-.55),Vector3(.18,.14,.14),"15202a")
	for side in [-1.0,1.0]:
		var eye_x:float=side*.205
		if kind=="nico":ball(head,"Mask",Vector3(eye_x,.025,-.334),Vector3(.4,.29,.18),"26303e")
		ball(head,"Eye",Vector3(eye_x,.035,-.414),Vector3(.2,.25,.085),"fff1cb")
		ball(head,"Pupil",Vector3(eye_x-.025,.025,-.457),Vector3(.075,.16,.05),"152335")
		ball(head,"EyeLight",Vector3(eye_x-.04,.065,-.483),Vector3(.033,.05,.025),"ffffff")
		var ear:=cylinder(head,"Ear",Vector3(side*.34,.37,.03),.2,.4,fur,0);ear.rotation.z=-side*.25;ear.scale.z=.6
		var inner:=cylinder(head,"InnerEar",Vector3(side*.34,.38,-.065),.115,.27,"deaa91",0);inner.rotation.z=-side*.25;inner.scale.z=.3
		var arm:=pivot(rig,"ArmL" if side<0 else "ArmR",Vector3(side*.46,1.32,0))
		ball(arm,"Sleeve",Vector3(0,-.22,0),Vector3(.27,.58,.27),body if kind in ["wolf","largato","technician","oliver"] else fur)
		ball(arm,"Hand",Vector3(0,-.52,-.015),Vector3(.28,.29,.29),"e5e9dc" if kind in ["largato","technician"] else cream)
		var leg:=pivot(rig,"LegL" if side<0 else "LegR",Vector3(side*.22,.67,0))
		ball(leg,"Leg",Vector3(0,-.2,0),Vector3(.3,.57,.32),"25313f" if kind=="wolf" else fur)
		ball(leg,"Foot",Vector3(0,-.54,-.13),Vector3(.38,.21,.58),"172534" if kind=="wolf" else cream)
	var tail:=pivot(rig,"Tail",Vector3(0,.67,.25))
	for i in (7 if kind in ["nico","largato","lizard"] else 3):
		var t:=float(i)/6
		ball(tail,"TailSegment",Vector3(0,t*.38,t*.95),Vector3(.35-t*.16,.36-t*.18,.44-t*.18),"2a3542" if kind=="nico" and i%2==0 else fur)
	if kind=="nico":
		cylinder(torso,"Scarf",Vector3(0,.4,-.02),.31,.15,"3ec6a0")
		var scarf:=box(torso,"ScarfTip",Vector3(.13,.13,-.38),Vector3(.15,.49,.06),"38ad8d");scarf.rotation.z=.22
		box(torso,"Backpack",Vector3(0,.05,.37),Vector3(.56,.65,.23),"c97e32")
		for side in [-1.0,1.0]:box(torso,"Strap",Vector3(side*.25,.02,-.28),Vector3(.075,.59,.055),"d79849")
	elif kind=="wolf":
		box(torso,"Shirt",Vector3(0,.19,-.31),Vector3(.24,.48,.04),"f3e7ce")
		box(torso,"Tie",Vector3(0,.11,-.35),Vector3(.10,.41,.035),"9b4855")
		badge(torso,Vector3(-.25,.27,-.30),.8)
		for side in [-1.0,1.0]:
			var brow:=box(head,"Brow",Vector3(side*.20,.2,-.39),Vector3(.29,.07,.08),"302c3d");brow.rotation.z=side*.2
	elif kind=="largato":
		for side in [-1.0,1.0]:box(torso,"Coat",Vector3(side*.24,-.19,-.05),Vector3(.34,.91,.58),"e7e8da")
		box(torso,"Shirt",Vector3(0,.19,-.30),Vector3(.22,.5,.05),"35414e")
		badge(torso,Vector3(-.26,.17,-.37),.65)
		label(torso,"LARGATO",Vector3(.25,.13,-.39),8,"1e3e43").rotation.y=PI
		ball(torso,"ChemicalStain",Vector3(-.28,-.22,-.35),Vector3(.14,.18,.035),"83b4a0")
		ball(torso,"ChemicalStain",Vector3(.23,-.4,-.35),Vector3(.13,.11,.035),"a79bb5")
		for side in [-1.0,1.0]:
			var lens:=ring(head,"Goggles",Vector3(side*.205,.06,-.47),.165,"435868");lens.rotation.x=PI/2
		box(head,"Bridge",Vector3(0,.07,-.48),Vector3(.16,.045,.04),"aabbbb",.6)
		var needle:=prop("syringe");needle.position=Vector3(0,-.64,-.15);needle.rotation.x=-.5;needle.scale=Vector3.ONE*.65;rig.get_node("ArmR").add_child(needle)
	elif kind=="jose":
		cylinder(torso,"Scarf",Vector3(0,.4,0),.31,.15,"e28c35")
		for side in [-1.0,1.0]:
			var horn:=cylinder(head,"Horn",Vector3(side*.28,.5,.09),.11,.52,"594c43",.035);horn.rotation.x=.45
		cylinder(head,"Beard",Vector3(0,-.43,-.30),.14,.32,cream,0).rotation.x=PI
	elif kind=="urso":
		torso.scale=Vector3(1.35,1.13,1.2);head.scale=Vector3(1.13,1.0,1.0)
		cylinder(torso,"Scarf",Vector3(0,.43,0),.32,.12,"4f9883")
	elif kind=="oliver":
		box(head,"Eyepatch",Vector3(-.20,.05,-.47),Vector3(.28,.23,.07),"1c2730")
		box(head,"Strap",Vector3(0,.14,-.39),Vector3(.75,.055,.12),"3a2d30")
		var band:=box(head,"Bandana",Vector3(0,.3,0),Vector3(.74,.15,.6),"aa4651");band.rotation.z=.08
	elif kind=="technician":
		ball(head,"Helmet",Vector3(0,.25,.01),Vector3(1,.48,.86),"d5a745")
		box(head,"Visor",Vector3(0,.05,-.43),Vector3(.71,.27,.12),"70d5df",.3,.25)
		var tool:=prop("syringe");tool.position=Vector3(0,-.54,-.15);tool.rotation.x=-.8;tool.scale=Vector3.ONE*.5;rig.get_node("ArmR").add_child(tool)
	elif kind=="mutant":
		for i in 3:cylinder(torso,"Spine",Vector3(0,.25-i*.22,.35),.13,.37,"89d0aa",0).rotation.x=.8
		for side in [-1.0,1.0]:ball(head,"ChemicalEye",Vector3(side*.205,.03,-.47),Vector3(.11,.2,.07),"b7ef85",.6)
	preload("res://world/Scripts/Lab3D/character_details.gd").decorate(root,kind,load("res://world/Scripts/Lab3D/models.gd"))
	_animation(root)
	return root
static func _animation(root:Node3D) -> void:
	var player:=AnimationPlayer.new();player.name="Animations";root.add_child(player)
	var library:=AnimationLibrary.new()
	for action in ["idle","run","jump","attack","hurt","talk","operate","tail"]:
		var anim:=Animation.new();anim.length=.55 if action=="run" else (.45 if action in ["attack","hurt"] else 1.8)
		anim.loop_mode=Animation.LOOP_LINEAR if action in ["idle","run","talk","operate"] else Animation.LOOP_NONE
		for joint in ["ArmL","ArmR","LegL","LegR","Head","Tail"]:
			var track:=anim.add_track(Animation.TYPE_VALUE);anim.track_set_path(track,NodePath("Rig/"+joint+":rotation"))
			for i in 5:
				var t:=float(i)/4;var rot:=Vector3.ZERO;var swing:=sin(t*TAU)
				if action=="run" and joint in ["ArmL","ArmR","LegL","LegR"]:rot.x=swing*(.75 if joint in ["LegL","ArmR"] else -.75)
				elif action=="jump":rot.x=.8 if joint.begins_with("Leg") else (1.0 if joint.begins_with("Arm") else 0.0)
				elif action=="attack" and joint=="ArmR":rot.x=sin(t*PI)*2.1
				elif action=="hurt" and joint=="Head":rot.z=sin(t*TAU)*.3
				elif action=="operate" and joint.begins_with("Arm"):rot.x=1.2+swing*.15
				elif action=="tail" and joint=="Tail":rot.y=sin(t*PI)*2.6
				elif joint=="Head":rot.z=swing*(.09 if action=="talk" else .035)
				elif joint=="Tail":rot.y=swing*.12
				anim.track_insert_key(track,t*anim.length,rot)
		var root_track:=anim.add_track(Animation.TYPE_VALUE);anim.track_set_path(root_track,NodePath("Rig:position"))
		for i in 5:anim.track_insert_key(root_track,float(i)/4*anim.length,Vector3(0,-absf(sin(float(i)/4*TAU))*(.37 if root.name=="Guardian" else .13) if action=="run" else 0,0))
		library.add_animation(action,anim)
	player.add_animation_library("",library);player.autoplay="idle"
static func prop(kind:String) -> Node3D:
	var root:=Node3D.new();root.name=kind.capitalize();root.set_meta("model_kind",kind)
	match kind:
		"keycard":
			bevel(root,"Card",Vector3.ZERO,Vector3(.95,.58,.09),"e4d9b9",.045)
			box(root,"Stripe",Vector3(0,.13,-.055),Vector3(.8,.07,.02),"3f798c")
			box(root,"Chip",Vector3(-.25,-.08,-.065),Vector3(.18,.15,.025),"d3ae59",.6)
			label(root,"C",Vector3(.18,-.08,-.07),20,"233d4b").rotation.y=PI
		"cherry":
			for side in [-1.0,1.0]:ball(root,"Fruit",Vector3(side*.15,.05,0),Vector3(.33,.36,.34),"da3e66")
			var stem:=cylinder(root,"Stem",Vector3(0,.34,0),.025,.5,"568e4e");stem.rotation.z=-.3
			ball(root,"Leaf",Vector3(.14,.52,0),Vector3(.3,.06,.12),"83b860")
		"drone":
			ball(root,"Core",Vector3.ZERO,Vector3(1,.65,.75),"293c51")
			ball(root,"Lens",Vector3(0,0,-.4),Vector3(.38,.38,.13),"6de0ed",1)
			for side in [-1.0,1.0]:
				box(root,"Arm",Vector3(side*.6,0,0),Vector3(.6,.12,.15),"90a4ab",.4)
				ring(root,"Rotor",Vector3(side*.88,.1,0),.36,"385b70")
		"syringe":
			cylinder(root,"Glass",Vector3.ZERO,.11,.55,"8fdfb6")
			for y in [-.28,.28]:cylinder(root,"Rim",Vector3(0,y,0),.15,.07,"dce6df",-1,.4)
			cylinder(root,"Needle",Vector3(0,-.52,0),.025,.43,"aebcc7",0,.7)
			box(root,"Grip",Vector3(0,.38,0),Vector3(.38,.06,.1),"3b6975")
		"terminal_heat","terminal_cold","injector":
			var accent:="f49b52" if kind=="terminal_heat" else ("66dceb" if kind=="terminal_cold" else "b9dc84")
			box(root,"Base",Vector3(0,.16,0),Vector3(1.5,.3,1.2),"26394c",.4)
			box(root,"Housing",Vector3(0,.75,0),Vector3(1.05,1.0,.8),"c1c8bf",.3)
			box(root,"Screen",Vector3(0,1.1,-.43),Vector3(.74,.43,.04),accent,0,.6)
			cylinder(root,"Indicator",Vector3(-.42,1.45,0),.08,.23,accent)
			label(root,"F" if kind=="terminal_heat" else ("G" if kind=="terminal_cold" else "LG-17"),Vector3(0,1.09,-.47),30,"132a36").rotation.y=PI
			if kind=="injector":
				for side in [-1.0,1.0]:cylinder(root,"Canister",Vector3(side*.8,1.1,0),.22,1.6,accent)
		"lever":
			box(root,"Base",Vector3(0,.25,0),Vector3(.9,.5,.7),"3c5765",.4)
			var arm:=pivot(root,"Handle",Vector3(0,.45,0));arm.rotation.x=-.55
			cylinder(arm,"Shaft",Vector3(0,.34,0),.06,.7,"bdcac8",-1,.5)
			box(arm,"Grip",Vector3(0,.72,0),Vector3(.55,.13,.14),"d9a851")
		"crate":
			box(root,"Crate",Vector3(0,.7,0),Vector3(1.4,1.4,1.4),"7c9a9f",.4)
			for x in [-.64,.64]:box(root,"Brace",Vector3(x,.7,-.72),Vector3(.12,1.4,.08),"d5d3ba")
		"tank":
			for y in [.2,3.0]:cylinder(root,"Cap",Vector3(0,y,0),1.05,.3,"415d70",-1,.5)
			cylinder(root,"Liquid",Vector3(0,1.6,.12),.78,2.55,"397c75")
			for side in [-1.0,1.0]:box(root,"Brace",Vector3(side*.92,1.6,0),Vector3(.16,2.8,.2),"a1b5b1",.5)
			box(root,"Window",Vector3(0,1.6,-.76),Vector3(1.3,2.35,.05),"66ab9b",.2,.15)
		"egg":
			ball(root,"Shell",Vector3(0,1.3,0),Vector3(1.7,2.5,1.7),"c7c5b2")
			for i in 5:
				var vein:=box(root,"Crack",Vector3(sin(i)*.35,.65+i*.28,-.77),Vector3(.07,.4,.05),"86e8bb",0,1.5);vein.rotation.z=.5 if i%2 else -.5
		"flag":
			cylinder(root,"Pole",Vector3(0,1.1,0),.055,2.2,"b1bdc3",-1,.6)
			ball(root,"Finial",Vector3(0,2.25,0),Vector3(.16,.16,.16),"ead18a")
			box(root,"Flag",Vector3(.45,1.85,0),Vector3(.9,.46,.035),"5bcfc4",0,.2)
			cylinder(root,"Base",Vector3(0,.1,0),.35,.2,"2d4555")
		"wagon":
			box(root,"Chassis",Vector3(0,.7,0),Vector3(2.9,.9,1.9),"79513a")
			box(root,"Counter",Vector3(0,1.3,-.55),Vector3(2.9,.2,1.0),"b98952")
			for side in [-1.0,1.0]:
				cylinder(root,"Post",Vector3(side*1.25,1.75,.25),.07,2.0,"885f3c")
				var wheel:=cylinder(root,"Wheel",Vector3(side*1.5,.4,.3),.45,.16,"3b3432",-1,.2);wheel.rotation.z=PI/2
			for i in 6:box(root,"Awning",Vector3(-1.25+i*.5,2.8,-.1),Vector3(.5,.16,2.3),"d8c28a" if i%2 else "487d7d")
	preload("res://world/Scripts/Lab3D/prop_details.gd").decorate(root,kind,load("res://world/Scripts/Lab3D/models.gd"))
	root.set_meta("detail_revision",76)
	return root
static func guardian() -> Node3D:
	var root:=Node3D.new();root.name="Guardian"
	var rig:=pivot(root,"Rig",Vector3.ZERO)
	var torso:=pivot(rig,"Torso",Vector3(0,2.65,0));ball(torso,"CoreArmor",Vector3.ZERO,Vector3(2.7,3.0,1.9),"343049")
	bevel(torso,"ChestPlate",Vector3(0,.25,-.67),Vector3(2.0,1.7,.55),"514559",.18)
	bevel(torso,"Belt",Vector3(0,-.95,-.15),Vector3(2.15,.48,1.5),"292d40",.14)
	var head:=pivot(rig,"Head",Vector3(0,4.25,-.2));bevel(head,"Helmet",Vector3.ZERO,Vector3(1.75,1.4,1.45),"454057",.22)
	bevel(head,"Jaw",Vector3(0,-.5,-.4),Vector3(1.5,.45,1.15),"2b3043",.10)
	pivot(rig,"Tail",Vector3.ZERO)
	for side in [-1.0,1.0]:
		var horn:=cylinder(head,"Horn",Vector3(side*.8,.9,.15),.32,1.5,"726078",.04);horn.rotation.z=-side*.38
		ball(head,"Eye",Vector3(side*.4,.05,-.76),Vector3(.32,.17,.09),"ffac58",1)
		var brow:=bevel(head,"Brow",Vector3(side*.4,.21,-.74),Vector3(.64,.18,.24),"292d42",.045);brow.rotation.z=side*.2
		var arm:=pivot(rig,"ArmL" if side<0 else "ArmR",Vector3(side*1.6,3.65,-.05))
		ball(arm,"Shoulder",Vector3(0,-.15,0),Vector3(1.15,1.1,1.2),"5d4a61")
		bevel(arm,"Gauntlet",Vector3(0,-1.05,-.12),Vector3(.95,1.45,1.05),"302f46",.18)
		bevel(arm,"Fist",Vector3(0,-1.75,-.2),Vector3(1.1,.65,1.2),"454057",.15)
		var leg:=pivot(rig,"LegL" if side<0 else "LegR",Vector3(side*.67,1.8,0))
		bevel(leg,"Leg",Vector3(0,-.8,0),Vector3(.86,1.6,1.0),"393247",.12)
		bevel(leg,"Foot",Vector3(0,-1.6,-.38),Vector3(1.0,.4,1.7),"242a3b",.10)
		for j in 3:box(leg,"Toe",Vector3(-.3+j*.3,-1.56,-1.2),Vector3(.16,.18,.15),"a18e83")
		for i in 6:
			var link:=ring(arm,"Chain",Vector3(0,-1.45-i*.16,-.25),.16,"b2a6a3");link.rotation.x=PI/2;link.rotation.y=i%2*PI/2
		for j in 2:box(arm,"LavaCrack",Vector3(side*.4,-.75-j*.34,-.61),Vector3(.08,.4,.04),"e98e4f",0,.4).rotation.z=side*.4
	box(torso,"Core",Vector3(0,.25,-.97),Vector3(.25,1.2,.05),"e99b58",0,.65)
	preload("res://world/Scripts/Lab3D/guardian_details.gd").decorate(root,load("res://world/Scripts/Lab3D/models.gd"))
	root.set_meta("detail_revision",76)
	_animation(root)
	return root
static func instantiate(kind:String) -> Node3D:
	if kind in ["nico","largato"]:
		var imported:="res://world/Models/ImportedV81/"+kind+".tscn"
		if ResourceLoader.exists(imported):return load(imported).instantiate()
	var path:="res://world/Models/Lab3D/"+kind+".tscn"
	if ResourceLoader.exists(path):return load(path).instantiate()
	return guardian() if kind=="guardian" else (character(kind) if kind in ["nico","wolf","largato","urso","jose","oliver","technician","mutant","lizard"] else prop(kind))

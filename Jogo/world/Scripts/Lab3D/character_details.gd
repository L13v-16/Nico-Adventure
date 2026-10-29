extends RefCounted
## Character-specific silhouettes and details, all attached to animated pivots.
static func decorate(root:Node3D,kind:String,art:Script) -> void:
	var rig:Node3D=root.get_node("Rig");var head:Node3D=rig.get_node("Head");var torso:Node3D=rig.get_node("Torso");var tail:Node3D=rig.get_node("Tail")
	var fur:String={"nico":"718394","wolf":"5b596b","largato":"86b93b","urso":"88603e","jose":"dfbc78","oliver":"84909a","technician":"799097","mutant":"a264ae","lizard":"64a188"}[kind]
	var cream:String={"nico":"f1d7a3","wolf":"bcb9b3","largato":"d7e491","urso":"ceab77","jose":"fff1be","oliver":"e6c19b"}.get(kind,"d7dfd3")
	_remove(head,["Ear","InnerEar"])
	for side in [-1.0,1.0]:
		if kind in ["urso","oliver"]:
			var size:=.38 if kind=="oliver" else .29
			art.ball(head,"RoundEar",Vector3(side*.37,.34,0),Vector3(size,size,.18),fur)
			art.ball(head,"EarInset",Vector3(side*.37,.35,-.085),Vector3(size*.69,size*.69,.045),"d89b9d" if kind=="oliver" else "b18a60")
		elif kind=="jose":
			var ear:=_patch(head,"GoatEar",[Vector2(0,0),Vector2(.15,.10),Vector2(.43,.02),Vector2(.29,-.11),Vector2(.05,-.09)],.06,fur,art);ear.position=Vector3(side*.31,.16,-.04);ear.scale.x=side
			art.ball(ear,"EarInset",Vector3(.23,-.01,-.04),Vector3(.28,.09,.025),"c99385")
		else:
			var ear:=_patch(head,"SculptedEar",[Vector2(-.15,0),Vector2(.14,-.01),Vector2(.16,.12),Vector2(.10,.38),Vector2(-.02,.29),Vector2(-.16,.14)],.14,fur,art);ear.position=Vector3(side*.32,.28,.01);ear.rotation.z=-side*.15
			var inset:=_patch(ear,"EarInset",[Vector2(-.085,.055),Vector2(.085,.045),Vector2(.065,.27),Vector2(-.035,.18)],.018,"d3a191",art);inset.position.z=-.077
		if kind not in ["technician"]:
			var brow:MeshInstance3D=art.ball(head,"Eyelid",Vector3(side*.205,.165,-.393),Vector3(.25,.08,.10),fur);brow.rotation.z=side*(.12 if kind in ["wolf","largato"] else -.08)
			art.ball(head,"Iris",Vector3(side*.205-.025,.025,-.461),Vector3(.115,.185,.023),"d7ad52" if kind in ["nico","largato","wolf"] else "825b3c")
			art.ball(head,"FocusedPupil",Vector3(side*.205-.025,.025,-.478),Vector3(.043 if kind=="largato" else .061,.135,.018),"142330")
			art.ball(head,"Catchlight",Vector3(side*.205-.043,.067,-.49),Vector3(.032,.043,.018),"fff5dc")
			for i in (0 if kind in ["urso","oliver"] else 2):
				var tuft:=_patch(head,"CheekFur",[Vector2(0,.12),Vector2(.18,.05),Vector2(.24,-.08),Vector2(.10,-.04),Vector2(.20,-.17),Vector2(-.01,-.10)],.09,fur,art);tuft.position=Vector3(side*(.32+i*.014),-.14-i*.08,-.12);tuft.scale.x=side
		# Toe separation and a thumb make hands/feet read as paws at close range.
		var arm:Node3D=rig.get_node("ArmL" if side<0 else "ArmR")
		art.ball(arm,"Thumb",Vector3(-side*.12,-.50,-.09),Vector3(.13,.17,.15),cream if kind not in ["largato","technician"] else "becfc7")
		var leg:Node3D=rig.get_node("LegL" if side<0 else "LegR")
		if kind=="jose":
			_remove(leg,["Foot"])
			for toe in [-1.0,1.0]:_soft_box(leg,"ClovenHoof",Vector3(toe*.09,-.54,-.13),Vector3(.16,.20,.44),"4a4240",art,.04)
		else:
			for toe in [-1.0,1.0]:art.box(leg,"ToeSeam",Vector3(toe*.072,-.52,-.416),Vector3(.012,.065,.016),"8e795f" if kind not in ["wolf","largato","technician"] else "111d29")
	# Mouth inset and lip line are distinct from the nose and muzzle.
	art.ball(head,"MouthLine",Vector3(0,-.285,-.509),Vector3(.30,.027,.027),"59464a")
	art.box(head,"Philtrum",Vector3(0,-.22,-.535),Vector3(.018,.09,.018),"59464a")
	_remove(tail,["TailSegment"])
	match kind:
		"nico":
			_tail(tail,[Vector3.ZERO,Vector3(0,-.02,.23),Vector3(.02,.04,.44),Vector3(.04,.15,.64),Vector3(.05,.30,.80),Vector3(.04,.46,.89),Vector3(0,.59,.92)],[.16,.18,.18,.17,.15,.12,.025],["2a3542",fur],art)
			for side in [-1.0,1.0]:
				art.ball(head,"MaskWing",Vector3(side*.33,.035,-.275),Vector3(.31,.25,.19),"26303e")
				for i in 3:art.ball(head,"WhiskerDot",Vector3(side*(.16+i*.038),-.20-i*.012,-.528+i*.022),Vector3(.022,.022,.012),"5e5550")
			var tuft:=_patch(head,"Forelock",[Vector2(-.16,0),Vector2(.17,0),Vector2(.25,.18),Vector2(.04,.12),Vector2(-.035,.29),Vector2(-.10,.12),Vector2(-.23,.19)],.18,"536676",art);tuft.position=Vector3(0,.33,-.07)
			_remove(torso,["Backpack","ScarfTip"])
			_soft_box(torso,"Satchel",Vector3(0,.05,.37),Vector3(.61,.69,.28),"b97133",art,.09)
			_soft_box(torso,"SatchelFlap",Vector3(0,.24,.53),Vector3(.60,.23,.07),"db9c48",art,.04)
			_soft_box(torso,"SatchelPocket",Vector3(0,-.10,.53),Vector3(.40,.23,.065),"c78439",art,.035)
			art.box(torso,"Buckle",Vector3(0,.11,.582),Vector3(.13,.13,.025),"e3c47c",.6)
			art.box(torso,"BuckleInset",Vector3(0,.11,.599),Vector3(.065,.055,.009),"624c36")
			for side in [-1.0,1.0]:
				art.box(torso,"SatchelStitch",Vector3(side*.23,.03,.523),Vector3(.013,.32,.014),"f0c57b")
				art.ball(torso,"StrapRivet",Vector3(side*.25,.15,-.316),Vector3(.053,.053,.025),"d8b770")
			art.ball(torso,"ScarfKnot",Vector3(.22,.34,-.30),Vector3(.20,.19,.17),"58d1ac")
			var scarf:=_patch(torso,"ScarfFold",[Vector2(-.10,.22),Vector2(.08,.20),Vector2(.11,-.22),Vector2(0,-.16),Vector2(-.07,-.28)],.055,"38ad8d",art);scarf.position=Vector3(.20,.03,-.35);scarf.rotation.z=.15
			art.box(scarf,"FoldHighlight",Vector3(-.02,.02,-.034),Vector3(.025,.31,.012),"68d7b4")
		"jose":
			_remove(head,["Horn","Beard"])
			for side in [-1.0,1.0]:
				var points:=[Vector3(side*.25,.32,.05),Vector3(side*.29,.55,.11),Vector3(side*.31,.68,.27),Vector3(side*.32,.67,.44),Vector3(side*.31,.54,.56)]
				_tail(head,points,[.12,.115,.09,.065,.012],["645849","9a8870"],art,"CurvedHorn")
				art.ball(head,"CreamFace",Vector3(side*.29,-.17,-.29),Vector3(.29,.41,.17),"f7e4b6")
			for i in 3:
				var beard:=_patch(head,"BeardTuft",[Vector2(-.07,.12),Vector2(.08,.12),Vector2(.04,-.16),Vector2(0,-.23),Vector2(-.05,-.10)],.09,"f4e1b8",art);beard.position=Vector3((i-1)*.085,-.40,-.29)
			art.ball(torso,"ScarfKnot",Vector3(.22,.32,-.29),Vector3(.18,.17,.16),"f4b85e")
			var scarf:=_patch(torso,"OrangeScarfTail",[Vector2(-.07,.18),Vector2(.09,.16),Vector2(.17,-.19),Vector2(.05,-.14),Vector2(0,-.23)],.045,"dd8a35",art);scarf.position=Vector3(.23,.08,-.34)
			art.ball(tail,"GoatTail",Vector3(0,.04,.10),Vector3(.20,.33,.35),fur)
		"urso":
			art.ball(tail,"BearTail",Vector3(0,-.10,.05),Vector3(.23,.22,.19),fur)
			for side in [-1.0,1.0]:
				var arm:Node3D=rig.get_node("ArmL" if side<0 else "ArmR");arm.scale=Vector3(1.15,1,1.12)
				art.ball(head,"MuzzleCheek",Vector3(side*.18,-.21,-.35),Vector3(.30,.26,.24),cream)
			art.ball(torso,"ScarfKnot",Vector3(.29,.33,-.32),Vector3(.22,.20,.17),"68b4a7")
			_soft_box(torso,"ScarfTail",Vector3(.30,.04,-.38),Vector3(.17,.47,.05),"4f9883",art,.02)
		"oliver":
			_recolor(head,"Fur",fur,art);_recolor(torso,"Body","453e52",art)
			_tail(tail,[Vector3.ZERO,Vector3(.02,-.25,.25),Vector3(.07,-.47,.54),Vector3(.23,-.49,.83),Vector3(.44,-.35,1.05),Vector3(.43,-.18,1.20),Vector3(.28,-.10,1.24)],[.065,.062,.055,.05,.045,.032,.01],["c78f91"],art)
			for side in [-1.0,1.0]:
				var lapel:=_patch(torso,"VestLapel",[Vector2(0,.28),Vector2(.22,.10),Vector2(.09,-.20)],.045,"817168",art);lapel.position=Vector3(side*.10,.10,-.30);lapel.scale.x=side
				var leg:Node3D=rig.get_node("LegL" if side<0 else "LegR");_recolor(leg,"Leg","354c6a",art)
				_recolor(rig.get_node("ArmL" if side<0 else "ArmR"),"Sleeve",fur,art)
				art.ball(head,"Whisker",Vector3(side*.29,-.19,-.35),Vector3(.33,.012,.018),"d5c6b1").rotation.z=side*.18
			art.ball(head,"EyePatchRivet",Vector3(-.20,.05,-.516),Vector3(.04,.04,.025),"c4a662")
			art.ball(head,"BandanaKnot",Vector3(.32,.25,.22),Vector3(.21,.19,.19),"a53d4b")
			for i in 2:art.box(head,"BandanaTail",Vector3(.34+i*.08,.09,.24),Vector3(.10,.33,.07),"a53d4b").rotation.z=.18+i*.28
			for i in 3:art.ball(torso,"VestButton",Vector3(0,.18-i*.16,-.314),Vector3(.065,.065,.025),"dbb770")
		"wolf":
			head.get_node("Muzzle").scale.z*=1.4;head.get_node("Muzzle").position.z-=.06;head.get_node("Nose").position.z-=.11
			_suit(torso,art,"344251","9b4855")
			for side in [-1.0,1.0]:
				var arm:Node3D=rig.get_node("ArmL" if side<0 else "ArmR");art.cylinder(arm,"Cuff",Vector3(0,-.43,0),.14,.09,"d8d9cd")
				art.ball(arm,"CuffLink",Vector3(side*.14,-.43,-.025),Vector3(.045,.06,.06),"d8b56b")
			_tail(tail,[Vector3.ZERO,Vector3(0,-.1,.25),Vector3(0,-.08,.48),Vector3(0,.06,.67)],[.15,.19,.14,.02],[fur,"9a9a9d"],art)
		"largato":
			torso.scale=Vector3(.87,1.07,.95)
			_suit(torso,art,"f0efe0","35414e")
			for side in [-1.0,1.0]:
				_soft_box(torso,"CoatPocket",Vector3(side*.26,-.25,-.36),Vector3(.24,.24,.035),"d1d6c8",art,.025)
				for i in 3:art.ball(head,"CheekScale",Vector3(side*(.32+i*.025),-.08+i*.11,-.25+i*.04),Vector3(.08,.12,.05),"5c8f3c")
				var arm:Node3D=rig.get_node("ArmL" if side<0 else "ArmR");_recolor(arm,"Hand","465c61",art)
				art.cylinder(arm,"GloveCuff",Vector3(0,-.40,0),.145,.10,"a3b9b4")
			art.box(torso,"Pen",Vector3(.24,-.06,-.39),Vector3(.025,.19,.025),"b77d42")
			_tail(tail,[Vector3.ZERO,Vector3(0,-.04,.30),Vector3(.04,.04,.60),Vector3(.16,.18,.86),Vector3(.33,.38,1.05),Vector3(.43,.60,1.10),Vector3(.39,.77,1.01)],[.17,.155,.13,.10,.07,.04,.009],["6b9b3b","82b34a"],art)
			for i in 4:art.cylinder(tail,"TailCrest",Vector3(.03+i*.03,.08+i*.055,.20+i*.18),.09-i*.012,.22-i*.025,"aecb67",0).rotation.x=.3
		"technician":
			for side in [-1.0,1.0]:
				art.box(torso,"Reflector",Vector3(side*.25,.14,-.30),Vector3(.10,.54,.028),"d0c99a")
				art.cylinder(head,"HelmetRivet",Vector3(side*.38,.25,-.23),.045,.03,"8b9e9f").rotation.x=PI/2
			_soft_box(torso,"UtilityBelt",Vector3(0,-.31,0),Vector3(.80,.13,.60),"334652",art,.035)
			_tail(tail,[Vector3.ZERO,Vector3(0,-.12,.20),Vector3(0,-.05,.38)],[.12,.10,.01],[fur],art)
		"mutant","lizard":
			_tail(tail,[Vector3.ZERO,Vector3(0,-.09,.30),Vector3(.05,0,.62),Vector3(.18,.20,.86),Vector3(.25,.40,.92)],[.17,.15,.11,.06,.01],[fur,"548575" if kind=="lizard" else "b47bc4"],art)
			for i in 4:art.ball(torso,"ScalePatch",Vector3((i%2-.5)*.48,.23-(i/2)*.23,-.29),Vector3(.12,.13,.035),"88b293" if kind=="lizard" else "c6a0c9")
	root.set_meta("detail_revision",76)

static func _remove(parent:Node,names:Array) -> void:
	for child in parent.get_children():
		for prefix:String in names:
			if String(child.name).begins_with(prefix):child.free();break
static func _recolor(parent:Node,name:String,color:String,art:Script) -> void:
	var mesh:=parent.get_node_or_null(name) as MeshInstance3D
	if mesh!=null:mesh.material_override=art.material(color)
static func _soft_box(parent:Node3D,name:String,at:Vector3,size:Vector3,color:String,art:Script,rounding:float=.04) -> MeshInstance3D:
	var node:MeshInstance3D=art.bevel(parent,name,at,size,color,rounding);node.material_override=art.material(color);return node
static func _patch(parent:Node3D,name:String,outline:Array,depth:float,color:String,art:Script) -> MeshInstance3D:
	var mesh:=SurfaceTool.new();mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center:=Vector2.ZERO
	for point:Vector2 in outline:center+=point/outline.size()
	for i in outline.size():
		var a:Vector2=outline[i];var b:Vector2=outline[(i+1)%outline.size()]
		for side in [-1.0,1.0]:art._triangle(mesh,[Vector3(center.x,center.y,side*depth*.5),Vector3(a.x,a.y,side*depth*.5),Vector3(b.x,b.y,side*depth*.5)],Vector3(0,0,side))
		art._quad(mesh,[Vector3(a.x,a.y,-depth*.5),Vector3(b.x,b.y,-depth*.5),Vector3(b.x,b.y,depth*.5),Vector3(a.x,a.y,depth*.5)],Vector3(b.y-a.y,a.x-b.x,0).normalized())
	return art.piece(parent,name,Vector3.ZERO,mesh.commit(),color)
static func _suit(torso:Node3D,art:Script,color:String,tie:String) -> void:
	for side in [-1.0,1.0]:
		var lapel:=_patch(torso,"TailoredLapel",[Vector2(0,.33),Vector2(.27,.13),Vector2(.15,-.01),Vector2(.22,-.10),Vector2(.045,-.34)],.065,color,art);lapel.position=Vector3(side*.065,.08,-.32);lapel.scale.x=side
		art.ball(torso,"SeamButton",Vector3(side*.09,-.17,-.365),Vector3(.04,.04,.018),"b9bba9")
	var neck:=_patch(torso,"TieKnot",[Vector2(-.055,.07),Vector2(.055,.07),Vector2(.06,-.02),Vector2(0,-.08),Vector2(-.06,-.02)],.025,tie,art);neck.position=Vector3(0,.32,-.36)
static func _tail(parent:Node3D,points:Array,radii:Array,colors:Array,art:Script,name:String="TailMesh") -> void:
	# Continuous rings avoid the old bead-like silhouette; alternating surfaces form bands.
	for c in colors.size():
		var mesh:=SurfaceTool.new();mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
		for segment in points.size()-1:
			if segment%colors.size()!=c:continue
			for j in 16:
				var corners:Array[Vector3]=[];var normals:Array[Vector3]=[]
				for entry in [[segment,j],[segment+1,j],[segment+1,j+1],[segment,j+1]]:
					var k:int=entry[0];var angle:float=entry[1]*TAU/16
					var tangent:Vector3=(points[mini(k+1,points.size()-1)]-points[maxi(k-1,0)]).normalized()
					var x:=Vector3.RIGHT;var y:Vector3=tangent.cross(x).normalized();x=y.cross(tangent).normalized()
					var normal:Vector3=x*cos(angle)+y*sin(angle);corners.append(points[k]+normal*radii[k]);normals.append(normal)
				for indices in [[0,1,2],[0,2,3]]:
					for idx:int in indices:mesh.set_normal(normals[idx]);mesh.add_vertex(corners[idx])
		art.piece(parent,name+str(c),Vector3.ZERO,mesh.commit(),colors[c])
	for k in [0,points.size()-1]:
		var mesh:=SurfaceTool.new();mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
		var tangent:Vector3=(points[mini(k+1,points.size()-1)]-points[maxi(k-1,0)]).normalized()
		var y:Vector3=tangent.cross(Vector3.RIGHT).normalized();var x:Vector3=y.cross(tangent).normalized()
		for j in 16:
			var a:float=j*TAU/16;var b:float=(j+1)*TAU/16
			art._triangle(mesh,[points[k],points[k]+(x*cos(a)+y*sin(a))*radii[k],points[k]+(x*cos(b)+y*sin(b))*radii[k]],tangent*(-1 if k==0 else 1))
		art.piece(parent,name+"Cap"+str(k),Vector3.ZERO,mesh.commit(),colors[0 if k==0 else (k-1)%colors.size()])

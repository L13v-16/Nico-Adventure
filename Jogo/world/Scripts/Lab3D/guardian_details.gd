extends RefCounted
## Armor is attached to the original animated pivots. The shoulder tops remain
## clear: the arrival cinematic mounts Nico and José at ArmL/R local Y = .38.
static func decorate(root:Node3D,art:Script) -> void:
	var torso:=root.get_node("Rig/Torso") as Node3D
	var head:=root.get_node("Rig/Head") as Node3D
	# Overlapping obsidian plates frame a readable incandescent chest sigil.
	for side in [-1.0,1.0]:
		for i in 3:
			var plate:=art.bevel(torso,"ObsidianChestPlate",Vector3(side*(.53-i*.035),.77-i*.48,-1.0),Vector3(.77-i*.055,.37,.15),"25293b",.055) as MeshInstance3D
			plate.rotation.z=side*(.09-i*.025)
		art.bevel(torso,"HipPlate",Vector3(side*.91,-1.05,-.33),Vector3(.35,.52,1.03),"373448",.075)
	var old_core:=torso.get_node_or_null("Core") as GeometryInstance3D
	if old_core!=null:old_core.hide()
	var frame:=art.bevel(torso,"RuneStoneFrame",Vector3(0,.24,-1.10),Vector3(.61,.61,.14),"8b6655",.07) as Node3D
	frame.rotation.z=PI/4
	var rune:=art.box(torso,"FurnaceRune",Vector3(0,.24,-1.19),Vector3(.34,.34,.035),"ffae59",0,.9) as Node3D
	rune.rotation.z=PI/4
	_trace(torso,art,"ChestFissure",Vector3(0,.55,-1.17),Vector3(.13,.93,-1.10),.035,"e88b4d",.55)
	_trace(torso,art,"ChestFissure",Vector3(0,-.07,-1.17),Vector3(-.12,-.55,-1.09),.035,"e88b4d",.55)
	_trace(torso,art,"ChestFissure",Vector3(-.23,.24,-1.17),Vector3(-.81,.38,-1.09),.03,"e88b4d",.5)
	_trace(torso,art,"ChestFissure",Vector3(.23,.24,-1.17),Vector3(.81,.07,-1.09),.03,"e88b4d",.5)
	art.bevel(torso,"BeltBuckle",Vector3(0,-.96,-.95),Vector3(.47,.30,.14),"867668",.055)
	# A vertebral back silhouette remains legible from the gameplay camera.
	for i in 3:
		art.bevel(torso,"BackPlate",Vector3(0,.70-i*.53,.88),Vector3(1.43-i*.12,.43,.25),"272d3e",.065)
	_trace(torso,art,"BackFissure",Vector3(-.15,.83,1.015),Vector3(.05,.31,1.015),.035,"d77b45",.4)
	_trace(torso,art,"BackFissure",Vector3(.05,.31,1.015),Vector3(-.16,-.29,1.015),.035,"d77b45",.4)
	# Deep visor, angled brow plates and a toothed basalt jaw replace a plain box.
	art.bevel(head,"VisorRecess",Vector3(0,.045,-.79),Vector3(1.46,.26,.18),"161e2d",.045)
	art.bevel(head,"MouthRecess",Vector3(0,-.43,-1.0),Vector3(1.09,.13,.06),"161e2d",.025)
	for side in [-1.0,1.0]:
		var brow:=art.bevel(head,"SlopedBrowPlate",Vector3(side*.40,.245,-.83),Vector3(.70,.20,.30),"4f465b",.05) as Node3D
		brow.rotation.z=side*.18
		art.ball(head,"FurnaceEye",Vector3(side*.39,.035,-.90),Vector3(.35,.12,.055),"ffb363",1.0)
		art.bevel(head,"CheekGuard",Vector3(side*.73,-.23,-.45),Vector3(.32,.61,.67),"363248",.07)
		var tooth:=art.cylinder(head,"StoneFang",Vector3(side*.35,-.45,-1.055),.075,.21,"aa9583",0) as Node3D
		tooth.rotation.z=PI
		var horn_band:=art.cylinder(head,"HornGrowthBand",Vector3(side*.893,.668,.15),.245,.10,"9c8b8c",.225) as Node3D
		horn_band.rotation.z=-side*.38
	for side in [-1.0,1.0]:
		var arm:=root.get_node("Rig/ArmL" if side<0 else "Rig/ArmR") as Node3D
		# All shoulder additions stay below local Y=.32, leaving riders supported.
		art.bevel(arm,"ShoulderFacePlate",Vector3(0,-.18,-.49),Vector3(1.07,.61,.31),"343047",.085)
		art.bevel(arm,"ShoulderSidePlate",Vector3(side*.43,-.27,-.02),Vector3(.24,.67,1.03),"3e374d",.065)
		art.bevel(arm,"ForearmPlate",Vector3(0,-.93,-.65),Vector3(.72,.75,.19),"474054",.06)
		art.cylinder(arm,"WristShackle",Vector3(0,-1.40,-.12),.57,.20,"69616a",-1,.65)
		for x in [-.30,.30]:
			art.ball(arm,"ShackleRivet",Vector3(x,-1.40,-.70),Vector3(.12,.12,.07),"b7a28b")
		for i in 2:
			var link:=art.ring(arm,"ShackleLink",Vector3(side*.60,-1.46-i*.24,-.18),.185,"b3a097") as Node3D
			link.rotation.x=PI/2;link.rotation.y=i*PI/2
		_trace(arm,art,"ShoulderFissure",Vector3(-.30,.02,-.66),Vector3(-.10,-.22,-.66),.033,"ed914f",.55)
		_trace(arm,art,"ShoulderFissure",Vector3(-.10,-.22,-.66),Vector3(.23,-.32,-.66),.033,"ed914f",.55)
		_trace(arm,art,"ForearmFissure",Vector3(-side*.15,-.65,-.76),Vector3(side*.12,-1.15,-.76),.035,"ed914f",.5)
		var leg:=root.get_node("Rig/LegL" if side<0 else "Rig/LegR") as Node3D
		art.bevel(leg,"KneeShield",Vector3(0,-.64,-.57),Vector3(.73,.55,.20),"514457",.07)
		art.bevel(leg,"AnkleGuard",Vector3(0,-1.27,-.03),Vector3(.90,.20,1.03),"746173",.045)
		art.bevel(leg,"BootTopPlate",Vector3(0,-1.54,-.62),Vector3(.91,.18,1.10),"3b354a",.055)
		_trace(leg,art,"KneeFissure",Vector3(-side*.15,-.44,-.685),Vector3(side*.12,-.78,-.685),.03,"e5894b",.45)
		_trace(leg,art,"ShinFissure",Vector3(side*.12,-.78,-.53),Vector3(-side*.08,-1.13,-.53),.028,"d97b43",.4)

static func _trace(parent:Node3D,art:Script,name:String,from:Vector3,to:Vector3,width:float,color:String,glow:float) -> void:
	var edge:=to-from
	var shard:=art.box(parent,name,(from+to)*.5,Vector3(width,edge.length(),width),color,0,glow) as Node3D
	shard.quaternion=Quaternion(Vector3.UP,edge.normalized())

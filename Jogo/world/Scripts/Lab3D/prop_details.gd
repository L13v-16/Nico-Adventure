extends RefCounted
## Supported mechanical details for the native 3D laboratory props.
## The base model keeps its interaction silhouette and animation anchors.
const STEEL:="91a6aa"
const DARK:="263c49"
const TEAL:="61c9c5"
const BRASS:="cfa45d"
const CREAM:="ddd8bb"

static func decorate(root:Node3D,kind:String,art:Script) -> void:
	match kind:
		"drone":_drone(root,art)
		"terminal_heat","terminal_cold","injector":_terminal(root,kind,art)
		"lever":_lever(root,art)
		"tank":_tank(root,art)
		"egg":_egg(root,art)
		"wagon":_wagon(root,art)
		"flag":_flag(root,art)
		"crate":_crate(root,art)
		"keycard":_keycard(root,art)
		"syringe":_syringe(root,art)
		"cherry":
			for side in [-1.0,1.0]:
				art.ball(root,"FruitGlint",Vector3(side*.15-.06,.14,-.14),Vector3(.075,.10,.025),"f18ba0")
			_rod(root,"StemFork",Vector3(0,.32,0),Vector3(.15,.2,0),.018,"426c49",art)
			_rod(root,"LeafVein",Vector3(.03,.555,0),Vector3(.25,.555,0),.009,"bfd981",art)

static func _rod(parent:Node3D,name:String,a:Vector3,b:Vector3,radius:float,color:String,art:Script) -> MeshInstance3D:
	var delta:=b-a
	var node:MeshInstance3D=art.cylinder(parent,name,(a+b)*.5,radius,delta.length(),color,-1,.35)
	if delta.length_squared()>.00001:node.quaternion=Quaternion(Vector3.UP,delta.normalized())
	return node

static func _bolt(parent:Node3D,at:Vector3,art:Script,radius:float=.035,forward:Vector3=Vector3.FORWARD) -> void:
	var head:MeshInstance3D=art.cylinder(parent,"Bolt",at,radius,.025,BRASS,-1,.55)
	head.quaternion=Quaternion(Vector3.UP,forward)
	var slot:MeshInstance3D=art.box(head,"Slot",Vector3(0,.014,0),Vector3(radius*1.2,.008,radius*.22),DARK)
	slot.rotation.y=.45

static func _gauge(parent:Node3D,at:Vector3,radius:float,art:Script,accent:String=BRASS) -> void:
	var gauge:Node3D=art.pivot(parent,"PressureGauge",at)
	var bezel:MeshInstance3D=art.cylinder(gauge,"Bezel",Vector3.ZERO,radius,.065,DARK,-1,.5);bezel.rotation.x=PI/2
	var face:MeshInstance3D=art.cylinder(gauge,"Dial",Vector3(0,0,-.037),radius*.8,.015,CREAM);face.rotation.x=PI/2
	for i in 5:
		var angle:float=-2.4+i*.42
		var tick:MeshInstance3D=art.box(gauge,"ScaleMark",Vector3(cos(angle)*radius*.6,sin(angle)*radius*.6,-.05),Vector3(.016,radius*.2,.008),DARK)
		tick.rotation.z=angle-PI/2
	_rod(gauge,"Needle",Vector3(0,0,-.061),Vector3(radius*.4,radius*.35,-.061),.011,accent,art)
	art.ball(gauge,"Pin",Vector3(0,0,-.065),Vector3(.04,.04,.025),DARK)

static func _drone(root:Node3D,art:Script) -> void:
	art.bevel(root,"TopArmor",Vector3(0,.23,.02),Vector3(.72,.22,.54),"aebbb4",.07)
	art.bevel(root,"GimbalYoke",Vector3(0,-.17,-.32),Vector3(.57,.19,.35),DARK,.045)
	var optic:MeshInstance3D=art.ring(root,"LensBezel",Vector3(0,0,-.444),.235,BRASS);optic.rotation.x=PI/2
	var pupil:MeshInstance3D=art.ring(root,"Iris",Vector3(0,0,-.477),.115,DARK);pupil.rotation.x=PI/2
	art.ball(root,"OpticalHighlight",Vector3(-.08,.08,-.481),Vector3(.09,.07,.025),"d8ffff",.4)
	for side in [-1.0,1.0]:
		var joint:MeshInstance3D=art.cylinder(root,"ArmJoint",Vector3(side*.49,0,0),.105,.2,BRASS,-1,.6);joint.rotation.z=PI/2
		var motor:MeshInstance3D=art.cylinder(root,"RotorMotor",Vector3(side*.88,.07,0),.10,.22,DARK,-1,.4)
		var rotor:Node3D=art.pivot(root,"RotorJointL" if side<0 else "RotorJointR",Vector3(side*.88,.15,0))
		for i in 3:
			var blade:MeshInstance3D=art.bevel(rotor,"RotorBlade",Vector3.ZERO,Vector3(.53,.035,.075),STEEL,.012)
			blade.rotation.y=i*TAU/3
		art.cylinder(rotor,"RotorHub",Vector3(0,.018,0),.075,.055,BRASS,-1,.5)
		_rod(root,"LandingStrut",Vector3(side*.28,-.19,.12),Vector3(side*.36,-.39,.18),.035,STEEL,art)
		art.bevel(root,"LandingSkid",Vector3(side*.36,-.40,.08),Vector3(.13,.07,.48),DARK,.025)
		art.ball(root,"StatusLamp",Vector3(side*.31,.17,-.27),Vector3(.07,.06,.05),"f4ad69",.6)
	_rod(root,"Antenna",Vector3(0,.27,.19),Vector3(0,.58,.24),.018,DARK,art)
	art.ball(root,"AntennaTip",Vector3(0,.59,.24),Vector3(.07,.07,.07),TEAL,.4)
	for i in 3:art.box(root,"Vent",Vector3(-.13+i*.13,.339,.08),Vector3(.055,.015,.23),DARK)

static func _terminal(root:Node3D,kind:String,art:Script) -> void:
	var hot:=kind=="terminal_heat"
	var accent:="eea45b" if hot else ("78d9e4" if kind=="terminal_cold" else "b0d78a")
	art.bevel(root,"PlinthTrim",Vector3(0,.055,0),Vector3(1.54,.10,1.23),"587078",.04)
	for x in [-.42,.42]:
		art.box(root,"ScreenSide",Vector3(x,1.1,-.46),Vector3(.055,.51,.055),DARK,.4)
	for y in [.85,1.35]:art.box(root,"ScreenRim",Vector3(0,y,-.46),Vector3(.89,.055,.055),DARK,.4)
	_gauge(root,Vector3(-.26,.56,-.43),.14,art,accent)
	for x in [.13,.29]:
		var button:MeshInstance3D=art.cylinder(root,"Switch",Vector3(x,.57,-.44),.065,.055,accent,-1,.2);button.rotation.x=PI/2
	for x in [-.64,.64]:
		for z in [-.47,.47]:_bolt(root,Vector3(x,.324,z),art,.04,Vector3.UP)
	for i in 4:
		var stripe:MeshInstance3D=art.box(root,"BaseHazard",Vector3(-.42+i*.28,.17,-.611),Vector3(.12,.13,.022),BRASS)
		stripe.rotation.z=-.35
	for side in [-1.0,1.0]:
		art.bevel(root,"SideServicePanel",Vector3(side*.54,.73,.04),Vector3(.055,.60,.55),"5c777d",.025)
		for j in 3:art.box(root,"ServiceVent",Vector3(side*.575,.59+j*.13,.04),Vector3(.025,.035,.34),DARK)
		if kind!="injector":
			_rod(root,"ExternalPipe",Vector3(side*.61,.36,.28),Vector3(side*.61,1.40,.28),.06,BRASS,art)
			for y in [.44,1.29]:art.cylinder(root,"PipeCollar",Vector3(side*.61,y,.28),.088,.065,DARK,-1,.5)
			if not hot:
				for j in 4:art.ring(root,"CoolingCoil",Vector3(side*.61,.61+j*.12,.28),.11,STEEL)
			else:
				for j in 3:art.bevel(root,"HeatFin",Vector3(side*.61,.62+j*.16,.28),Vector3(.20,.045,.20),"ad7950",.018)
	art.bevel(root,"BeaconMount",Vector3(-.42,1.32,0),Vector3(.22,.12,.24),DARK,.025)
	art.cylinder(root,"BeaconCap",Vector3(-.42,1.58,0),.10,.045,BRASS,-1,.5)
	if kind=="injector":
		for side in [-1.0,1.0]:
			for y in [.40,1.75]:art.cylinder(root,"ReservoirBand",Vector3(side*.8,y,0),.245,.12,DARK,-1,.55)
			art.cylinder(root,"ReservoirLid",Vector3(side*.8,1.93,0),.25,.10,BRASS,-1,.6)
			for i in 4:art.box(root,"ReservoirScale",Vector3(side*.8+.02,.70+i*.21,-.224),Vector3(.15,.025,.015),CREAM)
			_rod(root,"ChemicalHose",Vector3(side*.8,.34,0),Vector3(side*.4,.34,.29),.055,DARK,art)
			_rod(root,"HoseManifold",Vector3(side*.4,.34,.29),Vector3(side*.4,.82,.29),.055,DARK,art)
		art.bevel(root,"DoseTray",Vector3(0,.34,-.57),Vector3(.65,.10,.25),STEEL,.03)
		for x in [-.20,0,.20]:art.cylinder(root,"DoseSocket",Vector3(x,.401,-.57),.055,.025,DARK)

static func _lever(root:Node3D,art:Script) -> void:
	art.bevel(root,"FootTrim",Vector3(0,.055,0),Vector3(.94,.11,.74),"658181",.035)
	for x in [-.34,.34]:
		for z in [-.23,.23]:_bolt(root,Vector3(x,.512,z),art,.035,Vector3.UP)
	_rod(root,"PivotAxle",Vector3(-.28,.47,0),Vector3(.28,.47,0),.115,STEEL,art)
	for side in [-1.0,1.0]:
		var cap:MeshInstance3D=art.cylinder(root,"PivotCap",Vector3(side*.30,.47,0),.14,.055,BRASS,-1,.55);cap.rotation.z=PI/2
		art.box(root,"TravelStop",Vector3(side*.20,.53,side*.23),Vector3(.12,.08,.11),DARK)
	var handle:Node3D=root.get_node_or_null("Handle")
	if handle:
		for x in [-.21,.21]:art.box(handle,"GripEnd",Vector3(x,.72,0),Vector3(.065,.15,.17),DARK)
		for x in [-.12,0,.12]:art.box(handle,"GripTexture",Vector3(x,.723,-.078),Vector3(.025,.09,.018),"97703f")
		art.box(handle,"DirectionTab",Vector3(0,.27,-.075),Vector3(.15,.16,.035),BRASS)
	for z in [-.23,.23]:art.box(root,"StateMark",Vector3(0,.515,z),Vector3(.22,.018,.065),TEAL if z<0 else BRASS,0,.15)
	art.box(root,"FrontRecess",Vector3(0,.25,-.359),Vector3(.50,.17,.022),DARK)
	for x in [-.15,0,.15]:art.box(root,"StatusPip",Vector3(x,.25,-.376),Vector3(.055,.055,.018),TEAL,0,.2)

static func _tank(root:Node3D,art:Script) -> void:
	for y in [.38,2.82]:
		var collar:MeshInstance3D=art.ring(root,"ContainmentCollar",Vector3(0,y,0),1.015,BRASS);collar.scale.y=.75
		for x in [-.79,.79]:_bolt(root,Vector3(x,y,-.66),art,.045)
	for side in [-1.0,1.0]:
		art.bevel(root,"SideColumn",Vector3(side*.96,1.60,.03),Vector3(.18,2.74,.29),"617b87",.045)
		_rod(root,"RearHose",Vector3(side*.73,.35,.66),Vector3(side*.73,2.67,.66),.075,DARK,art)
		for y in [.5,2.5]:art.ring(root,"HoseClamp",Vector3(side*.73,y,.66),.10,BRASS)
		art.box(root,"WindowSideTrim",Vector3(side*.67,1.6,-.79),Vector3(.07,2.33,.05),DARK,.5)
	for y in [.44,2.76]:art.box(root,"WindowTrim",Vector3(0,y,-.79),Vector3(1.40,.085,.06),DARK,.5)
	for j in 6:art.box(root,"FluidScale",Vector3(-.53,.70+j*.31,-.797),Vector3(.10 if j%2 else .17,.025,.016),"c3e6c7")
	for y in [.9,1.7,2.3]:art.ball(root,"SuspendedBubble",Vector3(.23+(y-.9)*.12,y,-.80),Vector3(.055,.075,.018),"9ce3bb",.25)
	_gauge(root,Vector3(.57,3.04,-.56),.16,art,TEAL)
	_rod(root,"UpperManifold",Vector3(-.26,3.17,.12),Vector3(.28,3.17,.12),.09,STEEL,art)
	art.cylinder(root,"ValveStem",Vector3(-.26,3.30,.12),.045,.22,BRASS,-1,.5)
	art.ring(root,"ValveWheel",Vector3(-.26,3.44,.12),.21,TEAL)
	for i in 3:
		var angle:float=i*TAU/3
		_rod(root,"ValveSpoke",Vector3(-.26,3.44,.12),Vector3(-.26+cos(angle)*.18,3.44,.12+sin(angle)*.18),.022,TEAL,art)

static func _shell_point(u:float,v:float) -> Vector3:
	return Vector3(.863*sin(u)*cos(v),1.30+1.268*sin(v),-.863*cos(u)*cos(v))

static func _egg(root:Node3D,art:Script) -> void:
	# Fine fissures follow the shell surface rather than float on a flat plane.
	for side in [-1.0,1.0]:
		var u:float=side*.64
		for i in 5:
			var v:float=-.72+i*.26
			var a:=_shell_point(u+sin(i*2.3)*.10,v)
			var b:=_shell_point(u+sin((i+1)*2.3)*.10,v+.26)
			_rod(root,"ShellFissure",a,b,.020,"54726b",art)
			if i%2==0:
				_rod(root,"FissureGlow",a+Vector3(0,0,-.006),b+Vector3(0,0,-.006),.008,"92e5bb",art)
				_rod(root,"FissureFork",b,_shell_point(u+side*.26,v+.37),.012,"54726b",art)
	for i in 3:
		var seam:MeshInstance3D=art.ball(root,"ShellSpeckle",_shell_point(-.22+i*.23,.63),Vector3(.075,.045,.018),"a2ac9c")
		seam.rotation.y=-.22+i*.23

static func _wagon(root:Node3D,art:Script) -> void:
	for i in 7:
		art.box(root,"FrontPlankJoint",Vector3(-1.27+i*.42,.72,-.962),Vector3(.025,.72,.02),"573e32")
	for y in [.31,1.06]:art.bevel(root,"FrontTimber",Vector3(0,y,-.99),Vector3(2.87,.13,.12),"a27248",.025)
	for side in [-1.0,1.0]:
		for j in 3:art.box(root,"SidePlankJoint",Vector3(side*1.458,.71,-.69+j*.58),Vector3(.02,.69,.025),"573e32")
		for y in [.32,1.07]:art.box(root,"IronCorner",Vector3(side*1.37,y,-1.004),Vector3(.17,.15,.035),DARK,.5)
		for y in [.33,1.07]:_bolt(root,Vector3(side*1.37,y,-1.037),art,.035)
		# The wheel fittings are outside the existing tire, joined to its axle.
		var hub:MeshInstance3D=art.cylinder(root,"WheelHub",Vector3(side*1.603,.40,.30),.105,.10,BRASS,-1,.6);hub.rotation.z=PI/2
		var rim:MeshInstance3D=art.ring(root,"WheelRim",Vector3(side*1.59,.40,.30),.385,"9b7852");rim.rotation.z=PI/2
		for i in 6:
			var angle:float=i*TAU/6
			_rod(root,"WheelSpoke",Vector3(side*1.595,.4,.3),Vector3(side*1.595,.4+cos(angle)*.34,.3+sin(angle)*.34),.028,"af8b58",art)
		_rod(root,"CanopyBrace",Vector3(side*1.25,2.22,.25),Vector3(side*1.25,2.69,-.96),.045,"79513a",art)
	_rod(root,"WheelAxle",Vector3(-1.48,.4,.3),Vector3(1.48,.4,.3),.085,DARK,art)
	art.bevel(root,"CounterLip",Vector3(0,1.31,-1.073),Vector3(2.98,.19,.10),"d1a16a",.025)
	for i in 6:
		var color:="d8c28a" if i%2 else "487d7d"
		art.box(root,"AwningValance",Vector3(-1.25+i*.5,2.67,-1.24),Vector3(.5,.19,.055),color)
		var scallop:MeshInstance3D=art.cylinder(root,"CanopyScallop",Vector3(-1.25+i*.5,2.59,-1.24),.24,.055,color);scallop.rotation.x=PI/2;scallop.scale.z=.35
	art.box(root,"CanopyFrontRail",Vector3(0,2.77,-1.18),Vector3(3.0,.08,.10),"79513a")
	# Small goods sit on the counter, leaving Oliver's face and the shop open.
	art.bevel(root,"CoinDish",Vector3(.94,1.43,-.71),Vector3(.40,.06,.26),DARK,.02)
	for x in [.84,.99]:art.cylinder(root,"CherryToken",Vector3(x,1.48,-.71),.065,.035,BRASS,-1,.6)
	art.bevel(root,"SupplyBox",Vector3(-.98,1.52,-.39),Vector3(.43,.26,.35),"d1b77b",.035)
	art.box(root,"SupplyBoxRibbon",Vector3(-.98,1.526,-.57),Vector3(.055,.24,.02),"b9654d")
	art.label(root,"OLIVER GANCHO",Vector3(0,.73,-1.027),15,"f3db9e").rotation.y=PI

static func _flag(root:Node3D,art:Script) -> void:
	art.bevel(root,"BaseSocket",Vector3(0,.24,0),Vector3(.24,.20,.24),STEEL,.035)
	for y in [.33,1.52,2.12]:art.cylinder(root,"PoleCollar",Vector3(0,y,0),.075,.065,BRASS,-1,.6)
	var finial:MeshInstance3D=art.cylinder(root,"FinialSpire",Vector3(0,2.37,0),.075,.17,BRASS,0,.5)
	var flag:Node3D=root.get_node_or_null("Flag")
	if flag:
		for y in [-.21,.21]:art.box(flag,"StitchedHem",Vector3(0,y,-.024),Vector3(.87,.025,.013),"b6e9ce")
		art.box(flag,"FlyHem",Vector3(.422,0,-.024),Vector3(.025,.43,.013),"b6e9ce")
		var badge:MeshInstance3D=art.cylinder(flag,"CheckpointSeal",Vector3(-.02,0,-.029),.13,.018,CREAM,-1,.2);badge.rotation.x=PI/2
		_rod(flag,"CheckStroke",Vector3(-.08,-.01,-.044),Vector3(-.025,-.06,-.044),.017,DARK,art)
		_rod(flag,"CheckStroke",Vector3(-.025,-.06,-.044),Vector3(.065,.055,-.044),.017,DARK,art)
	for x in [-.21,.21]:_bolt(root,Vector3(x,.207,0),art,.03,Vector3.UP)

static func _crate(root:Node3D,art:Script) -> void:
	# Recess outlines and corner hardware leave the full square collision intact.
	for side in [-1.0,1.0]:
		art.box(root,"FrontPanelSeam",Vector3(0,.70,side*.707),Vector3(1.06,.89,.014),"405d6b")
		art.bevel(root,"FrontInset",Vector3(0,.70,side*.722),Vector3(.95,.78,.025),"688b91",.025)
		art.box(root,"SidePanelSeam",Vector3(side*.707,.70,0),Vector3(.014,.90,1.0),"405d6b")
		art.bevel(root,"SideInset",Vector3(side*.722,.70,0),Vector3(.025,.79,.88),"688b91",.018)
		for y in [.12,1.28]:
			for x in [-.55,.55]:
				art.bevel(root,"CornerPlate",Vector3(x,y,side*.733),Vector3(.27,.23,.045),CREAM,.025)
				_bolt(root,Vector3(x,y,side*.77),art,.035,Vector3(0,0,side))
	for z in [-.56,.56]:art.box(root,"TopBrace",Vector3(0,1.416,z),Vector3(1.38,.035,.13),CREAM,.4)
	for i in 3:art.box(root,"SerialDash",Vector3(-.13+i*.13,.72,-.745),Vector3(.055,.20,.018),DARK)
	art.bevel(root,"LidGrip",Vector3(0,1.43,0),Vector3(.42,.055,.18),DARK,.015)

static func _keycard(root:Node3D,art:Script) -> void:
	art.box(root,"MagneticStripe",Vector3(0,.12,.052),Vector3(.83,.11,.018),DARK)
	art.box(root,"CardInset",Vector3(.20,-.08,-.056),Vector3(.34,.24,.014),"b9cbb9")
	for x in [-.29,-.21]:art.box(root,"ChipContact",Vector3(x,-.08,-.082),Vector3(.012,.12,.01),"95733e")
	art.box(root,"ChipContact",Vector3(-.25,-.08,-.083),Vector3(.15,.013,.01),"95733e")
	for i in 4:art.box(root,"AccessBarcode",Vector3(-.29+i*.065,-.22,-.056),Vector3(.025,.05,.016),DARK)
	for x in [-.39,.39]:art.ball(root,"CardFastener",Vector3(x,.235,-.058),Vector3(.033,.033,.014),BRASS)

static func _syringe(root:Node3D,art:Script) -> void:
	art.cylinder(root,"PlungerRod",Vector3(0,.38,0),.035,.23,STEEL,-1,.6)
	art.cylinder(root,"ThumbPad",Vector3(0,.51,0),.13,.045,DARK,-1,.4)
	art.cylinder(root,"NeedleCollar",Vector3(0,-.35,0),.075,.10,BRASS,-1,.6)
	for i in 4:art.box(root,"DoseMark",Vector3(.015,-.16+i*.105,-.109),Vector3(.10 if i%2 else .065,.015,.012),"315b65")
	art.box(root,"GlassGlint",Vector3(-.065,0,-.093),Vector3(.018,.35,.012),"d7f3d0")

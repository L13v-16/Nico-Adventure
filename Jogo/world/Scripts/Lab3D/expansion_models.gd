extends RefCounted
## Native, editable industrial props for the expanded 3D laboratory.
## Feet are at Y=0; interactive faces point along -Z. No raster textures.
const STEEL:="91a6aa"
const DARK:="263c49"
const TEAL:="61c9c5"
const BRASS:="cfa45d"
const IVORY:="ddd8bb"
const HEAT:="ef9960"
const COLD:="79d9e8"

static func make(kind:String,art:Script) -> Node3D:
	var root:=Node3D.new();root.name=kind.to_pascal_case();root.set_meta("model_kind",kind);root.set_meta("model_revision",77)
	match kind:
		"power_cell":_cell(root,art)
		"power_socket":_socket(root,art)
		"thermal_relay":_relay(root,art)
		"piston_bridge":_bridge(root,art)
		"ventilation_fan":_fan(root,art)
		"security_scanner":_scanner(root,art)
		"archive_console":_archive(root,art)
		"blast_gate":_gate(root,art)
		"cargo_cart":_cart(root,art)
		"specimen_tree":_tree(root,art)
	_owners(root,root)
	return root

static func _owners(parent:Node,root:Node) -> void:
	for child:Node in parent.get_children():
		child.owner=root;_owners(child,root)

static func _rod(parent:Node3D,name:String,a:Vector3,b:Vector3,radius:float,color:String,art:Script) -> MeshInstance3D:
	var delta:=b-a
	var node:MeshInstance3D=art.cylinder(parent,name,(a+b)*.5,radius,delta.length(),color,-1,.4)
	if delta.length_squared()>.00001:node.quaternion=Quaternion(Vector3.UP,delta.normalized())
	return node

static func _disc(parent:Node3D,name:String,at:Vector3,radius:float,depth:float,color:String,art:Script) -> MeshInstance3D:
	var node:MeshInstance3D=art.cylinder(parent,name,at,radius,depth,color,-1,.45);node.rotation.x=PI/2;return node

static func _rim(parent:Node3D,name:String,at:Vector3,radius:float,color:String,art:Script) -> MeshInstance3D:
	var node:MeshInstance3D=art.ring(parent,name,at,radius,color);node.rotation.x=PI/2;return node

static func _bolt(parent:Node3D,at:Vector3,art:Script) -> void:
	_disc(parent,"HexBolt",at,.045,.035,BRASS,art)
	art.box(parent,"BoltSlot",at+Vector3(0,0,-.02),Vector3(.045,.011,.012),DARK)

static func _gauge(parent:Node3D,at:Vector3,art:Script,accent:String=TEAL) -> Node3D:
	var gauge:Node3D=art.pivot(parent,"Gauge",at)
	_disc(gauge,"BrassBezel",Vector3.ZERO,.17,.075,BRASS,art)
	_disc(gauge,"IvoryDial",Vector3(0,0,-.044),.133,.015,IVORY,art)
	for i in 4:
		var angle:float=-2.5+i*.61
		var tick:MeshInstance3D=art.box(gauge,"DialTick",Vector3(cos(angle)*.105,sin(angle)*.105,-.059),Vector3(.012,.035,.008),DARK);tick.rotation.z=angle-PI/2
	_rod(gauge,"Needle",Vector3(0,0,-.066),Vector3(.07,.07,-.066),.011,accent,art)
	return gauge

static func _text(parent:Node3D,value:String,at:Vector3,art:Script,size:int=18,color:String=IVORY) -> void:
	var label:Label3D=art.label(parent,value,at,size,color);label.rotation.y=PI

static func _cell(root:Node3D,art:Script) -> void:
	art.bevel(root,"BatteryBody",Vector3(0,.34,0),Vector3(.5,.58,.44),DARK,.075)
	for y in [.09,.60]:art.bevel(root,"ProtectiveCap",Vector3(0,y,0),Vector3(.56,.12,.49),IVORY,.045)
	for x in [-.22,.22]:art.bevel(root,"SideRail",Vector3(x,.35,-.21),Vector3(.065,.43,.065),BRASS,.02)
	art.bevel(root,"ChargePanel",Vector3(0,.35,-.24),Vector3(.30,.34,.035),"1b373e",.015)
	var charge:Node3D=art.pivot(root,"Charge",Vector3(0,.35,-.266))
	for i in 3:art.box(charge,"ChargeSegment",Vector3(0,-.10+i*.10,0),Vector3(.19,.055,.02),TEAL,0,.65)
	for side in [-1.0,1.0]:_rod(root,"HandleLeg",Vector3(side*.16,.64,0),Vector3(side*.16,.81,0),.035,STEEL,art)
	_rod(root,"Handle",Vector3(-.16,.81,0),Vector3(.16,.81,0),.045,DARK,art)
	for x in [-.12,.12]:art.cylinder(root,"Contact",Vector3(x,.012,0),.055,.025,BRASS,-1,.8)
	for x in [-.18,.18]:_bolt(root,Vector3(x,.12,-.26),art)

static func _socket(root:Node3D,art:Script) -> void:
	art.bevel(root,"GroundPlinth",Vector3(0,.08,0),Vector3(1.1,.16,.95),DARK,.05)
	art.bevel(root,"Pedestal",Vector3(0,.53,.10),Vector3(.83,.94,.64),IVORY,.08)
	art.bevel(root,"SocketFrame",Vector3(0,.69,-.27),Vector3(.77,.78,.18),STEEL,.05)
	art.bevel(root,"Receptacle",Vector3(0,.66,-.38),Vector3(.55,.59,.055),DARK,.035)
	for x in [-.16,.16]:art.box(root,"PowerContact",Vector3(x,.46,-.42),Vector3(.06,.18,.045),BRASS,.6)
	for side in [-1.0,1.0]:art.bevel(root,"GuideJaw",Vector3(side*.31,.62,-.46),Vector3(.08,.45,.19),BRASS,.025)
	var indicator:MeshInstance3D=art.ball(root,"StatusLamp",Vector3(0,1.14,-.28),Vector3(.16,.13,.07),TEAL,.6);indicator.set_meta("status_light",true)
	_text(root,"ENERGIA",Vector3(0,.22,-.25),art,11,"28444c")
	for x in [-.44,.44]:_bolt(root,Vector3(x,.1,-.48),art)
	for x in [-.22,0,.22]:art.box(root,"Vent",Vector3(x,.50,.431),Vector3(.075,.35,.018),DARK)
	_rod(root,"Cable",Vector3(.36,.30,.25),Vector3(.47,.12,.35),.06,DARK,art)

static func _relay(root:Node3D,art:Script) -> void:
	art.bevel(root,"Foundation",Vector3(0,.12,0),Vector3(1.65,.24,1.1),DARK,.065)
	art.bevel(root,"Cabinet",Vector3(0,.80,.14),Vector3(1.4,1.35,.62),IVORY,.09)
	art.bevel(root,"FrontPlate",Vector3(0,.80,-.21),Vector3(1.23,1.15,.09),STEEL,.055)
	for side in [-1.0,1.0]:
		var accent:String=HEAT if side>0 else COLD
		_gauge(root,Vector3(side*.37,1.15,-.30),art,accent)
		art.bevel(root,"ElementWindow",Vector3(side*.37,.64,-.29),Vector3(.36,.38,.055),DARK,.035)
		var symbol:Node3D=art.pivot(root,"HeatSymbol" if side>0 else "ColdSymbol",Vector3(side*.37,.64,-.335))
		if side>0:
			for i in 3:
				var tip:MeshInstance3D=art.ball(symbol,"Flame",Vector3(-.08+i*.08,.01+(.05 if i==1 else 0),0),Vector3(.08,.23-i*.015,.03),accent,.4);tip.rotation.z=-.35+i*.35
		else:
			for i in 3:
				var angle:float=i*PI/3;_rod(symbol,"IceCrystal",Vector3(-cos(angle)*.12,-sin(angle)*.12,0),Vector3(cos(angle)*.12,sin(angle)*.12,0),.013,accent,art)
		_rod(root,"SidePipe",Vector3(side*.66,.22,.29),Vector3(side*.66,1.78,.29),.065,BRASS,art)
		for y in [.32,1.65]:art.cylinder(root,"PipeCollar",Vector3(side*.66,y,.29),.10,.095,DARK,-1,.5)
		art.ball(root,"RelayLamp",Vector3(side*.37,1.57,-.19),Vector3(.12,.12,.09),accent,.6)
	art.bevel(root,"Busbar",Vector3(0,1.76,.29),Vector3(1.45,.13,.20),DARK,.04)
	art.box(root,"Divider",Vector3(0,.85,-.29),Vector3(.06,1,.07),DARK)
	_text(root,"01  →  02",Vector3(0,.31,-.28),art,15,"29454c")
	for x in [-.56,.56]:_bolt(root,Vector3(x,1.34,-.28),art)

static func _bridge(root:Node3D,art:Script) -> void:
	# Top of the structural walking deck is exactly 0. The physics body is supplied by the device.
	art.bevel(root,"Deck",Vector3(0,-.195,0),Vector3(4,.25,16),"567780",.07)
	for i in 8:
		var z:float=-7+i*2
		art.bevel(root,"DeckPlate",Vector3(0,-.035,z),Vector3(3.66,.07,1.82),STEEL,.025)
		for x in [-1.55,1.55]:art.box(root,"TractionMark",Vector3(x,.0015,z),Vector3(.055,.003,1.20),DARK)
	for side in [-1.0,1.0]:
		art.bevel(root,"EdgeGirder",Vector3(side*1.88,-.42,0),Vector3(.25,.55,15.9),DARK,.05)
		art.box(root,"GuidanceLight",Vector3(side*1.96,-.15,0),Vector3(.025,.07,15.3),TEAL,0,.4)
		for z in [-6.5,0,6.5]:
			_rod(root,"HydraulicBarrel",Vector3(side*1.40,-1.70,z+.40),Vector3(side*1.40,-.78,z),.17,DARK,art)
			_rod(root,"HydraulicPiston",Vector3(side*1.40,-.82,z),Vector3(side*1.40,-.31,z-.19),.08,STEEL,art)
			art.ball(root,"PivotJoint",Vector3(side*1.40,-.37,z-.18),Vector3(.26,.26,.26),BRASS)
	for z in [-7.8,7.8]:art.bevel(root,"EndBumper",Vector3(0,-.20,z),Vector3(4,.28,.22),BRASS,.04)

static func _fan(root:Node3D,art:Script) -> void:
	art.bevel(root,"FloorMount",Vector3(0,.10,0),Vector3(2.3,.2,1.1),DARK,.08)
	for side in [-1.0,1.0]:art.bevel(root,"Support",Vector3(side*1.03,.58,.10),Vector3(.25,.95,.45),IVORY,.07)
	_rim(root,"OuterDuct",Vector3(0,1.8,.08),1.61,DARK,art)
	_rim(root,"IvoryFlange",Vector3(0,1.8,-.12),1.56,IVORY,art)
	_rim(root,"InnerDuct",Vector3(0,1.8,.20),1.43,STEEL,art)
	_disc(root,"Motor",Vector3(0,1.8,.31),.30,.45,DARK,art)
	var rotors:Node3D=art.pivot(root,"Rotors",Vector3(0,1.8,0))
	for i in 5:
		var rotor:Node3D=art.pivot(rotors,"BladeJoint",Vector3.ZERO);rotor.rotation.z=i*TAU/5
		var blade:MeshInstance3D=art.bevel(rotor,"Blade",Vector3(.73,.14,0),Vector3(1.2,.36,.09),"689596",.07);blade.rotation.z=.27;blade.rotation.y=.23
	_disc(rotors,"RotorHub",Vector3(0,0,-.08),.29,.20,BRASS,art)
	for radius in [.57,1.04,1.44]:_rim(root,"SafetyGuard",Vector3(0,1.8,-.32),radius,DARK,art).scale=Vector3(1,.33,1)
	for i in 6:
		var angle:float=i*TAU/6
		_rod(root,"GuardSpoke",Vector3(0,1.8,-.37),Vector3(cos(angle)*1.47,1.8+sin(angle)*1.47,-.37),.021,DARK,art)
	for i in 8:
		var angle:float=i*TAU/8;_bolt(root,Vector3(cos(angle)*1.49,1.8+sin(angle)*1.49,-.24),art)
	art.ball(root,"WarningLamp",Vector3(.95,.23,-.46),Vector3(.11,.11,.06),HEAT,.5)

static func _scanner(root:Node3D,art:Script) -> void:
	art.bevel(root,"AnchoredFoot",Vector3(0,.10,0),Vector3(1.03,.2,.95),DARK,.06)
	art.cylinder(root,"Pedestal",Vector3(0,.65,.08),.25,1.1,IVORY,-1,.4)
	for y in [.25,1.12]:art.cylinder(root,"ColumnBand",Vector3(0,y,.08),.29,.13,BRASS,-1,.5)
	var head:Node3D=art.pivot(root,"SensorHead",Vector3(0,1.40,.02))
	art.bevel(head,"SensorHousing",Vector3(0,.17,0),Vector3(1.04,.65,.80),IVORY,.13)
	art.bevel(head,"DarkFace",Vector3(0,.17,-.43),Vector3(.83,.48,.10),DARK,.06)
	_disc(head,"LensBezel",Vector3(0,.17,-.51),.20,.08,BRASS,art)
	art.ball(head,"Lens",Vector3(0,.17,-.57),Vector3(.29,.29,.08),TEAL,.6)
	art.ball(head,"LensGlint",Vector3(-.06,.23,-.61),Vector3(.07,.07,.025),"e0f9ed",.2)
	for x in [-.34,.34]:art.ball(head,"WarningLens",Vector3(x,.18,-.50),Vector3(.09,.09,.035),HEAT,.6)
	for x in [-.30,0,.30]:art.box(head,"CoolingVent",Vector3(x,.49,.09),Vector3(.10,.025,.35),DARK)
	_disc(head,"SideMotor",Vector3(.55,.17,0),.16,.10,STEEL,art).rotation.y=PI/2
	for x in [-.37,.37]:_bolt(root,Vector3(x,.13,-.48),art)
	_text(root,"SCN · 17",Vector3(0,.76,-.18),art,12,"263c49")

static func _archive(root:Node3D,art:Script) -> void:
	art.bevel(root,"ConsoleFoot",Vector3(0,.09,0),Vector3(1.8,.18,1.2),DARK,.07)
	art.bevel(root,"Cabinet",Vector3(0,.66,.17),Vector3(1.45,1.18,.66),IVORY,.08)
	var monitor:Node3D=art.pivot(root,"Display",Vector3(0,1.36,.05));monitor.rotation.x=-.10
	art.bevel(monitor,"MonitorHousing",Vector3.ZERO,Vector3(1.66,1.05,.23),DARK,.08)
	var screen:MeshInstance3D=art.box(monitor,"Screen",Vector3(0,0,-.13),Vector3(1.42,.80,.035),"234b57");art.screen(screen)
	art.bevel(root,"KeyboardTray",Vector3(0,.99,-.47),Vector3(1.55,.12,.55),STEEL,.04)
	for row in 3:art.box(root,"KeyRow",Vector3(-.15,1.055,-.62+row*.12),Vector3(.96,.035,.065),DARK)
	art.ball(root,"Trackball",Vector3(.57,1.07,-.50),Vector3(.13,.07,.13),TEAL,.2)
	art.bevel(root,"FileShelf",Vector3(0,.38,-.24),Vector3(1.1,.48,.04),DARK,.02)
	for i in 4:
		art.bevel(root,"DataVolume",Vector3(-.35+i*.23,.36,-.32),Vector3(.17,.37,.19),["638a8e","b8b397","8e778d","b3a06d"][i],.015)
		art.box(root,"VolumeLabel",Vector3(-.35+i*.23,.42,-.42),Vector3(.10,.09,.012),IVORY)
	_text(root,"ARQUIVO  /  LG-17",Vector3(0,.71,-.18),art,13,"29474e")
	for side in [-1.0,1.0]:_bolt(monitor,Vector3(side*.75,.41,-.14),art)
	art.box(root,"ReadyLight",Vector3(.62,1.82,-.10),Vector3(.12,.04,.02),TEAL,0,.5)

static func _gate(root:Node3D,art:Script) -> void:
	var panels:Node3D=art.pivot(root,"GatePanels",Vector3.ZERO)
	for side in [-1.0,1.0]:
		var leaf:Node3D=art.pivot(panels,"GateLeft" if side<0 else "GateRight",Vector3(side*6,0,0))
		art.bevel(leaf,"DoorLeaf",Vector3(0,2.25,0),Vector3(12,4.5,.65),IVORY,.15)
		art.bevel(leaf,"RecessedPanel",Vector3(0,2.3,-.36),Vector3(11.2,3.65,.15),"54747c",.12)
		for y in [.65,3.85]:art.bevel(leaf,"StructuralBrace",Vector3(0,y,-.47),Vector3(11.5,.25,.20),DARK,.045)
		for x in [-4,0,4]:
			art.bevel(leaf,"VerticalRib",Vector3(x,2.3,-.48),Vector3(.22,3.1,.18),DARK,.045)
			_bolt(leaf,Vector3(x,.67,-.59),art);_bolt(leaf,Vector3(x,3.83,-.59),art)
		art.box(leaf,"WarningStripe",Vector3(0,1.2,-.47),Vector3(11.2,.25,.04),BRASS,.3)
		art.box(leaf,"StatusStrip",Vector3(-side*5.73,2.3,-.49),Vector3(.10,3.3,.035),TEAL,0,.6)
		art.bevel(leaf,"IdentificationPlate",Vector3(0,2.9,-.60),Vector3(4.4,.7,.05),IVORY,.035)
		_text(leaf,"CONTENÇÃO",Vector3(0,2.9,-.64),art,54,"29474e")
	for side in [-1.0,1.0]:art.bevel(root,"GatePillar",Vector3(side*12.35,2.45,.10),Vector3(.7,4.9,1.2),DARK,.09)
	art.bevel(root,"MotorHeader",Vector3(0,4.85,.10),Vector3(25.4,.65,1.2),DARK,.08)
	for x in [-8,0,8]:art.bevel(root,"HeaderMotor",Vector3(x,4.88,-.58),Vector3(1.4,.35,.3),BRASS,.06)

static func _cart(root:Node3D,art:Script) -> void:
	art.bevel(root,"CargoDeck",Vector3(0,.56,0),Vector3(1.65,.20,2.0),STEEL,.055)
	art.bevel(root,"DeckInset",Vector3(0,.675,0),Vector3(1.39,.03,1.72),DARK,.012)
	for x in [-.71,.71]:
		for z in [-.69,.69]:
			var wheel:Node3D=art.pivot(root,"Wheel",Vector3(x,.25,z))
			var tyre:MeshInstance3D=art.cylinder(wheel,"Rubber",Vector3.ZERO,.25,.17,DARK,-1,.2);tyre.rotation.z=PI/2
			var hub:MeshInstance3D=art.cylinder(wheel,"Hub",Vector3(signf(x)*.095,0,0),.13,.04,BRASS,-1,.6);hub.rotation.z=PI/2
			art.bevel(root,"CasterFork",Vector3(x,.43,z),Vector3(.12,.20,.25),IVORY,.03)
		_rod(root,"HandleUpright",Vector3(x,.64,.83),Vector3(x,1.45,.83),.045,DARK,art)
	_rod(root,"HandleGrip",Vector3(-.71,1.45,.83),Vector3(.71,1.45,.83),.075,BRASS,art)
	for z in [-.88,.88]:art.bevel(root,"Bumper",Vector3(0,.55,z),Vector3(1.74,.12,.16),DARK,.03)
	for i in 3:art.box(root,"DeckRail",Vector3(-.46+i*.46,.70,0),Vector3(.035,.025,1.52),STEEL)

static func _tree(root:Node3D,art:Script) -> void:
	art.cylinder(root,"AnchoredPlanter",Vector3(0,.32,0),.72,.64,DARK,.82,.3)
	art.ring(root,"PotRim",Vector3(0,.65,0),.84,BRASS)
	art.cylinder(root,"Soil",Vector3(0,.65,0),.68,.06,"34483f")
	for side in [-1.0,1.0]:
		_rod(root,"HydroponicTube",Vector3(side*.57,.13,.22),Vector3(side*.57,.74,.22),.06,STEEL,art)
		art.ball(root,"NutrientLight",Vector3(side*.58,.40,-.38),Vector3(.12,.16,.06),TEAL,.5)
	var points:=[Vector3(0,.66,0),Vector3(-.13,1.20,.06),Vector3(.05,1.75,.02),Vector3(.13,2.24,.02),Vector3(0,2.73,0)]
	for i in 4:_rod(root,"GrownTrunk",points[i],points[i+1],.14-i*.025,"697d70",art)
	for i in 5:
		var angle:float=i*TAU/5
		var base:=Vector3(.04,1.47+i*.17,.02)
		var bend:=base+Vector3(cos(angle)*.50,.23,sin(angle)*.50)
		var end:=base+Vector3(cos(angle)*.84,.50,sin(angle)*.84)
		_rod(root,"Branch",base,bend,.065,"697d70",art);_rod(root,"BranchTip",bend,end,.043,"7d9980",art)
		var leaf:MeshInstance3D=art.ball(root,"BioluminescentLeaf",end,Vector3(.72,.21,.40),"60bba1",.15);leaf.rotation=Vector3(.20,angle,-.20)
		art.ball(root,"LuminousFruit",end+Vector3(0,-.13,0),Vector3(.16,.25,.16),"b7dba0",.6)
		_rod(root,"LeafVein",end+Vector3(-cos(angle)*.18,.08,-sin(angle)*.18),end+Vector3(cos(angle)*.18,.08,sin(angle)*.18),.012,"b3dac0",art)
	art.ball(root,"Crown",Vector3(0,2.83,0),Vector3(.63,.32,.55),"70c3b2",.2)
	art.bevel(root,"SpecimenPlate",Vector3(0,.30,-.81),Vector3(.63,.24,.045),IVORY,.03)
	_text(root,"FLORA · 09",Vector3(0,.30,-.84),art,10,"294b4b")

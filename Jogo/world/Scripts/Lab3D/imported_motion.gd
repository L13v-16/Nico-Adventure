extends RefCounted
## Bind-space anatomy and editable bone animation for the two supplied static meshes.
const NAMES:=["Root","Hips","Spine","Head","ArmL","ForearmL","HandL","ArmR","ForearmR","HandR","LegL","ShinL","FootL","LegR","ShinR","FootR","Tail","TailTip"]
static func bones(kind:String,h:float) -> Array:
	var points:=[Vector3.ZERO,Vector3(0,.28,0),Vector3(0,.48,0),Vector3(0,.62,-.09),Vector3(-.19,.51,-.01),Vector3(-.21,.39,-.04),Vector3(-.21,.27,-.09),Vector3(.19,.51,-.01),Vector3(.21,.39,-.04),Vector3(.21,.27,-.09),Vector3(-.105,.28,0),Vector3(-.11,.15,-.01),Vector3(-.11,.045,-.07),Vector3(.105,.28,0),Vector3(.11,.15,-.01),Vector3(.11,.045,-.07),Vector3(0,.28,.13),Vector3(0,.30,.47)]
	if kind=="largato":
		points[1]=Vector3(0,.29,0);points[2]=Vector3(.02,.51,-.02);points[3]=Vector3(.07,.69,-.09)
		points[4]=Vector3(-.15,.60,-.02);points[5]=Vector3(-.18,.48,-.04);points[6]=Vector3(-.15,.40,-.04)
		points[7]=Vector3(.22,.61,0);points[8]=Vector3(.26,.43,-.05);points[9]=Vector3(.16,.61,-.22)
		points[16]=Vector3(0,.29,.13);points[17]=Vector3(.12,.52,.42)
	var parents:=[-1,0,1,2,2,4,5,2,7,8,1,10,11,1,13,14,1,16]
	var result:=[]
	for i in NAMES.size():result.append({"name":NAMES[i],"parent":parents[i],"at":points[i]*h})
	return result

static func blend(a:float,b:float,t:float) -> float:return smoothstep(a,b,t)
static func weights(kind:String,p:Vector3,color:Color=Color.WHITE) -> Dictionary:
	var w:Dictionary={1:1.0}
	var dark:bool=maxf(color.r,maxf(color.g,color.b))<.32
	if kind=="nico" and p.y>.28 and p.y<.59 and color.r>.30 and color.r>color.g*1.12 and color.r>color.b*1.4:return {2:1.0}
	if kind=="nico" and p.y>.18 and p.y<.38 and absf(p.x)>.105 and p.z<.14 and dark:return {6 if p.x<0 else 9:1.0}
	var head:float=blend(.55,.63,p.y) if kind=="nico" else blend(.64,.72,p.y)
	var tail:float=blend(.16,.28,p.z)*(1-blend(.43,.51,p.y))
	if kind=="largato":tail=blend(.17,.30,p.z)
	var arm:float=blend(.11,.175,absf(p.x))*(1-blend(.51,.57,p.y))*blend(.13,.19,p.y)*(1-blend(.15,.23,p.z))
	if kind=="largato":
		arm=blend(.12,.19,absf(p.x))*blend(.22,.30,p.y)*(1-blend(.63,.72,p.y))*(1-blend(.13,.22,p.z))
		# Rigidly follow the hand for the oversized syringe that is part of this mesh.
		var syringe_end:=Vector3(-.31,.02,.17);var syringe_start:=Vector3(-.15,.40,-.04)
		var axis:Vector3=syringe_start-syringe_end
		var t:float=clampf((p-syringe_end).dot(axis)/axis.length_squared(),0,1)
		var distance:float=p.distance_to(syringe_end+axis*t)
		if p.x<-.10 and distance<.15 and p.z<.24 and (p.y>.19 or (p.z>.04 and (not dark or p.x<-.245))):return {6:1.0}
	var leg:float=(1-blend(.25,.34,p.y))*(1-tail)*(1-arm)
	var spine:float=blend(.27,.44,p.y)*(1-head)*(1-tail)*(1-arm)
	w={1:maxf(.001,1-head-tail-arm-leg-spine)}
	if spine>0:w[2]=spine
	if head>0:w[3]=head
	if tail>0:
		var tip:float=blend(.34,.63,p.z) if kind=="nico" else blend(.36,.52,p.y)
		w[16]=tail*(1-tip);w[17]=tail*tip
	if arm>0:
		var upper:int=4 if p.x<0 else 7
		var elbow:float=1-blend(.35,.45,p.y)
		if kind=="largato" and p.x>0:elbow=blend(.40,.57,p.y)
		w[upper]=arm*(1-elbow);w[upper+1]=arm*elbow*.6;w[upper+2]=arm*elbow*.4
	if leg>0:
		var hip:int=10 if p.x<0 else 13
		var knee:float=1-blend(.10,.20,p.y)
		w[hip]=leg*(1-knee);w[hip+1]=leg*knee*.8;w[hip+2]=leg*knee*.2
	return w

static func library(kind:String,bone_data:Array) -> AnimationLibrary:
	var lib:=AnimationLibrary.new()
	for action in ["RESET","idle","run","jump","fall","double_jump","slide","slam","spin","attack","cast_fire","cast_ice","hurt","death","carry_idle","carry_run","talk","operate","tail","melt"]:
		var animation:=Animation.new()
		animation.length=.60 if action in ["run","carry_run"] else (.45 if action in ["jump","double_jump","attack","cast_fire","cast_ice","hurt","spin","slam"] else (1.0 if action in ["death","melt"] else 1.8))
		animation.loop_mode=Animation.LOOP_LINEAR if action in ["idle","run","fall","slide","carry_idle","carry_run","talk","operate"] else Animation.LOOP_NONE
		for bone in NAMES:
			var track:=animation.add_track(Animation.TYPE_ROTATION_3D);animation.track_set_path(track,NodePath("Rig/Skeleton3D:"+bone));animation.track_set_interpolation_type(track,Animation.INTERPOLATION_CUBIC)
			for key in 17:
				var t:=float(key)/16
				animation.track_insert_key(track,t*animation.length,Quaternion.from_euler(pose(kind,action,bone,t)))
		var bob:=animation.add_track(Animation.TYPE_VALUE);animation.track_set_path(bob,NodePath("Rig:position"))
		for key in 17:
			var t:=float(key)/16;var y:=0.0
			if action in ["run","carry_run"]:y=sin(t*TAU*2)*.012+.015
			elif action in ["idle","talk","carry_idle","operate"]:y=(1-cos(t*TAU))*.006
			elif action=="slide":y=-.22
			elif action=="death":y=-smoothstep(.1,.75,t)*.15
			animation.track_insert_key(bob,t*animation.length,Vector3(0,y,0))
		lib.add_animation(action,animation)
	return lib

static func pose(kind:String,action:String,bone:String,t:float) -> Vector3:
	var r:=Vector3.ZERO;var wave:=sin(t*TAU);var pulse:=sin(t*PI);var left:bool=bone.ends_with("L");var side:float=-1 if left else 1
	if action=="RESET":return r
	if bone=="Tail":r.y=wave*.10
	if bone=="TailTip":r.y=sin(t*TAU+.7)*.12
	if bone=="Head":r.z=wave*.025
	if action in ["run","carry_run"]:
		if bone.begins_with("Leg"):r.x=wave*side*.55
		elif bone.begins_with("Shin"):r.x=maxf(0,-wave*side)*-.75
		elif bone.begins_with("Arm"):r.x=-wave*side*(.16 if kind=="nico" else .10)
		elif bone.begins_with("Forearm"):r.x=-.18
		elif bone=="Spine":r.x=-.08;r.y=wave*.06
		elif bone=="Tail":r.y=wave*.19;r.x=.1
	if action in ["carry_idle","carry_run"] and (bone.begins_with("Arm") or bone.begins_with("Forearm")):r=Vector3(.30 if bone.begins_with("Arm") else .08,0,side*.08)
	if action in ["jump","double_jump","fall","slam"]:
		if bone.begins_with("Leg"):r.x=.32 if action!="slam" else .9
		elif bone.begins_with("Shin"):r.x=-.6 if action!="slam" else -1.0
		elif bone.begins_with("Arm"):r=Vector3(.15 if action!="slam" else .3,0,side*.18)
		elif bone=="Tail":r.x=.35
		elif bone=="Spine" and action=="double_jump":r.x=pulse*.25
	if action=="slide":
		if bone.begins_with("Leg"):r.x=1.1
		elif bone.begins_with("Shin"):r.x=-1.35
		elif bone.begins_with("Arm"):r.x=-.35;r.z=side*.3
		elif bone=="Spine":r.x=-.30
		elif bone=="Head":r.x=.22
	if action=="spin":
		if bone.begins_with("Arm"):r.z=side*.28
		elif bone.begins_with("Forearm"):r.x=-.22
		elif bone=="Spine":r.y=sin(t*TAU*2)*.10
		elif bone=="Tail":r.y=.6
	if action in ["attack","cast_fire","cast_ice"]:
		if bone==("ArmL" if kind=="largato" else "ArmR"):r.x=pulse*.28;r.z=pulse*.06
		elif bone==("ForearmL" if kind=="largato" else "ForearmR"):r.x=pulse*.08
		elif bone=="Spine":r.y=pulse*-.20
		elif bone=="Head":r.x=-pulse*.08
	if action in ["talk","operate"]:
		if bone=="Head":r.x=wave*.07;r.y=cos(t*TAU)*.04
		if bone.begins_with("Arm"):r.x=(.08 if action=="operate" else .04)+wave*.04
		if bone.begins_with("Forearm"):r.x=.06+wave*.04
	if action=="tail":
		if bone=="Tail":r.y=pulse*1.4
		elif bone=="TailTip":r.y=sin(t*PI-.3)*.8
		elif bone=="Spine":r.y=-pulse*.35
	if action=="hurt":
		if bone=="Spine":r.x=pulse*.22;r.z=wave*.10
		elif bone=="Head":r.x=pulse*-.3
		elif bone.begins_with("Arm"):r.z=side*.22*pulse
	if action in ["death","melt"]:
		if bone=="Spine":r.x=smoothstep(.1,.8,t)*.9
		elif bone=="Head":r.x=smoothstep(.15,.9,t)*.45
		elif bone.begins_with("Arm"):r.z=side*.25*smoothstep(0,.7,t)
	if kind=="largato" and bone.begins_with("Leg"):r*=.7
	return r

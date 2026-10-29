extends RefCounted
## Dedicated rigs for the supplied laboratory antagonists; Nico's rig is unchanged.
const Base=preload("res://world/Scripts/Lab3D/imported_motion.gd")
const NAMES=Base.NAMES
static func bones(kind:String,h:float) -> Array:
	if kind=="largato":return Base.bones(kind,h)
	var points:=[Vector3.ZERO,Vector3(0,.39,0),Vector3(0,.56,0),Vector3(-.02,.70,-.03),Vector3(-.16,.57,-.02),Vector3(-.20,.44,-.08),Vector3(-.20,.33,-.16),Vector3(.16,.57,0),Vector3(.20,.44,.07),Vector3(.19,.32,.17),Vector3(-.055,.38,0),Vector3(-.055,.20,-.08),Vector3(-.045,.045,-.15),Vector3(.055,.38,0),Vector3(.055,.20,.09),Vector3(.045,.06,.15),Vector3(0,.37,.15),Vector3(0,.23,.52)]
	var parents:=[-1,0,1,2,2,4,5,2,7,8,1,10,11,1,13,14,1,16];var result:=[]
	for i in NAMES.size():result.append({"name":NAMES[i],"parent":parents[i],"at":points[i]*h})
	return result
static func weights(kind:String,p:Vector3,color:Color) -> Dictionary:
	var dark:=maxf(color.r,maxf(color.g,color.b))<.30
	if kind=="largato":
		# Keep each boot rigid and exclude it before testing the adjacent syringe.
		if p.y<.10 and p.z<.10 and absf(p.x)>.04 and absf(p.x)<.26:return {12 if p.x<0 else 15:1.0}
		# The old .15-radius selection included the near boot. The narrow syringe
		# axis and color/height exclusion keep the boot attached to its own leg.
		var end:=Vector3(-.31,.02,.17);var start:=Vector3(-.15,.40,-.04);var axis:=start-end
		var u:=clampf((p-end).dot(axis)/axis.length_squared(),0,1)
		var radius:=p.distance_to(end+axis*u)
		var metal:bool=absf(color.r-color.g)<.12 and absf(color.g-color.b)<.12 and color.g>.13
		var serum:bool=color.g>.07 and color.g>color.r*1.15 and color.g>color.b*1.1
		var lower_cap:bool=p.x<-.235 and p.y<.18 and p.z>.07 and radius<.18
		if lower_cap or (p.x<-.115 and radius<.15 and (p.y>.18 or ((metal or serum) and p.y>.005))):
			return {6:1.0}
	var tail:float=smoothstep(.17,.29,p.z) if kind=="largato" else smoothstep(.20,.34,p.z)*(1-smoothstep(.36,.45,p.y))
	var head:float=smoothstep(.60,.68,p.y)*(1-tail) if kind=="largato" else smoothstep(.62,.72,p.y)*(1-tail)
	var arm:float=smoothstep(.13,.205,absf(p.x))*smoothstep(.28,.36,p.y)*(1-smoothstep(.61,.69,p.y))*(1-smoothstep(.12,.22,p.z))*(1-head)*(1-tail)
	if kind=="wolf":arm=smoothstep(.13,.18,absf(p.x))*smoothstep(.24,.33,p.y)*(1-smoothstep(.56,.65,p.y))*(1-head)*(1-tail)
	var cloth:bool=kind=="largato" and p.y>.13 and color.r>.28 and color.g>.25 and color.b>.19 and color.g<color.r*1.25
	var leg:float=(1-smoothstep(.20,.29,p.y))*(1-tail)*(1-arm)*(0 if cloth else 1)
	if kind=="wolf":leg=(1-smoothstep(.32,.43,p.y))*(1-tail)*(1-arm)
	var spine:float=smoothstep(.26,.48,p.y)*(1-head)*(1-tail)*(1-arm)*(1-leg)
	if kind=="wolf":spine=smoothstep(.40,.56,p.y)*(1-head)*(1-tail)*(1-arm)*(1-leg)
	var w:Dictionary={1:maxf(.001,1-head-tail-arm-leg-spine)}
	if head>0:w[3]=head
	if spine>0:w[2]=spine
	if tail>0:
		var tip:float=smoothstep(.36,.53,p.y) if kind=="largato" else smoothstep(.36,.65,p.z)
		w[16]=tail*(1-tip);w[17]=tail*tip
	if arm>0:
		var upper:int=4 if p.x<0 else 7
		var elbow:float=1-smoothstep(.38,.51,p.y)
		if kind=="largato" and p.x>0:elbow=smoothstep(.40,.57,p.y)
		w[upper]=arm*(1-elbow);w[upper+1]=arm*elbow*.6;w[upper+2]=arm*elbow*.4
	if leg>0:
		var hip:int=10 if p.x<0 else 13
		var knee:float=1-smoothstep(.10,.20,p.y)
		if kind=="wolf":knee=1-smoothstep(.12,.26,p.y)
		w[hip]=leg*(1-knee);w[hip+1]=leg*knee*.65;w[hip+2]=leg*knee*.35
	return w
static func library(kind:String,_bones:Array) -> AnimationLibrary:
	var lib:=AnimationLibrary.new()
	for action in ["RESET","idle","run","jump","fall","attack","tail","hurt","talk","operate","melt","death","warn_tail","warn_shoot","warn_jump"]:
		var a:=Animation.new();a.length=duration(action)
		a.loop_mode=Animation.LOOP_LINEAR if action in ["idle","run","fall","talk","operate"] else Animation.LOOP_NONE
		for bone in NAMES:
			var track:=a.add_track(Animation.TYPE_ROTATION_3D);a.track_set_path(track,NodePath("Rig/Skeleton3D:"+bone));a.track_set_interpolation_type(track,Animation.INTERPOLATION_CUBIC)
			for key in 25:
				var t:=float(key)/24;a.track_insert_key(track,t*a.length,Quaternion.from_euler(pose(kind,action,bone,t)))
		# Body breathing never translates the feet through the ground.
		var breath:=a.add_track(Animation.TYPE_SCALE_3D);a.track_set_path(breath,NodePath("Rig/Skeleton3D:Spine"))
		for key in 25:
			var t:=float(key)/24;var y:=1.0+(1-cos(t*TAU))*.002 if action in ["idle","talk","operate"] else 1.0
			a.track_insert_key(breath,t*a.length,Vector3(1,y,1))
		lib.add_animation(action,a)
	return lib
static func duration(action:String) -> float:
	if action=="run":return .72
	if action=="tail" or action=="hurt":return .45
	if action=="attack":return .50
	if action=="jump":return .95
	if action.begins_with("warn_") or action in ["death","melt"]:return 1.0
	return 2.4
static func pose(kind:String,action:String,bone:String,t:float) -> Vector3:
	var r:=Vector3.ZERO
	if action=="RESET":return r
	var wave:=sin(t*TAU);var pulse:=sin(t*PI);var side:float=-1 if bone.ends_with("L") else 1
	if bone=="Head":r.z=wave*.012
	if bone=="Tail":r.y=wave*.045
	if bone=="TailTip":r.y=sin(t*TAU)*.045
	match action:
		"run":
			if bone.begins_with("Leg"):r.x=wave*side*(.23 if kind=="largato" else .12)
			elif bone.begins_with("Shin"):r.x=-maxf(0,-wave*side)*.20
			elif bone.begins_with("Arm"):r.x=-wave*side*.065
			elif bone=="Spine":r.y=wave*.025
			elif bone=="Tail":r.y=wave*.10
		"talk","operate":
			if bone=="Head":r.x=wave*.045;r.y=wave*.025
			elif bone.begins_with("Arm"):r.x=wave*(.06 if action=="operate" else .035)
			elif bone=="Spine":r.y=wave*.012
		"warn_tail":
			var wind:=smoothstep(0,.8,t)
			if bone=="Tail":r.y=-.30*wind
			elif bone=="TailTip":r.y=-.15*wind
			elif bone=="Spine":r.y=.07*wind
		"warn_shoot":
			if bone=="ArmL":r.x=.08*smoothstep(0,.75,t)
			elif bone=="Head":r.x=-.035*smoothstep(0,.75,t)
		"warn_jump":
			if bone.begins_with("Leg"):r.x=.07*smoothstep(0,.8,t)
			elif bone.begins_with("Shin"):r.x=-.07*smoothstep(0,.8,t)
			elif bone=="Spine":r.x=.035*smoothstep(0,.8,t)
		"attack":
			if bone=="ArmL":r.x=pulse*.16;r.z=pulse*.025
			elif bone=="ForearmL":r.x=pulse*.06
			elif bone=="Spine":r.y=-pulse*.055
		"tail":
			var swing:=sin(t*PI*1.5)*sin(t*PI)
			if bone=="Tail":r.y=swing*.70
			elif bone=="TailTip":r.y=swing*.32
			elif bone=="Spine":r.y=-swing*.075
		"jump","fall":
			if bone.begins_with("Leg"):r.x=pulse*.13
			elif bone.begins_with("Shin"):r.x=-pulse*.20
			elif bone.begins_with("Arm"):r.z=side*pulse*.08
		"hurt":
			if bone=="Spine":r.x=pulse*.065
			elif bone=="Head":r.x=-pulse*.09
			elif bone.begins_with("Arm"):r.z=side*pulse*.06
		"death","melt":
			if bone=="Spine":r.x=smoothstep(.1,.9,t)*.16
			elif bone=="Head":r.x=smoothstep(.1,.9,t)*.12
			elif bone.begins_with("Arm"):r.z=side*.08*smoothstep(.1,.9,t)
	return r

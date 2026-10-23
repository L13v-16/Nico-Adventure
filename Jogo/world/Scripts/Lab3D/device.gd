extends Node3D
const Art=preload("res://world/Scripts/Lab3D/models.gd")
var level:Node3D
var kind:="cherry"
var sector:=0
var cherry_id:=""
var destination:=0
var width:=3.0
var depth:=3.0
var rise:=6.0
var circuit:=""
var enabled:=true
var active:=false
var collected:=false
var reversed:=false
var frozen_left:=0.0
var life:=-1.0
var clock:=0.0
var _cooldown:=0.0
var _body:PhysicsBody3D
var _art:Node3D
var _label:Label3D
var _phase:="waiting"
var _wait:=0.0
var _activated:=false
var travel:=Vector3.ZERO
func _ready() -> void:
	add_to_group("lab3d_devices")
	if kind=="cherry" and Save.is_free_mode() and Save.has_collected_cherry("fase_5",cherry_id):collected=true;queue_free();return
	var model_kind:String={"cherry":"cherry","checkpoint":"flag","keycard":"keycard","lever":"lever","heat":"terminal_heat","cold":"terminal_cold","injector":"injector","tank":"tank","camera":"drone"}.get(kind,"")
	_art=Art.instantiate(model_kind) if model_kind!="" else Node3D.new();add_child(_art)
	if kind in ["heat","cold","injector","tank","camera"]:_art.rotation.y=PI
	if kind in ["heat","cold","injector","pool","camera","press","tank","laser"]:
		add_to_group("lab3d_targets");_target_shape(Vector3(width,.22,depth) if kind=="pool" else Vector3(1.5,2.5,1.3),Vector3(0,0 if kind=="pool" else 1.1,0))
	match kind:
		"fragment":
			for side in [-1.0,1.0]:
				var crystal:=Art.cylinder(_art,"Crystal",Vector3(0,side*.24,0),.28,.48,"efcb72",0);crystal.rotation.x=PI if side<0 else 0
			_art.position.y=1.0
		"keycard":
			_art.position.y=1.2;Art.label(self,"CARTÃO",Vector3(0,2.1,0),23,"ffe39a")
		"cherry":_art.position.y=.8
		"pool":
			Art.box(_art,"Liquid",Vector3(0,-.035,0),Vector3(width,.12,depth),"65b78c",0,.15)
			for i in 8:Art.ball(_art,"Bubble",Vector3(sin(i*2)*width*.35,.09,cos(i*3)*depth*.35),Vector3(.17,.1,.17),"bae887",.25)
		"door":
			_body=StaticBody3D.new();_body.collision_layer=1;add_child(_body)
			var shape:=BoxShape3D.new();shape.size=Vector3(5.4,4.5,.35);var col:=CollisionShape3D.new();col.shape=shape;col.position.y=2.25;_body.add_child(col)
			for side in [-1.0,1.0]:Art.box(_art,"DoorLeaf",Vector3(side*1.28,2.1,0),Vector3(2.5,4.2,.28),"a9b4af",.5)
			Art.box(_art,"Seam",Vector3(0,2.1,.16),Vector3(.06,4.1,.05),"50cdbd",0,.5)
			_label=Art.label(self,"E · PRÓXIMO SETOR",Vector3(0,4.7,.3),25)
		"lift","ferry":
			if travel==Vector3.ZERO:travel=Vector3(0,rise,0)
			_body=AnimatableBody3D.new();_body.collision_layer=1;add_child(_body)
			var shape:=BoxShape3D.new();shape.size=Vector3(4,.26,4);var col:=CollisionShape3D.new();col.shape=shape;col.position.y=-.13;_body.add_child(col)
			Art.box(_body,"Platform",Vector3(0,-.14,0),Vector3(4,.28,4),"48677d",.5)
			for x in [-1.8,1.8]:Art.box(_body,"Rim",Vector3(x,.025,0),Vector3(.09,.06,3.7),"6cd3e3",0,.5)
			for x in [-2.4,2.4]:Art.box(_art,"GuideRail",Vector3(x,rise*.5,0) if kind=="lift" else Vector3(x,-.6,travel.z*.5),Vector3(.16,rise+1,.24) if kind=="lift" else Vector3(.16,.25,absf(travel.z)+5),"6c8393",.5)
			_label=Art.label(_body,"EMBARQUE",Vector3(0,.18,0),21,"a9e9de");_label.rotation.x=-PI/2
		"conveyor":
			Art.box(_art,"Belt",Vector3(0,.015,0),Vector3(width,.08,depth),"2e4552",.4)
			for i in range(0,int(depth*3)):Art.box(_art,"Tread",Vector3(0,.07,-depth*.5+i*.33),Vector3(width*.9,.035,.055),"8a9b9e")
		"press":
			Art.box(_art,"Gantry",Vector3(0,4.2,0),Vector3(6,.5,2),"284353",.5)
			for x in [-2.7,2.7]:Art.box(_art,"Column",Vector3(x,2,0),Vector3(.3,4,.4),"8da5ad",.4)
			_body=AnimatableBody3D.new();_body.collision_layer=1;add_child(_body)
			var shape:=BoxShape3D.new();shape.size=Vector3(3.6,1,1.6);var col:=CollisionShape3D.new();col.shape=shape;_body.add_child(col)
			Art.box(_body,"Ram",Vector3.ZERO,shape.size,"bdc7b5",.6);_body.position.y=3.5
			Art.box(_body,"HazardBand",Vector3(0,-.35,.82),Vector3(3.6,.2,.04),"edb45b")
		"laser":
			for x in [-width*.5,width*.5]:Art.box(_art,"Post",Vector3(x,.8,0),Vector3(.25,1.6,.4),"456271",.4)
			Art.box(_art,"Beam",Vector3(0,.75,0),Vector3(width,.09,.09),"f19b88",0,1.2)
		"spring","boost":
			Art.cylinder(_art,"Base",Vector3(0,.12,0),1.0,.24,"2f4b62",-1,.5)
			Art.cylinder(_art,"Plate",Vector3(0,.32,0),.8,.12,"dfab60" if kind=="spring" else "66d9df")
			_label=Art.label(self,"↑" if kind=="spring" else ">>",Vector3(0,.41,0),50,"183644");_label.rotation.x=-PI/2
		"rescue":
			Art.cylinder(_art,"Base",Vector3(0,.15,0),2,.3,"3c5268",-1,.4)
			for i in 12:
				var a:=i*TAU/12;Art.cylinder(_art,"Bar",Vector3(sin(a)*1.75,1.65,cos(a)*1.75),.045,3.0,"8f9da1",-1,.4)
			Art.ring(_art,"Rim",Vector3(0,3.2,0),1.85,"627f91")
			var urso:=Art.instantiate("urso");urso.name="Urso";urso.position.y=.3;_art.add_child(urso)
			_label=Art.label(self,"URSO",Vector3(0,3.7,0),34,"f5d895")
		"record":_label=Art.label(self,"LG-17\nEstabilizador do enxerto de Largato",Vector3(0,2,0),24,"9be3ce")
	if kind in ["heat","cold","injector"]:_label=Art.label(self,"FOGO" if kind=="heat" else ("GELO" if kind=="cold" else "INJETOR · E"),Vector3(0,2.1,0),25,"f2deb0")
func _target_shape(size:Vector3,at:Vector3) -> void:
	_body=StaticBody3D.new();_body.collision_layer=17 if kind in ["heat","cold","injector","tank"] else 16;_body.set_meta("receiver",self);add_child(_body)
	var shape:=BoxShape3D.new();shape.size=size;var col:=CollisionShape3D.new();col.shape=shape;col.position=at;_body.add_child(col)
func aim_point() -> Vector3:return global_position+Vector3.UP*((-.05 if frozen_left>0 else .05) if kind=="pool" else 1.2)
func accepts(element:String) -> bool:
	if kind=="heat":return element=="fire" and level.boss.active and level.boss.phase==2
	if kind=="cold":return element=="ice" and level.boss.active and level.boss.phase==2
	if kind=="injector":return level.boss.active and level.boss.phase==3
	if kind=="pool":return frozen_left<=0 if element=="ice" else frozen_left>0
	return kind in ["pool","camera","press","tank","laser"]
func _physics_process(delta:float) -> void:
	if sector!=level.sector or level.intro_active or level.completed:return
	clock+=delta;frozen_left=maxf(0,frozen_left-delta);_cooldown=maxf(0,_cooldown-delta)
	if life>0:
		life-=delta
		if life<=0:queue_free();return
	var player:CharacterBody3D=level.player;var gap:Vector3=player.global_position-global_position
	var near:=absf(gap.x)<width*.5 and absf(gap.z)<depth*.5 and absf(gap.y)<.8
	match kind:
		"fragment":
			_art.rotation.y+=delta
			if not collected and (gap+Vector3(0,-.7,0)).length()<1.25:collected=true;level.secrets_found+=1;Sfx.checkpoint();level.notice("Registro secreto encontrado: %d/%d."%[level.secrets_found,level.total_secrets]);queue_free()
		"cherry":
			_art.rotation.y+=delta;_art.position.y=.8+sin(clock*3)*.08
			var radius:float=player.equipment.get_magnet_radius()/25.0
			if radius>0 and gap.length()<radius:
				var ray:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*.7,player.global_position+Vector3.UP,1)
				if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():global_position=global_position.move_toward(player.global_position,8*delta)
			if not collected and (gap+Vector3(0,-.6,0)).length()<1.25 and player.collect_item(cherry_id):collected=true;level.spark(global_position+Vector3.UP,"ed9b9d");queue_free()
		"keycard":
			_art.rotation.y+=delta
			if gap.length()<2:level.access_card=true;level.notice("Cartão de acesso obtido. E na porta à frente.");Sfx.checkpoint();queue_free()
		"checkpoint":
			_art.get_node("Flag").rotation.y=sin(clock*3)*.08
			if gap.length()<2 and not active:
				active=true;player.respawn_position=global_position+Vector3(.8,.1,.5);level.checkpoint_sector=sector;player.heal_one();Sfx.checkpoint();level.notice("Checkpoint registrado. Um coração recuperado.")
		"pool":
			_body.collision_layer=1|16 if frozen_left>0 else 16
			_body.get_child(0).position.y=-.11 if frozen_left>0 else 0.0
			var liquid:MeshInstance3D=_art.get_node("Liquid");liquid.material_override=Art.material("94e7ee" if frozen_left>0 else "65b78c",0,.2)
			for i in range(1,_art.get_child_count()):_art.get_child(i).position.y=.08 if frozen_left>0 else .09+absf(sin(clock*2+i))*.14
			if near and _cooldown<=0:
				if _activated:player.velocity.y=15;_cooldown=1.0
				elif frozen_left<=0:player.take_damage(1,global_position)
		"lift","ferry":_tick_lift(delta,player)
		"conveyor":
			if near:player.position+=Vector3(0,0,(3 if reversed else -3)*delta)
		"press":
			var cycle:=fposmod(clock,4.8);var lowered:=cycle>3.0 and cycle<3.65 and frozen_left<=0
			_body.position.y=move_toward(_body.position.y,.55 if lowered else 3.5,20*delta)
			if lowered and absf(gap.x)<2 and absf(gap.z)<1.0 and gap.y<1.8:player.take_damage(1,global_position)
			_art.get_node("Gantry").material_override=Art.material("bd8953" if cycle>2.1 and cycle<3.65 else "284353",.4)
		"laser":
			var on:=fposmod(clock,4.5)>2.5 and frozen_left<=0;_art.get_node("Beam").visible=on
			if on and absf(gap.x)<width*.5 and absf(gap.z)<.4 and gap.y<1.1:player.take_damage(1,global_position)
		"camera":
			_art.rotation.y=PI+sin(clock*.65)*.7
			if frozen_left<=0 and _cooldown<=0 and gap.length()<12 and Vector2(player.velocity.x,player.velocity.z).length()>1:
				var ray:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP,player.global_position+Vector3.UP,1)
				if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():level.enemy_shot(global_position+Vector3.UP,player.global_position+Vector3.UP,11);_cooldown=2.4;Sfx.play("lab_scan",-12)
		"spring":
			if near and _cooldown<=0:player.velocity.y=16;_cooldown=1;Sfx.jump()
		"boost":
			if near:player.velocity.z=-18;player.boost=minf(100,player.boost+30*delta)
		"heat","cold","injector":
			var confirmed:bool=(level.boss.heated>0 if kind=="heat" else level.boss.cooled>0) if kind!="injector" else level.boss.injector_reversed
			_label.modulate=Color("9ce4bd") if confirmed else Color("f2deb0")
func _tick_lift(delta:float,player:CharacterBody3D) -> void:
	if not enabled:_label.text="E NA ALAVANCA";return
	var feet:Vector3=player.global_position-_body.global_position
	var aboard:=absf(feet.x)<1.85 and absf(feet.z)<1.85 and absf(feet.y)<.35
	match _phase:
		"waiting":
			_label.text="EMBARQUE"
			if aboard:_phase="boarding";_wait=.65
		"boarding":
			_label.text="↑ SUBINDO";_wait-=delta
			if _wait<=0:_phase="rising"
		"rising":
			_body.position=_body.position.move_toward(travel,2.8*delta)
			if _body.position.distance_to(travel)<.001:_phase="arrived";_wait=1.5
		"arrived":
			_label.text="SAÍDA →"
			_wait=1.5 if aboard else _wait-delta
			if _wait<=0:_phase="returning"
		"returning":
			_body.position=_body.position.move_toward(Vector3.ZERO,4*delta)
			if _body.position.length()<.001:_phase="waiting"
func interact() -> bool:
	match kind:
		"door":
			if not level.access_card:level.notice("Pegue o cartão de acesso antes de entrar.");return true
			level.enter_sector(destination);return true
		"lever":
			reversed=not reversed;_art.get_node("Handle").rotation.x=.55 if reversed else -.55
			for item in get_tree().get_nodes_in_group("lab3d_devices"):
				if item.circuit==circuit and item!=self:item.enabled=true;item.reversed=reversed
			Sfx.play("lab_clink",-8);level.notice("Circuito ligado. A plataforma está pronta para subir.");return true
		"injector":return level.boss.reverse_injector()
		"rescue":
			if level.boss.dead:level.rescue_urso()
			else:level.notice("Largato controla a contenção. Vença-o para libertar Urso.")
			return true
		"record":level.notice("LG-17 estabiliza o enxerto de Largato. O injetor pode inverter o fluxo.");return true
	return false
func take_element(element:String,_source:Vector3,seconds:float=3) -> void:
	if not accepts(element):return
	if kind in ["heat","cold","injector"]:level.boss.machine_element(kind,element);return
	if element=="ice":
		frozen_left=12 if kind=="pool" else maxf(5,seconds);_activated=false;Sfx.play("lab_clink",-10)
		if kind=="pool":level.notice("Ponte de gelo formada: atravesse antes de derreter!")
	elif kind=="pool" and frozen_left>0:
		frozen_left=0;_activated=true;get_tree().create_timer(2).timeout.connect(func():if is_instance_valid(self):_activated=false)
	elif kind=="tank":
		level.spawn_enemy(global_position+Vector3(0,0,1.5),"mutant",sector);level.spark(global_position+Vector3.UP,"96d6ae");queue_free()

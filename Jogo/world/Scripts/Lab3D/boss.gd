extends CharacterBody3D
const Art=preload("res://world/Scripts/Lab3D/models.gd")
var level:Node3D
var active:=false
var dead:=false
var dying:=false
var phase:=1
var health:=4.0
var vulnerable:=0.0
var heated:=0.0
var cooled:=0.0
var injector_heat:=false
var injector_cold:=false
var injector_reversed:=false
var syringe_ammo:=0
var serum_hits:=0
var model:Node3D
var _state:="idle"
var _timer:=1.6
var _clock:=0.0
var _attack:=0
var pattern:="tail"
var dose_unlocked:=false
var _machine_attack:=0
var _wave_radius:=0.0
var _wave_center:=Vector3.ZERO
var _wave:MeshInstance3D
var _spent:=false
var _invulnerable:=0.0
var _face:=Vector3.FORWARD
var _aim:=Vector3.ZERO
var _jump_from:=Vector3.ZERO
var _jump_t:=0.0
var _hazard_left:=0.0
var _hazard_at:=Vector3.ZERO
var _machine_timer:=4.0
var _serum_cooldown:=0.0
var _warning:MeshInstance3D
var _opening:MeshInstance3D
var _lift:Node3D
var _flood:MeshInstance3D
var _intro_seen:=false
var _shot_warning:=0.0
var _shot_recoil:=0.0
var _animation_action:=""
var _hit_flash:=0.0
var _hit_materials:Array[StandardMaterial3D]=[]
func _ready() -> void:
	add_to_group("lab3d_enemies");add_to_group("lab3d_targets");collision_layer=4;collision_mask=1
	var shape:=CapsuleShape3D.new();shape.radius=.75;shape.height=2.8;var col:=CollisionShape3D.new();col.shape=shape;col.position.y=1.4;add_child(col)
	model=Art.instantiate("largato");model.scale=Vector3.ONE*1.25;add_child(model)
	for display:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		var original:=display.mesh.surface_get_material(0)
		if original is StandardMaterial3D:
			var copy:=original.duplicate() as StandardMaterial3D
			display.material_override=copy;_hit_materials.append(copy)
	_warning=Art.ring(level,"BossWarning",Vector3.ZERO,1.4,"f3b05e",.5);_warning.hide()
	_opening=Art.ring(self,"Opening",Vector3(0,3.1,0),.65,"ffe4a1",.5);_opening.hide()
	_lift=Node3D.new();add_child(_lift);Art.cylinder(_lift,"Lift",Vector3(0,-.12,0),1.25,.22,"344d61",-1,.6);_lift.hide()
	_flood=Art.box(level,"RooftopFlood",Vector3(0,level.roof_y+.035,-245),Vector3(23,.07,12),"70bb91",0,.25);_flood.hide()
	_wave=Art.ring(level,"TailShockwave",Vector3.ZERO,1,"b6e1ac",.7);_wave.hide()
func aim_point() -> Vector3:return global_position+Vector3.UP*1.25
func accepts(_element:String) -> bool:return active and not dead and not dying and phase<3
func start_encounter() -> void:
	if active or dead or dying:return
	active=true;level.player.heal_full();level.player._invulnerability_timer=2;level.player.velocity=Vector3.ZERO;level.player.reset_traversal()
	level.player.respawn_position=Vector3(0,level.roof_y+.05,-226);level.checkpoint_sector=3
	if not _intro_seen:
		_intro_seen=true;level.play_cutscene("boss")
	level.notice("Largato: Excelente! A cobaia demonstrou capacidade de subir escadas.")
func _physics_process(delta:float) -> void:
	if level.sector!=3 or level.intro_active or dead or dying:return
	if not active:
		if level.player.position.z<-231:start_encounter()
		return
	_tick_wave(delta)
	_clock+=delta;_timer-=delta;vulnerable=maxf(0,vulnerable-delta);_invulnerable=maxf(0,_invulnerable-delta);_serum_cooldown=maxf(0,_serum_cooldown-delta)
	_opening.visible=vulnerable>0 and not _spent;_lift.visible=phase==2
	var before:=position
	_shot_recoil=maxf(0,_shot_recoil-delta);_hit_flash=maxf(0,_hit_flash-delta)
	model.visible=true
	if phase==1:_containment(delta)
	elif phase==2:_overload(delta)
	else:_last_dose(delta)
	var action:="idle"
	if phase==1:
		match _state:
			"jump":action="jump"
			"warning":action="warn_jump" if pattern=="jump" else ("warn_shoot" if pattern=="volley" else "warn_tail")
			"tail":action="tail"
			"shoot":action="attack"
			"dash":action="run"
			"ring":action="tail"
			"idle":action="run" if position.distance_squared_to(before)>.000001 else "idle"
	elif phase==2:action="idle" if vulnerable>0 else "operate"
	else:action="operate" if _shot_warning>0 else ("attack" if _shot_recoil>0 else "talk")
	if _invulnerable>0:action="hurt"
	_play_action(action)
	for material:StandardMaterial3D in _hit_materials:material.albedo_color=Color.WHITE.lerp(Color("ffb6a1"),clampf(_hit_flash/.18,0,1)*.7)

func _play_action(action:String) -> void:
	var animation:AnimationPlayer=model.get_node("Animations")
	animation.speed_scale=2.0 if action=="tail" or (action=="attack" and phase==3) else (1.4 if action=="attack" else (1.25 if action=="hurt" else 1.0))
	# Select exactly once per tick. A finished one-shot holds its last pose;
	# a cutscene-paused loop resumes without resetting the animation clock.
	if action!=_animation_action or animation.assigned_animation!=action:
		animation.play(action,.12);_animation_action=action
	elif not animation.is_playing() and animation.current_animation!="":animation.play()

func _containment(delta:float) -> void:
	if _state=="jump":
		_jump_t+=delta;var t:=clampf(_jump_t/.95,0,1);position=_jump_from.lerp(_aim,t)+Vector3.UP*sin(t*PI)*5
		if t>=1:position.y=level.roof_y;_open(2.6);_warning.hide();level.shake(.15);Sfx.play("lab_clink",-7)
		return
	position.y=level.roof_y
	match _state:
		"idle":
			var to:Vector3=level.player.position-position;to.y=0
			if to.length()>5:
				position+=to.normalized()*2.2*delta;_face=to.normalized();model.rotation.y=atan2(-_face.x,-_face.z)
			if _timer<=0:
				_attack+=1;pattern=["tail","volley","jump","dash","ring"][(_attack-1)%5];_state="warning";_timer=1.15;_face=to.normalized();model.rotation.y=atan2(-_face.x,-_face.z)
				_aim=level.player.position+_face*1.5;_aim.x=clampf(_aim.x,-11,11);_aim.z=clampf(_aim.z,-253,-231);_aim.y=level.roof_y
				_warning.scale=Vector3.ONE*(3.2 if pattern=="ring" else 1.0);_warning.global_position=_aim+Vector3.UP*.07 if pattern in ["jump","dash","volley"] else position+_face*2+Vector3.UP*.06;_warning.show();level.notice({"tail":"CAUDA · afaste-se ou salte!","volley":"TRÊS DOSES · desvie para o lado!","jump":"SALTO · saia da marca!","dash":"INVESTIDA · ele não corrige a direção!","ring":"ONDA · salte o anel!"}[pattern]);Sfx.play("lab_scan",-8)
		"warning":
			if _timer<=0:
				if pattern=="jump":_state="jump";_jump_t=0;_jump_from=position
				elif pattern=="volley":_fan(_aim+Vector3.UP);_state="shoot";_timer=.7
				elif pattern=="dash":_state="dash";_timer=1.0;_warning.hide()
				elif pattern=="ring":_start_wave();_state="ring";_timer=1.4;_warning.hide()
				else:_state="tail";_timer=.45
		"dash":
			position+=_face*8.5*delta;position.x=clampf(position.x,-11,11);position.z=clampf(position.z,-253,-231)
			var gap:Vector3=level.player.position-position
			if Vector2(gap.x,gap.z).length()<1.8 and gap.y<1.4:level.player.take_damage(1,position)
			if _timer<=0:_open(3.0)
		"ring":
			if _timer<=0:_open(2.8)
		"tail":
			var gap:Vector3=level.player.position-position
			if _timer<.28 and _timer>.05 and Vector2(gap.x,gap.z).length()<4.4 and Vector3(gap.x,0,gap.z).normalized().dot(_face)>.15 and gap.y<1.25:level.player.take_damage(1,position)
			if _timer<=0:_open(2.6)
		"shoot":
			if _timer<=0:_open(2.5)
		"opening":
			if _timer<=0:_state="idle";_timer=1.6
func _open(seconds:float) -> void:
	_state="opening";_timer=seconds;vulnerable=seconds;_spent=false;_warning.hide()
	if phase==2:_unlock_doses();_clear_hazards();_hazard_left=0;_machine_timer=3.3;_flood.hide();level.notice("Máquinas estabilizadas! Largato desce: acerte uma vez.");Sfx.play("lab_door",-8)
func _overload(delta:float) -> void:
	if vulnerable<=0 and _state=="opening":_state="idle";heated=0;cooled=0;_spent=false;_clock=0;_machine_timer=3.3
	var open:=vulnerable>0
	position=position.move_toward(Vector3(0,level.roof_y+(0 if open else 5),-241),7*delta)
	var facing:Vector3=level.player.position-position;model.rotation.y=lerp_angle(model.rotation.y,atan2(-facing.x,-facing.z),1-exp(-delta*5))
	var flood_cycle:=fposmod(_clock,11)
	_flood.visible=not open and flood_cycle>5 and flood_cycle<10
	_flood.material_override=Art.material("91dfe8" if cooled>0 else ("e5ad6a" if flood_cycle<7 else "70bb91"),0,.2)
	if open:return
	heated=maxf(0,heated-delta);cooled=maxf(0,cooled-delta);_machine_timer-=delta
	if heated>0 and cooled>0:_open(5.4);return
	if _machine_timer<=0:
		_machine_timer=5.2;_machine_attack+=1
		if _machine_attack%3==0:_start_wave();level.notice("CAUDA SÍSMICA · salte o anel enquanto ativa os terminais!")
		elif _machine_attack%3==2:_fan(level.player.position+Vector3.UP);level.notice("RAJADA · continue se movendo!")
		else:
			_hazard_at=level.player.position;_hazard_at.y=level.roof_y;_hazard_left=1.5;_warning.scale=Vector3.ONE;_warning.global_position=_hazard_at+Vector3.UP*.06;_warning.show();Sfx.play("lab_alarm",-12)
	if _hazard_left>0:
		_hazard_left-=delta
		if _hazard_left<=0:level.spawn_pool(_hazard_at,1.5,3.0);_warning.hide();Sfx.play("lab_splash",-10)
	if _flood.visible and flood_cycle>=7 and cooled<=0:
		var p:Vector3=level.player.position
		if absf(p.x)<11.5 and p.z<-239 and p.z>-251 and p.y<level.roof_y+.6:level.player.take_damage(1,p-Vector3.UP)
func _last_dose(delta:float) -> void:
	position=position.move_toward(Vector3(0,level.roof_y,-243),5*delta)
	model.scale=Vector3(1.25+serum_hits*.08,1.25-serum_hits*.10,1.25+serum_hits*.08)
	var facing:Vector3=(_aim if _shot_warning>0 else level.player.position)-position;model.rotation.y=lerp_angle(model.rotation.y,atan2(-facing.x,-facing.z),1-exp(-delta*5))
	if _shot_warning>0:
		_shot_warning-=delta
		if _shot_warning<=0:_shoot(_aim);_shot_recoil=.5;_timer=3;_warning.hide()
	elif _timer<=0:
		_shot_warning=.95;_aim=level.player.position+Vector3.UP;_warning.global_position=level.player.position+Vector3.UP*.06;_warning.show();Sfx.play("lab_scan",-9)
func _shoot(target:Vector3) -> void:level.enemy_shot(position+Vector3.UP*1.6,target,13,self)
func machine_element(kind:String,element:String) -> void:
	if not active or dying or dead:return
	if phase==2 and vulnerable<=0:
		if kind=="heat" and element=="fire":heated=18;Sfx.checkpoint()
		elif kind=="cold" and element=="ice":cooled=18;Sfx.checkpoint()
	elif phase==3 and kind=="injector":
		if element=="fire":injector_heat=true;level.notice("Válvula aberta. Use GELO no injetor para estabilizar.")
		elif element=="ice" and injector_heat:injector_cold=true;level.notice("Fluxo estável! E no injetor para inverter e pegar as doses LG-17.")
func take_element(_element:String,source:Vector3,_seconds:float=3) -> void:take_damage(1,source)
func take_damage(amount:float,_source:Vector3) -> void:
	if not active or dead or dying or phase==3 or vulnerable<=0 or _spent or _invulnerable>0:return
	_spent=true;_invulnerable=.8;_hit_flash=.18;health-=minf(1,amount);Sfx.hit();level.spark(position+Vector3.UP,"f2d98e")
	if health<=0:
		_clear_hazards();_warning.hide();_flood.hide();_clock=0;vulnerable=0;_state="idle";_invulnerable=1
		if phase==1:phase=2;health=3;_machine_timer=4;level.player.heal_one();level.notice("Largato: Procedimento perfeitamente aprovado! FOGO à esquerda, GELO à direita.")
		else:phase=3;health=3;_timer=4;heated=0;cooled=0;_unlock_doses();level.notice("LG-17 LIBERADO · siga a luz verde e pegue as doses com E. F arremessa em Largato!")
func reverse_injector() -> bool:
	if not active or phase<2:return false
	if not dose_unlocked:level.notice("Estabilize os terminais de FOGO e GELO para liberar o estoque LG-17.");return true
	injector_reversed=true;syringe_ammo=3;_serum_cooldown=.7;Sfx.checkpoint();level.notice("3 doses LG-17. F arremessa em Largato. E aqui recarrega.");return true
func throw_serum() -> bool:
	if not active or phase!=3 or not injector_reversed or syringe_ammo<=0 or _serum_cooldown>0:return false
	syringe_ammo-=1;_serum_cooldown=1
	var shot:=preload("res://world/Scripts/Lab3D/projectile.gd").new();shot.friendly=true;shot.serum=true;shot.source=level.player;shot.position=level.player.position+Vector3.UP*1.2
	shot.flight=(aim_point()-shot.position).normalized()*25;level.add_child(shot);Sfx.play("lab_dart",-6);return true
func receive_serum(shot:Node3D) -> bool:
	if not active or phase!=3 or dying or dead or not shot.friendly or not shot.serum or shot.spent:return false
	shot.spent=true;serum_hits+=1;health=3-serum_hits;_shot_warning=0;_timer=maxf(2,_timer);_warning.hide();_clear_hazards(true);Sfx.play("lab_splash",-5)
	level.notice("LG-17: %d/3. O enxerto de Largato está se desfazendo!"%serum_hits)
	if serum_hits>=3:
		active=false;dying=true;collision_layer=0;_lift.hide();_flood.hide();_clear_hazards();level.play_cutscene("melt")
	return true
func _clear_hazards(keep_serum:bool=false) -> void:
	_wave_radius=0
	if is_instance_valid(_wave):_wave.hide()
	for node in get_tree().get_nodes_in_group("lab3d_projectiles"):
		if not keep_serum or not node.friendly:node.set_physics_process(false);node.queue_free()
	for node in get_tree().get_nodes_in_group("lab3d_devices"):
		if node.kind=="pool" and node.life>0:node.set_physics_process(false);node.queue_free()
func reset_encounter() -> void:
	if dead or dying:return
	active=false;phase=1;health=4;vulnerable=0;heated=0;cooled=0;_state="idle";_timer=1.6;_clock=0;_attack=0;_spent=false;_invulnerable=0;_hazard_left=0;_shot_warning=0
	injector_heat=false;injector_cold=false;injector_reversed=false;syringe_ammo=0;serum_hits=0;_serum_cooldown=0;dose_unlocked=false;_machine_attack=0;_wave_radius=0;_wave.hide()
	_shot_recoil=0;_hit_flash=0;_animation_action=""
	for material:StandardMaterial3D in _hit_materials:material.albedo_color=Color.WHITE
	_play_action("idle")
	position=Vector3(0,level.roof_y,-242);model.scale=Vector3.ONE*1.25;model.visible=true;collision_layer=4;_warning.hide();_flood.hide();_lift.hide();_clear_hazards()
func status() -> String:
	if phase<3 and vulnerable>0:return "Acerto confirmado · aguarde a próxima abertura" if _spent else "VULNERÁVEL · %.1f s · um acerto por abertura"%vulnerable
	if phase==1:
		if _state=="warning":return {"tail":"CAUDA: pule ou saia do alcance","volley":"RAJADA: desvie lateralmente","jump":"SALTO: saia do círculo","dash":"INVESTIDA: saia da linha","ring":"ONDA: salte o anel"}[pattern]
		return "Desvie dos golpes e ataque na recuperação. J gira no chão ou no ar; aproxime-se nas aberturas."
	if phase==2 and dose_unlocked and not injector_reversed:return "LG-17 LIBERADO · luz verde no injetor · E para guardar as doses!"
	if phase==2:return "FOGO à esquerda: %s  |  GELO à direita: %s"%[("OK %ds"%ceili(heated)) if heated>0 else "aguardando",("OK %ds"%ceili(cooled)) if cooled>0 else "aguardando"]
	if injector_reversed:return "F: LG-17 · %d doses · %d/3 acertos · E no injetor recarrega"%[syringe_ammo,serum_hits]
	return "LG-17 · SIGA A LUZ VERDE · E PARA PEGAR → F PARA ARREMESSAR"

func _unlock_doses() -> void:
	if dose_unlocked:return
	dose_unlocked=true;injector_heat=true;injector_cold=true
	Sfx.play("lab_door",-6);level.notice("ESTOQUE LG-17 LIBERADO · siga o sinal verde à esquerda e recolha com E, antes da última etapa.")
func _fan(target:Vector3) -> void:
	var source:=position+Vector3.UP*1.6
	var aim:Vector3=(target-source).normalized()
	for angle in [-.28,0,.28]:level.enemy_shot(source,source+aim.rotated(Vector3.UP,angle)*20,10,self)
	Sfx.play("lab_dart",-10)
func _start_wave() -> void:
	_wave_radius=.2;_wave_center=position;_wave_center.y=level.roof_y+.08;_wave.global_position=_wave_center;_wave.show();Sfx.play("lab_pressure",-10)
func _tick_wave(delta:float) -> void:
	if _wave_radius<=0:return
	_wave_radius+=delta*7
	_wave.scale=Vector3(_wave_radius,1,_wave_radius)
	var p:Vector3=level.player.position-_wave_center
	if absf(Vector2(p.x,p.z).length()-_wave_radius)<.55 and p.y<1.0:level.player.take_damage(1,_wave_center)
	if _wave_radius>16:_wave_radius=0;_wave.hide()

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
func _ready() -> void:
	add_to_group("lab3d_enemies");add_to_group("lab3d_targets");collision_layer=4;collision_mask=1
	var shape:=CapsuleShape3D.new();shape.radius=.75;shape.height=2.8;var col:=CollisionShape3D.new();col.shape=shape;col.position.y=1.4;add_child(col)
	model=Art.instantiate("largato");model.scale=Vector3.ONE*1.25;add_child(model)
	_warning=Art.ring(level,"BossWarning",Vector3.ZERO,1.4,"f3b05e",.5);_warning.hide()
	_opening=Art.ring(self,"Opening",Vector3(0,3.1,0),.65,"ffe4a1",.5);_opening.hide()
	_lift=Node3D.new();add_child(_lift);Art.cylinder(_lift,"Lift",Vector3(0,-.12,0),1.25,.22,"344d61",-1,.6);_lift.hide()
	_flood=Art.box(level,"RooftopFlood",Vector3(0,level.roof_y+.035,-239),Vector3(23,.07,24),"70bb91",0,.25);_flood.hide()
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
	_clock+=delta;_timer-=delta;vulnerable=maxf(0,vulnerable-delta);_invulnerable=maxf(0,_invulnerable-delta);_serum_cooldown=maxf(0,_serum_cooldown-delta)
	_opening.visible=vulnerable>0 and not _spent;_lift.visible=phase==2
	model.visible=_invulnerable<=0 or fposmod(_invulnerable,.12)>.025
	if phase==1:_containment(delta)
	elif phase==2:_overload(delta)
	else:_last_dose(delta)
	if _invulnerable>0:model.get_node("Animations").play("hurt")
func _containment(delta:float) -> void:
	if _state=="jump":
		_jump_t+=delta;var t:=clampf(_jump_t/.95,0,1);position=_jump_from.lerp(_aim,t)+Vector3.UP*sin(t*PI)*5
		model.get_node("Animations").play("jump")
		if t>=1:position.y=level.roof_y;_open(2.6);_warning.hide();level.shake(.15);Sfx.play("lab_clink",-7)
		return
	position.y=level.roof_y
	match _state:
		"idle":
			model.get_node("Animations").play("run")
			var to:Vector3=level.player.position-position;to.y=0
			if to.length()>5:
				position+=to.normalized()*2.2*delta;_face=to.normalized();model.rotation.y=atan2(-_face.x,-_face.z)
			if _timer<=0:
				_attack+=1;_state="warning";_timer=1.0;_face=to.normalized();model.rotation.y=atan2(-_face.x,-_face.z)
				_aim=level.player.position+_face*1.5;_aim.x=clampf(_aim.x,-11,11);_aim.z=clampf(_aim.z,-253,-231);_aim.y=level.roof_y
				_warning.global_position=_aim+Vector3.UP*.07 if _attack%3==0 else position+_face*2+Vector3.UP*.06;_warning.show();Sfx.play("lab_scan",-8)
		"warning":
			model.get_node("Animations").play("operate")
			if _timer<=0:
				if _attack%3==0:_state="jump";_jump_t=0;_jump_from=position
				elif _attack%2==0:_shoot(_aim+Vector3.UP);_state="shoot";_timer=.5;model.get_node("Animations").play("attack")
				else:_state="tail";_timer=.45;model.get_node("Animations").play("tail")
		"tail":
			var gap:Vector3=level.player.position-position
			if Vector2(gap.x,gap.z).length()<4.4 and Vector3(gap.x,0,gap.z).normalized().dot(_face)>.15 and gap.y<1.25:level.player.take_damage(1,position)
			if _timer<=0:_open(2.6)
		"shoot":
			if _timer<=0:_open(2.5)
		"opening":
			model.get_node("Animations").play("hurt" if _invulnerable>0 else "idle")
			if _timer<=0:_state="idle";_timer=1.6
func _open(seconds:float) -> void:
	_state="opening";_timer=seconds;vulnerable=seconds;_spent=false;_warning.hide()
	if phase==2:_clear_hazards();_hazard_left=0;_machine_timer=3.3;_flood.hide();level.notice("Máquinas estabilizadas! Largato desce: acerte uma vez.");Sfx.play("lab_door",-8)
func _overload(delta:float) -> void:
	if vulnerable<=0 and _state=="opening":_state="idle";heated=0;cooled=0;_spent=false;_clock=0;_machine_timer=3.3
	var open:=vulnerable>0
	position=position.move_toward(Vector3(0,level.roof_y+(0 if open else 5),-241),7*delta)
	model.get_node("Animations").play("idle" if open else "operate")
	var facing:Vector3=level.player.position-position;model.rotation.y=lerp_angle(model.rotation.y,atan2(-facing.x,-facing.z),1-exp(-delta*5))
	var flood_cycle:=fposmod(_clock,11)
	_flood.visible=not open and flood_cycle>5 and flood_cycle<10
	_flood.material_override=Art.material("91dfe8" if cooled>0 else ("e5ad6a" if flood_cycle<7 else "70bb91"),0,.2)
	if open:return
	heated=maxf(0,heated-delta);cooled=maxf(0,cooled-delta);_machine_timer-=delta
	if heated>0 and cooled>0:_open(5.4);return
	if _machine_timer<=0:
		_machine_timer=5.2;_hazard_at=level.player.position;_hazard_at.y=level.roof_y;_hazard_left=1.35;_warning.global_position=_hazard_at+Vector3.UP*.06;_warning.show();Sfx.play("lab_alarm",-12)
	if _hazard_left>0:
		_hazard_left-=delta
		if _hazard_left<=0:level.spawn_pool(_hazard_at,1.5,3.0);_warning.hide();Sfx.play("lab_splash",-10)
	if _flood.visible and flood_cycle>=7 and cooled<=0:
		var p:Vector3=level.player.position
		if absf(p.x)<11.5 and p.z<-227 and p.z>-251 and p.y<level.roof_y+.6:level.player.take_damage(1,p-Vector3.UP)
func _last_dose(delta:float) -> void:
	position=position.move_toward(Vector3(0,level.roof_y,-243),5*delta)
	model.scale=Vector3(1.25+serum_hits*.08,1.25-serum_hits*.10,1.25+serum_hits*.08)
	model.get_node("Animations").play("operate" if _shot_warning>0 else "talk")
	var facing:Vector3=(_aim if _shot_warning>0 else level.player.position)-position;model.rotation.y=lerp_angle(model.rotation.y,atan2(-facing.x,-facing.z),1-exp(-delta*5))
	if _shot_warning>0:
		_shot_warning-=delta
		if _shot_warning<=0:_shoot(_aim);_timer=3;_warning.hide()
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
	_spent=true;_invulnerable=.8;health-=minf(1,amount);Sfx.hit();level.spark(position+Vector3.UP,"f2d98e")
	if health<=0:
		_clear_hazards();_warning.hide();_flood.hide();_clock=0;vulnerable=0;_state="idle";_invulnerable=1
		if phase==1:phase=2;health=3;_machine_timer=4;level.notice("Largato: Procedimento perfeitamente aprovado! FOGO à esquerda, GELO à direita.")
		else:phase=3;health=3;_timer=4;heated=0;cooled=0;level.notice("Largato: Meu orçamento! Inverta o injetor com FOGO, GELO e E.")
func reverse_injector() -> bool:
	if not active or phase!=3:return false
	if not injector_heat or not injector_cold:level.notice("Injetor: FOGO, depois GELO, depois E.");return true
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
	for node in get_tree().get_nodes_in_group("lab3d_projectiles"):
		if not keep_serum or not node.friendly:node.set_physics_process(false);node.queue_free()
	for node in get_tree().get_nodes_in_group("lab3d_devices"):
		if node.kind=="pool" and node.life>0:node.set_physics_process(false);node.queue_free()
func reset_encounter() -> void:
	if dead or dying:return
	active=false;phase=1;health=4;vulnerable=0;heated=0;cooled=0;_state="idle";_timer=1.6;_clock=0;_attack=0;_spent=false;_invulnerable=0;_hazard_left=0;_shot_warning=0
	injector_heat=false;injector_cold=false;injector_reversed=false;syringe_ammo=0;serum_hits=0;_serum_cooldown=0
	position=Vector3(0,level.roof_y,-242);model.scale=Vector3.ONE*1.25;model.visible=true;collision_layer=4;_warning.hide();_flood.hide();_lift.hide();_clear_hazards()
func status() -> String:
	if phase<3 and vulnerable>0:return "Acerto confirmado · aguarde a próxima abertura" if _spent else "VULNERÁVEL · %.1f s · um acerto por abertura"%vulnerable
	if phase==1:
		if _state=="warning":return "SALTO: saia do círculo" if _attack%3==0 else ("SERINGA: desvie da mira" if _attack%2==0 else "CAUDA: pule ou saia do alcance")
		return "Desvie dos golpes e ataque na recuperação. J gira no chão ou no ar; aproxime-se nas aberturas."
	if phase==2:return "FOGO à esquerda: %s  |  GELO à direita: %s"%[("OK %ds"%ceili(heated)) if heated>0 else "aguardando",("OK %ds"%ceili(cooled)) if cooled>0 else "aguardando"]
	if injector_reversed:return "F: LG-17 · %d doses · %d/3 acertos · E no injetor recarrega"%[syringe_ammo,serum_hits]
	return "Injetor: use GELO e aperte E" if injector_heat else "Injetor à esquerda: FOGO → GELO → E → F"

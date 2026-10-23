extends CharacterBody2D
signal died
signal defeated
const LEFT:=6160.0
const RIGHT:=7040.0
const CENTER:=6600.0
const FLOOR:=-1290.0
var active:=false
var dead:=false
var dying:=false
var phase:=1
var health:=4.0
var state:="idle"
var timer:=1.5
var vulnerable:=0.0
var _invulnerable:=0.0
var _spent_window:=false
var _clock:=0.0
var _attack_number:=0
var _side:=-1.0
var _jump_start:=Vector2.ZERO
var _jump_end:=Vector2.ZERO
var _jump_time:=0.0
var _entrance_seen:=false
var heated:=0.0
var cooled:=0.0
var injector_heat:=false
var injector_cold:=false
var injector_reversed:=false
var serum_hits:=0
var syringe_ammo:=0
var _serum_cooldown:=0.0
var _machine_timer:=0.0
var _hazard_x:=0.0
var _warning_left:=0.0
var _empty_notice:=0.0
var _lift:Sprite2D
var _sprite:AnimatedSprite2D
var _base_scale:=Vector2.ONE
var _player:CharacterBody2D
var _bar:CanvasLayer
var _caption:Label
var _fill:ColorRect
var _gates:Array[StaticBody2D]=[]
func _ready() -> void:
	add_to_group("enemies");add_to_group("bosses");collision_layer=4;collision_mask=1;z_index=4
	_player=get_tree().get_first_node_in_group("player")
	var collider:=CollisionShape2D.new();var shape:=RectangleShape2D.new();shape.size=Vector2(43,58)
	collider.shape=shape;collider.position.y=-29;add_child(collider)
	_sprite=preload("res://world/Scripts/lab_art.gd").actor("largato",136)
	_base_scale=_sprite.scale;add_child(_sprite);_sprite.play(&"idle")
	_lift=preload("res://world/Scripts/lab_art.gd").prop("platform",125,true);_lift.z_index=-1;_lift.position.y+=2;_lift.hide();add_child(_lift)
	_bar=CanvasLayer.new();_bar.layer=16;add_child(_bar)
	var back:=ColorRect.new();back.position=Vector2(100,58);back.size=Vector2(440,48);back.color=Color("15242d");back.mouse_filter=Control.MOUSE_FILTER_IGNORE;_bar.add_child(back)
	_caption=Label.new();_caption.position=Vector2(106,59);_caption.size=Vector2(428,36);_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;_caption.add_theme_font_size_override("font_size",9);_bar.add_child(_caption)
	_fill=ColorRect.new();_fill.position=Vector2(106,101);_fill.size=Vector2(428,3);_fill.color=Color("8ce18c");_fill.mouse_filter=Control.MOUSE_FILTER_IGNORE;_bar.add_child(_fill);_bar.hide()
	_player.respawned.connect(reset_encounter)
func start_encounter() -> void:
	if active or dead or dying:return
	active=true;phase=1;health=4;timer=1.6;state="idle";_spent_window=false
	_player.position=Vector2(clampf(_player.position.x,LEFT+95,RIGHT-95),FLOOR-11)
	_player.velocity=Vector2.ZERO;_player._invulnerability_timer=maxf(.25,_player._invulnerability_timer)
	get_parent().frame_camera(0,true)
	_player.respawn_position=Vector2(6080,FLOOR-11)
	for x in [6125.0,7072.0]:
		var gate:=StaticBody2D.new();gate.collision_layer=1;gate.collision_mask=0;gate.position=Vector2(x,FLOOR-100)
		var collider:=CollisionShape2D.new();var shape:=RectangleShape2D.new();shape.size=Vector2(12,440);collider.shape=shape;gate.add_child(collider);get_parent().add_child(gate);_gates.append(gate)
	_bar.show()
	if not _entrance_seen:
		_entrance_seen=true
		var scene:=preload("res://world/Scripts/lab_cutscene.gd").new();scene.mode="boss";scene.name="LargatoEntrance";scene.level=get_parent();get_parent().add_child(scene)
func _physics_process(delta:float) -> void:
	_lift.visible=active and phase==2
	if dead or dying:return
	if not active:
		if _player.position.x>LEFT and _player.position.x<RIGHT and absf(_player.position.y-FLOOR)<220 and not _player.is_dead():start_encounter()
		return
	_clock+=delta;timer-=delta;vulnerable=maxf(0,vulnerable-delta);_invulnerable=maxf(0,_invulnerable-delta);_serum_cooldown=maxf(0,_serum_cooldown-delta);_empty_notice=maxf(0,_empty_notice-delta)
	_sprite.modulate=Color("c5f4b0") if _invulnerable>0 else Color.WHITE
	_sprite.flip_h=(_side>0) if phase==1 and state in ["warning","tail","shoot"] else _player.position.x>position.x
	if phase==1:_tick_containment(delta)
	elif phase==2:_tick_overload(delta)
	else:_tick_final(delta)
	if phase==1 and _player.global_position.distance_to(global_position+Vector2(0,-20))<34 and vulnerable<=0:_player.take_damage(1,position)
	_caption.text="LARGATO · DIRETOR DE PESQUISA
"+_advice()
	_fill.size.x=428*(health/(4 if phase==1 else 3))
	queue_redraw()
func _tick_containment(delta:float) -> void:
	if state=="jump":
		_jump_time+=delta;var t:=clampf(_jump_time/.9,0,1)
		position=_jump_start.lerp(_jump_end,t)+Vector2(0,-sin(t*PI)*90);_sprite.play(&"jump")
		if t>=1:position.y=FLOOR;_open_window(1.8)
		return
	position.y=FLOOR
	match state:
		"idle":
			_sprite.play(&"run");position.x+=_side*85*delta
			if position.x<LEFT+90:_side=1
			if position.x>RIGHT-90:_side=-1
			if timer<=0:
				_attack_number+=1;_side=-1.0 if _player.position.x<position.x else 1.0;state="warning";timer=.8;_sprite.play(&"windup");Sfx.play("lab_scan",-9)
		"warning":
			_sprite.play(&"windup")
			if timer<=0:
				if _attack_number%3==0:
					state="jump";_jump_time=0;_jump_start=position;_jump_end=Vector2(clampf(_player.position.x+_side*110,LEFT+90,RIGHT-90),FLOOR)
				elif _attack_number%2==0:state="shoot";timer=.4;_shoot(_player.position);_sprite.play(&"shoot")
				else:state="tail";timer=.38;_sprite.play(&"tail")
		"tail":
			var distance:float=(_player.position.x-position.x)*_side
			if distance>0 and distance<108 and _player.position.y>FLOOR-42:_player.take_damage(1,position)
			if timer<=0:_open_window(1.9)
		"shoot":
			if timer<=0:_open_window(1.7)
		"opening":
			_sprite.play(&"hurt" if _invulnerable>0 else &"idle")
			if timer<=0:state="idle";timer=1.6;_side=-_side
func _open_window(seconds:float) -> void:
	state="opening";timer=seconds;vulnerable=seconds;_spent_window=false
func _tick_overload(delta:float) -> void:
	heated=maxf(0,heated-delta);cooled=maxf(0,cooled-delta);_machine_timer-=delta
	var open:=vulnerable>0
	position.y=move_toward(position.y,FLOOR if open else FLOOR-112,190*delta);position.x=move_toward(position.x,CENTER,240*delta)
	_sprite.play(&"hurt" if _invulnerable>0 else (&"idle" if open else &"operate"))
	if heated>0 and cooled>0 and not open and not _spent_window:
		_open_window(4.8);get_parent()._show_notice("Máquinas estabilizadas! Ataque Largato enquanto ele desce.");Sfx.play("lab_door",-8)
	if vulnerable<=0 and state=="opening":
		state="idle";heated=0;cooled=0;_spent_window=false
	if _machine_timer<=0:
		_machine_timer=4.6;_hazard_x=clampf(_player.position.x,LEFT+60,RIGHT-60);_warning_left=1.1;Sfx.play("lab_alarm",-12)
	if _warning_left>0:
		_warning_left-=delta
		if _warning_left<=0:
			if absf(_player.position.x-_hazard_x)<30 and _player.position.y>FLOOR-55:_player.take_damage(1,Vector2(_hazard_x,FLOOR))
			_shoot(_player.position+Vector2(-70,0));_shoot(_player.position+Vector2(70,0))
	if flood_active() and _player.position.y+11>FLOOR-2 and _player.position.x>LEFT+125 and _player.position.x<RIGHT-125:
		_player.take_damage(1,Vector2(_player.position.x,FLOOR+22))
func flood_active() -> bool:return phase==2 and cooled<=0 and vulnerable<=0 and fposmod(_clock,10)>6.5 and fposmod(_clock,10)<9
func _tick_final(delta:float) -> void:
	position=position.move_toward(Vector2(CENTER+190,FLOOR),200*delta);_sprite.play(&"inject" if _invulnerable>0 else &"taunt")
	var squash:float=1-serum_hits*.07+sin(_clock*9)*serum_hits*.012
	_sprite.scale=_base_scale*Vector2(1+serum_hits*.035,squash);preload("res://world/Scripts/magic_art.gd").reanchor(_sprite)
	if timer<=0:_shoot(_player.position);timer=2.7
	if _empty_notice<=0 and injector_reversed and syringe_ammo==0:
		get_parent()._show_notice("Sem dose? Volte ao injetor e aperte E para recarregar.");_empty_notice=4
func _shoot(target:Vector2) -> void:
	var shot:=preload("res://world/Scripts/lab_projectile.gd").new();shot.owner_boss=self
	var side:float=signf(target.x-position.x);shot.position=position+Vector2(side*32,-28);shot.flight=(target-shot.position).normalized()*210;get_parent().add_child(shot);Sfx.play("lab_dart",-8)
func take_damage(amount:float,_source:Vector2) -> void:
	if not active or dead or dying or phase==3 or vulnerable<=0 or _invulnerable>0 or _spent_window or amount<=0:return
	_spent_window=true;_invulnerable=.8;health-=minf(1,amount);_sprite.play(&"hurt");Sfx.hit()
	if health<=0:
		if phase==1:_begin_overload()
		else:_begin_final()
func take_element(element:String,source:Vector2) -> void:take_damage(1,source)
func freeze_for(_seconds:float) -> void:pass
func _begin_overload() -> void:
	phase=2;health=3;state="idle";vulnerable=0;_clock=0;_spent_window=false;_machine_timer=3
	_clear_attacks();_invulnerable=1.0
	get_parent().show_lab_notice("Largato: Você não entende. Isto é um procedimento perfeitamente aprovado! FOGO à esquerda, GELO à direita.",7)
	Sfx.play("lab_alarm",-7)
func machine_element(kind:String,element:String) -> void:
	if not active or dying or dead:return
	if phase==2:
		if kind=="heat" and element=="fire":heated=12;Sfx.checkpoint()
		elif kind=="cold" and element=="ice":cooled=12;Sfx.checkpoint()
	elif phase==3 and kind=="injector":
		if element=="fire":injector_heat=true;get_parent()._show_notice("Válvula de injeção aberta. Use GELO para estabilizar o fluxo.")
		elif element=="ice" and injector_heat:injector_cold=true;get_parent()._show_notice("Fluxo estável! E no injetor para inverter e recolher as doses LG-17.")
func _begin_final() -> void:
	get_parent().get_node("LabInjector")._body.set_deferred("collision_layer",16)
	for terminal in ["LabHeat","LabCold"]:get_parent().get_node(terminal)._body.set_deferred("collision_layer",0)
	phase=3;health=3;state="final";vulnerable=0;_clock=0;timer=3;heated=0;cooled=0;_warning_left=0
	_clear_attacks();_invulnerable=1.0
	get_parent().show_lab_notice("Largato: Pare de destruir meu laboratório! O orçamento já foi reduzido duas vezes! Inverta o injetor: FOGO, GELO e E.",7)
func reverse_injector() -> bool:
	if not active or phase!=3:return false
	if not injector_heat or not injector_cold:
		get_parent()._show_notice("Aqueça a válvula com FOGO e estabilize com GELO antes de inverter.");return true
	injector_reversed=true;syringe_ammo=3;_serum_cooldown=.7
	get_parent()._show_notice("3 doses LG-17 recolhidas. F: arremessar contra Largato. O soro age no enxerto criado por ele.");Sfx.checkpoint();return true
func throw_serum() -> bool:
	if not active or phase!=3 or not injector_reversed or syringe_ammo<=0 or _serum_cooldown>0:return false
	syringe_ammo-=1;_serum_cooldown=.75
	var shot:=preload("res://world/Scripts/lab_projectile.gd").new();shot.friendly=true;shot.serum=true;shot.owner_boss=self
	shot.position=_player.position+Vector2(0,-8);shot.flight=(position+Vector2(0,-28)-shot.position).normalized()*380;get_parent().add_child(shot);Sfx.play("lab_dart",-6);return true
func receive_serum(shot:Node2D) -> bool:
	if not active or phase!=3 or dying or dead or not shot.friendly or not shot.serum or shot.owner_boss!=self or shot.get_meta("spent",false):return false
	shot.set_meta("spent",true);serum_hits+=1;health=maxf(0,3-serum_hits);_invulnerable=.8;Sfx.play("lab_splash",-5)
	if serum_hits>=3:_defeat()
	return true
func _defeat() -> void:
	active=false;dying=true;_lift.hide();collision_layer=0;_bar.hide();_clear_attacks()
	var scene:=preload("res://world/Scripts/lab_cutscene.gd").new();scene.mode="melt";scene.name="LargatoMeltdown";scene.level=get_parent()
	scene.finished.connect(func():dying=false;dead=true;_sprite.scale=_base_scale;_sprite.play(&"puddle");preload("res://world/Scripts/magic_art.gd").reanchor(_sprite);_clear_gates();died.emit();defeated.emit(),CONNECT_ONE_SHOT)
	get_parent().add_child(scene)
func _clear_attacks() -> void:
	for shot in get_tree().get_nodes_in_group("lab_projectiles"):
		if shot.owner_boss==self:shot.queue_free()
	for pool in get_tree().get_nodes_in_group("lab_devices"):
		if pool.get_meta("boss_owner_id",0)==get_instance_id():pool.queue_free()
func _clear_gates() -> void:
	for gate in _gates:
		if is_instance_valid(gate):gate.queue_free()
	_gates.clear()
func reset_encounter() -> void:
	if dead or dying:return
	_clear_gates();_clear_attacks();active=false;phase=1;health=4;state="idle";timer=1.5;vulnerable=0;_clock=0;_spent_window=false;_invulnerable=0
	heated=0;cooled=0;injector_heat=false;injector_cold=false;injector_reversed=false;serum_hits=0;syringe_ammo=0;_warning_left=0
	get_parent().get_node("LabInjector")._body.set_deferred("collision_layer",0)
	for terminal in ["LabHeat","LabCold"]:get_parent().get_node(terminal)._body.set_deferred("collision_layer",4|16)
	_lift.hide();position=Vector2(CENTER+170,FLOOR);collision_layer=4;_sprite.scale=_base_scale;_sprite.modulate=Color.WHITE;_sprite.play(&"idle");_bar.hide()
	_attack_number=0;_side=-1;_serum_cooldown=0;_empty_notice=0;queue_redraw();get_parent().frame_camera(0,true)
func is_dead() -> bool:return dead
func _advice() -> String:
	if phase==1:return "1/3 · Pule a cauda e ataque na recuperação."
	if phase==2:return "2/3 · FOGO: terminal esquerdo · GELO: direito · Ataque na descida."
	return "3/3 · Inverta o injetor · E: doses · F: arremessar (%d)"%syringe_ammo
func _draw() -> void:
	if not active:return
	if vulnerable>0 and not _spent_window:draw_arc(Vector2(0,-70),10,0,TAU,20,Color("ffe49c"),2)
	if phase==1 and state=="warning":draw_rect(Rect2(0 if _side>0 else -108,-2,108,3),Color("ffbc70",absf(sin(_clock*14))))
	if phase==2:
		draw_line(Vector2(0,FLOOR-position.y),Vector2(0,5),Color("172333"),12)
		draw_line(Vector2(0,FLOOR-position.y),Vector2(0,5),Color("adb9c4"),6)
		var level_x:float=LEFT-position.x
		var cycle:=fposmod(_clock,10)
		if cooled>0 or flood_active():
			var color:=Color("98e6ef") if cooled>0 else Color("63d36b",.85)
			draw_rect(Rect2(level_x+125,FLOOR-position.y+2,RIGHT-LEFT-250,10),color)
			for x in range(125,int(RIGHT-LEFT-125),12):draw_rect(Rect2(level_x+x,FLOOR-position.y+sin(_clock*4+x)*2,8,3),color.lightened(.3))
		elif cycle>5 and cycle<6.5 and vulnerable<=0:
			for x in range(125,int(RIGHT-LEFT-125),20):draw_rect(Rect2(level_x+x,FLOOR-position.y-2,12,3),Color("ffbc70",absf(sin(_clock*10))))
		if _warning_left>0:draw_rect(Rect2(_hazard_x-position.x-27,FLOOR-position.y-3,54,4),Color("ffc376",absf(sin(_clock*18))))

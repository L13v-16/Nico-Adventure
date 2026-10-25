extends CharacterBody2D
signal died
signal defeated
signal encounter_started
const Art=preload("res://world/Scripts/underworld_art.gd")
const MAX_HEALTH:=12.0
const BOOT_FEET=preload("res://world/Arte/Underworld/V59/guardian_feet.tres")
const OPENING_SPAWN:=Vector2(6800,89)
const MARKER_X:=7150.0
const UPPER_FLOOR:=-160.0
const ARENA_CENTER:=6960.0
const EDGE_LEFT:=6660.0
const EDGE_RIGHT:=7280.0
var health:=MAX_HEALTH
var active:=false
var phase:=1
var state:="idle"
var lava_y:=165.0
var heated:=false
var brittle:=false
var armor_broken:=false
var _timer:=1.2
var _phase_time:=0.0
var _vulnerable:=0.0
var _invulnerable:=0.0
var _target_x:=0.0
var _side:=-1.0
var _sprite:AnimatedSprite2D
var _armor_cue:Node2D
var _player:CharacterBody2D
var _caption:Label
var _fill:ColorRect
var _bar:CanvasLayer
var _gates:Array[StaticBody2D]=[]
var _pedestal:AnimatableBody2D
var _entrance: CanvasLayer
var cylinder: Node2D
var _normal_scale := Vector2.ONE
var _entrance_seen := false
var _upper_unlocked := false
var _cast_warn := false
var _cast_target := Vector2.ZERO
var _cast_anim := 0.0
var _phase_caption: Label
var _anchor: StaticBody2D
var _rising_floor:AnimatableBody2D
var _center_clock:=-1.0
var _center_from:=0.0
var _center_cooldown:=0.0
var _landing_grace:=0.0
var _arena_cycle:=0
var _phase2_parries:=0
var _parry_stun:=0.0
var final_seals:Node2D
var _ring_pattern:Node2D
var _floor_break:CanvasLayer
func _ready() -> void:
	process_physics_priority=-30
	add_to_group("enemies")
	add_to_group("bosses")
	add_to_group("jose_targets")
	collision_layer=4
	collision_mask=1
	var shape:=RectangleShape2D.new()
	shape.size=Vector2(68,104)
	var collider:=CollisionShape2D.new()
	collider.shape=shape
	collider.position.y=-52
	add_child(collider)
	_sprite=Art.actor("boss",162)
	_sprite.sprite_frames = preload("res://world/Arte/Underworld/V59/guardian.tres")
	_sprite.sprite_frames=_sprite.sprite_frames.duplicate(true)
	var poses:=preload("res://world/Scripts/polish99_art.gd")
	for entry in [["walk",[0,1],7,true],["windup",[2],5,false],["sweep",[3],6,false],["guard",[4],5,false],["heated",[5],5,false],["frozen",[6],5,false],["exposed",[7],5,false],["roar",[8],5,false],["leap",[9],5,false],["slam",[10],5,false],["recover",[11,4],3,false]]:
		poses.append(_sprite.sprite_frames,"warden",entry[0],entry[1],entry[2],entry[3])
	_normal_scale = _sprite.scale
	add_child(_sprite)
	_sprite.frame_changed.connect(_anchor_guardian)
	_sprite.animation_changed.connect(_anchor_guardian)
	_sprite.animation_changed.connect(_guardian_sound)
	_sprite.play(&"idle")
	_anchor_guardian()
	_pedestal=AnimatableBody2D.new()
	_pedestal.material=preload("res://world/Scripts/magic_art.gd").material()
	_pedestal.material.set_shader_parameter("alpha_cutoff",.94)
	_pedestal.collision_layer=0
	_pedestal.collision_mask=0
	var support:=CollisionShape2D.new()
	var support_shape:=RectangleShape2D.new()
	support_shape.size=Vector2(144,24)
	support.shape=support_shape
	support.position=Vector2(0,12)
	_pedestal.add_child(support)
	_pedestal.draw.connect(func():preload("res://world/Scripts/underworld_tiles.gd").platform(_pedestal,Rect2(-72,0,144,24)))
	add_child(_pedestal)
	_pedestal.hide()
	_player=get_tree().get_first_node_in_group("player")
	_player.respawned.connect(reset_encounter)
	_anchor = preload("res://world/Scripts/warden_chain_anchor.gd").new()
	_anchor.name = "PinnedChain"
	_anchor.boss = self
	add_child(_anchor)
	_armor_cue=Node2D.new();_armor_cue.name="ArmorSequence";_armor_cue.z_index=5;_armor_cue.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;_armor_cue.draw.connect(_paint_armor_guide);add_child(_armor_cue);_armor_cue.hide()
	_build_bar()
func _build_bar() -> void:
	_bar=CanvasLayer.new()
	_bar.layer=16
	add_child(_bar)
	var panel:=Panel.new()
	panel.position=Vector2(174,58)
	panel.size=Vector2(448,50)
	var style := preload("res://world/Scripts/ui_style.gd").panel_style()
	style.bg_color = Color("1a1824")
	style.border_color = Color("a88468")
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.shadow_size = 2
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_bar.add_child(panel)
	_phase_caption = Label.new()
	_phase_caption.position = Vector2(182, 59)
	_phase_caption.size = Vector2(432, 11)
	_phase_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_caption.add_theme_font_size_override("font_size", 9)
	_phase_caption.add_theme_color_override("font_color", Color("ffd298"))
	_bar.add_child(_phase_caption)
	_caption=Label.new()
	_caption.position=Vector2(182,72)
	_caption.size=Vector2(432,26)
	_caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_caption.add_theme_font_size_override("font_size",8)
	_bar.add_child(_caption)
	_fill=ColorRect.new()
	_fill.position=Vector2(182,103)
	_fill.size=Vector2(432,3)
	_fill.color=Color("f4a96b")
	_fill.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_bar.add_child(_fill)
	_bar.hide()
func start_encounter() -> void:
	if active or is_dead():return
	active=true
	stage_opening()
	_timer=1.3
	state="idle"
	for x in [6450.0,7470.0]:
		var gate:=StaticBody2D.new()
		gate.collision_layer=1
		gate.collision_mask=0
		gate.position=Vector2(x,-170)
		var shape:=RectangleShape2D.new()
		shape.size=Vector2(12,700)
		var collider:=CollisionShape2D.new()
		collider.shape=shape
		gate.add_child(collider)
		get_parent().add_child(gate)
		_gates.append(gate)
	_bar.show()
	encounter_started.emit()
	if not _entrance_seen:
		_entrance_seen = true
		_entrance = preload("res://world/Scripts/warden_intro.gd").new()
		_entrance.name = "WardenEntrance"
		_entrance.boss = self
		get_parent().add_child(_entrance)
	else: Sfx.play("warden_chain", -7)
func _anchor_guardian() -> void:
	var texture:Texture2D=_sprite.sprite_frames.get_frame_texture(_sprite.animation,_sprite.frame)
	if texture==null:return
	var feet:Dictionary=BOOT_FEET.get_meta("feet")
	var foot:float=texture.get_meta("ground_foot",feet.get(texture.resource_path,texture.get_height()))
	_sprite.position=Vector2(-texture.get_width()*.5*_sprite.scale.x,-foot*_sprite.scale.y)
	_sprite.set_meta("ground_art_offset",_sprite.position)
func stage_opening() -> void:
	position=Vector2(7100,100);velocity=Vector2.ZERO
	_player.release_vine(false);_player._cancel_attack()
	_player.position=OPENING_SPAWN;_player.respawn_position=OPENING_SPAWN
	_player.velocity=Vector2.ZERO;_player._hitstun_timer=0
	_player._spring_lock=0;_player._jump_buffer_timer=0;_player._camera_look=0
	_player._facing=1;_player.anim.flip_h=false;_player.anim.play(&"idle")
	_player._invulnerability_timer=maxf(_player._invulnerability_timer,1.5)
	var jose:CharacterBody2D=get_parent().get_node("Jose")
	jose.position=OPENING_SPAWN+Vector2(-42,11);jose.velocity=Vector2.ZERO
	jose.state="idle";jose._target=null;jose._safe_spot=jose.position
	jose._sprite.flip_h=false;jose._sprite.play(&"idle")
	var camera:Camera2D=_player.get_node("Camera2D")
	_player._camera_base_offset=Vector2(6975,-65)-_player.position
	camera.offset=_player._camera_base_offset;camera.zoom=Vector2.ONE*.9
	camera.reset_smoothing();camera.force_update_scroll()
func _clear_projectiles() -> void:
	for shot in get_tree().get_nodes_in_group("underworld_projectiles"):shot.queue_free()
func _clear_gates() -> void:
	for gate in _gates:
		if is_instance_valid(gate):gate.queue_free()
	_gates.clear()
func reset_encounter() -> void:
	if is_dead():return
	if is_instance_valid(_floor_break):_floor_break.finish()
	if phase==6:
		_begin_final_seals();return
	if phase!=5:_end_ring_pattern()
	_center_clock=-1;_center_cooldown=0;_landing_grace=0;_parry_stun=0
	_arena_cycle=0;_phase2_parries=0;collision_layer=4
	if is_instance_valid(_entrance): _entrance.finish()
	if phase == 5 and is_instance_valid(cylinder):
		collision_layer=0
		_clear_projectiles()
		cylinder._recover()
		return
	if _upper_unlocked:
		_ensure_rising_floor()
		_clear_projectiles()
		active = true
		health = 9
		phase = 3
		state = "idle"
		position = Vector2(7100, UPPER_FLOOR)
		lava_y = -109
		velocity = Vector2.ZERO
		_timer = 1.6
		_phase_time = 0
		_vulnerable = 0
		_invulnerable = 0
		heated = false
		brittle = false
		armor_broken = false
		_cast_warn = false
		_sprite.modulate = Color.WHITE
		_sprite.play(&"guard")
		_player.position = Vector2(6950, UPPER_FLOOR - 11)
		_player.respawn_position = _player.position
		_player.velocity = Vector2.ZERO
		_player._invulnerability_timer = 1.5
		return
	_clear_gates()
	if is_instance_valid(_rising_floor):_rising_floor.queue_free()
	_rising_floor=null
	_clear_projectiles()
	active=false
	health=MAX_HEALTH
	phase=1
	state="idle"
	lava_y=165
	position=Vector2(7100,100)
	velocity=Vector2.ZERO
	_timer=1.2
	_phase_time=0
	_vulnerable=0
	_invulnerable=0
	heated=false
	brittle=false
	armor_broken=false
	_cast_warn = false
	_cast_anim = 0
	_sprite.play(&"idle")
	_sprite.scale = _normal_scale
	_anchor_guardian()
	collision_layer = 4
	_pedestal.hide()
	_pedestal.collision_layer=0
	_bar.hide()
	queue_redraw()
func _physics_process(delta:float) -> void:
	if is_dead():return
	if not active:
		if _player.position.x>6510 and _player.position.x<7430 and not _player.is_dead():start_encounter()
		return
	if phase==6:
		_phase_time+=delta;queue_redraw();return
	if phase == 5:
		_phase_time += delta
		_vulnerable = maxf(0, _vulnerable - delta)
		_sprite.play(&"hurt" if _vulnerable > 0 else (&"roar" if cylinder._warning > 0 else &"exposed"))
		_sprite.modulate = Color.WHITE
		_sprite.flip_h = false
		_update_bar()
		queue_redraw()
		return
	_timer-=delta
	_phase_time+=delta
	var was_vulnerable := _vulnerable > 0
	_vulnerable=maxf(0,_vulnerable-delta)
	if was_vulnerable and _vulnerable <= 0:
		heated = false
		brittle = false
		armor_broken = false
		state = "recover"
		_timer = 0.65
	_invulnerable=maxf(0,_invulnerable-delta)
	_cast_anim = maxf(0, _cast_anim - delta)
	_sprite.modulate=Color("ffdfb3") if _invulnerable>0 else Color.WHITE
	_side=-1 if _player.position.x<position.x else 1
	_sprite.flip_h=_side>0
	_pedestal.hide()
	_pedestal.collision_layer=0
	_center_cooldown=maxf(0,_center_cooldown-delta)
	_landing_grace=maxf(0,_landing_grace-delta)
	_parry_stun=maxf(0,_parry_stun-delta)
	if _center_clock<0 and _center_cooldown<=0 and _vulnerable<=0 and _parry_stun<=0 and not _has_returning_chain() and state in ["idle","recover"] and (position.x<EDGE_LEFT or position.x>EDGE_RIGHT):
		_begin_center_jump()
	if _center_clock>=0:
		_tick_center_jump(delta)
		_update_bar();queue_redraw();return
	if phase==2:
		_tick_lava_arena(delta)
	elif _vulnerable>0:
		_sprite.play(&"stuck" if phase==1 else &"exposed")
	else:
		match state:
			"recover":
				_sprite.play(&"recover")
				if _timer <= 0:
					state = "idle"
					_timer = 1.05
			"idle":
				_sprite.play(&"walk" if phase==4 and _landing_grace<=0 and absf(_player.position.x-position.x)>85 else (&"heated" if heated else (&"frozen" if brittle else &"guard")))
				if phase==4 and _landing_grace<=0:
					var gap:float=_player.position.x-position.x
					if absf(gap)>85:
						position.x=move_toward(position.x,clampf(_player.position.x,6835,7340),95*delta)
				if _timer<=0:
					state="warning"
					_target_x=clampf(_player.position.x,6490,7410)
					_timer=1.0
					Sfx.play("warden_chain", -6)
			"warning":
				_sprite.play(&"windup")
				if _timer<=0:
					_slam()
					state="slam"
					_timer=0.45
			"slam":
				_sprite.play(&"slam")
				if _timer<=0:
					state="idle"
					_timer=1.5
					if phase==1:
						_vulnerable=2.6
						Fx.popup(Vector2(_target_x, 52), "CORRENTE PRESA!", Color("ffe2a2"), 9)
	if phase>=2 and _player.position.y+11>lava_y and _phase_time>0.5:_player.take_damage(1,Vector2(_player.position.x,lava_y+20))
	if phase!=2 and _landing_grace<=0 and _vulnerable<=0 and state != "recover" and _player.position.distance_to(position+Vector2(0,-22))<48:_player.take_damage(1,position)
	if _invulnerable > 0.43 and phase != 2: _sprite.play(&"hurt")
	_update_bar()
	queue_redraw()
func _update_bar() -> void:
	_armor_cue.visible=active and phase==3;_armor_cue.queue_redraw()
	if phase==6:return
	if phase==5:
		if not is_instance_valid(cylinder):return
		_fill.size.x=432*maxf(0,3-cylinder.hits)/3.0
		_phase_caption.text="5 / 6 · CANHÕES DA TORRE · CANHÕES %d / 3" % cylinder.hits
		_caption.text=_advice()
		_fill.color=Color("a2d9ee") if cylinder.hits==1 else Color("f4ac71")
		return
	_fill.size.x=432*health/MAX_HEALTH
	_phase_caption.text="%d / 6 · CARCEREIRO · " % phase + ["", "CORRENTES", "ANEL DE CORRENTES · %d / 7" % _phase2_parries, "ARMADURA RACHADA", "A INVESTIDA DE JOSÉ"][phase]
	_caption.text=_advice()
	_fill.color = Color("a7e5f4") if brittle else (Color("ffba75") if heated else Color("e4bb8d"))
	if phase==2:
		_fill.size.x=432*maxf(0,7-_phase2_parries)/7.0
		_fill.color=Color("b4ec92")
func arena_floor_y() -> float:
	return _rising_floor.floor_height() if phase==2 and is_instance_valid(_rising_floor) else (100.0 if phase==1 else UPPER_FLOOR)
func _begin_center_jump() -> void:
	_center_clock=0;_center_from=position.x
	_cast_warn=false;_vulnerable=0;velocity=Vector2.ZERO
	state="center_windup"
	if phase==2:
		_sprite.scale=_normal_scale*1.25
		_anchor_guardian()
	_clear_projectiles()
	Sfx.play("warden_chain",-9)
func _has_returning_chain() -> bool:
	for shot in get_tree().get_nodes_in_group("underworld_projectiles"):
		if shot.get("returned")==true:return true
	return false
func _tick_center_jump(delta:float) -> void:
	_center_clock+=delta
	var floor_y:=arena_floor_y()
	if phase>=2:lava_y=floor_y+70
	if _center_clock<.6:
		state="center_windup";_sprite.play(&"windup");position=Vector2(_center_from,floor_y)
	elif _center_clock<1.5:
		state="center_jump";collision_layer=0
		var jump:=clampf((_center_clock-.6)/.9,0,1)
		position=Vector2(lerpf(_center_from,ARENA_CENTER,smoothstep(0,1,jump)),floor_y-sin(jump*PI)*100)
		_sprite.play(&"leap" if jump<.65 else &"slam")
	else:
		if state!="center_land":Sfx.land(.6)
		state="center_land";position=Vector2(ARENA_CENTER,floor_y);collision_layer=4
		_sprite.play(&"recover")
		if _center_clock>=2.0:
			_center_clock=-1;_center_cooldown=3;_landing_grace=1;state="idle";_timer=2
func _ensure_ring_pattern() -> void:
	if is_instance_valid(_ring_pattern):return
	_ring_pattern=preload("res://world/Scripts/warden_ring_pattern.gd").new()
	_ring_pattern.boss=self
	get_parent().add_child(_ring_pattern)
	# O guardião está no centro ao fundo; a passagem à frente fica livre.
	collision_layer=0;z_index=0
	_sprite.scale=_normal_scale*1.25
	_anchor_guardian()
func _end_ring_pattern() -> void:
	if is_instance_valid(_ring_pattern):_ring_pattern.queue_free()
	_ring_pattern=null
	collision_layer=4;z_index=3
	_sprite.scale=_normal_scale
	_anchor_guardian()
func _tick_lava_arena(delta:float) -> void:
	_ensure_rising_floor();_ensure_ring_pattern()
	collision_layer=0
	position.y=arena_floor_y();lava_y=position.y+70
	if _parry_stun>0:_play_ring_pose(&"hurt")
	else:
		_ring_pattern.tick(delta)
		_play_ring_pose(_ring_pattern.guardian_pose())
	if _phase_time>=18 and _phase2_parries>=7:
		_end_ring_pattern()
		phase=3;position.y=UPPER_FLOOR;_phase_time=0;state="idle";_timer=1.8;health=9
		_upper_unlocked=true;_cast_warn=false;_clear_projectiles()
		_player.respawn_position=Vector2(6950,UPPER_FLOOR-11)
		Fx.popup(Vector2(6990,UPPER_FLOOR-110),"SELOS QUEBRADOS · FOGO E GELO!",Color("bce6d6"),9)
func _play_ring_pose(animation:StringName) -> void:
	var size:=_normal_scale*1.25*(.8 if String(animation).begins_with("ring_") else 1.0)
	if not _sprite.scale.is_equal_approx(size):
		_sprite.scale=size
		_anchor_guardian()
	_sprite.play(animation)
	if is_instance_valid(_ring_pattern):_ring_pattern.queue_redraw()
func receive_returned_chain() -> bool:
	# Uma devolução vale um ponto: dano extra e projéteis simultâneos não
	# podem somar vários acertos durante o mesmo atordoamento.
	if not active or phase!=2 or is_dead() or _parry_stun>0 or _center_clock>=0 or _phase2_parries>=7:return false
	_phase2_parries=mini(7,_phase2_parries+1);_parry_stun=1.3;_timer=maxf(_timer,2.3);_cast_warn=false
	Sfx.play("warden_hurt",-7)
	Fx.burst(position+Vector2(0,-55),Color("c6ff99"),12,100)
	Fx.popup(position+Vector2(0,-125),"DEVOLVIDO! %d / 7" % _phase2_parries,Color("d8ffad"),10)
	_ensure_ring_pattern()
	_ring_pattern.on_return()
	return true
func _advice() -> String:
	if _center_clock>=0:return "ELE VAI SALTAR AO CENTRO · Afaste-se do círculo"
	if _vulnerable>0 and phase < 5:return "J / X NA CORRENTE PRESA!" if phase == 1 else "ATAQUE O PONTO FRACO!"
	if phase==6:return final_seals.advice() if is_instance_valid(final_seals) else "OS ÚLTIMOS SELOS"
	match phase:
		1:return "Pule a onda; J / X no fecho dourado da corrente presa"
		2:
			var advice:String=_ring_pattern.advice() if is_instance_valid(_ring_pattern) else "CORRA · PULE · J / X REBATE A ESFERA VERDE"
			var remaining:float=maxf(_player._attack_cooldown,_player.elements.cooldown)
			return advice+(" · NICO: %.1fs"%remaining if remaining>0 else " · J/X: PRONTO")
		3:return "2: GELO NA ARMADURA AQUECIDA → 3: ATAQUE O NÚCLEO" if heated else "1: FOGO NA ARMADURA → 2: GELO → 3: ATAQUE"
		4:return "Atraia para o círculo dourado e use C: JOSÉ"
		5:return "CANHÃO %d / 3 · %s · %s · K: ativar" % [mini(cylinder.hits+1,3),"DIREITA" if cylinder.hits==1 else "ESQUERDA","GELO" if cylinder.hits==1 else "FOGO"]
	return ""
func _slam() -> void:
	var floor_y:=100.0 if phase==1 else UPPER_FLOOR
	Fx.burst(Vector2(_target_x,floor_y),Color("f3ad75"),15,160)
	Sfx.play("warden_slam", -4)
	_player._add_shake(2.5)
	if absf(_player.position.x-_target_x)<27 and _player.position.y+11>floor_y-35:_player.take_damage(1,Vector2(_target_x,floor_y))
	for direction in [-1.0,1.0]:
		var wave:=preload("res://world/Scripts/underworld_shockwave.gd").new()
		wave.position=Vector2(_target_x,floor_y)
		wave.speed=direction*(210 if phase>=3 else 180)
		get_parent().add_child(wave)
func _cast_chain() -> void:
	Sfx.play("warden_chain", -8)
	_cast_anim = 0.45
	var shot:=preload("res://world/Scripts/warden_chain_bolt.gd").new()
	shot.boss=self
	shot.position=position+Vector2(_side*60,-18)
	shot.flight=Vector2(_side*190,0)
	get_parent().add_child(shot)
func take_element(element:String,source:Vector2) -> void:
	if phase==6:
		if active and is_instance_valid(final_seals):final_seals.element(element,source)
		return
	if not active or is_dead() or phase==2 or phase==5:return
	if _vulnerable>0:take_damage(1,source);return
	if phase!=3:return
	if element=="ice" and not heated:
		Sfx.play("warden_fizzle",-10);Fx.burst(position+Vector2(0,-75),Color("b8e7ff"),5,45)
	if element=="fire":
		heated=true
		Sfx.play("warden_fire_charge", -8)
		Fx.popup(position+Vector2(0,-140),"ARMADURA AQUECIDA · GELO!",Color("ffc788"),9)
	elif element=="ice" and heated:
		brittle=true
		Sfx.play("warden_ice_charge",-7)
		_vulnerable=3.0
		_timer=3.4
		state="idle"
		Fx.burst(position+Vector2(0,-60),Color("b6f1ff"),20,150)
		Sfx.play("warden_break", -5)
func take_damage(amount:float,_source:Vector2) -> void:
	if phase==6:
		if active and is_instance_valid(final_seals):final_seals.strike(amount)
		return
	if not active or is_dead() or phase in [2,5] or amount<=0 or _invulnerable>0 or _vulnerable<=0:return
	_invulnerable=0.65
	health=maxf(0,health-amount)
	Sfx.play("warden_hurt", -5)
	Fx.burst(position+Vector2(0,-60),Color("ffe3a3"),15,140)
	if phase==1 and health<=9:
		health=9
		phase=2
		_phase_time=0
		_vulnerable=0
		_timer=2.4;state="idle";_arena_cycle=0;_phase2_parries=0;_parry_stun=0
		_clear_projectiles()
		_ensure_rising_floor()
		_ensure_ring_pattern()
		_begin_center_jump()
		Sfx.play("warden_rise",-7)
		Fx.popup(_player.position+Vector2(0,-50),"ANEL DE CORRENTES · CORRA, PULE E DEVOLVA!",Color("ffe2aa"),9)
	elif phase==3 and health<=3:
		health=3
		phase=4
		_vulnerable=0
		_phase_time=0
		heated=false
		brittle=false
		_timer=1.5
		var jose:CharacterBody2D=get_parent().get_node("Jose")
		jose.position=Vector2(6950,UPPER_FLOOR-1)
		jose.velocity=Vector2.ZERO
		jose.state="idle"
	elif health<=0:_begin_cylinder()
func _begin_cylinder() -> void:
	_center_clock=-1;collision_layer=4
	health = 3
	phase = 5
	state = "cylinder"
	_phase_time = 0
	_vulnerable = 0
	lava_y = 165
	_clear_projectiles()
	position = Vector2(7145, UPPER_FLOOR)
	collision_layer = 0
	_sprite.scale = _normal_scale * 1.6
	_sprite.play(&"exposed")
	_anchor_guardian()
	_player.heal_full()
	cylinder = preload("res://world/Scripts/warden_cylinder.gd").new()
	cylinder.name = "WardenCylinder"
	cylinder.boss = self
	get_parent().add_child(cylinder)
	_floor_break=preload("res://world/Scripts/warden_floor_break.gd").new()
	_floor_break.name="WardenFloorBreak";_floor_break.boss=self
	get_parent().add_child(_floor_break)
func _begin_final_seals() -> void:
	if is_instance_valid(cylinder):cylinder.set_physics_process(false);cylinder.queue_free()
	if is_instance_valid(final_seals):final_seals.set_physics_process(false);final_seals.queue_free()
	_clear_projectiles();_end_ring_pattern()
	phase=6;health=3;active=true;state="final_seals";_phase_time=0;_center_clock=-1
	_vulnerable=0;_invulnerable=0;collision_layer=4;lava_y=165
	position=Vector2(7100,UPPER_FLOOR);velocity=Vector2.ZERO
	_sprite.scale=_normal_scale;_sprite.play(&"guard");_anchor_guardian()
	_ensure_rising_floor()
	_player.position=Vector2(6960,UPPER_FLOOR-11);_player.respawn_position=_player.position
	_player.velocity=Vector2.ZERO;_player.heal_full();_player._invulnerability_timer=1.5
	final_seals=preload("res://world/Scripts/warden_final_seals.gd").new()
	final_seals.name="FinalSeals";final_seals.boss=self;add_child(final_seals)
	_bar.show();Sfx.play("warden_roar",-6)
	Fx.popup(_player.position+Vector2(0,-50),"OS ÚLTIMOS SELOS!",Color("ffe5b9"),10)

func _ensure_rising_floor() -> void:
	if is_instance_valid(_rising_floor):return
	_rising_floor=preload("res://world/Scripts/warden_rising_floor.gd").new()
	_rising_floor.boss=self
	_rising_floor.sync_to_physics=false
	_rising_floor.position=Vector2(6456,_rising_floor.floor_height())
	get_parent().add_child(_rising_floor)
func can_jose_target() -> bool:
	return active and phase==4 and not is_dead() and not armor_broken and absf(position.x-MARKER_X)<70
func jose_point() -> Vector2:return Vector2(position.x,UPPER_FLOOR)
func receive_jose_hit() -> bool:
	if not can_jose_target():return false
	armor_broken=true
	_vulnerable=5.0
	_timer=5.5
	Fx.popup(position+Vector2(0,-145),"CABEÇADA! PROTEÇÃO QUEBRADA",Color("ffe5ac"),10)
	Sfx.play("warden_break", -4)
	return true
func _defeat() -> void:
	if is_instance_valid(final_seals):final_seals.queue_free()
	health=0
	active=false
	state="defeated"
	velocity=Vector2.ZERO
	position.y=UPPER_FLOOR
	_sprite.play(&"freed")
	_sprite.scale = _normal_scale
	_anchor_guardian()
	Sfx.play("warden_freed", -3)
	if is_instance_valid(cylinder):
		_player.position = Vector2(7280, UPPER_FLOOR - 11)
		_player.respawn_position = _player.position
		_player.velocity = Vector2.ZERO
		cylinder.queue_free()
	_sprite.modulate=Color.WHITE
	collision_layer=0
	_clear_gates()
	_clear_projectiles()
	lava_y=165
	_pedestal.hide()
	_pedestal.collision_layer=0
	_bar.hide()
	died.emit()
	defeated.emit()
	queue_redraw()
func is_dead() -> bool:return health<=0
func _draw() -> void:

	if active and _center_clock>=0:
		var center:=to_local(Vector2(ARENA_CENTER,arena_floor_y()))
		draw_arc(center,48,PI,TAU,20,Color("ffe5ad"),2)
		draw_line(center+Vector2(-48,0),center+Vector2(48,0),Color("e6b97e"),3)
	if active and phase != 2 and phase < 5 and (state == "slam" or _vulnerable > 0):
		var hand := Vector2(_side * 50, -22)
		var pinned := to_local(Vector2(_target_x, 100 if phase == 1 else UPPER_FLOOR))
		preload("res://world/Scripts/underworld_chain_art.gd").strand(self, hand, pinned, 6)
	if active and state=="warning":
		var at:=to_local(Vector2(_target_x,100 if phase==1 else UPPER_FLOOR))
		draw_rect(Rect2(at-Vector2(22,3),Vector2(44,3)),Color("ffbd79"))
		draw_line(at+Vector2(0,-25),at+Vector2(0,-8),Color("fff0b0"),3)
	if active and phase==4:
		var at:=to_local(Vector2(MARKER_X,UPPER_FLOOR-2))
		draw_arc(at,28,PI,TAU,12,Color("ffe3a3"),2)
		draw_line(at+Vector2(-22,-2),at+Vector2(22,-2),Color("ffd278"),2)
	if active and phase>=2 and phase<5 and lava_y<155:
		var start:=to_local(Vector2(6456,lava_y))
		preload("res://world/Scripts/underworld_lava.gd").draw_pool(self,Rect2(start,Vector2(1008,480)),_phase_time)

func _guardian_sound() -> void:
	match _sprite.animation:
		"walk":Sfx.play("warden_chain",-19)
		"sweep":Sfx.play("warden_chain",-8)
		"leap":Sfx.play("warden_rise",-13)
		"recover":Sfx.play("warden_chain",-18)

func _paint_armor_guide() -> void:
	if active and phase==3:
		var icons:Texture2D=preload("res://world/Arte/HUD/element_icons_v80.png")
		var icon_width:=icons.get_width()*.5
		for i in 2:
			var color:=Color("ffb65b") if i==0 else Color("86e6ff")
			var selected:bool=(i==1) if heated else (i==0)
			var at:=Vector2(-146+i*34,-124)
			_armor_cue.draw_rect(Rect2(at-Vector2(3,3),Vector2(28,28)),Color("17202b"))
			if selected:_armor_cue.draw_rect(Rect2(at-Vector2(3,3),Vector2(28,28)),color,false,2)
			_armor_cue.draw_texture_rect_region(icons,Rect2(at,Vector2(22,22)),Rect2(i*icon_width,0,icon_width,icons.get_height()))
		var target:=Vector2(0,-90)
		_armor_cue.draw_arc(target,22+sin(_phase_time*5)*2,0,TAU,20,Color("86e6ff") if heated else Color("ffb65b"),2)

extends CharacterBody2D
signal died
signal defeated
signal encounter_started
const Art := preload("res://world/Scripts/magic_art.gd")
const LEFT := 5220.0
const RIGHT := 5800.0
const FLOOR := 64.0
const MAX_HEALTH := 8.0
const MAX_DAMAGE_PER_STUN := 1.0
const ROUND_TWO_BARREL_DELAY := 3.2
const LANDING_OPENING := 1.8
const SPRING_ROUND_HEALTH := 3.0
const SPRING_FLIGHT_LIMIT := 2.2
var _stun_damage := 0.0
var _spring_side := -1
var _spring_armed := false
var _spring_high := false
var _spring_air_time := 0.0
var _ring_springs: Array[Node2D] = []
var phase := 1
var _entrance_seen := false
var _entrance: CanvasLayer
var _rope_bounces := 0
var _stun_hit := false
var health := MAX_HEALTH
var active := false
var state := "idle"
var _timer := 1.4
var _direction := -1.0
var _attack_number := 0
var _invulnerability := 0.0
var _target_x := 5520.0
var _player: CharacterBody2D
var _sprite: AnimatedSprite2D
var _bar: CanvasLayer
var _fill: ColorRect
var _caption: Label
var _arena_gates: Array[StaticBody2D] = []
var _shock := 0.0
var _planned := "punch"
var _state_elapsed := 0.0
var _melee_hits := 0
var _throws := 0
const BASE_FRAMES := preload("res://world/Arte/Magic/hyena.tres")
const ATTACK_FRAMES := preload("res://world/Arte/Magic/V26/hyena_attacks.tres")

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	collision_layer=4
	collision_mask=1
	var collider:=CollisionShape2D.new()
	var shape:=RectangleShape2D.new()
	shape.size=Vector2(46,58)
	collider.shape=shape
	collider.position=Vector2(0,-29)
	add_child(collider)
	_sprite=Art.actor(preload("res://world/Arte/Magic/hyena.tres"),96)
	_play(&"idle")
	_sprite.frame_changed.connect(_sync_facing)
	_sprite.animation_changed.connect(_sync_facing)
	add_child(_sprite)
	_player=get_tree().get_first_node_in_group("player") as CharacterBody2D
	_player.respawned.connect(reset_encounter)
	for spring in get_tree().get_nodes_in_group("spring_mushrooms"):
		if spring.get_parent()==get_parent() and spring.position.x>5000:
			_ring_springs.append(spring)
			spring.bounced.connect(_on_ring_spring.bind(spring))
	_build_bar()

func _build_bar() -> void:
	_bar=CanvasLayer.new()
	_bar.layer=16
	add_child(_bar)
	var backing:=ColorRect.new()
	backing.position=Vector2(100,58)
	backing.size=Vector2(440,27)
	backing.color=Color("20192f")
	backing.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_bar.add_child(backing)
	_caption=Label.new()
	_caption.position=Vector2(106,58)
	_caption.size=Vector2(428,17)
	_caption.add_theme_font_size_override("font_size",10)
	_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_bar.add_child(_caption)
	_fill=ColorRect.new()
	_fill.position=Vector2(106,78)
	_fill.size=Vector2(428,3)
	_fill.color=Color("dd98d0")
	_fill.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_bar.add_child(_fill)
	_bar.hide()

func start_encounter() -> void:
	if active or is_dead():return
	active=true
	get_parent().get_node("HyenaRing").set_locked(true)
	state="idle"
	_timer=1.2
	for x in [5184.0,5856.0]:
		var gate:=StaticBody2D.new()
		gate.collision_layer=1
		gate.collision_mask=0
		gate.position=Vector2(x,FLOOR)
		var collider:=CollisionShape2D.new()
		var shape:=RectangleShape2D.new()
		shape.size=Vector2(12,400)
		collider.shape=shape
		collider.position.y=-200
		gate.add_child(collider)
		get_parent().add_child(gate)
		_arena_gates.append(gate)
	_bar.show()
	encounter_started.emit()
	Sfx.alert()
	if not _entrance_seen:
		_entrance_seen=true
		_entrance=preload("res://world/Scripts/boss_entrance.gd").new()
		_entrance.boss=self;_entrance.kind="triple";_entrance.name="TripleHEntrance"
		get_parent().add_child(_entrance)

func reset_encounter() -> void:
	if is_dead():return
	if is_instance_valid(_entrance):_entrance.finish()
	phase=1;_rope_bounces=0;_stun_hit=false;_stun_damage=0
	_clear_spring_launch();_spring_side=-1
	_clear_gates()
	active=false
	health=MAX_HEALTH
	position=Vector2(5616,FLOOR)
	velocity=Vector2.ZERO
	state="idle"
	_timer=1.4
	_invulnerability=0
	_shock=0
	_attack_number=0
	_state_elapsed=0
	_clear_projectiles()
	_sprite.modulate=Color.WHITE
	_play(&"idle")
	_bar.hide()
	queue_redraw()

func _clear_gates() -> void:
	for gate in _arena_gates:
		if is_instance_valid(gate):gate.queue_free()
	_arena_gates.clear()
	var ring:=get_parent().get_node_or_null("HyenaRing")
	if ring!=null:
		ring.set_locked(false)
		ring.set_spring_side(0)

func _physics_process(delta: float) -> void:
	if is_dead():return
	if not active:
		if _player.global_position.x>5220 and _player.global_position.x<5830 and not _player.is_dead():start_encounter()
		return
	_timer-=delta
	_state_elapsed+=delta
	_invulnerability=maxf(0,_invulnerability-delta)
	_shock=maxf(0,_shock-delta)
	_sprite.modulate=Color("ffc4eb") if _invulnerability>0 else Color.WHITE
	match state:
		"spring_intro":
			_play(&"guard")
			if _timer<=0:_position_for_spring()
		"spring_position":
			_play(&"run")
			var gap:=_target_x-position.x
			_direction=signf(gap)
			position.x=move_toward(position.x,_target_x,220*delta)
			if absf(gap)<4:_set_state("spring_warning",1.1)
		"spring_warning":
			_play(&"windup")
			if _timer<=0:
				_set_state("leap",1.5)
				velocity=Vector2(0,-340)
		"spring_guard":
			_play(&"guard")
			if _timer<=0:
				_clear_spring_launch()
				_set_state("spring_warning",1.1)
		"spring_recovery":
			_play(&"hurt" if _invulnerability>0.64 else &"stunned")
			if _timer<=0:_position_for_spring()
		"rope_warning":
			_play(&"kick_windup")
			if _timer<=0:_set_state("rope_run",4.0);velocity=Vector2(_direction*290,0)
		"rope_run":
			_play(&"run")
			if position.x<=LEFT+22 or position.x>=RIGHT-22 or _timer<=0:
				_rope_bounces+=1;_direction=-_direction
				position.x=clampf(position.x,LEFT+28,RIGHT-28)
				Sfx.swing();Fx.burst(position+Vector2(0,-25),Color("e0b0f4"),8,100)
				if _rope_bounces>=2:
					_target_x=(LEFT+RIGHT)*.5
					_set_state("leap_warning",1.0);velocity=Vector2.ZERO
				else:velocity.x=_direction*290;_timer=4.0
		"idle":
			_play(&"guard")
			if _timer<=0:_prepare_attack()
		"approach":
			_play(&"run")
			_direction=signf(_player.global_position.x-position.x)
			velocity.x=_direction*175
			if absf(_player.position.x-position.x)<105 or _timer<=0:
				velocity=Vector2.ZERO
				_warn(_planned)
		"warning", "leap_warning", "punch_warning", "kick_warning", "throw_warning":
			var pose:StringName=&"throw_hold" if state=="throw_warning" else (&"kick_windup" if state=="kick_warning" else (&"guard" if state=="punch_warning" else &"windup"))
			_play(pose)
			if _timer<=0:
				match state:
					"leap_warning":
						_set_state("leap",1.5)
						velocity=Vector2((_target_x-position.x)/0.9,-450)
					"punch_warning":_set_state("punch",0.72)
					"kick_warning":_set_state("kick",0.48)
					"throw_warning":_set_state("throw",0.95 if health<=4 else 0.65)
					_:
						_set_state("charge",1.6)
						velocity=Vector2(_direction*(360 if health<=4 else 300),0)
		"punch":
			_play(&"punch")
			if _state_elapsed>=0.12+_melee_hits*0.22 and _melee_hits<2:
				_melee_hits+=1
				_hurt_front(100)
			if _timer<=0:_set_state("punch_recovery",1.5)
		"kick":
			_play(&"kick")
			if _state_elapsed>=0.13 and _melee_hits==0:
				_melee_hits=1
				_hurt_front(125)
			if _timer<=0:_set_state("opening",1.7)
		"throw":
			_play(&"throw")
			if _state_elapsed>=0.18 and _throws==0:
				_throw_object("barrel",_target_x)
				_throws=1
			if phase==1 and health<=4 and _state_elapsed>=0.55 and _throws==1:
				_throw_object("rock",clampf(_player.position.x,LEFT+25,RIGHT-25))
				_throws=2
			if _timer<=0:_set_state("opening",1.8)
		"opening":
			_play(&"hurt" if _invulnerability>0.64 else &"stunned")
			if _timer<=0:_set_state("idle",0.65)
		"punch_recovery", "recovery":
			_play(&"guard")
			if _timer<=0:_set_state("idle",0.65)
		"charge":
			_play(&"run")
			if _timer<=0 or position.x<=LEFT+16 or position.x>=RIGHT-16:
				velocity=Vector2.ZERO
				_set_state("opening",1.8)
		"leap":
			_play(&"leap")
			velocity.y+=1000*delta
		"stunned":
			_play(&"hurt" if _invulnerability>0.64 else &"stunned")
			if _timer<=0:_set_state("idle",0.8)
	if state in ["charge","leap","approach","rope_run"]:
		move_and_slide()
		position.x=clampf(position.x,LEFT+12,RIGHT-12)
		if state=="leap" and is_on_floor():
			_shock=0.55
			Fx.burst(global_position,Color("d7b1fa"),20,180)
			if _player.is_on_floor() and absf(_player.global_position.x-position.x)<105:_player.take_damage(1,global_position)
			velocity=Vector2.ZERO
			if phase>=2:
				for direction in [-1.0,1.0]:
					var wave:=preload("res://world/Scripts/ring_shockwave.gd").new()
					wave.owner_boss=self;wave.position=position;wave.speed=direction*170;get_parent().add_child(wave)
				if phase==3:
					_set_state("spring_guard",7.0)
				else:
					_direction=signf(_player.position.x-position.x);_target_x=clampf(_player.position.x,LEFT+25,RIGHT-25)
					_set_state("throw_warning",ROUND_TWO_BARREL_DELAY)
			else:_set_state("opening",2.0)
	if phase==3:
		_tick_spring_launch(delta)
		if _try_spring_stomp(delta) and is_dead():return
	_sync_facing()
	_fill.size.x=428*health/(3.0 if phase>=2 else MAX_HEALTH)
	var advice:="Rebata o barril ou ataque por trás dos socos"
	if _has_attack_opening():advice="ABERTURA! J / X ou pule na cabeça"
	if _has_attack_opening() and _stun_hit:advice="ACERTOU! Prepare a próxima abertura"
	elif state.begins_with("throw"):advice="J / X: REBATA O BARRIL!"
	elif state.begins_with("punch"):advice="SOCOS! Passe por cima e ataque por trás"
	elif state.begins_with("kick"):advice="CHUTE! Pule ou recue"
	elif state=="leap_warning":advice="SAIA DA MARCA E PULE!"
	if phase==2:
		if state.begins_with("rope"):advice="CORRIDA NAS CORDAS · PULE!"
		elif state=="leap_warning":advice="SALTO NO CENTRO · AFASTE-SE!"
		elif state=="leap":advice="PULE A ONDA · DEPOIS REBATA O BARRIL"
		elif state=="throw_warning":
			advice="BARRIL EM %.1f s · PREPARE J / X"%maxf(0,_timer)
			if _has_attack_opening():advice=("ACERTOU! " if _stun_hit else "ABERTURA! ATAQUE AGORA · ")+"BARRIL EM %.1f s"%maxf(0,_timer)
	if phase==3:
		var side_name:="ESQUERDO" if _spring_side<0 else "DIREITO"
		advice="TRAMPOLIM %s → CAIA NA CABEÇA!"%side_name
		if state in ["spring_warning","leap"]:advice="PULE A ONDA · TRAMPOLIM "+side_name
		elif state=="spring_recovery":advice="ACERTO! AGORA USE O OUTRO TRAMPOLIM"
	_caption.text="TRIPLE H · %d / 3 · "%phase+advice
	if not _player.is_dead() and absf(_player.global_position.x-position.x)<36:
		var feet:float=_player.global_position.y+11
		if _has_attack_opening() and not _stun_hit and _player.velocity.y>50 and feet>position.y-88 and feet<position.y-44:
			take_damage(_player.get_attack_damage(),_player.global_position)
			_player.launch_from_spring(390)
		elif not _has_attack_opening() and _invulnerability<=0 and _player.global_position.y>position.y-60 and _player.global_position.y<position.y+15:
			_player.take_damage(1,global_position)
	queue_redraw()

func _set_state(value:String,duration:float) -> void:
	state=value
	_timer=duration
	_state_elapsed=0
	_melee_hits=0
	_throws=0
	if phase<3 and (value=="opening" or (phase==2 and value=="throw_warning")):
		_stun_damage=0;_stun_hit=false

func _has_attack_opening() -> bool:
	if phase>=3:return false
	return state in ["stunned","opening"] or (phase==2 and state=="throw_warning" and _state_elapsed<LANDING_OPENING)

func _prepare_attack() -> void:
	if phase==3:
		_position_for_spring();return
	if phase==2:
		_rope_bounces=0;_direction=1 if position.x<(LEFT+RIGHT)*.5 else -1
		_set_state("rope_warning",1.1);Sfx.alert();return
	var pattern:=["punch","throw","charge","kick","throw","leap"]
	_planned=pattern[_attack_number%pattern.size()]
	_attack_number+=1
	if _planned in ["punch","kick"] and absf(_player.position.x-position.x)>125:
		_set_state("approach",1.3)
	else:_warn(_planned)

func _warn(attack:String) -> void:
	_direction=signf(_player.position.x-position.x)
	if is_zero_approx(_direction):_direction=-1
	_target_x=clampf(_player.position.x,LEFT+30,RIGHT-30)
	_set_state("warning" if attack=="charge" else attack+"_warning",1.0 if attack=="throw" else 0.75)
	Sfx.alert()

func _hurt_front(reach:float) -> void:
	Sfx.swing()
	var gap:float=(_player.position.x-position.x)*_direction
	Fx.burst(position+Vector2(_direction*75,-32),Color("f2d2ff"),5,80)
	if gap>-12 and gap<reach and _player.position.y>position.y-58 and _player.position.y<position.y+12:
		_player.take_damage(1,position+Vector2(_direction*25,-25))

func _throw_object(kind:String,target_x:float) -> void:
	var object:=preload("res://world/Scripts/hyena_projectile.gd").new()
	object.kind=kind
	object.thrower=weakref(self)
	object.position=position+Vector2(_direction*37,-66)
	var target:=Vector2(target_x,FLOOR-14)
	var duration:=0.85
	object.flight=Vector2((target.x-object.position.x)/duration,(target.y-object.position.y-0.5*620*duration*duration)/duration)
	get_parent().add_child(object)
	Sfx.swing()

func _clear_projectiles() -> void:
	for object in get_tree().get_nodes_in_group("hyena_projectiles"):object.queue_free()

func _play(animation:StringName) -> void:
	var frames:SpriteFrames=ATTACK_FRAMES if ATTACK_FRAMES.has_animation(animation) else BASE_FRAMES
	_sprite.material.set_shader_parameter("alpha_cutoff",0.94)
	if _sprite.sprite_frames!=frames:
		_sprite.sprite_frames=frames
		_sprite.scale=Vector2.ONE*(96.0/BASE_FRAMES.get_frame_texture(&"idle",0).get_width())
	_sprite.play(animation)
	Art.reanchor(_sprite)

func _stun(duration:float=2.5) -> void:
	if phase==3:return
	if state=="stunned":return
	# A returned barrel can extend an existing opening, but cannot refill its damage.
	if not _has_attack_opening():
		_stun_hit=false
		_stun_damage=0
	_set_state("stunned",duration)
	velocity=Vector2.ZERO
	Sfx.hit()
	Fx.burst(global_position+Vector2(0,-55),Color("f6d299"),12,100)

func _sync_facing() -> void:
	# A antecipação aérea veio voltada à direita no atlas; compensa só essa célula.
	var reversed_cell:bool=_sprite.animation==&"leap" and _sprite.frame==0
	_sprite.flip_h=(_direction>0)!=reversed_cell

func receive_reflected_barrel() -> void:
	if not active or is_dead():return
	if phase==3:return
	if state=="stunned":return
	# A grounded stagger is earned by reflecting an actual thrown barrel.
	position.y=FLOOR
	_stun(3.5)
	Fx.popup(position+Vector2(0,-92),"BARRIL DEVOLVIDO!",Color("c6ffe5"),11)

func take_damage(amount: float, source: Vector2) -> void:
	if not active or is_dead() or amount<=0 or _invulnerability>0:return
	if phase==3:
		Fx.popup(global_position+Vector2(0,-100),"USE O TRAMPOLIM!",Color("f7ccaa"),9)
		return
	if not _has_attack_opening():
		if state in ["punch","punch_recovery"] and (source.x-position.x)*_direction < -8 and absf(source.y-position.y)<95:
			_stun(3.2)
			Fx.popup(position+Vector2(0,-92),"POR TRÁS!",Color("c6ffe5"),11)
		else:
			Fx.popup(global_position+Vector2(0,-88),"ESPERE A ABERTURA",Color("f7ccaa"),9)
			return
	var allowed:=MAX_DAMAGE_PER_STUN-_stun_damage
	if allowed<=0:return
	var applied:=minf(amount,allowed)
	_stun_damage+=applied
	_stun_hit=_stun_damage>=MAX_DAMAGE_PER_STUN
	health=maxf(0,health-applied)
	_invulnerability=0.8
	_timer=maxf(_timer,1.0)
	_play(&"hurt")
	Fx.burst(global_position+Vector2(0,-38),Color("ffdeb0"),16,170)
	Sfx.hit()
	if health<=0 and phase==1:
		phase=2;health=3;_clear_projectiles();velocity=Vector2.ZERO;position.y=FLOOR
		_set_state("idle",2.0);_stun_hit=false;_stun_damage=0
		_player.heal_one();Sfx.alert()
		Fx.popup(position+Vector2(0,-110),"SEGUNDO ROUND!",Color("ffe2ac"),10)
	elif health<=0 and phase==2:
		_begin_spring_round()
	elif is_dead():
		_defeat()
	queue_redraw()

func _begin_spring_round() -> void:
	phase=3;health=SPRING_ROUND_HEALTH
	_clear_projectiles();_clear_spring_launch()
	velocity=Vector2.ZERO;position.y=FLOOR
	_spring_side=-1;_stun_hit=false;_stun_damage=0
	_set_state("spring_intro",2.8)
	get_parent().get_node("HyenaRing").set_spring_side(_spring_side)
	_player.heal_one();Sfx.alert()
	Fx.popup(position+Vector2(0,-110),"ROUND 3 · TRAMPOLINS!",Color("ffe2ac"),11)

func _position_for_spring() -> void:
	_clear_spring_launch()
	# Keep the champion on the mat, within a comfortable spring-powered jump.
	_target_x=5360.0 if _spring_side<0 else 5680.0
	velocity=Vector2.ZERO
	_set_state("spring_position",3.0)
	get_parent().get_node("HyenaRing").set_spring_side(_spring_side)

func _on_ring_spring(player:CharacterBody2D,spring:Node2D) -> void:
	if phase!=3 or not active or is_dead() or player!=_player:return
	_clear_spring_launch()
	if state not in ["spring_position","spring_warning","leap","spring_guard"]:return
	var side:=-1 if spring.position.x<(LEFT+RIGHT)*.5 else 1
	if side!=_spring_side or absf(player.position.x-spring.position.x)>32:return
	_spring_armed=true
	Fx.popup(spring.position+Vector2(0,-60),"CAIA NA CABEÇA!",Color("c6ffe5"),9)

func _clear_spring_launch() -> void:
	_spring_armed=false;_spring_high=false;_spring_air_time=0

func _tick_spring_launch(delta:float) -> void:
	if not _spring_armed:return
	_spring_air_time+=delta
	if _player.is_dead() or _player._hitstun_timer>0 or _spring_air_time>SPRING_FLIGHT_LIMIT or (_spring_air_time>.12 and _player.is_on_floor()):
		_clear_spring_launch();return
	if _player.position.y+11<FLOOR-132:_spring_high=true

func _try_spring_stomp(delta:float) -> bool:
	if state!="spring_guard" or not _spring_armed or not _spring_high or _invulnerability>0:return false
	var feet:float=_player.position.y+11
	var head:=position.y-76
	if _player.velocity.y<=50 or absf(_player.position.x-position.x)>44 or feet<head-8 or feet>head+maxf(20,_player.velocity.y*delta+10):return false
	_clear_spring_launch()
	health=maxf(0,health-1)
	_invulnerability=.8
	_player.launch_from_spring(320)
	_player._invulnerability_timer=maxf(_player._invulnerability_timer,.45)
	Sfx.hit();Fx.burst(position+Vector2(0,-76),Color("ffe2ac"),18,160)
	if is_dead():_defeat()
	else:
		_spring_side=-_spring_side
		get_parent().get_node("HyenaRing").set_spring_side(_spring_side)
		_set_state("spring_recovery",1.4)
	return true

func _defeat() -> void:
	active=false;velocity=Vector2.ZERO;position.y=FLOOR
	_clear_projectiles();_clear_spring_launch()
	state="defeated";collision_layer=0
	_clear_gates();_bar.hide();_sprite.modulate=Color.WHITE
	_play(&"defeat");Sfx.enemy_death()
	died.emit();defeated.emit()
	queue_redraw()

func is_dead() -> bool:
	return health<=0

func _draw() -> void:
	if active and _has_attack_opening() and not _stun_hit:
		draw_arc(Vector2(0,-35),53,PI,TAU,20,Color("ffe2a0"),2)
		draw_string(ThemeDB.fallback_font,Vector2(-48,-97),"ATAQUE!",HORIZONTAL_ALIGNMENT_CENTER,96,10,Color("ffe2a0"))
	if phase==3 and active and state=="spring_guard":
		var color:=Color("ffe2ac") if _spring_armed else Color("c4a3ec")
		draw_line(Vector2(-8,-101),Vector2(0,-93),color,3)
		draw_line(Vector2(0,-93),Vector2(8,-101),color,3)
	if state in ["warning","leap_warning","punch_warning","kick_warning","throw_warning","spring_warning"]:
		var at:=Vector2(_target_x-global_position.x,0) if state in ["leap_warning","throw_warning","spring_warning"] else Vector2(0,-85)
		draw_rect(Rect2(at+Vector2(-16,-3),Vector2(32,3)),Color("ffa3a9"))
		draw_rect(Rect2(at+Vector2(-2,-20),Vector2(4,11)),Color("ffe4b5"))
		draw_rect(Rect2(at+Vector2(-2,-5),Vector2(4,4)),Color("ffe4b5"))
	if _shock>0:
		var radius:float=(1-_shock/0.55)*105
		draw_line(Vector2(-radius,0),Vector2(-radius-12,0),Color("eec6ff"),3)
		draw_line(Vector2(radius,0),Vector2(radius+12,0),Color("eec6ff"),3)

extends CharacterBody2D
signal died
signal defeated
signal encounter_started
const Art=preload("res://world/Scripts/underworld_art.gd")
const MAX_HEALTH:=12.0
const MARKER_X:=7150.0
const UPPER_FLOOR:=-160.0
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
func _ready() -> void:
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
	_sprite.sprite_frames = preload("res://world/Arte/Underworld/V44/guardian.tres")
	_normal_scale = _sprite.scale
	add_child(_sprite)
	_sprite.play(&"idle")
	_pedestal=AnimatableBody2D.new()
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
	_build_bar()
func _build_bar() -> void:
	_bar=CanvasLayer.new()
	_bar.layer=16
	add_child(_bar)
	var panel:=Panel.new()
	panel.position=Vector2(66,58)
	panel.size=Vector2(508,32)
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
	_phase_caption.position = Vector2(74, 59)
	_phase_caption.size = Vector2(492, 11)
	_phase_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_caption.add_theme_font_size_override("font_size", 9)
	_phase_caption.add_theme_color_override("font_color", Color("ffd298"))
	_bar.add_child(_phase_caption)
	_caption=Label.new()
	_caption.position=Vector2(74,71)
	_caption.size=Vector2(492,11)
	_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_caption.add_theme_font_size_override("font_size",8)
	_bar.add_child(_caption)
	_fill=ColorRect.new()
	_fill.position=Vector2(74,85)
	_fill.size=Vector2(492,3)
	_fill.color=Color("f4a96b")
	_fill.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_bar.add_child(_fill)
	_bar.hide()
func start_encounter() -> void:
	if active or is_dead():return
	active=true
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
func _clear_projectiles() -> void:
	for shot in get_tree().get_nodes_in_group("underworld_projectiles"):shot.queue_free()
func _clear_gates() -> void:
	for gate in _gates:
		if is_instance_valid(gate):gate.queue_free()
	_gates.clear()
func reset_encounter() -> void:
	if is_dead():return
	if is_instance_valid(_entrance): _entrance.finish()
	if phase == 5 and is_instance_valid(cylinder):
		_clear_projectiles()
		cylinder._recover()
		return
	if _upper_unlocked:
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
	preload("res://world/Scripts/magic_art.gd").reanchor(_sprite)
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
	if phase == 5:
		_phase_time += delta
		_vulnerable = maxf(0, _vulnerable - delta)
		_sprite.play(&"hurt" if _vulnerable > 0 else (&"roar" if cylinder._warning > 0 else &"exposed"))
		_sprite.modulate = Color.WHITE
		_sprite.flip_h = false
		_fill.size.x = 492 * maxf(0, 3 - cylinder.hits) / 3.0
		_phase_caption.text = "5 / 5 · ÚLTIMA CORRENTE · CANHÕES %d / 3" % cylinder.hits
		_caption.text = _advice()
		_fill.color = Color("a2d9ee") if cylinder.hits == 1 else Color("f4ac71")
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
	_pedestal.visible=phase==2
	_pedestal.collision_layer=1 if phase==2 else 0
	if phase==2:
		lava_y=lerpf(153, -109,clampf(_phase_time/13,0,1))
		position.y=lerpf(100,UPPER_FLOOR,clampf((_phase_time-2)/9,0,1))
		_sprite.play(&"chain_cast" if _cast_anim > 0 or _cast_warn else &"lava")
		if _timer <= 0.4 and not _cast_warn:
			_cast_warn = true
			_cast_target = _player.position
		if _timer<=0:
			_cast_chain()
			_timer=2.3
			_cast_warn = false
		if _phase_time>=11 and _player.position.y+11<=UPPER_FLOOR+15:
			phase=3
			position.y=UPPER_FLOOR
			_phase_time=0
			state="idle"
			_timer=1.4
			health=9
			_upper_unlocked = true
			_cast_warn = false
			_player.respawn_position = Vector2(6950, UPPER_FLOOR - 11)
			Fx.popup(Vector2(6990, UPPER_FLOOR - 110), "PATAMAR SEGURO · RETOMADA ATIVADA", Color("bce6d6"), 9)
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
				_sprite.play(&"heated" if heated else (&"frozen" if brittle else &"guard"))
				if phase==4:
					var gap:float=_player.position.x-position.x
					if absf(gap)>85:position.x=move_toward(position.x,clampf(_player.position.x,6835,7340),95*delta)
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
	if _vulnerable<=0 and state != "recover" and _player.position.distance_to(position+Vector2(0,-22))<48:_player.take_damage(1,position)
	if _invulnerable > 0.43 and phase != 2: _sprite.play(&"hurt")
	_fill.size.x=492*health/MAX_HEALTH
	_phase_caption.text="%d / 5 · CARCEREIRO · " % phase + ["", "CORRENTES", "LAVA ASCENDENTE", "ARMADURA RACHADA", "A INVESTIDA DE JOSÉ"][phase]
	_caption.text=_advice()
	_fill.color = Color("a7e5f4") if brittle else (Color("ffba75") if heated else Color("e4bb8d"))
	queue_redraw()
func _advice() -> String:
	if _vulnerable>0 and phase < 5:return "J / X NA CORRENTE PRESA!" if phase == 1 else "ATAQUE O PONTO FRACO!"
	match phase:
		1:return "Pule a onda; J / X no fecho dourado da corrente presa"
		2:return "LAVA SUBINDO! E: corrente · ↑: subir · Espaço: soltar"
		3:return "GELO nas correntes!" if heated else "FOGO na armadura!"
		4:return "Atraia para o círculo dourado e use C: JOSÉ"
		5:return "Suba pelas plataformas; K no canhão de " + ("GELO" if cylinder.hits == 1 else "FOGO") + " · Q: alternar"
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
	shot.position=position+Vector2(_side * 45,-75)
	shot.flight=((_cast_target if _cast_warn else _player.position)-shot.position).normalized()*175
	get_parent().add_child(shot)
func take_element(element:String,source:Vector2) -> void:
	if not active or is_dead() or phase==2 or phase==5:return
	if _vulnerable>0:take_damage(1,source);return
	if phase!=3:return
	if element=="fire":
		heated=true
		Sfx.play("warden_fire_charge", -8)
		Fx.popup(position+Vector2(0,-140),"ARMADURA AQUECIDA · GELO!",Color("ffc788"),9)
	elif element=="ice" and heated:
		brittle=true
		_vulnerable=3.0
		_timer=3.4
		state="idle"
		Fx.burst(position+Vector2(0,-60),Color("b6f1ff"),20,150)
		Sfx.play("warden_break", -5)
func take_damage(amount:float,_source:Vector2) -> void:
	if not active or is_dead() or phase==5 or amount<=0 or _invulnerable>0 or _vulnerable<=0:return
	_invulnerable=0.65
	health=maxf(0,health-amount)
	Sfx.play("warden_hurt", -5)
	Fx.burst(position+Vector2(0,-60),Color("ffe3a3"),15,140)
	if phase==1 and health<=9:
		health=9
		phase=2
		_phase_time=0
		_vulnerable=0
		_timer=1.8
		_clear_projectiles()
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
	preload("res://world/Scripts/magic_art.gd").reanchor(_sprite)
	_player.heal_full()
	cylinder = preload("res://world/Scripts/warden_cylinder.gd").new()
	cylinder.name = "WardenCylinder"
	cylinder.boss = self
	get_parent().add_child(cylinder)
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
	health=0
	active=false
	state="defeated"
	velocity=Vector2.ZERO
	position.y=UPPER_FLOOR
	_sprite.play(&"freed")
	_sprite.scale = _normal_scale
	preload("res://world/Scripts/magic_art.gd").reanchor(_sprite)
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
	if active and phase == 2 and _cast_warn:
		var from := Vector2(_side * 45, -75)
		var target := to_local(_cast_target)
		for i in range(1, 12):
			var at := from.lerp(target, i / 12.0).round()
			draw_rect(Rect2(at, Vector2(2, 2)), Color(1, 0.75, 0.4, 0.6))
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

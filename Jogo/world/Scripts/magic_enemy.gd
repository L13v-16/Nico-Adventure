extends CharacterBody2D
signal died
@export_enum("beetle", "moth") var species := "beetle"
@export var patrol_width := 150.0
@export var phase := 0.0
const Art := preload("res://world/Scripts/magic_art.gd")
var health := 2.0
var frozen_left := 0.0
var state := "patrol"
var _timer := 1.7
var _clock := 0.0
var _direction := -1.0
var _home := Vector2.ZERO
var _target := Vector2.ZERO
var _invulnerability := 0.0
var _sprite: AnimatedSprite2D
var _player: CharacterBody2D

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("magic_enemies")
	collision_layer = 4
	collision_mask = 1
	_home = position
	_clock = phase
	health = 2.0 if species=="beetle" else 1.0
	_sprite = Art.actor(load("res://world/Arte/Magic/%s.tres"%species),56 if species=="beetle" else 48)
	add_child(_sprite)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(36,22) if species=="beetle" else Vector2(28,26)
	var collider := CollisionShape2D.new()
	collider.position.y = -11 if species=="beetle" else -12
	collider.shape = shape
	add_child(collider)
	_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	_sprite.play(&"walk" if species=="beetle" else &"fly")

func _physics_process(delta: float) -> void:
	if is_dead(): return
	_clock += delta
	_invulnerability = maxf(0,_invulnerability-delta)
	if frozen_left>0:
		frozen_left = maxf(0,frozen_left-delta)
		_sprite.pause()
		_sprite.modulate = Color("95e7ff")
		queue_redraw()
		return
	_sprite.modulate = Color("ffbdd5") if _invulnerability>0 else Color.WHITE
	_timer -= delta
	var near: bool = is_instance_valid(_player) and not _player.is_dead() and global_position.distance_to(_player.global_position)<150
	if species=="beetle":
		if state=="patrol" and _timer<=0 and near:
			state="warning"
			_timer=0.65
			var side:=signf(_player.global_position.x-global_position.x)
			if not is_zero_approx(side):_direction=side
			Sfx.alert()
		elif state=="warning" and _timer<=0:
			state="attack"
			_timer=0.55
		elif state=="attack" and _timer<=0:
			state="patrol"
			_timer=1.8
		var edge := _home.x+patrol_width*0.5*_direction
		if (position.x-edge)*_direction>=0:
			_direction *= -1
			state="patrol"
			_timer=1.0
		velocity.x = 0 if state=="warning" else _direction*(155 if state=="attack" else 52)
		velocity.y = minf(velocity.y+980*delta,700)
		move_and_slide()
		position.x=clampf(position.x,_home.x-patrol_width*0.5,_home.x+patrol_width*0.5)
	else:
		if state=="patrol" and _timer<=0 and near:
			state="warning"
			_timer=0.7
			_target=_player.global_position+Vector2(0,-7)
		elif state=="warning" and _timer<=0:
			state="attack"
			_timer=0.7
		elif state=="attack" and _timer<=0:
			state="return"
			_timer=0.8
		elif state=="return" and _timer<=0:
			state="patrol"
			_timer=2.0
		var desired := _home+Vector2(sin(_clock)*patrol_width*0.5,cos(_clock*1.7)*15)
		if state=="attack": desired=_target
		if state!="warning":
			var previous := position
			position=position.move_toward(desired,(225 if state=="attack" else 100)*delta)
			var side:=signf(position.x-previous.x)
			if not is_zero_approx(side):_direction=side
	_sprite.flip_h=_direction>0
	_sprite.play(&"warning" if state=="warning" else (&"attack" if state=="attack" else (&"walk" if species=="beetle" else &"fly")))
	if near and absf(_player.global_position.x-global_position.x)<25 and absf(_player.global_position.y-global_position.y)<25:
		if species=="moth" and _player.velocity.y>60 and _player.global_position.y<global_position.y-12:
			take_damage(1,_player.global_position)
			_player.launch_from_spring(320)
		else:
			_player.take_damage(1,global_position)
	queue_redraw()

func take_damage(amount: float, _source: Vector2) -> void:
	if is_dead() or amount<=0 or _invulnerability>0:return
	health=maxf(0,health-amount)
	_invulnerability=0.35
	Fx.burst(global_position+Vector2(0,-16),Color("dcb8ff"),8,90)
	if is_dead():
		frozen_left=0
		velocity=Vector2.ZERO
		queue_redraw()
		collision_layer=0
		_sprite.play(&"defeat")
		_sprite.modulate=Color.WHITE
		died.emit()
		Sfx.enemy_death()
		var tween:=create_tween()
		tween.tween_interval(0.3)
		tween.tween_property(self,"modulate:a",0.0,0.35)
		tween.tween_callback(queue_free)

func freeze_for(duration: float) -> void:
	if not is_dead(): frozen_left=maxf(frozen_left,duration)
	queue_redraw()

func is_dead() -> bool:
	return health<=0

func _draw() -> void:
	if frozen_left>0:
		draw_rect(Rect2(-22,-32,44,32),Color(0.6,0.9,1.0,0.17))
		draw_line(Vector2(-22,-32),Vector2(22,-32),Color("dafbff"),1)

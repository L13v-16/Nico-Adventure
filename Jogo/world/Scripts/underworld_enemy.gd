extends CharacterBody2D
signal died
@export_enum("skeleton","imp") var species:="skeleton"
@export var patrol_width:=150.0
var health:=2.0
var frozen_left:=0.0
var state:="patrol"
var _timer:=1.4
var _clock:=0.0
var _side:=-1.0
var _home:=Vector2.ZERO
var _invulnerable:=0.0
var _stagger:=0.0
var _sprite:AnimatedSprite2D
var _player:CharacterBody2D
const Art=preload("res://world/Scripts/underworld_art.gd")
func _ready() -> void:
	add_to_group("enemies")
	add_to_group("underworld_enemies")
	collision_layer=4
	collision_mask=1
	_home=position
	health=2 if species=="skeleton" else 1
	_sprite=Art.actor(species,46 if species=="skeleton" else 42)
	add_child(_sprite)
	if species=="imp":
		_sprite.frame_changed.connect(_anchor_flight)
		_sprite.animation_changed.connect(_anchor_flight)
	var shape:=RectangleShape2D.new()
	shape.size=Vector2(23,34) if species=="skeleton" else Vector2(26,22)
	var collider:=CollisionShape2D.new()
	collider.shape=shape
	collider.position.y=-17 if species=="skeleton" else -11
	add_child(collider)
	_player=get_tree().get_first_node_in_group("player")
	_sprite.play(&"walk" if species=="skeleton" else &"fly")
	if species=="imp":_anchor_flight()
func _anchor_flight() -> void:
	if is_dead():return # A pose derrotada continua apoiada no chão ao cair.
	var texture:Texture2D=_sprite.sprite_frames.get_frame_texture(_sprite.animation,_sprite.frame)
	if texture!=null and texture.has_meta("hover_anchor"):
		# Corpo e ponto de lançamento ficam estáveis enquanto as asas batem.
		_sprite.position=Vector2(0,-11)-Vector2(texture.get_meta("hover_anchor"))*_sprite.scale
		_sprite.set_meta("ground_art_offset",_sprite.position)
func _physics_process(delta:float) -> void:
	if is_dead():
		if species=="imp":
			velocity.y=minf(velocity.y+980*delta,600)
			move_and_slide()
		return
	_invulnerable=maxf(0,_invulnerable-delta)
	if frozen_left>0:
		frozen_left=maxf(0,frozen_left-delta)
		_sprite.pause()
		_sprite.modulate=Color("a2eaff")
		return
	_stagger=maxf(0,_stagger-delta)
	if _stagger>0:
		_sprite.play(&"hurt")
		_sprite.modulate=Color("ffbf9d")
		if species=="skeleton":
			velocity.y=minf(velocity.y+980*delta,600)
			velocity.x=move_toward(velocity.x,0,250*delta)
			move_and_slide()
		return
	_clock+=delta
	_timer-=delta
	_sprite.modulate=Color("ffaf97") if _invulnerable>0 else Color.WHITE
	var near:bool=not _player.is_dead() and absf(_player.position.x-position.x)<250 and absf(_player.position.y-position.y)<180
	if state=="patrol" and _timer<=0 and near:
		state="warning"
		_timer=0.75
		_side=-1 if _player.position.x<position.x else 1
		Sfx.alert()
	elif state=="warning" and _timer<=0:
		state="attack"
		_timer=0.35
		if species=="imp":_throw()
		elif absf(_player.position.x-position.x)<56 and absf(_player.position.y-position.y)<42:_player.take_damage(1,position)
	elif state=="attack" and _timer<=0:
		state="patrol"
		_timer=2.2
	if species=="skeleton":
		if state=="patrol":
			if absf(position.x-_home.x)>patrol_width/2:_side=-signf(position.x-_home.x)
		velocity.x=_side*38 if state=="patrol" else 0
		velocity.y=minf(velocity.y+980*delta,600)
		move_and_slide()
		position.x=clampf(position.x,_home.x-patrol_width/2,_home.x+patrol_width/2)
	else:
		if state=="patrol":position=_home+Vector2(sin(_clock*0.7)*patrol_width/2,cos(_clock*1.6)*12)
	_sprite.flip_h=_side>0
	_sprite.play(&"warning" if state=="warning" else (&"attack" if state=="attack" else (&"walk" if species=="skeleton" else &"fly")))
	if global_position.distance_to(_player.global_position)<25:
		if _player.velocity.y>70 and _player.position.y<position.y-12:
			take_damage(1,_player.position)
			_player.launch_from_spring(330)
		else:_player.take_damage(1,position)
func _throw() -> void:
	var shot:=preload("res://world/Scripts/underworld_trident.gd").new()
	shot.position=global_position+Vector2(_side*18,-11)
	var aim:Vector2=(_player.global_position+Vector2(0,-4)-shot.position).normalized()
	shot.flight=aim*205
	get_parent().add_child(shot)
func take_element(element:String,source:Vector2) -> void:
	take_damage(1,source)
	if element=="ice":freeze_for(3)
func take_damage(amount:float,source:Vector2) -> void:
	if is_dead() or _invulnerable>0 or amount<=0:return
	health=maxf(0,health-amount)
	_invulnerable=0.3
	_stagger=0.28
	state="patrol"
	_timer=1.1
	velocity.x=(1 if position.x>=source.x else -1)*110
	Fx.burst(position+Vector2(0,-18),Color("f6b17a"),7,90)
	Sfx.hit()
	if is_dead():
		frozen_left=0
		collision_layer=0
		_sprite.play(&"defeat")
		_sprite.modulate=Color.WHITE
		died.emit()
		var tween:=create_tween()
		tween.tween_interval(0.35)
		tween.tween_property(self,"modulate:a",0.0,0.4)
		tween.tween_callback(queue_free)
func is_dead() -> bool:return health<=0
func freeze_for(seconds:float) -> void:
	if not is_dead():frozen_left=maxf(frozen_left,seconds)

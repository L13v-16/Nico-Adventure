extends CharacterBody2D
signal died
@export var species:="specimen"
@export var patrol_width:=160.0
var health:=2.0
var frozen_left:=0.0
var state:="walk"
var _clock:=0.0
var _timer:=1.5
var _invulnerable:=0.0
var _home:=Vector2.ZERO
var _side:=-1.0
var _sprite:AnimatedSprite2D
var _player:CharacterBody2D
func _ready() -> void:
	add_to_group("enemies");add_to_group("lab_enemies");collision_layer=4;collision_mask=1
	_home=position;_player=get_tree().get_first_node_in_group("player")
	health=3 if species=="technician" else 2
	_sprite=preload("res://world/Scripts/lab_art.gd").actor(species,48 if species!="lizard" else 58);add_child(_sprite);_sprite.play(&"walk")
	var collider:=CollisionShape2D.new();var shape:=RectangleShape2D.new();shape.size=Vector2(25,26)
	collider.shape=shape;collider.position.y=-13;add_child(collider)
func _physics_process(delta:float) -> void:
	if is_dead():return
	if position.y>430:take_damage(health,position);return
	_clock+=delta;_invulnerable=maxf(0,_invulnerable-delta)
	if frozen_left>0:
		frozen_left=maxf(0,frozen_left-delta);_sprite.pause();_sprite.modulate=Color("9deafa");return
	_sprite.modulate=Color("ffb9a6") if _invulnerable>0 else Color.WHITE
	if absf(_player.position.x-position.x)>680:return
	_timer-=delta
	var close:bool=not _player.is_dead() and absf(_player.position.x-position.x)<230 and absf(_player.position.y-position.y)<110
	if state=="walk" and _timer<=0 and close:state="warning";_timer=.7;_side=signf(_player.position.x-position.x);Sfx.play("lab_scan",-14)
	elif state=="warning" and _timer<=0:
		state="attack";_timer=.45
		if species in ["drone","technician"]:_shoot()
		elif species=="specimen":velocity=Vector2(_side*155,-280)
		elif absf(_player.position.x-position.x)<85:_player.take_damage(1,position)
	elif state=="attack" and _timer<=0:state="walk";_timer=2.0
	if species=="drone":position=_home+Vector2(sin(_clock)*patrol_width/2,cos(_clock*2)*9)
	else:
		if absf(position.x-_home.x)>patrol_width/2:_side=-signf(position.x-_home.x)
		if state=="walk" and is_on_floor():
			var probe:=PhysicsRayQueryParameters2D.create(global_position+Vector2(_side*24,-8),global_position+Vector2(_side*24,24),1)
			if get_world_2d().direct_space_state.intersect_ray(probe).is_empty():_side=-_side
		if state=="walk":velocity.x=_side*(42 if species!="lizard" else 58)
		elif state=="warning":velocity.x=0
		velocity.y=minf(velocity.y+980*delta,650);move_and_slide()
		position.x=clampf(position.x,_home.x-patrol_width/2-40,_home.x+patrol_width/2+40)
	_sprite.flip_h=_side>0;_sprite.play(&"attack" if state=="attack" else (&"warning" if state=="warning" else &"walk"))
	if species=="lizard" and state=="warning":_sprite.modulate.a=.45+absf(sin(_clock*5))*.3
	if _player.global_position.distance_to(global_position+Vector2(0,-12))<25:
		if _player.velocity.y>60 and _player.position.y<position.y-12:take_damage(1,_player.position);_player.launch_from_spring(330)
		else:_player.take_damage(1,position)
func _shoot() -> void:
	var shot:=preload("res://world/Scripts/lab_projectile.gd").new();shot.net=species=="technician"
	shot.position=position+Vector2(_side*20,-16);shot.flight=(_player.position-shot.position).normalized()*190;get_parent().add_child(shot)
	Sfx.play("lab_dart",-12)
func take_damage(amount:float,_source:Vector2) -> void:
	if is_dead() or _invulnerable>0 or amount<=0:return
	health=maxf(0,health-amount);_invulnerable=.35;Sfx.hit()
	if is_dead():
		collision_layer=0;_sprite.modulate=Color.WHITE;_sprite.play(&"defeat");died.emit()
		var tween:=create_tween();tween.tween_interval(.3);tween.tween_property(self,"modulate:a",0,.4);tween.tween_callback(queue_free)
func take_element(element:String,source:Vector2) -> void:
	take_damage(1,source)
	if element=="ice":freeze_for(3)
func freeze_for(seconds:float) -> void:
	if not is_dead():frozen_left=maxf(frozen_left,seconds)
func is_dead() -> bool:return health<=0

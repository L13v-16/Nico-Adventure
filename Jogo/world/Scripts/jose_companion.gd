extends CharacterBody2D
signal headbutt_landed(target:Node)
const Art=preload("res://world/Scripts/underworld_art.gd")
var rescued:=false
var state:="idle"
var _timer:=0.0
var _sprite:AnimatedSprite2D
var _target:Node2D
var _player:CharacterBody2D
var _dash_side:=1.0
var _safe_spot:=Vector2.ZERO
var _prepare_timeout:=0.0
func _ready() -> void:
	collision_layer=0
	collision_mask=1
	var shape:=CapsuleShape2D.new()
	shape.radius=10
	shape.height=30
	var collider:=CollisionShape2D.new()
	collider.shape=shape
	collider.position.y=-15
	add_child(collider)
	_sprite=Art.actor("jose",44)
	add_child(_sprite)
	_sprite.play(&"idle")
	_player=get_tree().get_first_node_in_group("player")
	_player.respawned.connect(reset_follow)
	_safe_spot=position
func reset_follow() -> void:
	_target=null
	state="idle"
	velocity=Vector2.ZERO
	position=_player.respawn_position+Vector2(-36,11)
func command(target:Node2D) -> bool:
	if not rescued or state in ["windup","charge"] or not is_instance_valid(target):return false
	if not target.has_method("can_jose_target") or not target.can_jose_target():return false
	if _player.global_position.distance_to(target.jose_point())>240:return false
	_target=target
	_dash_side=1 if target.jose_point().x>position.x else -1
	state="windup"
	_timer=0.35
	_prepare_timeout=2.2
	if not is_on_floor():velocity.y=-360
	_sprite.flip_h=_dash_side<0
	_sprite.play(&"windup")
	return true
func _physics_process(delta:float) -> void:
	if not rescued:return
	_timer-=delta
	if state=="windup":
		_prepare_timeout-=delta
		var approach_x:float=_target.jose_point().x-_dash_side*24 if is_instance_valid(_target) else position.x
		velocity.x=clampf((approach_x-position.x)*5,-180,180) if not is_on_floor() else 0
		if not is_on_floor():_timer=maxf(_timer,0.12)
		_sprite.play(&"jump" if not is_on_floor() else &"windup")
		if _prepare_timeout<=0:
			state="idle"
			_target=null
		if _timer<=0:state="charge";_timer=1.0
	elif state=="charge":
		if not is_instance_valid(_target):state="idle"
		else:
			velocity.x=_dash_side*480
			_sprite.play(&"charge")
			var reach:float=_target.jose_hit_range() if _target.has_method("jose_hit_range") else 48.0
			if absf(position.x-_target.jose_point().x)<reach and absf(position.y-_target.jose_point().y)<55:
				var target:=_target
				if target.receive_jose_hit():headbutt_landed.emit(target)
				state="recover"
				_timer=0.6
				velocity.x=0
				_sprite.play(&"impact")
			elif _timer<=0:state="recover";_timer=0.5;velocity.x=0
	elif state=="recover":
		velocity.x=0
		if _timer<=0:state="idle"
	else:
		var dx:float=_player.position.x-position.x
		velocity.x=signf(dx)*minf(absf(dx)*3,245) if absf(dx)>62 else 0
		if velocity.x!=0:_sprite.flip_h=velocity.x<0
		_sprite.play((&"jump" if velocity.y<0 else &"fall") if not is_on_floor() else (&"walk" if absf(velocity.x)>5 else &"idle"))
		if is_on_floor() and absf(dx)>90 and _player.position.y+11<position.y-24:velocity.y=-440
		elif is_on_floor() and absf(dx)>75:
			var front:=global_position+Vector2(signf(dx)*28,-6)
			var probe:=PhysicsRayQueryParameters2D.create(front,front+Vector2(0,48),1)
			if get_world_2d().direct_space_state.intersect_ray(probe).is_empty():velocity.y=-410
		if _player.is_on_floor() and (absf(dx)>340 or position.y>300 or position.y-_player.position.y>160):
			# Reencontra Nico fora do enquadramento, depois de abismos e elevadores.
			position=_player.position+Vector2(-signf(dx)*58,11)
			velocity=Vector2.ZERO
	velocity.y=minf(velocity.y+980*delta,650)
	move_and_slide()
	if is_on_floor():_safe_spot=position
	if position.y>390:position=_safe_spot;velocity=Vector2.ZERO

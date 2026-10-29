extends CharacterBody2D
signal died
var level:Node2D
var species:=0
var sector:=0
var patrol_width:=140.0
var health:=2.0
var state:="walk"
var frozen_left:=0.0
var _timer:=1.7
var _side:=-1.0
var _clock:=0.0
var _home:=Vector2.ZERO
var _invulnerable:=0.0
var _fired:=false
var _sprite:AnimatedSprite2D
func _ready() -> void:
	add_to_group("enemies");add_to_group("corp_enemies");collision_layer=4;collision_mask=1
	_home=position;health=4 if species==2 else (3 if species==3 else 2)
	_sprite=AnimatedSprite2D.new();_sprite.sprite_frames=preload("res://world/Scripts/Corp2D/art.gd").enemy_frames(species)
	_sprite.centered=false;_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;add_child(_sprite)
	_sprite.scale=Vector2.ONE*(.16 if species==2 else .12)
	preload("res://world/Scripts/general_art.gd").extend_enemy(_sprite,species)
	_sprite.frame_changed.connect(_anchor);_sprite.animation_changed.connect(_anchor);_sprite.play("walk");_anchor()
	var shape:=RectangleShape2D.new();shape.size=Vector2(26,32 if species!=1 else 22)
	var collider:=CollisionShape2D.new();collider.shape=shape;collider.position.y=-shape.size.y/2;add_child(collider)
func _anchor() -> void:
	preload("res://world/Scripts/general_art.gd").anchor_enemy(_sprite)
func _physics_process(delta:float) -> void:
	if health<=0 or level.sector!=sector or level.intro_active or level.completed:return
	var player:CharacterBody2D=level.player
	_clock+=delta;_invulnerable=maxf(0,_invulnerable-delta)
	if frozen_left>0:
		frozen_left=maxf(0,frozen_left-delta);_sprite.pause();_sprite.modulate=Color("87ddff");return
	_sprite.modulate=Color("ffb69e") if _invulnerable>0 else Color.WHITE
	_timer-=delta
	var offset:=player.position-position
	if state=="walk":
		if _timer<=0 and absf(offset.x)<230 and absf(offset.y)<90 and not player.is_dead():
			state="warning";_timer=1.0;_side=signf(offset.x);Sfx.play("lab_scan",-16)
	elif state=="warning" and _timer<=0:state="attack";_timer=.45;_fired=false
	elif state=="attack":
		if not _fired:
			_fired=true
			if species in [1,3]:level.shoot(position+Vector2(_side*20,-20),Vector2(_side,-.03)*185,false,species==1)
			elif absf(offset.x)<75 and offset.x*_side>0 and absf(offset.y)<30:player.take_damage(1,position)
			if species==2:level.shoot(position+Vector2(_side*28,-5),Vector2(_side*180,0),true)
		if _timer<=0:state="recovery";_timer=1.35
	elif state in ["hurt","recovery"] and _timer<=0:state="walk";_timer=1.7
	if species==1:
		if state=="walk":
			var target:=player.position+Vector2(-90,-70) if absf(offset.x)<260 else _home
			position=position.move_toward(target,35*delta);position.y+=sin(_clock*3)*4*delta
	else:
		if state=="walk":
			if absf(position.x-_home.x)>patrol_width/2:_side=-signf(position.x-_home.x)
			var ray:=PhysicsRayQueryParameters2D.create(position+Vector2(_side*25,-8),position+Vector2(_side*25,28),1)
			if is_on_floor() and get_world_2d().direct_space_state.intersect_ray(ray).is_empty():_side=-_side
			velocity.x=_side*(26 if species==2 else 40)
		else:velocity.x=move_toward(velocity.x,0,800*delta)
		velocity.y=minf(velocity.y+980*delta,620);move_and_slide()
	_sprite.flip_h=_side>0;_sprite.play(state)
	if not player.is_dead() and player.position.distance_to(position+Vector2(0,-14))<25:
		if player.velocity.y>70 and player.position.y<position.y-22:
			take_damage(1,player.position);player.launch_from_spring(330)
		elif state=="attack":player.take_damage(1,position)
	queue_redraw()
func take_element(element:String,source:Vector2) -> void:
	if element=="ice":freeze_for(3);take_damage(1,source)
	else:take_damage(1,source,true)
func freeze_for(seconds:float) -> void:
	if health>0:frozen_left=maxf(frozen_left,seconds)
func take_damage(amount:float,source:Vector2,elemental:bool=false) -> void:
	if health<=0 or _invulnerable>0:return
	var shielded:bool=species in [0,2] and state not in ["recovery","hurt"] and frozen_left<=0 and (source.x-position.x)*_side>0
	if shielded and not elemental:
		level.tell("Escudo à frente! Acerte por trás, congele ou espere o ataque.");Sfx.play("lab_clink",-14);return
	health-=amount;_invulnerable=.4;Sfx.hit();Fx.burst(position+Vector2(0,-18),Color("ffc07a"),7,90)
	if health<=0:
		state="defeated";_sprite.play("defeated");_anchor();_sprite.modulate=Color.WHITE
		collision_layer=0;died.emit();set_physics_process(false)
		var tween:=create_tween()
		if species==1:
			var ray:=PhysicsRayQueryParameters2D.create(position,position+Vector2(0,160),1)
			var hit:=get_world_2d().direct_space_state.intersect_ray(ray)
			if not hit.is_empty():tween.tween_property(self,"position:y",hit.position.y,.2)
		tween.tween_property(self,"modulate:a",0,.4);tween.tween_callback(queue_free)
	else:state="hurt";_timer=.7;_sprite.play("hurt");_anchor()
func is_dead() -> bool:return health<=0
func _draw() -> void:
	if frozen_left>0:draw_arc(Vector2(0,-18),23,0,TAU,10,Color("c5f4ff"),2)
	if state=="warning":
		draw_rect(Rect2(-1,-53,3,8),Color("ffd187"));draw_rect(Rect2(-1,-43,3,2),Color("ffd187"))
		for x in range(20,75,12):draw_rect(Rect2(_side*x,-5,4,2),Color("ffb28d",.7))

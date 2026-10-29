extends Node2D
## Pêndulo com impulso do jogador e velocidade tangencial ao soltar.
@export var length := 194.0
@export var automatic_travel := 0.0
@export var phase := -1.57
@export var plant_offset := Vector2.ZERO
var angle := -0.85
var angular_velocity := 0.0
var rider: CharacterBody2D
var shifted := false
var _home := Vector2.ZERO
var _shift := Vector2.ZERO
var _clock := 0.0
var _anchor_velocity := Vector2.ZERO
var _needs_release := false
var _shift_velocity := Vector2.ZERO
var _anchor_acceleration := Vector2.ZERO
var _last_step := -1
const GRAVITY := 780.0
const REST_AMPLITUDE := 0.78
const SOFT_LIMIT := 0.90
const MAX_ANGLE := 1.08
const MAX_ANGULAR_SPEED := 2.25
const HAND_OFFSET := Vector2(0,12)
var _hint: Label
var _art: Node2D
var _cherries: Array[Dictionary] = []
const SEGMENTS := [preload("res://world/Arte/Magic/V26/vine_segment_0.tres"),preload("res://world/Arte/Magic/V26/vine_segment_1.tres"),preload("res://world/Arte/Magic/V26/vine_segment_2.tres"),preload("res://world/Arte/Magic/V26/vine_segment_3.tres")]
const ANCHOR := preload("res://world/Arte/Magic/V26/vine_anchor.tres")
const GRIP := preload("res://world/Arte/Magic/V26/vine_grip.tres")

func _ready() -> void:
	add_to_group("living_vines")
	process_physics_priority = -10
	_home = position
	# Start at the actual moving anchor position, without a first-frame jump.
	position=_home+Vector2(sin(phase)*automatic_travel,0)
	angle=sin(phase)*REST_AMPLITUDE;angular_velocity=0
	_anchor_velocity=Vector2(cos(phase)*automatic_travel*.65,0)
	_art=Node2D.new()
	_art.material=preload("res://world/Scripts/magic_art.gd").material()
	_art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_art.draw.connect(_paint)
	add_child(_art)
	_hint = Label.new()
	_hint.text = "E  agarrar"
	_hint.add_theme_font_size_override("font_size",9)
	_hint.add_theme_color_override("font_color",Color("c4fff0"))
	_hint.add_theme_color_override("font_shadow_color",Color("201638"))
	_hint.add_theme_constant_override("shadow_offset_x",1)
	_hint.add_theme_constant_override("shadow_offset_y",1)
	add_child(_hint)

func _physics_process(delta: float) -> void:
	if delta<=0:return
	var previous_grip:=get_grip()+HAND_OFFSET
	_clock += delta
	var old := global_position
	var offset:Vector2=(plant_offset if shifted else Vector2.ZERO)-_shift
	_shift_velocity=_shift_velocity.move_toward((offset*4).limit_length(120),420*delta)
	var step:=_shift_velocity*delta
	if step.length()>offset.length() and step.dot(offset)>0:step=offset;_shift_velocity=Vector2.ZERO
	_shift+=step
	position = _home + _shift + Vector2(sin(_clock*0.65+phase)*automatic_travel,0)
	var velocity_now:=(global_position-old)/delta
	_anchor_acceleration=((velocity_now-_anchor_velocity)/delta).limit_length(600)
	_anchor_velocity=velocity_now
	if not is_instance_valid(rider):
		rider = null
	var direction:=Input.get_axis("move_left","move_right") if rider!=null else 0.0
	_advance(delta,direction,rider!=null)
	_last_step=Engine.get_physics_frames()
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	var closest:=Geometry2D.get_closest_point_to_segment(player.global_position,previous_grip,get_grip()+HAND_OFFSET) if is_instance_valid(player) else Vector2.INF
	var near:bool=is_instance_valid(player) and not player.is_dead() and player.global_position.distance_to(closest)<=42
	_hint.visible = near and rider == null
	_hint.text=Controls.key_label("interagir",0)+" · agarrar"
	_hint.position = to_local(get_grip())+Vector2(-22,14)
	var held := Input.is_action_pressed("interagir")
	if not held:_needs_release=false
	if near and rider == null and held and not _needs_release:try_grab(player)
	_update_cherries()
	_art.queue_redraw()

func swing(delta: float, direction: float) -> void:
	# The vine advances before Nico, exactly once per physics tick. The shared
	# player API also calls swing() for the unrelated Underworld chains.
	if _last_step==Engine.get_physics_frames():return
	_advance(delta,direction,true);_last_step=Engine.get_physics_frames()

func _advance(delta:float,direction:float,occupied:bool) -> void:
	if delta<=0:return
	if not is_finite(angle) or not is_finite(angular_velocity):angle=-REST_AMPLITUDE;angular_velocity=0
	var rope:=maxf(32,length)
	var steps:=maxi(1,int(ceilf(minf(delta,.1)*120)))
	var dt:=minf(delta,.1)/steps
	for i in steps:
		var acceleration:float=-GRAVITY/rope*sin(angle)-angular_velocity*(.12 if occupied else .06)
		acceleration-=_anchor_acceleration.x/rope*cos(angle)+_anchor_acceleration.y/rope*sin(angle)
		if occupied:acceleration+=clampf(direction,-1,1)*2.9*cos(angle)
		else:
			var energy:=.5*angular_velocity*angular_velocity+GRAVITY/rope*(1-cos(angle))
			var target:=GRAVITY/rope*(1-cos(REST_AMPLITUDE))
			acceleration+=clampf((target-energy)*.8,-1,.9)*signf(angular_velocity)
		if absf(angle)>SOFT_LIMIT:
			acceleration-=signf(angle)*(absf(angle)-SOFT_LIMIT)*24
			if angle*angular_velocity>0:acceleration-=angular_velocity*4
		angular_velocity=clampf(angular_velocity+acceleration*dt,-MAX_ANGULAR_SPEED,MAX_ANGULAR_SPEED)
		angle+=angular_velocity*dt
		if absf(angle)>MAX_ANGLE:
			angle=signf(angle)*MAX_ANGLE
			if angle*angular_velocity>0:angular_velocity*=-.15

func try_grab(player:CharacterBody2D) -> bool:
	if _needs_release or is_instance_valid(rider) or not player.can_grab_vine():return false
	var target:=get_grip()+HAND_OFFSET
	var motion:=target-player.global_position
	if motion.length()>48 or player.test_move(player.global_transform,motion):return false
	var incoming:=player.velocity-_anchor_velocity
	if not player.grab_vine(self):return false
	player.move_and_collide(motion)
	rider=player
	var tangent:=Vector2(cos(angle),-sin(angle))
	angular_velocity=clampf(lerpf(angular_velocity,incoming.dot(tangent)/maxf(length,32),.30),-MAX_ANGULAR_SPEED,MAX_ANGULAR_SPEED)
	return true

func get_grip() -> Vector2:
	return global_position+Vector2(sin(angle),cos(angle))*length

func release_velocity() -> Vector2:
	var tangent:=Vector2(cos(angle),-sin(angle))*length*angular_velocity+_anchor_velocity
	return Vector2(clampf(tangent.x,-430,430),clampf(tangent.y,-310,430))

func jump_velocity(direction:float) -> Vector2:
	var result:=release_velocity()
	# Steering adds a small impulse; it cannot reverse momentum instantly.
	if absf(direction)>.01:result.x+=direction*(180 if absf(result.x)<120 else 60)
	result.x=clampf(result.x,-440,440)
	result.y=clampf(result.y-160,-300,-170)
	return result

func add_path_cherry(item: Node2D, at_angle: float) -> void:
	_cherries.append({"item":weakref(item),"angle":at_angle})
	_update_cherries()

func _update_cherries() -> void:
	for entry in _cherries:
		var item:Node2D=entry.item.get_ref()
		if is_instance_valid(item) and not item.collected:
			var a:float=entry.angle
			item.global_position=global_position+Vector2(sin(a),cos(a))*length+Vector2(0,6)

func detach() -> void:
	rider = null
	_needs_release=Input.is_action_pressed("interagir")

func toggle_plant() -> void:
	shifted = not shifted
	Fx.burst(global_position,Color("88ffe2"),8,70)

func _paint() -> void:
	var end := Vector2(sin(angle),cos(angle))*length
	_art.draw_texture_rect(ANCHOR,Rect2(-24,-19,48,30),false)
	var count:=int(ceil(length/30))
	var span:=length/count
	for i in count:
		var texture:Texture2D=SEGMENTS[i%4]
		var width:=texture.get_width()/float(texture.get_height())*(span+2)
		_art.draw_set_transform((end*float(i)/count).round(),-angle)
		_art.draw_texture_rect(texture,Rect2(-width/2,-1,width,span+2),false)
	_art.draw_set_transform(Vector2.ZERO)
	_art.draw_texture_rect(GRIP,Rect2(end.round()-Vector2(8,7),Vector2(16,16)),false)

extends Node2D
## Ator de encenação: a física e a posição verdadeira de Nico ficam intactas.
const DURATION:=8.4
const STREAMS=preload("res://world/Arte/Underworld/V40/elemental_streams.tres")
var player:CharacterBody2D
var altar:AnimatedSprite2D
var clock:=0.0
var stage:="calling"
var done:=false
var actor:Node2D
var anim:AnimatedSprite2D
var _home:=Vector2.ZERO
var _focus:=Vector2.ZERO
var _rear:Node2D
var _front:Node2D
var _heads:Array[AnimatedSprite2D]=[]
var _angles:Array[float]=[]
var _center:=Vector2.ZERO
var _radius:=0.0
var _orbit_height:=17.0
var _power:=0.0
var _was_visible:=true
var _restored:=false
var _absorbed:=false
var _lift_sound:=false

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	z_index=6
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_home=player.global_position
	_focus=Vector2(altar.global_position.x-_altar_offset().x,_home.y-64)
	_was_visible=player.visible
	player.hide()
	_rear=Node2D.new()
	_rear.draw.connect(_draw_streams.bind(_rear,false))
	add_child(_rear)
	actor=Node2D.new()
	actor.name="LevitatingNico"
	actor.z_index=1
	anim=AnimatedSprite2D.new()
	anim.name="anim"
	anim.sprite_frames=player.anim.sprite_frames
	anim.position=player.anim.position
	anim.centered=player.anim.centered
	anim.offset=player.anim.offset
	anim.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	actor.add_child(anim)
	add_child(actor)
	_front=Node2D.new()
	_front.z_index=2
	_front.draw.connect(_draw_streams.bind(_front,true))
	add_child(_front)
	for i in 4:
		var head:=AnimatedSprite2D.new()
		head.sprite_frames=STREAMS
		head.material=preload("res://world/Scripts/magic_art.gd").material()
		head.material.set_shader_parameter("alpha_cutoff",0.94)
		head.play(&"water" if i%2==1 else &"fire")
		var texture:Texture2D=STREAMS.get_frame_texture(head.animation,0)
		head.scale=Vector2(29,16)/texture.get_size()
		add_child(head)
		_heads.append(head)
		_angles.append(0.0)
	update_scene(0)

func _altar_offset() -> Vector2:return altar.get_meta("ground_art_offset",Vector2.ZERO)

func update_scene(time:float) -> void:
	if _restored:return
	clock=time
	stage="calling" if time<1.1 else ("rising" if time<2.4 else ("orbiting" if time<5.9 else ("absorbing" if time<6.9 else ("landing" if time<DURATION else "complete"))))
	var lift:=smoothstep(1.1,2.4,time)
	var landing:=smoothstep(6.9,8.25,time)
	var at:=_home.lerp(_focus,lift).lerp(_home,landing)
	if time>2.4 and time<6.9:at.y+=roundf(sin(time*3.2)*2)
	actor.global_position=at.round()
	anim.play(&"idle" if time<1.1 or time>8.15 else &"fall")
	_center=actor.global_position+Vector2(0,-12)
	var absorption:=smoothstep(5.9,6.8,time)
	_radius=lerpf(36,3,absorption)
	_orbit_height=lerpf(17,2,absorption)
	_power=smoothstep(1.1,2.3,time)*(1-smoothstep(6.65,6.95,time))
	var speed:=time*3.1+maxf(0,time-5.9)*3.5
	for i in 4:
		var angle:float=speed*(1 if i%2==0 else -1)+floorf(i*0.5)*PI+(0.7 if i%2==1 else 0)
		_angles[i]=angle
		var point:=_point(angle)
		_heads[i].global_position=point.round()
		_heads[i].rotation=Vector2(-sin(angle)*_radius,cos(angle)*_orbit_height).angle()+(PI if i%2==1 else 0)
		_heads[i].z_index=2 if sin(angle)>0 else 0
		_heads[i].modulate.a=_power
		_heads[i].visible=_power>0.01
	var pose:StringName=&"temple_dormant" if time<1.1 else (&"temple_fire" if time<1.75 else (&"temple_ice" if time<2.4 else (&"temple_both" if time<5.9 else (&"temple_shine" if time<6.9 else &"temple_ready"))))
	altar.play(pose)
	if time>=1.1 and not _lift_sound:_lift_sound=true;Sfx.select()
	if time>=6.45 and not _absorbed:_absorbed=true;Sfx.secret()
	_rear.queue_redraw()
	_front.queue_redraw()
	queue_redraw()
	if time>=DURATION:
		done=true
		restore()

func _point(angle:float) -> Vector2:
	return _center+Vector2(cos(angle)*_radius,sin(angle)*_orbit_height)

func _draw_streams(canvas:Node2D,front:bool) -> void:
	if _power<=0.01:return
	for i in 4:
		var water:=i%2==1
		var direction:float=-1 if water else 1
		var outer:=Color("17548f") if water else Color("a92e15")
		var middle:=Color("3fc6f2") if water else Color("ff922c")
		var core:=Color("d6f8ff") if water else Color("ffe595")
		for step in range(1,25):
			var angle_a:float=_angles[i]-direction*(1-float(step-1)/24)*1.6
			var angle_b:float=_angles[i]-direction*(1-float(step)/24)*1.6
			if (sin((angle_a+angle_b)*0.5)>=0)!=front:continue
			var a:=_point(angle_a).round()
			var b:=_point(angle_b).round()
			var fade:=_power*(0.25+float(step)/32)
			canvas.draw_line(a,b,Color(outer,fade),4)
			canvas.draw_line(a,b,Color(middle,fade),2.5)
			canvas.draw_line(a,b,Color(core,fade*0.8),1)
			if step%6==0:
				var drop:=b+Vector2(sin(clock*3+step)*4,cos(clock*4+step)*3)
				canvas.draw_rect(Rect2(drop.round(),Vector2(2,2)),Color(middle,fade))

func _draw() -> void:
	if not is_node_ready() or _restored:return
	var shadow:=Vector2(actor.global_position.x,_home.y+11)
	draw_set_transform(shadow,0,Vector2(1,0.2))
	draw_circle(Vector2.ZERO,13,Color(0.03,0.02,0.06,0.22))
	draw_set_transform(Vector2.ZERO)
	if clock>=6.3 and clock<7.05:
		var t:=clampf((clock-6.3)/0.75,0,1)
		for i in 16:
			var angle:float=i*TAU/16+clock*0.3
			var inner:=_center+Vector2.from_angle(angle)*(5+t*14)
			var outer:=_center+Vector2.from_angle(angle)*(10+t*29)
			var color:=Color("ffcf75") if i%2==0 else Color("96ecff")
			draw_line(inner.round(),outer.round(),Color(color,1-t),2)

func restore() -> void:
	if _restored:return
	_restored=true
	visible=false
	if is_instance_valid(player):player.visible=_was_visible

func _exit_tree() -> void:restore()

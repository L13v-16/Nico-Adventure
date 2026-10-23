extends Node2D
## Broad, contact-triggered elevators: wait for boarding, hold while occupied.
var rise:=180.0
var width:=136.0
var speed:=66.0
var circuit:=""
var enabled:=true
var state:="waiting"
var timer:=0.0
var _body:AnimatableBody2D
var _art:Sprite2D
var _player:CharacterBody2D
var _state_index:=-1
func _ready() -> void:
	add_to_group("lab_lifts");process_physics_priority=-50
	_player=get_tree().get_first_node_in_group("player")
	_body=AnimatableBody2D.new();_body.sync_to_physics=false;_body.collision_layer=1;_body.collision_mask=0;add_child(_body)
	var shape:=RectangleShape2D.new();shape.size=Vector2(width,8)
	var collider:=CollisionShape2D.new();collider.shape=shape;collider.position.y=4;collider.one_way_collision=true;collider.one_way_collision_margin=12;_body.add_child(collider)
	_art=Sprite2D.new();_art.centered=false;_art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;_body.add_child(_art)
	_art.material=preload("res://world/Scripts/magic_art.gd").material();_art.material.set_shader_parameter("alpha_cutoff",.94)
	_body.sync_to_physics=true;_update_art()
func occupied() -> bool:
	return not _player.is_dead() and absf(_player.global_position.x-global_position.x)<width*.48 and absf(_player.global_position.y+11-_body.global_position.y)<14 and _player.velocity.y>=-30
func enable() -> void:enabled=true;_state_index=-1;_update_art()
func _physics_process(delta:float) -> void:
	var on:=occupied()
	match state:
		"waiting":
			if enabled and on:state="boarding";timer=.65
		"boarding":
			if not on:state="waiting"
			else:
				timer-=delta
				if timer<=0:state="rising";Sfx.play("lab_door",-18)
		"rising":
			_body.position.y=move_toward(_body.position.y,-rise,speed*delta)
			if _body.position.y<=-rise:state="arrived";timer=1.4;Sfx.play("lab_clink",-17)
		"arrived":
			if on:timer=1.4
			else:
				timer-=delta
				if timer<=0:state="returning"
		"returning":
			_body.position.y=move_toward(_body.position.y,0,speed*1.35*delta)
			if _body.position.y>=0:state="waiting"
	_update_art();queue_redraw()
func _update_art() -> void:
	var index:=0 if not enabled or state in ["waiting","returning"] else (1 if state=="boarding" else (2 if state=="rising" else 3))
	if index==_state_index:return
	_state_index=index;_art.texture=load("res://world/Arte/Lab/V72/lift_%02d.tres"%index)
	var ratio:=width/float(_art.texture.get_meta("visible_width",300));_art.scale=Vector2.ONE*ratio
	_art.position=Vector2(-_art.texture.get_width()*.5*ratio,-float(_art.texture.get_meta("surface_y",300))*ratio)
	_art.modulate=Color.WHITE if enabled else Color("65788a")
func _draw() -> void:
	# Recessed vertical guides explain how the platform is supported.
	for x in [-width*.38,width*.38]:
		draw_line(Vector2(x,12),Vector2(x,-rise-24),Color("16232f"),7)
		draw_line(Vector2(x-1,12),Vector2(x-1,-rise-24),Color("5d7482"),2)
		for y in range(-int(rise),1,28):draw_rect(Rect2(x-3,y,6,3),Color("839294"))

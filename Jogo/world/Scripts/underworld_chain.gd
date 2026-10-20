extends Node2D
@export var length:=260.0
var max_length:=260.0
var angle:=0.0
var rider:CharacterBody2D
var _held:=false
func _ready() -> void:
	max_length=length
	process_physics_priority=-10
	add_to_group("underworld_chains")
func _physics_process(delta:float) -> void:
	var player:=get_tree().get_first_node_in_group("player") as CharacterBody2D
	var held:=Input.is_action_pressed("interagir")
	if player!=null and not is_instance_valid(rider) and held and not _held and player.global_position.distance_to(get_grip()+Vector2(0,10))<50:
		if player.grab_vine(self):rider=player
	_held=held
	if not is_instance_valid(rider):
		length=move_toward(length,max_length,75*delta)
		angle=move_toward(angle,0,delta)
	queue_redraw()
func swing(delta:float,direction:float) -> void:
	length=clampf(length+Input.get_axis("ui_up","ui_down")*125*delta,42,max_length)
	angle=clampf(angle+direction*delta*0.8,-0.32,0.32)
func get_grip() -> Vector2:return global_position+Vector2(sin(angle),cos(angle))*length
func release_velocity() -> Vector2:return Vector2(0,0)
func detach() -> void:rider=null
func _draw() -> void:
	var end:=to_local(get_grip())
	var count:=int(length/8)
	for i in count+1:
		var at:Vector2=(end*float(i)/maxi(count,1)).round()
		draw_rect(Rect2(at-Vector2(3,3),Vector2(6,8)),Color("171926"))
		draw_rect(Rect2(at-Vector2(2,2),Vector2(4,6)),Color("9c8ca0"),false,1)
	draw_circle(end,5,Color("efbc75"),false,2)

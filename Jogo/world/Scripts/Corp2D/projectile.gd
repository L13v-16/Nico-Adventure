extends Node2D
var flight:=Vector2.LEFT*180
var life:=4.0
var wave:=false
var harmless:=false
var electrical:=true
var style:="energy"
func _physics_process(delta:float) -> void:
	life-=delta
	if life<=0:queue_free();return
	var next:=position+flight*delta
	var hit:=get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(position,next,1|2))
	if not hit.is_empty():
		if hit.collider.is_in_group("player") and not harmless:
			if electrical:get_parent().electric_hit(position)
			else:hit.collider.take_damage(1,position)
		queue_free();return
	position=next;queue_redraw()
func _draw() -> void:
	if style=="pen":
		draw_set_transform(Vector2.ZERO,flight.angle())
		draw_texture_rect_region(preload("res://world/Arte/CorpV86/wolf_combat.png"),Rect2(-12,-4,24,8),Rect2(742,691,96,39))
		return
	var color:=Color("ff775f")
	if wave:
		draw_arc(Vector2(0,4),13,PI,TAU,8,color,3);draw_line(Vector2(-9,3),Vector2(9,3),Color("ffe9b3"),2)
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(-8,0),Vector2(0,-3),Vector2(8,0),Vector2(0,3)]),color)
		draw_line(Vector2(-2,0),Vector2(4,0),Color("fff2c5"),2)

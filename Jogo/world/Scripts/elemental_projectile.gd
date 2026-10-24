extends Node2D
@export var element:="fire"
var flight:=Vector2.RIGHT*420
var life:=1.7
var source:Node2D
var freeze_duration:=3.0
var _trail:Array[Vector2]=[]
var _hit_shape:CircleShape2D
func _ready() -> void:
	add_to_group("elemental_projectiles")
	z_index=6
	_hit_shape=CircleShape2D.new()
	_hit_shape.radius=7
func _physics_process(delta:float) -> void:
	life-=delta
	if life<=0:queue_free();return
	var next:=global_position+flight*delta
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=_hit_shape
	query.transform=Transform2D(0,global_position)
	query.collision_mask=1|4|16
	if is_instance_valid(source) and source is CollisionObject2D:query.exclude=[source.get_rid()]
	var space:=get_world_2d().direct_space_state
	# O volume acompanha a arte e acerta caranguejos baixos. A varredura
	# respeita paredes e também encontra runas que contêm o ponto de saída.
	var hits:=space.intersect_shape(query,1)
	var impact:=global_position
	if hits.is_empty():
		query.motion=next-global_position
		var travel:=space.cast_motion(query)
		if travel[0]<1:
			impact=global_position.lerp(next,minf(1,travel[1]+.01))
			query.transform.origin=impact;query.motion=Vector2.ZERO
			hits=space.intersect_shape(query,1)
	if not hits.is_empty():
		var target:Node=hits[0].collider
		if target.has_method("take_element"):
			target.take_element(element,global_position)
			if element=="ice" and target.has_method("freeze_for"):target.freeze_for(freeze_duration)
		elif target.is_in_group("enemies") and target.has_method("take_damage"):
			if element=="ice" and target.has_method("freeze_for"):target.freeze_for(freeze_duration)
			else:target.take_damage(1.0,global_position)
		Fx.burst(impact,Color("ffba63") if element=="fire" else Color("9eeaff"),7,95)
		queue_free()
		return
	_trail.append(global_position)
	if _trail.size()>5:_trail.pop_front()
	global_position=next
	queue_redraw()
func _draw() -> void:
	var color:=Color("ff9e43") if element=="fire" else Color("8ddcf2")
	for i in _trail.size():
		var at:=to_local(_trail[i]).round()
		draw_rect(Rect2(at-Vector2(2,2),Vector2(4,4)),Color(color,0.15+i*0.13))
	draw_colored_polygon(PackedVector2Array([Vector2(-7,0),Vector2(-2,-5),Vector2(5,-3),Vector2(8,0),Vector2(3,5),Vector2(-3,4)]),color)
	draw_rect(Rect2(-2,-2,5,4),Color("fff0b3") if element=="fire" else Color("e9fdff"))

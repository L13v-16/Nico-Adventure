extends StaticBody2D
var flight:=Vector2.LEFT*105
var life:=3.2
var frozen:=0.0
var _clock:=0.0
func _ready() -> void:
	add_to_group("enemies");texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;collision_layer=4;collision_mask=0
	var col:=CollisionShape2D.new();var shape:=CircleShape2D.new();shape.radius=5;col.shape=shape;add_child(col)
func _physics_process(delta:float) -> void:
	_clock+=delta;life-=delta
	if life<=0:queue_free();return
	if frozen>0:frozen-=delta;queue_redraw();return
	var next:=position+flight*delta
	var hit:=get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(position,next,1|2))
	if not hit.is_empty():
		if hit.collider.is_in_group("player"):hit.collider.take_damage(1,position)
		take_damage(1,position);return
	position=next;queue_redraw()
func take_damage(_amount:float,_source:Vector2) -> void:Fx.burst(position,Color("e5a9ef"),6,65);queue_free()
func take_element(element:String,source:Vector2) -> void:
	if element=="ice":frozen=2.5
	else:take_damage(1,source)
func freeze_for(seconds:float) -> void:frozen=maxf(frozen,seconds)
func is_dead() -> bool:return is_queued_for_deletion()
func _draw() -> void:
	var color:=Color("a3edff") if frozen>0 else Color("e49bf2")
	draw_rect(Rect2(-4,-3,8,6),Color("572b75"));draw_rect(Rect2(-3,-4,6,8),color);draw_rect(Rect2(-2,-2,3,3),Color("fff0ff"))
	for i in 3:draw_rect(Rect2(-flight.normalized()*float(i*5+7)+Vector2(0,sin(_clock*8+i)*2),Vector2(2,2)),Color(color,.4))

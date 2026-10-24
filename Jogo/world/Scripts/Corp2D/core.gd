extends StaticBody2D
var boss:Node2D
func _ready() -> void:
	add_to_group("enemies");collision_layer=4;collision_mask=0;z_index=3
	var collider:=CollisionShape2D.new();var shape:=RectangleShape2D.new();shape.size=Vector2(36,34);collider.shape=shape;add_child(collider)
func take_damage(amount:float,source:Vector2) -> void:boss.hit_core(amount,source)
func take_element(_element:String,source:Vector2) -> void:boss.hit_core(1,source)
func is_dead() -> bool:return boss.dead
func _draw() -> void:
	if boss.vulnerable>0:
		draw_arc(Vector2.ZERO,22,0,TAU,16,Color("ffe49f"),2)
		draw_circle(Vector2.ZERO,5,Color("fff8ce"))

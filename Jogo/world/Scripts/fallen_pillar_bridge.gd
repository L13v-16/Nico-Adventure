extends StaticBody2D
## A própria coluna quebrada vira um caminho de pedra, com topo plano.
var width:=154.0
func _ready() -> void:
	add_to_group("fallen_pillar_bridges")
	collision_layer=1
	collision_mask=0
	var shape:=RectangleShape2D.new()
	shape.size=Vector2(width,12)
	var collider:=CollisionShape2D.new()
	collider.shape=shape
	collider.position=Vector2(width/2,6)
	add_child(collider)
func _draw() -> void:
	draw_texture_rect(preload("res://world/Arte/Underworld/V45/pillar_03.tres"),Rect2(0,0,width,29),false)

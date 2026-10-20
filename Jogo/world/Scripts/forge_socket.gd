extends StaticBody2D
var element:="fire"
var forge:Node2D
func _ready() -> void:
	var shape:=RectangleShape2D.new()
	shape.size=Vector2(32,34)
	var collider:=CollisionShape2D.new()
	collider.shape=shape
	add_child(collider)
func take_element(value:String,_source:Vector2) -> void:
	if value==element:forge.activate(value)
	else:forge.activate("wrong")
	queue_redraw()
func _draw() -> void:
	var color:=Color("ff9d50") if element=="fire" else Color("9ce7fa")
	draw_rect(Rect2(-16,9,32,12),Color("514250"))
	draw_rect(Rect2(-13,-15,26,26),Color("171923"))
	draw_rect(Rect2(-13,-15,26,26),Color("a77c56"),false,2)
	if element=="fire":draw_colored_polygon(PackedVector2Array([Vector2(-6,5),Vector2(-3,-4),Vector2(0,-10),Vector2(5,-2),Vector2(6,5)]),color)
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(0,-10),Vector2(6,-2),Vector2(0,6),Vector2(-6,-2)]),color)

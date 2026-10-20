extends Node2D
var speed:=190.0
var life:=3.6
func _ready() -> void:add_to_group("underworld_projectiles")
func _physics_process(delta:float) -> void:
	life-=delta
	position.x+=speed*delta
	if life<=0:queue_free();return
	var player:=get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player!=null and absf(player.position.x-position.x)<18 and player.position.y+11>position.y-18 and player.position.y<position.y+10:player.take_damage(1,position)
	queue_redraw()
func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-14,0),Vector2(-8,-7),Vector2(-5,-15),Vector2(1,-8),Vector2(7,-18),Vector2(10,-5),Vector2(17,0)]),Color("f19a58"))
	draw_line(Vector2(-12,-1),Vector2(14,-1),Color("ffe9a1"),2)

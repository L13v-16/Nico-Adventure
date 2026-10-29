extends Node2D
var speed := 170.0
var life := 3.2
var owner_boss: Node2D
func _ready() -> void:
	add_to_group("hyena_projectiles");z_index=4
func _physics_process(delta: float) -> void:
	if not is_instance_valid(owner_boss) or not owner_boss.active:queue_free();return
	position.x+=speed*delta;life-=delta
	if life<=0 or position.x<5200 or position.x>5830:queue_free();return
	var player:CharacterBody2D=owner_boss._player
	if absf(player.position.x-position.x)<17 and player.position.y+11>position.y-16:
		player.take_damage(1,position);queue_free()
	queue_redraw()
func _draw() -> void:
	for i in 3:
		var height:float=7+(i%2)*6
		draw_rect(Rect2(i*8-12,-height,6,height),Color("d7a7ec"))
		draw_rect(Rect2(i*8-12,-height,4,3),Color("fff0c5"))

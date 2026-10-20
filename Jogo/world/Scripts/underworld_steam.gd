extends Node2D
@export var phase:=0.0
var cycle:=0.0
func _physics_process(delta:float) -> void:
	cycle=fposmod(cycle+delta,4.1)
	if cycle>2.9 and cycle<3.65:
		var player:=get_tree().get_first_node_in_group("player") as CharacterBody2D
		if player!=null and absf(player.position.x-position.x)<17 and player.position.y>position.y-95 and player.position.y<position.y+5:player.take_damage(1,position)
	queue_redraw()
func _ready() -> void:cycle=phase
func _draw() -> void:
	draw_rect(Rect2(-14,-2,28,6),Color("6c5868"))
	draw_rect(Rect2(-10,-1,20,2),Color("eac38e") if cycle>1.9 else Color("292433"))
	if cycle>1.9:
		var height:=90 if cycle>2.9 and cycle<3.65 else 12
		for i in 14:
			var t:=fposmod(cycle*2+i*0.07,1)
			var at:=Vector2(roundf(sin(i*1.3+cycle*2)*13),roundf(-t*height))
			draw_rect(Rect2(at,Vector2(6,4)),Color(0.85,0.78,0.84,0.65*(1-t)))

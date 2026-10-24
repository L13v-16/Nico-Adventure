extends "res://world/Scripts/moving_platform.gd"

func _draw() -> void:
	# Flutuadores e amarras ficam sob o piso, cujo topo é a colisão.
	for x in [-24.0, 15.0]:
		draw_rect(Rect2(x - 2.0, 11.0, 13.0, 9.0), Color("193f49"))
		draw_rect(Rect2(x, 12.0, 9.0, 5.0), Color("52a59b"))
		draw_rect(Rect2(x + 2.0, 11.0, 2.0, 10.0), Color("e1c08a"))

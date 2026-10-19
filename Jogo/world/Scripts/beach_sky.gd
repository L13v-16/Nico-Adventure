extends Control

const BACKDROP := preload("res://world/Arte/Beach/beach_background.png")
var _player: Node2D
var _time := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player = get_tree().get_first_node_in_group("player") as Node2D

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var scroll := 0.0 if not is_instance_valid(_player) else _player.global_position.x * 0.07
	draw_texture_rect(BACKDROP, Rect2(-scroll, 0, 1280, 360), false)
	# Pássaros distantes acompanham o vento, com poucos pixels por silhueta.
	for i in range(4):
		var p := Vector2(fposmod(80.0 + i * 174.0 + _time * 3.0 - scroll * 0.25, 700.0) - 30.0, 65.0 + sin(i * 2.3) * 18.0)
		var wing := 2.0 if sin(_time * 3.5 + i) > 0.0 else -1.0
		draw_line(p + Vector2(-4, wing), p, Color("3b718e"), 1)
		draw_line(p, p + Vector2(4, wing), Color("3b718e"), 1)

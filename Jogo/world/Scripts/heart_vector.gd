extends Control

@export var filled: bool = true:
	set(value):
		filled = value
		queue_redraw()


func _draw() -> void:
	var origin: Vector2 = Vector2(floorf((size.x - 24.0) * 0.5), floorf((size.y - 24.0) * 0.5))
	var outline: PackedVector2Array = PackedVector2Array([
		Vector2(1, 5), Vector2(4, 5), Vector2(4, 2), Vector2(10, 2),
		Vector2(10, 5), Vector2(13, 5), Vector2(13, 2), Vector2(19, 2),
		Vector2(19, 5), Vector2(22, 5), Vector2(22, 12), Vector2(19, 12),
		Vector2(19, 15), Vector2(16, 15), Vector2(16, 18), Vector2(13, 18),
		Vector2(13, 21), Vector2(10, 21), Vector2(10, 18), Vector2(7, 18),
		Vector2(7, 15), Vector2(4, 15), Vector2(4, 12), Vector2(1, 12)
	])
	var shadow: PackedVector2Array = PackedVector2Array()
	for index: int in range(outline.size()):
		outline[index] += origin
		shadow.append(outline[index] + Vector2(0, 2))
	draw_colored_polygon(shadow, Color(0.025, 0.035, 0.07, 0.85))
	draw_colored_polygon(outline, Color(1.0, 0.28, 0.36) if filled else Color(0.20, 0.19, 0.27))
	outline.append(outline[0])
	draw_polyline(outline, Color(1.0, 0.76, 0.68) if filled else Color(0.42, 0.39, 0.49), 1.0, false)
	if filled:
		draw_rect(Rect2(origin + Vector2(5, 5), Vector2(4, 3)), Color(1.0, 0.77, 0.67))

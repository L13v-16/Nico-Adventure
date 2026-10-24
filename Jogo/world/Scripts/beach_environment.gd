extends Node2D
## Mar e acabamento dos barrancos. A geometria editável permanece no TileMap.

var _time := 0.0
var _clock := 0.0
@onready var _terrain: TileMapLayer = get_parent().get_node("Level")

func _process(delta: float) -> void:
	_time += delta
	_clock += delta
	if _clock >= 0.05:
		_clock = 0.0
		queue_redraw()

func _draw() -> void:
	var camera := get_viewport().get_camera_2d()
	var start := -200.0
	var end := 5400.0
	if camera != null:
		start = floor((camera.get_screen_center_position().x - 500.0) / 16.0) * 16.0
		end = start + 1000.0
	draw_rect(Rect2(start, 112.0, end - start, 400.0), Color("258f9d"))
	draw_rect(Rect2(start, 121.0, end - start, 391.0), Color("227f92"))
	for x in range(int(start), int(end), 8):
		var wave := floorf(sin(float(x) * 0.052 + _time * 1.7) * 2.0)
		draw_rect(Rect2(x, 112.0 + wave, 8.0, 2.0), Color("bbf1da"))
		draw_rect(Rect2(x + 2, 116.0 + wave, 6.0, 1.0), Color("69c8bf"))
	for i in range(24):
		var x := start + fposmod(float(i) * 67.0 + _time * 9.0, end - start)
		var y := 127.0 + fposmod(float(i) * 27.0, 110.0)
		var bright := 0.25 + 0.15 * sin(_time * 2.0 + i)
		draw_rect(Rect2(Vector2(x, y).round(), Vector2(9.0, 1.0)), Color(0.65, 0.94, 0.89, bright))
	if _terrain == null:
		return
	# Sombra só nas faces expostas; não há linhas entre tiles vizinhos.
	for cell in _terrain.get_used_cells():
		var pos := Vector2(cell * 16)
		if pos.x < start or pos.x > end:
			continue
		var atlas := _terrain.get_cell_atlas_coords(cell)
		if atlas.y == 3:
			# Estacas apoiam os cais fixos acima da água.
			if cell.x % 3 == 0:
				draw_rect(Rect2(pos + Vector2(6, 12), Vector2(4, maxf(124.0 - pos.y, 16.0))), Color("5d4946"))
			continue
		if _terrain.get_cell_source_id(cell + Vector2i.LEFT) == -1:
			draw_rect(Rect2(pos + Vector2(0, 4 if atlas.y == 0 else 0), Vector2(2, 12 if atlas.y == 0 else 16)), Color(0.30, 0.26, 0.22, 0.35))
		if _terrain.get_cell_source_id(cell + Vector2i.RIGHT) == -1:
			draw_rect(Rect2(pos + Vector2(14, 4 if atlas.y == 0 else 0), Vector2(2, 12 if atlas.y == 0 else 16)), Color(0.27, 0.22, 0.23, 0.48))

extends Node2D
## Conecta somente as bordas visíveis do atlas forest_terrain_v2 (source 1).
## A composição é visual: as posições, polígonos e apoios continuam na cena.

const TERRAIN_SOURCE := 1
const EDGE_SIZE := 2.0
const EARTH_LEFT := Color(0.26, 0.18, 0.13, 0.32)
const EARTH_RIGHT := Color(0.14, 0.10, 0.09, 0.44)
const EARTH_BASE := Color(0.12, 0.09, 0.08, 0.38)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()


func _draw() -> void:
	var layer := get_parent() as TileMapLayer
	if layer == null or layer.tile_set == null or not layer.tile_set.has_source(TERRAIN_SOURCE):
		return
	var atlas_source := layer.tile_set.get_source(TERRAIN_SOURCE) as TileSetAtlasSource
	if atlas_source == null or atlas_source.texture == null:
		return
	var texture: Texture2D = atlas_source.texture
	var size: Vector2 = Vector2(layer.tile_set.tile_size)
	# Inclui as quinas e os apoios originais: eles também fecham uma vizinhança.
	var occupied: Dictionary = {}
	for cell: Vector2i in layer.get_used_cells():
		occupied[cell] = true
	for cell: Vector2i in layer.get_used_cells_by_id(TERRAIN_SOURCE):
		var tile: TileData = layer.get_cell_tile_data(cell)
		if tile != null and tile.get_collision_polygons_count(0) > 0 and tile.is_collision_polygon_one_way(0, 0):
			# The floating end caps draw their own silhouette and rim.
			continue
		var atlas: Vector2i = layer.get_cell_atlas_coords(cell)
		var top_left: Vector2 = layer.map_to_local(cell) - size * 0.5
		if atlas.y >= 2:
			_draw_rock_edges(atlas_source, texture, occupied, cell, top_left, size)
		else:
			_draw_earth_edges(occupied, cell, atlas.y == 0, top_left, size)


func _draw_rock_edges(atlas_source: TileSetAtlasSource, texture: Texture2D,
		occupied: Dictionary, cell: Vector2i, top_left: Vector2, size: Vector2) -> void:
	# A última linha contém topo, base, esquerda e direita. Recortar só a
	# faixa externa permite combinar duas ou mais faces no mesmo bloco.
	if not occupied.has(cell + Vector2i.UP):
		var source: Rect2i = atlas_source.get_tile_texture_region(Vector2i(0, 3))
		var sample := Rect2(Vector2(source.position), Vector2(size.x, EDGE_SIZE))
		draw_texture_rect_region(texture, Rect2(top_left, Vector2(size.x, EDGE_SIZE)), sample)
	if not occupied.has(cell + Vector2i.DOWN):
		var source: Rect2i = atlas_source.get_tile_texture_region(Vector2i(1, 3))
		var offset := Vector2(0.0, size.y - EDGE_SIZE)
		var sample := Rect2(Vector2(source.position) + offset, Vector2(size.x, EDGE_SIZE))
		draw_texture_rect_region(texture, Rect2(top_left + offset, Vector2(size.x, EDGE_SIZE)), sample)
	if not occupied.has(cell + Vector2i.LEFT):
		var source: Rect2i = atlas_source.get_tile_texture_region(Vector2i(2, 3))
		var sample := Rect2(Vector2(source.position), Vector2(EDGE_SIZE, size.y))
		draw_texture_rect_region(texture, Rect2(top_left, Vector2(EDGE_SIZE, size.y)), sample)
	if not occupied.has(cell + Vector2i.RIGHT):
		var source: Rect2i = atlas_source.get_tile_texture_region(Vector2i(3, 3))
		var offset := Vector2(size.x - EDGE_SIZE, 0.0)
		var sample := Rect2(Vector2(source.position) + offset, Vector2(EDGE_SIZE, size.y))
		draw_texture_rect_region(texture, Rect2(top_left + offset, Vector2(EDGE_SIZE, size.y)), sample)


func _draw_earth_edges(occupied: Dictionary, cell: Vector2i, grass: bool,
		top_left: Vector2, size: Vector2) -> void:
	# O capim já possui luz e raízes. Nas laterais a sombra começa sob a copa,
	# enquanto no miolo nenhum contorno é desenhado entre células vizinhas.
	var start_y := 4.0 if grass else 0.0
	if not occupied.has(cell + Vector2i.LEFT):
		draw_rect(Rect2(top_left + Vector2(0.0, start_y), Vector2(1.0, size.y - start_y)), EARTH_LEFT)
	if not occupied.has(cell + Vector2i.RIGHT):
		draw_rect(Rect2(top_left + Vector2(size.x - 1.0, start_y), Vector2(1.0, size.y - start_y)), EARTH_RIGHT)
	if not occupied.has(cell + Vector2i.DOWN):
		draw_rect(Rect2(top_left + Vector2(0.0, size.y - 1.0), Vector2(size.x, 1.0)), EARTH_BASE)

extends Node2D
## Acabamento visual da floresta. Não cria corpos, áreas ou objetos coletáveis.
## A animação acompanha a pausa da fase e usa poucos pixels sem textura extra.

const LEAF_ZONES: Array[Rect2] = [
	Rect2(-160, -118, 560, 158),
	Rect2(560, -118, 500, 158),
	Rect2(2496, -118, 448, 158),
	Rect2(3024, -166, 480, 142),
	Rect2(4176, -166, 500, 158),
	Rect2(4832, -182, 528, 168),
]
const LEAF_COLORS: Array[Color] = [
	Color(0.58, 0.70, 0.38, 0.50),
	Color(0.75, 0.66, 0.36, 0.44),
	Color(0.39, 0.57, 0.38, 0.54),
]
const WINDOW_CENTERS: Array[Vector2] = [
	Vector2(5131, -80), Vector2(5177, -80),
]

var _leaves: Array[Dictionary] = []
var _dust: Array[Dictionary] = []
var _plants: Array[Dictionary] = []
var _time := 0.0
var _redraw_clock := 0.0
var _terrain: TileMapLayer


func _ready() -> void:
	_terrain = get_parent().get_node_or_null("Level") as TileMapLayer
	var rng := RandomNumberGenerator.new()
	rng.seed = 626103
	for zone in LEAF_ZONES:
		# Aproximadamente duas folhas em cada tela; o cenário continua legível.
		for index in range(6):
			_leaves.append({
				"zone": zone,
				"offset": Vector2(rng.randf(), rng.randf()),
				"speed": rng.randf_range(6.0, 10.0),
				"phase": rng.randf_range(0.0, TAU),
				"color": LEAF_COLORS[index % LEAF_COLORS.size()],
			})
	for index in range(46):
		_dust.append({
			"offset": Vector2(rng.randf_range(1256.0, 2392.0), rng.randf_range(34.0, 143.0)),
			"phase": rng.randf_range(0.0, TAU),
			"alpha": rng.randf_range(0.12, 0.26),
		})
	var details: Node = get_parent().get_node_or_null("EnvironmentDetails")
	if details != null:
		for child in details.get_children():
			if child is Sprite2D and (String(child.name).begins_with("Fern") or String(child.name).begins_with("HangingRoots")):
				_plants.append({
					"node": child,
					"rotation": child.rotation,
					"phase": rng.randf_range(0.0, TAU),
					"strength": 0.018 if String(child.name).begins_with("Fern") else 0.012,
				})
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	_redraw_clock += delta
	# 24 atualizações/s evitam custo desnecessário em efeitos quase imóveis.
	if _redraw_clock < 1.0 / 24.0:
		return
	_redraw_clock = 0.0
	for plant in _plants:
		var sprite: Sprite2D = plant["node"] as Sprite2D
		if is_instance_valid(sprite):
			# Os sprites dessas plantas têm origem na base: ela permanece no chão.
			sprite.rotation = float(plant["rotation"]) + sin(_time * 1.15 + float(plant["phase"])) * float(plant["strength"])
	queue_redraw()


func _draw() -> void:
	for leaf in _leaves:
		var zone: Rect2 = leaf["zone"]
		var offset: Vector2 = leaf["offset"]
		var phase: float = float(leaf["phase"])
		var travel: float = _time * float(leaf["speed"])
		var point := zone.position + Vector2(
			fposmod(offset.x * zone.size.x + travel * 0.38 + sin(_time * 0.8 + phase) * 9.0, zone.size.x),
			fposmod(offset.y * zone.size.y + travel, zone.size.y)
		)
		if not _is_air(point):
			continue
		var color: Color = leaf["color"]
		var width := 2.0 if sin(_time * 1.8 + phase) > 0.0 else 1.0
		draw_rect(Rect2(point.round(), Vector2(width, 1.0)), color)
	for mote in _dust:
		var point: Vector2 = mote["offset"]
		var phase: float = float(mote["phase"])
		point += Vector2(sin(_time * 0.24 + phase) * 4.0, sin(_time * 0.18 + phase) * 2.5)
		if not _is_air(point):
			continue
		var alpha: float = float(mote["alpha"]) * (0.7 + 0.3 * sin(_time * 0.7 + phase))
		draw_rect(Rect2(point.round(), Vector2.ONE), Color(0.65, 0.73, 0.76, alpha))
	_draw_arrival_light()


func _is_air(point: Vector2) -> bool:
	if _terrain == null:
		return true
	var cell: Vector2i = _terrain.local_to_map(_terrain.to_local(to_global(point)))
	return _terrain.get_cell_source_id(cell) < 0


func _draw_arrival_light() -> void:
	# As janelas destacam a casa sem encobrir a porta nem a varanda da cutscene.
	for center in WINDOW_CENTERS:
		for ring in range(4, 0, -1):
			var extent := Vector2(4.0 + float(ring) * 2.0, 4.0 + float(ring) * 2.0)
			draw_rect(Rect2(center - extent, extent * 2.0), Color(0.97, 0.67, 0.28, 0.018))
		draw_rect(Rect2(center - Vector2(3, 3), Vector2(6, 6)), Color(1.0, 0.73, 0.35, 0.12))

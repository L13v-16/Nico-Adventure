extends CanvasLayer
## Encontro na casa da árvore e partida para o arquipélago.
## O dono da fase controla pausa, HUD e resultados; esta cena só emite finished.

signal finished

const UiStyle := preload("res://world/Scripts/ui_style.gd")
const ACTOR_SHADER := preload("res://world/Scripts/characters_cutout.gdshader")
const FRAME_SIZE := Vector2(640.0, 360.0)
const BEAT_DURATIONS: Array[float] = [6.0, 7.0, 8.0, 6.0, 4.5]
const SPEAKERS: Array[String] = ["Nico", "Arara Minas", "Arara Minas", "Nico", "Nico e Arara Minas"]
const LINES: Array[String] = [
	"Arara Minas! Você também conseguiu escapar!",
	"Consegui escapar, Nico. Vi levarem a tartaruga para a Costa das Marés. Precisamos ir até lá!",
	"A tartaruga é nosso próximo resgate! Depois, seguimos por Remi, José, Urso e o mico-leão-dourado.",
	"Então vamos à Costa das Marés salvar a tartaruga! Vamos trazer todos de volta para casa.",
	"Próxima parada: Costa das Marés. A tartaruga precisa de nós!",
]
const FRIEND_NAMES: Array[String] = ["Tartaruga", "Remi", "José", "Urso", "Mico-leão-dourado"]
const FRIEND_FILES: Array[String] = ["remi", "jose", "urso", "mico_leao_dourado"]
const MAP_POINTS: Array[Vector2] = [Vector2(89, 113), Vector2(205, 95), Vector2(321, 116), Vector2(437, 92), Vector2(553, 110)]

@export var auto_progress := true

var beat_index := 0
var has_finished := false

var _started := false
var _elapsed := 0.0
var _total_elapsed := 0.0
var _last_advance_msec := -1000
var _canvas: Control
var _actors: Control
var _dialogue: Panel
var _speaker: Label
var _line: Label
var _hint: Label
var _location: Label
var _title: Label
var _subtitle: Label
var _next_rescue_hint: Label
var _friend_labels: Array[Label] = []
var _textures: Dictionary = {}
var _nico_frames: Array[Texture2D] = []
var _nico_run_frames: Array[Texture2D] = []
var _arara_idle: Array[Texture2D] = []
var _arara_fly: Array[Texture2D] = []
var _friend_textures: Array[Texture2D] = []
var _friend_second_textures: Array[Texture2D] = []
var _card_style: StyleBoxFlat
var _next_card_style: StyleBoxFlat


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 80
	start()


func start() -> void:
	if _started or has_finished:
		return
	_started = true
	Sfx.begin_dialogue_music(self)
	_load_art()
	_build()
	_show_beat(0)


func _load_art() -> void:
	# Carregamento em tempo de execução permite importar as artes separadamente.
	_textures["casa_arvore"] = _texture("res://world/Arte/Props/casa_arvore_v13.png")
	_textures["arvore"] = _texture("res://world/Arte/Props/arvore.png")
	for frame: int in range(1, 5):
		_nico_frames.append(_texture("res://world/Arte/Nico/idle_%d.png" % frame))
		_arara_fly.append(_texture("res://world/Arte/Amigos/arara_fly_%d.png" % frame))
	for frame: int in range(1, 7):
		_nico_run_frames.append(_texture("res://world/Arte/Nico/run_%d.png" % frame))
	for frame: int in range(1, 3):
		_arara_idle.append(_texture("res://world/Arte/Amigos/arara_idle_%d.png" % frame))
	# A primeira parada usa a mesma tartaruga idosa que será resgatada na praia.
	_friend_textures.append(_texture("res://world/Arte/Tartaruga/turtle_idle_1.png"))
	_friend_second_textures.append(_texture("res://world/Arte/Tartaruga/turtle_idle_2.png"))
	for file: String in FRIEND_FILES:
		_friend_textures.append(_texture("res://world/Arte/Amigos/%s.png" % file))
		_friend_second_textures.append(_texture("res://world/Arte/Amigos/%s_2.png" % file))


func _texture(path: String) -> Texture2D:
	if path.ends_with("/Amigos/remi.png"): path = "res://world/Arte/Magic/remi_idle.tres"
	if path.ends_with("/Amigos/remi_2.png"): path = "res://world/Arte/Magic/remi_blink.tres"
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


func _build() -> void:
	_canvas = Control.new()
	_canvas.name = "IslandFinaleCanvas"
	_canvas.size = FRAME_SIZE
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_canvas.draw.connect(_draw_scene)
	add_child(_canvas)
	_card_style = _friend_card_style()
	_next_card_style = _friend_card_style()
	_next_card_style.border_color = UiStyle.GOLD_COLOR
	_next_card_style.bg_color = Color(0.12, 0.15, 0.14, 0.97)
	_actors = Control.new()
	_actors.name = "CharacterArt"
	_actors.size = FRAME_SIZE
	_actors.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_actors.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var actor_material := ShaderMaterial.new()
	actor_material.shader = ACTOR_SHADER
	_actors.material = actor_material
	_actors.draw.connect(_draw_actors)
	_canvas.add_child(_actors)

	_location = _label("CASA DA ÁRVORE  /  O REENCONTRO", 11, Color(0.8, 0.88, 0.86), Rect2(24, 27, 540, 18), HORIZONTAL_ALIGNMENT_LEFT)
	_dialogue = Panel.new()
	_dialogue.name = "Dialogue"
	_dialogue.position = Vector2(24, 258)
	_dialogue.size = Vector2(592, 70)
	_dialogue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = UiStyle.panel_style()
	style.border_color = Color(0.42, 0.72, 0.61)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	_dialogue.add_theme_stylebox_override("panel", style)
	_canvas.add_child(_dialogue)
	_speaker = _label("", 12, UiStyle.GOLD_COLOR, Rect2(40, 265, 554, 18), HORIZONTAL_ALIGNMENT_LEFT)
	_line = _label("", 14, UiStyle.TEXT_COLOR, Rect2(40, 284, 554, 39), HORIZONTAL_ALIGNMENT_LEFT)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint = _label("E / Enter / Espaço: continuar    ·    ESC: pular cena", 10, Color(0.66, 0.77, 0.8), Rect2(24, 338, 592, 15))
	_title = _label("RUMO À PRAIA", 32, Color(1.0, 0.92, 0.65), Rect2(50, 91, 540, 43))
	_subtitle = _label("Costa das Marés · Próximo resgate: Tartaruga", 16, Color(0.89, 0.96, 0.95), Rect2(50, 139, 540, 28))
	_next_rescue_hint = _label("PRÓXIMO RESGATE", 9, UiStyle.GOLD_COLOR, Rect2(37, 139, 104, 15))
	for index: int in FRIEND_NAMES.size():
		var label_node: Label = _label(FRIEND_NAMES[index], 11, UiStyle.GOLD_COLOR if index == 0 else Color(0.89, 0.94, 0.89), Rect2(37 + index * 116, 222, 104, 21))
		label_node.add_theme_font_size_override("font_size", 9 if index == 4 else 11)
		_friend_labels.append(label_node)


func _label(text: String, font_size: int, color: Color, rect: Rect2, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var node: Label = UiStyle.shadowed_label(text, font_size, color, align)
	node.position = rect.position
	node.size = rect.size
	_canvas.add_child(node)
	return node


func _show_beat(index: int) -> void:
	beat_index = index
	_elapsed = 0.0
	_speaker.text = SPEAKERS[index]
	_line.text = LINES[index]
	_title.visible = index == 4
	_subtitle.visible = index == 4
	_next_rescue_hint.visible = index == 2
	for label_node: Label in _friend_labels:
		label_node.visible = index == 2
	_location.text = "CASA DA ÁRVORE  /  O REENCONTRO" if index <= 1 else "PRÓXIMA PARADA  /  COSTA DAS MARÉS"
	_canvas.queue_redraw()
	_actors.queue_redraw()


func _process(delta: float) -> void:
	if not _started or has_finished:
		return
	_elapsed += delta
	_total_elapsed += delta
	var fade: float = clampf(_elapsed / 0.3, 0.0, 1.0)
	_speaker.modulate.a = fade
	_line.modulate.a = fade
	_title.modulate.a = clampf((_elapsed - 0.3) / 0.65, 0.0, 1.0)
	_subtitle.modulate.a = _title.modulate.a
	_canvas.queue_redraw()
	_actors.modulate.a = clampf(_elapsed / 0.22, 0.0, 1.0)
	_actors.queue_redraw()
	if auto_progress and _elapsed >= BEAT_DURATIONS[beat_index]:
		_advance()


func _input(event: InputEvent) -> void:
	if not _started or has_finished:
		return
	var skip := false
	var advance := false
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		skip = key_event.keycode == KEY_ESCAPE
		advance = key_event.keycode in [KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]
	elif event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		advance = mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
	if not skip and not advance:
		return
	get_viewport().set_input_as_handled()
	# Entrada da porta e tecla mantida não podem saltar o primeiro diálogo.
	if _total_elapsed < 0.65 or _elapsed < 0.45:
		return
	var now: int = Time.get_ticks_msec()
	if now - _last_advance_msec < 300:
		return
	_last_advance_msec = now
	if skip:
		_finish()
	else:
		_advance()


func _advance() -> void:
	if has_finished:
		return
	if beat_index + 1 < BEAT_DURATIONS.size():
		_show_beat(beat_index + 1)
	else:
		_finish()


func _finish() -> void:
	if has_finished:
		return
	has_finished = true
	Sfx.end_dialogue_music(self)
	set_process_input(false)
	set_process(false)
	finished.emit()
	queue_free()


func _draw_scene() -> void:
	_draw_sky()
	if beat_index <= 1:
		_draw_meeting()
	elif beat_index == 2:
		_draw_map()
	else:
		_draw_flight()
	# Letterbox e marcadores discretos mantêm a leitura da cena em 640 × 360.
	_canvas.draw_rect(Rect2(0, 0, 640, 20), Color(0.015, 0.035, 0.065))
	_canvas.draw_rect(Rect2(0, 332, 640, 28), Color(0.015, 0.035, 0.065))
	for index: int in 5:
		_canvas.draw_circle(Vector2(576 + index * 8, 35), 2.0, UiStyle.GOLD_COLOR if index == beat_index else Color(0.4, 0.52, 0.55, 0.65))
	var veil: float = clampf(1.0 - _elapsed / 0.22, 0.0, 1.0)
	_canvas.draw_rect(Rect2(0, 48, 640, 207), Color(0.02, 0.06, 0.1, veil * 0.48))


func _draw_sky() -> void:
	UiStyle.draw_v_gradient(_canvas, Rect2(Vector2.ZERO, FRAME_SIZE), Color(0.07, 0.18, 0.28), Color(0.47, 0.64, 0.63), 48)
	_canvas.draw_circle(Vector2(510, 84), 27.0, Color(1.0, 0.87, 0.54, 0.22))
	_canvas.draw_circle(Vector2(510, 84), 19.0, Color(1.0, 0.89, 0.64, 0.6))
	for index: int in 5:
		var cloud_x: float = fposmod(29.0 + float(index) * 153.0 - _total_elapsed * (2.0 + float(index % 2)), 790.0) - 80.0
		var cloud_y: float = 60.0 + float((index * 17) % 3) * 21.0
		_draw_cloud(Vector2(cloud_x, cloud_y), 0.6 + float(index % 3) * 0.2)
	_canvas.draw_rect(Rect2(0, 163, 640, 169), Color(0.12, 0.38, 0.48))
	for index: int in 16:
		var row: float = 173.0 + float(index) * 10.0
		var drift: float = sin(_total_elapsed * 0.6 + float(index)) * 16.0
		for column: int in 4:
			var water_x: float = float(column) * 188.0 + float((index * 29) % 87) + drift
			_canvas.draw_line(Vector2(water_x, row), Vector2(water_x + 26.0 + float(index % 3) * 9.0, row), Color(0.49, 0.77, 0.75, 0.1), 1.0)
	_draw_island(Vector2(87, 167), 0.8, Color(0.16, 0.37, 0.37), false)
	_draw_island(Vector2(338, 174), 0.5, Color(0.22, 0.43, 0.42), false)
	_draw_island(Vector2(577, 161), 0.6, Color(0.2, 0.4, 0.4), false)


func _draw_cloud(at: Vector2, cloud_scale: float) -> void:
	var color := Color(0.87, 0.94, 0.88, 0.12)
	_canvas.draw_circle(at, 10.0 * cloud_scale, color)
	_canvas.draw_circle(at + Vector2(15, -4) * cloud_scale, 13.0 * cloud_scale, color)
	_canvas.draw_circle(at + Vector2(31, 0) * cloud_scale, 9.0 * cloud_scale, color)
	_canvas.draw_rect(Rect2(at + Vector2(-1, 0) * cloud_scale, Vector2(32, 8) * cloud_scale), color)


func _draw_meeting() -> void:
	# Artes da própria fase, com o oceano aparecendo por trás da copa.
	var tree: Texture2D = _textures.get("arvore") as Texture2D
	_draw_texture(tree, Rect2(-47, 121, 210, 196), Color(0.37, 0.59, 0.51))
	_draw_texture(tree, Rect2(126, 176, 151, 141), Color(0.48, 0.65, 0.52))
	_canvas.draw_colored_polygon(PackedVector2Array([Vector2(0, 303), Vector2(172, 295), Vector2(291, 318), Vector2(640, 309), Vector2(640, 332), Vector2(0, 332)]), Color(0.08, 0.2, 0.16))
	_canvas.draw_line(Vector2(0, 303), Vector2(164, 296), Color(0.43, 0.63, 0.35), 3.0)
	var house: Texture2D = _textures.get("casa_arvore") as Texture2D
	# O mesmo deck da fase está em y155 no PNG: -10,5 + 155 × 1,5 = 222.
	# Tronco e galhos da própria arte sustentam a varanda, sem estacas soltas.
	_draw_texture(house, Rect2(283, -10.5, 336, 336))
	var arrive: float = _meeting_arrival()
	_draw_shadow(Vector2(_meeting_nico_x() + 33, 221), Vector2(22, 4), 0.3)
	_draw_shadow(Vector2(468, 221), Vector2(25, 4), arrive * 0.28)
	for index: int in 6:
		var mote: Vector2 = Vector2(34.0 + float(index) * 104.0 + sin(_total_elapsed + float(index)) * 9.0, 176.0 + sin(_total_elapsed * 0.7 + float(index) * 1.9) * 34.0)
		_canvas.draw_circle(mote, 1.0, Color(0.94, 0.88, 0.5, 0.35 + 0.2 * sin(_total_elapsed * 2.0 + float(index))))


func _draw_map() -> void:
	_canvas.draw_rect(Rect2(24, 55, 592, 193), Color(0.025, 0.1, 0.17, 0.66))
	_canvas.draw_line(Vector2(39, 66), Vector2(601, 66), Color(0.69, 0.82, 0.66, 0.3), 1.0)
	var route_progress: float = clampf(_elapsed / 2.5, 0.0, 1.0)
	var previous := Vector2(38, 130)
	for index: int in MAP_POINTS.size():
		var point: Vector2 = MAP_POINTS[index]
		_draw_dotted_route(previous, point, route_progress, index)
		var island_color := Color(0.7, 0.63, 0.37) if index == 0 else Color(0.23, 0.42, 0.26)
		_draw_island(point + Vector2(0, 8), 0.56, island_color, true)
		_canvas.draw_circle(point + Vector2(0, -8), 4.0 if index == 0 else 3.0, UiStyle.GOLD_COLOR if index == 0 else Color(0.57, 0.76, 0.66))
		_canvas.draw_line(point + Vector2(0, 28), Vector2(point.x, 151), Color(0.57, 0.76, 0.66, 0.4), 1.0)
		var rect := Rect2(37 + index * 116, 154, 104, 89)
		_canvas.draw_style_box(_next_card_style if index == 0 else _card_style, rect)
		previous = point
	# Pequena bússola sem texto redundante com os nomes dos amigos.
	_canvas.draw_line(Vector2(588, 78), Vector2(588, 100), Color(0.78, 0.88, 0.77), 1.0)
	_canvas.draw_line(Vector2(580, 89), Vector2(596, 89), Color(0.78, 0.88, 0.77), 1.0)
	_canvas.draw_colored_polygon(PackedVector2Array([Vector2(588, 74), Vector2(585, 82), Vector2(591, 82)]), UiStyle.GOLD_COLOR)


func _friend_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.09, 0.14, 0.94)
	style.border_color = Color(0.38, 0.59, 0.54, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	return style


func _draw_dotted_route(from: Vector2, to: Vector2, progress: float, segment: int) -> void:
	var distance: float = from.distance_to(to)
	var dots: int = maxi(int(distance / 9.0), 1)
	for dot: int in dots:
		var fraction: float = float(dot) / float(dots)
		if (float(segment) + fraction) / float(MAP_POINTS.size()) <= progress:
			var point: Vector2 = from.lerp(to, fraction)
			point.y -= sin(fraction * PI) * 12.0
			_canvas.draw_circle(point, 1.2, Color(1.0, 0.86, 0.46, 0.9) if segment == 0 else Color(0.57, 0.76, 0.66, 0.6))


func _draw_flight() -> void:
	_draw_island(Vector2(39 - _elapsed * 4.0, 249), 1.5, Color(0.12, 0.3, 0.22), true)
	_draw_island(Vector2(605, 213), 1.0, Color(0.17, 0.37, 0.25), true)
	var at: Vector2 = _flight_position()
	for index: int in 3:
		var length: float = 14.0 + float(index) * 7.0
		_canvas.draw_line(at + Vector2(-30 - length, 38 + index * 14), at + Vector2(-15, 38 + index * 14), Color(0.79, 0.92, 0.85, 0.18), 1.0)


func _draw_actors() -> void:
	# Material aplicado só às artes dos personagens: o cenário e a interface
	# conservam transparências suaves e suas cores originais.
	if beat_index <= 1:
		var arrive: float = _meeting_arrival()
		_draw_nico(Vector2(_meeting_nico_x(), 158), 2.0)
		var arara_at: Vector2 = Vector2(lerpf(608.0, 448.0, arrive), lerpf(62.0, 149.5, arrive))
		if arrive < 0.98:
			arara_at.y -= sin(arrive * PI) * 25.0
		var arara_texture: Texture2D = _arara_fly[int(_total_elapsed * 8.0) % _arara_fly.size()] if arrive < 0.98 else _arara_idle[int(_total_elapsed * 2.0) % _arara_idle.size()]
		_draw_actor_texture(arara_texture, Rect2(arara_at, Vector2(80, 80)), true)
	elif beat_index == 2:
		for index: int in FRIEND_NAMES.size():
			var texture: Texture2D = _friend_textures[index]
			if int(_total_elapsed / 0.7) % 2 == 1 and _friend_second_textures[index] != null:
				texture = _friend_second_textures[index]
			if index == 0:
				# A arte da tartaruga tem proporção 4:3; os demais amigos são quadrados.
				_draw_actor_texture(texture, Rect2(47, 160, 84, 63))
			else:
				_draw_actor_texture(texture, Rect2(60 + index * 116, 160, 58, 58))
	else:
		var at: Vector2 = _flight_position()
		var flight_scale: float = 0.75 if beat_index == 4 else 1.0
		# Os pés de Nico acompanham o dorso registrado nos quatro frames.
		var wing_frame: int = int(_total_elapsed * 8.0) % _arara_fly.size()
		_draw_actor_texture(_arara_fly[wing_frame], Rect2(at, Vector2(112, 112) * flight_scale))
		_draw_nico(at + Vector2(40, 17) * flight_scale, 1.5 * flight_scale)


func _meeting_arrival() -> float:
	return _ease_out(clampf(_elapsed / 2.4, 0.0, 1.0)) if beat_index == 0 else 1.0


func _meeting_nico_x() -> float:
	return lerpf(282.0, 331.0, _ease_out(clampf(_elapsed / 1.4, 0.0, 1.0))) if beat_index == 0 else 331.0


func _flight_position() -> Vector2:
	if beat_index == 4:
		return Vector2(398 + _elapsed * 13.0, 162.0 + sin(_total_elapsed * 3.0) * 3.0)
	var trip: float = clampf(_elapsed / 6.0, 0.0, 1.0)
	return Vector2(lerpf(120.0, 407.0, trip), 142.0 - sin(trip * PI) * 38.0 + sin(_total_elapsed * 3.0) * 3.0)


func _draw_island(at: Vector2, island_scale: float, color: Color, detailed: bool) -> void:
	var points := PackedVector2Array([
		Vector2(-57, 6), Vector2(-43, -2), Vector2(-27, -21), Vector2(-9, -28),
		Vector2(7, -20), Vector2(22, -32), Vector2(38, -15), Vector2(58, 5),
		Vector2(43, 13), Vector2(5, 18), Vector2(-34, 14),
	])
	for index: int in points.size():
		points[index] = at + points[index] * island_scale
	_canvas.draw_colored_polygon(points, color)
	_canvas.draw_line(at + Vector2(-50, 9) * island_scale, at + Vector2(49, 9) * island_scale, Color(0.83, 0.76, 0.47, 0.55), maxf(1.0, 2.0 * island_scale))
	if detailed:
		_canvas.draw_line(at + Vector2(8, -3) * island_scale, at + Vector2(12, -39) * island_scale, Color(0.19, 0.27, 0.18), 2.0 * island_scale)
		_canvas.draw_colored_polygon(PackedVector2Array([
			at + Vector2(12, -42) * island_scale, at + Vector2(-10, -34) * island_scale,
			at + Vector2(11, -36) * island_scale, at + Vector2(31, -31) * island_scale,
			at + Vector2(21, -42) * island_scale,
		]), Color(0.26, 0.47, 0.29))


func _draw_shadow(at: Vector2, radius: Vector2, alpha: float) -> void:
	var points := PackedVector2Array()
	for index: int in 18:
		var angle: float = TAU * float(index) / 18.0
		points.append(at + Vector2(cos(angle), sin(angle)) * radius)
	_canvas.draw_colored_polygon(points, Color(0.02, 0.07, 0.08, alpha))


func _draw_nico(at: Vector2, sprite_scale: float) -> void:
	if beat_index == 0 and _elapsed < 1.4:
		var run_index: int = int(_elapsed * 12.0) % _nico_run_frames.size()
		_draw_actor_texture(_nico_run_frames[run_index], Rect2(at, Vector2(33, 32) * sprite_scale))
		return
	var index: int = int(_total_elapsed * 5.0) % _nico_frames.size()
	_draw_actor_texture(_nico_frames[index], Rect2(at, Vector2(33, 32) * sprite_scale))


func _draw_actor_texture(texture: Texture2D, rect: Rect2, flip_h: bool = false) -> void:
	if texture == null:
		return
	if flip_h:
		# Espelha dentro do mesmo retângulo e conserva o pouso na varanda.
		_actors.draw_set_transform(rect.position + Vector2(rect.size.x, 0), 0.0, Vector2(-1, 1))
		_actors.draw_texture_rect(texture, Rect2(Vector2.ZERO, rect.size), false)
		_actors.draw_set_transform(Vector2.ZERO)
	else:
		_actors.draw_texture_rect(texture, rect, false)


func _draw_texture(texture: Texture2D, rect: Rect2, color: Color = Color.WHITE) -> void:
	if texture != null:
		_canvas.draw_texture_rect(texture, rect, false, color)


func _ease_out(value: float) -> float:
	return 1.0 - pow(1.0 - value, 3.0)

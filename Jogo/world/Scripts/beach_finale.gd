extends CanvasLayer
const FriendArt = preload("res://world/Scripts/friend_art.gd")
## O dono da fase controla a pausa e os resultados; a cena só emite finished.

signal finished

const UiStyle := preload("res://world/Scripts/ui_style.gd")
const ACTOR_SHADER := preload("res://world/Scripts/characters_cutout.gdshader")
const FRAME_SIZE := Vector2(640.0, 360.0)
const BEAT_DURATIONS: Array[float] = [4.0, 4.5, 4.5]
const SPEAKERS: Array[String] = ["Nico", "Tartaruga", "Arara Minas"]
const LINES: Array[String] = [
	"Você está livre! Conseguimos abrir a gaiola.",
	"Obrigada por me libertarem de Urus, o Urubu! Vocês chegaram bem na hora!",
	"Remi, nosso amigo esquilo, está na Floresta Violeta! Triple H vigia a clareira. Vamos resgatá-lo!",
]

@export var auto_progress := true

var beat_index := 0
var has_finished := false
var _started := false
var _elapsed := 0.0
var _total_elapsed := 0.0
var _last_advance_msec := -1000
var _canvas: Control
var _actors: Control
var _portrait: Control
var _speaker: Label
var _line: Label
var _nico_frames: Array[Texture2D] = []
var _arara_frames: Array[Texture2D] = []
var _arara_portraits: Array[Texture2D] = [preload("res://world/Arte/Friends/V47/arara_portrait_neutral.tres"),preload("res://world/Arte/Friends/V47/arara_portrait_talk.tres")]
var _turtle: Texture2D
var _turtle_frames: SpriteFrames
var _turtle_portraits: Array[Texture2D] = []
var _nico_portrait: Texture2D
var _equipped_nico: Node2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 80
	start()


func start() -> void:
	if _started or has_finished:
		return
	_started = true
	Sfx.begin_dialogue_music(self)
	for frame: int in range(1, 5):
		_nico_frames.append(_texture("res://world/Arte/Nico/idle_%d.png" % frame))
	for frame: int in range(1, 3):
		_arara_frames.append(_texture("res://world/Arte/Amigos/arara_idle_%d.png" % frame))
	_turtle = _texture("res://world/Arte/Friends/V47/turtle_body_00.tres")
	if ResourceLoader.exists("res://world/Arte/Tartaruga/turtle.tres"):
		_turtle_frames = load("res://world/Arte/Tartaruga/turtle.tres") as SpriteFrames
	_turtle_portraits.append(_texture("res://world/Arte/Friends/V47/turtle_portrait_neutral.tres"))
	_turtle_portraits.append(_texture("res://world/Arte/Friends/V47/turtle_portrait_talk.tres"))
	_nico_portrait = _texture("res://world/Arte/Nico/hud_1.png")
	_build()
	_show_beat(0)


func _texture(path: String) -> Texture2D:
	return FriendArt.texture(path) if ResourceLoader.exists(FriendArt.resolve(path)) else null


func _build() -> void:
	_canvas = Control.new()
	_canvas.name = "BeachRescueCanvas"
	_canvas.size = FRAME_SIZE
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_canvas.draw.connect(_draw_scene)
	add_child(_canvas)
	_actors = Control.new()
	_actors.name = "RescuedFriends"
	_actors.size = FRAME_SIZE
	_actors.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_actors.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var material := ShaderMaterial.new()
	material.shader = ACTOR_SHADER
	_actors.material = material
	_actors.draw.connect(_draw_actors)
	_canvas.add_child(_actors)
	_make_equipped_nico()
	_label("PRAIA  /  UM AMIGO A SALVO", 11, Color(0.84, 0.94, 0.92), Rect2(24, 28, 490, 18), HORIZONTAL_ALIGNMENT_LEFT)
	var panel := Panel.new()
	panel.position = Vector2(24, 258)
	panel.size = Vector2(592, 70)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = UiStyle.panel_style()
	style.border_color = Color(0.48, 0.78, 0.77)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	_canvas.add_child(panel)
	_portrait = Control.new()
	_portrait.name = "TalkingPortrait"
	_portrait.position = Vector2(32, 265)
	_portrait.size = Vector2(56, 56)
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var portrait_material := ShaderMaterial.new()
	portrait_material.shader = ACTOR_SHADER
	_portrait.material = portrait_material
	_portrait.draw.connect(_draw_portrait)
	_canvas.add_child(_portrait)
	_speaker = _label("", 12, UiStyle.GOLD_COLOR, Rect2(102, 265, 494, 18), HORIZONTAL_ALIGNMENT_LEFT)
	_line = _label("", 14, UiStyle.TEXT_COLOR, Rect2(102, 284, 494, 39), HORIZONTAL_ALIGNMENT_LEFT)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label("E / Enter / Espaço: continuar    ·    ESC: pular cena", 10, Color(0.69, 0.81, 0.83), Rect2(24, 338, 592, 15))


func _make_equipped_nico() -> void:
	# Nico mantém seu sprite original e anima mesmo com a fase pausada.
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null or not player.has_method("get_equipment"):
		return
	if _nico_frames.is_empty() or _nico_frames.has(null):
		return
	var actor := Node2D.new()
	actor.name = "OriginalNico"
	actor.position = Vector2(212, 210)
	actor.scale = Vector2(2, 2)
	actor.z_index = 2
	actor.process_mode = Node.PROCESS_MODE_ALWAYS
	var animation := AnimatedSprite2D.new()
	animation.name = "anim"
	animation.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 5.0)
	frames.set_animation_loop(&"idle", true)
	for texture: Texture2D in _nico_frames:
		frames.add_frame(&"idle", texture)
	animation.sprite_frames = frames
	animation.animation = &"idle"
	actor.add_child(animation)
	_equipped_nico = actor
	_actors.add_child(actor)
	animation.play(&"idle")


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
	_line.visible_characters = 0
	_canvas.queue_redraw()
	_actors.queue_redraw()
	_portrait.queue_redraw()


func _process(delta: float) -> void:
	if not _started or has_finished:
		return
	_elapsed += delta
	_total_elapsed += delta
	var fade: float = clampf(_elapsed / 0.25, 0.0, 1.0)
	_speaker.modulate.a = fade
	_line.modulate.a = fade
	_line.visible_characters = mini(int(floorf(_elapsed * 44.0)), LINES[beat_index].length())
	_canvas.queue_redraw()
	_actors.queue_redraw()
	_portrait.queue_redraw()
	if auto_progress and _elapsed >= BEAT_DURATIONS[beat_index]:
		_advance()


func _input(event: InputEvent) -> void:
	if not _started or has_finished:
		return
	var skip := false
	var advance := false
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if not key.pressed or key.echo:
			return
		skip = key.keycode == KEY_ESCAPE
		advance = event.is_action_pressed("interagir") or key.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]
	elif event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		advance = mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
	if not skip and not advance:
		return
	get_viewport().set_input_as_handled()
	# O golpe que abriu a gaiola não deve avançar o primeiro diálogo.
	if _total_elapsed < 0.65 or _elapsed < 0.35:
		return
	var now: int = Time.get_ticks_msec()
	if now - _last_advance_msec < 250:
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
	UiStyle.draw_v_gradient(_canvas, Rect2(Vector2.ZERO, FRAME_SIZE), Color(0.24, 0.61, 0.73), Color(0.71, 0.89, 0.84), 48)
	_canvas.draw_rect(Rect2(487, 56, 28, 28), Color(1.0, 0.93, 0.65))
	_canvas.draw_rect(Rect2(480, 63, 42, 14), Color(1.0, 0.93, 0.65))
	_draw_cloud(Vector2(91, 74), 1.0)
	_draw_cloud(Vector2(348, 95), 0.75)
	_canvas.draw_rect(Rect2(0, 146, 640, 93), Color(0.13, 0.51, 0.64))
	_canvas.draw_rect(Rect2(0, 166, 640, 72), Color(0.15, 0.63, 0.71))
	_canvas.draw_rect(Rect2(0, 192, 640, 47), Color(0.28, 0.74, 0.74))
	for row: int in 6:
		var wave_y: float = 153.0 + float(row) * 11.0
		var drift: float = roundf(sin(_total_elapsed * 0.8 + float(row)) * 12.0)
		for column: int in 6:
			var wave_x: float = float(column) * 119.0 + float((row * 23) % 61) + drift
			_canvas.draw_rect(Rect2(wave_x, wave_y, 27 + row * 2, 1), Color(0.73, 0.95, 0.9, 0.45))
	_canvas.draw_colored_polygon(PackedVector2Array([Vector2(0, 222), Vector2(101, 213), Vector2(213, 218), Vector2(318, 208), Vector2(441, 211), Vector2(543, 202), Vector2(640, 212), Vector2(640, 360), Vector2(0, 360)]), Color(0.78, 0.65, 0.43))
	_canvas.draw_colored_polygon(PackedVector2Array([Vector2(0, 229), Vector2(103, 220), Vector2(215, 225), Vector2(320, 215), Vector2(443, 218), Vector2(545, 209), Vector2(640, 219), Vector2(640, 360), Vector2(0, 360)]), Color(0.94, 0.83, 0.59))
	for index: int in 24:
		var at := Vector2(12 + (index * 83) % 626, 231 + (index * 17) % 24)
		_canvas.draw_rect(Rect2(at, Vector2(3 if index % 3 == 0 else 1, 1)), Color(0.65, 0.5, 0.29, 0.36))
	_draw_palm(Vector2(66, 240), 1.1)
	_draw_palm(Vector2(600, 229), 0.7)
	_shadow(Vector2(212, 242), Vector2(23, 3))
	_shadow(Vector2(306, 241), Vector2(20, 3))
	_shadow(Vector2(429, 241), Vector2(53, 4))
	# O cadeado aberto fica no chão; a tartaruga aparece livre ao lado dos amigos.
	_canvas.draw_rect(Rect2(537, 233, 8, 6), Color(0.53, 0.36, 0.17))
	_canvas.draw_line(Vector2(539, 234), Vector2(539, 229), Color(0.87, 0.7, 0.34), 2.0)
	_canvas.draw_line(Vector2(539, 229), Vector2(544, 229), Color(0.87, 0.7, 0.34), 2.0)
	_canvas.draw_line(Vector2(544, 229), Vector2(546, 231), Color(0.87, 0.7, 0.34), 2.0)
	_canvas.draw_rect(Rect2(0, 0, 640, 20), Color(0.015, 0.045, 0.075))
	_canvas.draw_rect(Rect2(0, 332, 640, 28), Color(0.015, 0.045, 0.075))
	for index: int in 3:
		_canvas.draw_rect(Rect2(584 + index * 9, 34, 4, 4), UiStyle.GOLD_COLOR if index == beat_index else Color(0.39, 0.6, 0.64))
	var veil: float = clampf(1.0 - _total_elapsed / 0.3, 0.0, 1.0)
	_canvas.draw_rect(Rect2(0, 48, 640, 208), Color(0.02, 0.08, 0.12, veil))


func _draw_actors() -> void:
	if not is_instance_valid(_equipped_nico):
		var nico_frame: int = int(_total_elapsed * 5.0) % _nico_frames.size()
		_draw_actor(_nico_frames[nico_frame], Rect2(179, 178, 66, 64))
	var arara_frame: int = int(_total_elapsed * 2.0) % _arara_frames.size()
	# A Arara olha para a amiga resgatada e mantém os pés sobre a areia.
	_draw_actor(_arara_frames[arara_frame], Rect2(247, 167.5, 80, 80))
	# Movimentos sutis mantêm os pés plantados e deixam o diálogo respirar.
	var arrive: float = 1.0 - pow(1.0 - clampf(_total_elapsed / 1.4, 0.0, 1.0), 3.0)
	var turtle_x: float = roundf(lerpf(385.0, 365.0, arrive))
	var turtle_y: float = 152.0 + (1.0 if sin(_total_elapsed * 2.0) > 0.8 else 0.0)
	var turtle_texture: Texture2D = _turtle
	if _turtle_frames != null:
		var animation: StringName = &"walk" if _total_elapsed < 1.4 else &"idle"
		var frame: int = int(_total_elapsed * _turtle_frames.get_animation_speed(animation)) % _turtle_frames.get_frame_count(animation)
		turtle_texture = _turtle_frames.get_frame_texture(animation, frame)
	# A tartaruga se aproxima olhando para Nico e Arara.
	_draw_actor(turtle_texture, Rect2(turtle_x, turtle_y, 128, 96), true)


func _draw_portrait() -> void:
	_portrait.draw_rect(Rect2(0, 0, 56, 56), Color(0.07, 0.14, 0.2))
	_portrait.draw_rect(Rect2(0, 0, 56, 56), Color(0.36, 0.63, 0.62), false, 1.0)
	var texture: Texture2D
	if beat_index == 1:
		# Cinco mudanças por segundo; a boca repousa quando a fala termina.
		var speaking_until: float = minf(BEAT_DURATIONS[beat_index] - 0.4, float(LINES[beat_index].length()) / 34.0 + 0.5)
		var mouth_frame: int = int(_elapsed * 5.0) % 2 if _elapsed < speaking_until else 0
		texture = _turtle_portraits[mouth_frame]
	elif beat_index == 0:
		texture = _nico_portrait
	else:
		texture = _arara_portraits[int(_elapsed * 5.0) % 2]
	if texture == null:
		return
	# Conserva a proporção nativa de cada retrato ou sprite reutilizado.
	var art_size: Vector2 = texture.get_size()
	var fit_scale: float = minf(52.0 / art_size.x, 52.0 / art_size.y)
	var fitted: Vector2 = art_size * fit_scale
	_portrait.draw_texture_rect(texture, Rect2((Vector2(56, 56) - fitted) * 0.5, fitted), false)


func _draw_actor(texture: Texture2D, rect: Rect2, flip_h: bool = false) -> void:
	if texture == null:
		return
	if flip_h:
		# Espelha dentro do mesmo retângulo; a âncora não muda de lado.
		_actors.draw_set_transform(rect.position + Vector2(rect.size.x, 0), 0.0, Vector2(-1, 1))
		_actors.draw_texture_rect(texture, Rect2(Vector2.ZERO, rect.size), false)
		_actors.draw_set_transform(Vector2.ZERO)
	else:
		_actors.draw_texture_rect(texture, rect, false)


func _draw_cloud(at: Vector2, cloud_scale: float) -> void:
	var x: float = roundf(at.x - fposmod(_total_elapsed * 1.2, 14.0))
	_canvas.draw_rect(Rect2(Vector2(x, at.y), Vector2(68, 8) * cloud_scale), Color(0.88, 0.97, 0.93, 0.7))
	_canvas.draw_rect(Rect2(Vector2(x + 9 * cloud_scale, at.y - 6 * cloud_scale), Vector2(41, 10) * cloud_scale), Color(0.88, 0.97, 0.93, 0.7))
	_canvas.draw_rect(Rect2(Vector2(x + 21 * cloud_scale, at.y - 11 * cloud_scale), Vector2(19, 6) * cloud_scale), Color(0.88, 0.97, 0.93, 0.7))


func _draw_palm(at: Vector2, palm_scale: float) -> void:
	var trunk := PackedVector2Array([Vector2(-5, 0), Vector2(3, -35), Vector2(3, -70), Vector2(10, -71), Vector2(10, -33), Vector2(2, 0)])
	for index: int in trunk.size():
		trunk[index] = at + trunk[index] * palm_scale
	_canvas.draw_colored_polygon(trunk, Color(0.42, 0.3, 0.2))
	var crown: Vector2 = at + Vector2(7, -70) * palm_scale
	for side: int in [-1, 1]:
		_canvas.draw_colored_polygon(PackedVector2Array([crown, crown + Vector2(25 * side, -18) * palm_scale, crown + Vector2(48 * side, -6) * palm_scale, crown + Vector2(24 * side, -9) * palm_scale, crown + Vector2(42 * side, 9) * palm_scale, crown + Vector2(13 * side, -1) * palm_scale, crown + Vector2(25 * side, 20) * palm_scale, crown + Vector2(3 * side, 6) * palm_scale]), Color(0.13, 0.38, 0.29))
	_canvas.draw_line(crown, crown + Vector2(-30, -10) * palm_scale, Color(0.38, 0.6, 0.35), 2.0)
	_canvas.draw_line(crown, crown + Vector2(31, -4) * palm_scale, Color(0.38, 0.6, 0.35), 2.0)


func _shadow(at: Vector2, radius: Vector2) -> void:
	var points := PackedVector2Array()
	for index: int in 16:
		var angle: float = TAU * float(index) / 16.0
		points.append(at + Vector2(cos(angle), sin(angle)) * radius)
	_canvas.draw_colored_polygon(points, Color(0.27, 0.29, 0.23, 0.23))

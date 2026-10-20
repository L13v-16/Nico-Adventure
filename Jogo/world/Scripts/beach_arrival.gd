extends CanvasLayer
const FriendArt = preload("res://world/Scripts/friend_art.gd")
## Conversa de chegada sobre o cenário real. A fase controla pausa e cronômetro.
signal finished
const UiStyle := preload("res://world/Scripts/ui_style.gd")
const LINES := [
	{"speaker":"Arara Minas", "text":"Chegamos à Costa das Marés! Nossa amiga Tartaruga está presa além do cais. Ela é idosa e conhece os caminhos entre as ilhas.", "tip":"NOSSO RESGATE", "detail":"Tartaruga\nUma amiga experiente", "icon":"turtle"},
	{"speaker":"Nico", "text":"Foi o lobo do crachá dourado que levou nossos amigos. Ele veio para cá?", "tip":"O CRACHÁ DOURADO", "detail":"Lobo da corporação\nO líder do sequestro", "icon":"wolf"},
	{"speaker":"Arara Minas", "text":"Ele é o chefe da corporação. Mandou Urus, o Urubu, vigiar a Tartaruga. Primeiro vamos libertá-la; depois seguimos o rastro do lobo.", "tip":"GUARDIÃO DO CAIS", "detail":"Urus, o Urubu\nVigia a Tartaruga", "icon":"urus"},
	{"speaker":"Arara Minas", "text":"Cuidado com os caranguejos: pule e caia sobre o casco para derrotá-los. Socos não funcionam, e encostar de lado machuca.", "tip":"CARANGUEJOS", "detail":"Pule sobre o casco!\nEvite o contato lateral", "icon":"crab"},
	{"speaker":"Arara Minas", "text":"O açaí dá poder de gelo: seus ataques congelam os inimigos por um tempo. Use essa chance para atravessar com calma.", "tip":"PODER DO AÇAÍ", "detail":"Golpes congelantes\nO efeito é temporário", "icon":"acai"},
	{"speaker":"Arara Minas", "text":"Espere as jangadas se aproximarem e toque nas bandeiras. Contra Urus, pule dentro dos canhões e escolha a hora certa para ser lançado nele.", "tip":"CONTRA URUS", "detail":"Escolha o canhão\nEspere a mira verde", "icon":"cannon"},
	{"speaker":"Nico", "text":"Entendi! Vou resgatar a Tartaruga. Nos vemos no cais, Arara Minas!", "tip":"PRÓXIMO PASSO", "detail":"Atravesse a praia\nLiberte a Tartaruga", "icon":"turtle"},
]
const ICON_PATHS := {
	"turtle":"Tartaruga/portrait_idle.png", "wolf":"Corporacao/wolf_idle.png",
	"urus":"Beach/urubu_fly_1.png", "crab":"Beach/crab_walk_1.png",
	"acai":"Beach/acai.png", "cannon":"Beach/cannon_idle.png",
}
var beat_index := 0
var has_finished := false
var auto_progress := true
var _elapsed := 0.0
var _clock := 0.0
var _revealed := false
var _canvas: Control
var _portrait: Control
var _icon: Control
var _speaker: Label
var _line: Label
var _tip: Label
var _detail: Label
var _hint: Label
var _textures: Dictionary = {}
var _old_camera: Camera2D
var _arrival_camera: Camera2D
var _hud: CanvasLayer
var _hud_was_visible := true
var _actors: Array[Node] = []
var _actor_modes: Array[int] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 80
	Sfx.begin_dialogue_music(self)
	for key in ICON_PATHS:
		_textures[key] = FriendArt.texture("res://world/Arte/" + String(ICON_PATHS[key]))
	for i in range(1, 3):
		_textures["arara%d" % i] = FriendArt.texture("res://world/Arte/Friends/V47/arara_portrait_%s.tres" % ("neutral" if i == 1 else "talk"))
	_textures["nico"] = load("res://world/Arte/Nico/hud_1.png") as Texture2D
	_frame_characters()
	_build()
	_show_beat(0)

func _frame_characters() -> void:
	var level := get_parent()
	_old_camera = get_viewport().get_camera_2d()
	_arrival_camera = Camera2D.new()
	_arrival_camera.name = "ArrivalConversationCamera"
	_arrival_camera.position = Vector2(117, 35)
	_arrival_camera.zoom = Vector2(1.7, 1.7)
	level.add_child(_arrival_camera)
	_arrival_camera.make_current()
	_hud = level.get_node_or_null("HUD") as CanvasLayer
	if _hud != null:
		_hud_was_visible = _hud.visible
		_hud.hide()
	for path in ["Player/anim", "Scenery/AraraMinas"]:
		var actor := level.get_node_or_null(path)
		if actor != null:
			_actors.append(actor)
			_actor_modes.append(actor.process_mode)
			actor.process_mode = Node.PROCESS_MODE_ALWAYS

func _build() -> void:
	_canvas = Control.new()
	_canvas.size = Vector2(640, 360)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_canvas.draw.connect(_draw_frame)
	add_child(_canvas)
	_label("COSTA DAS MARÉS  /  A CHEGADA", 12, UiStyle.TEXT_COLOR, Rect2(24, 24, 450, 20))
	var panel := Panel.new()
	panel.position = Vector2(20, 236)
	panel.size = Vector2(600, 102)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := UiStyle.panel_style()
	style.border_color = Color("78c9c3")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	_canvas.add_child(panel)
	_portrait = _art_control(Vector2(30, 255), Vector2(68, 68), _draw_portrait)
	_speaker = _label("", 13, UiStyle.GOLD_COLOR, Rect2(112, 245, 486, 18))
	_line = _label("", 14, UiStyle.TEXT_COLOR, Rect2(112, 267, 486, 63))
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip = _label("", 10, Color("ecd08a"), Rect2(452, 78, 156, 17))
	_detail = _label("", 11, UiStyle.TEXT_COLOR, Rect2(452, 101, 156, 42))
	_icon = _art_control(Vector2(393, 87), Vector2(52, 52), _draw_icon)
	_hint = _label("E / ENTER / ESPAÇO  revelar / avançar     •     ESC  pular", 10, Color("a5c9c4"), Rect2(24, 342, 590, 16))

func _art_control(at: Vector2, bounds: Vector2, callback: Callable) -> Control:
	var art := Control.new()
	art.position = at
	art.size = bounds
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.draw.connect(callback)
	var material := ShaderMaterial.new()
	material.shader = load("res://world/Scripts/characters_cutout.gdshader") as Shader
	art.material = material
	_canvas.add_child(art)
	return art

func _label(text: String, size_font: int, color: Color, rect: Rect2) -> Label:
	var label := UiStyle.shadowed_label(text, size_font, color, HORIZONTAL_ALIGNMENT_LEFT)
	label.position = rect.position
	label.size = rect.size
	_canvas.add_child(label)
	return label

func _show_beat(index: int) -> void:
	beat_index = index
	_elapsed = 0.0
	_revealed = false
	_speaker.text = String(LINES[index].speaker)
	_line.text = String(LINES[index].text)
	_line.visible_characters = 0
	_tip.text = String(LINES[index].tip)
	_detail.text = String(LINES[index].detail)
	_portrait.queue_redraw()
	_icon.queue_redraw()

func _process(delta: float) -> void:
	if has_finished:
		return
	_elapsed += delta
	_clock += delta
	_canvas.scale = get_viewport().get_visible_rect().size / Vector2(640, 360)
	_line.visible_characters = -1 if _revealed else mini(int(_elapsed * 45), _line.text.length())
	_portrait.queue_redraw()
	_canvas.queue_redraw()
	if auto_progress and _elapsed > maxf(4.5, _line.text.length() / 45.0 + 2.6):
		_advance()

func _input(event: InputEvent) -> void:
	if has_finished or event.is_echo():
		return
	var skip := event.is_action_pressed("ui_cancel")
	var advance := event.is_action_pressed("interagir") or event.is_action_pressed("ui_accept")
	if event is InputEventMouseButton:
		advance = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if not skip and not advance:
		return
	get_viewport().set_input_as_handled()
	if _clock < 0.35:
		return
	if skip:
		_finish()
	elif not _revealed and _line.visible_characters < _line.text.length():
		_revealed = true
	else:
		_advance()

func _advance() -> void:
	if has_finished:
		return
	if beat_index + 1 < LINES.size():
		_show_beat(beat_index + 1)
	else:
		_finish()

func _finish() -> void:
	if has_finished:
		return
	has_finished = true
	_restore_context()
	Sfx.end_dialogue_music(self)
	finished.emit()
	queue_free()

func _restore_context() -> void:
	if is_instance_valid(_old_camera) and _old_camera.is_inside_tree():
		_old_camera.make_current()
	if is_instance_valid(_arrival_camera):
		_arrival_camera.queue_free()
	if is_instance_valid(_hud):
		_hud.visible = _hud_was_visible
	for i in _actors.size():
		if is_instance_valid(_actors[i]):
			_actors[i].process_mode = _actor_modes[i]

func _exit_tree() -> void:
	if not has_finished:
		_restore_context()

func _draw_frame() -> void:
	_canvas.draw_rect(Rect2(0, 0, 640, 360), Color(0.02, 0.07, 0.12, 0.15))
	_canvas.draw_style_box(UiStyle.panel_style(), Rect2(382, 68, 238, 86))
	for i in LINES.size():
		_canvas.draw_rect(Rect2(540 + i * 10, 31, 6, 3), Color("ecd08a") if i <= beat_index else Color("4f827f"))

func _draw_portrait() -> void:
	if String(LINES[beat_index].speaker) == "Nico":
		_portrait.draw_texture_rect(_textures.nico, Rect2(0, 0, 68, 68), false)
	else:
		var frame := 1 + int(_clock * 4) % 2
		_portrait.draw_texture_rect(_textures["arara%d" % frame], Rect2(0, 0, 68, 68), false)

func _draw_icon() -> void:
	var texture: Texture2D = _textures[String(LINES[beat_index].icon)]
	var bounds := FriendArt.bounds(texture)
	var ratio := minf(52.0 / bounds.size.x, 52.0 / bounds.size.y)
	var size := Vector2(bounds.size) * ratio
	_icon.draw_texture_rect_region(texture, Rect2((Vector2(52, 52) - size) * 0.5, size), bounds)

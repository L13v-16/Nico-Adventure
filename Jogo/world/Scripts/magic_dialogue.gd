extends CanvasLayer
signal finished
@export var rescue := false
@export var auto_progress := true
const UiStyle := preload("res://world/Scripts/ui_style.gd")
const ARRIVAL := [
	["Arara Minas","Esta é a Floresta Violeta! Remi, nosso amigo esquilo, está preso na clareira da Hiena HaHa, a Triple H.","REMI PRECISA DE NÓS"],
	["Arara Minas","Os cogumelos vermelhos são elásticos. Caia sobre o chapéu e eles vão lançar você muito mais alto que um salto comum!","VERMELHO: IMPULSO ALTO"],
	["Arara Minas","Aproxime-se da ponta de um cipó e aperte E para agarrar. Use A / D ou as setas para ganhar balanço. Espaço / W solta com um salto!","E: AGARRAR  ·  DIREÇÃO: BALANÇAR"],
	["Arara Minas","Alguns cipós passeiam sozinhos. Toque nas plantas luminosas para mudar a posição de outros. Observe antes de saltar!","PLANTAS VIVAS MUDAM O CAMINHO"],
	["Arara Minas","A fruta-do-dragão cresce nesta floresta! Ela permite lançar fogo por 20 segundos. Recolha uma e segure K para disparar. O efeito termina quando o tempo acaba.","FRUTA-DO-DRAGÃO  ·  K: FOGO POR 20 SEGUNDOS"],
	["Arara Minas","Hiena HaHa, a Triple H, montou um ringue! J / X rebate o barril e a deixa tonta. Nos socos, pule sobre ela e acerte por trás! Os cogumelos dos postes ajudam a passar por cima.","REBATA O BARRIL  ·  SOCOS: ACERTE POR TRÁS"],
	["Nico","Vou ter cuidado com os besouros espinhosos e as mariposas. Hiena HaHa, já estou chegando!","J / X: ATACAR  ·  BANDEIRAS: RETORNO"],
]
const RESCUE := [
	["Nico","Remi! Hiena HaHa não vai mais prender ninguém aqui. Você está livre!","REMI RESGATADO"],
	["Remi","Eu sabia que vocês viriam! O lobo do crachá dourado quer dominar todas as ilhas. Ele levou José, Urso e o mico para longe daqui.","O RASTRO DA CORPORAÇÃO"],
	["Arara Minas","Então seguimos juntos. Cada amigo de volta deixa nossa turma mais forte!","UMA NOVA COMPANHIA NA VIAGEM"],
	["Remi","José, nosso amigo bode, foi levado ao Submundo. Cuidado com os canhões da corporação! Vamos encontrar nossos amigos e parar esse lobo!","PRÓXIMA JORNADA: O SUBMUNDO"],
]
var beat_index := 0
var has_finished := false
var _elapsed := 0.0
var _clock := 0.0
var _revealed := false
var _canvas: Control
var _line: Label
var _speaker: Label
var _topic: Label
var _portrait: TextureRect
var _actor: AnimatedSprite2D
var _actor_anchor: Node2D
var _lines: Array
var _portraits: Dictionary = {}
var _old_hud_visible := true

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	layer=80
	_lines=RESCUE if rescue else ARRIVAL
	Sfx.begin_dialogue_music(self)
	_portraits={"Nico":preload("res://world/Arte/Nico/hud_1.png"),"Arara Minas":preload("res://world/Arte/Friends/V47/arara_portrait_neutral.tres"),"Remi":preload("res://world/Arte/Magic/remi_portrait.tres")}
	var hud:=get_parent().get_node_or_null("HUD") as CanvasLayer
	if hud!=null:
		_old_hud_visible=hud.visible
		hud.hide()
	_build()
	_show_beat()

func _label(text: String, size: int, rect: Rect2, color: Color) -> Label:
	var label:=UiStyle.label(text,size,color,HORIZONTAL_ALIGNMENT_LEFT)
	label.position=rect.position
	label.size=rect.size
	_canvas.add_child(label)
	return label

func _build() -> void:
	_canvas=Control.new()
	_canvas.size=Vector2(640,360)
	_canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_overlay)
	add_child(_canvas)
	_label("FLORESTA VIOLETA  /  "+("UM AMIGO DE VOLTA" if rescue else "ENTRE CIPÓS E ENCANTOS"),11,Rect2(24,23,590,20),Color("e3d2f7"))
	_topic=_label("",13,Rect2(30,66,580,22),Color("c3ffe9"))
	var panel:=Panel.new()
	panel.position=Vector2(20,220)
	panel.size=Vector2(600,116)
	var style:=UiStyle.panel_style()
	style.bg_color=Color("211932")
	style.border_color=Color("a77bd0")
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel",style)
	_canvas.add_child(panel)
	_portrait=TextureRect.new()
	_portrait.position=Vector2(34,237)
	_portrait.size=Vector2(68,76)
	_portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait.material=preload("res://world/Scripts/magic_art.gd").material()
	_canvas.add_child(_portrait)
	_speaker=_label("",13,Rect2(116,234,480,20),Color("efd5a4"))
	_line=_label("",14,Rect2(116,259,478,68),Color("efe8fa"))
	_line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_label("E / Enter / Espaço: continuar    ·    ESC: pular",10,Rect2(24,341,590,16),Color("b7a7ca"))
	if rescue:
		# A world-space parent keeps every pose on the real ground, including
		# after the camera has finished its last scroll update.
		_actor_anchor=Node2D.new()
		_actor_anchor.process_mode=Node.PROCESS_MODE_ALWAYS
		_actor_anchor.z_index=5
		get_parent().add_child(_actor_anchor)
		_actor_anchor.position=Vector2(6096,64)
		_actor=preload("res://world/Scripts/magic_art.gd").actor(preload("res://world/Arte/Magic/remi.tres"),32)
		_actor.material.set_shader_parameter("alpha_cutoff",0.94)
		_actor_anchor.add_child(_actor)
		_actor.flip_h=true # Nico aguarda à esquerda durante o resgate.
		_actor.play(&"happy")
		preload("res://world/Scripts/magic_art.gd").reanchor(_actor)

func _show_beat() -> void:
	_elapsed=0
	_revealed=false
	_speaker.text=String(_lines[beat_index][0])
	_line.text=String(_lines[beat_index][1])
	_topic.text=String(_lines[beat_index][2])
	var texture:Texture2D=_portraits[_speaker.text]
	_portrait.texture=texture
	_line.visible_characters=0

func _process(delta: float) -> void:
	_clock+=delta
	_elapsed+=delta
	if has_finished:return
	_line.visible_characters=-1 if _revealed else int(_elapsed*44)
	if is_instance_valid(_actor):
		_actor_anchor.position=Vector2(6096-minf(_clock*12,26),64)
		# A greeting, a blink and speaking poses; the feet never bob off the floor.
		_actor.play(&"talk" if _speaker.text=="Remi" and _line.visible_characters>=0 else (&"happy" if _clock<2.2 or beat_index==3 else &"idle"))
	if _speaker.text=="Remi":
		_portrait.texture=preload("res://world/Arte/Magic/remi_portrait_talk.tres") if int(_clock*7)%2==0 and _line.visible_characters>=0 else preload("res://world/Arte/Magic/remi_portrait.tres")
	if _speaker.text=="Arara Minas":
		_portrait.texture=preload("res://world/Arte/Friends/V47/arara_portrait_talk.tres") if int(_clock*7)%2==0 and _line.visible_characters>=0 else _portraits["Arara Minas"]
	_canvas.queue_redraw()
	if auto_progress and _elapsed>maxf(6.0,_line.text.length()/36.0+3.0):_advance()

func _input(event: InputEvent) -> void:
	if has_finished or event.is_echo() or _elapsed<0.28:return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interagir") or (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()
		if _line.visible_characters>=0 and _line.visible_characters<_line.text.length():_revealed=true
		else:_advance()

func _advance() -> void:
	if beat_index+1>=_lines.size():_finish()
	else:
		beat_index+=1
		_show_beat()

func _finish() -> void:
	if has_finished:return
	has_finished=true
	if is_instance_valid(_actor_anchor):_actor_anchor.queue_free()
	var hud:=get_parent().get_node_or_null("HUD") as CanvasLayer
	if hud!=null and not rescue:hud.visible=_old_hud_visible
	Sfx.end_dialogue_music(self)
	finished.emit()
	queue_free()

func _draw_overlay() -> void:
	_canvas.draw_rect(Rect2(0,0,640,360),Color(0.08,0.035,0.16,0.27))
	_canvas.draw_rect(Rect2(0,0,640,8),Color("211730"))
	for i in _lines.size():
		_canvas.draw_rect(Rect2(555+i*11,30,7,3),Color("bfe9d5") if i<=beat_index else Color("6e507d"))
	for i in 24:
		var x:=fposmod(float(i)*53.7+sin(_clock*0.6+i)*16,640)
		var y:=100+fposmod(float(i)*17.3-_clock*7,100)
		_canvas.draw_rect(Rect2(roundf(x),roundf(y),1,2),Color(0.67,1.0,0.91,0.25+0.3*absf(sin(_clock+i))))

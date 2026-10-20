extends CanvasLayer
signal finished
@export_enum("arrival","temple","ending","launch") var mode:="arrival"
@export var auto_progress:=true
var has_finished:=false
var beat_index:=0
var _clock:=0.0
var _elapsed:=0.0
var _revealed:=false
var _lines:Array=[]
var _canvas:Control
var _line:Label
var _speaker:Label
var _portrait:TextureRect
var _title:Label
var _portraits:Dictionary={}
var _old_hud:=true
const Ui=preload("res://world/Scripts/ui_style.gd")
const LINES={
	"arrival":[
		["José","Nico! A empresa me largou aqui, mas estas grades não seguraram minhas cabeçadas. Ainda precisamos encontrar a saída!"],
		["Nico","José, meu amigo! Vou tirar nós dois daqui. Esse canhão da corporação vai ter volta!"],
		["José","Marque os obstáculos e aperte C. Eu quebro paredes rachadas, derrubo pilares frágeis e empurro blocos pesados."],
		["José","Observe as fendas: rachaduras brilham, pedras tremem e faíscas sobem antes da lava. As marcadas com uma seta azul servem de impulso!"],
		["José","Rochas claras se aproximam; as roxas se afastam. Ajuste a ponte e use as pedras para se proteger dos tridentes. Vamos juntos!"],
	],
	"temple":[
		["José","O Templo dos Contrários! Estas inscrições dizem que calor e frio abrem o caminho da Forja Invertida."],
		["Nico","Agora consigo lançar fogo e gelo quando quiser! K dispara; Q alterna o elemento. Não preciso gastar frutas."],
		["José","Na forja: fogo na válvula laranja, gelo na azul, fogo e gelo outra vez. Desvie do vapor e use as plataformas."],
		["José","O Carcereiro guarda a chave. A corporação prendeu correntes no guardião. Talvez seja possível quebrar esse controle!"],
	],
	"ending":[
		["Carcereiro","As correntes... enfim se partiram. Os executivos me enganaram para guardar seus prisioneiros."],
		["José","Nossas cabeçadas e os poderes de Nico acabaram com isso. Agora ninguém fica preso aqui!"],
		["Carcereiro","A Chave das Profundezas é de vocês. A passagem leva às instalações da corporação. Sigam o símbolo do crachá dourado."],
		["Nico","José está de volta! Vamos reunir a turma, encontrar o Urso e o mico e enfrentar o lobo!"],
	]
}
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	layer=80
	Sfx.begin_dialogue_music(self)
	var hud:=get_parent().get_node_or_null("HUD") as CanvasLayer
	if hud!=null:_old_hud=hud.visible;hud.hide()
	var player:=get_parent().get_node_or_null("Player") as CharacterBody2D
	if player!=null:
		player.elements._hud.hide()
		player._freeze_hud.hide()
	_portraits={"Nico":load("res://world/Arte/Nico/hud_1.png"),"José":load("res://world/Arte/Underworld/jose_portrait_neutral.tres"),"Carcereiro":load("res://world/Arte/Underworld/boss_frame_15.tres")}
	_canvas=Control.new()
	_canvas.size=Vector2(640,360)
	_canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_overlay)
	add_child(_canvas)
	_title=_label("SUBMUNDO  /  "+{"arrival":"UM AMIGO, UMA SAÍDA","temple":"TEMPLO DOS CONTRÁRIOS","ending":"CORRENTES PARTIDAS","launch":"DESCARTE DA CORPORAÇÃO"}[mode],12,Rect2(24,22,600,23),Color("f7bb79"))
	if mode=="launch":
		_lines=[]
		return
	_lines=LINES[mode]
	var panel:=Panel.new()
	panel.position=Vector2(18,224)
	panel.size=Vector2(604,112)
	var style:=Ui.panel_style()
	style.bg_color=Color("211b2c")
	style.border_color=Color("b98760")
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel",style)
	_canvas.add_child(panel)
	_portrait=TextureRect.new()
	_portrait.position=Vector2(30,238)
	_portrait.size=Vector2(72,78)
	_portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait.material=preload("res://world/Scripts/magic_art.gd").material()
	_canvas.add_child(_portrait)
	_speaker=_label("",13,Rect2(115,235,480,22),Color("f7bd83"))
	_line=_label("",13,Rect2(115,262,477,66),Color("f7eee2"))
	_line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_label("E / Enter / Espaço: continuar   ·   ESC: pular",10,Rect2(24,341,590,17),Color("c5acb6"))
	_show_beat()
func _label(text:String,size:int,rect:Rect2,color:Color) -> Label:
	var label:=Ui.label(text,size,color,HORIZONTAL_ALIGNMENT_LEFT)
	label.position=rect.position
	label.size=rect.size
	_canvas.add_child(label)
	return label
func _show_beat() -> void:
	_elapsed=0
	_revealed=false
	_speaker.text=_lines[beat_index][0]
	_line.text=_lines[beat_index][1]
	_line.visible_characters=0
	_portrait.texture=_portraits[_speaker.text]
func _process(delta:float) -> void:
	if has_finished:return
	_clock+=delta
	_elapsed+=delta
	_canvas.queue_redraw()
	if mode=="launch":
		var level:=get_parent()
		var player:CharacterBody2D=level.player
		var t:=clampf((_clock-1.05)/1.6,0,1)
		player.position=Vector2(68+122*t,lerpf(-185,89,t*t))
		player.visible=not (_clock>0.5 and _clock<1.05)
		player.get_node("anim").play("fall" if t>0 else "idle")
		player.get_node("Camera2D").force_update_scroll()
		var cannon:AnimatedSprite2D=level.get_node("Scenery/CorporateCannon")
		var pose:StringName=&"cannon_load" if _clock<0.5 else (&"cannon_charge" if _clock<1.05 else (&"cannon_fire" if _clock<1.2 else (&"cannon_recoil" if _clock<1.45 else (&"cannon_smoke" if _clock<2.1 else &"cannon_idle"))))
		cannon.play(pose)
		if _clock>1.05 and not level.get_meta("cannon_fired",false):
			level.set_meta("cannon_fired",true)
			Sfx.hit()
			Fx.burst(Vector2(60,-174),Color("ffc570"),24,200)
		if _clock>=3.1:_finish()
		return
	if mode=="temple":
		var temple:AnimatedSprite2D=get_parent().get_node("Scenery/Temple")
		var pose:StringName=&"temple_fire" if _clock<1.2 else (&"temple_ice" if _clock<2.4 else (&"temple_both" if _clock<3.6 else (&"temple_opening" if _clock<5 else &"temple_shine")))
		temple.play(pose)
	_line.visible_characters=-1 if _revealed else int(_elapsed*43)
	if _speaker.text=="José":
		_portrait.texture=load("res://world/Arte/Underworld/jose_portrait_talk.tres") if int(_clock*6)%2==0 and _line.visible_characters>=0 else _portraits["José"]
	if auto_progress and _elapsed>maxf(5.5,_line.text.length()/34.0+2.6):_advance()
func _input(event:InputEvent) -> void:
	if has_finished or event.is_echo() or _elapsed<0.25:return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish()
	elif mode!="launch" and (event.is_action_pressed("ui_accept") or event.is_action_pressed("interagir") or (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT)):
		get_viewport().set_input_as_handled()
		if _line.visible_characters>=0 and _line.visible_characters<_line.text.length():_revealed=true
		else:_advance()
func _advance() -> void:
	if beat_index+1>=_lines.size():_finish()
	else:beat_index+=1;_show_beat()
func _finish() -> void:
	if has_finished:return
	has_finished=true
	if mode=="launch":
		get_parent().player.show()
		get_parent().get_node("Scenery/CorporateCannon").play(&"cannon_idle")
	var hud:=get_parent().get_node_or_null("HUD") as CanvasLayer
	if hud!=null: hud.visible=_old_hud
	Sfx.end_dialogue_music(self)
	finished.emit()
	queue_free()
func _draw_overlay() -> void:
	_canvas.draw_rect(Rect2(0,0,640,7),Color("191522"))
	if mode=="launch":
		_canvas.draw_rect(Rect2(0,310,640,50),Color("191522"))
		var w:=clampf((_clock-0.1)/0.4,0,1)
		_canvas.draw_rect(Rect2(0,0,640,360),Color(1,0.7,0.35,maxf(0,0.4-absf(_clock-1.05))*w))

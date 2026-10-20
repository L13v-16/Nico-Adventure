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
var _sky:Control
var _ritual:Node2D
var _panel:Panel
var _ritual_caption:Label
var _continue_hint:Label
var _temple_talk_started:=false
var _escape:Control
const Ui=preload("res://world/Scripts/ui_style.gd")
const LINES={
	"arrival":[
		["José","Nico! A empresa me largou aqui, mas estas grades não seguraram minhas cabeçadas. Ainda precisamos encontrar a saída!"],
		["Nico","José! Um tiro da empresa me derrubou da Arara Minas. Precisamos sair daqui e avisar a turma!"],
		["José","Marque os obstáculos e aperte C. Eu quebro paredes rachadas, derrubo pilares frágeis e empurro blocos pesados."],
		["José","Observe as fendas: rachaduras brilham, pedras tremem e faíscas sobem antes da lava. As marcadas com uma seta azul servem de impulso!"],
		["José","Rochas claras se aproximam; as roxas se afastam. Ajuste a ponte e use as pedras para se proteger dos tridentes. Vamos juntos!"],
	],
	"temple":[
		["José","As chamas e as águas do altar despertaram seu domínio dos contrários! Agora você pode usar fogo e gelo sem frutas."],
		["Nico","Agora consigo lançar fogo e gelo quando quiser! K dispara; Q alterna o elemento. Não preciso gastar frutas."],
		["José","Na forja: fogo na válvula laranja, gelo na azul, fogo e gelo outra vez. Desvie do vapor e use as plataformas."],
		["José","O Carcereiro guarda a chave. A corporação prendeu correntes no guardião. Talvez seja possível quebrar esse controle!"],
	],
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
	_title=_label("SUBMUNDO  /  "+{"arrival":"UM AMIGO, UMA SAÍDA","temple":"ALTAR DOS CONTRÁRIOS","ending":"CORRENTES PARTIDAS","launch":"ATAQUE NO CÉU"}[mode],12,Rect2(24,22,600,23),Color("f7bb79"))
	if mode=="launch":
		_lines=[]
		_title.hide()
		_sky=preload("res://world/Scripts/underworld_sky_attack.gd").new()
		_sky.player=player
		_canvas.add_child(_sky)
		return
	if mode=="ending":
		_lines=[]
		_title.hide()
		_escape=preload("res://world/Scripts/underworld_escape.gd").new()
		_escape.name="MountedEscape"
		_escape.player=player
		_canvas.add_child(_escape)
		return
	_lines=LINES[mode]
	var panel:=Panel.new()
	_panel=panel
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
	_continue_hint=_label("E / Enter / Espaço: continuar   ·   ESC: pular",10,Rect2(24,341,590,17),Color("c5acb6"))
	_show_beat()
	if mode=="temple":
		_ritual=preload("res://world/Scripts/altar_awakening.gd").new()
		_ritual.name="AltarAwakening"
		_ritual.player=player
		_ritual.altar=get_parent().get_node("Scenery/Temple")
		get_parent().add_child(_ritual)
		_ritual_caption=_label("O ALTAR RESPONDE",13,Rect2(35,297,570,28),Color("fff0c9"))
		_ritual_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		_set_temple_panel(false)
		_continue_hint.text="E / Enter / Espaço: avançar animação   ·   ESC: pular"
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
		_sky.update_scene(_clock)
		if _clock>=_sky.DURATION:_finish()
		return
	if mode=="ending":
		_escape.update_scene(_clock)
		if _clock>=_escape.DURATION:_finish()
		return
	if mode=="temple":
		if not _temple_talk_started:
			_ritual.update_scene(_clock)
			_ritual_caption.text="O ALTAR RESPONDE" if _clock<1.1 else ("NICO É ERGUIDO PELA ENERGIA" if _clock<2.4 else ("ÁGUA E CHAMAS GIRAM AO SEU REDOR" if _clock<5.9 else ("O PODER DOS CONTRÁRIOS" if _clock<6.9 else "FOGO E GELO DESPERTARAM")))
			if not _ritual.done:return
			_start_temple_talk()
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
		if mode=="ending":
			_clock=_escape.next_beat(_clock)
			_elapsed=0
			_escape.update_scene(_clock)
			if _clock>=_escape.DURATION:_finish()
			return
		if mode=="temple" and not _temple_talk_started:
			_clock=_ritual.DURATION
			_ritual.update_scene(_clock)
			_start_temple_talk()
			return
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
	_cleanup_ritual()
	_cleanup_escape()
	var hud:=get_parent().get_node_or_null("HUD") as CanvasLayer
	if hud!=null: hud.visible=_old_hud
	Sfx.end_dialogue_music(self)
	finished.emit()
	queue_free()
func _draw_overlay() -> void:
	_canvas.draw_rect(Rect2(0,0,640,7),Color("191522"))
	if mode=="temple" and not _temple_talk_started:
		_canvas.draw_rect(Rect2(0,0,640,360),Color(0.04,0.03,0.08,0.14))
		_canvas.draw_rect(Rect2(0,330,640,30),Color("191522"))
		var flash:=maxf(0,1-absf(_clock-6.45)/0.16)*0.2
		if flash>0:_canvas.draw_rect(Rect2(0,0,640,330),Color(1,0.95,0.8,flash))

func _set_temple_panel(shown:bool) -> void:
	for node in [_panel,_portrait,_speaker,_line]:node.visible=shown

func _start_temple_talk() -> void:
	if _temple_talk_started:return
	_temple_talk_started=true
	_set_temple_panel(true)
	_ritual_caption.hide()
	_continue_hint.text="E / Enter / Espaço: continuar   ·   ESC: pular"
	_show_beat()

func _cleanup_ritual() -> void:
	if is_instance_valid(_ritual):
		_ritual.restore()
		_ritual.queue_free()
		_ritual=null

func _cleanup_escape() -> void:
	if is_instance_valid(_escape):
		_escape.restore()
		_escape.queue_free()
		_escape=null

func _exit_tree() -> void:
	_cleanup_ritual()
	_cleanup_escape()

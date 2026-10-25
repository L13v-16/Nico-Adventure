extends "res://world/Scripts/Corp2D/cutscene.gd"
const ROOM=preload("res://world/Arte/MemoriesV96/control_room.png")
const PLAN=preload("res://world/Arte/MemoriesV96/circus_plan.png")
var _body:Label
var _heading:Label
func _ready() -> void:
	mode="circus";super._ready();_robot.hide()
	_nico.position=Vector2(135,268)
	_wolf=_actor(preload("res://world/Scripts/Corp2D/polish_art.gd").wolf_frames(),73,Vector2(545,260));(_wolf.get_child(0) as AnimatedSprite2D).flip_h=true
	_heading=Label.new();_heading.position=Vector2(24,12);_heading.size=Vector2(592,25);_heading.add_theme_font_size_override("font_size",16);_heading.add_theme_color_override("font_color",Color("b9ffc8"));_canvas.add_child(_heading)
	_body=Label.new();_body.position=Vector2(24,299);_body.size=Vector2(590,45);_body.add_theme_font_size_override("font_size",13);_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_canvas.add_child(_body)
func duration() -> float:return 24.0
func _process(delta:float) -> void:
	clock+=delta
	_heading.text="ARQUIVO CONFIDENCIAL · PROJETO CIRCO"
	var phase:=clampi(int(clock/6),0,3)
	_body.text=["NICO: Um circo em cada ilha? Eles vão derrubar a mata... e usar nossos amigos como atrações!","LOBO LÁZARO, EM GRAVAÇÃO: Cada animal será um espetáculo. As ilhas serão nossa maior fonte de lucro.","NICO: Urso nos testes, Tartaruga na costa, Mico na cobertura... os sequestros eram parte deste plano.","NICO: Provas copiadas! Vamos libertar o Mico e acabar com esse projeto. Nossos amigos vão voltar para casa."][phase]
	_wolf.visible=phase in [1,2];(_wolf.get_child(0) as AnimatedSprite2D).play("windup")
	_nico.position.x=lerpf(95,175,smoothstep(0,3,clock));(_nico.get_child(0) as AnimatedSprite2D).play("run" if clock<3 else "idle")
	if phase!=_cue:_cue=phase;Sfx.play("lab_clink",-14)
	_canvas.queue_redraw()
	if clock>=duration():finish()
func _draw_scene() -> void:
	_canvas.draw_texture_rect(ROOM,Rect2(0,0,640,360),false)
	_canvas.draw_rect(Rect2(0,0,640,360),Color(0,.03,.02,.2))
	var reveal:=smoothstep(1,4,clock)
	_canvas.draw_texture_rect(PLAN,Rect2(180,71,264,176),false,Color(1,1,1,reveal))
	for y in range(72,246,3):_canvas.draw_line(Vector2(181,y),Vector2(443,y),Color(0,.1,.02,.16))
	_canvas.draw_rect(Rect2(0,0,640,42),Color("09151a"));_canvas.draw_rect(Rect2(0,283,640,77),Color("09151a"))
	if clock>18:
		_canvas.draw_rect(Rect2(191,251,240,5),Color("193e2f"));_canvas.draw_rect(Rect2(191,251,240*smoothstep(18,23,clock),5),Color("9fffc0"))
	_canvas.draw_string(ThemeDB.fallback_font,Vector2(450,355),"E / Espaço · continuar",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("a1afbd"))

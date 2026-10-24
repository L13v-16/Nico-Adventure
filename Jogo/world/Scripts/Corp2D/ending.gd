extends "res://world/Scripts/Corp2D/cutscene.gd"
const TOWN=preload("res://world/Arte/CorpV86/town.png")
const PRISON=preload("res://world/Arte/CorpV86/prison.png")
const Polish=preload("res://world/Scripts/Corp2D/polish_art.gd")
var villains:Array[Node2D]=[]
var extras:Array[Node2D]=[]
var _front:Control
var _caption:Label
var _chapter:=0
func _ready() -> void:
	mode="ending";super._ready()
	for data in [[Polish.wolf_frames(),79],[preload("res://world/Arte/Beach/urus.tres"),85],[preload("res://world/Arte/Magic/hyena.tres"),83],[preload("res://world/Arte/Lab/V68/largato.tres"),82]]:
		var node:=_actor(data[0],data[1],Vector2.ZERO);villains.append(node)
		var anim:=node.get_child(0) as AnimatedSprite2D
		anim.play("idle" if anim.sprite_frames.has_animation("idle") else "hurt")
	for path in ["oliver","mico"]:extras.append(_actor(load("res://world/Arte/Friends/V47/"+path+".tres"),51,Vector2.ZERO))
	_front=Control.new();_front.mouse_filter=Control.MOUSE_FILTER_IGNORE;_front.draw.connect(_draw_front);add_child(_front)
	_caption=Label.new();_caption.position=Vector2(23,303);_caption.size=Vector2(594,40);_caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_caption.add_theme_font_size_override("font_size",13);_front.add_child(_caption)
	_update_cast()
func duration() -> float:return 40.0
func _process(delta:float) -> void:
	clock+=delta;_update_cast();_canvas.queue_redraw();_front.queue_redraw()
	if clock>=duration():finish()
func _update_cast() -> void:
	var chapter:=0 if clock<6 else (1 if clock<17 else 2)
	if chapter!=_chapter:
		_chapter=chapter
		if chapter==1:Sfx.play("lab_door",-8)
		else:Sfx.finish()
	_robot.visible=chapter==0;_nico.visible=chapter!=1
	for node in _actors:node.visible=chapter==2
	for node in extras:node.visible=chapter==2
	for i in villains.size():villains[i].visible=chapter==1;villains[i].position=Vector2(128+i*128,248)
	if chapter==0:
		_nico.position=Vector2(155,247);_robot.modulate.a=1-smoothstep(2,5.5,clock)
		_caption.text="O robô caiu. Os arquivos recuperados provaram quem comandava os sequestros."
	elif chapter==1:
		_caption.text="Lobo, Urus, Triple H e Largato: atrás das grades. As ilhas estavam finalmente livres."
	else:
		var t:=clock-17
		_nico.position=Vector2(275,263);_nico.rotation=0
		for i in _actors.size():
			var target:=Vector2([50,125,200,350,425][i],263)
			_actors[i].position=Vector2(-65 if i<3 else 705,263).lerp(target,smoothstep(i*.35,2.4+i*.35,t))
			var anim:=_actors[i].get_child(0) as AnimatedSprite2D
			var moving:bool=t<2.4+i*.35
			var animation:StringName=&"walk" if moving and anim.sprite_frames.has_animation("walk") else &"idle"
			if i==0 and moving:animation=&"fly";_actors[i].position.y-=sin(clampf(t/3,0,1)*PI)*45
			anim.flip_h=i>=3
			if anim.sprite_frames.has_animation(animation):anim.play(animation)
		for i in extras.size():extras[i].position=Vector2(730+i*75,263).lerp(Vector2(500+i*75,263),smoothstep(2,5,t))
		if t>5 and t<7:_nico.position.y-=sin((t-5)*PI)*14
		_caption.text="De volta à cidade, os amigos se reencontraram. Dessa vez, ninguém ficaria para trás."
		if t>8:_caption.text="José: Agora só aceito viagem de férias!   Arara Minas: Sem canhões no caminho, combinado?"
		if t>15:_caption.text="Nico: A melhor parte da aventura é ter vocês de volta. Obrigado por jogar!"
func _unhandled_input(event:InputEvent) -> void:
	if event.is_echo() or clock<.6:return
	if event.is_action_pressed("ui_cancel"):get_viewport().set_input_as_handled();finish()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		if clock<6:clock=6.05
		elif clock<17:clock=17.05
		elif clock<33:clock=33.05
		else:finish()
func _draw_scene() -> void:
	if clock<6:
		_canvas.draw_texture_rect(preload("res://world/Arte/CorpV82/background.png"),Rect2(0,0,640,360),false)
		for x in range(0,640,80):_canvas.draw_texture_rect(Art.cell("props",0),Rect2(x,247,80,32),false)
	else:_canvas.draw_texture_rect(PRISON if clock<17 else TOWN,Rect2(0,0,640,360),false)
func _draw_front() -> void:
	if clock>=6 and clock<17:
		for i in 4:_front.draw_texture_rect(Polish.cell(11),Rect2(72+i*128,125,112,131),false)
	if clock>=22:
		for i in 28:
			var point:=Vector2(fposmod(i*43.7+clock*7,640),fposmod(i*23+clock*13,220)+35)
			_front.draw_rect(Rect2(point,Vector2(2,3)),[Color("ffe89e"),Color("e6a0b9"),Color("8de6ce")][i%3])
	_front.draw_rect(Rect2(0,0,640,34),Color("0b111d"));_front.draw_rect(Rect2(0,282,640,78),Color("0b111d"))
	var title:="FIM DO EXPEDIENTE" if clock<6 else ("JUSTIÇA PELAS ILHAS" if clock<17 else "NICO'S ADVENTURE · JUNTOS EM CASA")
	var font:=ThemeDB.fallback_font
	_front.draw_string(font,Vector2(22,23),title,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("ffe2a1"))
	_front.draw_string(font,Vector2(23,297),"EPÍLOGO",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("e6c27d"))
	_front.draw_string(font,Vector2(350,353),"E / Enter: próxima cena · Esc: pular",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("c5d7d9"))

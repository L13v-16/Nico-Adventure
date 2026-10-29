extends "res://world/Scripts/Corp2D/cutscene.gd"
const TOWN=preload("res://world/Arte/CorpV86/town.png")
const PRISON=preload("res://world/Arte/CorpV86/prison.png")
const Polish=preload("res://world/Scripts/Corp2D/polish_art.gd")
const PORTRAIT=preload("res://world/Arte/Friends/V47/mico_portrait_happy.tres")
const RESCUE_START:=3.0
const RELEASE_AT:=14.0
const PRISON_AT:=19.0
const TOWN_AT:=30.0
var villains:Array[Node2D]=[]
var extras:Array[Node2D]=[]
var _front:Control
var _caption:Label
var _chapter:=-1
var _rescue_saved:=false
var _rescue_cue:=-1
var _mico:Node2D
var _jose:Node2D
var gate_open:=0.0

func _ready() -> void:
	mode="ending";super._ready()
	for data in [[Polish.wolf_frames(),79],[preload("res://world/Arte/Beach/urus.tres"),85],[preload("res://world/Arte/Magic/hyena.tres"),83],[preload("res://world/Arte/Lab/V68/largato.tres"),82]]:
		var node:=_actor(data[0],data[1],Vector2.ZERO);villains.append(node)
		_animate(node,"idle" if (node.get_child(0) as AnimatedSprite2D).sprite_frames.has_animation("idle") else "hurt")
	for path in ["oliver","mico"]:extras.append(_actor(load("res://world/Arte/Friends/V47/"+path+".tres"),51,Vector2.ZERO))
	_mico=extras[1];_jose=_actors[3]
	_front=Control.new();_front.mouse_filter=Control.MOUSE_FILTER_IGNORE;_front.draw.connect(_draw_front);add_child(_front)
	_caption=Label.new();_caption.position=Vector2(23,304);_caption.size=Vector2(594,38);_caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_caption.add_theme_font_size_override("font_size",13);_front.add_child(_caption)
	_update_cast()

func duration() -> float:return 54.0

func _process(delta:float) -> void:
	clock+=delta;_update_cast();_canvas.queue_redraw();_front.queue_redraw()
	if clock>=duration():finish()

func _animate(node:Node2D,animation:StringName,face_left:bool=false) -> void:
	var sprite:=node.get_child(0) as AnimatedSprite2D
	sprite.flip_h=face_left
	if sprite.sprite_frames.has_animation(animation):sprite.play(animation)

func _remember_rescue() -> void:
	if not _rescue_saved:_rescue_saved=Save.set_story_flag("mico_rescued")

func finish() -> void:
	if _done:return
	_remember_rescue()
	super.finish()

func _update_cast() -> void:
	var chapter:=0 if clock<RESCUE_START else (1 if clock<PRISON_AT else (2 if clock<TOWN_AT else 3))
	if chapter!=_chapter:
		_chapter=chapter
		if chapter==2:Sfx.play("lab_door",-8)
		elif chapter==3:Sfx.finish()
	_robot.visible=chapter==0;_nico.visible=chapter!=2
	for node in _actors:node.visible=chapter==3
	for node in extras:node.visible=chapter==3
	for i in villains.size():villains[i].visible=chapter==2;villains[i].position=Vector2(128+i*128,248)
	if chapter==0:
		_nico.position=Vector2(155,247)
		_robot.modulate.a=1-smoothstep(.6,2.9,clock)
		_robot.rotation=sin(clock*13)*.012*(1-smoothstep(0,3,clock))
		_caption.text="O robô caiu. Mas ainda faltava trazer um amigo para casa."
	elif chapter==1:_update_rescue()
	elif chapter==2:
		_remember_rescue()
		_caption.text="As provas dos sequestros chegaram às ilhas. Lobo Lázaro, Urus, Triple H e Largato: atrás das grades."
	else:_update_town()

func _update_rescue() -> void:
	var t:=clock-RESCUE_START
	_mico.show();_jose.show();_nico.rotation=0;_jose.rotation=0
	gate_open=smoothstep(7,9,t)
	_nico.position=Vector2(155,247).lerp(Vector2(335,247),smoothstep(0,3,t))
	_jose.position=Vector2(-55,247).lerp(Vector2(270,247),smoothstep(1,4,t))
	_animate(_nico,"run" if t<3 else "idle")
	_animate(_jose,"walk" if t<4 else "idle")
	_mico.position=Vector2(460,247)
	_animate(_mico,"talk",true)
	_caption.text="Mico-leão-dourado: Nico! Eu sabia que vocês viriam! A trava ainda está ligada."
	if t>=3:
		_caption.text="José: Nico, desligue a trava. Eu abro caminho!"
		_nico.position.x=335+sin(clampf((t-4)/1.5,0,1)*PI)*15
		_animate(_nico,"idle")
		if t>=4 and t<5.5:_nico.rotation=sin((t-4)/1.5*PI)*.12
	if t>=5.5:
		_caption.text="Nico: Trava desligada! José, é com você!"
		_jose.position.x=lerpf(270,405,smoothstep(5.5,7,t))
		_animate(_jose,"charge" if t<7 else ("impact" if t<7.5 else ("recover" if t<8 else "idle")))
		_jose.position.x-=14*smoothstep(7,8,t)
	if t>=7 and _rescue_cue<0:_rescue_cue=0;Sfx.play("lab_clink",-5);Sfx.hit()
	if t>=9:
		var exit_t:=smoothstep(9,11,t)
		_mico.position=Vector2(460,247).lerp(Vector2(285,247),exit_t)
		_mico.position.y-=sin(exit_t*PI)*38
		_animate(_mico,"jump" if exit_t<.5 else ("fall" if exit_t<1 else "happy"),exit_t<1)
		_jose.position.x=lerpf(391,390,smoothstep(9,11,t))
		_caption.text="Mico-leão-dourado: Livre! Eu ouvi a confusão toda daqui. Vocês derrubaram a empresa inteira?"
		if _rescue_cue<1:_rescue_cue=1;Sfx.jump()
	if clock>=RELEASE_AT:
		_remember_rescue()
		_animate(_nico,"idle",true)
		_caption.text="Nico: A gente não ia embora sem você. Agora estamos todos juntos!"
		if _rescue_cue<2:_rescue_cue=2;Sfx.finish()
	if t>13:_caption.text="Mico-leão-dourado: Então vamos para casa. Tenho um abraço guardado para cada um!"

func _update_town() -> void:
	_remember_rescue()
	var t:=clock-TOWN_AT
	_nico.position=Vector2(275,263);_nico.rotation=0;_animate(_nico,"idle")
	for i in _actors.size():
		var target:=Vector2([50,125,200,350,425][i],263)
		_actors[i].rotation=0
		_actors[i].position=Vector2(-65 if i<3 else 705,263).lerp(target,smoothstep(i*.35,2.4+i*.35,t))
		var moving:bool=t<2.4+i*.35
		_animate(_actors[i],"walk" if moving else "idle",i>=3)
		if i==0 and moving:_animate(_actors[i],"fly");_actors[i].position.y-=sin(clampf(t/3,0,1)*PI)*45
	for i in extras.size():
		extras[i].position=Vector2(730+i*75,263).lerp(Vector2(500+i*75,263),smoothstep(2,5,t))
		_animate(extras[i],"walk" if t<5 else ("happy" if i==1 else "idle"),true)
	if t>5 and t<7:_nico.position.y-=sin((t-5)*PI)*14
	_caption.text="De volta à cidade, Mico-leão-dourado reencontrou os amigos. Dessa vez, ninguém ficou para trás."
	if t>8:_caption.text="José: Agora só aceito viagem de férias!   Arara Minas: Sem canhões no caminho, combinado?"
	if t>17:_caption.text="Nico: A melhor parte da aventura é ter vocês de volta. Obrigado por jogar!"

func _unhandled_input(event:InputEvent) -> void:
	if event.is_echo() or clock<.6:return
	if event.is_action_pressed("ui_cancel"):get_viewport().set_input_as_handled();finish()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		for boundary in [RESCUE_START,10.0,RELEASE_AT,PRISON_AT,TOWN_AT,47.0]:
			if clock<boundary:clock=boundary+.05;_update_cast();return
		finish()

func _draw_scene() -> void:
	if clock<PRISON_AT:
		_canvas.draw_texture_rect(preload("res://world/Arte/CorpV82/background.png"),Rect2(0,0,640,360),false,Color("aab2c1"))
		_canvas.draw_rect(Rect2(0,0,640,282),Color(0,0,.03,.28))
		for x in range(0,640,80):_canvas.draw_texture_rect(Art.cell("props",0),Rect2(x,247,80,32),false)
		if clock>=RESCUE_START:
			_canvas.draw_rect(Rect2(405,131,110,116),Color(0,0,0,.3))
			_canvas.draw_set_transform(Vector2(399,247));Polish.deck(_canvas,122,26);_canvas.draw_set_transform(Vector2.ZERO)
			_canvas.draw_texture_rect(Polish.cell(8),Rect2(350,193,32,54),false)
	else:_canvas.draw_texture_rect(PRISON if clock<TOWN_AT else TOWN,Rect2(0,0,640,360),false)

func _draw_front() -> void:
	if clock>=RESCUE_START and clock<PRISON_AT:
		var t:=clock-RESCUE_START
		_draw_gate()
		var status:=Color("92e9c0") if t>=5.5 else Color("ed856c")
		_front.draw_rect(Rect2(362,210,9,6),status)
		_front.draw_string(ThemeDB.fallback_font,Vector2(415,125),"MICO-LEÃO-DOURADO",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("ffe2a1"))
		if t>7 and t<8:
			for i in 8:
				var point:=Vector2(410,208)+Vector2(cos(i*.8),sin(i*.8))*(t-7)*48
				_front.draw_rect(Rect2(point,Vector2(2,2)),Color("ffe2a1"))
		if clock>=RELEASE_AT:
			_front.draw_texture_rect(PORTRAIT,Rect2(24,53,65,65),false)
			_front.draw_string(ThemeDB.fallback_font,Vector2(101,79),"AMIGO RESGATADO",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("92e9c0"))
			_front.draw_string(ThemeDB.fallback_font,Vector2(101,98),"Mico-leão-dourado",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("ffe2a1"))
	if clock>=PRISON_AT and clock<TOWN_AT:
		for i in 4:_front.draw_texture_rect(Polish.cell(11),Rect2(72+i*128,125,112,131),false)
	if clock>=TOWN_AT+5:
		for i in 28:
			var point:=Vector2(fposmod(i*43.7+clock*7,640),fposmod(i*23+clock*13,220)+35)
			_front.draw_rect(Rect2(point,Vector2(2,3)),[Color("ffe89e"),Color("e6a0b9"),Color("8de6ce")][i%3])
	for boundary in [PRISON_AT,TOWN_AT]:
		var opacity:=1-absf(clock-boundary)/.35
		if opacity>0:_front.draw_rect(Rect2(0,34,640,248),Color(0,0,0,opacity))
	_front.draw_rect(Rect2(0,0,640,34),Color("0b111d"));_front.draw_rect(Rect2(0,282,640,78),Color("0b111d"))
	var title:="FIM DO EXPEDIENTE" if clock<RESCUE_START else ("O ÚLTIMO RESGATE" if clock<PRISON_AT else ("JUSTIÇA PELAS ILHAS" if clock<TOWN_AT else "NICO'S ADVENTURE · JUNTOS EM CASA"))
	var font:=ThemeDB.fallback_font
	_front.draw_string(font,Vector2(22,23),title,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("ffe2a1"))
	_front.draw_string(font,Vector2(23,297),"EPÍLOGO",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("e6c27d"))
	_front.draw_string(font,Vector2(350,353),"E / Enter: próxima cena · Esc: pular",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("c5d7d9"))

func _draw_gate() -> void:
	# Fixed masonry and lintel remain in place; the barred door retracts sideways
	# behind the right jamb instead of flattening the entire illustration.
	var texture:=Polish.cell(11)
	var size:=texture.get_size()
	var frame:=Rect2(405,131,110,116)
	var regions:=[Rect2(0,0,.17,1),Rect2(.83,0,.17,1),Rect2(.17,0,.66,.14),Rect2(.17,.91,.66,.09)]
	for uv:Rect2 in regions:
		_front.draw_texture_rect_region(texture,Rect2(frame.position+uv.position*frame.size,uv.size*frame.size),Rect2(uv.position*size,uv.size*size))
	var panel:=Rect2(.17,.14,.66,.77)
	var remain:=1-gate_open
	if remain>.001:
		var destination:=Rect2(frame.position+Vector2(panel.position.x+panel.size.x*gate_open,panel.position.y)*frame.size,Vector2(panel.size.x*remain,panel.size.y)*frame.size)
		_front.draw_texture_rect_region(texture,destination,Rect2(panel.position*size,Vector2(panel.size.x*remain,panel.size.y)*size))

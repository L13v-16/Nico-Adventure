extends CanvasLayer
signal finished
var level:Node2D
var mode:="arrival"
var record_title:=""
var record_text:=""
var clock:=0.0
var _done:=false
var _canvas:Control
var _stage:Node2D
var _nico:Node2D
var _robot:Sprite2D
var _actors:Array[Node2D]=[]
var _old_pause:=false
var _old_intro:=false
var _old_timing:=false
var _old_menu:=false
var _old_hud:=true
var _cue:=-1
const Art=preload("res://world/Scripts/Corp2D/art.gd")
const Friends=preload("res://world/Scripts/magic_art.gd")
const NAMES:=["Arara Minas","Tartaruga","Remi","José","Urso"]
const ACTIONS:=["Eu cuido dos sensores!", "Meu casco segura essa descarga!", "Cabos? Eu conheço um atalho!", "Ninguém segura esta cabeçada!", "Deixem os braços comigo!"]
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;layer=90
	_old_pause=get_tree().paused;_old_intro=level.intro_active;_old_timing=level._timing;_old_menu=level.pause_menu.can_open;_old_hud=level.get_node("HUD").visible
	get_tree().paused=true;level.intro_active=true;level._timing=false;level.pause_menu.can_open=false;level.get_node("HUD").hide();Sfx.begin_dialogue_music(self)
	_canvas=Control.new();_canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE;_canvas.draw.connect(_draw_scene);add_child(_canvas)
	_stage=Node2D.new();add_child(_stage)
	_nico=_actor(level.player.anim.sprite_frames,55,Vector2(145,247));(_nico.get_child(0) as AnimatedSprite2D).play("idle")
	_robot=Art.sprite("robot",3 if mode=="ending" else 0,220,2);_robot.position+=Vector2(465,247);_stage.add_child(_robot)
	if mode in ["friends","ending"]:
		for i in 5:
			var path:String=["Friends/V47/arara","Friends/V47/turtle","Friends/V47/remi","Underworld/jose","Friends/V47/urso"][i]
			var actor:=_actor(load("res://world/Arte/"+path+".tres"),[65,53,53,53,76][i],Vector2(-100-i*70,247))
			_actors.append(actor)
	if mode=="record":_robot.hide();_nico.hide()
func _actor(frames:SpriteFrames,width:float,at:Vector2) -> Node2D:
	var root:=Node2D.new();root.position=at;_stage.add_child(root)
	var sprite:=Friends.actor(frames,width);root.add_child(sprite);sprite.play("idle" if frames.has_animation("idle") else frames.get_animation_names()[0]);Friends.reanchor(sprite);return root
func duration() -> float:
	return {"arrival":8.0,"boss":10.0,"friends":19.0,"ending":17.0,"record":14.0}.get(mode,8.0)
func _process(delta:float) -> void:
	clock+=delta
	if mode=="arrival":_nico.position.x=lerpf(30,180,smoothstep(0,2.5,clock));_robot.modulate=Color(.2,.25,.3,.7)
	elif mode=="boss":
		_robot.position.y=lerpf(-300,247-_robot.texture.get_height()*_robot.scale.y,smoothstep(0,2.3,clock))
		if clock>2.4 and _cue<0:_cue=0;Sfx.play("intro_impact",-8)
	elif mode=="friends":
		_nico.position=Vector2(155-35*smoothstep(0,1,clock),247);_nico.rotation=-PI*.45*smoothstep(.2,1,clock)
		var active_index:=clampi(int((clock-3)/2.6),-1,4)
		for i in _actors.size():
			var t:=clock-3-i*2.6
			var target:=Vector2([465,320,450,385,535][i],[115,247,147,247,247][i])
			_actors[i].position=Vector2(-80,247).lerp(target,smoothstep(0,1.2,t))
			if i in [0,2]:_actors[i].position.y-=sin(clampf(t/1.2,0,1)*PI)*45
			if i==0 and t>2.4:_actors[i].position=target.lerp(Vector2(255,215),smoothstep(2.4,4,t))
			if i==2 and t>2.4:_actors[i].position=target.lerp(Vector2(350,247),smoothstep(2.4,4,t))
			if i==3 and t>1.2 and t<2.4:_actors[i].position.x+=sin((t-1.2)/1.2*PI)*40
			if i==4 and t>1.2:_actors[i].rotation=-.08
			if active_index==i and _cue!=i:
				_cue=i;Sfx.play("lab_clink",-9);_robot.modulate=Color("b9ddf2")
		if clock>16:_nico.rotation=lerpf(-PI*.45,0,smoothstep(16,18,clock));_nico.position.y=247
		if clock>15.8:
			_robot.texture=Art.cell("robot",2,2);_robot.scale=Vector2.ONE*(220.0/_robot.texture.get_width());_robot.position=Vector2(355,247-_robot.texture.get_height()*_robot.scale.y)
	elif mode=="ending":
		for i in _actors.size():_actors[i].position=Vector2(195+i*65,247)
		_robot.modulate.a=1-smoothstep(2,6,clock);_nico.position.x=135
	_canvas.queue_redraw()
	if clock>=duration():finish()
func _unhandled_input(event:InputEvent) -> void:
	if clock<.6:return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled();finish()
func finish() -> void:
	if _done:return
	_done=true;_restore();finished.emit();queue_free()
func _restore() -> void:
	if get_tree()!=null:get_tree().paused=_old_pause
	if is_instance_valid(level) and level.is_inside_tree():
		level.intro_active=_old_intro;level._timing=_old_timing;level.pause_menu.can_open=_old_menu;level.get_node("HUD").visible=_old_hud
	Sfx.end_dialogue_music(self)
func _exit_tree() -> void:
	if not _done:_restore()
func _draw_scene() -> void:
	_canvas.draw_texture_rect(preload("res://world/Arte/CorpV82/background.png"),Rect2(0,0,640,360),false,Color("aab2c1"))
	_canvas.draw_rect(Rect2(0,0,640,360),Color(.015,.02,.04,.3))
	for x in range(0,640,80):_canvas.draw_texture_rect(Art.cell("props",0),Rect2(x,247,80,30),false)
	if mode=="friends":
		var index:=int((clock-3)/2.6)
		if index==0:
			for i in 6:_canvas.draw_line(Vector2(465,115),Vector2(465+cos(i+clock*4)*24,115+sin(i+clock*4)*24),Color("ffe4a0"),2)
		elif index==1:
			_canvas.draw_arc(Vector2(320,230),25,PI,TAU,12,Color("a9edff"),3)
			_canvas.draw_line(Vector2(435,220),Vector2(340,225),Color("92ddff"),3)
		elif index==2:
			for i in 5:_canvas.draw_line(Vector2(455+i*4,150),Vector2(445+i*7,165),Color("ffd188"),2)
		elif index==3:_canvas.draw_arc(Vector2(425,232),25,-PI/2,PI/2,12,Color("ffe2a0"),3)
		elif index==4:_canvas.draw_line(Vector2(525,200),Vector2(560,180),Color("d6c8a8"),4)
	_canvas.draw_rect(Rect2(0,0,640,34),Color("0b111d"));_canvas.draw_rect(Rect2(0,278,640,82),Color("0b111d"))
	var title:="A CORPORAÇÃO DO MAL";var speaker:="NICO";var text:="Chegamos à sede. Desta vez, vamos encerrar os sequestros."
	if mode=="arrival" and clock>3.5:speaker="LOBO · TRANSMISSÃO";text="Visitantes devem retirar uma senha. A sua é: contenção imediata."
	elif mode=="boss":
		title="LOBO · PRESIDENTE EXECUTIVO"
		speaker="LOBO";text="Você tem coragem. Eu tenho um orçamento de defesa."
		if clock>5:speaker="NICO";text="Seus amigos são números nos relatórios. Os meus vieram comigo."
	elif mode=="friends":
		title="NINGUÉM FICA PARA TRÁS"
		if clock<3:speaker="LOBO";text="Fim da sua aventura, pequena amostra."
		elif clock<16:
			var i:=clampi(int((clock-3)/2.6),0,4);speaker=NAMES[i].to_upper();text=ACTIONS[i]
		else:speaker="NICO";text="Eu comecei sozinho. Vamos terminar juntos!"
	elif mode=="ending":
		title="NICO'S ADVENTURE · JUNTOS"
		speaker="ARARA MINAS";text="O sinal caiu. As outras ilhas também estão livres!"
		if clock>5:speaker="JOSÉ";text="Acho que o departamento de sequestros vai fechar."
		if clock>10:speaker="NICO";text="Agora, a próxima viagem é por nossa conta. Obrigado por jogar!"
	elif mode=="record":title=record_title;speaker="ARQUIVO DA CORPORAÇÃO";text=record_text
	var font:=ThemeDB.fallback_font
	_canvas.draw_string(font,Vector2(24,23),title,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("e6c27d"))
	_canvas.draw_string(font,Vector2(24,298),speaker,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("e6c27d"))
	# Label handles wrapping instead of stretching text beyond the letterbox.
	if _canvas.get_node_or_null("Dialogue")==null:
		var label:=Label.new();label.name="Dialogue";label.position=Vector2(24,305);label.size=Vector2(590,35);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",13);_canvas.add_child(label)
	_canvas.get_node("Dialogue").text=text
	_canvas.draw_string(font,Vector2(446,353),"E / Espaço · continuar",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("a1afbd"))


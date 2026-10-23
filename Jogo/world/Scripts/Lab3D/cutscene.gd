extends Node3D
signal finished
const Art=preload("res://world/Scripts/Lab3D/models.gd")
var level:Node3D
var mode:="arrival"
var clock:=0.0
var _camera:Camera3D
var _ui:CanvasLayer
var _canvas:Control
var _cast:Dictionary={}
var _cues:Dictionary={}
var _done:=false
var _old_pause:=false
var _old_hud:=true
var _old_intro:=false
var _old_menu:=true
var _egg:Node3D
var _halves:Array[Node3D]=[]
var _inner:Node3D
var _flat_layer:CanvasLayer
var _flat:Node2D
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	_old_pause=get_tree().paused;_old_intro=level.intro_active;_old_hud=level.hud.visible;_old_menu=level.pause_menu.can_open
	level.intro_active=true;level.hud.hide();level.pause_menu.can_open=false;get_tree().paused=true;Sfx.begin_dialogue_music(self)
	_camera=Camera3D.new();_camera.fov=53;_camera.near=.08;_camera.far=400;add_child(_camera);_camera.make_current()
	_ui=CanvasLayer.new();_ui.layer=90;add_child(_ui);_canvas=Control.new();_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE;_canvas.draw.connect(_draw);_ui.add_child(_canvas)
	if mode=="arrival":_build_arrival()
	if mode in ["arrival","ending"]:
		_flat_layer=CanvasLayer.new();_flat_layer.layer=88;add_child(_flat_layer)
		var backdrop:=ColorRect.new();backdrop.color=Color("183344");backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_flat_layer.add_child(backdrop)
		_flat=preload("res://world/Scripts/Lab3D/dimensional_scene.gd").new();_flat.z_index=50;_flat.ending=mode=="ending";_flat_layer.add_child(_flat)
	_update(0)
func _actor(kind:String,parent:Node3D,at:Vector3,scale:float=1.0) -> Node3D:
	var model:=Art.instantiate(kind);model.position=at;model.scale=Vector3.ONE*scale;parent.add_child(model);_cast[kind]=model;return model
func _build_arrival() -> void:
	_actor("guardian",self,Vector3(0,0,20))
	_actor("nico",self,Vector3(-.6,4.0,20),.9)
	_actor("jose",self,Vector3(.6,4.0,20),.9)
	level.player.model.hide()
	_inner=Node3D.new();_inner.position=Vector3(48,12,-105);add_child(_inner)
	Art.box(_inner,"Floor",Vector3(0,-.2,-2),Vector3(14,.4,14),"405369",.3)
	Art.box(_inner,"Wall",Vector3(0,3,-8),Vector3(14,6,.4),"2a4157")
	for x in [-6,6]:
		Art.box(_inner,"Wall",Vector3(x,3,-2),Vector3(.4,6,12),"4e6577")
		Art.box(_inner,"Light",Vector3(x*.97,4.5,-2),Vector3(.08,.18,10),"89d2d2",0,.6)
		var light:=OmniLight3D.new();light.position=Vector3(x*.6,3,-2);light.light_color=Color("b6ced8");light.omni_range=14;light.light_energy=2;_inner.add_child(light)
	Art.label(_inner,"CORPORAÇÃO / PROJETO EXPERIMENTAL\nCONTENÇÃO: ESTÁVEL",Vector3(0,4.6,-7.65),40,"b9dfc8")
	_actor("wolf",_inner,Vector3(-2.3,0,-1.5),1.25).rotation.y=PI*.85
	_actor("largato",_inner,Vector3(2.1,0,-1.0),1.25).rotation.y=-PI*.85
	Art.cylinder(_inner,"Podium",Vector3(0,.25,-4),1.6,.5,"32465d",-1,.6)
	Art.ring(_inner,"ContainmentRing",Vector3(0,.55,-4),1.5,"91e1c0",.6)
	_egg=Art.instantiate("egg");_egg.position=Vector3(0,.5,-4);_egg.rotation.y=PI;_inner.add_child(_egg)
	var creature:=_actor("mutant",_inner,Vector3(0,.5,-4),.05);creature.rotation.y=PI;creature.hide()
	for side in [-1.0,1.0]:
		var half:=Node3D.new();half.position=Vector3(0,1.8,-4);_inner.add_child(half);half.hide();_halves.append(half)
		var shell:=SphereMesh.new();shell.radius=.85;shell.height=1.1;shell.is_hemisphere=true;shell.radial_segments=12;shell.rings=6
		var piece:=Art.piece(half,"ShellHalf",Vector3.ZERO,shell,"c7c5b2");piece.rotation.z=side*PI/2;piece.scale=Vector3(1.6,1,1)
func duration() -> float:return 15.5 if mode=="arrival" else (7.0 if mode=="boss" else (11.5 if mode=="melt" else 7.0))
func _process(delta:float) -> void:
	clock+=delta;_update(delta)
	if clock>=duration():finish()
func _pose(actor:Node3D,animation:String,delta:float) -> void:
	var player:=actor.get_node_or_null("Animations") as AnimationPlayer
	if player!=null:player.play(animation);player.advance(delta);player.pause()
func _sound(at:float,id:String,volume:float=-10) -> void:
	if clock>=at and not _cues.has(at):_cues[at]=true;Sfx.play(id,volume)
func _view(at:Vector3,target:Vector3) -> void:
	_camera.global_position=at;_camera.look_at(target,Vector3.UP)
func _update(delta:float) -> void:
	if _flat!=null:
		_flat.scale=_canvas.get_viewport_rect().size/Vector2(640,360)
		_flat.update_scene(clock)
		_flat_layer.visible=(clock<5.3 or (clock<6.3 and fposmod(clock*8,1)>.25+(clock-5.3)*.6)) if mode=="arrival" else clock>=.55
	if mode=="arrival":_arrival(delta)
	elif mode=="boss":
		var boss:Node3D=level.boss;boss.model.rotation.y=PI;_pose(boss.model,"operate" if clock>4 else "talk",delta)
		_view(boss.position+Vector3(5-clock*.25,3.2,7),boss.position+Vector3.UP*1.6);_sound(1,"lab_alarm",-12);_sound(4.5,"lab_clink",-8)
	elif mode=="melt":_meltdown(delta)
	else:
		var urso:Node3D=level.rescue_chamber._art.get_node("Urso");_pose(urso,"talk",delta)
		var at:Vector3=urso.global_position;_view(at+Vector3(5,2.4,7),at+Vector3.UP*1.2)
	_canvas.queue_redraw()
func _arrival(delta:float) -> void:
	var monster:Node3D=_cast.guardian
	var approach:=smoothstep(0,2.2,clock);monster.position=Vector3(0,0,lerpf(20,14,approach))
	var charge:=smoothstep(4.4,5.3,clock)
	if clock>=4.4:monster.position.z=lerpf(14,10.3,charge)
	monster.rotation.x=-sin(charge*PI)*.12 if clock<6.3 else 0.0
	var drop:=smoothstep(2.2,3.8,clock)
	_pose(monster,"run" if clock<2.2 or (clock>4.4 and clock<5.3) else ("attack" if clock>=5.3 and clock<5.8 else "idle"),delta*.6)
	# Follow the actual animated shoulder pivots, including the guardian's body bob.
	var left:Node3D=monster.get_node("Rig/ArmL");var right:Node3D=monster.get_node("Rig/ArmR")
	_cast.nico.global_position=(left.global_transform*Vector3(0,.38,0)).lerp(Vector3(-3,0,15),drop)+Vector3.UP*sin(drop*PI)*1.5
	_cast.jose.global_position=(right.global_transform*Vector3(0,.38,0)).lerp(Vector3(3,0,14.5),drop)+Vector3.UP*sin(drop*PI)*1.2
	_pose(_cast.nico,"jump" if drop>0 and drop<1 else "idle",delta);_pose(_cast.jose,"talk",delta)
	if clock>=5.3:
		level.open_service_door();var blast:=clampf(clock-5.3,0,.9)
		for i in 2:
			var side:=-1.0 if i==0 else 1.0;var leaf:Node3D=level.front_door.get_child(i)
			leaf.position=Vector3(side*(1.35+4*blast),maxf(.22,2.4+4*blast-8*blast*blast),3*blast);leaf.rotation=Vector3(blast/.9*PI/2,0,side*blast*.45)
	if clock<6.3:
		_view(Vector3(9,4.8,8).lerp(Vector3(7,3.8,16),smoothstep(2,5.3,clock)),Vector3(0,2.2,lerpf(17,11,smoothstep(2,5.3,clock))))
	else:
		level.open_service_door()
		if clock<14.0:
			var t:=clampf((clock-6)/8,0,1);var focus:Vector3=_inner.global_position+Vector3(0,1.8,-3)
			_view(_inner.global_position+Vector3(4.5-t*2,3.4,4.8-t*2),focus)
			_pose(_cast.wolf,"talk" if clock<8.7 else "hurt",delta);_pose(_cast.largato,"operate" if clock<10.0 else "hurt",delta)
			_egg.rotation.z=sin(clock*31)*.035*smoothstep(6,9.8,clock);_egg.scale=Vector3.ONE*(1+sin(clock*15)*.035)
			if clock>=10.1:
				_egg.hide();var burst:=clampf((clock-10.1)/1.2,0,1)
				_cast.mutant.show();_cast.mutant.scale=Vector3.ONE*lerpf(.35,1.25,burst);_cast.mutant.position=Vector3(0,.5+sin(burst*PI)*.65,-4+burst*1.3);_pose(_cast.mutant,"attack",delta)
				for i in 2:
					_halves[i].show();var side:=-1.0 if i==0 else 1.0;_halves[i].position=Vector3(side*burst*1.7,.6+(1-burst)*1.3,-4);_halves[i].rotation.z=side*burst*1.3
				_cast.wolf.position.x=-2.3-burst*.7;_cast.largato.position.x=2.1+burst*.6
		else:_view(Vector3(-6,3.2,14),Vector3(0,1.4,4));_cast.nico.position=Vector3(0,0,lerpf(13,5,smoothstep(14,15.5,clock)));_pose(_cast.nico,"run",delta)
	if clock>=5.3 and clock<5.9 and Save.is_camera_shake_enabled():_camera.position+=Vector3(sin(clock*90),cos(clock*75),0)*.13
	_sound(4.3,"warden_roar",-10);_sound(5.3,"warden_break",-4);_sound(5.65,"lab_clink",-8);_sound(6.4,"lab_alarm",-8);_sound(9.5,"lab_bubble",-5);_sound(10.1,"lab_splash",-5);_sound(10.3,"warden_roar",-12)
func _meltdown(delta:float) -> void:
	var boss:Node3D=level.boss;var at:Vector3=boss.position
	_view(at+Vector3(4.5-clock*.12,2.5,6),at+Vector3.UP*.9)
	_pose(boss.model,"hurt" if clock<3 else "operate",delta)
	var melt:=smoothstep(2.2,6.5,clock);boss.model.scale=Vector3(1.25+melt*.8,1.25*(1-melt),1.25+melt*.8)
	if not _cast.has("puddle"):
		var puddle:=Art.cylinder(self,"Puddle",at+Vector3.UP*.025,1.7,.05,"81b969");puddle.scale=Vector3.ZERO;_cast.puddle=puddle
		var glasses:=Art.ring(self,"Glasses",at+Vector3(.4,.15,.3),.22,"a1b6c2");glasses.hide();_cast.glasses=glasses
		var tag:=Art.badge(self,at+Vector3(-.45,.14,.35),1.3);tag.rotation.x=PI/2;tag.hide();_cast.badge=tag
	_cast.puddle.scale=Vector3.ONE*melt
	if clock>6.5:boss.model.hide();_cast.glasses.show();_cast.badge.show()
	_sound(.8,"lab_splash",-5);_sound(2.4,"lab_bubble",-8);_sound(5.5,"lab_splash",-10);_sound(6.7,"lab_clink",-7);_sound(7.1,"lab_clink",-12);_sound(9.3,"lab_bubble",-12)
func _words() -> Array[String]:
	if mode=="arrival":
		if clock<3.8:return ["JOSÉ","A entrada está trancada. Grandão, abra caminho!"]
		if clock<6.2:return ["NICO","Esse tremor veio do laboratório inteiro..."]
		if clock<8.5:return ["LOBO DA CORPORAÇÃO","O que foi isso? Eu pedi resultados, não um terremoto!"]
		if clock<10.1:return ["LARGATO","A vibração rompeu a contenção. O experimento está eclodindo!"]
		if clock<12.4:return ["LARGATO","Iniciar protocolo de emergência! Isto... estava quase sob controle."]
		if clock<14:return ["LOBO DA CORPORAÇÃO","Impeça o guaxinim de chegar à cobertura. Eu cuido dos executivos."]
		return ["NICO","Urso está lá dentro. Vamos encontrá-lo!"]
	if mode=="boss":return ["LARGATO","Excelente! A cobaia chegou à cobertura. Seu teste final começa agora." if clock<4 else "Não toque no injetor LG-17. É um procedimento perfeitamente aprovado!"]
	if mode=="ending":return ["URSO","Você voltou por mim! Vamos tirar os outros das mãos da corporação." if clock<4 else "NICO: Ninguém vai ficar para trás. Vamos sair daqui juntos!"]
	return ["LARGATO","Isto não consta... no procedimento..." if clock<3 else ("Meu relatório... e o orçamento..." if clock<6.5 else "A limpeza ficou fora do orçamento.")]
func _draw() -> void:
	var rect:=_canvas.get_viewport_rect();var scale:=rect.size/Vector2(640,360);_canvas.draw_set_transform(Vector2.ZERO,0,scale)
	_canvas.draw_rect(Rect2(0,0,640,27),Color("0e1c2a"));_canvas.draw_rect(Rect2(0,280,640,80),Color("0e1c2a"))
	var distortion:=maxf(0,1-absf(clock-5.8)/.5) if mode=="arrival" else (maxf(0,1-clock/.9) if mode=="ending" else 0.0)
	if distortion>0:
		for i in 13:
			var y:=32+fposmod(i*31+floor(clock*12)*17,241)
			_canvas.draw_rect(Rect2(fposmod(i*83+clock*110,640),y,65+i%4*35,2+i%3),Color(.22,.9,.9,distortion*.38))
		_canvas.draw_string(ThemeDB.fallback_font,Vector2(205,165),"RECONSTRUINDO REALIDADE..." if mode=="arrival" else "REALIDADE RESTAURADA",HORIZONTAL_ALIGNMENT_LEFT,300,11,Color("c5f1e9",distortion))
	var words:=_words();var font:=ThemeDB.fallback_font
	_canvas.draw_string(font,Vector2(20,18),"LABORATÓRIO / "+("A ECLOSÃO" if mode=="arrival" else ("COBERTURA" if mode=="boss" else ("URSO RESGATADO" if mode=="ending" else "PROTOCOLO ENCERRADO"))),HORIZONTAL_ALIGNMENT_LEFT,600,11,Color("eccb87"))
	_canvas.draw_rect(Rect2(20,293,3,41),Color("dfb65e"));_canvas.draw_string(font,Vector2(31,301),words[0],HORIZONTAL_ALIGNMENT_LEFT,590,10,Color("dfb65e"))
	var sentence:String=words[1];var space:=sentence.rfind(" ",72)
	if font.get_string_size(sentence,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x>575 and space>0:
		_canvas.draw_string(font,Vector2(31,320),sentence.left(space),HORIZONTAL_ALIGNMENT_LEFT,580,12,Color("f4e8d0"));_canvas.draw_string(font,Vector2(31,337),sentence.substr(space+1),HORIZONTAL_ALIGNMENT_LEFT,580,12,Color("f4e8d0"))
	else:_canvas.draw_string(font,Vector2(31,323),sentence,HORIZONTAL_ALIGNMENT_LEFT,580,12,Color("f4e8d0"))
	_canvas.draw_string(font,Vector2(477,353),"E / Enter / Esc: pular",HORIZONTAL_ALIGNMENT_LEFT,160,8,Color("9bb7be"))
	var fade:=maxf(1-smoothstep(0,.35,clock),smoothstep(duration()-.4,duration(),clock))
	if fade>0:_canvas.draw_rect(Rect2(0,0,640,360),Color("0e1b29",fade))
func _unhandled_input(event:InputEvent) -> void:
	if clock>.4 and (event.is_action_pressed("interagir") or event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):get_viewport().set_input_as_handled();finish()
func finish() -> void:
	if _done:return
	_done=true
	if mode=="arrival":level.open_service_door();level.player.model.show()
	if mode=="melt":
		level.boss.model.hide()
		for key in ["puddle","glasses","badge"]:
			if _cast.has(key):_cast[key].show();_cast[key].scale=Vector3.ONE;_cast[key].reparent(level)
	if mode=="ending" and _flat_layer!=null:
		# Keep the restored 2D world behind the results, rather than revealing 3D again.
		_flat_layer.show();_flat_layer.layer=0;_flat_layer.reparent(level)
	_restore();finished.emit();queue_free()
func _restore() -> void:
	if get_tree()==null:return
	get_tree().paused=_old_pause
	if is_instance_valid(level):level.intro_active=_old_intro;level.hud.visible=_old_hud;level.pause_menu.can_open=_old_menu;level.camera.make_current();level.snap_camera()
	Sfx.end_dialogue_music(self)
func _exit_tree() -> void:
	if not _done:_restore()

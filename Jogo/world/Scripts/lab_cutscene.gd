extends CanvasLayer
signal finished
var mode:="arrival"
var level:Node2D
var clock:=0.0
var _done:=false
var _canvas:Control
var _stage:Node2D
var _actor:AnimatedSprite2D
var _rig:Node2D
var _nico:AnimatedSprite2D
var _cues:Dictionary={}
var _old_pause:=false
var _old_intro:=false
var _old_timing:=false
var _old_hud:=true
var _old_menu:=true
var _boss_hud:=false
const Art=preload("res://world/Scripts/lab_art.gd")
const FLOOR:=247.0
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;layer=90
	_old_pause=get_tree().paused;_old_intro=level.intro_active;_old_timing=level._timing;_old_hud=level.get_node("HUD").visible;_old_menu=level.pause_menu.can_open
	_boss_hud=level.get_node("Boss")._bar.visible;level.get_node("Boss")._bar.hide()
	get_tree().paused=true;level.intro_active=true;level._timing=false;level.pause_menu.can_open=false;level.get_node("HUD").hide();Sfx.begin_dialogue_music(self)
	var backing:=ColorRect.new();backing.z_index=-30;backing.size=Vector2(640,360);backing.color=Color("151e2c");backing.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(backing)
	_stage=Node2D.new();add_child(_stage)
	var background:=Sprite2D.new();background.texture=Art.texture("background_00" if mode=="arrival" else "background_03");background.centered=false;background.z_index=-10;background.position=Vector2(0,8);background.scale=Vector2(640.0/768,240.0/384);_stage.add_child(background)
	for x in range(0,640,80):
		var floor_art:=Art.prop("floor_00",82,true);floor_art.position+=Vector2(x+40,FLOOR);_stage.add_child(floor_art)
	_nico=Art.Art.actor(level.player.anim.sprite_frames,48);_nico.position+=Vector2(124,FLOOR);_nico.play(&"idle");_stage.add_child(_nico)
	_rig=Node2D.new();_rig.position=Vector2(438,FLOOR);_stage.add_child(_rig)
	if mode=="arrival":_actor=Art.Art.actor(preload("res://world/Arte/Underworld/jose.tres"),64)
	elif mode=="ending":_actor=Art.Art.actor(preload("res://world/Arte/Amigos/urso.tres"),98)
	else:_actor=Art.actor("largato",184)
	_rig.add_child(_actor);_actor.play(&"idle")
	if mode in ["boss","melt"]:
		var machine:=Art.prop("injector",115);machine.position+=Vector2(545,FLOOR);_machine_back(machine)
	_canvas=Control.new();_canvas.z_index=10;_canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE;_canvas.draw.connect(_draw_scene);add_child(_canvas)
	_update_scene()
func _machine_back(machine:Node2D) -> void:_stage.add_child(machine);machine.z_index=-1
func duration() -> float:return 11.5 if mode=="melt" else (9.0 if mode=="boss" else 8.5)
func _process(delta:float) -> void:
	clock+=delta;_update_scene()
	if clock>=duration():finish()
func _sound(at:float,name:String,volume:float=-9) -> void:
	if clock<at or _cues.has(at):return
	_cues[at]=true;Sfx.play(name,volume)
func _update_scene() -> void:
	if mode=="melt":
		var pose:StringName=&"inject" if clock<2.4 else (&"melt1" if clock<4.6 else (&"melt2" if clock<6.8 else (&"coat" if clock<8.8 else &"puddle")))
		_actor.play(pose);Art.Art.reanchor(_actor)
		_rig.position.x=lerpf(438,372,smoothstep(4.6,6.8,clock))
		_sound(1.0,"lab_splash",-5);_sound(2.6,"lab_bubble",-10);_sound(5.0,"lab_splash",-9);_sound(8.25,"lab_clink",-8);_sound(8.85,"lab_clink",-12);_sound(9.6,"lab_bubble",-13)
	elif mode=="boss":
		_rig.position.x=lerpf(610,438,smoothstep(0,1.4,clock));_actor.play(&"run" if clock<1.4 else (&"taunt" if clock<6 else &"shoot"));Art.Art.reanchor(_actor)
		_sound(1.5,"lab_door",-10)
	elif mode=="arrival":_actor.play(&"idle");_actor.flip_h=true
	else:_actor.play(&"idle");_actor.flip_h=true
	_canvas.queue_redraw()
func _unhandled_input(event:InputEvent) -> void:
	if clock<.4:return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled();finish()
func finish() -> void:
	if _done:return
	_done=true;_restore();finished.emit();queue_free()
func _restore() -> void:
	if get_tree()!=null:get_tree().paused=_old_pause
	if is_instance_valid(level) and level.is_inside_tree():
		level.intro_active=_old_intro;level._timing=_old_timing;level.pause_menu.can_open=_old_menu;level.get_node("HUD").visible=_old_hud
		level.get_node("Boss")._bar.visible=_boss_hud and not level.get_node("Boss").is_dead() and not level.get_node("Boss").dying
	Sfx.end_dialogue_music(self)
func _exit_tree() -> void:
	if not _done:_restore()
func _draw_scene() -> void:
	var ink:=Color("101c28");var gold:=Color("b0ecd5");var font:=ThemeDB.fallback_font
	_canvas.draw_rect(Rect2(0,0,640,26),ink);_canvas.draw_rect(Rect2(0,264,640,96),ink)
	var title:="LABORATÓRIO DOS EXECUTIVOS"
	var speaker:="";var line:="";var subline:=""
	if mode=="arrival":
		speaker="JOSÉ" if clock<4.2 else "NICO"
		line="O grandão segura a entrada. Eu cuido da nossa rota de fuga." if clock<4.2 else "Urso está aqui dentro. Vou encontrar a câmara de pesquisa."
		subline="Entrada de serviço · Fogo e gelo continuam disponíveis."
	elif mode=="boss":
		title="LARGATO · DIRETOR DE PESQUISA"
		speaker="LARGATO" if clock<3.4 or clock>6.1 else "NICO"
		line="Excelente! A cobaia demonstrou capacidade de invasão." if clock<3.4 else ("Urso não é uma cobaia. Vou tirar todos daqui!" if clock<6.1 else "Protocolo de contenção! Prefiro estudar você... inteiro.")
		subline="LG-17: estabilizador do enxerto de Largato. Não é uma arma universal."
	elif mode=="ending":
		title="URSO RESGATADO"
		speaker="URSO" if clock<4.3 else "NICO"
		line="Ele chamava aquilo de teste de resistência. Obrigado por voltar." if clock<4.3 else "Vamos sair daqui. Ainda falta trazer nossos amigos para casa."
		subline="A corporação deixou registros de uma próxima instalação."
	else:
		title="PROTOCOLO ENCERRADO"
		speaker="LARGATO" if clock<4.6 else ""
		line="Isso... não consta... no procedimento aprovado..." if clock<2.4 else ("Eu ainda... preciso enviar... o relatório..." if clock<4.6 else "")
		if clock>=8.8:subline="LARGATO · DIRETOR DE PESQUISA"
		if clock>=9.9:subline="A limpeza ficou fora do orçamento."
	_canvas.draw_string(font,Vector2(20,18),title,HORIZONTAL_ALIGNMENT_LEFT,600,11,gold)
	_canvas.draw_rect(Rect2(20,278,3,47),gold)
	_canvas.draw_string(font,Vector2(31,286),speaker,HORIZONTAL_ALIGNMENT_LEFT,590,10,gold)
	_canvas.draw_string(font,Vector2(31,307),line,HORIZONTAL_ALIGNMENT_LEFT,590,12,Color("f3ecdf"))
	_canvas.draw_string(font,Vector2(31,330),subline,HORIZONTAL_ALIGNMENT_LEFT,590,9,Color("aebfca"))
	_canvas.draw_string(font,Vector2(470,352),"E / Enter / Esc: pular",HORIZONTAL_ALIGNMENT_LEFT,170,8,Color("acb6c4"))
	var fade:=1-smoothstep(0,.35,clock)
	if fade>0:_canvas.draw_rect(Rect2(0,0,640,360),Color(ink,fade))

extends CanvasLayer
## Actors reuse the game's atlases. Only this layer animates during the pause.
var boss: Node2D
var kind := "urus"
var clock := 0.0
var _done := false
var _level: Node
var _old_pause := false
var _old_intro := false
var _old_timing := true
var _old_can_open := true
var _old_hud := true
var _canvas: Control
var _actor: AnimatedSprite2D
var _actor_rig: Node2D
var _nico: Node2D
var _cue := false
const SHORE=preload("res://world/Arte/Beach/beach_background.png")
const FOREST=preload("res://world/Arte/Magic/magic_background.png")
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;layer=80
	_level=boss.get_parent()
	_old_pause=get_tree().paused;_old_intro=_level.intro_active;_old_timing=_level._timing
	_old_can_open=_level.pause_menu.can_open;_old_hud=_level.get_node("HUD").visible
	_level.intro_active=true;_level._timing=false;_level.pause_menu.can_open=false
	_level.get_node("HUD").hide();get_tree().paused=true
	Sfx.begin_dialogue_music(self);Sfx.alert()
	_canvas=Control.new();_canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE;_canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_canvas.draw.connect(_draw_scene);add_child(_canvas)
	if kind=="triple":
		_actor_rig=Node2D.new();_canvas.add_child(_actor_rig)
		_actor=preload("res://world/Scripts/magic_art.gd").actor(preload("res://world/Arte/Magic/hyena.tres"),140)
		_actor_rig.add_child(_actor)
	_nico=Node2D.new();_nico.position=Vector2(130,247);_canvas.add_child(_nico)
	var anim:=AnimatedSprite2D.new();anim.name="anim";anim.sprite_frames=_level.player.anim.sprite_frames
	anim.centered=false;anim.position=Vector2(-33,-60);anim.scale=Vector2.ONE*2;anim.play(&"idle");_nico.add_child(anim)
func _process(delta: float) -> void:
	if _done:return
	clock+=delta
	if kind=="triple":
		_actor_rig.position=Vector2(lerpf(690,440,smoothstep(0,1.7,clock)),247-sin(clampf((clock-1.7)/.9,0,1)*PI)*54)
		_actor.play(&"run" if clock<1.7 else (&"leap" if clock<2.6 else &"idle"))
		preload("res://world/Scripts/magic_art.gd").reanchor(_actor)
		_actor.flip_h=false
	_nico.get_node("anim").play(&"hurt" if clock>1.9 and clock<2.25 else &"idle")
	if clock>=2.1 and not _cue:_cue=true;Sfx.swing()
	_canvas.queue_redraw()
	if clock>=6.2:finish()
func _unhandled_input(event: InputEvent) -> void:
	if clock<.3:return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled();finish()
func finish() -> void:
	if _done:return
	_done=true;_restore();queue_free()
func _restore() -> void:
	if get_tree()!=null:get_tree().paused=_old_pause
	if is_instance_valid(_level) and _level.is_inside_tree():
		_level.intro_active=_old_intro;_level._timing=_old_timing
		_level.pause_menu.can_open=_old_can_open;_level.get_node("HUD").visible=_old_hud
	Sfx.end_dialogue_music(self)
func _exit_tree() -> void:
	if not _done:_restore()
func _draw_scene() -> void:
	var ink:=Color("111827") if kind=="urus" else Color("21152f")
	_canvas.draw_rect(Rect2(0,0,640,360),ink)
	_canvas.draw_texture_rect(SHORE if kind=="urus" else FOREST,Rect2(0,31,640,233),false,Color("94aab8") if kind=="urus" else Color("9f83be"))
	_canvas.draw_rect(Rect2(0,31,640,233),Color(ink,.25))
	_canvas.draw_rect(Rect2(0,0,640,31),ink);_canvas.draw_rect(Rect2(0,264,640,96),ink)
	var gold:=Color("f6d39b");var font:=ThemeDB.fallback_font
	if kind=="urus":
		for i in 5:_canvas.draw_line(Vector2(0,145+i*20),Vector2(640,145+i*20),Color("264a61"),1)
		var at:=Vector2(lerpf(710,450,smoothstep(0,2.1,clock)),140+sin(clock*2)*16)
		var frames:Array=boss.flight_frames
		var texture:Texture2D=boss.boss_texture if frames.is_empty() else frames[int(clock*7)%frames.size()]
		_canvas.draw_texture_rect(texture,Rect2(at-Vector2(65,80),Vector2(130,160)),false)
		_canvas.draw_line(Vector2(35,249),Vector2(605,249),Color("d2bd8e"),4)
	else:
		for y in [174,195,216]:_canvas.draw_line(Vector2(32,y),Vector2(606,y),Color("7e579f"),3)
		_canvas.draw_rect(Rect2(24,236,592,13),Color("8b684f"))
	var title:="URUS, O URUBU" if kind=="urus" else "TRIPLE H"
	var subtitle:="O FISCAL DOS CÉUS" if kind=="urus" else "O ÚLTIMO CAMPEÃO DO RINGUE"
	_canvas.draw_string(font,Vector2(28,21),subtitle,HORIZONTAL_ALIGNMENT_LEFT,560,11,gold)
	if clock>1.7:
		_canvas.draw_string(font,Vector2(28,290),title,HORIZONTAL_ALIGNMENT_CENTER,584,21,gold)
		var line:String
		if kind=="urus":line="Urus: Esta ilha tem dono. Quero ver alcançar meu voo!" if clock<3.8 else "Nico: Vou escolher o canhão certo e libertar a Tartaruga!"
		else:line="Triple H: Ninguém sai do meu ringue com o cinturão!" if clock<3.8 else "Nico: Remi vem comigo. Seu barril vai voltar para você!"
		_canvas.draw_string(font,Vector2(22,315),line,HORIZONTAL_ALIGNMENT_CENTER,596,12,Color("f2e8db"))
		_canvas.draw_string(font,Vector2(22,336),"Mira verde: pule no canhão" if kind=="urus" else "Barril: J / X · Socos: por trás · Final: trampolins",HORIZONTAL_ALIGNMENT_CENTER,596,10,Color("bbd6d5"))
	_canvas.draw_string(font,Vector2(428,354),"Enter / E / Esc: pular",HORIZONTAL_ALIGNMENT_RIGHT,188,9,Color("b5abbb"))

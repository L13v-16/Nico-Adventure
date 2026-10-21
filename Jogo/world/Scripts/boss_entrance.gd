extends CanvasLayer
## Self-contained cinematic staging; gameplay actors remain paused and untouched.
const DURATION:=8.2
const GROUND:=244.0
const Art=preload("res://world/Scripts/magic_art.gd")
const SHORE=preload("res://world/Arte/Beach/beach_background.png")
const FOREST=preload("res://world/Arte/Magic/magic_background.png")
const ROPES=preload("res://world/Arte/Magic/V26/rope_middle.tres")
const MAT=preload("res://world/Arte/Magic/V26/mat.tres")
const POST_LEFT=preload("res://world/Arte/Magic/V26/post_left.tres")
const POST_RIGHT=preload("res://world/Arte/Magic/V26/post_right.tres")
const HYENA=preload("res://world/Arte/Magic/hyena.tres")
const ATTACKS=preload("res://world/Arte/Magic/V26/hyena_attacks.tres")
var boss:Node2D
var kind:="urus"
var clock:=0.0
var _done:=false
var _level:Node
var _old_pause:=false
var _old_intro:=false
var _old_timing:=true
var _old_can_open:=true
var _old_hud:=true
var _boss_hud:CanvasLayer
var _old_boss_hud:=false
var _canvas:Control
var _stage:Node2D
var _scenery:Node2D
var _actor:AnimatedSprite2D
var _actor_rig:Node2D
var _nico:Node2D
var _nico_actor:AnimatedSprite2D
var _cannon:AnimatedSprite2D
var _base_scale:=Vector2.ONE
var _cues:Dictionary={}
var _cue:=false
var _impact:=0.0
var _speaker:=""
var _dialogue:=""
var _visible_characters:=0
var _beat:="arrival"

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;layer=80
	_level=boss.get_parent()
	_old_pause=get_tree().paused;_old_intro=_level.intro_active;_old_timing=_level._timing
	_old_can_open=_level.pause_menu.can_open;_old_hud=_level.get_node("HUD").visible
	_boss_hud=boss._hud_layer if kind=="urus" else boss._bar
	_old_boss_hud=_boss_hud.visible;_boss_hud.hide()
	_level.intro_active=true;_level._timing=false;_level.pause_menu.can_open=false
	_level.get_node("HUD").hide();get_tree().paused=true
	Sfx.begin_dialogue_music(self)
	var backing:=ColorRect.new();backing.name="OpaqueBackdrop";backing.size=Vector2(640,360)
	backing.color=Color("101c29") if kind=="urus" else Color("21162d")
	backing.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(backing)
	_stage=Node2D.new();add_child(_stage)
	_scenery=Node2D.new()
	_scenery.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;_scenery.draw.connect(_draw_stage);_stage.add_child(_scenery)
	_actor_rig=Node2D.new();_actor_rig.z_index=2;_stage.add_child(_actor_rig)
	_actor=Art.actor(preload("res://world/Arte/Beach/urus.tres") if kind=="urus" else HYENA,154 if kind=="urus" else 128)
	_actor.material.set_shader_parameter("alpha_cutoff",.94)
	_base_scale=_actor.scale;_actor_rig.add_child(_actor)
	_actor.frame_changed.connect(_sync_actor);_actor.animation_changed.connect(_sync_actor)
	_nico=Node2D.new();_nico.z_index=3;_stage.add_child(_nico)
	_nico_actor=Art.actor(_level.player.anim.sprite_frames,48)
	_nico.add_child(_nico_actor);_nico_actor.play(&"idle")
	if kind=="urus":
		_cannon=Art.actor(preload("res://world/Arte/Beach/cannon.tres"),74)
		_cannon.position+=Vector2(88,GROUND);_cannon.z_index=1;_stage.add_child(_cannon);_cannon.play(&"idle")
	_canvas=Control.new();_canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_overlay);add_child(_canvas)
	_update_scene()
func _process(delta:float) -> void:
	if _done:return
	clock+=delta;_update_scene()
	if clock>=DURATION:finish()
func _sync_actor() -> void:
	_actor.flip_h=kind=="triple" and _actor.animation==&"leap" and _actor.frame==0
	Art.reanchor(_actor)
func _pose(animation:StringName,attack:bool=false) -> void:
	var frames:SpriteFrames=ATTACKS if attack else (HYENA if kind=="triple" else preload("res://world/Arte/Beach/urus.tres"))
	if _actor.sprite_frames!=frames:_actor.sprite_frames=frames;_actor.scale=_base_scale
	_actor.play(animation);_sync_actor()
func _sound(at:float,key:String,volume:float=-8) -> void:
	if clock<at or _cues.has(at):return
	_cues[at]=key;Sfx.play(key,volume)
func _update_scene() -> void:
	var push:=1.0+.018*smoothstep(2.4,5.2,clock)
	_stage.scale=Vector2.ONE*push;_stage.position=Vector2(320,150)*(1-push)
	_nico.position=Vector2(lerpf(142,167,smoothstep(0,.65,clock)),GROUND)
	_nico_actor.play(&"run" if clock<.65 else &"idle")
	_nico_actor.flip_h=false;Art.reanchor(_nico_actor)
	if kind=="urus":
		var travel:=smoothstep(.45,1.7,clock)
		var settle:=smoothstep(1.7,2.5,clock)
		_actor_rig.position=Vector2(lerpf(lerpf(716,374,travel),445,settle),lerpf(120,209,travel)+sin(clock*3.4)*5)
		_pose(&"fly")
		_sound(.48,"intro_wing",-8);_sound(1.24,"intro_wing",-7);_sound(2.0,"intro_wing",-8)
		_sound(2.55,"intro_reveal",-10)
	else:
		if clock<1.15:
			_actor_rig.position=Vector2(lerpf(710,495,smoothstep(0,1.15,clock)),GROUND);_pose(&"run")
		elif clock<1.6:
			_actor_rig.position=Vector2(495,GROUND);_pose(&"windup")
		elif clock<2.35:
			var jump:=clampf((clock-1.6)/.75,0,1)
			_actor_rig.position=Vector2(lerpf(495,441,jump),GROUND-sin(jump*PI)*66);_pose(&"leap")
		elif clock<2.72:
			_actor_rig.position=Vector2(441,GROUND);_pose(&"land")
		else:
			_actor_rig.position=Vector2(441,GROUND);_pose(&"taunt" if clock<5.2 else &"guard",true)
		_impact=maxf(0,1-(clock-2.35)/.6) if clock>=2.35 else 0
		_stage.position.y+=sin(clock*73)*_impact*2
		_nico.position.x-=sin(clampf((clock-2.35)/.4,0,1)*PI)*5
		_sound(.28,"intro_step",-11);_sound(.67,"intro_step",-10);_sound(1.62,"swing",-10)
		_sound(2.35,"intro_impact",-5);_sound(2.7,"intro_ring_bell",-9)
	_cue=clock>=2.35
	_beat="arrival" if clock<2.65 else ("challenge" if clock<5.2 else ("reply" if clock<7.45 else "ready"))
	_speaker=("URUS" if kind=="urus" else "TRIPLE H") if clock<5.2 else "NICO"
	if clock<2.65:_dialogue=""
	elif clock<5.2:_dialogue="Esta ilha tem dono. Tente me alcançar, pequeno!" if kind=="urus" else "Este ringue é meu! Ninguém leva o meu prisioneiro!"
	elif clock<7.45:_dialogue="Então vou subir até você. A Tartaruga vem comigo!" if kind=="urus" else "Remi vem comigo. E seus golpes vão voltar para você!"
	else:_speaker="";_dialogue="PREPARE-SE!"
	var line_start:=2.65 if clock<5.2 else (5.2 if clock<7.45 else 7.45)
	_visible_characters=mini(_dialogue.length(),int(maxf(0,clock-line_start)*42))
	_scenery.queue_redraw();_canvas.queue_redraw()
func _unhandled_input(event:InputEvent) -> void:
	if clock<.35:return
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
		if is_instance_valid(_boss_hud):_boss_hud.visible=_old_boss_hud
	Sfx.end_dialogue_music(self)
func _exit_tree() -> void:
	if not _done:_restore()
func _draw_stage() -> void:
	var bg:Texture2D=SHORE if kind=="urus" else FOREST
	_scenery.draw_rect(Rect2(-20,-10,680,285),Color("152330") if kind=="urus" else Color("221530"))
	var pan:float=lerpf(-10,-22,smoothstep(0,DURATION,clock))
	_scenery.draw_texture_rect(bg,Rect2(pan,8,680,280),false,Color("cad8db") if kind=="urus" else Color("c3abd8"))
	if kind=="urus":
		for i in 12:
			var x:=fposmod(i*63.0+clock*11,680)-20
			_scenery.draw_rect(Rect2(x,170+i%4*16,15,1),Color("bce6d7",.45))
		_scenery.draw_rect(Rect2(-10,GROUND,660,30),Color("bb9865"))
		_scenery.draw_rect(Rect2(-10,GROUND,660,3),Color("eed5a1"))
		for i in 90:_scenery.draw_rect(Rect2((i*61)%650,GROUND+5+i%7*3,2,1),Color("e3bd84"))
		var shade:=maxf(0,1-absf(clock-1.2)/1.1)
		var oval:=PackedVector2Array()
		for point in 20:oval.append(Vector2(_actor_rig.position.x-20+cos(point*TAU/20)*47,GROUND-1+sin(point*TAU/20)*4))
		_scenery.draw_colored_polygon(oval,Color("152333",shade*.45))
	else:
		for x in range(0,640,80):_scenery.draw_texture_rect(MAT,Rect2(x,GROUND,81,27),false)
		for y in [174,194,214]:
			var wobble:=sin(clock*28)*_impact*5
			_scenery.draw_polyline(PackedVector2Array([Vector2(32,y),Vector2(180,y+wobble),Vector2(450,y-wobble),Vector2(609,y)]),Color("534472"),5)
			_scenery.draw_polyline(PackedVector2Array([Vector2(32,y-1),Vector2(180,y-1+wobble),Vector2(450,y-1-wobble),Vector2(609,y-1)]),Color("bea0db"),2)
		_scenery.draw_texture_rect(POST_LEFT,Rect2(16,138,48,108),false)
		_scenery.draw_texture_rect(POST_RIGHT,Rect2(580,138,48,108),false)
		for i in 14:
			var age:=clock-2.35
			if age<0 or age>.65:continue
			var side:float=-1 if i%2==0 else 1
			_scenery.draw_rect(Rect2(441+side*(8+i*3)*age*3,GROUND-3-sin(age/.65*PI)*(4+i%3*3),3,2),Color("e0c5a1",1-age/.65))
		for i in 12:
			var x:=fposmod(i*83.0+clock*(3+i%3),640)
			_scenery.draw_rect(Rect2(x,80+float((i*37)%140),1,2),Color("b6f6e2",.3+.3*sin(clock*2+i)))
func _draw_overlay() -> void:
	var font:=ThemeDB.fallback_font
	var ink:=Color("0d1725") if kind=="urus" else Color("181020")
	var accent:=Color("eacb87") if kind=="urus" else Color("d8a5df")
	_canvas.draw_rect(Rect2(0,0,640,23),ink)
	_canvas.draw_rect(Rect2(0,263,640,97),ink)
	_canvas.draw_rect(Rect2(20,274,3,55),accent)
	if clock>2.35:
		var alpha:=smoothstep(2.35,2.75,clock)
		_canvas.draw_rect(Rect2(20,35,261 if kind=="urus" else 196,52),Color(ink,.88*alpha))
		_canvas.draw_rect(Rect2(20,35,3,52),Color(accent,alpha))
		_canvas.draw_string(font,Vector2(32,57),"URUS, O URUBU" if kind=="urus" else "TRIPLE H",HORIZONTAL_ALIGNMENT_LEFT,270,21,Color(accent,alpha))
		_canvas.draw_string(font,Vector2(32,76),"O FISCAL DOS CÉUS" if kind=="urus" else "O DONO DO RINGUE",HORIZONTAL_ALIGNMENT_LEFT,260,9,Color("eee3cf",alpha))
	if not _dialogue.is_empty():
		_canvas.draw_string(font,Vector2(32,286),_speaker,HORIZONTAL_ALIGNMENT_LEFT,560,10,accent)
		_canvas.draw_string(font,Vector2(32,308),_dialogue.left(_visible_characters),HORIZONTAL_ALIGNMENT_LEFT,580,13,Color("f4ecdf"))
		var hint:="Mira verde: pule no canhão certo." if kind=="urus" else "Rebata barris · Acerte por trás · Use os trampolins."
		_canvas.draw_string(font,Vector2(32,330),hint,HORIZONTAL_ALIGNMENT_LEFT,580,9,Color("b5c4ca"))
	_canvas.draw_string(font,Vector2(24,16),"PRAIA DAS MARÉS" if kind=="urus" else "FLORESTA VIOLETA",HORIZONTAL_ALIGNMENT_LEFT,400,9,Color("c8c7cd"))
	_canvas.draw_string(font,Vector2(426,351),"Enter / E / Esc: pular",HORIZONTAL_ALIGNMENT_RIGHT,188,9,Color("aaa4b5"))
	var fade:=1-smoothstep(0,.3,clock)
	if clock>7.95:fade=maxf(fade,smoothstep(7.95,DURATION,clock))
	if fade>0:_canvas.draw_rect(Rect2(0,0,640,360),Color(ink,fade))

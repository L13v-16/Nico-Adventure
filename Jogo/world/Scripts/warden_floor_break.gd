extends CanvasLayer
## The arena collapses into the cannon tower; gameplay remains paused throughout.
const DURATION:=8.0
const Art=preload("res://world/Scripts/underworld_art.gd")
const Tiles=preload("res://world/Scripts/underworld_tiles.gd")
const CAVE=preload("res://world/Arte/Underworld/V36/background.png")
var boss:CharacterBody2D
var clock:=0.0
var done:=false
var revealed:=false
var impacted:=false
var canvas:Control
var front:Control
var cast:Node2D
var guardian:AnimatedSprite2D
var nico:AnimatedSprite2D
var jose:AnimatedSprite2D
var _level:Node2D
var _old_pause:=false
var _old_timing:=true
var _old_intro:=false
var _old_menu:=true
var _old_smoothing:=true
var _visibility:Dictionary={}

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;layer=80
	_level=boss.get_parent();_old_pause=get_tree().paused
	_old_timing=_level._timing;_old_intro=_level.intro_active;_old_menu=_level.pause_menu.can_open
	_level._timing=false;_level.intro_active=true;_level.pause_menu.can_open=false
	var camera:Camera2D=boss._player.get_node("Camera2D")
	_old_smoothing=camera.position_smoothing_enabled;camera.position_smoothing_enabled=false
	for actor in [boss,boss._player,_level.get_node("Jose"),boss.cylinder,_level.get_node("HUD"),boss._bar,boss._player.elements._hud,boss._player._freeze_hud]:
		_visibility[actor]=actor.visible;actor.hide()
	get_tree().paused=true;Sfx.begin_dialogue_music(self)
	canvas=Control.new();canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE
	canvas.material=preload("res://world/Scripts/magic_art.gd").material()
	canvas.material.set_shader_parameter("alpha_cutoff",.94)
	canvas.draw.connect(_draw_scene);add_child(canvas)
	cast=Node2D.new();canvas.add_child(cast)
	guardian=AnimatedSprite2D.new();guardian.sprite_frames=boss._sprite.sprite_frames
	guardian.centered=false;guardian.material=boss._sprite.material;cast.add_child(guardian)
	guardian.scale=boss._normal_scale*1.35
	# The live actor uses the same sole contacts, including the cropped frames.
	guardian.frame_changed.connect(_anchor_guardian);guardian.animation_changed.connect(_anchor_guardian)
	nico=AnimatedSprite2D.new();nico.sprite_frames=boss._player.anim.sprite_frames
	nico.centered=false;nico.position=Vector2(170,216);nico.scale=Vector2.ONE*1.15;cast.add_child(nico)
	jose=Art.actor("jose",38);cast.add_child(jose);jose.position+=Vector2(126,246)
	front=Control.new();front.mouse_filter=Control.MOUSE_FILTER_IGNORE
	front.draw.connect(_draw_overlay);canvas.add_child(front)
	update_scene(0)

func _anchor_guardian() -> void:
	var texture:Texture2D=guardian.sprite_frames.get_frame_texture(guardian.animation,guardian.frame)
	var foot:float=boss.BOOT_FEET.get_meta("feet").get(texture.resource_path,texture.get_height())
	guardian.position=Vector2(414-texture.get_width()*.5*guardian.scale.x,246-foot*guardian.scale.y)

func update_scene(time:float) -> void:
	if done:return
	clock=clampf(time,0,DURATION)
	var camera:Camera2D=boss._player.get_node("Camera2D")
	boss._player._camera_base_offset=Vector2(7145,-270)-boss._player.position
	camera.offset=boss._player._camera_base_offset;camera.zoom=Vector2.ONE*.74
	camera.force_update_scroll()
	guardian.play(&"roar" if clock<1.25 else (&"windup" if clock<2.4 else (&"slam" if clock<3.05 else &"exposed")))
	_anchor_guardian()
	var fall:=maxf(0,clock-3.05)
	cast.position=Vector2(sin(clock*49)*2.5 if clock>=2.4 and clock<3.1 else 0,fall*fall*82)
	nico.play(&"idle" if clock<2.4 else &"jump")
	jose.play(&"idle" if clock<2.4 else &"jump")
	Art.Base.reanchor(jose)
	if clock>=2.4 and not impacted:
		impacted=true;Sfx.play("warden_slam",-3);Sfx.play("warden_break",-4)
	if clock>=3.15 and not has_meta("fall_sound"):
		set_meta("fall_sound",true)
		var sound:=AudioStreamPlayer.new();sound.stream=Sfx._streams["sky_fall"]
		sound.bus="SFX";sound.volume_db=-6;add_child(sound);sound.play()
	if clock>=5.2 and not revealed:
		revealed=true;cast.hide();_show_world()
	canvas.queue_redraw();front.queue_redraw()

func _process(delta:float) -> void:
	update_scene(clock+delta)
	if clock>=DURATION:finish()

func _show_world() -> void:
	_stage_companion()
	for actor in [boss,boss._player,_level.get_node("Jose"),boss.cylinder]:
		if is_instance_valid(actor):actor.visible=bool(_visibility.get(actor,true))
	boss._player.anim.play(&"idle")

func _stage_companion() -> void:
	var companion:CharacterBody2D=_level.get_node("Jose")
	companion.position=Vector2(6915,boss.UPPER_FLOOR);companion.velocity=Vector2.ZERO
	companion.state="idle";companion._target=null;companion._safe_spot=companion.position
	companion._sprite.flip_h=false;companion._sprite.play(&"idle")

func _unhandled_input(event:InputEvent) -> void:
	if clock<.3 or event.is_echo():return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled();finish()

func finish() -> void:
	if done:return
	done=true;_restore();queue_free()

func _restore() -> void:
	if get_tree()!=null:get_tree().paused=_old_pause
	Sfx.end_dialogue_music(self)
	if not is_instance_valid(_level) or not _level.is_inside_tree():return
	for actor in _visibility:
		if is_instance_valid(actor):actor.visible=_visibility[actor]
	_level._timing=_old_timing;_level.intro_active=_old_intro;_level.pause_menu.can_open=_old_menu
	if is_instance_valid(boss) and is_instance_valid(boss.cylinder):
		boss.cylinder._recover()
		boss._player._cancel_attack();boss._player._jump_buffer_timer=0
		boss._player._spring_lock=0;boss._player._hitstun_timer=0
		boss._player.anim.play(&"idle")
		_stage_companion()
		var camera:Camera2D=boss._player.get_node("Camera2D")
		camera.position_smoothing_enabled=_old_smoothing;camera.reset_smoothing();camera.force_update_scroll()
		boss._update_bar();boss._bar.show()

func _exit_tree() -> void:
	if not done:_restore()

func _draw_scene() -> void:
	if clock<5.2:
		canvas.draw_texture_rect(CAVE,Rect2(0,-22,640,360),false,Color("c1adbd"))
		for i in 20:
			var fall:=maxf(0,clock-2.65-absf(i-13)*.035)
			var y:=246+fall*fall*(72+i%3*18)
			Tiles.platform(canvas,Rect2(i*32,y,32,18))
			Tiles.tile(canvas,Rect2(i*32,y+18,32,32),4+i%4)
		if clock>=1.25 and clock<3.3:
			var reach:=smoothstep(1.25,2.75,clock)*360
			for side in [-1.0,1.0]:
				var points:=PackedVector2Array([Vector2(414,246),Vector2(414+side*reach*.3,250),Vector2(414+side*reach*.45,243),Vector2(414+side*reach*.7,252),Vector2(414+side*reach,247)])
				canvas.draw_polyline(points,Color("201726"),4)
				canvas.draw_polyline(points,Color("ffc078"),1)
func _draw_overlay() -> void:
	front.draw_rect(Rect2(0,0,640,29),Color("100e19"))
	front.draw_rect(Rect2(0,281,640,79),Color("100e19"))
	front.draw_string(ThemeDB.fallback_font,Vector2(24,20),"O CHÃO NÃO VAI SEGURAR!" if clock<5.2 else "A TORRE SOB A ARENA",HORIZONTAL_ALIGNMENT_LEFT,560,12,Color("ffd398"))
	var line:="Carcereiro: Então caiam com a minha prisão!" if clock<2.4 else ("Nico: José, cuidado! O chão está desabando!" if clock<5.2 else "José: Aqueles canhões! Fogo, gelo e fogo. Mire neles, Nico!")
	front.draw_string(ThemeDB.fallback_font,Vector2(24,308),line,HORIZONTAL_ALIGNMENT_CENTER,592,12,Color("f4e5d9"))
	front.draw_string(ThemeDB.fallback_font,Vector2(24,332),"K: disparar · Q: alternar elemento" if clock>=5.2 else "",HORIZONTAL_ALIGNMENT_CENTER,592,10,Color("c4dceb"))
	front.draw_string(ThemeDB.fallback_font,Vector2(420,350),"Enter / E / Esc: pular",HORIZONTAL_ALIGNMENT_RIGHT,190,9,Color("bba8ba"))
	var fade:=maxf(0,1-absf(clock-5.2)/.65)
	if fade>0:front.draw_rect(Rect2(0,29,640,252),Color(.06,.04,.1,fade))
	var flash:=maxf(0,1-absf(clock-2.4)/.2)*.3
	if flash>0:front.draw_rect(Rect2(0,29,640,252),Color(1,.65,.3,flash))

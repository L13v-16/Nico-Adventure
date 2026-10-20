extends Node2D
## Encenação sobre o mapa real, com ataques visuais de Nico e roupas equipadas.
const DURATION:=7.4
const BEATS:=[0.0,1.1,1.65,2.7,3.3,4.4,5.7,6.6,DURATION]
var player:CharacterBody2D
var jose:CharacterBody2D
var cage:Node2D
var clock:=0.0
var stage:="approach"
var done:=false
var _old_camera:Camera2D
var _camera:Camera2D
var _old_mode:=0
var _old_z:=0
var _cues:Dictionary={}
var _restored:=false
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	_old_mode=player.process_mode;_old_z=player.z_index
	player.process_mode=Node.PROCESS_MODE_ALWAYS;player.set_physics_process(false);player.z_index=5
	player._cancel_attack();player._facing=1;player._attack_facing=1;player.velocity=Vector2.ZERO
	jose.hide()
	_old_camera=get_viewport().get_camera_2d()
	_camera=Camera2D.new();_camera.name="CageRescueCamera";_camera.position=Vector2(260,35);_camera.zoom=Vector2.ONE*1.8
	add_child(_camera);_camera.make_current()
	update_scene(0)
func next_beat(time:float) -> float:
	for beat in BEATS:
		if beat>time+.1:return beat
	return DURATION
func _cue(name:String,at:float,callback:Callable) -> void:
	if clock>=at and not _cues.has(name):_cues[name]=true;callback.call()
func update_scene(time:float) -> void:
	if _restored:return
	clock=time
	stage="approach" if time<1.05 else ("strike" if time<3.65 else ("lowering" if time<5.2 else ("opening" if time<5.8 else "free")))
	cage.set_pose(time)
	var x:=lerpf(190,246,smoothstep(0,.85,time))
	var foot:=100.0
	var pose:StringName=&"run" if time<.85 else &"idle"
	for jump_at in [1.05,2.65]:
		var progress:=clampf((time-jump_at)/1.0,0,1)
		if progress>0 and progress<1:
			foot-=sin(progress*PI)*60
			pose=&"jump" if progress<.5 else &"fall"
	if time>3.8:x=lerpf(246,190,smoothstep(3.8,4.45,time));pose=&"run" if time<4.45 else &"idle"
	player.position=Vector2(x,foot-11).round()
	player.anim.flip_h=time>3.8 and time<4.45;player.anim.play(pose)
	player._attack_elapsed=-1
	player._hit_flash_timer=0
	for impact in [1.55,3.15]:
		var swing:float=time-(float(impact)-float(player.ATTACK_WINDUP)-.04)
		if swing>=0 and swing<float(player.ATTACK_DURATION):player._attack_elapsed=swing
		player._hit_flash_timer=maxf(player._hit_flash_timer,maxf(0,.1-absf(time-impact)))
	player._squash=0;player._update_combat_visuals()
	_cue("jump1",1.05,func():Sfx.jump())
	_cue("swing1",1.4,func():Sfx.swing())
	_cue("hit1",1.55,func():Sfx.hit();Sfx.play("warden_chain",-14))
	_cue("land1",2.05,func():Sfx.land(.35))
	_cue("jump2",2.65,func():Sfx.jump())
	_cue("swing2",3.0,func():Sfx.swing())
	_cue("hit2",3.15,func():Sfx.hit();Sfx.play("warden_break",-13))
	_cue("land2",3.65,func():Sfx.land(.4))
	_cue("lower",3.7,func():Sfx.play("warden_chain",-16))
	_cue("ground",5.15,func():Sfx.land(.6))
	_cue("open",5.65,func():Sfx.secret())
	if time>=DURATION:complete()
func complete() -> void:
	if done:return
	done=true
	cage.release()
	player.position=Vector2(190,89);player.velocity=Vector2.ZERO
	player._cancel_attack();player._hit_flash_timer=0;player._update_combat_visuals();player.anim.play(&"idle")
	jose.position=Vector2(225,100);jose.velocity=Vector2.ZERO;jose._sprite.flip_h=true;jose._sprite.play(&"idle");jose.show()
	restore()
func restore() -> void:
	if _restored:return
	_restored=true
	if is_instance_valid(player):
		player._cancel_attack();player._hit_flash_timer=0;player._update_combat_visuals()
		player.process_mode=_old_mode;player.set_physics_process(false);player.z_index=_old_z
	if is_instance_valid(_old_camera):_old_camera.make_current();_old_camera.force_update_scroll()
	if is_instance_valid(_camera):_camera.queue_free()
func _exit_tree() -> void:restore()

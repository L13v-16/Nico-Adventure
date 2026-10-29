extends Node2D
## Arena contínua inspirada no ritmo de Mecha-Bandicoot: correr, saltar, devolver.
const Hazard=preload("res://world/Scripts/warden_ring_hazard.gd")
const Tiles=preload("res://world/Scripts/underworld_tiles.gd")
const RingArt=preload("res://world/Scripts/warden_ring_art.gd")
var boss:CharacterBody2D
var beat:="rest"
var clock:=0.0
var drops:=0
var next_drop:=0.0
var cycle_step:=0
var break_flash:=0.0
var _rear:Node2D
func _ready() -> void:
	z_index=2
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_rear=Node2D.new();_rear.z_index=-4;add_child(_rear)
	_rear.material=preload("res://world/Scripts/magic_art.gd").material()
	_rear.material.set_shader_parameter("alpha_cutoff",.94)
	_rear.draw.connect(_draw_rear)
func _physics_process(delta:float) -> void:
	break_flash=maxf(0,break_flash-delta)
	queue_redraw()
	_rear.queue_redraw()
func schedule() -> Array[String]:
	if boss._phase2_parries<2:return ["pincer","charge","pulse","charge","sweep","charge","rain","charge"]
	if boss._phase2_parries<4:return ["fissures","charge","rain","charge"]
	return ["charge"]

func _wave(x:float,side:float,speed:float,warning:float) -> void:
	var wave:=Hazard.new()
	wave.boss=boss;wave.kind="sweep";wave.direction=side
	wave.speed=speed;wave.warning_time=warning
	wave.position=Vector2(x,boss.arena_floor_y())
	get_parent().add_child(wave)

func _has_hazards() -> bool:
	for hazard in get_tree().get_nodes_in_group("warden_ring_hazards"):
		if not hazard.is_queued_for_deletion():return true
	return false

func _pulse_pair() -> void:
	_wave(boss.position.x-30,-1,225,1.1)
	_wave(boss.position.x+30,1,225,1.1)
	Sfx.play("warden_chain",-13)
func tick(delta:float) -> void:
	if boss._parry_stun>0:return
	clock+=delta
	match beat:
		"rest":
			if boss._timer<=0:
				var moves:=schedule()
				begin_beat(moves[cycle_step%moves.size()])
		"rain":
			if drops<4 and clock>=next_drop:
				var shot:=Hazard.new()
				shot.boss=boss;shot.kind="rain"
				shot.position=Vector2(clampf(boss._player.position.x,6500,7420),boss.arena_floor_y())
				get_parent().add_child(shot)
				drops+=1;next_drop+=.7
				Sfx.play("warden_chain",-16)
			if clock>=4.0:finish_beat(.65)
		"sweep":
			if clock>=4.8:finish_beat(.65)
		"pincer":
			if clock>=4.8 and not _has_hazards():finish_beat(.9)
		"pulse":
			if drops==1 and clock>=1.45:
				_pulse_pair();drops=2
			if clock>=4.8 and not _has_hazards():finish_beat(.9)
		"fissures":
			if clock>=2.5 and not _has_hazards():finish_beat(.9)
		"charge":
			if clock>=1.25:
				boss._cast_chain()
				beat="orb";clock=0
		"orb":
			# Não mistura a próxima chuva com uma esfera ainda em voo.
			if clock>1 and get_tree().get_nodes_in_group("underworld_projectiles").is_empty():finish_beat(1.1)
func begin_beat(value:String) -> void:
	beat=value;clock=0;drops=0;next_drop=0
	boss._clear_projectiles()
	Sfx.alert()
	if value=="sweep":
		var side:=1.0 if boss._player.position.x<boss.ARENA_CENTER else -1.0
		_wave(6490 if side>0 else 7430,side,255,.95)
	elif value=="pincer":
		_wave(6490,1,200,1.2);_wave(7430,-1,200,1.2)
	elif value=="pulse":
		_pulse_pair();drops=1
	elif value=="fissures":
		# Lock the three marks now, leaving generous gaps and open flanks.
		var center:=clampf(boss._player.position.x,6640,7280)
		for offset in [-112.0,0.0,112.0]:
			var fissure:=Hazard.new()
			fissure.boss=boss;fissure.kind="fissure"
			fissure.warning_time=1.4;fissure.position=Vector2(center+offset,boss.arena_floor_y())
			get_parent().add_child(fissure)
		Sfx.play("warden_fire_charge",-12)
	elif value=="charge":Sfx.play("warden_ice_charge",-10)
func finish_beat(wait:float) -> void:
	beat="rest";clock=0;cycle_step+=1;boss._timer=wait
func on_return() -> void:
	# A successful counter always grants a clean recovery, even on a late shot.
	boss._clear_projectiles()
	var hits:int=boss._phase2_parries
	if hits==2 or hits==4:
		break_flash=1.4
		Sfx.play("warden_break",-6)
		boss._player.heal_one()
		Fx.popup(boss.position+Vector2(0,-150),"SELO DA VARREDURA QUEBRADO!" if hits==2 else "SELO DA CHUVA QUEBRADO!",Color("d9ffc5"),9)
		boss._clear_projectiles()
		boss._player._invulnerability_timer=maxf(1.5,boss._player._invulnerability_timer)
		finish_beat(2.4)
		cycle_step=0
	else:finish_beat(2.2)
func advice() -> String:
	if boss._phase2_parries>=7:return "SELOS QUEBRADOS · O piso leva você ao patamar"
	if boss._parry_stun>0:
		if boss._phase2_parries>=4:return "DOIS SELOS QUEBRADOS · Devolva as últimas esferas!"
		return "ACERTOU! · Máximo de 1 acerto por atordoamento"
	match beat:
		"rain":return "CHUVA DE FERRAGENS · Corra para sair das miras laranjas"
		"sweep":return "CORRENTE RASTEIRA · Pule por cima da varredura"
		"pincer":return "PINÇA DE CORRENTES · Pule as correntes dos dois lados"
		"pulse":return "DUAS ONDAS DO CENTRO · Espere e pule uma de cada vez"
		"fissures":return "FENDAS MARCADAS · Saia dos círculos antes das correntes subirem"
		"charge":return "ESFERA VERDE · Prepare J / X para devolver"
		"orb":return "J / X REBATE A ESFERA VERDE · Acerte de frente!"
	return "CORRA · PULE · DEVOLVA · %d / 7" % boss._phase2_parries
func guardian_pose() -> StringName:
	match beat:
		"rain":return &"ring_rain"
		"sweep":return &"ring_sweep_ready" if clock<.95 else &"ring_sweep_release"
		"pincer":return &"ring_sweep_ready" if clock<1.2 else &"ring_sweep_release"
		"pulse":return &"ring_rain" if clock<1.1 or (clock>=1.45 and clock<2.55) else &"ring_sweep_release"
		"fissures":return &"windup" if clock<1.4 else &"slam"
		"charge":return &"ring_charge"
		"orb":return &"ring_cast"
	return &"ring_rest"
func _draw() -> void:
	if not is_instance_valid(boss) or not boss.active or boss.phase!=2:return
	for i in 2:
		var at:=boss.position+Vector2(-67 if i==0 else 67,-85)
		var actor:AnimatedSprite2D=boss._sprite
		var frame:Texture2D=actor.sprite_frames.get_frame_texture(actor.animation,actor.frame)
		var key:="seal_left" if i==0 else "seal_right"
		if frame.has_meta(key):
			var anchor:Vector2=frame.get_meta(key)
			anchor.x*=-1 if actor.flip_h else 1
			at=boss.position+anchor*actor.scale
		var destroyed:bool=boss._phase2_parries>=(2 if i==0 else 4)
		var cracked:bool=boss._phase2_parries>=(1 if i==0 else 3)
		RingArt.draw_sprite(self,14 if destroyed else (13 if cracked else 12),at,52)
		if destroyed and break_flash>0:RingArt.draw_sprite(self,15,at,52+(1.4-break_flash)*24,false,Color(1,1,1,break_flash/1.4))
func _draw_rear() -> void:
	if not is_instance_valid(boss) or not boss.active or boss.phase!=2:return
	var floor_y:float=boss.arena_floor_y()
	# Mureta de basalto curva, atrás do guardião e apoiada no piso inteiro.
	for i in 49:
		var a:=PI+PI*i/48.0
		var p:=Vector2(boss.ARENA_CENTER+cos(a)*450,floor_y-7+sin(a)*32).round()
		Tiles.platform(_rear,Rect2(p-Vector2(15,0),Vector2(30,12)))
		Tiles.tile(_rear,Rect2(p+Vector2(-15,12),Vector2(30,maxf(1,floor_y-p.y))),4+i%4)

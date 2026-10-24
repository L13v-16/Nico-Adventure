extends Node2D
signal defeated
var level:Node2D
var active:=false
var dead:=false
var dying:=false
var phase:=1
var health:=3
var vulnerable:=0.0
var _timer:=2.5
var _state:="wait"
var _attack:=0
var _heat:=false
var _cold:=false
var _hurt:=0.0
var _window_hit:=false
var _target_x:=0.0
var _friends_seen:=false
var _sprite:Sprite2D
var core:StaticBody2D
var steps:Array[Node2D]=[]
const Art=preload("res://world/Scripts/Corp2D/art.gd")
func _ready() -> void:
	_sprite=Art.sprite("robot",0,320,2);_sprite.z_index=1;add_child(_sprite)
	core=preload("res://world/Scripts/Corp2D/core.gd").new();core.boss=self;core.position=Vector2(0,-24);add_child(core)
func begin() -> void:
	if active or dead:return
	active=true
	if level.player.position.x<8480:level.player.position=Vector2(8480,89);level.player.velocity=Vector2.ZERO
	level.player.set_checkpoint(Vector2(8480,89));level.player.heal_full();_timer=2.8
	level.tell("Espere o golpe: o núcleo fica exposto depois da onda de impacto.")
func _physics_process(delta:float) -> void:
	if not active or dead or level.intro_active or level.player.is_dead():return
	_hurt=maxf(0,_hurt-delta);vulnerable=maxf(0,vulnerable-delta);_timer-=delta
	_sprite.modulate=Color("ffbeae") if _hurt>0 else Color.WHITE
	core.position=Vector2(-50,-240) if phase==3 else Vector2(0,-24)
	if phase==2 and _heat and _cold and vulnerable<=0:
		open_window(3.5);_heat=false;_cold=false
		for node in get_tree().get_nodes_in_group("corp_devices"):
			if node.link=="boss":node.activated=false
	if _timer<=0:
		match _state:
			"wait":
				_attack+=1;_state="warning";_timer=1.15;_target_x=level.player.position.x
				_pose(1);Sfx.play("lab_scan",-9)
			"warning":
				_state="recover";_timer=2.4 if phase==1 else 2.8
				Sfx.play("warden_slam",-9);level.player._add_shake(4)
				if _attack%2==1:
					for side in [-1,1]:level.shoot(position+Vector2(side*110,-5),Vector2(side*170,0),true)
					if absf(level.player.position.x-_target_x)<24 and level.player.position.y>70:level.player.take_damage(1,Vector2(_target_x,100))
				else:
					for offset in [-65,0,65]:level.shoot(Vector2(_target_x+offset,-220),Vector2(0,150),false,false)
				if phase in [1,3]:open_window(2.4)
				_pose(2 if phase>1 else 0)
			"recover":_state="wait";_timer=1.8 if phase<3 else 2.6;_pose(2 if phase>1 else 0)
	core.queue_redraw();queue_redraw()
func _pose(index:int) -> void:
	_sprite.texture=Art.cell("robot",index,2)
	var ratio:=320.0/_sprite.texture.get_width();_sprite.scale=Vector2.ONE*ratio
	_sprite.position=Vector2(-160,-_sprite.texture.get_height()*ratio)
func open_window(seconds:float) -> void:
	vulnerable=seconds;_window_hit=false
	level.tell("NÚCLEO EXPOSTO · um golpe certeiro!" if phase<3 else "Suba pelos braços e acerte a cabine iluminada!")
func relay(element:String) -> void:
	if phase!=2 or not active:return
	if element=="fire":_heat=true
	else:_cold=true
	level.tell("Regulador vermelho aquecido. Falta GELO no azul." if _heat and not _cold else "Regulador azul congelado. Falta FOGO no vermelho.")
func hit_core(_amount:float,_source:Vector2) -> void:
	if not active or dead or level.intro_active or vulnerable<=0 or _window_hit:return
	if phase==3 and level.player.position.y>position.y-235:
		level.tell("A cabine fica no alto. Use as plataformas dos braços.");return
	_window_hit=true;health-=1;_hurt=.45;Sfx.hit();Fx.burst(core.global_position,Color("ffe8a3"),20,150)
	if health<=0:_advance_phase()
func _advance_phase() -> void:
	vulnerable=0;_window_hit=true;level.clear_shots()
	if phase==1:
		phase=2;health=3;_state="wait";_timer=3.5;_pose(2);level.player.heal_full()
		level.tell("BLINDAGEM ATIVA · FOGO no vermelho e GELO no azul para abrir o núcleo.")
	elif phase==2:
		active=false;level.play_friends_turn()
	else:
		active=false;dead=true;dying=true;_pose(3);Sfx.play("lab_clink",-7);defeated.emit()
func enable_final_phase() -> void:
	phase=3;health=3;active=true;_friends_seen=true;_state="wait";_timer=5.0;_pose(2)
	core.position=Vector2(-50,-240)
	for info in [Vector3(-310,-50,100),Vector3(-225,-100,100),Vector3(-140,-150,100),Vector3(-55,-200,100),Vector3(-80,-250,100)]:
		var ledge:=preload("res://world/Scripts/Corp2D/terrain.gd").new();ledge.position=position+Vector2(info.x,info.y);ledge.width=info.z;ledge.depth=10;ledge.platform=true;ledge.variant=1;ledge.z_index=2;level.add_child(ledge);steps.append(ledge)
	level.player.position=Vector2(8480,89);level.player.velocity=Vector2.ZERO;level.player.set_checkpoint(level.player.position);level.player.heal_full()
	level.tell("Os amigos travaram os braços! Suba até a cabine; espere a luz do núcleo.")
func reset_encounter() -> void:
	if dead:return
	active=false;health=3;vulnerable=0;_state="wait";_timer=3;_heat=false;_cold=false;level.clear_shots()
	if phase==3:_timer=5
	_pose(2 if phase>1 else 0)
func status() -> String:
	return ["PROTOCOLO DE DEMISSÃO","FALHA TÉRMICA","JUNTOS ATÉ O TOPO"][phase-1]
func _draw() -> void:
	if active and _state=="warning":
		var local_x:=_target_x-position.x
		draw_rect(Rect2(local_x-24,-3,48,3),Color("ffb475"))
		if _attack%2==0:
			for offset in [-65,0,65]:draw_line(Vector2(local_x+offset,-290),Vector2(local_x+offset,0),Color(1,.3,.2,.25),2)


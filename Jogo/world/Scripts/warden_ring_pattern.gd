extends Node2D
## Arena contínua inspirada no ritmo de Mecha-Bandicoot: correr, saltar, devolver.
const Chains=preload("res://world/Scripts/underworld_chain_art.gd")
const Hazard=preload("res://world/Scripts/warden_ring_hazard.gd")
const Tiles=preload("res://world/Scripts/underworld_tiles.gd")
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
	_rear.draw.connect(_draw_rear)
func _physics_process(delta:float) -> void:
	break_flash=maxf(0,break_flash-delta)
	queue_redraw()
	_rear.queue_redraw()
func schedule() -> Array[String]:
	if boss._phase2_parries<2:return ["rain","sweep","charge"]
	if boss._phase2_parries<4:return ["rain","charge"]
	return ["charge"]
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
		var sweep:=Hazard.new()
		sweep.boss=boss;sweep.kind="sweep"
		sweep.direction=1 if boss._player.position.x<boss.ARENA_CENTER else -1
		sweep.position=Vector2(6490 if sweep.direction>0 else 7430,boss.arena_floor_y())
		get_parent().add_child(sweep)
	elif value=="charge":Sfx.play("warden_ice_charge",-10)
func finish_beat(wait:float) -> void:
	beat="rest";clock=0;cycle_step+=1;boss._timer=wait
func on_return() -> void:
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
		return "ACERTOU! · Os selos quebram em 2 e 4 devoluções"
	match beat:
		"rain":return "CHUVA DE FERRAGENS · Corra para sair das miras laranjas"
		"sweep":return "CORRENTE RASTEIRA · Pule por cima da varredura"
		"charge":return "ESFERA VERDE · Prepare J / X para devolver"
		"orb":return "J / X REBATE A ESFERA VERDE · Acerte de frente!"
	return "CORRA · PULE · DEVOLVA · %d / 7" % boss._phase2_parries
func _draw() -> void:
	if not is_instance_valid(boss) or not boss.active or boss.phase!=2:return
	for i in 2:
		var at:=boss.position+Vector2(-67 if i==0 else 67,-85)
		var destroyed:bool=boss._phase2_parries>=(2 if i==0 else 4)
		if not destroyed:
			draw_texture_rect(Chains.CLASP,Rect2(at-Vector2(12,15),Vector2(24,30)),false)
			draw_arc(at,19,0,TAU,16,Color("ffc887"),2)
		else:
			Chains.strand(self,at,at+Vector2(-12 if i==0 else 12,20),5,7,Color("706577"))
			if break_flash>0:draw_arc(at,20+(1.4-break_flash)*25,0,TAU,16,Color(.75,1,.6,break_flash/1.4),2)
	if beat=="charge":
		var at:=boss.position+Vector2(0,-88)
		var r:=6+clampf(clock/1.25,0,1)*14
		draw_arc(at,r,0,TAU,16,Color("b6ff8e"),3)
		for i in 6:
			var a:=i*TAU/6+clock*2
			draw_rect(Rect2(at+Vector2(cos(a),sin(a))*r-Vector2.ONE*2,Vector2.ONE*4),Color("d9ffb4"))
func _draw_rear() -> void:
	if not is_instance_valid(boss) or not boss.active or boss.phase!=2:return
	var floor_y:float=boss.arena_floor_y()
	# Mureta de basalto curva, atrás do guardião e apoiada no piso inteiro.
	for i in 49:
		var a:=PI+PI*i/48.0
		var p:=Vector2(boss.ARENA_CENTER+cos(a)*450,floor_y-7+sin(a)*32).round()
		Tiles.platform(_rear,Rect2(p-Vector2(15,0),Vector2(30,12)))
		Tiles.tile(_rear,Rect2(p+Vector2(-15,12),Vector2(30,maxf(1,floor_y-p.y))),4+i%4)

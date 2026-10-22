extends Node2D
@export var kind:="tank"
@export var chemical:="toxic"
@export var width:=100.0
@export var circuit:=""
@export var phase:=0.0
var clock:=0.0
var health:=2.0
var frozen_left:=0.0
var disabled_left:=0.0
var boost_left:=0.0
var temporary_life:=-1.0
var activated:=false
var reversed:=false
var _cooldown:=0.0
var _body:StaticBody2D
var _platform:AnimatableBody2D
var _sprite:Sprite2D
var _player:CharacterBody2D
var _home:=Vector2.ZERO
var _beam_x:=0.0
const Art=preload("res://world/Scripts/lab_art.gd")
func _ready() -> void:
	add_to_group("lab_devices");_home=position;clock=phase
	_player=get_tree().get_first_node_in_group("player");texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var picture:String={"tank":"tank","gate":"door","camera":"camera","laser":"laser","conveyor":"conveyor","press":"press","mover":"arm","lever":"lever","card":"card","heat":"heat","cold":"cold","injector":"injector","rescue":"tank","record":"cold","cover":"crate"}.get(kind,"")
	if picture!="":
		_sprite=Art.prop(picture,width,kind=="conveyor");add_child(_sprite)
	if kind in ["tank","camera","chemical","heat","cold","injector","laser","press","mover"]:
		_body=preload("res://world/Scripts/lab_target.gd").new();_body.device=self;_body.collision_layer=4|16;_body.collision_mask=0
		var shape:=RectangleShape2D.new();shape.size=Vector2(width*.6,36 if kind!="tank" else 64)
		var collider:=CollisionShape2D.new();collider.shape=shape;collider.position.y=-18 if kind!="tank" else -32
		_body.add_child(collider);add_child(_body)
		if kind=="injector" or (kind=="mover" and circuit=="arena"):_body.collision_layer=0
	if kind in ["gate","cover","conveyor"]:
		_body=StaticBody2D.new();_body.collision_layer=1;_body.collision_mask=0
		var shape:=RectangleShape2D.new();shape.size=Vector2(width*.7,92 if kind=="gate" else (42 if kind=="cover" else 8))
		var collider:=CollisionShape2D.new();collider.shape=shape;collider.position.y=-46 if kind=="gate" else (-21 if kind=="cover" else 3)
		_body.add_child(collider);add_child(_body)
		if kind=="conveyor":_body.position.y=-1;_body.constant_linear_velocity=Vector2(82,0)
	if kind=="mover":
		process_physics_priority=-20;_platform=AnimatableBody2D.new();_platform.sync_to_physics=false;_platform.collision_layer=1;_platform.collision_mask=0
		var collider:=CollisionShape2D.new();var shape:=RectangleShape2D.new();shape.size=Vector2(116,8);collider.shape=shape;collider.position.y=4;collider.one_way_collision=true;collider.one_way_collision_margin=12
		_platform.add_child(collider);add_child(_platform);_platform.sync_to_physics=true
		var surface:=Art.prop("platform",120,true);_platform.add_child(surface)
	if kind=="rescue":
		var bear:=Art.Art.actor(preload("res://world/Arte/Amigos/urso.tres"),64)
		bear.name="Urso";bear.position+=Vector2(0,-6);bear.z_index=1;bear.modulate=Color("c8e6d8");add_child(bear);bear.play(&"idle")
func _physics_process(delta:float) -> void:
	clock+=delta;frozen_left=maxf(0,frozen_left-delta);disabled_left=maxf(0,disabled_left-delta);boost_left=maxf(0,boost_left-delta);_cooldown=maxf(0,_cooldown-delta)
	if temporary_life>0:
		temporary_life-=delta
		if temporary_life<=0:queue_free();return
	if is_instance_valid(_sprite):
		_sprite.modulate=Color("abedff") if frozen_left>0 else Color.WHITE
		if kind=="heat" and get_parent().get_node("Boss").heated>0:_sprite.modulate=Color("ffc578")
		elif kind=="cold" and get_parent().get_node("Boss").cooled>0:_sprite.modulate=Color("9becff")
	if kind=="mover":
		if frozen_left<=0:
			_platform.position=Vector2(sin(clock*.65)*58*(-1 if reversed else 1),-46+sin(clock*.85)*36)
	if kind=="conveyor":_body.constant_linear_velocity=Vector2(-82 if reversed else 82,0) if frozen_left<=0 else Vector2.ZERO
	if absf(_player.position.x-position.x)>700:return
	var near:bool=not _player.is_dead() and absf(_player.position.x-position.x)<width*.5 and absf(_player.position.y+11-position.y)<18
	if kind=="card" and _player.global_position.distance_to(global_position+Vector2(0,-16))<30:
		get_parent().access_card=true;get_parent()._show_notice("Cartão de acesso obtido. E na porta de segurança.");Sfx.checkpoint();queue_free();return
	if kind=="chemical":
		if frozen_left>0:_set_ice_collision(true)
		else:_set_ice_collision(false)
		if near and _cooldown<=0:
			if boost_left>0:_player.launch_from_spring(540);_cooldown=.8;Sfx.play("lab_pressure",-7)
			elif frozen_left>0:pass
			elif chemical=="bounce":_player.launch_from_spring(470);_cooldown=.6;Sfx.jump()
			elif chemical=="slip":_player.velocity.x+=signf(_player.velocity.x+1)*65*delta
			else:_player.take_damage(1,position)
	elif kind=="laser" and frozen_left<=0 and disabled_left<=0:
		var cycle:=fposmod(clock,3.6)
		if cycle>2.1 and cycle<3.2 and absf(_player.position.x-position.x)<9 and _player.position.y>position.y-85 and _player.position.y<position.y:_player.take_damage(1,position)
	elif kind=="camera" and not activated and frozen_left<=0 and disabled_left<=0:
		_beam_x=sin(clock*.7)*90
		if _cooldown<=0 and absf(_player.position.x-position.x-_beam_x)<35 and absf(_player.velocity.x)>45:
			var query:=PhysicsRayQueryParameters2D.create(global_position+Vector2(0,-22),_player.global_position,1)
			if get_world_2d().direct_space_state.intersect_ray(query).is_empty():
				_cooldown=2.8;get_parent()._show_notice("Movimento detectado! Congele o sensor ou use uma caixa como cobertura.");Sfx.play("lab_alarm",-12)
				var shot:=preload("res://world/Scripts/lab_projectile.gd").new();shot.position=global_position+Vector2(0,-22);shot.flight=(_player.position-shot.position).normalized()*175;get_parent().add_child(shot)
	elif kind=="press" and frozen_left<=0:
		var cycle:=fposmod(clock,4.2)
		if cycle>2.8 and cycle<3.35 and near:_player.take_damage(1,position)
	queue_redraw()
func _set_ice_collision(on:bool) -> void:
	if not is_instance_valid(_body):return
	_body.set_deferred("collision_layer",(1|16) if on else 16)
	var collider:CollisionShape2D=_body.get_child(0)
	collider.position.y=4 if on else -12
	collider.shape.size=Vector2(width,8) if on else Vector2(width,28)
	collider.one_way_collision=on
func interact() -> bool:
	var level:=get_parent()
	match kind:
		"gate":
			if not level.access_card:level._show_notice("É necessário o cartão laranja do setor de segurança.")
			else:activated=true;_body.set_deferred("collision_layer",0);_sprite.texture=Art.texture("door_open");Sfx.play("lab_door",-8)
		"lever":
			reversed=not reversed
			for device in get_tree().get_nodes_in_group("lab_devices"):
				if device!=self and device.circuit==circuit:device.reversed=not device.reversed;device.disabled_left=8
			level._show_notice("Circuito invertido: esteiras e braços mudaram de direção. Segurança suspensa por 8 s.");Sfx.select()
		"record":level.show_lab_notice("REGISTRO LG-17: o estabilizador pertence ao enxerto de Largato. Calor abre a injeção; frio permite inverter o fluxo.",8)
		"injector":return level.get_node("Boss").reverse_injector()
		"rescue":
			if level.get_node("Boss").is_dead():level.rescue_urso()
			else:level._show_notice("Urso está preso. Derrote o diretor para abrir a câmara.")
		_:return false
	return true
func take_element(element:String,_source:Vector2) -> void:
	if kind=="chemical":
		if element=="ice":frozen_left=8;boost_left=0
		elif frozen_left>0:frozen_left=0;boost_left=2.2
	elif kind in ["heat","cold","injector"]:get_parent().get_node("Boss").machine_element(kind,element)
	elif element=="ice":freeze_for(5)
	elif kind=="tank" or kind=="camera":take_damage(1,_source)
func take_damage(amount:float,_source:Vector2) -> void:
	if kind not in ["tank","camera"] or activated:return
	if _cooldown>.1:return
	health-=amount;_cooldown=.25;Sfx.hit()
	if health<=0:
		activated=true;_body.set_deferred("collision_layer",0)
		if kind=="tank":
			_sprite.texture=Art.texture("tank_broken");get_parent().spawn_enemy(global_position+Vector2(0,-4),"specimen",true)
		else:_sprite.modulate=Color("5a6772");disabled_left=9999
func freeze_for(seconds:float) -> void:frozen_left=maxf(frozen_left,seconds)
func _draw() -> void:
	if kind=="chemical":
		var color:=Color("62d768") if chemical=="toxic" else (Color("c87adb") if chemical=="bounce" else Color("589ee5"))
		if frozen_left>0:color=Color("a5e6f4")
		draw_rect(Rect2(-width/2,0,width,13),color.darkened(.4));draw_rect(Rect2(-width/2,-2,width,4),color)
		for i in 6:
			var x:float=-width/2+fposmod(i*23+clock*13,width)
			draw_circle(Vector2(x,3+sin(clock*3+i)*2),2,Color(color.lightened(.25),.8))
		if boost_left>0:
			for i in 9:draw_circle(Vector2(sin(i+clock)*10,-fposmod(clock*75+i*9,65)),2,Color("d8e6e9",.65))
	elif kind=="mover" and is_instance_valid(_platform):
		draw_line(Vector2(0,-16),_platform.position+Vector2(-25,5),Color("172333"),9)
		draw_line(Vector2(0,-16),_platform.position+Vector2(-25,5),Color("c1cbd0"),5)
		draw_circle(_platform.position+Vector2(-25,5),6,Color("bc813d"))
	elif kind=="laser" and disabled_left<=0 and frozen_left<=0:
		var cycle:=fposmod(clock,3.6);var active:=cycle>2.1 and cycle<3.2
		draw_line(Vector2(0,-7),Vector2(0,-88),Color("ff526b") if active else Color("e8c46a",.3),4 if active else 1)
	elif kind=="camera" and not activated and frozen_left<=0 and disabled_left<=0:
		draw_colored_polygon(PackedVector2Array([Vector2(0,-22),Vector2(_beam_x-30,0),Vector2(_beam_x+30,0)]),Color("73c9e3",.16))
	elif kind=="press":
		var cycle:=fposmod(clock,4.2);var low:float=smoothstep(2.65,2.9,cycle)*(1-smoothstep(3.35,3.7,cycle)) if frozen_left<=0 else 0
		draw_rect(Rect2(-width*.3,-80+low*62,width*.6,10),Color("c6cbd1"))
		if cycle>2 and cycle<2.8:draw_rect(Rect2(-width*.4,-1,width*.8,3),Color("ffb05d",absf(sin(clock*12))))
	if kind in ["lever","gate","record","injector","rescue"] and absf(_player.position.x-position.x)<58:
		draw_string(ThemeDB.fallback_font,Vector2(-26,-72),"E · "+{"lever":"inverter","gate":"acesso","record":"registro","injector":"injetor","rescue":"Urso"}[kind],HORIZONTAL_ALIGNMENT_LEFT,120,8,Color("ffe6b7"))

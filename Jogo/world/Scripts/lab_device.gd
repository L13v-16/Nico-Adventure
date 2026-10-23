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
var _state_picture:=""
var _lever_time:=0.0
var _chemical_art:AnimatedSprite2D
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
		var shape:=RectangleShape2D.new();shape.size=Vector2(width*(.85 if kind=="cover" else .7),92 if kind=="gate" else (62 if kind=="cover" else 8))
		var collider:=CollisionShape2D.new();collider.shape=shape;collider.position.y=-46 if kind=="gate" else (-31 if kind=="cover" else 3)
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
	if kind=="injector":
		var arm:=Art.prop("injector",100);arm.z_index=-1;arm.position.x+=24;add_child(arm)
	if kind=="gate":_body.collision_layer=0 # Recessed doors; room walls seal the shaft.
	if kind=="chemical":
		_chemical_art=preload("res://world/Scripts/lab_effect.gd").new();_chemical_art.drawn_width=width;add_child(_chemical_art)
		_set_ice_collision(false)
	_update_state_art()
func _update_state_art() -> void:
	var picture:=""
	var boss:Node=get_parent().get_node_or_null("Boss")
	if kind=="lever":picture="state_%02d"%(1 if _lever_time>0 else (2 if reversed else 0))
	elif kind=="heat":picture="state_%02d"%(5 if boss.heated>0 else 4)
	elif kind=="cold":picture="state_%02d"%(7 if boss.cooled>0 else 6)
	elif kind=="injector":picture="state_%02d"%(11 if boss.injector_reversed else (10 if boss.injector_cold else (9 if boss.injector_heat else 8)))
	if picture.is_empty() or picture==_state_picture:return
	_state_picture=picture;_sprite.texture=Art.texture(picture)
	var drawn_width:=64.0 if kind=="lever" else width
	var ratio:=drawn_width/_sprite.texture.get_width();_sprite.scale=Vector2.ONE*ratio
	_sprite.position=Vector2(-drawn_width*.5,-float(_sprite.texture.get_meta("ground_foot",348))*ratio)
func _physics_process(delta:float) -> void:
	clock+=delta;frozen_left=maxf(0,frozen_left-delta);disabled_left=maxf(0,disabled_left-delta);boost_left=maxf(0,boost_left-delta);_cooldown=maxf(0,_cooldown-delta)
	_lever_time=maxf(0,_lever_time-delta);_update_state_art()
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
		var art_state:="ice" if frozen_left>0 else "poison"
		if _chemical_art.style!=art_state:_chemical_art.set_style(art_state)
		if frozen_left>0:_set_ice_collision(true)
		else:_set_ice_collision(false)
		if near and _cooldown<=0:
			if boost_left>0:_player.launch_from_spring(540);_cooldown=.8;Sfx.play("lab_pressure",-7)
			elif frozen_left>0:pass
			elif chemical=="bounce":_player.launch_from_spring(470);_cooldown=.6;Sfx.jump()
			elif chemical=="slip":_player.velocity.x+=signf(_player.velocity.x+1)*65*delta
			else:
				if _player._invulnerability_timer<=0:get_parent().spawn_lab_effect(_player.position,"splash",42)
				_player.take_damage(1,position);_cooldown=.6
	elif kind=="laser" and frozen_left<=0 and disabled_left<=0:
		var cycle:=fposmod(clock,3.6)
		if cycle>2.1 and cycle<3.2 and absf(_player.position.x-position.x)<9 and _player.position.y>position.y-85 and _player.position.y<position.y:_player.take_damage(1,position)
	elif kind=="camera" and not activated and frozen_left<=0 and disabled_left<=0 and absf(_player.position.y-position.y)<95:
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
			if is_instance_valid(level.rooms):level.rooms.travel(self)
		"lever":
			reversed=not reversed
			_lever_time=.14;_update_state_art()
			for device in get_tree().get_nodes_in_group("lab_devices"):
				if device!=self and device.circuit==circuit:device.reversed=not device.reversed;device.disabled_left=8
			for lift in get_tree().get_nodes_in_group("lab_lifts"):
				if lift.circuit==circuit:lift.enable()
			level.lessons["circuit"]=true;level._show_notice("Circuito ligado: o elevador azul está pronto. A esteira mudou de sentido.");Sfx.select()
		"record":level.show_lab_notice("REGISTRO LG-17: o estabilizador pertence ao enxerto de Largato. Calor abre a injeção; frio permite inverter o fluxo.",8)
		"injector":return level.get_node("Boss").reverse_injector()
		"rescue":
			if level.get_node("Boss").is_dead():level.rescue_urso()
			else:level._show_notice("Urso está preso. Derrote o diretor para abrir a câmara.")
		_:return false
	return true
func take_element(element:String,_source:Vector2) -> void:
	if kind=="chemical":
		if element=="ice":
			if frozen_left<=0:get_parent().spawn_lab_effect(position,"freeze",64);Sfx.play("lab_clink",-10)
			frozen_left=12;boost_left=0;get_parent().lessons["ice_bridge"]=true
		elif frozen_left>0:
			frozen_left=0;boost_left=2.2;get_parent().show_lab_notice("FOGO no gelo libera pressão. Cuidado: a ponte vai derreter.",4)
	elif kind in ["heat","cold","injector"]:get_parent().get_node("Boss").machine_element(kind,element)
	elif element=="ice":get_parent().spawn_lab_effect(position+Vector2(0,-18),"freeze",44);freeze_for(5)
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
		if frozen_left>0:
			var ink:=Color("9aebff") if frozen_left>2 else Color("f1ce7c")
			draw_rect(Rect2(-18,-39,36,3),Color("132d3e"));draw_rect(Rect2(-18,-39,36*clampf(frozen_left/12,0,1),3),ink)
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
	if kind in ["lever","gate","record","injector","rescue"] and _player.position.distance_to(position)<76:
		var action:String={"lever":"inverter","gate":"entrar","record":"registro","injector":"injetor","rescue":"Urso"}[kind]
		if kind=="gate" and is_instance_valid(get_parent().rooms):action=get_parent().rooms.door_label(roundi(position.x))
		draw_string(ThemeDB.fallback_font,Vector2(-90,26 if kind=="gate" else -72),"E · "+action,HORIZONTAL_ALIGNMENT_CENTER,180,8,Color("ffe6b7"))

extends "res://world/Scripts/level.gd"
var access_card:=false
var _rescued:=false
var _ambience:=4.0
var rooms:Node2D
func _ready() -> void:
	$Player.z_index=5
	if not InputMap.has_action("lab_throw"):
		InputMap.add_action("lab_throw");var key:=InputEventKey.new();key.physical_keycode=KEY_F;InputMap.action_add_event("lab_throw",key)
	preload("res://world/Scripts/lab_layout.gd").build(self)
	$Boss.defeated.connect(_on_largato_defeated)
	$HUD/Notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	$HUD/Notice.add_theme_font_size_override("font_size",10)
	$HUD/Notice.size.y=46
	super._ready()
	rooms=preload("res://world/Scripts/lab_rooms.gd").new();rooms.name="Rooms";add_child(rooms)
func _polish_terrain() -> void:pass
func _spawn_fragments() -> void:
	total_secrets=3
	for at in [Vector2(1070,-10),Vector2(2750,-80),Vector2(4830,-30)]:
		var fragment:Node2D=FRAGMENT_SCRIPT.new();fragment.position=at;fragment.collected.connect(_on_secret_collected);add_child(fragment)
func has_elemental_mastery() -> bool:return true
func nico_attack_cooldown_floor() -> float:return .65 if $Boss.active else 0.0
func spawn_enemy(at:Vector2,species:String,released:bool=false) -> Node2D:
	var enemy:=preload("res://world/Scripts/lab_enemy.gd").new();enemy.species=species;enemy.position=at;add_child(enemy)
	if released:
		total_enemies+=1;enemy.died.connect(_on_enemy_died);Fx.burst(at+Vector2(0,-30),Color("a2e3d8"),12,100)
	return enemy
func spawn_pool(at:Vector2,type:String,life:float=-1,width:float=100) -> Node2D:
	var pool:=preload("res://world/Scripts/lab_device.gd").new();pool.kind="chemical";pool.chemical=type;pool.position=at;pool.width=width;pool.temporary_life=life;add_child(pool);return pool
func show_lab_notice(message:String,seconds:float=5) -> void:
	_show_notice(message);_notice_time=seconds
func _start_sequence() -> void:
	var skip:=Save.consume_skip_intro()
	if not skip or not Save.has_story_flag("lab_entrance_breached"):
		var arrival:=preload("res://world/Scripts/lab_cutscene.gd").new();arrival.mode="arrival";arrival.level=self;arrival.name="LabArrival";add_child(arrival);await arrival.finished;Save.set_story_flag("lab_arrived");Save.set_story_flag("lab_entrance_breached")
	_begin_intro()
func _process(delta:float) -> void:
	_update_notice(delta)
	if intro_active or completed:return
	if _timing:_elapsed+=delta
	var camera:Camera2D=player.get_node("Camera2D")
	var boss:Node2D=$Boss
	notice.position.y=145 if boss.active else 56
	frame_camera(delta)
	if player.position.y>300:player.take_damage(3,Vector2(player.position.x,330))
	_ambience-=delta
	if _ambience<=0 and not get_tree().paused:_ambience=9;Sfx.play("lab_machine",-21)
	if boss.active:hint.text=boss._advice()+" · K: poder · Q: alternar"
	elif boss.is_dead():hint.text="E junto de Urso: abrir a câmara e resgatá-lo."
	elif player.position.x<1536:hint.text="SEGURANÇA · E: porta/alavanca · GELO: sensores · Caixas servem de cobertura."
	elif player.position.x<3072:hint.text="GELO: ponte sobre líquidos · FOGO no gelo: impulso · Roxo: quique · Azul: escorrega."
	elif player.position.x<4608:hint.text="Fábrica · E inverte circuitos · GELO pausa as máquinas · Observe o aviso das prensas."
	else:hint.text="Pesquisa avançada · E: registros LG-17 · Sua segurança é nossa 17ª prioridade."
func frame_camera(delta:float,snap:bool=false) -> void:
	var camera:Camera2D=player.get_node("Camera2D")
	var fighting:bool=$Boss.active
	var factor:=1.0 if snap else 1-exp(-delta*6)
	camera.zoom=camera.zoom.lerp(Vector2.ONE*(.9 if fighting else 1.5),factor)
	var desired:=Vector2(50,-40)
	if not fighting and is_instance_valid(rooms):
		var bounds:Vector2=rooms.BOUNDS[rooms.current]
		var half_width:float=320.0/camera.zoom.x
		var origin:=clampf(player.position.x,bounds.x+half_width,bounds.y-half_width)
		var center:=clampf(player.position.x+player._facing*50,bounds.x+half_width,bounds.y-half_width)
		# Camera2D applies offset after its limits; cancel look-ahead at walls.
		desired.x=center-origin-player._camera_look
	if fighting:
		var half_width:float=320.0/camera.zoom.x
		var center:=clampf(player.position.x+player._facing*45,6160+half_width-100,7040-half_width+100)
		desired=Vector2(center-player.position.x-player._camera_look,20-player.position.y)
	player._camera_base_offset=player._camera_base_offset.lerp(desired,factor)
	if snap:
		camera.offset=player._camera_base_offset+Vector2(player._camera_look,0)
		camera.reset_smoothing();camera.force_update_scroll()
func _physics_process(_delta:float) -> void:
	if is_instance_valid(rooms) and rooms.transitioning:return
	if not intro_active and not completed and player.elements.can_control() and Input.is_action_just_pressed("lab_throw"):$Boss.throw_serum()
func _unhandled_input(event:InputEvent) -> void:
	if event.is_echo():return
	if intro_active or completed or get_tree().paused or not event.is_action_pressed("interagir"):return
	if is_instance_valid(rooms) and rooms.transitioning:return
	for shop in get_tree().get_nodes_in_group("caravan_shops"):
		if shop.get_parent()==self and shop._can_open():return
	var closest:Node2D;var distance:=65.0
	for device in get_tree().get_nodes_in_group("lab_devices"):
		if device.get_parent()!=self or device.kind not in ["gate","lever","record","injector","rescue"]:continue
		var gap:float=player.position.distance_to(device.position+Vector2(0,-11))
		if gap<distance:closest=device;distance=gap
	if closest!=null and closest.interact():get_viewport().set_input_as_handled()
func _on_largato_defeated() -> void:
	Save.set_story_flag("lab_largato_defeated")
	$UrsoChamber._sprite.texture=preload("res://world/Scripts/lab_art.gd").texture("tank_broken")
	$UrsoChamber.get_node("Urso").modulate=Color.WHITE
	show_lab_notice("Largato virou uma poça. A câmara está liberada: encontre Urso à direita e aperte E.",7)
func rescue_urso() -> void:
	if not $Boss.is_dead() or completed:return
	_rescued=true;Save.set_story_flag("urso_rescued");player.heal_full();_complete_level()
func _on_finish_entered(body:Node2D) -> void:
	if body==player and _rescued and not completed:rescue_urso()
func _on_checkpoint_entered(body:Node2D,checkpoint) -> void:
	# Area callbacks queued before a door teleport may arrive in the next room.
	if is_instance_valid(rooms):
		if rooms.sector_at(checkpoint.global_position.x)!=rooms.current:return
		if player.global_position.distance_to(checkpoint.global_position)>90:return
	super._on_checkpoint_entered(body,checkpoint)
func _start_finale(stats:Dictionary,new_record:bool) -> void:
	_show_notice("");player.velocity=Vector2.ZERO;get_tree().paused=true
	_finale=preload("res://world/Scripts/lab_cutscene.gd").new();_finale.mode="ending";_finale.level=self;_finale.name="UrsoRescue"
	_finale.finished.connect(_on_finale_finished.bind(stats,new_record),CONNECT_ONE_SHOT);add_child(_finale)

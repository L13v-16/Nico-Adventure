extends "res://world/Scripts/level.gd"
const Layout=preload("res://world/Scripts/underworld_layout.gd")
const Dialogue=preload("res://world/Scripts/underworld_dialogue.gd")
var temple_seen:=false
var key_collected:=false
var _selected_target:Node2D
var _temple_busy:=false
var _clock:=0.0
var _command_flash:=0.0
func _ready() -> void:
	temple_seen=false
	Layout.build(self)
	$Forge.solved.connect(func():_show_notice("Forja funcionando! A passagem está aberta."))
	$Boss.defeated.connect(_on_boss_defeated)
	$Boss.encounter_started.connect(func():_show_notice(""))
	player.shop_shield_changed.connect(func(hits:int):game_hud.set_shop_shield(hits))
	super._ready()
func _polish_terrain() -> void:pass
func _setup_enemies() -> void:
	total_enemies=0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		total_enemies+=1
		enemy.died.connect(_on_enemy_died)
func _spawn_fragments() -> void:
	var points:=[Vector2(1210,20),Vector2(3640,-130),Vector2(5580,-32)]
	total_secrets=points.size()
	for point in points:
		var fragment:Node2D=FRAGMENT_SCRIPT.new()
		fragment.position=point
		fragment.collected.connect(_on_secret_collected)
		add_child(fragment)
func _start_sequence() -> void:
	Save.consume_skip_intro()
	Sfx.begin_dialogue_music(self)
	intro_active=true
	_timing=false
	pause_menu.can_open=false
	player.set_physics_process(false)
	var camera:=player.get_node("Camera2D") as Camera2D
	camera.position_smoothing_enabled=false
	get_tree().paused=true
	await _dialogue("launch","CorporateCannon")
	player.position=Vector2(190,89)
	player.velocity=Vector2.ZERO
	player.get_node("anim").play(&"idle")
	player.respawn_position=player.position
	camera.offset=Vector2(55,-9)
	camera.force_update_scroll()
	await _begin_intro()
	intro_active=true
	_timing=false
	pause_menu.can_open=false
	get_tree().paused=true
	await _dialogue("arrival","JoseRescue")
	Sfx.end_dialogue_music(self)
	Save.set_story_flag("jose_rescued")
	$Jose.rescued=true
	intro_active=false
	get_tree().paused=false
	player.set_physics_process(true)
	camera.position_smoothing_enabled=true
	pause_menu.can_open=true
	_timing=true
	_elapsed=0
	_show_notice("José resgatado! Agora encontrem uma saída.")
func _dialogue(mode:String,node_name:String) -> void:
	var dialogue:=Dialogue.new()
	dialogue.mode=mode
	dialogue.name=node_name
	add_child(dialogue)
	await dialogue.finished
func has_elemental_mastery() -> bool:return temple_seen
func nico_attack_cooldown_floor() -> float:
	return 1.0 if $Boss.active and $Boss.phase==2 else 0.0
func _temple() -> void:
	_temple_busy=true
	intro_active=true
	_timing=false
	pause_menu.can_open=false
	player._cancel_attack()
	player.velocity=Vector2.ZERO
	player.anim.play(&"idle")
	var camera:=player.get_node("Camera2D") as Camera2D
	camera.position_smoothing_enabled=false
	camera.zoom=Vector2.ONE*1.15
	camera.offset=Vector2(3555-player.position.x,-64)
	camera.force_update_scroll()
	get_tree().paused=true
	await _dialogue("temple","TempleLesson")
	var saved:bool=Save.set_story_flag("elemental_mastery")
	$Scenery/Temple.play(&"temple_ready")
	temple_seen=true
	$Forge.power_ready=true
	$Forge._update()
	_temple_busy=false
	intro_active=false
	get_tree().paused=false
	pause_menu.can_open=true
	_timing=true
	_show_notice("Poderes do altar! K: disparar · Q: alternar fogo/gelo" if saved else "Altar ativado nesta partida. Não foi possível salvar o aprendizado.")
	player._camera_base_offset=camera.offset
	camera.position_smoothing_enabled=true
func _process(delta:float) -> void:
	_clock+=delta
	_update_notice(delta)
	if completed:return
	if _timing:_elapsed+=delta
	if intro_active:return
	var x:float=player.position.x
	var boss:Node2D=$Boss
	var arena:bool=boss.active
	var camera:=player.get_node("Camera2D") as Camera2D
	var arena_zoom:float=0.9 if boss.phase==5 else clampf(640.0 / (absf(x-boss.position.x)+180.0),0.74,0.9)
	camera.zoom=camera.zoom.lerp(Vector2.ONE*(arena_zoom if arena else 1.5),1-exp(-delta*4))
	# A câmera acompanha a subida da luta para manter a cabeça do guardião
	# abaixo da HUD, sem perder o patamar seguro que Nico precisa alcançar.
	var arena_y:float=-65
	if arena and boss.phase==2:arena_y=boss.arena_floor_y()-155
	elif arena and boss.phase>=3:arena_y=-220
	if arena and boss.phase==5:arena_y=-312
	var arena_x:float=7145 if arena and boss.phase==5 else clampf((x + boss.position.x) * 0.5 + signf(boss.position.x-x)*25, 6740, 7180)
	var desired:=Vector2(arena_x-x-float(player._camera_look),arena_y-player.position.y) if arena else Vector2(55,-38)
	player._camera_base_offset=player._camera_base_offset.lerp(desired,1-exp(-delta*5))
	camera.limit_top=-750 if arena and boss.phase==5 else -550
	if player.position.y>210 and x<6450:player.take_damage(3,Vector2(x,240))
	if not temple_seen and not _temple_busy and player.is_on_floor() and not player.is_dead() and x>3460 and x<3750:_temple()
	if Input.is_action_just_pressed("jose_command") and player.elements.can_control():_command_jose()
	if x<900:hint.text="Pedras rachadas: C chama José para quebrar  ·  J / X: atacar  ·  Encontre o altar para aprender fogo e gelo."
	elif x<1450:hint.text="Rochas claras seguem você; roxas se afastam. Posicione a ponte e pule. Ao embarcar, elas param."
	elif x<2200:hint.text="Observe as faíscas antes da erupção! A seta azul marca um gêiser que lança Nico para cima."
	elif x<3376:hint.text="Use os gêiseres de impulso para alcançar as partes altas. C: José derruba pilares frágeis."
	elif x<3904:hint.text="Santuário dos Contrários: receba fogo e gelo. K: disparar  ·  Q: alternar"
	elif x<4944:hint.text="Forja: fogo na válvula laranja, gelo na azul; repita. K: disparar · Q: alternar. Evite o vapor."
	elif x<6144:hint.text="As rochas bloqueiam tridentes! C: derrube o pilar para criar uma ponte sobre a lava."
	elif x<6450:hint.text="I: mochila  ·  Ative a bandeira antes de enfrentar o Carcereiro."
	elif arena:hint.text=boss._advice()+"  ·  K: disparo  ·  Q: elemento  ·  C: José"
	else:hint.text="O Carcereiro guarda a saída. Prepare os poderes e chame José!"
	if arena and boss.phase==5:hint.text=boss._advice()+" · Espere a ponte chegar · Q: elemento"
	queue_redraw()
func _unhandled_input(event:InputEvent) -> void:
	if intro_active or completed or get_tree().paused:return
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT:
		_selected_target=_nearest_target(get_global_mouse_position(),90)
		get_viewport().set_input_as_handled()
func _nearest_target(point:Vector2,limit:float=240) -> Node2D:
	var best:Node2D
	var distance:=limit
	for target in get_tree().get_nodes_in_group("jose_targets"):
		if not target.can_jose_target():continue
		var gap:float=point.distance_to(target.jose_point())
		if gap<distance:best=target;distance=gap
	return best
func _command_jose() -> bool:
	var target:Node2D=_selected_target
	if not is_instance_valid(target) or not target.can_jose_target() or player.position.distance_to(target.jose_point())>240:
		target=_nearest_target(player.position)
	if target==null:
		_show_notice("Atraia o Carcereiro para o círculo dourado antes de chamar José." if $Boss.active and $Boss.phase==4 else "Aproxime-se de um obstáculo marcado para José atingir.")
		return false
	_selected_target=target
	return $Jose.command(target)
func _on_boss_defeated() -> void:
	# The final cannon can defeat him while Nico is airborne. No exit trigger.
	_on_finish_entered.call_deferred(player)
func _on_finish_entered(body:Node2D) -> void:
	if body != player or completed or not $Boss.is_dead() or player.is_dead():return
	key_collected=true
	Save.set_story_flag("depth_key")
	player.heal_full()
	_complete_level()
func _start_finale(stats:Dictionary,new_record:bool) -> void:
	_show_notice("")
	$HUD.hide()
	# The finale stages its own actors, including Nico's current equipment.
	player.velocity=Vector2.ZERO
	$Jose.velocity=Vector2.ZERO
	get_tree().paused=true
	_finale=Dialogue.new()
	_finale.mode="ending"
	_finale.name="UnderworldEscape"
	_finale.finished.connect(_on_finale_finished.bind(stats,new_record),CONNECT_ONE_SHOT)
	add_child(_finale)
func buy_acai_power() -> bool:
	if completed or intro_active or player.is_dead():return false
	var power:=preload("res://world/Scripts/acai_power.gd").new()
	add_child(power)
	if not power.activate_for(player):power.queue_free();return false
	return true
func _draw() -> void:
	# Lava abaixo das ilhas: sua superfície permanece longe do chão seguro.
	if not is_node_ready():return
	for gap in [[904,1320],[2200,2540],[3180,3376],[3776,3904],[4944,5200],[5904,6144]]:
		preload("res://world/Scripts/underworld_lava.gd").draw_pool(self,Rect2(gap[0],210,gap[1]-gap[0],260),_clock)
	if is_instance_valid(_selected_target) and _selected_target.can_jose_target():
		var point:Vector2=_selected_target.jose_point()+Vector2(0,-73)
		draw_arc(point,12,0,TAU,16,Color("ffe09b"),2)
		draw_line(point-Vector2(4,0),point+Vector2(4,0),Color("ffffff"),2)

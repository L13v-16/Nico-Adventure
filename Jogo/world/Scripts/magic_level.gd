extends "res://world/Scripts/level.gd"
const Layout := preload("res://world/Scripts/magic_layout.gd")
const DIALOGUE := preload("res://world/Scripts/magic_dialogue.gd")
var _boss_defeated := false
var _rescue_ready := false

func _ready() -> void:
	Layout.build(self)
	$Boss.defeated.connect(_on_boss_defeated)
	$Boss.encounter_started.connect(func():_show_notice(""))
	$RescueCage.opened.connect(_on_cage_opened)
	player.shop_shield_changed.connect(func(hits:int):game_hud.set_shop_shield(hits))
	super._ready()

func _polish_terrain() -> void:
	pass

func _start_sequence() -> void:
	Save.consume_skip_intro()
	await _begin_intro()
	intro_active=true
	_timing=false
	pause_menu.can_open=false
	get_tree().paused=true
	var arrival:=DIALOGUE.new()
	arrival.name="MagicArrival"
	add_child(arrival)
	await arrival.finished
	intro_active=false
	get_tree().paused=false
	pause_menu.can_open=true
	_timing=true
	_elapsed=0
	_show_notice("Encontre Remi no ringue da Hiena HaHa!")

func _setup_enemies() -> void:
	total_enemies=0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_in_group("rescue_cage"):continue
		total_enemies+=1
		enemy.died.connect(_on_enemy_died)

func _spawn_fragments() -> void:
	var spots:=[Vector2(1050,-125),Vector2(2740,-180),Vector2(4020,-173)]
	total_secrets=spots.size()
	for spot in spots:
		var fragment=FRAGMENT_SCRIPT.new()
		fragment.position=spot
		fragment.collected.connect(_on_secret_collected)
		add_child(fragment)

func _process(delta: float) -> void:
	_update_notice(delta)
	if completed:return
	if _timing:_elapsed+=delta
	var x:=player.position.x
	var arena:bool=$Boss.active
	var camera:=player.get_node("Camera2D") as Camera2D
	camera.zoom=camera.zoom.lerp(Vector2.ONE*(0.9 if arena else 1.5),1-exp(-delta*4))
	var desired:=Vector2(5520-x-float(player.get("_camera_look")),-80-player.position.y) if arena else Vector2(55,-38)
	var offset:Vector2=player.get("_camera_base_offset")
	player.set("_camera_base_offset",offset.lerp(desired,1-exp(-delta*5)))
	if x<550:hint.text="Remi está na clareira.  •  J / X: atacar  •  I: mochila  •  ESC: menu"
	elif x<1080:hint.text="Cogumelo vermelho: caia sobre ele para subir muito alto. Direcione Nico no ar!"
	elif x<1500:hint.text="E: agarrar o cipó  ·  Espaço: soltar  ·  Fruta-do-dragão: fogo temporário. Segure K para disparar!"
	elif x<2200:hint.text="Toque na planta luminosa: ela aproxima o cipó. Espere a ponta e aperte E!"
	elif x<3050:hint.text="Este cipó se move sozinho! Use o cogumelo e observe a aproximação antes de agarrar."
	elif x<3700:hint.text="Fruta-do-dragão: K lança fogo por 20 s. Açaí congela. Evite os espinhos do besouro!"
	elif x<4496:hint.text="Outra planta muda o cipó. Balance e solte no impulso para alcançar a próxima ilha."
	elif x<5184:hint.text="Oliver chegou antes de nós! E: caravana  •  I: mochila  •  Ative a bandeira antes de Hiena HaHa."
	elif not _boss_defeated:hint.text="Hiena HaHa: J / X rebate o barril. Nos socos, passe por cima e ataque por trás!"
	elif not _rescue_ready:hint.text="Hiena HaHa derrotada! Vá até Remi e use J / X para abrir o cadeado."
	else:hint.text="Remi está livre! Aproxime-se dele para conversar."

func _on_boss_defeated() -> void:
	_boss_defeated=true
	$RescueCage.unlocked=true
	game_hud.set_face(ROSTO_FELIZ,2)
	_show_notice("Abra o cadeado e liberte Remi! J / X: atacar.")

func _on_cage_opened() -> void:
	_show_notice("Remi resgatado!")
	await get_tree().create_timer(0.6).timeout
	_rescue_ready=true
	_on_finish_entered(player)

func _on_finish_entered(body: Node2D) -> void:
	if not _rescue_ready or player.position.x<6000:return
	super._on_finish_entered(body)

func _start_finale(stats: Dictionary,new_record: bool) -> void:
	for power in get_tree().get_nodes_in_group("acai_power"):
		if power.is_active():power.call("_deactivate")
	_show_notice("")
	$HUD.hide()
	$RescueCage.hide()
	player.position=Vector2(6038,53)
	player.get_node("anim").flip_h=false
	var camera:=player.get_node("Camera2D") as Camera2D
	camera.position_smoothing_enabled=false
	camera.zoom=Vector2(1.5,1.5)
	camera.offset=Vector2(70,5)
	camera.force_update_scroll()
	get_tree().paused=true
	_finale=DIALOGUE.new()
	_finale.rescue=true
	_finale.name="RemiRescue"
	_finale.finished.connect(_on_finale_finished.bind(stats,new_record),CONNECT_ONE_SHOT)
	add_child(_finale)

func buy_acai_power() -> bool:
	if completed or intro_active or player.is_dead():return false
	var power:=preload("res://world/Scripts/acai_power.gd").new()
	add_child(power)
	if not power.activate_for(player):
		power.queue_free()
		return false
	return true

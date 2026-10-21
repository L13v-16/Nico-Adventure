extends "res://world/Scripts/level.gd"

const ARRIVAL_SCRIPT := preload("res://world/Scripts/beach_arrival.gd")

var _rescue_ready := false
var _boss_defeated := false

func _ready() -> void:
	$RescueCage.opened.connect(_on_cage_opened)
	$Boss.defeated.connect(_on_boss_defeated)
	$Water.body_entered.connect(_on_water_entered)
	$Player.shop_shield_changed.connect(_on_shop_shield_changed)
	# As telas usam o mesmo atlas; aqui preservamos os tamanhos nativos da fase.
	var arara:AnimatedSprite2D=$Scenery/AraraMinas
	arara.scale=Vector2.ONE*48.0/arara.sprite_frames.get_frame_texture(&"idle",0).get_width()
	var turtle:AnimatedSprite2D=$RescueCage/Turtle
	turtle.scale=Vector2(64,48)/turtle.sprite_frames.get_frame_texture(&"idle",0).get_size()
	super._ready()
	_on_cherry_balance_changed(player.get_cherry_balance())

func _start_sequence() -> void:
	Save.consume_skip_intro()
	await _begin_intro()
	# O pedido de pular o prólogo também é usado por Próxima ilha: a chegada
	# deve aparecer ao seguir da floresta para a praia.
	intro_active = true
	_timing = false
	pause_menu.can_open = false
	get_tree().paused = true
	var arrival := ARRIVAL_SCRIPT.new()
	arrival.name = "BeachArrival"
	add_child(arrival)
	await arrival.finished
	intro_active = false
	get_tree().paused = false
	pause_menu.can_open = true
	_timing = true
	_elapsed = 0.0
	_show_notice("Resgate a Tartaruga! Caranguejos: pule sobre o casco.")

func _polish_terrain() -> void:
	pass


func _update_gems(total: int) -> void:
	if total > _gems_last:
		game_hud.set_face(ROSTO_FELIZ, 0.9)
	_gems_last = total
	game_hud.set_cherry_wallet(player.get_cherry_balance(), total, total_gems)
	_refresh_pause_summary()


func _on_cherry_balance_changed(balance: int) -> void:
	game_hud.set_cherry_wallet(balance, player.gems, total_gems)
	_refresh_pause_summary()


func _on_shop_shield_changed(hits: int) -> void:
	game_hud.set_shop_shield(hits)


func _refresh_pause_summary() -> void:
	if pause_menu == null:
		return
	pause_menu.set_summary("Saldo: %d cerejas  •  Coletadas: %d/%d  •  Vida: %d/%d" % [player.get_cherry_balance(), player.gems, total_gems, maxi(player.health, 0), player.MAX_HEALTH])


func buy_acai_power() -> bool:
	if completed or intro_active or player.is_dead():
		return false
	var power := preload("res://world/Scripts/acai_power.gd").new()
	power.name = "ShopAcai"
	add_child(power)
	if not power.activate_for(player):
		power.queue_free()
		return false
	return true

func _setup_enemies() -> void:
	total_enemies = 1 # O chefe conta uma vez, a jaula não é inimigo.
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_in_group("rescue_cage"):
			continue
		total_enemies += 1
		enemy.died.connect(_on_enemy_died)

func _spawn_fragments() -> void:
	var spots: Array[Vector2] = [Vector2(704,10), Vector2(1760,-66), Vector2(3344,12)]
	total_secrets = spots.size()
	for spot in spots:
		var fragment = FRAGMENT_SCRIPT.new()
		fragment.position = spot
		fragment.collected.connect(_on_secret_collected)
		add_child(fragment)

func _process(delta: float) -> void:
	_update_notice(delta)
	if completed:
		return
	if _timing:
		_elapsed += delta
	var x := player.position.x
	var camera: Camera2D = player.get_node("Camera2D")
	var in_arena := x > 4240.0 and not _boss_defeated
	var zoom_target := Vector2.ONE * (1.25 if in_arena else 2.0)
	camera.zoom = camera.zoom.lerp(zoom_target, 1.0 - exp(-delta * 5.0))
	# A arena abre o enquadramento para mostrar as asas e a boca dos canhões.
	var arena_offset_x := clampf(4588.0 - x, -160.0, 160.0) - float(player.get("_camera_look"))
	var desired_offset := Vector2(arena_offset_x, -60.0) if in_arena else Vector2(64, -24)
	var current_offset: Vector2 = player.get("_camera_base_offset")
	player.set("_camera_base_offset", current_offset.lerp(desired_offset, 1.0 - exp(-delta * 5.0)))
	if x < 600.0:
		hint.text = "Oliver está na chegada! E: loja  •  I: mochila  •  Espaço / W: pular  •  J / X: atacar"
	elif x < 1000.0:
		hint.text = "Caranguejos: pule sobre o casco! Socos não os derrotam."
	elif x < 1504.0:
		hint.text = "Espere a jangada se aproximar e salte. O mar leva à última bandeira."
	elif x < 2600.0:
		hint.text = "Açaí: proteção e golpes que congelam por 12 segundos. I: mochila."
	elif x < 4256.0:
		hint.text = "I: mochila  •  Prepare seus equipamentos para enfrentar Urus, o Urubu."
	elif not _boss_defeated:
		hint.text = "Urus, o Urubu: escolha o canhão e pule quando a mira estiver verde."
	elif not $RescueCage.is_dead():
		hint.text = "O cadeado está vulnerável! J / X: quebre a jaula e liberte a tartaruga."
	else:
		hint.text = "A tartaruga está livre!"

func _on_water_entered(body: Node2D) -> void:
	if body == player and not completed and not player.is_dead():
		Fx.burst(Vector2(player.position.x, 114), Color("c5f6ef"), 18, 155)
		player.call("_register_death")

func _on_boss_defeated() -> void:
	_boss_defeated = true
	defeated += 1
	$RescueCage.unlocked = true
	game_hud.set_face(ROSTO_FELIZ, 2.0)
	_show_notice("Urus derrotado! Quebre o cadeado para libertar a tartaruga.")

func _on_cage_opened() -> void:
	_show_notice("Tartaruga resgatada!")
	await get_tree().create_timer(0.65).timeout
	_rescue_ready = true
	_on_finish_entered(player)

func _on_finish_entered(body: Node2D) -> void:
	if not _rescue_ready:
		return
	super._on_finish_entered(body)

func _start_finale(stats: Dictionary, new_record: bool) -> void:
	# Encerra o contador do poder antes de a pausa congelar o mundo.
	for power in get_tree().get_nodes_in_group("acai_power"):
		if power.is_active():
			power.call("_deactivate")
	super._start_finale(stats, new_record)

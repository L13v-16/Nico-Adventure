extends Node2D
## A geometria da fase e os percursos das plataformas ficam na cena, editáveis.

const NOTICE_TIME := 3.0
const PAUSE_MENU_SCRIPT: GDScript = preload("res://world/Scripts/pause_menu.gd")
const TERRAIN_SHADE_SCRIPT: GDScript = preload("res://world/Scripts/terrain_shade.gd")
const STORY_INTRO_SCRIPT: GDScript = preload("res://world/Scripts/story_intro.gd")
const RESULTS_SCRIPT: GDScript = preload("res://world/Scripts/results_screen.gd")
const FINALE_SCRIPT: GDScript = preload("res://world/Scripts/island_finale.gd")
const FRAGMENT_SCRIPT: GDScript = preload("res://world/Scripts/fragment.gd")
const MENU_SCENE := "res://world/main_menu.tscn"

@export var level_id := "fase_1"
@export var level_name := "Fase 1 — A Floresta"
## Tempo de referência para a nota: mais rápido que isto rende bônus total.
@export var par_time := 120.0
@export var secret_count := 3
## Altura do chão na chegada, comparada aos pés do personagem.
@export var finish_floor_y := -28.0
@export var finale_script: GDScript = FINALE_SCRIPT
@export_file("*.tscn") var next_level_scene := "res://world/beach_02.tscn"
@export var intro_title := "VALE DAS COPAS"
@export var intro_act := 1
@export var pause_on_focus_loss := true

var completed := false
var intro_active := true
var active_checkpoint  # Checkpoint; sem tipo para dispensar o cache de classes
var total_gems := 0
var pause_menu
var _notice_time := 0.0
var _gems_last := 0
var _health_last := 3

## Caras do retrato (ver ROSTOS em game_hud.gd): feliz, caído e susto.
const ROSTO_NORMAL := 0
const ROSTO_FELIZ := 1
const ROSTO_CAIDO := 2
const ROSTO_SUSTO := 3

# --- Estatísticas da fase (GDD §39) ---------------------------------------
var total_enemies := 0
var defeated := 0
var deaths := 0
var total_secrets := 0
var secrets_found := 0
var _elapsed := 0.0
var _timing := false
var _results
var _finale: CanvasLayer

@onready var player: CharacterBody2D = $Player
@onready var game_hud: Control = $HUD/GameHUD
@onready var hint: Label = $HUD/Hint
@onready var notice: Label = $HUD/Notice


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and pause_on_focus_loss:
		if not intro_active and not completed and not get_tree().paused and is_instance_valid(pause_menu) and pause_menu.can_open:
			player._cancel_attack()
			pause_menu.open()


func _ready() -> void:
	total_gems = $items.get_child_count()
	if Save.is_free_mode():
		for item in $items.get_children():
			if item.collected:player.gems+=1
		if Save.is_legacy_cherry_history(level_id):
			player.gems=clampi(int(Save.get_level_stats(level_id).get("cherries",0)),0,total_gems)
		_gems_last=player.gems
	_polish_terrain()
	_spawn_fragments()
	_setup_enemies()
	player.gem_collected.connect(_update_gems)
	player.cherry_balance_changed.connect(_on_cherry_balance_changed)
	player.respawned.connect(_on_respawned)
	player.health_changed.connect(_update_health)
	player.died.connect(_on_player_died)
	for checkpoint in $Checkpoints.get_children():
		checkpoint.body_entered.connect(_on_checkpoint_entered.bind(checkpoint))
	$Finish.body_entered.connect(_on_finish_entered)
	_setup_pause_menu()
	_update_gems(player.gems)
	_update_health(player.health, player.MAX_HEALTH)
	game_hud.configure_intro(intro_title, intro_act)
	_start_sequence()


## Mostra a abertura da história (GDD §61) antes da abertura da fase, a não ser
## que o menu tenha pedido para pular.
func _start_sequence() -> void:
	var skip: bool = Save.consume_skip_intro()
	if not skip and not Save.has_seen_intro():
		var story = STORY_INTRO_SCRIPT.new()
		add_child(story)
		await story.finished
		Save.set_seen_intro()
	_begin_intro()


func _setup_enemies() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	total_enemies = enemies.size()
	for enemy in enemies:
		if enemy.has_signal("died"):
			enemy.died.connect(_on_enemy_died)


func _setup_pause_menu() -> void:
	pause_menu = PAUSE_MENU_SCRIPT.new()
	pause_menu.can_open = false
	pause_menu.resumed.connect(_on_pause_resumed)
	pause_menu.restart_requested.connect(_restart)
	add_child(pause_menu)


func _begin_intro() -> void:
	# A abertura anima na camada de interface; o mundo espera até ela terminar.
	pause_menu.can_open = false
	get_tree().paused = true
	game_hud.start_intro()
	await game_hud.intro_finished
	intro_active = false
	get_tree().paused = false
	pause_menu.can_open = true
	_elapsed = 0.0
	_timing = true
	_show_notice("Boa sorte na jornada!")
	Sfx.start()


func _process(delta: float) -> void:
	_update_notice(delta)
	if completed:
		return
	if _timing:
		_elapsed += delta
	var x := player.position.x
	_update_arrival_camera(delta, x)
	if x < 700.0:
		hint.text = "Setas / A D: mover  •  Espaço / W: pular  •  J / X / clique: atacar  •  ESC: menu"
	elif x < 1136.0:
		hint.text = "As plataformas esperam nas pontas. Pule e deixe elas carregarem você."
	elif x < 1552.0:
		hint.text = "Caverna: salte o vão. Segure Espaço / W para ir mais longe."
	elif x < 2416.0:
		hint.text = "Toque nas bandeiras da caverna para salvar seu ponto de retorno."
	elif x < 2496.0:
		hint.text = "Uma nova travessia à frente! Toque nas bandeiras para salvar o retorno.  •  ESC: menu"
	elif x < 3024.0:
		hint.text = "Pegue a plataforma para atravessar o vão. Espere o melhor momento.  •  ESC: menu"
	elif x < 3424.0:
		hint.text = "Use o elevador para alcançar a ilha alta. Segure o pulo para ir mais longe.  •  ESC: menu"
	elif x < 4224.0:
		hint.text = "Duas travessias e uma ilha para descansar. Vá no seu ritmo.  •  ESC: menu"
	else:
		hint.text = "A casa na árvore é a chegada! Pule até a varanda. R: voltar à bandeira.  •  ESC: menu"


func _update_arrival_camera(delta: float, x: float) -> void:
	# Abre o enquadramento só na chegada para mostrar a copa e as raízes.
	var camera := player.get_node("Camera2D") as Camera2D
	var arrival := smoothstep(4768.0, 5008.0, x)
	var follow := 1.0 - exp(-delta * 5.0)
	camera.zoom = camera.zoom.lerp(Vector2.ONE * lerpf(2.0, 1.25, arrival), follow)
	var desired_offset := Vector2(64, lerpf(-20.0, -120.0 - player.global_position.y, arrival))
	var current_offset: Vector2 = player.get("_camera_base_offset")
	player.set("_camera_base_offset", current_offset.lerp(desired_offset, follow))


func _physics_process(_delta: float) -> void:
	# A área é alcançada durante o salto; conclua só depois de pousar na varanda.
	if not completed and $Finish.overlaps_body(player):
		_on_finish_entered(player)


func _update_gems(total: int) -> void:
	if total > _gems_last:
		game_hud.set_face(ROSTO_FELIZ, 0.9)
	_gems_last = total
	game_hud.set_cherry_wallet(player.get_cherry_balance(), total, total_gems)
	_refresh_pause_summary()


func _on_cherry_balance_changed(balance: int) -> void:
	game_hud.set_cherry_wallet(balance, player.gems, total_gems)
	_refresh_pause_summary()


func _update_health(current: int, maximum: int) -> void:
	if current < _health_last:
		game_hud.set_face(ROSTO_SUSTO, 1.2)
	elif current > _health_last:
		game_hud.set_face(ROSTO_FELIZ, 1.0)
	_health_last = current
	game_hud.set_health(current, maximum)
	_refresh_pause_summary()


func _refresh_pause_summary() -> void:
	if pause_menu == null:
		return
	pause_menu.set_summary("Saldo: %d cerejas  •  Coletadas: %d/%d  •  Vida: %d/%d" % [
		player.get_cherry_balance(), player.gems, total_gems, maxi(player.health, 0), player.MAX_HEALTH
	])


func _on_enemy_died() -> void:
	defeated += 1
	game_hud.set_face(ROSTO_FELIZ, 0.8)


func _on_player_died() -> void:
	deaths += 1
	game_hud.set_face(ROSTO_CAIDO, 0.0)


func _on_secret_collected() -> void:
	secrets_found += 1
	game_hud.set_face(ROSTO_FELIZ, 1.0)


func _on_checkpoint_entered(body: Node2D, checkpoint) -> void:
	if body != player or completed or checkpoint == active_checkpoint:
		return
	# Ao voltar pelo mapa, mantenha o ponto de retorno mais avançado.
	if active_checkpoint != null and checkpoint.position.x < active_checkpoint.position.x:
		return
	active_checkpoint = checkpoint
	player.set_checkpoint(checkpoint.get_node("Spawn").global_position)
	player.heal_full()
	checkpoint.activate()
	_show_notice("Ponto de retorno ativado")
	Sfx.checkpoint()


func _on_respawned() -> void:
	$Player/Camera2D.reset_smoothing()
	game_hud.set_face(ROSTO_NORMAL, 0.0)
	_show_notice("De volta ao ponto de retorno. Tente outra vez!")


func _on_pause_resumed() -> void:
	# O tempo pode ter ficado congelado por um golpe; garanta o ritmo normal.
	Fx.cancel_hitstop()


func _show_notice(message: String) -> void:
	notice.text = message
	_notice_time = NOTICE_TIME if not message.is_empty() else 0.0


## Aparece suavemente e desaparece em vez de piscar.
func _update_notice(delta: float) -> void:
	_notice_time = maxf(_notice_time - delta, 0.0)
	if _notice_time <= 0.0:
		notice.visible = false
		return
	notice.visible = true
	var appear: float = clampf((NOTICE_TIME - _notice_time) / 0.16, 0.0, 1.0)
	var leave: float = clampf(_notice_time / 0.45, 0.0, 1.0)
	notice.modulate.a = minf(appear, leave)


func _on_finish_entered(body: Node2D) -> void:
	if body != player or completed or player.health <= 0:
		return
	if not player.is_on_floor() or absf(player.global_position.y + 11.0 - finish_floor_y) > 3.0:
		return
	completed = true
	_timing = false
	pause_menu.can_open = false
	player.finish_level()
	Sfx.finish()
	hint.text = ""
	var stats := _build_stats()
	var previous := Save.get_level_stats(level_id)
	var best := Save.mark_level_complete(level_id, stats)
	var new_record: bool = previous.is_empty() or (
		Save.rank_index(String(best.get("rank", "D"))) > Save.rank_index(String(previous.get("rank", "D")))
	)
	_start_finale(stats, new_record)


func _start_finale(stats: Dictionary, new_record: bool) -> void:
	# O resultado já está salvo; pular a cena preserva o mesmo progresso.
	_show_notice("")
	$HUD.hide()
	get_tree().paused = true
	if finale_script == null:
		_show_results(stats, new_record)
		return
	_finale = finale_script.new()
	_finale.name = "IslandFinale"
	_finale.finished.connect(_on_finale_finished.bind(stats, new_record), CONNECT_ONE_SHOT)
	add_child(_finale)


func _on_finale_finished(stats: Dictionary, new_record: bool) -> void:
	_finale = null
	# Resultados processam durante a pausa; o cenário permanece em repouso.
	_show_results(stats, new_record)


func _build_stats() -> Dictionary:
	var cherry_ratio := 1.0 if total_gems <= 0 else float(player.gems) / float(total_gems)
	var enemy_ratio := 1.0 if total_enemies <= 0 else float(defeated) / float(total_enemies)
	var secret_ratio := 1.0 if total_secrets <= 0 else float(secrets_found) / float(total_secrets)
	var collect := (cherry_ratio + enemy_ratio + secret_ratio) / 3.0
	return {
		"rank": Save.compute_rank(collect, _elapsed, par_time, deaths),
		"time": _elapsed,
		"cherries": player.gems,
		"enemies": defeated,
		"secrets": secrets_found,
		"deaths": deaths,
		"total_cherries": total_gems,
		"total_enemies": total_enemies,
		"total_secrets": total_secrets,
		"perfect": total_gems > 0 and player.gems >= total_gems,
	}


func _show_results(stats: Dictionary, new_record: bool) -> void:
	var perfect := bool(stats.get("perfect", false))
	_results = RESULTS_SCRIPT.new()
	_results.replay_requested.connect(_restart)
	_results.menu_requested.connect(_to_menu)
	_results.next_requested.connect(_next_level)
	add_child(_results)
	_results.setup("FASE PERFEITA!" if perfect else "FASE CONCLUÍDA!", level_name, stats, new_record, not next_level_scene.is_empty())


func _next_level() -> void:
	if next_level_scene.is_empty():
		return
	Fx.cancel_hitstop()
	get_tree().paused = false
	Save.request_play(true,Save.is_free_mode())
	get_tree().change_scene_to_file(next_level_scene)


func _to_menu() -> void:
	Fx.cancel_hitstop()
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)


func _restart() -> void:
	Fx.cancel_hitstop()
	get_tree().paused = false
	Save.request_play(true,Save.is_free_mode())
	get_tree().reload_current_scene()


## Coloca os Fragmentos (segredos) acima das plataformas móveis: são pontos que
## o jogador já precisa alcançar para atravessar, mas ficam fora do rastro de
## cerejas — recompensam quem explora (GDD §16 e §74).
func _spawn_fragments() -> void:
	var platforms := $MovingPlatforms.get_children()
	if platforms.is_empty():
		total_secrets = 0
		return

	var count: int = maxi(secret_count, 1)
	var spots: Array[Vector2] = []
	for index in count:
		# Distribui as plataformas igualmente pelo percurso da fase.
		var pick := 0
		if count > 1:
			pick = int(round(float(index) * float(platforms.size() - 1) / float(count - 1)))
		var platform: Node2D = platforms[pick]
		spots.append(_free_spot(platform.position + Vector2(0.0, -42.0)))

	total_secrets = spots.size()
	for spot: Vector2 in spots:
		var fragment = FRAGMENT_SCRIPT.new()
		fragment.position = spot
		fragment.collected.connect(_on_secret_collected)
		add_child(fragment)


## Sobe o ponto escolhido até achar espaço livre, caso ele caia no cenário.
func _free_spot(spot: Vector2) -> Vector2:
	var layer: TileMapLayer = $Level
	var position := spot
	for _i in 8:
		var cell := layer.local_to_map(position)
		if layer.get_cell_source_id(cell) == -1 and layer.get_cell_source_id(cell + Vector2i(0, -1)) == -1:
			return position
		position.y -= 16.0
	return position


## Os tiles já estão conectados na cena, inclusive no editor. O acabamento só
## compõe contornos nas faces expostas, sem trocar células nem suas colisões.
func _polish_terrain() -> void:
	var layer: TileMapLayer = $Level
	if layer.get_node_or_null("TerrainShade") == null:
		var shade: Node2D = TERRAIN_SHADE_SCRIPT.new()
		shade.name = "TerrainShade"
		layer.add_child(shade)

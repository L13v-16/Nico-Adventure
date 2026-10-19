extends Node
## Save — progresso e preferências que sobrevivem entre partidas.
##
## Registrado como autoload (ver project.godot). Guarda tudo em
## user://save.cfg: abertura já vista, tela cheia, e o melhor resultado de
## cada fase (nota, tempo, cerejas, inimigos, segredos e mortes), além do
## saldo de cerejas disponível para compras entre as fases.
## O volume de áudio continua em user://settings.cfg, cuidada pelo Sfx.

const SAVE_PATH := "user://save.cfg"
const SAVE_TEMP_PATH := "user://save.cfg.tmp"
const CAMPAIGN_LEVEL_IDS := ["fase_1", "fase_2"]
const MAX_CHERRY_BALANCE := 9223372036854775807
const RANK_ORDER := ["D", "C", "B", "A", "S"]
const FIRST_LEVEL_SCENE := "res://world/word_01.tscn"
const BEACH_LEVEL_SCENE := "res://world/beach_02.tscn"

## Guardado no arquivo: id da fase -> dicionário de resultados.
var _levels: Dictionary = {}
var _seen_intro := false
var _fullscreen := false
var _campaign_started := false
var _cherry_balance := 0
## Transitório (não vai para o disco): o menu pede à fase para pular a abertura.
var _pending_skip_intro := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()
	_apply_fullscreen()


# --- Progresso -----------------------------------------------------------------

func has_progress() -> bool:
	return _campaign_started or _seen_intro or not _levels.is_empty() or _cherry_balance > 0


func is_level_completed(level_id: String) -> bool:
	return _levels.has(level_id)


## Só a conclusão de toda a campanha libera o modo livre.
func is_game_completed() -> bool:
	for level_id in CAMPAIGN_LEVEL_IDS:
		if not is_level_completed(level_id):
			return false
	return true


func get_cherry_balance() -> int:
	return _cherry_balance


## A carteira é independente das cerejas usadas para a nota da fase.
## O chamador só deve confirmar a coleta quando a gravação for bem-sucedida.
func add_cherries(amount: int) -> bool:
	if amount <= 0 or _cherry_balance > MAX_CHERRY_BALANCE - amount:
		return false
	var previous_balance := _cherry_balance
	var previously_started := _campaign_started
	_cherry_balance += amount
	_campaign_started = true
	if not _save():
		_cherry_balance = previous_balance
		_campaign_started = previously_started
		return false
	return true


## Nunca debita parcialmente: inclusive uma falha de disco preserva o saldo.
func try_spend_cherries(amount: int) -> bool:
	if amount <= 0 or amount > _cherry_balance:
		return false
	var previous_balance := _cherry_balance
	_cherry_balance -= amount
	if not _save():
		_cherry_balance = previous_balance
		return false
	return true


func get_level_stats(level_id: String) -> Dictionary:
	return _levels.get(level_id, {})


func completed_count() -> int:
	return _levels.size()


## A próxima ilha é a praia depois do encontro com Arara Minas.
func get_continue_scene() -> String:
	if is_level_completed("fase_1") or is_level_completed("fase_2"):
		return BEACH_LEVEL_SCENE
	return FIRST_LEVEL_SCENE


## Guarda o resultado e mantém o melhor de cada campo. Devolve o recorde.
func mark_level_complete(level_id: String, stats: Dictionary) -> Dictionary:
	var previous: Dictionary = _levels.get(level_id, {})
	var best := stats.duplicate()
	best["total_cherries"] = int(stats.get("total_cherries", previous.get("total_cherries", 44 if level_id == "fase_1" else 0)))
	best["total_enemies"] = int(stats.get("total_enemies", previous.get("total_enemies", 0)))
	best["total_secrets"] = int(stats.get("total_secrets", previous.get("total_secrets", 3)))
	if not previous.is_empty():
		best["rank"] = _better_rank(String(previous.get("rank", "D")), String(stats.get("rank", "D")))
		best["time"] = minf(float(previous.get("time", INF)), float(stats.get("time", INF)))
		best["cherries"] = maxi(int(previous.get("cherries", 0)), int(stats.get("cherries", 0)))
		best["enemies"] = maxi(int(previous.get("enemies", 0)), int(stats.get("enemies", 0)))
		best["secrets"] = maxi(int(previous.get("secrets", 0)), int(stats.get("secrets", 0)))
		best["deaths"] = mini(int(previous.get("deaths", 999)), int(stats.get("deaths", 999)))
	_levels[level_id] = best
	_campaign_started = true
	_save()
	return best


func reset_progress() -> void:
	_levels.clear()
	_seen_intro = false
	_campaign_started = false
	_cherry_balance = 0
	_pending_skip_intro = false
	_save()


# --- Abertura da história ------------------------------------------------------

func has_seen_intro() -> bool:
	return _seen_intro


func set_seen_intro() -> void:
	if _seen_intro:
		return
	_seen_intro = true
	_save()


## O menu chama isto antes de carregar a fase.
func request_play(skip_intro: bool) -> void:
	_pending_skip_intro = skip_intro
	if not _campaign_started:
		_campaign_started = true
		_save()


## A fase chama isto uma vez e o pedido é limpo.
func consume_skip_intro() -> bool:
	var value := _pending_skip_intro
	_pending_skip_intro = false
	return value


# --- Vídeo ---------------------------------------------------------------------

func is_fullscreen() -> bool:
	return _fullscreen


func set_fullscreen(value: bool) -> void:
	_fullscreen = value
	_apply_fullscreen()
	_save()


func _apply_fullscreen() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if _fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)


# --- Classificação -------------------------------------------------------------

func rank_index(rank: String) -> int:
	return RANK_ORDER.find(rank)


func _better_rank(a: String, b: String) -> String:
	return a if rank_index(a) >= rank_index(b) else b


## Nota de 0 a 100 vira letra. `collect_ratio` vai de 0 a 1 (tudo coletado).
func compute_rank(collect_ratio: float, time: float, par_time: float, deaths: int) -> String:
	var score := clampf(collect_ratio, 0.0, 1.0) * 80.0
	var time_ratio := clampf(1.0 - (time - par_time) / maxf(par_time * 1.5, 1.0), 0.0, 1.0)
	score += time_ratio * 20.0
	score -= float(deaths) * 7.0
	score = clampf(score, 0.0, 100.0)
	if score >= 92.0:
		return "S"
	if score >= 80.0:
		return "A"
	if score >= 66.0:
		return "B"
	if score >= 48.0:
		return "C"
	return "D"


# --- Arquivo -------------------------------------------------------------------

func _load() -> void:
	# Recarregar também é seguro após apagar/trocar o arquivo de save.
	_levels.clear()
	_seen_intro = false
	_fullscreen = false
	_campaign_started = false
	_cherry_balance = 0
	_pending_skip_intro = false
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	_seen_intro = bool(config.get_value("progress", "seen_intro", false))
	_fullscreen = bool(config.get_value("video", "fullscreen", false))
	var saved_balance: Variant = config.get_value("wallet", "cherries", 0)
	if saved_balance is int:
		_cherry_balance = maxi(saved_balance, 0)
	_campaign_started = bool(config.get_value("progress", "started", false))
	var saved_levels: Variant = config.get_value("progress", "levels", [])
	if not (saved_levels is Array or saved_levels is PackedStringArray):
		return
	for level_id in saved_levels:
		var section := "level_%s" % str(level_id)
		if not config.has_section(section):
			continue
		_levels[str(level_id)] = {
			"rank": String(config.get_value(section, "rank", "D")),
			"time": float(config.get_value(section, "time", 0.0)),
			"cherries": int(config.get_value(section, "cherries", 0)),
			"enemies": int(config.get_value(section, "enemies", 0)),
			"secrets": int(config.get_value(section, "secrets", 0)),
			"deaths": int(config.get_value(section, "deaths", 0)),
			"total_cherries": int(config.get_value(section, "total_cherries", 44 if str(level_id) == "fase_1" else 0)),
			"total_enemies": int(config.get_value(section, "total_enemies", 0)),
			"total_secrets": int(config.get_value(section, "total_secrets", 3)),
		}


func _save() -> bool:
	var config := ConfigFile.new()
	# Mantém preferências e campos futuros sem reaproveitar recordes apagados.
	config.load(SAVE_PATH)
	for section in config.get_sections():
		if section.begins_with("level_"):
			config.erase_section(section)
	config.set_value("progress", "seen_intro", _seen_intro)
	config.set_value("progress", "started", _campaign_started)
	config.set_value("wallet", "cherries", _cherry_balance)
	config.set_value("progress", "levels", _levels.keys())
	config.set_value("video", "fullscreen", _fullscreen)
	for level_id in _levels.keys():
		var section := "level_%s" % str(level_id)
		var stats: Dictionary = _levels[level_id]
		config.set_value(section, "rank", stats.get("rank", "D"))
		config.set_value(section, "time", stats.get("time", 0.0))
		config.set_value(section, "cherries", stats.get("cherries", 0))
		config.set_value(section, "enemies", stats.get("enemies", 0))
		config.set_value(section, "secrets", stats.get("secrets", 0))
		config.set_value(section, "deaths", stats.get("deaths", 0))
		config.set_value(section, "total_cherries", stats.get("total_cherries", 0))
		config.set_value(section, "total_enemies", stats.get("total_enemies", 0))
		config.set_value(section, "total_secrets", stats.get("total_secrets", 0))
	# O arquivo válido só é substituído depois de a nova versão estar completa.
	# O rename no mesmo diretório substitui o destino sem truncar o save atual.
	var error := config.save(SAVE_TEMP_PATH)
	if error != OK:
		push_warning("Não foi possível gravar o progresso: %s" % error_string(error))
		return false
	error = DirAccess.rename_absolute(
		ProjectSettings.globalize_path(SAVE_TEMP_PATH),
		ProjectSettings.globalize_path(SAVE_PATH)
	)
	if error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_TEMP_PATH))
		push_warning("Não foi possível atualizar o progresso: %s" % error_string(error))
		return false
	return true

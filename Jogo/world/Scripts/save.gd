extends Node
## Save — progresso e preferências que sobrevivem entre partidas.
##
## Registrado como autoload (ver project.godot). Guarda tudo em
## user://save.cfg: abertura já vista, tela cheia, e o melhor resultado de
## cada fase (nota, tempo, cerejas, inimigos, segredos e mortes), além do
## saldo de cerejas disponível para compras entre as fases.
## O volume de áudio continua em user://settings.cfg, cuidada pelo Sfx.

const Catalog := preload("res://world/Scripts/equipment_catalog.gd")
const SAVE_PATH := "user://save.cfg"
const SAVE_TEMP_PATH := "user://save.cfg.tmp"
const CAMPAIGN_LEVEL_IDS := ["fase_1", "fase_2", "fase_3", "fase_4", "fase_5"]
const MAX_CHERRY_BALANCE := 9223372036854775807
const RANK_ORDER := ["D", "C", "B", "A", "S"]
const FIRST_LEVEL_SCENE := "res://world/word_01.tscn"
const BEACH_LEVEL_SCENE := "res://world/beach_02.tscn"
const MAGIC_LEVEL_SCENE := "res://world/magic_03.tscn"
const UNDERWORLD_LEVEL_SCENE := "res://world/underworld_04.tscn"
const LAB_LEVEL_SCENE := "res://world/lab_05.tscn"

## Guardado no arquivo: id da fase -> dicionário de resultados.
var _levels: Dictionary = {}
var _seen_intro := false
var _fullscreen := false
var _camera_shake := true
var _campaign_started := false
var _cherry_balance := 0
## Transitório (não vai para o disco): o menu pede à fase para pular a abertura.
var _pending_skip_intro := false
var _free_mode := false
var _collected_cherries: Dictionary = {}
var _legacy_cherry_locks: Dictionary = {}
var _story_flags: Dictionary = {}
var _owned_equipment: Dictionary = {}
var _equipped_equipment: Dictionary = {}


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


func is_free_mode() -> bool:
	return _free_mode

func has_story_flag(flag: String) -> bool:
	return _story_flags.has(flag)

func set_story_flag(flag: String) -> bool:
	if flag not in ["jose_rescued", "elemental_mastery", "depth_key", "lab_arrived", "lab_entrance_breached", "lab_3d_hatching_seen", "lab_dimension_breach_seen", "lab_largato_defeated", "urso_rescued"]:return false
	if _story_flags.has(flag):return true
	_story_flags[flag]=true
	if not _save():
		_story_flags.erase(flag)
		return false
	return true


func has_collected_cherry(level_id: String, cherry_id: String) -> bool:
	return _legacy_cherry_locks.has(level_id) or _collected_cherries.get(level_id,{}).has(cherry_id)


func is_legacy_cherry_history(level_id: String) -> bool:
	return _legacy_cherry_locks.has(level_id)


## History and wallet are committed together. A failed write cannot spend a
## collectible, and free-mode reloads cannot grant the same cherry twice.
func collect_level_cherry(level_id: String, cherry_id: String) -> bool:
	if level_id not in CAMPAIGN_LEVEL_IDS or cherry_id.is_empty():return false
	if _free_mode and has_collected_cherry(level_id,cherry_id):return false
	if _cherry_balance >= MAX_CHERRY_BALANCE:return false
	var previous:Dictionary=_collected_cherries.get(level_id,{}).duplicate()
	var previously_present:=_collected_cherries.has(level_id)
	var previously_started:=_campaign_started
	var collected:=previous.duplicate()
	collected[cherry_id]=true
	_collected_cherries[level_id]=collected
	_cherry_balance+=1
	_campaign_started=true
	if not _save():
		_cherry_balance-=1
		_campaign_started=previously_started
		if previously_present:_collected_cherries[level_id]=previous
		else:_collected_cherries.erase(level_id)
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


## Wallet and backpack share one atomic write: a failed purchase keeps both.
func get_equipment_state() -> Dictionary:
	return {"owned": _owned_equipment.duplicate(), "equipped": _equipped_equipment.duplicate()}


func commit_equipment_state(owned: Dictionary, equipped: Dictionary, cost: int = 0) -> bool:
	if cost < 0 or cost > _cherry_balance:return false
	var clean := _sanitize_equipment(owned, equipped)
	if clean.owned != owned or clean.equipped != equipped:return false
	var previous := get_equipment_state()
	var balance := _cherry_balance
	_owned_equipment = owned.duplicate()
	_equipped_equipment = equipped.duplicate()
	_cherry_balance -= cost
	if not _save():
		_owned_equipment = previous.owned
		_equipped_equipment = previous.equipped
		_cherry_balance = balance
		return false
	return true


func _sanitize_equipment(owned: Variant, equipped: Variant) -> Dictionary:
	var stock: Dictionary = {}
	var slots: Dictionary = {}
	if owned is Dictionary:
		for id in owned:
			if id is String and Catalog.ITEMS.has(id) and owned[id] is int and owned[id] > 0:
				stock[id] = mini(owned[id], 3 if Catalog.is_consumable(id) else 1)
	if equipped is Dictionary:
		for slot in equipped:
			var id: Variant = equipped[slot]
			if id is String and stock.has(id) and not Catalog.is_consumable(id) and Catalog.ITEMS[id].slot == slot:
				slots[slot] = id
	return {"owned": stock, "equipped": slots}


func get_level_stats(level_id: String) -> Dictionary:
	return _levels.get(level_id, {})


func completed_count() -> int:
	return _levels.size()


## Retoma o resgate seguinte sem apagar as ilhas nem a carteira existentes.
func get_continue_scene() -> String:
	if is_level_completed("fase_4") or is_level_completed("fase_5"):
		return LAB_LEVEL_SCENE
	if is_level_completed("fase_3") or is_level_completed("fase_4"):
		return UNDERWORLD_LEVEL_SCENE
	if is_level_completed("fase_2"):
		return MAGIC_LEVEL_SCENE
	if is_level_completed("fase_1"):
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
	_story_flags.clear()
	_owned_equipment.clear()
	_equipped_equipment.clear()
	_collected_cherries.clear()
	_legacy_cherry_locks.clear()
	_free_mode=false
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
func request_play(skip_intro: bool, free_mode: bool = false) -> void:
	_pending_skip_intro = skip_intro
	_free_mode=free_mode and is_game_completed()
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


func is_camera_shake_enabled() -> bool:
	return _camera_shake


func set_camera_shake_enabled(value: bool) -> void:
	_camera_shake = value
	_save()


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
	_story_flags.clear()
	_owned_equipment.clear()
	_equipped_equipment.clear()
	_seen_intro = false
	_fullscreen = false
	_camera_shake = true
	_campaign_started = false
	_cherry_balance = 0
	_pending_skip_intro = false
	_free_mode=false
	_collected_cherries.clear()
	_legacy_cherry_locks.clear()
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	_seen_intro = bool(config.get_value("progress", "seen_intro", false))
	_fullscreen = bool(config.get_value("video", "fullscreen", false))
	_camera_shake = bool(config.get_value("video", "camera_shake", true))
	var saved_flags:Variant=config.get_value("progress","story_flags",[])
	if saved_flags is Array or saved_flags is PackedStringArray:
		for flag in saved_flags:
			if flag in ["jose_rescued", "elemental_mastery", "depth_key", "lab_arrived", "lab_entrance_breached", "lab_3d_hatching_seen", "lab_dimension_breach_seen", "lab_largato_defeated", "urso_rescued"]:_story_flags[flag]=true
	var saved_balance: Variant = config.get_value("wallet", "cherries", 0)
	if saved_balance is int:
		_cherry_balance = maxi(saved_balance, 0)
	_campaign_started = bool(config.get_value("progress", "started", false))
	var equipment := _sanitize_equipment(config.get_value("equipment", "owned", {}), config.get_value("equipment", "equipped", {}))
	_owned_equipment = equipment.owned
	_equipped_equipment = equipment.equipped
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
	if config.get_value("cherry_history","version",0)==1:
		for level_id in CAMPAIGN_LEVEL_IDS:
			var stored:Variant=config.get_value("cherry_history",level_id,[])
			if not (stored is Array or stored is PackedStringArray):continue
			var collected:Dictionary={}
			for cherry_id in stored:
				if cherry_id is String and not cherry_id.is_empty():collected[cherry_id]=true
			_collected_cherries[level_id]=collected
		var legacy:Variant=config.get_value("cherry_history","legacy_completed",[])
		if legacy is Array or legacy is PackedStringArray:
			for level_id in legacy:
				if level_id in CAMPAIGN_LEVEL_IDS:_legacy_cherry_locks[level_id]=true
	else:
		# Older saves know the best count, but not the individual locations.
		# Protect completed islands from extra credits without touching the wallet.
		for level_id in CAMPAIGN_LEVEL_IDS:
			if is_level_completed(level_id):_legacy_cherry_locks[level_id]=true


func _save() -> bool:
	var config := ConfigFile.new()
	# Mantém preferências e campos futuros sem reaproveitar recordes apagados.
	config.load(SAVE_PATH)
	for section in config.get_sections():
		if section.begins_with("level_"):
			config.erase_section(section)
	config.set_value("progress", "seen_intro", _seen_intro)
	config.set_value("progress", "started", _campaign_started)
	config.set_value("progress", "story_flags", _story_flags.keys())
	config.set_value("wallet", "cherries", _cherry_balance)
	config.set_value("equipment", "version", 1)
	config.set_value("equipment", "owned", _owned_equipment)
	config.set_value("equipment", "equipped", _equipped_equipment)
	config.set_value("progress", "levels", _levels.keys())
	config.set_value("video", "fullscreen", _fullscreen)
	config.set_value("video", "camera_shake", _camera_shake)
	config.set_value("cherry_history","version",1)
	config.set_value("cherry_history","legacy_completed",_legacy_cherry_locks.keys())
	for level_id in CAMPAIGN_LEVEL_IDS:
		config.set_value("cherry_history",level_id,_collected_cherries.get(level_id,{}).keys())
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

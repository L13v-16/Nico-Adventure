extends Node
## A mochila e as peças equipadas acompanham Nico entre fases e partidas.

signal changed

const Catalog := preload("res://world/Scripts/equipment_catalog.gd")
const FROST_DURATION := 30.0
var _owned: Dictionary = {}
var _equipped: Dictionary = {}
var _frost_left := 0.0
var _player: Node
var _inventory: CanvasLayer
var _transaction_busy := false


func _ready() -> void:
	_player = get_parent()
	var stored := Save.get_equipment_state()
	_owned = stored.owned
	_equipped = stored.equipped
	_player.respawned.connect(_clear_temporary)
	_player.died.connect(_clear_temporary)
	_build_presentations.call_deferred()


func _build_presentations() -> void:
	var inventory_script := load("res://world/Scripts/equipment_inventory.gd") as GDScript
	_inventory = inventory_script.new()
	_inventory.name = "EquipmentInventory"
	_inventory.set("model", self)
	_inventory.set("player", _player)
	add_child(_inventory)
	var path := "res://world/Scripts/equipment_visual.gd"
	if ResourceLoader.exists(path):
		var visual: Node2D = load(path).new()
		visual.name = "EquipmentVisual"
		visual.set("model", self)
		_player.add_child(visual)


func _process(delta: float) -> void:
	if _frost_left > 0.0:
		_frost_left = maxf(_frost_left - delta, 0.0)
		if _frost_left <= 0.0:
			changed.emit()
	if bool(_player.get("_finished")) and _frost_left > 0.0:
		_clear_temporary()


func owns(item_id: String) -> bool:
	return get_quantity(item_id) > 0


func get_quantity(item_id: String) -> int:
	return int(_owned.get(item_id, 0))


func is_equipped(item_id: String) -> bool:
	if not Catalog.ITEMS.has(item_id):
		return false
	return _equipped.get(Catalog.ITEMS[item_id]["slot"], "") == item_id


func get_equipped_items() -> Array:
	return _equipped.values().duplicate()


func get_damage_multiplier() -> float:
	return 1.2 if is_equipped("claws") else 1.0


func get_speed_multiplier() -> float:
	return 1.1 if is_equipped("sneakers") else 1.0


func get_attack_cooldown_multiplier() -> float:
	return 0.85 if is_equipped("swift_gloves") else 1.0


func get_jump_multiplier() -> float:
	return 1.1 if is_equipped("jump_brooch") else 1.0


func get_freeze_duration() -> float:
	return 2.0 + (2.0 if _frost_left > 0.0 else 0.0) + (2.0 if is_equipped("lasting_ice") else 0.0)


func get_frost_boost_left() -> float:
	return _frost_left


func buy_item(item_id: String) -> Dictionary:
	if _transaction_busy or not Catalog.ITEMS.has(item_id) or _player.is_dead():
		return _result(false, "Não foi possível comprar este item agora.")
	var item: Dictionary = Catalog.ITEMS[item_id]
	if owns(item_id) and not Catalog.is_consumable(item_id):
		return _result(false, "Você já tem este item. Equipe ou retire pela mochila [I].")
	if Catalog.is_consumable(item_id) and get_quantity(item_id) >= 3:
		return _result(false, "Limite de 3 unidades deste suprimento na mochila.")
	var price := int(item["price"])
	if _player.get_cherry_balance() < price:
		return _result(false, "Cerejas insuficientes. Escolha outro item antes de seguir viagem.")
	_transaction_busy = true
	var stock := _owned.duplicate()
	var slots := _equipped.duplicate()
	stock[item_id] = get_quantity(item_id) + 1
	if not Catalog.is_consumable(item_id):slots[item["slot"]] = item_id
	if not _commit(stock, slots, price):
		_transaction_busy = false
		return _result(false, "Não foi possível salvar a compra. Suas cerejas foram mantidas.")
	_player.cherries_spent += price
	_player.cherry_balance_changed.emit(_player.get_cherry_balance())
	_transaction_busy = false
	return _result(true, "%s %s" % [item["name"], "guardado na mochila [I]. Use quando precisar." if Catalog.is_consumable(item_id) else "comprado e equipado! Troque pela mochila [I]."])


func toggle_item(item_id: String) -> Dictionary:
	if _transaction_busy or not Catalog.ITEMS.has(item_id) or not owns(item_id) or _player.is_dead():
		return _result(false, "Você não tem este item na mochila.")
	var item: Dictionary = Catalog.ITEMS[item_id]
	var stock := _owned.duplicate()
	var slots := _equipped.duplicate()
	if Catalog.is_consumable(item_id):
		if item_id == "honey_biscuit" and _player.health >= _player.MAX_HEALTH:
			return _result(false, "Vida cheia! O biscoito continua na mochila.")
		var level := _player.get_parent()
		if item_id == "travel_acai" and (not level.has_method("buy_acai_power") or level.completed or level.intro_active):
			return _result(false, "Não é possível usar o açaí agora. Ele continua na mochila.")
		if get_quantity(item_id) > 1:stock[item_id] = get_quantity(item_id) - 1
		else:stock.erase(item_id)
		if not _commit(stock, slots):return _save_rejected()
		if item_id == "honey_biscuit":
			_player.heal_one()
			return _result(true, "Biscoito de Mel: 1 coração recuperado!")
		if item_id == "travel_acai":
			level.buy_acai_power()
			return _result(true, "Açaí de Viagem: K dispara gelo por 12 s, com proteção e ataque dobrado.")
		_frost_left = FROST_DURATION
		_player.elements.refresh_available("ice")
		changed.emit()
		return _result(true, "Açaí Congelante: K dispara gelo por 30 s; golpes e disparos congelam por mais tempo!")
	var was_equipped := is_equipped(item_id)
	if was_equipped:slots.erase(item["slot"])
	else:slots[item["slot"]] = item_id
	if not _commit(stock, slots):return _save_rejected()
	return _result(true, "%s %s" % [item["name"], "guardado." if was_equipped else "equipado!"])


func consume_leaf() -> bool:
	if not is_equipped("leaf") or not owns("leaf"):return false
	var stock := _owned.duplicate()
	var slots := _equipped.duplicate()
	slots.erase("charm")
	stock.erase("leaf")
	return _commit(stock, slots)


func _commit(stock: Dictionary, slots: Dictionary, cost: int = 0) -> bool:
	if not Save.commit_equipment_state(stock, slots, cost):return false
	_owned = stock
	_equipped = slots
	changed.emit()
	return true


func _save_rejected() -> Dictionary:
	return _result(false, "Não foi possível salvar a mochila. Seus itens foram mantidos.")


func open_inventory() -> void:
	if is_instance_valid(_inventory):
		_inventory.call("open")


func clear_temporary() -> void:
	_clear_temporary()
	if bool(_player.get("_finished")) and is_instance_valid(_inventory):
		_inventory.call("close")


func _clear_temporary() -> void:
	_frost_left = 0.0
	changed.emit()


func _result(ok: bool, message: String) -> Dictionary:
	return {"ok": ok, "message": message}

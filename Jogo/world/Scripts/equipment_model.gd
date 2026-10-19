extends Node
## Itens pertencem à tentativa atual; peças compradas sobrevivem ao respawn.

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


func get_freeze_duration() -> float:
	return 2.0 + (2.0 if _frost_left > 0.0 else 0.0) + (2.0 if is_equipped("lasting_ice") else 0.0)


func get_frost_boost_left() -> float:
	return _frost_left


func buy_item(item_id: String) -> Dictionary:
	if _transaction_busy or not Catalog.ITEMS.has(item_id) or _player.is_dead():
		return _result(false, "Não foi possível comprar este item agora.")
	var item: Dictionary = Catalog.ITEMS[item_id]
	if owns(item_id) and item_id != "frozen_acai":
		return _result(false, "Você já tem este item. Equipe ou retire pela mochila [I].")
	if item_id == "frozen_acai" and get_quantity(item_id) >= 3:
		return _result(false, "A mochila já tem 3 açaís congelantes.")
	var price := int(item["price"])
	if _player.get_cherry_balance() < price:
		return _result(false, "Cerejas insuficientes. Escolha outro item antes de seguir viagem.")
	_transaction_busy = true
	if not _player.try_spend_cherries(price):
		_transaction_busy = false
		return _result(false, "Saldo insuficiente para esta compra.")
	_owned[item_id] = get_quantity(item_id) + 1
	if item_id != "frozen_acai":
		_equipped[item["slot"]] = item_id
	changed.emit()
	_transaction_busy = false
	return _result(true, "%s %s" % [item["name"], "guardado na mochila [I]. Use quando precisar." if item_id == "frozen_acai" else "comprado e equipado! Troque pela mochila [I]."])


func toggle_item(item_id: String) -> Dictionary:
	if not Catalog.ITEMS.has(item_id) or not owns(item_id) or _player.is_dead():
		return _result(false, "Você não tem este item na mochila.")
	var item: Dictionary = Catalog.ITEMS[item_id]
	if item_id == "frozen_acai":
		_owned[item_id] = get_quantity(item_id) - 1
		_frost_left = FROST_DURATION
		changed.emit()
		return _result(true, "Açaí Congelante ativo por 30 s. Acerte golpes para congelar inimigos!")
	if is_equipped(item_id):
		_equipped.erase(item["slot"])
		changed.emit()
		return _result(true, "%s guardado." % item["name"])
	_equipped[item["slot"]] = item_id
	changed.emit()
	return _result(true, "%s equipado!" % item["name"])


func consume_leaf() -> bool:
	if not is_equipped("leaf") or not owns("leaf"):
		return false
	_equipped.erase("charm")
	_owned.erase("leaf")
	changed.emit()
	return true


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

extends Area2D
## Açaí: proteção, dano dobrado e golpes congelantes por 12 segundos, sem curar.
## Cada fruto é consumido uma vez. Outro fruto renova o efeito sem acumular.

const ART_PATH := "res://world/Arte/Beach/acai.png"
const PROTECTION_REFRESH := 0.1

@export_range(1.0, 60.0, 0.5) var duration := 12.0

var _consumed := false
var _active := false
var _time_left := 0.0
var _elapsed := 0.0
var _player: Node2D
var _sprite: Sprite2D
var _texture: Texture2D
var _aura: Node2D


func _ready() -> void:
	add_to_group("acai_power")
	# Renova a proteção antes dos inimigos e de o jogador processarem o quadro.
	process_physics_priority = -10
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	var shape := CircleShape2D.new()
	shape.radius = 13.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	_sprite = Sprite2D.new()
	_sprite.name = "AcaiSprite"
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists(ART_PATH):
		_texture = load(ART_PATH) as Texture2D
	_sprite.texture = _texture
	add_child(_sprite)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func is_active() -> bool:
	return _active


func get_time_left() -> float:
	return _time_left if _active else 0.0


func _on_body_entered(body: Node2D) -> void:
	activate_for(body)


## Frutos e compras usam o mesmo efeito, inclusive renovação e limpeza.
func activate_for(body: Node2D) -> bool:
	if _consumed or not body.is_in_group("player"):
		return false
	if body.has_method("is_dead") and bool(body.call("is_dead")):
		return false
	# Uma única aura e um único contador, mesmo ao pegar outro fruto cedo.
	for other: Node in get_tree().get_nodes_in_group("acai_power"):
		if other != self and other.has_method("is_active") and bool(other.call("is_active")):
			other.call("_deactivate")
	_consumed = true
	_active = true
	_time_left = duration
	_player = body
	_sprite.hide()
	set_deferred("monitoring", false)
	for signal_name: String in ["died", "respawned", "tree_exiting"]:
		if body.has_signal(signal_name) and not body.is_connected(signal_name, _on_player_reset):
			body.connect(signal_name, _on_player_reset)
	_apply_effect()
	_make_aura()
	if _player.has_method("set_acai_power"):_player.set_acai_power(self)
	var sfx: Node = get_node_or_null("/root/Sfx")
	if sfx != null and sfx.has_method("secret"):
		sfx.call("secret")
	queue_redraw()
	return true


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if not _consumed:
		_sprite.position.y = roundf(sin(_elapsed * 3.0) * 2.0)
		queue_redraw()
	if not _active:
		return
	if not is_instance_valid(_player):
		_deactivate()
		return
	if _player.has_method("is_dead") and bool(_player.call("is_dead")):
		_deactivate()
		return
	_time_left = maxf(_time_left - delta, 0.0)
	if _time_left <= 0.0:
		_deactivate()
		return
	_apply_effect()
	if is_instance_valid(_aura):
		_aura.global_position = _player.global_position + Vector2(0, -4)
		_aura.queue_redraw()


func _apply_effect() -> void:
	if not is_instance_valid(_player):
		return
	_player.set("attack_damage", 2)
	var current: float = float(_player.get("_invulnerability_timer"))
	_player.set("_invulnerability_timer", maxf(current, PROTECTION_REFRESH))


func _on_player_reset() -> void:
	_deactivate()


func _deactivate() -> void:
	if not _active:
		return
	_active = false
	_time_left = 0.0
	if is_instance_valid(_player):
		_player.set("attack_damage", 1)
		if _player.has_method("set_acai_power"):_player.set_acai_power(null)
		# Preserva a invulnerabilidade maior da bandeira e de um impacto anterior.
		if float(_player.get("_invulnerability_timer")) <= PROTECTION_REFRESH + 0.001:
			_player.set("_invulnerability_timer", 0.0)
		for signal_name: String in ["died", "respawned", "tree_exiting"]:
			if _player.has_signal(signal_name) and _player.is_connected(signal_name, _on_player_reset):
				_player.disconnect(signal_name, _on_player_reset)
	_player = null
	if is_instance_valid(_aura):
		_aura.queue_free()
	_aura = null


func _exit_tree() -> void:
	_deactivate()


func _make_aura() -> void:
	_aura = Node2D.new()
	_aura.name = "AcaiAura"
	_aura.z_index = 20
	_aura.draw.connect(_draw_aura)
	add_child(_aura)
	_aura.global_position = _player.global_position + Vector2(0, -4)
	_aura.queue_redraw()


func _draw() -> void:
	if _consumed:
		return
	for index: int in 3:
		var angle: float = _elapsed * 1.4 + float(index) * TAU / 3.0
		var at := Vector2(cos(angle) * 17.0, sin(angle) * 8.0)
		draw_rect(Rect2(at.round(), Vector2(1, 1)), Color(0.84, 0.54, 1.0, 0.65))


func _draw_aura() -> void:
	if not _active or not is_instance_valid(_aura):
		return
	var radius: float = 19.0 + sin(_elapsed * 4.0) * 1.0
	_aura.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(0.67, 0.34, 0.9, 0.3), 1.0)
	for index: int in 5:
		var angle: float = _elapsed * 1.6 + float(index) * TAU / 5.0
		var at := Vector2(cos(angle), sin(angle)) * radius
		_aura.draw_rect(Rect2(at.round(), Vector2(2, 2)), Color(0.83, 0.54, 1.0, 0.56))



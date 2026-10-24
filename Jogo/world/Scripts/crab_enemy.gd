extends CharacterBody2D
## Caranguejo: os socos batem no casco; um salto descendente o derrota.

signal died

@export var walk_frames: Array[Texture2D] = []
@export var stomp_frames: Array[Texture2D] = []
@export var patrol_radius := 56.0
@export var speed := 35.0

var health := 1
var direction := -1.0
var _spawn_x := 0.0
var _time := 0.0
var _dead := false
var _death_time := 0.0
var _notice_left := 0.0
var _previous_feet: Dictionary = {}
var _contact: Area2D
var _floor_probe: RayCast2D
var _body_shape: CollisionShape2D
var _freeze_left := 0.0


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("crabs")
	process_physics_priority = 10
	collision_layer = 4
	collision_mask = 1
	_spawn_x = global_position.x
	_body_shape = CollisionShape2D.new()
	var body := RectangleShape2D.new()
	body.size = Vector2(26, 12)
	_body_shape.shape = body
	_body_shape.position = Vector2(0, -6)
	add_child(_body_shape)
	_contact = Area2D.new()
	_contact.collision_layer = 0
	_contact.collision_mask = 2
	_contact.monitorable = false
	var contact_shape := CollisionShape2D.new()
	var contact_rect := RectangleShape2D.new()
	contact_rect.size = Vector2(38, 22)
	contact_shape.shape = contact_rect
	contact_shape.position = Vector2(0, -11)
	_contact.add_child(contact_shape)
	add_child(_contact)
	_floor_probe = RayCast2D.new()
	_floor_probe.target_position = Vector2(0, 22)
	_floor_probe.collision_mask = 1
	_floor_probe.exclude_parent = true
	add_child(_floor_probe)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not is_frozen():
		_time += delta
	_notice_left = maxf(_notice_left - delta, 0.0)
	if _dead:
		_death_time += delta
		if _death_time >= 0.25:
			queue_free()
		queue_redraw()
		return
	if is_frozen():
		_freeze_left = maxf(_freeze_left - delta, 0.0)
		velocity.x = 0.0
		if not is_on_floor():
			velocity.y = minf(velocity.y + get_gravity().y * delta, 700.0)
		move_and_slide()
		_check_players(delta)
		queue_redraw()
		return
	if is_on_floor():
		_floor_probe.position = Vector2(direction * 19.0, -8)
		_floor_probe.force_raycast_update()
		var beyond := (global_position.x >= _spawn_x + patrol_radius and direction > 0) or (global_position.x <= _spawn_x - patrol_radius and direction < 0)
		if beyond or not _floor_probe.is_colliding():
			direction *= -1.0
	else:
		velocity.y = minf(velocity.y + get_gravity().y * delta, 700.0)
	velocity.x = direction * speed
	move_and_slide()
	_check_players(delta)
	queue_redraw()


func _check_players(delta: float) -> void:
	var top := global_position.y - 14.0
	for candidate in get_tree().get_nodes_in_group("player"):
		var player := candidate as CharacterBody2D
		if player == null:
			continue
		var feet := player.global_position + Vector2(0, 11)
		var key := player.get_instance_id()
		var reset := _forget_player.bind(key)
		if not player.respawned.is_connected(reset):
			player.respawned.connect(reset)
			player.died.connect(reset)
		var previous: Vector2 = _previous_feet.get(key, feet - player.velocity * delta)
		if previous.distance_to(feet) > 100.0:
			previous = feet - player.velocity * delta
		_previous_feet[key] = feet
		if player.is_dead() or player.get_meta("cannon_flight", false):
			continue
		var descending: bool = player.velocity.y > 20.0 and feet.y > previous.y
		var crossing: bool = previous.y <= top + 0.25 and feet.y >= top - 0.25
		if descending and crossing:
			var progress := clampf((top - previous.y) / maxf(feet.y - previous.y, 0.001), 0.0, 1.0)
			var cross_x := lerpf(previous.x, feet.x, progress)
			if absf(cross_x - global_position.x) <= 20.0:
				_stomp(player)
				return
		# Acima do casco, espere a travessia dos pés: tocar a margem superior
		# da área de contato durante a descida não deve machucar antes do pouso.
		if not is_frozen() and _contact.overlaps_body(player) and feet.y > top + 4.0:
			player.take_damage(1, global_position + Vector2(0, -6))


func _forget_player(id: int) -> void:
	_previous_feet.erase(id)


func _stomp(player: CharacterBody2D) -> void:
	if _dead:
		return
	_dead = true
	health = 0
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	_body_shape.set_deferred("disabled", true)
	_contact.set_deferred("monitoring", false)
	player.velocity.y = -270.0
	player.set("_jump_buffer_timer", 0.0)
	player.set("_coyote_timer", 0.0)
	player.set("_jump_was_held", Input.is_action_pressed("ui_accept") or Input.is_physical_key_pressed(KEY_W))
	player.call("update_state", 0.0)
	player.call("play_state_animation")
	Fx.burst(global_position + Vector2(0, -10), Color(1.0, 0.80, 0.49), 8, 90.0)
	Sfx.enemy_death()
	died.emit()
	queue_redraw()


func take_damage(_amount: float, _source: Vector2) -> void:
	if _dead or _notice_left > 0.0:
		return
	_notice_left = 1.2
	Fx.popup(global_position + Vector2(0, -26), "Pule no casco!", Color(1.0, 0.87, 0.53), 10)
	Sfx.select()


func freeze_for(duration: float) -> void:
	if _dead or duration <= 0.0:
		return
	_freeze_left = maxf(_freeze_left, duration)
	velocity.x = 0.0
	Fx.burst(global_position + Vector2(0, -10), Color("b8f1ff"), 6, 70.0)
	queue_redraw()


func is_frozen() -> bool:
	return _freeze_left > 0.0 and not _dead


func is_dead() -> bool:
	return _dead


func _draw() -> void:
	var frame: Texture2D
	if _dead and not stomp_frames.is_empty():
		frame = stomp_frames[mini(int(_death_time / 0.25 * stomp_frames.size()), stomp_frames.size() - 1)]
	elif not walk_frames.is_empty():
		frame = walk_frames[int(_time * 8.0) % walk_frames.size()]
	if frame != null:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1) if direction > 0 else Vector2.ONE)
		draw_texture_rect(frame, Rect2(-16, -24, 32, 24), false)
		draw_set_transform(Vector2.ZERO)
	else:
		var squish := 0.4 if _dead else 1.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, squish))
		draw_rect(Rect2(-13, -14, 26, 11), Color(0.80, 0.31, 0.21))
		draw_rect(Rect2(-10, -17, 20, 5), Color(1.0, 0.61, 0.34))
		draw_rect(Rect2(-9, -21, 4, 6), Color(0.95, 0.82, 0.51))
		draw_rect(Rect2(5, -21, 4, 6), Color(0.95, 0.82, 0.51))
		draw_rect(Rect2(-8, -21, 2, 3), Color(0.12, 0.16, 0.20))
		draw_rect(Rect2(6, -21, 2, 3), Color(0.12, 0.16, 0.20))
		for side in [-1.0, 1.0]:
			for index in 3:
				var leg_y := -3.0 - float(index) * 3.0
				draw_line(Vector2(side * 10, leg_y), Vector2(side * (16 + index % 2), leg_y + 3), Color(0.77, 0.37, 0.22), 2.0)
		draw_set_transform(Vector2.ZERO)

	if is_frozen():
		var ice := PackedVector2Array([Vector2(-18, -18), Vector2(-12, -26), Vector2(12, -26), Vector2(18, -18), Vector2(18, 1), Vector2(-18, 1), Vector2(-18, -18)])
		draw_colored_polygon(ice, Color(0.55, 0.87, 1.0, 0.23))
		draw_polyline(ice, Color(0.73, 0.96, 1.0, 0.92), 1.0)
		draw_line(Vector2(-12, -21), Vector2(-3, -11), Color(0.91, 1.0, 1.0, 0.65), 1.0)
		draw_line(Vector2(10, -19), Vector2(15, -5), Color(0.91, 1.0, 1.0, 0.65), 1.0)

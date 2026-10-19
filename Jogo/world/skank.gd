extends CharacterBody2D
## Patrulha o chão, avisa antes de investir e recebe golpes do jogador.

signal died

enum EnemyState { PATROL, ALERT, CHARGE, RECOVER, HURT, DEAD }

@export_group("Patrulha")
@export var speed: float = 55.0
## Distância máxima para cada lado do ponto em que o inimigo nasceu.
@export var patrol_radius: float = 72.0
@export var detection_range: float = 120.0

@export_group("Combate")
@export var health: float = 2.0
@export var charge_speed: float = 160.0
@export var alert_duration: float = 0.4
@export var charge_duration: float = 0.4
@export var recovery_duration: float = 0.85
@export var fall_limit: float = 400.0

var direction: int = -1
var state: EnemyState = EnemyState.PATROL
var _spawn_x: float
var _maximum_health: float
var _state_time: float = 0.0
var _freeze_left := 0.0
var _hurt_invulnerability_left := 0.0

@onready var anim: AnimatedSprite2D = $anim
@onready var floor_probe: RayCast2D = $FloorProbe
@onready var wall_probe: RayCast2D = $WallProbe
@onready var hitbox: Area2D = $Hitbox
@onready var death_puff: AnimatedSprite2D = $DeathPuff


func _ready() -> void:
	add_to_group("enemies")
	_spawn_x = global_position.x
	_maximum_health = maxf(health, 1.0)
	health = _maximum_health
	death_puff.animation_finished.connect(_on_death_animation_finished)
	anim.play("default")
	_update_visuals()


func _physics_process(delta: float) -> void:
	_hurt_invulnerability_left = maxf(_hurt_invulnerability_left - delta, 0.0)
	if state == EnemyState.DEAD:
		return
	# Um inimigo lançado no abismo conta como derrotado e libera seus recursos.
	if global_position.y > fall_limit:
		_die()
		return
	if is_frozen():
		_freeze_left = maxf(_freeze_left - delta, 0.0)
		velocity.x = 0.0
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		_update_visuals()
		queue_redraw()
		return
	_state_time += delta
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif velocity.y > 0.0:
		velocity.y = 0.0

	match state:
		EnemyState.PATROL:
			_patrol()
		EnemyState.ALERT:
			velocity.x = 0.0
			if _state_time >= alert_duration:
				_enter_state(EnemyState.CHARGE)
		EnemyState.CHARGE:
			# A investida também respeita buracos e paredes.
			if _state_time >= charge_duration or (is_on_floor() and not _front_is_safe()):
				_enter_state(EnemyState.RECOVER)
			else:
				velocity.x = charge_speed * direction
		EnemyState.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _state_time >= recovery_duration:
				_enter_state(EnemyState.PATROL)
		EnemyState.HURT:
			velocity.x = move_toward(velocity.x, 0.0, 260.0 * delta)
			if _state_time >= 0.25:
				_enter_state(EnemyState.RECOVER)

	move_and_slide()
	_update_visuals()
	_damage_touching_player()
	queue_redraw()


func _patrol() -> void:
	if is_on_floor():
		var beyond_right: bool = global_position.x >= _spawn_x + patrol_radius and direction > 0
		var beyond_left: bool = global_position.x <= _spawn_x - patrol_radius and direction < 0
		if beyond_right or beyond_left or not _front_is_safe():
			direction *= -1
		# Se estiver numa ilha muito pequena, espera em vez de cair da outra ponta.
		velocity.x = speed * direction if _front_is_safe() else 0.0
		var target: Node2D = _find_nearby_player()
		if target != null:
			var previous_direction: int = direction
			if not is_zero_approx(target.global_position.x - global_position.x):
				direction = 1 if target.global_position.x > global_position.x else -1
			if _front_is_safe():
				_enter_state(EnemyState.ALERT)
			else:
				direction = previous_direction
	else:
		velocity.x = speed * direction


func _front_is_safe() -> bool:
	# Corpo e sprite têm centro x=7 e pés y=4. Os sensores olham além do corpo.
	floor_probe.position = Vector2(7.0 + 20.0 * direction, -10.0)
	wall_probe.target_position = Vector2(20.0 * direction, 0.0)
	floor_probe.force_raycast_update()
	wall_probe.force_raycast_update()
	return floor_probe.is_colliding() and not wall_probe.is_colliding()


func _find_nearby_player() -> Node2D:
	for candidate in get_tree().get_nodes_in_group("player"):
		var target: Node2D = candidate as Node2D
		if target == null:
			continue
		if target.has_method("is_dead") and target.call("is_dead"):
			continue
		var offset: Vector2 = target.global_position - global_position
		if absf(offset.x) <= detection_range and absf(offset.y) <= 24.0:
			return target
	return null


func _enter_state(next_state: EnemyState) -> void:
	state = next_state
	_state_time = 0.0
	if state == EnemyState.ALERT or state == EnemyState.RECOVER:
		velocity.x = 0.0
	if state == EnemyState.ALERT:
		Sfx.alert()


func _damage_touching_player() -> void:
	if state == EnemyState.HURT or state == EnemyState.DEAD or is_frozen():
		return
	# Repetir a consulta permite que a imunidade do jogador termine sem exigir
	# que ele saia e entre de novo na área. O jogador controla seus próprios iframes.
	for body in hitbox.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.call("take_damage", 1, global_position)


func take_damage(amount: float, source_position: Vector2) -> void:
	if amount <= 0 or state == EnemyState.DEAD or _hurt_invulnerability_left > 0.0:
		return
	_hurt_invulnerability_left = 0.25
	health = maxf(health - amount, 0.0)
	if health == 0:
		_die()
		return
	_enter_state(EnemyState.HURT)
	var away: float = signf(global_position.x - source_position.x)
	if is_zero_approx(away):
		away = -float(direction)
	velocity = Vector2(away * 110.0, -95.0)
	Fx.burst(global_position + Vector2(7.0, -10.0), Color(1.0, 0.85, 0.6), 6, 130.0)
	Fx.popup(global_position + Vector2(7.0, -30.0), "-%s" % ("%.1f" % amount).trim_suffix(".0"), Color(1.0, 0.95, 0.78), 8)
	_update_visuals()
	queue_redraw()


func freeze_for(duration: float) -> void:
	if is_dead() or duration <= 0.0:
		return
	_freeze_left = maxf(_freeze_left, duration)
	velocity.x = 0.0
	Fx.burst(global_position + Vector2(7, -10), Color("b8f1ff"), 6, 70.0)
	_update_visuals()
	queue_redraw()


func is_frozen() -> bool:
	return _freeze_left > 0.0 and not is_dead()


func is_dead() -> bool:
	return state == EnemyState.DEAD


func _die() -> void:
	_enter_state(EnemyState.DEAD)
	died.emit()
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	$CollisionShape2D.set_deferred("disabled", true)
	hitbox.set_deferred("monitoring", false)
	anim.hide()
	death_puff.show()
	death_puff.play("death")
	Fx.burst(global_position + Vector2(7.0, -10.0), Color(1.0, 0.6, 0.45), 14, 200.0)
	Sfx.enemy_death()
	queue_redraw()


func _on_death_animation_finished() -> void:
	if state == EnemyState.DEAD:
		queue_free()


func _update_visuals() -> void:
	anim.flip_h = direction > 0
	anim.modulate = Color.WHITE
	anim.speed_scale = 1.4
	match state:
		EnemyState.ALERT:
			anim.modulate = Color(1.0, 0.65, 0.52)
			anim.speed_scale = 0.0
		EnemyState.CHARGE:
			anim.modulate = Color(1.0, 0.82, 0.68)
			anim.speed_scale = 2.8
		EnemyState.RECOVER:
			anim.speed_scale = 0.6
		EnemyState.HURT:
			anim.modulate = Color(2.0, 1.45, 1.45)
			anim.speed_scale = 0.0
	if is_frozen():
		anim.modulate = Color(0.65, 0.91, 1.1)
		anim.speed_scale = 0.0


func _draw() -> void:
	if state == EnemyState.DEAD:
		return
	if health < _maximum_health:
		var ratio: float = float(health) / maxf(_maximum_health, 1.0)
		draw_rect(Rect2(-6.0, -31.0, 26.0, 4.0), Color(0.16, 0.12, 0.24, 0.9))
		draw_rect(Rect2(-5.0, -30.0, 24.0 * ratio, 2.0), Color(1.0, 0.55, 0.45))
	if is_frozen():
		var ice := PackedVector2Array([Vector2(-11, -19), Vector2(-5, -27), Vector2(20, -27), Vector2(26, -18), Vector2(26, 5), Vector2(-11, 5), Vector2(-11, -19)])
		draw_colored_polygon(ice, Color(0.55, 0.87, 1.0, 0.23))
		draw_polyline(ice, Color(0.73, 0.96, 1.0, 0.92), 1.0)
		draw_line(Vector2(-5, -23), Vector2(5, -12), Color(0.91, 1.0, 1.0, 0.65), 1.0)
		draw_line(Vector2(18, -18), Vector2(23, -4), Color(0.91, 1.0, 1.0, 0.65), 1.0)
	elif state == EnemyState.ALERT:
		var bob: float = sin(_state_time * TAU * 5.0)
		var warning_color := Color(1.0, 0.9, 0.38)
		draw_line(Vector2(7.0, -42.0 + bob), Vector2(7.0, -36.0 + bob), warning_color, 2.0)
		draw_circle(Vector2(7.0, -32.5 + bob), 1.2, warning_color)

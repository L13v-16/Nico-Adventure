extends CharacterBody2D

signal respawned
signal gem_collected(total: int)
signal health_changed(current: int, maximum: int)
signal died
signal cherry_balance_changed(balance: int)
signal shop_shield_changed(hits: int)

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const ACCELERATION = 1500.0
const FRICTION = 2000.0
const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.12
const MAX_FALL_SPEED = 700.0
const FALL_LIMIT = 400.0
const MAX_HEALTH = 3
const ATTACK_WINDUP = 0.04
const ATTACK_ACTIVE_TIME = 0.22
const ATTACK_DURATION = 0.30
const ATTACK_COOLDOWN = 0.35
const ATTACK_REACH = 52.0
const ATTACK_BUFFER_TIME := 0.12
## Modificado temporariamente pelo açaí; o golpe normal continua valendo 1.
var attack_damage: int = 1
const HITSTUN_TIME = 0.18
const INVULNERABILITY_TIME = 0.9
const RESPAWN_INVULNERABILITY = 1.0
const DEATH_DELAY = 0.35

@export_group("Movimento")
@export var coyote_time: float = COYOTE_TIME
@export var jump_buffer_time: float = JUMP_BUFFER_TIME
@export var move_acceleration: float = ACCELERATION
@export var braking: float = FRICTION
@export var ground_snap: float = 6.0

# Sensação de movimento (juice)
const LAND_DUST_SPEED = 240.0
const RUN_DUST_SPEED = 150.0
const RUN_DUST_INTERVAL = 0.14
const SQUASH_JUMP = -0.26
const SQUASH_RECOVER = 16.0
const SHAKE_LIMIT = 7.0

enum State { IDLE, RUN, JUMP, FALL, HURT, DIE }

var current_state: State = State.IDLE
var respawn_position: Vector2
var gems: int = 0
## Coletas e gastos desta tentativa ficam separados da carteira persistente.
var cherries_spent: int = 0
var shop_shield_hits: int = 0
var health: int = MAX_HEALTH
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _jump_was_held: bool = false
var _finished: bool = false
var _facing: float = 1.0
var _attack_facing: float = 1.0
var _attack_elapsed: float = -1.0
var _attack_cooldown: float = 0.0
var _attack_buffer_timer := 0.0
var _attack_hit_targets: Dictionary = {}
var _attack_shape: RectangleShape2D = RectangleShape2D.new()
var _attack_query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
var _hitstun_timer: float = 0.0
var _invulnerability_timer: float = 0.0
var _death_timer: float = 0.0
var _hit_flash_timer: float = 0.0
var _sprite_base_position: Vector2
var _sprite_base_scale: Vector2
var _sprite_base_modulate: Color
var _squash: float = 0.0
var _was_on_floor: bool = false
var _run_dust_timer: float = 0.0
var _shake: float = 0.0
var _camera_look: float = 0.0
var _camera: Camera2D
var _camera_base_offset: Vector2
var equipment: Node
var _freeze_hud: CanvasLayer
var _freeze_canvas: Control
var _freeze_status: Label
var _active_acai: Node
const ACAI_ICON := preload("res://world/Arte/Beach/acai.png")
var _vine: Node2D
var _vine_cooldown := 0.0
var _spring_lock := 0.0
var elements:Node
var _last_valid_position := Vector2.ZERO
var _last_valid_camera_base := Vector2.ZERO

@onready var anim: AnimatedSprite2D = $anim


func _ready() -> void:
	add_to_group("player")
	equipment = preload("res://world/Scripts/equipment_model.gd").new()
	equipment.name = "Equipment"
	add_child(equipment)
	_make_freeze_hud()
	elements=preload("res://world/Scripts/elemental_power.gd").new()
	elements.name="Elements"
	add_child(elements)
	respawn_position = global_position
	_last_valid_position = global_position
	# Keeps the feet attached while riding descending or horizontal platforms.
	floor_snap_length = ground_snap
	platform_on_leave = CharacterBody2D.PLATFORM_ON_LEAVE_ADD_UPWARD_VELOCITY
	_sprite_base_position = anim.position
	_sprite_base_scale = anim.scale
	_sprite_base_modulate = anim.modulate
	_facing = -1.0 if anim.flip_h else 1.0
	_attack_shape.size = Vector2(36.0, 24.0)
	_attack_query.shape = _attack_shape
	_attack_query.collision_mask = 4
	_attack_query.collide_with_bodies = true
	_attack_query.collide_with_areas = false
	_attack_query.exclude = [get_rid()]
	_camera = get_node_or_null("Camera2D") as Camera2D
	if _camera != null:
		_camera_base_offset = _camera.offset
	else:
		_camera_base_offset = Vector2.ZERO
	health_changed.emit(health, MAX_HEALTH)


func _process(_delta: float) -> void:
	# Cannon flight temporarily owns movement, while powers keep counting down.
	if not is_physics_processing():_update_freeze_hud()


func _physics_process(delta: float) -> void:
	if _finished:
		return
	_stabilize_motion()
	if delta <= 0.0:
		return
	_tick_combat(delta)
	_vine_cooldown = maxf(0.0, _vine_cooldown - delta)
	_spring_lock = maxf(0.0, _spring_lock - delta)
	if health <= 0:
		_death_timer -= delta
		velocity.y = minf(velocity.y + get_gravity().y * delta, MAX_FALL_SPEED)
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta * 0.4)
		move_and_slide()
		_stabilize_motion()
		if _death_timer <= 0.0:
			_register_death()
		_update_combat_visuals()
		_update_camera(delta)
		return
	if is_instance_valid(_vine):
		_swing_on_vine(delta)
		return

	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)
		velocity.y = minf(velocity.y + get_gravity().y * delta, MAX_FALL_SPEED)

	_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)
	var jump_held := Input.is_action_pressed("ui_accept") or Input.is_physical_key_pressed(KEY_W)
	var can_control: bool = _hitstun_timer <= 0.0
	if can_control and jump_held and not _jump_was_held:
		_jump_buffer_timer = jump_buffer_time

	var jumped := false
	if can_control and _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY * equipment.get_jump_multiplier()
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		_squash = SQUASH_JUMP
		jumped = true
		Sfx.jump()

	# A short tap produces a short jump, including a buffered tap before landing.
	if can_control and _spring_lock <= 0.0 and velocity.y < 0.0 and not jump_held and (_jump_was_held or jumped):
		velocity.y *= 0.5
	_jump_was_held = jump_held

	var direction := clampf(
		Input.get_axis("ui_left", "ui_right")
		+ float(Input.is_physical_key_pressed(KEY_D))
		- float(Input.is_physical_key_pressed(KEY_A)),
		-1.0, 1.0
	)
	if can_control:
		if direction != 0.0:
			velocity.x = move_toward(velocity.x, direction * SPEED * equipment.get_speed_multiplier(), move_acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, braking * delta)
		if _attack_elapsed < 0.0 and direction != 0.0:
			_facing = signf(direction)
		if InputMap.has_action("attack") and Input.is_action_just_pressed("attack"):
			_attack_buffer_timer = ATTACK_BUFFER_TIME
		if _attack_buffer_timer > 0 and _attack_cooldown <= 0.0 and _attack_elapsed < 0.0:
			_start_attack()

	var fall_speed: float = velocity.y
	move_and_slide()
	_stabilize_motion()
	_apply_ground_feedback(fall_speed, delta)
	if global_position.y > FALL_LIMIT:
		_register_death()
		return
	if is_attacking():
		_strike_enemies()

	update_state(direction)
	play_state_animation()
	_update_combat_visuals()
	_update_camera(delta)


## Poeira, "squash" de aterrissagem e rastro ao correr.
func _apply_ground_feedback(fall_speed: float, delta: float) -> void:
	if is_on_floor():
		if not _was_on_floor:
			var weight: float = clampf(fall_speed / MAX_FALL_SPEED, 0.0, 1.0)
			_squash = maxf(_squash, weight * 0.45 + 0.14)
			Sfx.land(weight)
			if fall_speed > LAND_DUST_SPEED:
				Fx.land(global_position + Vector2(0.0, 5.0), weight)
				_add_shake(weight * 1.8)
		_run_dust_timer -= delta
		if absf(velocity.x) > RUN_DUST_SPEED and _run_dust_timer <= 0.0:
			_run_dust_timer = RUN_DUST_INTERVAL
			var drift: float = -signf(velocity.x)
			Fx.dust(global_position + Vector2(drift * 3.0, 5.0), 2, drift)
	else:
		_run_dust_timer = 0.0
	_was_on_floor = is_on_floor()
	# Volta ao normal com amortecimento exponencial (independente do FPS).
	_squash = lerpf(_squash, 0.0, 1.0 - exp(-SQUASH_RECOVER * delta))


func _add_shake(amount: float) -> void:
	_shake = minf(_shake + amount, SHAKE_LIMIT)


## Uma posição inválida nunca deve alcançar a câmera nem apagar o cenário.
## Recupera a última posição válida sem consumir vida ou alterar a carteira.
func _stabilize_motion() -> void:
	if global_position.is_finite():
		_last_valid_position = global_position
	else:
		global_position = _last_valid_position
		reset_physics_interpolation()
	if not velocity.is_finite():
		velocity = Vector2.ZERO
	if _camera_base_offset.is_finite():
		_last_valid_camera_base = _camera_base_offset
	else:
		_camera_base_offset = _last_valid_camera_base


## Antecipação da câmera: olha na direção do movimento e acompanha impactos.
func _update_camera(delta: float) -> void:
	if _camera == null:
		return
	_stabilize_motion()
	if not Save.is_camera_shake_enabled(): _shake = 0.0
	_shake = move_toward(_shake, 0.0, delta * 26.0)
	var target_look: float = _facing * 34.0
	_camera_look = lerpf(_camera_look, target_look, 1.0 - exp(-4.0 * delta))
	var vertical: float = clampf(velocity.y / MAX_FALL_SPEED, -1.0, 1.0) * 20.0
	var shake_offset := Vector2.ZERO
	if _shake > 0.01:
		var time: float = float(Time.get_ticks_msec()) * 0.06
		shake_offset = Vector2(sin(time * 1.7), cos(time * 2.3)) * _shake
	_camera.offset = _camera_base_offset + Vector2(_camera_look, vertical) + shake_offset


func is_dead() -> bool:
	return _finished or health <= 0


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R and not _finished:
			respawn()
			get_viewport().set_input_as_handled()


func set_checkpoint(point: Vector2) -> void:
	respawn_position = point


## Conta a morte (vida zerada ou queda no vazio) e volta ao ponto de retorno.
## O atalho R chama respawn() direto, sem contar morte.
func _register_death() -> void:
	died.emit()
	respawn()


func respawn() -> void:
	if _finished:
		return
	release_vine(false)
	_spring_lock = 0.0
	shop_shield_hits = 0
	shop_shield_changed.emit(0)
	Fx.burst(global_position + Vector2(0.0, -4.0), Color(0.72, 0.9, 1.0), 10, 120.0)
	Sfx.respawn()
	global_position = respawn_position
	velocity = Vector2.ZERO
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_jump_was_held = Input.is_action_pressed("ui_accept") or Input.is_physical_key_pressed(KEY_W)
	_cancel_attack()
	_attack_cooldown = 0.0
	_hitstun_timer = 0.0
	_invulnerability_timer = RESPAWN_INVULNERABILITY
	_death_timer = 0.0
	_hit_flash_timer = 0.0
	_squash = 0.0
	_shake = 0.0
	_was_on_floor = false
	_run_dust_timer = 0.0
	health = MAX_HEALTH
	current_state = State.IDLE
	play_state_animation()
	_update_combat_visuals()
	_update_camera(0.0)
	health_changed.emit(health, MAX_HEALTH)
	respawned.emit()


func collect_item(cherry_id: String = "", level_id: String = "") -> bool:
	if _finished:
		return false
	var saved:bool=Save.add_cherries(1) if cherry_id.is_empty() or level_id.is_empty() else Save.collect_level_cherry(level_id,cherry_id)
	if not saved:
		return false
	gems += 1
	gem_collected.emit(gems)
	cherry_balance_changed.emit(get_cherry_balance())
	return true


func get_cherry_balance() -> int:
	return Save.get_cherry_balance()


func try_spend_cherries(amount: int) -> bool:
	if amount <= 0 or is_dead():
		return false
	if not Save.try_spend_cherries(amount):
		return false
	cherries_spent += amount
	cherry_balance_changed.emit(get_cherry_balance())
	return true


func heal_one() -> bool:
	if is_dead() or health >= MAX_HEALTH:
		return false
	health += 1
	health_changed.emit(health, MAX_HEALTH)
	return true


func grant_shop_shield(hits: int = 3) -> bool:
	if is_dead() or hits <= 0 or shop_shield_hits > 0:
		return false
	shop_shield_hits = mini(hits, 3)
	shop_shield_changed.emit(shop_shield_hits)
	queue_redraw()
	return true


func finish_level() -> void:
	release_vine(false)
	_finished = true
	equipment.clear_temporary()
	shop_shield_hits = 0
	shop_shield_changed.emit(0)
	Fx.cancel_hitstop()
	_cancel_attack()
	_hitstun_timer = 0.0
	_invulnerability_timer = 0.0
	_hit_flash_timer = 0.0
	if is_instance_valid(_freeze_hud):
		_freeze_hud.hide()
	if is_instance_valid(elements):elements._hud.hide()
	velocity = Vector2.ZERO
	current_state = State.IDLE
	play_state_animation()
	_update_combat_visuals()
	set_physics_process(false)
	set_process_unhandled_key_input(false)


func update_state(direction: float) -> void:
	anim.flip_h = (_attack_facing if _attack_elapsed >= 0.0 else _facing) < 0.0
	if health <= 0:
		current_state = State.DIE
		return
	if _hitstun_timer > 0.0:
		current_state = State.HURT
		return

	if not is_on_floor():
		current_state = State.JUMP if velocity.y < 0.0 else State.FALL
	else:
		current_state = State.RUN if direction != 0.0 else State.IDLE


func play_state_animation() -> void:
	if not anim:
		return

	match current_state:
		State.IDLE:
			anim.play("idle")
		State.RUN:
			anim.play("run")
		State.JUMP:
			anim.play("jump")
		State.FALL:
			anim.play("fall")
		State.HURT:
			anim.play("hurt")
		State.DIE:
			anim.play("die")


func heal_full() -> void:
	if _finished or health <= 0:
		return
	health = MAX_HEALTH
	health_changed.emit(health, MAX_HEALTH)


func take_damage(amount: int, source_position: Vector2) -> void:
	if _finished or health <= 0 or amount <= 0 or _invulnerability_timer > 0.0:
		return
	# A folha só é consumida depois dos testes de dano e imunidade. O mar
	# chama _register_death() diretamente e nunca é bloqueado por equipamento.
	if is_instance_valid(equipment) and equipment.consume_leaf():
		_invulnerability_timer = 0.65
		Fx.burst(global_position + Vector2(0, -5), Color("b9f4a5"), 10, 125.0)
		Sfx.hit()
		queue_redraw()
		return
	if shop_shield_hits > 0:
		shop_shield_hits -= 1
		shop_shield_changed.emit(shop_shield_hits)
		_invulnerability_timer = 0.65
		Fx.burst(global_position + Vector2(0, -5), Color("a7e7ff"), 8, 125.0)
		Sfx.hit()
		queue_redraw()
		return
	health = maxi(health - amount, 0)
	release_vine(false)
	_invulnerability_timer = INVULNERABILITY_TIME
	_hitstun_timer = HITSTUN_TIME
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	_cancel_attack()
	var away: float = signf(global_position.x - source_position.x)
	if is_zero_approx(away):
		away = -_facing
	velocity = Vector2(away * 220.0, -160.0)
	Fx.burst(global_position + Vector2(0.0, -6.0), Color(1.0, 0.55, 0.5), 8, 155.0)
	_add_shake(4.0)
	if health <= 0:
		_death_timer = DEATH_DELAY
		current_state = State.DIE
		Fx.burst(global_position + Vector2(0.0, -8.0), Color(1.0, 0.35, 0.45), 16, 210.0)
		_add_shake(6.0)
		Sfx.death()
	else:
		current_state = State.HURT
		Sfx.hurt()
	play_state_animation()
	_update_combat_visuals()
	health_changed.emit(health, MAX_HEALTH)


func is_attacking() -> bool:
	return (
		not _finished and health > 0
		and _attack_elapsed >= ATTACK_WINDUP
		and _attack_elapsed < ATTACK_WINDUP + ATTACK_ACTIVE_TIME
	)


func _start_attack() -> void:
	_attack_buffer_timer = 0.0
	_attack_elapsed = 0.0
	_attack_cooldown = ATTACK_COOLDOWN * equipment.get_attack_cooldown_multiplier()
	_attack_facing = _facing
	_attack_hit_targets.clear()
	Sfx.swing()


func _cancel_attack() -> void:
	_attack_elapsed = -1.0
	_attack_buffer_timer = 0.0
	_attack_hit_targets.clear()
	queue_redraw()


func _tick_combat(delta: float) -> void:
	_update_freeze_hud()
	_attack_buffer_timer = maxf(_attack_buffer_timer-delta,0)
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	_hitstun_timer = maxf(_hitstun_timer - delta, 0.0)
	_invulnerability_timer = maxf(_invulnerability_timer - delta, 0.0)
	_hit_flash_timer = maxf(_hit_flash_timer - delta, 0.0)
	if _attack_elapsed >= 0.0:
		_attack_elapsed += delta
		if _attack_elapsed >= ATTACK_DURATION:
			# Keep a recent press across the end of the current swing.
			_attack_elapsed = -1.0
			_attack_hit_targets.clear()
			queue_redraw()


func _strike_enemies() -> void:
	var query_transform: Transform2D = global_transform
	query_transform.origin = to_global(Vector2(_attack_facing * 26.0, -2.0))
	_attack_query.transform = query_transform
	var hits: Array[Dictionary] = get_world_2d().direct_space_state.intersect_shape(_attack_query, 16)
	var struck := false
	for hit: Dictionary in hits:
		var target: Node2D = hit.get("collider") as Node2D
		if not is_instance_valid(target) or not target.is_in_group("enemies"):
			continue
		if not target.has_method("take_damage"):
			continue
		var target_id: int = target.get_instance_id()
		if _attack_hit_targets.has(target_id):
			continue
		var front_distance: float = (target.global_position.x - global_position.x) * _attack_facing
		if front_distance <= 0.0 or front_distance > ATTACK_REACH:
			continue
		if target.has_method("is_dead") and bool(target.call("is_dead")):
			continue
		_attack_hit_targets[target_id] = true
		target.call("take_damage", get_attack_damage(), global_position)
		# O gelo pertence ao açaí: o comum e o gelado habilitam o efeito
		# nos golpes. As garras alteram só o dano; gelo duradouro só a duração.
		var frost_active: bool = attack_damage > 1 or equipment.get_frost_boost_left() > 0.0
		if frost_active and target.has_method("freeze_for") and not bool(target.call("is_dead")):
			target.call("freeze_for", equipment.get_freeze_duration())
		_hit_flash_timer = 0.10
		struck = true
		Fx.impact(global_position + Vector2(_attack_facing * 26.0, -4.0), _attack_facing)
		Fx.hitstop()
		_add_shake(2.4)
	if struck:
		Sfx.hit()


func _update_combat_visuals() -> void:
	anim.position = _sprite_base_position + Vector2(0.0, _squash * 6.0)
	anim.scale = _sprite_base_scale * Vector2(1.0 + _squash * 0.55, 1.0 - _squash)
	anim.modulate = _sprite_base_modulate
	if _attack_elapsed >= 0.0:
		var pulse: float = sin(clampf(_attack_elapsed / ATTACK_DURATION, 0.0, 1.0) * PI)
		anim.position += Vector2(_attack_facing * 3.0 * pulse, -pulse)
		anim.scale *= Vector2(1.0 + 0.12 * pulse, 1.0 - 0.08 * pulse)
	if _invulnerability_timer > 0.0:
		var blink_alpha: float = 0.35 if fmod(_invulnerability_timer * 18.0, 2.0) < 1.0 else 1.0
		anim.modulate.a = _sprite_base_modulate.a * blink_alpha
		if _hitstun_timer > 0.0:
			anim.modulate.r = 1.0
			anim.modulate.g = 0.5
			anim.modulate.b = 0.5
	queue_redraw()


func _draw() -> void:
	if shop_shield_hits > 0:
		draw_arc(Vector2(0, -5), 20.0, 0, TAU, 28, Color(0.48, 0.84, 1.0, 0.48), 1.5)
		for i in shop_shield_hits:
			draw_rect(Rect2(-6.0 + i * 5.0, -29.0, 3, 2), Color("c2f3ff"))
	if _attack_elapsed >= 0.0 and _attack_elapsed < ATTACK_WINDUP:
		draw_circle(Vector2(_attack_facing * 12.0, -3.0), 3.0, Color(0.65, 0.95, 1.0, 0.65))
	if is_attacking():
		var progress: float = clampf((_attack_elapsed - ATTACK_WINDUP) / ATTACK_ACTIVE_TIME, 0.0, 1.0)
		var sweep_end: float = lerpf(-1.2, 1.2, progress)
		var sweep_start: float = maxf(-1.35, sweep_end - 1.1)
		var trail: PackedVector2Array = PackedVector2Array()
		for index: int in range(13):
			var angle: float = lerpf(sweep_start, sweep_end, float(index) / 12.0)
			trail.append(Vector2(cos(angle) * _attack_facing * 31.0, sin(angle) * 24.0 - 3.0))
		draw_polyline(trail, Color(0.3, 0.85, 1.0, 0.6), 5.0, true)
		draw_polyline(trail, Color(1.0, 1.0, 0.85, 0.95), 2.0, true)
	if _hit_flash_timer > 0.0:
		var spark: Vector2 = Vector2(_attack_facing * 30.0, -4.0)
		var spark_size: float = 7.0 * (_hit_flash_timer / 0.10)
		draw_line(spark - Vector2(spark_size, 0.0), spark + Vector2(spark_size, 0.0), Color(1.0, 0.95, 0.45), 2.0)
		draw_line(spark - Vector2(0.0, spark_size), spark + Vector2(0.0, spark_size), Color(1.0, 1.0, 0.85), 2.0)


func get_equipment() -> Node:
	return equipment


func launch_from_spring(speed: float) -> void:
	release_vine(false)
	velocity.y = -absf(speed)
	_spring_lock = 0.38
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_squash = SQUASH_JUMP
	current_state = State.JUMP
	play_state_animation()


func can_grab_vine() -> bool:
	return not is_dead() and _hitstun_timer <= 0 and _vine_cooldown <= 0 and not is_instance_valid(_vine)


func grab_vine(vine: Node2D) -> bool:
	if not can_grab_vine(): return false
	_vine = vine
	_vine_cooldown = 0.18
	_cancel_attack()
	_coyote_timer = 0.0
	_jump_buffer_timer = 0.0
	_jump_was_held = Input.is_action_pressed("ui_accept") or Input.is_physical_key_pressed(KEY_W)
	return true


func release_vine(jump_off: bool = true) -> void:
	if not is_instance_valid(_vine):
		_vine = null
		return
	velocity = _vine.release_velocity()
	_vine.detach()
	_vine = null
	_vine_cooldown = 0.4
	anim.rotation = 0.0
	if jump_off:
		var direction := Input.get_axis("ui_left", "ui_right") + float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A))
		if absf(direction)>0: velocity.x = signf(direction)*maxf(absf(velocity.x),300.0)
		velocity.x = clampf(velocity.x,-420.0,420.0)
		velocity.y = clampf(velocity.y-65.0,-270.0,-160.0)
		_spring_lock = 0.2
		Sfx.jump()


func _swing_on_vine(delta: float) -> void:
	var direction := clampf(Input.get_axis("ui_left", "ui_right")+float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),-1,1)
	var jump_held := Input.is_action_pressed("ui_accept") or Input.is_physical_key_pressed(KEY_W)
	if (jump_held and not _jump_was_held) or (_vine_cooldown <= 0 and Input.is_action_just_pressed("interagir")):
		_jump_was_held = jump_held
		release_vine(true)
		return
	_jump_was_held = jump_held
	_vine.swing(delta,direction)
	_vine.queue_redraw()
	var target: Vector2 = _vine.get_grip()+Vector2(0,12)
	var contact := move_and_collide(target-global_position)
	if contact != null:
		release_vine(false)
		return
	velocity = _vine.release_velocity()
	if absf(direction)>0: _facing = signf(direction)
	anim.flip_h = _facing < 0
	anim.play("jump")
	_update_combat_visuals()
	anim.rotation = -float(_vine.angle)*0.18
	_update_camera(delta)


## Preserva os 20% das garras como fração, inclusive durante o açaí comum.
func get_attack_damage() -> float:
	return float(attack_damage) * equipment.get_damage_multiplier()


func set_acai_power(power: Node) -> void:
	_active_acai=power
	if is_instance_valid(elements):elements.refresh_available("ice" if is_instance_valid(power) else "")
	_update_freeze_hud()


func _make_freeze_hud() -> void:
	_freeze_hud = CanvasLayer.new()
	_freeze_hud.name = "FrostAcaiHud"
	_freeze_hud.layer = 24
	add_child(_freeze_hud)
	_freeze_canvas = Control.new()
	_freeze_canvas.position = Vector2(12,58)
	_freeze_canvas.size = Vector2(188,38)
	_freeze_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_freeze_canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_freeze_canvas.draw.connect(_draw_freeze_hud)
	_freeze_hud.add_child(_freeze_canvas)
	_freeze_status = Label.new()
	_freeze_status.position = Vector2(28,2)
	_freeze_status.size = Vector2(156,25)
	_freeze_status.add_theme_font_size_override("font_size",9)
	_freeze_status.add_theme_color_override("font_color",Color("d9faff"))
	_freeze_status.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_freeze_canvas.add_child(_freeze_status)
	_update_freeze_hud()


func _update_freeze_hud() -> void:
	if not is_instance_valid(_freeze_status) or not is_instance_valid(equipment):return
	var regular:float=_active_acai.get_time_left() if is_instance_valid(_active_acai) else 0.0
	var boost:float=equipment.get_frost_boost_left()
	_freeze_canvas.visible=not _finished and (regular>0 or boost>0)
	var boss:=get_parent().get_node_or_null("Boss")
	_freeze_canvas.position.y=90 if is_instance_valid(boss) and boss.get("active")==true else 58
	var title:="AÇAÍ 2× · %ds"%int(ceilf(regular)) if regular>0 else "AÇAÍ GELADO · %ds"%int(ceilf(boost))
	var detail:="Golpes: gelo %ds"%int(equipment.get_freeze_duration())
	if regular>0 and boost>0:detail+=" · Gelado %ds"%int(ceilf(boost))
	_freeze_status.text=title+"\n"+detail
	_freeze_canvas.queue_redraw()


func _draw_freeze_hud() -> void:
	_freeze_canvas.draw_rect(Rect2(0,0,188,38),Color("101f30"))
	_freeze_canvas.draw_rect(Rect2(0,0,188,38),Color("648d9e"),false,1)
	_freeze_canvas.draw_texture_rect(ACAI_ICON,Rect2(4,5,20,20),false)
	var regular:float=_active_acai.get_time_left() if is_instance_valid(_active_acai) else 0.0
	var boost:float=equipment.get_frost_boost_left()
	var total:float=_active_acai.duration if regular>0 else 30.0
	var left:float=regular if regular>0 else boost
	_freeze_canvas.draw_rect(Rect2(28,29,152,3),Color("304457"))
	_freeze_canvas.draw_rect(Rect2(28,29,152*clampf(left/maxf(total,0.1),0,1),3),Color("bd8fea") if regular>0 else Color("88dbed"))
	if regular>0 and boost>0:
		_freeze_canvas.draw_rect(Rect2(28,34,152*clampf(boost/30.0,0,1),1),Color("88dbed"))

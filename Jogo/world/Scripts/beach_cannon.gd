extends Node2D
## A boca captura somente um salto descendente. Andar por ela não dispara.

signal launched
signal landed
signal impact(hit: bool)

@export var boss_path: NodePath
@export var cooldown := 2.4
@export var mouth_height := 40.0
@export var mouth_half_width := 16.0
## Ponto fixo da mira: o urubu precisa passar por ele no instante do impacto.
@export var aim_offset := Vector2(120.0, -112.0)
@export var idle_texture: Texture2D
@export var fire_frames: Array[Texture2D] = []

const OUTBOUND_TIME := 0.72
const RETURN_TIME := 0.72
const JUMP_TO_IMPACT := 1.42

enum Flight { NONE, OUTBOUND, RETURN }
var _flight: Flight = Flight.NONE
var _flight_time := 0.0
var _shot_id := 0
var _shot_spent := false
var _cooldown_left := 0.0
var _time := 0.0
var _recoil := 0.0
var _fire_left := 0.0
var _previous_feet := INF
var _start := Vector2.ZERO
var _target := Vector2.ZERO
var _safe_landing := Vector2.ZERO
var _saved_physics := true
var _saved_key_input := true
var _saved_rotation := 0.0
var _boss: Node2D
var _player: CharacterBody2D


func _ready() -> void:
	add_to_group("beach_cannons")
	z_index = 5
	_find_references()


func _find_references() -> void:
	if not is_instance_valid(_boss):
		if not boss_path.is_empty():
			_boss = get_node_or_null(boss_path) as Node2D
		if not is_instance_valid(_boss):
			_boss = get_tree().get_first_node_in_group("beach_boss") as Node2D
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
		if is_instance_valid(_player):
			_player.respawned.connect(_on_player_reset)
			_player.died.connect(_on_player_reset)


func _physics_process(delta: float) -> void:
	_time += delta
	_recoil = maxf(_recoil - delta, 0.0)
	_fire_left = maxf(_fire_left - delta, 0.0)
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_find_references()
	if not is_instance_valid(_player):
		return
	if _flight != Flight.NONE:
		if _player.health <= 0 or bool(_player.get("_finished")):
			_abort_flight()
		else:
			_tick_flight(delta)
		queue_redraw()
		return
	var feet := _player.global_position.y + 11.0
	var mouth_y := global_position.y - mouth_height
	var was_above: bool = is_finite(_previous_feet) and _previous_feet <= mouth_y + 5.0
	var entering: bool = feet >= mouth_y - 4.0 and feet <= mouth_y + 9.0
	var descending: bool = not _player.is_on_floor() and _player.velocity.y > 20.0
	if _can_launch() and descending and was_above and entering and absf(_player.global_position.x - global_position.x) <= mouth_half_width:
		_start_launch()
	_previous_feet = feet
	queue_redraw()


func _can_launch() -> bool:
	return (
		is_instance_valid(_boss) and not _boss.is_dead() and _boss.active
		and _cooldown_left <= 0.0 and _player.health > 0
		and not _player.is_dead() and not _player.get_meta("cannon_flight", false)
	)


func _start_launch() -> void:
	_shot_id += 1
	_shot_spent = false
	_saved_physics = _player.is_physics_processing()
	_saved_key_input = _player.is_processing_unhandled_key_input()
	_saved_rotation = _player.anim.rotation
	_player.set_meta("cannon_flight", true)
	_player.set_physics_process(false)
	_player.set_process_unhandled_key_input(false)
	_player.call("_cancel_attack")
	_player.velocity = Vector2.ZERO
	_player.set("_invulnerability_timer", 0.3)
	_start = global_position + Vector2(0, -mouth_height - 9.0)
	_target = global_position + aim_offset
	var away := 1.0 if global_position.x < _boss.global_position.x else -1.0
	_safe_landing = Vector2(global_position.x + away * 56.0, global_position.y - 11.5)
	_player.global_position = _start
	_player.anim.play("jump")
	_flight = Flight.OUTBOUND
	_flight_time = 0.0
	_recoil = 0.22
	_fire_left = 0.24
	_boss.notify_launch()
	Fx.burst(global_position + Vector2(0, -mouth_height), Color(1.0, 0.79, 0.43), 12, 150.0)
	Sfx.land(1.0)
	Sfx.jump()
	launched.emit()


func _tick_flight(delta: float) -> void:
	_flight_time += delta
	_player.set("_invulnerability_timer", 0.3)
	_player.velocity = Vector2.ZERO
	if _flight == Flight.OUTBOUND:
		var progress := clampf(_flight_time / OUTBOUND_TIME, 0.0, 1.0)
		_player.global_position = _start.lerp(_target, progress) + Vector2(0.0, -sin(progress * PI) * 54.0)
		_player.anim.rotation = _saved_rotation + sin(progress * PI) * (0.28 if _target.x > _start.x else -0.28)
		if progress >= 1.0:
			var did_hit := false
			if not _shot_spent and is_instance_valid(_boss):
				did_hit = _boss.receive_cannon_hit(self, _shot_id)
			impact.emit(did_hit)
			_shot_spent = true
			_start = _player.global_position
			_flight = Flight.RETURN
			_flight_time = 0.0
	else:
		var progress := clampf(_flight_time / RETURN_TIME, 0.0, 1.0)
		_player.global_position = _start.lerp(_safe_landing, progress) + Vector2(0.0, -sin(progress * PI) * 48.0)
		_player.anim.rotation = _saved_rotation
		if progress >= 1.0:
			_player.global_position = _safe_landing
			_release_player()
			Fx.land(_safe_landing + Vector2(0, 11), 0.5)
			Sfx.land(0.5)
			landed.emit()
	if is_instance_valid(_player):
		_player.call("_update_camera", delta)


func is_shot_hitting(boss: Node, shot_id: int) -> bool:
	return _flight == Flight.OUTBOUND and _flight_time >= OUTBOUND_TIME and not _shot_spent and _boss == boss and shot_id == _shot_id


func get_impact_point() -> Vector2:
	return _target


func is_good_window() -> bool:
	return is_instance_valid(_boss) and _boss.active and not _boss.is_dead() and _boss.predicts_hit(global_position + aim_offset, JUMP_TO_IMPACT)


func _release_player() -> void:
	_flight = Flight.NONE
	_cooldown_left = cooldown
	_previous_feet = INF
	if not is_instance_valid(_player):
		return
	_player.remove_meta("cannon_flight")
	_player.velocity = Vector2.ZERO
	_player.anim.rotation = _saved_rotation
	_player.set("_coyote_timer", 0.0)
	_player.set("_jump_buffer_timer", 0.0)
	_player.set("_jump_was_held", Input.is_action_pressed("jump"))
	_player.set("_invulnerability_timer", maxf(float(_player.get("_invulnerability_timer")), 0.7))
	if not bool(_player.get("_finished")):
		_player.set_physics_process(_saved_physics)
		_player.set_process_unhandled_key_input(_saved_key_input)
		_player.call("update_state", 0.0)
		_player.call("play_state_animation")
		_player.call("_update_combat_visuals")


func _abort_flight() -> void:
	if _flight != Flight.NONE:
		_release_player()


func _on_player_reset() -> void:
	_abort_flight()
	_previous_feet = INF


func _exit_tree() -> void:
	_abort_flight()


func _draw() -> void:
	var usable: bool = is_instance_valid(_boss) and not _boss.is_dead() and _boss.active and _cooldown_left <= 0.0
	var light := Color(0.98, 0.79, 0.40)
	var good_window := is_good_window()
	var aim_color := Color(0.57, 1.0, 0.67) if good_window else Color(1.0, 0.77, 0.35)
	if is_instance_valid(_boss) and _boss.active and not _boss.is_dead():
		var guide_color := aim_color
		guide_color.a = 0.68 if _cooldown_left <= 0.0 else 0.28
		var mouth := Vector2(0, -mouth_height - 9.0)
		for index in range(1, 8):
			var progress := float(index) / 8.0
			var point := mouth.lerp(aim_offset, progress) + Vector2(0.0, -sin(progress * PI) * 54.0)
			draw_rect(Rect2(point.round() - Vector2(1, 1), Vector2(2, 2)), guide_color)
		for corner_x in [-1.0, 1.0]:
			for corner_y in [-1.0, 1.0]:
				var corner := aim_offset + Vector2(corner_x * 9, corner_y * 9)
				draw_line(corner, corner - Vector2(corner_x * 4, 0), guide_color, 1.0)
				draw_line(corner, corner - Vector2(0, corner_y * 4), guide_color, 1.0)
	var frame: Texture2D = idle_texture
	if _fire_left > 0.0 and not fire_frames.is_empty():
		frame = fire_frames[mini(int((0.24 - _fire_left) / 0.24 * fire_frames.size()), fire_frames.size() - 1)]
	if frame != null:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1) if aim_offset.x < 0 else Vector2.ONE)
		draw_texture_rect(frame, Rect2(-24, -64, 48, 64), false)
		draw_set_transform(Vector2.ZERO)
	else:
		_draw_body_fallback()
	if usable:
		var arrow_y := -mouth_height - 14.0 + roundf(sin(_time * 4.0) * 2.0)
		draw_line(Vector2(-5, arrow_y - 4), Vector2(0, arrow_y + 1), aim_color, 2.0)
		draw_line(Vector2(5, arrow_y - 4), Vector2(0, arrow_y + 1), aim_color, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(-31, -mouth_height - 26), "PULE AGORA" if good_window else "AGUARDE", HORIZONTAL_ALIGNMENT_CENTER, 62, 8, aim_color)
	elif _cooldown_left > 0.0 and is_instance_valid(_boss) and not _boss.is_dead():
		draw_rect(Rect2(-12, -mouth_height - 7, 24.0 * (1.0 - _cooldown_left / cooldown), 2), light)


func _draw_body_fallback() -> void:
	var brass := Color(0.68, 0.49, 0.23)
	var light := Color(0.98, 0.79, 0.40)
	var barrel := Color(0.17, 0.25, 0.30)
	var recoil_y := _recoil * 18.0
	var toward := signf(aim_offset.x)
	draw_rect(Rect2(-25, -9, 50, 8), Color(0.20, 0.19, 0.19))
	draw_rect(Rect2(-22, -13, 10, 12), brass)
	draw_rect(Rect2(12, -13, 10, 12), brass)
	draw_rect(Rect2(-19, -11, 4, 6), light)
	draw_rect(Rect2(15, -11, 4, 6), light)
	var barrel_points := PackedVector2Array([Vector2(-13, -mouth_height + 7 + recoil_y), Vector2(13, -mouth_height + 7 + recoil_y), Vector2(13 - toward * 6, -10), Vector2(-13 - toward * 6, -10)])
	draw_colored_polygon(barrel_points, Color(0.06, 0.11, 0.15))
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -mouth_height + 8 + recoil_y), Vector2(10, -mouth_height + 8 + recoil_y), Vector2(10 - toward * 6, -12), Vector2(-10 - toward * 6, -12)]), barrel)
	draw_line(Vector2(-7, -mouth_height + 9 + recoil_y), Vector2(-7 - toward * 6, -13), Color(0.30, 0.43, 0.45), 3.0)
	draw_rect(Rect2(-16, -mouth_height - 3 + recoil_y, 32, 11), brass)
	draw_rect(Rect2(-16, -mouth_height - 3 + recoil_y, 32, 3), light)
	draw_rect(Rect2(-12, -mouth_height + recoil_y, 24, 5), Color(0.025, 0.07, 0.10))
	draw_rect(Rect2(-17, -18, 34, 5), brass)
	draw_rect(Rect2(-14, -18, 28, 2), light)

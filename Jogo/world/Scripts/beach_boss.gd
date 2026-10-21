extends Node2D
## Urus, o Urubu só perde vida com Nico lançado por um dos canhões.

signal defeated

@export var boss_texture: Texture2D
@export var flight_frames: Array[Texture2D] = []
@export var hurt_frames: Array[Texture2D] = []
@export var maximum_health := 3
@export var arena_start_x := 4270.0
@export var arena_min_x := 4256.0
@export var arena_max_x := 5056.0
@export var arena_floor_y := 64.0

var phase := 1
var _entrance_seen := false
var _entrance: CanvasLayer
var _last_cannon_x := -INF
var _gust := false
var _gust_side := 1.0
var health := 3
var active := false
var _dead := false
var _time := 0.0
var _arena_time := 0.0
var _home_position := Vector2.ZERO
var _attack_clock := 2.6
var _warning_left := 0.0
var _warning_positions: Array[float] = []
var _feathers: Array[Dictionary] = []
var _used_shots: Dictionary = {}
var _hit_flash := 0.0
var _defeat_time := 0.0
var _message_left := 0.0
var _message := ""
var _punch_notice_cooldown := 0.0
var _player: CharacterBody2D
var _hud_layer: CanvasLayer
var _meter: BossMeter
var _instruction: Label


class BossMeter extends Control:
	var health := 3
	var maximum := 3
	func _draw() -> void:
		draw_style_box(_panel(), Rect2(Vector2.ZERO, size))
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(0, 12), "URUS, O URUBU", HORIZONTAL_ALIGNMENT_CENTER, size.x, 9, Color(1.0, 0.91, 0.70))
		var start_x := (size.x - float(maximum) * 31.0 + 3.0) * 0.5
		for index in maximum:
			var mark := Rect2(start_x + float(index) * 31.0, 18.0, 28.0, 6.0)
			draw_rect(mark, Color(0.97, 0.43, 0.35) if index < health else Color(0.27, 0.29, 0.36))
			draw_rect(mark, Color(1.0, 0.76, 0.52, 0.7), false, 1.0)

	func _panel() -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.04, 0.09, 0.14, 0.91)
		style.border_color = Color(0.59, 0.71, 0.71)
		style.set_border_width_all(1)
		style.set_corner_radius_all(3)
		return style


func _ready() -> void:
	add_to_group("beach_boss")
	health = maxi(maximum_health, 1)
	_home_position = global_position
	z_index = 7
	_build_hud()
	queue_redraw()


func _build_hud() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.layer = 5
	add_child(_hud_layer)
	_meter = BossMeter.new()
	_meter.position = Vector2(244.0, 12.0)
	_meter.size = Vector2(152.0, 30.0)
	_meter.maximum = maximum_health
	_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(_meter)
	_instruction = Label.new()
	_instruction.position = Vector2(148.0, 45.0)
	_instruction.size = Vector2(344.0, 22.0)
	_instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_instruction.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_instruction.add_theme_font_size_override("font_size", 11)
	_instruction.add_theme_color_override("font_color", Color(1.0, 0.95, 0.76))
	_instruction.add_theme_color_override("font_shadow_color", Color(0.04, 0.11, 0.18))
	_instruction.add_theme_constant_override("shadow_offset_x", 1)
	_instruction.add_theme_constant_override("shadow_offset_y", 1)
	_hud_layer.add_child(_instruction)
	_hud_layer.hide()


func _physics_process(delta: float) -> void:
	_time += delta
	_hit_flash = maxf(_hit_flash - delta, 0.0)
	_punch_notice_cooldown = maxf(_punch_notice_cooldown - delta, 0.0)
	_message_left = maxf(_message_left - delta, 0.0)
	if _dead:
		_defeat_time += delta
		if _defeat_time > 1.8:
			_hud_layer.hide()
		queue_redraw()
		return
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not is_instance_valid(_player):
		return
	if _player.global_position.x < arena_min_x - 96.0 or _player.is_dead():
		if active:
			active = false
			_clear_attacks()
			_hud_layer.hide()
		return
	if not active and _player.global_position.x >= arena_start_x:
		active = true
		_attack_clock = 2.6
		_hud_layer.show()
		_show_message("Urus muda de lado! Mira verde: pule no canhão.", 5.0)
		if not _entrance_seen:
			_entrance_seen=true
			_entrance=preload("res://world/Scripts/boss_entrance.gd").new()
			_entrance.boss=self;_entrance.kind="urus";_entrance.name="UrusEntrance"
			get_parent().add_child(_entrance)
			return
	if not active:
		return
	_arena_time += delta
	global_position = get_predicted_position(0.0)
	_instruction.text = _message if _message_left > 0.0 else ("2 / 2 · RAJADA FINAL · Alterne canhões e pule penas baixas" if phase==2 else "1 / 2 · Mira verde: pule  ·  Dourada: espere ou troque")
	if _player.get_meta("cannon_flight", false):
		_clear_attacks()
		_attack_clock = 2.6
		queue_redraw()
		return
	if _player.is_attacking() and _player.global_position.distance_to(get_hit_position()) < 85.0 and _punch_notice_cooldown <= 0.0:
		take_damage(1, _player.global_position)
	_tick_feathers(delta)
	if _warning_left > 0.0:
		_warning_left -= delta
		if _warning_left <= 0.0:
			_release_feathers()
	else:
		_attack_clock -= delta
		if _attack_clock <= 0.0:
			_begin_warning()
	queue_redraw()


func _begin_warning() -> void:
	_gust = phase==2 and not _gust
	_warning_left = 1.2 if _gust else 0.9
	_attack_clock = 3.0
	var target_x := clampf(_player.global_position.x, arena_min_x + 24.0, arena_max_x - 24.0)
	_warning_positions.clear()
	for offset in [-56.0, 0.0, 56.0]:
		_warning_positions.append(clampf(target_x + offset, arena_min_x + 20.0, arena_max_x - 20.0))
	_show_message("Atenção às marcas na areia!", 1.3)
	if _gust:_show_message("RAJADA BAIXA! Pule as penas; depois escolha o outro canhão.",1.8)
	Sfx.alert()


func _release_feathers() -> void:
	if _gust:
		_gust_side=-_gust_side
		for i in 2:
			_feathers.append({"position":Vector2(arena_min_x-20-i*32 if _gust_side>0 else arena_max_x+20+i*32,arena_floor_y-6),"velocity":Vector2(_gust_side*170,0),"age":0.0})
		_warning_positions.clear()
		return
	for target_x in _warning_positions:
		var origin := get_hit_position() + Vector2(0, 16)
		var target := Vector2(target_x, arena_floor_y - 7.0)
		_feathers.append({"position": origin, "velocity": origin.direction_to(target) * 168.0, "age": 0.0})
	_warning_positions.clear()


func _tick_feathers(delta: float) -> void:
	for index in range(_feathers.size() - 1, -1, -1):
		var feather: Dictionary = _feathers[index]
		feather["position"] += Vector2(feather["velocity"]) * delta
		feather["age"] += delta
		var point: Vector2 = feather["position"]
		var hit := point.distance_to(_player.global_position + Vector2(0, -3)) < 13.0
		if hit:
			_player.take_damage(1, point)
		if hit or float(feather["age"]) > 3.2 or point.y > arena_floor_y + 6.0:
			_feathers.remove_at(index)


func _clear_attacks() -> void:
	_feathers.clear()
	_warning_positions.clear()
	_warning_left = 0.0


func notify_launch() -> void:
	_clear_attacks()
	_attack_clock = 2.6


func get_hit_position() -> Vector2:
	return global_position


func get_predicted_position(seconds: float) -> Vector2:
	if _dead:
		return global_position
	var future := _arena_time + maxf(seconds, 0.0)
	return _home_position + Vector2(sin(future * (0.52 if phase==2 else 0.45)) * (174.0 if phase==2 else 152.0), sin(future * 0.9) * 6.0)


func predicts_hit(point: Vector2, seconds: float) -> bool:
	if phase==2 and absf(point.x-_last_cannon_x)<8:return false
	var predicted := get_predicted_position(seconds)
	return absf(predicted.x - point.x) <= 44.0 and absf(predicted.y - point.y) <= 40.0


## Apenas o canhão que está terminando um voo válido pode causar o impacto.
func receive_cannon_hit(cannon: Node, shot_id: int) -> bool:
	if _dead or not active or not is_instance_valid(cannon):
		return false
	if not cannon.is_in_group("beach_cannons") or not cannon.has_method("is_shot_hitting"):
		return false
	if not cannon.is_shot_hitting(self, shot_id):
		return false
	var token := "%d:%d" % [cannon.get_instance_id(), shot_id]
	if _used_shots.has(token):
		return false
	_used_shots[token] = true
	var impact: Vector2 = cannon.get_impact_point()
	if absf(global_position.x - impact.x) > 44.0 or absf(global_position.y - impact.y) > 40.0:
		_show_message("Passou longe! Espere a mira verde ou troque de canhão.", 2.6)
		Fx.popup(impact + Vector2(0, -18), "ERROU!", Color(1.0, 0.81, 0.43), 10)
		return false
	if phase==2 and absf(impact.x-_last_cannon_x)<8:
		_show_message("Ele protegeu esse lado! Use o outro canhão.",2.5)
		return false
	_last_cannon_x=impact.x
	health = maxi(health - 1, 0)
	_meter.health = health
	_meter.queue_redraw()
	_hit_flash = 0.28
	notify_launch()
	Fx.burst(get_hit_position(), Color(1.0, 0.81, 0.38), 15, 160.0)
	Sfx.hit()
	if health==0 and phase==1:
		phase=2;health=2;_last_cannon_x=-INF
		_meter.maximum=2;_meter.health=2;_meter.queue_redraw()
		_show_message("RAJADA FINAL! Dois impactos, alternando os canhões. Pule as penas baixas!",5.5)
		Sfx.alert()
	elif health == 0:
		_dead = true
		_defeat_time = 0.0
		_show_message("Urus, o Urubu caiu! Abra a jaula!", 1.8)
		_instruction.text = _message
		Sfx.enemy_death()
		defeated.emit()
	else:
		_show_message("Acertou! Troque de lado ou espere a mira verde.", 2.1)
	queue_redraw()
	return true


## Socos comuns não atravessam a defesa do chefe.
func take_damage(_amount: float, _source_position: Vector2) -> void:
	if _dead or _punch_notice_cooldown > 0.0:
		return
	_punch_notice_cooldown = 1.3
	_show_message("Use os canhões! Espere a mira verde.", 2.2)
	Fx.popup(get_hit_position() + Vector2(0, -54), "Use os canhões!", Color(1.0, 0.87, 0.49), 10)
	Sfx.select()


func _show_message(text: String, duration: float) -> void:
	_message = text
	_message_left = duration


func is_dead() -> bool:
	return _dead


func _draw() -> void:
	var bob := Vector2.ZERO
	if _dead:
		bob += Vector2(0.0, minf(_defeat_time * 90.0, 75.0))
	var tint := Color(1.0, 0.72, 0.55) if _hit_flash > 0.0 else Color.WHITE
	if _dead:
		tint.a = clampf(1.0 - _defeat_time / 1.8, 0.0, 1.0)
	var frame: Texture2D = boss_texture
	if _dead and not hurt_frames.is_empty():
		frame = hurt_frames.back()
	elif _hit_flash > 0.0 and not hurt_frames.is_empty():
		var hurt_index := mini(int((0.28 - _hit_flash) / 0.28 * hurt_frames.size()), hurt_frames.size() - 1)
		frame = hurt_frames[hurt_index]
	elif not flight_frames.is_empty():
		frame = flight_frames[int(_time * 6.0) % flight_frames.size()]
	if frame != null:
		draw_texture_rect(frame, Rect2(Vector2(-36, -48) + bob, Vector2(72, 96)), false, tint)
	else:
		_draw_fallback(bob, tint)
	if _gust and _warning_left>0:
		for x in [arena_min_x+30,arena_max_x-30]:
			var at:=to_local(Vector2(x,arena_floor_y-15))
			draw_string(ThemeDB.fallback_font,at-Vector2(22,0),"PULE",HORIZONTAL_ALIGNMENT_CENTER,44,10,Color("ffe5a8"))
	for target_x in _warning_positions:
		var point := to_local(Vector2(target_x, arena_floor_y - 2.0))
		var pulse := 0.55 + 0.45 * sin(_time * 18.0)
		draw_rect(Rect2(point + Vector2(-15, -3), Vector2(30, 3)), Color(1.0, 0.64, 0.24, pulse))
		draw_line(point + Vector2(-5, -12), point + Vector2(0, -5), Color(1.0, 0.87, 0.45), 2.0)
		draw_line(point + Vector2(5, -12), point + Vector2(0, -5), Color(1.0, 0.87, 0.45), 2.0)
	for feather: Dictionary in _feathers:
		var point := to_local(Vector2(feather["position"]))
		var direction := Vector2(feather["velocity"]).normalized()
		var side := direction.orthogonal()
		draw_colored_polygon(PackedVector2Array([point - direction * 10.0, point + side * 4.0, point + direction * 9.0, point - side * 4.0]), Color(0.19, 0.16, 0.25))
		draw_line(point - direction * 7.0, point + direction * 6.0, Color(1.0, 0.75, 0.43), 1.0)


func _draw_fallback(offset: Vector2, tint: Color) -> void:
	# Prévia legível enquanto o editor não associa a textura do personagem.
	draw_rect(Rect2(Vector2(-24, -3) + offset, Vector2(48, 45)), Color(0.10, 0.12, 0.18) * tint)
	draw_colored_polygon(PackedVector2Array([Vector2(-14, 0) + offset, Vector2(0, 27) + offset, Vector2(14, 0) + offset]), Color(0.88, 0.88, 0.77) * tint)
	draw_rect(Rect2(Vector2(-3, 7) + offset, Vector2(6, 20)), Color(0.73, 0.18, 0.20) * tint)
	draw_rect(Rect2(Vector2(-18, -37) + offset, Vector2(35, 37)), Color(0.22, 0.21, 0.29) * tint)
	draw_rect(Rect2(Vector2(-10, -30) + offset, Vector2(11, 6)), Color(0.93, 0.84, 0.60) * tint)
	draw_rect(Rect2(Vector2(-6, -29) + offset, Vector2(3, 5)), Color(0.06, 0.07, 0.1) * tint)
	draw_colored_polygon(PackedVector2Array([Vector2(12, -23) + offset, Vector2(32, -15) + offset, Vector2(13, -9) + offset]), Color(0.87, 0.61, 0.30) * tint)

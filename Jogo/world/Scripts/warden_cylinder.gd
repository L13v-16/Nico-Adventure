extends Node2D
## A cylindrical scaffold: orbiting one-way ledges have a front and a rear.
## Stable outer landings provide a readable climbing route and recovery points.
const Cannon = preload("res://world/Scripts/warden_cannon.gd")
const Tiles = preload("res://world/Scripts/underworld_tiles.gd")
var boss: CharacterBody2D
var hits := 0
var _clock := 0.0
var _attack := 3.5
var _warning := 0.0
var _target := Vector2.ZERO
var _orbits: Array[AnimatableBody2D] = []
var cannons: Array[StaticBody2D] = []
var _beams: Array[Dictionary] = []
var _safe := Vector2(-178, -11)
var _finish_left := -1.0

func _ready() -> void:
	process_physics_priority = -20
	add_to_group("warden_cylinders")
	position = Vector2(7145, -160)
	for tier in 4:
		for side in [-1.0, 1.0]:
			_landing(Vector2(side * 170, -tier * 60.0), 88)
		for part in 4:
			var ledge := _landing(Vector2.ZERO, 68, true)
			ledge.set_meta("tier", tier)
			ledge.set_meta("angle", part * TAU / 4 + tier * 0.7)
			_orbits.append(ledge)
	for i in 3:
		var cannon := Cannon.new()
		cannon.element = "ice" if i == 1 else "fire"
		cannon.position = Vector2(-170 if i % 2 == 0 else 170, -(i + 1) * 60.0)
		cannon.stage = self
		cannon.enabled = i == 0
		cannon.activated.connect(_on_cannon)
		add_child(cannon)
		cannons.append(cannon)
	_recover()
	Sfx.play("warden_rise", -5)
	Fx.popup(position + Vector2(-120, -260), "ÚLTIMA CORRENTE · SUBA E ATIVE OS CANHÕES", Color("ffe0aa"), 10)

func _landing(at: Vector2, width: float, orbit := false) -> AnimatableBody2D:
	var body := AnimatableBody2D.new()
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 0
	body.sync_to_physics = false
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 10)
	var collider := CollisionShape2D.new()
	collider.position.y = 5
	collider.shape = shape
	collider.one_way_collision = true
	collider.one_way_collision_margin = 6
	body.add_child(collider)
	body.draw.connect(func():
		Tiles.platform(body, Rect2(-width / 2, 0, width, 14))
		body.draw_rect(Rect2(-width / 2 + 3, 0, width - 6, 2), Color("b0a0bb") if orbit else Color("d4b27a")))
	add_child(body)
	return body

func _physics_process(delta: float) -> void:
	if not boss.active or boss.phase != 5: return
	if _finish_left >= 0:
		_finish_left -= delta
		if _finish_left <= 0:
			boss._defeat()
			return
	_clock += delta
	for ledge in _orbits:
		var tier: int = ledge.get_meta("tier")
		var angle: float = ledge.get_meta("angle") + _clock * (0.32 if tier % 2 == 0 else -0.28)
		var front := cos(angle) >= -0.1
		var rider: bool = absf(boss._player.global_position.x - ledge.global_position.x) < 38 and absf(boss._player.global_position.y + 11 - ledge.global_position.y) < 9 and boss._player.velocity.y >= -5
		ledge.position = Vector2(sin(angle) * 128, -tier * 60 - 26 + cos(angle) * 7)
		ledge.z_index = 2 if front else -2
		ledge.modulate = Color.WHITE if front else Color("5d526d")
		# Never remove the platform under a rider as it rounds the cylinder.
		ledge.collision_layer = 1 if front or rider else 0
	var player: CharacterBody2D = boss._player
	if player.is_on_floor() and absf(player.position.x - position.x) > 125 and player.position.y < position.y - 20:
		_safe = Vector2(-178 if player.position.x < position.x else 178, roundf((player.position.y + 11 - position.y) / 60) * 60 - 11)
		player.respawn_position = position + _safe
	if player.position.y > position.y + 38 and not player.is_dead():
		player.take_damage(1, player.position + Vector2(0, 30))
		_recover()
	_attack -= delta
	if _attack <= 0 and _warning <= 0:
		_warning = 1.05
		_target = player.position + Vector2(0, 11)
		Sfx.play("warden_chain", -8)
	if _warning > 0:
		_warning = maxf(0, _warning - delta)
		if _warning == 0:
			Sfx.play("warden_slam", -8)
			Fx.burst(_target, Color("d6a77d"), 12, 100)
			if absf(player.position.x - _target.x) < 24 and absf(player.position.y + 11 - _target.y) < 34:
				player.take_damage(1, _target)
			_attack = 3.8
	for beam in _beams: beam.time += delta
	_beams = _beams.filter(func(beam: Dictionary) -> bool: return beam.time < 0.65)
	queue_redraw()

func _recover() -> void:
	var player: CharacterBody2D = boss._player
	player.position = position + _safe
	player.respawn_position = player.position
	player.velocity = Vector2.ZERO
	player._invulnerability_timer = 1.4
	_warning = 0
	_attack = 2.8

func _on_cannon(cannon: StaticBody2D) -> void:
	if not boss.active or boss.phase != 5 or hits >= 3: return
	cannon.set_meta("fired_at", cannon._clock)
	hits += 1
	_beams.append({"from": cannon.position + Vector2(0, -28), "to": Vector2(0, -118), "time": 0.0, "ice": cannon.element == "ice"})
	Sfx.play("warden_cannon", -3)
	Sfx.play("warden_break", -7)
	Fx.burst(position + Vector2(0, -118), Color("a5ebff") if cannon.element == "ice" else Color("ffc37a"), 26, 170)
	boss._player._add_shake(3.5)
	boss.health = 3 - hits
	boss._sprite.play(&"hurt")
	if hits < 3:
		cannons[hits].enabled = true
		boss._vulnerable = 0.6
	else:
		# Let the final shell land before opening the exit.
		boss.health = 0.1
		_finish_left = 0.65

func _draw() -> void:
	# Elliptical chain rails and shaded ribs make the cylindrical depth readable.
	for tier in 4:
		var y := -tier * 60.0 - 20
		for back in [true, false]:
			var color := Color("493d59") if back else Color("ac8a72")
			var previous := Vector2.ZERO
			for step in 33:
				var a := PI + step * PI / 32 if back else step * PI / 32
				var point := Vector2(cos(a) * 150, y + sin(a) * 13)
				if step > 0:
					draw_line(previous.round(), point.round(), Color("241e30"), 4)
					draw_line(previous.round(), point.round(), color, 2)
				if step % 2 == 0: draw_rect(Rect2(point.round() - Vector2(2, 2), Vector2(4, 4)), color)
				previous = point
	for x in [-170.0, 170.0]:
		draw_line(Vector2(x, 6), Vector2(x, -240), Color("242130"), 6)
		draw_line(Vector2(x - 1, 6), Vector2(x - 1, -240), Color("81657c"), 2)
	if _warning > 0:
		var at := to_local(_target)
		draw_rect(Rect2(at - Vector2(23, 4), Vector2(46, 4)), Color("ffbb76"))
		for y in range(-130, -8, 12): draw_rect(Rect2(at + Vector2(-1, y), Vector2(2, 6)), Color(1, 0.65, 0.35, 0.5))
	for beam in _beams:
		var travel: float = minf(beam.time / 0.3, 1.0)
		var point: Vector2 = beam.from.lerp(beam.to, travel)
		var color := Color("95e5ff") if beam.ice else Color("ffbc71")
		if travel < 1:
			draw_line(beam.from, point, Color(color, 0.5), 3)
			draw_circle(point, 6, color)

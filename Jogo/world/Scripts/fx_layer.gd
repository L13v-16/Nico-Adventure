extends Node2D
## Camada de partículas e textos flutuantes.
##
## Vive dentro da cena atual (criada pelo singleton Fx) para que os efeitos
## acompanhem o mundo e desapareçam junto com a fase. Tudo é desenhado à mão,
## sem nós extras, mantendo o visual pixelado do projeto.

const MAX_PARTICLES := 400
const MAX_TEXTS := 20

const SHAPE_SQUARE := 0
const SHAPE_CIRCLE := 1
const SHAPE_SPARK := 2

var _particles: Array[Dictionary] = []
var _texts: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	z_index = 40
	_rng.randomize()


func clear_all() -> void:
	for child in get_children():
		if child.is_in_group("sprite_effects90"):child.queue_free()
	_particles.clear()
	_texts.clear()
	queue_redraw()


## Cria um punhado de partículas. A direção é dada em radianos; "bias" empurra
## todas elas para o mesmo lado (útil para poeira que fica para trás).
func spawn(
	origin: Vector2,
	amount: int,
	angle_center: float,
	angle_spread: float,
	speed: Vector2,
	life: Vector2,
	size: Vector2,
	color: Color,
	gravity: float = 220.0,
	shape: int = SHAPE_CIRCLE,
	bias: Vector2 = Vector2.ZERO
) -> void:
	for _index in range(amount):
		if _particles.size() >= MAX_PARTICLES:
			return
		var angle: float = angle_center + _rng.randf_range(-angle_spread, angle_spread)
		var particle_life: float = _rng.randf_range(life.x, life.y)
		_particles.append({
			"position": origin,
			"velocity": Vector2(cos(angle), sin(angle)) * _rng.randf_range(speed.x, speed.y) + bias,
			"life": particle_life,
			"max_life": particle_life,
			"size": _rng.randf_range(size.x, size.y),
			"color": color,
			"gravity": gravity,
			"shape": shape,
		})


## Texto que sobe e some (contadores "+1", avisos curtos).
func add_text(origin: Vector2, label: String, color: Color, font_size: int) -> void:
	if _texts.size() >= MAX_TEXTS:
		_texts.remove_at(0)
	var text_life: float = 0.75
	_texts.append({
		"position": origin,
		"text": label,
		"color": color,
		"size": font_size,
		"life": text_life,
		"max_life": text_life,
		"velocity": Vector2(0.0, -28.0),
	})


func _process(delta: float) -> void:
	if _particles.is_empty() and _texts.is_empty():
		return
	for index: int in range(_particles.size() - 1, -1, -1):
		var particle: Dictionary = _particles[index]
		var remaining: float = float(particle["life"]) - delta
		particle["life"] = remaining
		if remaining <= 0.0:
			_particles.remove_at(index)
			continue
		var velocity: Vector2 = particle["velocity"]
		velocity.y += float(particle["gravity"]) * delta
		particle["velocity"] = velocity
		particle["position"] = Vector2(particle["position"]) + velocity * delta
	for index: int in range(_texts.size() - 1, -1, -1):
		var entry: Dictionary = _texts[index]
		var remaining: float = float(entry["life"]) - delta
		entry["life"] = remaining
		if remaining <= 0.0:
			_texts.remove_at(index)
			continue
		entry["position"] = Vector2(entry["position"]) + Vector2(entry["velocity"]) * delta
	queue_redraw()


func _draw() -> void:
	for particle: Dictionary in _particles:
		var ratio: float = clampf(float(particle["life"]) / maxf(float(particle["max_life"]), 0.001), 0.0, 1.0)
		var color: Color = particle["color"]
		color.a *= ratio
		var position: Vector2 = particle["position"]
		var half: float = float(particle["size"]) * 0.5 * (0.35 + 0.65 * ratio)
		match int(particle["shape"]):
			SHAPE_SQUARE:
				draw_rect(Rect2(position - Vector2(half, half), Vector2(half, half) * 2.0), color)
			SHAPE_SPARK:
				var direction: Vector2 = Vector2(particle["velocity"]).normalized()
				draw_line(
					position - direction * half * 2.4,
					position + direction * half * 2.4,
					color, maxf(half * 0.9, 1.0), true
				)
			_:
				draw_circle(position, half, color)

	var font: Font = ThemeDB.fallback_font
	for entry: Dictionary in _texts:
		var ratio: float = clampf(float(entry["life"]) / maxf(float(entry["max_life"]), 0.001), 0.0, 1.0)
		var color: Color = entry["color"]
		color.a *= clampf(ratio * 1.8, 0.0, 1.0)
		var position: Vector2 = entry["position"]
		var font_size: int = int(entry["size"])
		var outline := Color(0.02, 0.03, 0.07, color.a * 0.85)
		draw_string_outline(
			font, position, String(entry["text"]),
			HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, 3, outline
		)
		draw_string(
			font, position, String(entry["text"]),
			HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, color
		)

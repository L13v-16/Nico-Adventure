extends AnimatableBody2D
## Plataforma de mão única. O CharacterBody2D recebe sua velocidade pelo
## move_and_slide(), sem precisar reposicionar o jogador manualmente.

## Destino em pixels, relativo à posição colocada no editor.
## Vector2(128, 0) move na horizontal; Vector2(0, -64) cria um elevador.
@export var travel_offset: Vector2 = Vector2(96.0, 0.0)

## Segundos para ir da origem ao destino. A volta leva o mesmo tempo.
@export_range(0.1, 30.0, 0.05, "or_greater") var travel_time: float = 2.5

## Ponto inicial no ciclo completo: 0 = origem, 0.5 = destino, 1 = origem.
## Use valores diferentes para desencontrar plataformas com o mesmo percurso.
@export_range(0.0, 1.0, 0.01) var phase: float = 0.0

## Tempo parado em cada ponta, para embarcar sem perseguir a plataforma.
@export_range(0.0, 2.0, 0.05) var endpoint_pause: float = 0.0

var _origin: Vector2
var _elapsed: float = 0.0


func _ready() -> void:
	_origin = position
	# A fase inicial é uma colocação, não uma viagem com velocidade alta.
	sync_to_physics = false
	position = _position_at_time(0.0)
	reset_physics_interpolation()
	sync_to_physics = true


func _physics_process(delta: float) -> void:
	_elapsed += delta
	# AnimatableBody2D calcula a velocidade real para carregar quem está em cima.
	position = _position_at_time(_elapsed)


func _position_at_time(seconds: float) -> Vector2:
	var leg := maxf(travel_time, 0.1)
	var pause := maxf(endpoint_pause, 0.0)
	var cycle_duration := (leg + pause) * 2.0
	var elapsed := fposmod(seconds + phase * cycle_duration, cycle_duration)
	var weight := 0.0
	if elapsed < pause:
		weight = 0.0
	elif elapsed < pause + leg:
		weight = (1.0 - cos((elapsed - pause) / leg * PI)) * 0.5
	elif elapsed < pause * 2.0 + leg:
		weight = 1.0
	else:
		weight = (1.0 + cos((elapsed - pause * 2.0 - leg) / leg * PI)) * 0.5
	return _origin + travel_offset * weight

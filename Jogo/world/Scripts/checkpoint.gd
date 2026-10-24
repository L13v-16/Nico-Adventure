class_name Checkpoint
extends Area2D
## Bandeira pixel art: seis quadros âmbar e seis verdes, com o mastro ancorado.
## A área de toque e o Marker2D de retorno permanecem definidos na fase.

const FLAG_FRAMES := preload("res://world/Arte/Checkpoint/checkpoint_v16.tres")

var activated := false
var _time := 0.0
var _glow := 0.0

@onready var _flag: AnimatedSprite2D = $FlagSprite


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_flag.sprite_frames = FLAG_FRAMES
	_flag.play(&"active" if activated else &"inactive")


func _process(delta: float) -> void:
	_time += delta
	_glow = lerpf(_glow, 1.0 if activated else 0.0, 1.0 - exp(-6.0 * delta))
	if activated:
		queue_redraw()


func activate() -> void:
	if activated:
		return
	activated = true
	_flag.play(&"active")
	_flag.frame = 0
	Fx.burst(global_position + Vector2(10, -30), Color(0.62, 1.0, 0.78), 14, 125.0)
	queue_redraw()


func _draw() -> void:
	if not activated:
		return
	# Pontos de luz inteiros, discretos, compatíveis com o desenho em pixels.
	for index: int in 3:
		var phase := fposmod(_time * 0.65 + float(index) / 3.0, 1.0)
		var at := Vector2(roundf(4.0 + float(index) * 7.0), roundf(-24.0 - phase * 17.0))
		var ink := Color(0.7, 1.0, 0.8, sin(phase * PI) * 0.6 * _glow)
		draw_rect(Rect2(at, Vector2.ONE), ink)

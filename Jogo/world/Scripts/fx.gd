extends Node
## Fx — fachada única para os efeitos visuais e o "hit-stop".
##
## Registrado como autoload (ver project.godot), então qualquer script pode
## chamar Fx.dust(), Fx.hitstop(), Fx.popup() sem precisar de referências.
## A camada de desenho é criada sob demanda dentro da cena atual.

const EFFECT_SCRIPT: GDScript = preload("res://world/Scripts/fx_layer.gd")
const HITSTOP_FRAMES := 4
const HITSTOP_LIMIT := 6
const HITSTOP_SCALE := 0.08
const HITSTOP_FRAME_USEC := 1_000_000.0 / 60.0

var _layer
var _hitstop_until_usec: int = 0
var _resume_time_scale := 1.0


func _ready() -> void:
	# Precisa continuar rodando mesmo com a árvore pausada para devolver o
	# tempo normal depois de um hit-stop ou de um menu de pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if _hitstop_until_usec > 0 and Time.get_ticks_usec() >= _hitstop_until_usec:
		cancel_hitstop()


func _layer_node():
	var scene: Node = get_tree().current_scene
	if scene == null:
		return null
	if is_instance_valid(_layer) and _layer.get_parent() == scene:
		return _layer
	_layer = scene.get_node_or_null("FxLayer")
	if _layer == null:
		_layer = EFFECT_SCRIPT.new() as Node2D
		_layer.name = "FxLayer"
		scene.add_child(_layer)
	return _layer


# --- Efeitos -----------------------------------------------------------------

## Poeira levantada ao correr ou aterrissar. "drift" indica a direção (-1/0/1).
func dust(origin: Vector2, amount: int = 3, drift: float = 0.0) -> void:
	var layer = _layer_node()
	if layer == null:
		return
	layer.spawn(
		origin, amount, -PI * 0.5 + drift * 0.45, 1.0,
		Vector2(16.0, 46.0), Vector2(0.20, 0.40), Vector2(3.0, 5.0),
		Color(0.87, 0.88, 0.82, 0.78), 130.0, layer.SHAPE_SQUARE,
		Vector2(-drift * 36.0, -16.0)
	)


## Nuvem de poeira de aterrissagem; "strength" vai de 0 a 1.
func land(origin: Vector2, strength: float) -> void:
	sprite_impact(origin,3,lerpf(24,36,clampf(strength,0,1)))
	var layer = _layer_node()
	if layer == null:
		return
	strength = clampf(strength, 0.0, 1.0)
	var amount: int = int(roundf(lerpf(5.0, 13.0, strength)))
	var speed: float = lerpf(24.0, 80.0, strength)
	layer.spawn(
		origin, amount, -PI * 0.5, 1.25,
		Vector2(speed * 0.35, speed), Vector2(0.16, 0.36), Vector2(3.0, 6.0),
		Color(0.9, 0.9, 0.85, 0.85), 150.0, layer.SHAPE_SQUARE
	)


## Faíscas de um golpe que acertou um inimigo.
func impact(origin: Vector2, direction: float) -> void:
	sprite_impact(origin)
	var layer = _layer_node()
	if layer == null:
		return
	var angle: float = 0.0 if direction >= 0.0 else PI
	layer.spawn(
		origin, 9, angle, 0.8,
		Vector2(90.0, 260.0), Vector2(0.09, 0.22), Vector2(2.0, 4.0),
		Color(1.0, 0.96, 0.72, 1.0), 30.0, layer.SHAPE_SPARK
	)


## Explosão radial (coleta, dano, derrota de inimigo).
func burst(origin: Vector2, color: Color, amount: int = 10, speed: float = 130.0) -> void:
	var layer = _layer_node()
	if layer == null:
		return
	layer.spawn(
		origin, amount, 0.0, PI,
		Vector2(speed * 0.35, speed * 1.4), Vector2(0.20, 0.55), Vector2(2.0, 5.0),
		color, 240.0, layer.SHAPE_CIRCLE
	)


## Texto curto que sobe e desaparece.
func popup(origin: Vector2, label: String, color: Color = Color.WHITE, font_size: int = 9) -> void:
	var layer = _layer_node()
	if layer == null:
		return
	layer.add_text(origin, label, color, font_size)


# --- Hit-stop ----------------------------------------------------------------

func sprite_impact(origin:Vector2,row:int=2,width:float=28) -> void:
	if not get_tree().current_scene is Node2D:return
	var layer=_layer_node()
	if layer==null or layer.get_child_count()>=24:return
	var effect:=preload("res://world/Scripts/sprite_effect.gd").new()
	effect.position=origin;effect.row=row;effect.width=width;layer.add_child(effect)

## Desacelera o impacto sem entregar um passo de física igual a zero.
## O prazo usa tempo real: não depende do FPS nem do relógio desacelerado.
func hitstop(frames: int = HITSTOP_FRAMES) -> void:
	if frames <= 0 or get_tree().paused:
		return
	if _hitstop_until_usec == 0:
		_resume_time_scale = Engine.time_scale if Engine.time_scale > 0.0 else 1.0
	var duration := int(clampi(frames, 1, HITSTOP_LIMIT) * HITSTOP_FRAME_USEC)
	_hitstop_until_usec = maxi(_hitstop_until_usec, Time.get_ticks_usec() + duration)
	Engine.time_scale = minf(_resume_time_scale, HITSTOP_SCALE)


## Devolve o tempo normal imediatamente (usar ao pausar, reiniciar ou concluir).
func cancel_hitstop() -> void:
	if _hitstop_until_usec > 0:
		Engine.time_scale = _resume_time_scale
	_hitstop_until_usec = 0

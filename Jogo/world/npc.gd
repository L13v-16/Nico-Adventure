extends CharacterBody2D
## Morador da vila: caminha devagar entre dois pontos, sem machucar nem barrar o
## Nico. Também guarda o nome, o retrato e as falas que a caixa de diálogo mostra.

@export var folha: Texture2D
@export_group("Passeio")
@export var speed: float = 20.0
@export var walk_left: float = -44.0
@export var walk_right: float = 44.0
@export var frame_speed: float = 6.0
@export_group("Diálogo")
@export var nome: String = "Morador"
@export var retrato: Texture2D
@export var falas: PackedStringArray = PackedStringArray()
@export var conversa_id: String = ""
## Caras extras do morador (1 a 4). Vazio usa só o retrato único.
@export var retratos: Array[Texture2D] = []
## Cara de cada fala de abertura (1 a 4). Vazio usa a primeira.
@export var caras: PackedInt32Array = PackedInt32Array()

const Conversas := preload("res://world/Scripts/conversas.gd")

var direction: int = -1
var _home: float = 0.0
var _tempo_quadro: float = 0.0

@onready var sprite: Sprite2D = $sprite


func _ready() -> void:
	add_to_group("npcs")
	_home = global_position.x
	sprite.texture = folha
	sprite.hframes = 6


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif velocity.y > 0.0:
		velocity.y = 0.0
	if global_position.x <= _home + walk_left:
		direction = 1
	elif global_position.x >= _home + walk_right:
		direction = -1
	velocity.x = speed * direction
	sprite.flip_h = direction > 0
	_tempo_quadro += delta * frame_speed
	sprite.frame = int(_tempo_quadro) % 6
	move_and_slide()


## Falas do morador, para a caixa de diálogo.
func conversa() -> PackedStringArray:
	return falas


## Perguntas que o Nico pode escolher depois das falas de abertura.
func perguntas() -> Array:
	if conversa_id.is_empty():
		return []
	return Conversas.perguntas(conversa_id)


## Retrato da cara pedida (1 a 4); sem caras extras, devolve o retrato único.
func retrato_da_cara(indice: int) -> Texture2D:
	if retratos.is_empty():
		return retrato
	return retratos[clampi(indice - 1, 0, retratos.size() - 1)]


## Cara da fala de abertura na posição indicada.
func cara_da_fala(indice: int) -> int:
	if indice < 0 or indice >= caras.size():
		return 1
	return caras[indice]

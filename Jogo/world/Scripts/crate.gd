extends StaticBody2D

@onready var head_detector: Area2D = $head_detector
var crate_piece = preload("res://prefabs/crate_piece.tscn")

@export var pieces: Array[Texture2D] = []
@export var hit_points: int = 5
var impulse: float = 200.0

func _ready() -> void:
	head_detector.body_entered.connect(_on_head_detector_body_entered)

func _on_head_detector_body_entered(body: Node2D) -> void:
	# Verifica se quem bateu foi o player (com class_name player definido)
	if body is player:
		if hit_points <= 1:
			break_crate()
		else:
			hit_points -= 1
			hit_flash()

func break_crate() -> void:
	for piece in pieces.size():
		var piece_instance = crate_piece.instantiate() as RigidBody2D
		get_tree().current_scene.add_child(piece_instance)

		# Atribui a textura correta para cada pedaço
		piece_instance.get_node("texture").texture = pieces[piece]

		# Define a posição inicial igual à da caixa
		piece_instance.global_position = global_position

		# Aplicação de impulso randômico com range_f
		piece_instance.apply_impulse(
			Vector2(
				randf_range(-impulse * 0.5, impulse * 0.5),
				randf_range(impulse * 1.5, -impulse * 2.5)
			)
		)

	queue_free()

func hit_flash() -> void:
	var twin = create_tween()
	twin.set_ease(Tween.EASE_OUT)
	twin.set_trans(Tween.TRANS_BACK)

	# Efeito de Squash & Stretch e brilho simultâneo (Parallel)
	twin.tween_property(self, "scale", Vector2(1.3, 0.5), 0.2)
	twin.parallel().tween_property(self, "modulate", Color.WHITE * 5.0, 0.1)

	twin.tween_property(self, "scale", Vector2(1.0, 1.0), 0.05)
	twin.parallel().tween_property(self, "modulate", Color.WHITE, 0.1)

	# Enadeiramento (Chain) com transição spring
	twin.chain().set_trans(Tween.TRANS_SPRING)

extends Area2D

@onready var anim: AnimatedSprite2D = $Anim

func _on_body_entered(body: Node2D) -> void:
	anim.play("collect")


func _on_anim_animation_finished() -> void:
	queue_free()

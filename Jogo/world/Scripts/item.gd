extends Area2D

@onready var anim: AnimatedSprite2D = $Anim
var collected := false

func _on_body_entered(body: Node2D) -> void:
	if collected or not body.is_in_group("player"):
		return
	if not body.collect_item():
		return
	collected = true
	set_deferred("monitoring", false)
	anim.play("collect")
	Sfx.cherry()
	Fx.burst(global_position, Color(1.0, 0.45, 0.55), 8, 110.0)
	Fx.popup(global_position + Vector2(0.0, -14.0), "+1", Color(1.0, 0.9, 0.92), 8)


func _on_anim_animation_finished() -> void:
	if collected:
		queue_free()

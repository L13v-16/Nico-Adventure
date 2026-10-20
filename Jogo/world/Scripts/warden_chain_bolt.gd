extends Node2D
## A locked-direction chain cast. Ground and gravity rocks block it.
const Chains = preload("res://world/Scripts/underworld_chain_art.gd")
var flight := Vector2.LEFT * 175
var life := 3.2
func _ready() -> void:
	add_to_group("underworld_projectiles")
	z_index = 5
func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0: queue_free(); return
	var next := global_position + flight * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, next, 1 | 2)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		if hit.collider.is_in_group("player"): hit.collider.take_damage(1, global_position - flight.normalized() * 10)
		Fx.burst(hit.position, Color("ddb982"), 6, 75)
		queue_free()
		return
	global_position = next
	queue_redraw()
func _draw() -> void:
	var direction := flight.normalized()
	Chains.strand(self, -direction * 37, Vector2.ZERO, 5)
	draw_set_transform(Vector2.ZERO, flight.angle() + PI / 2)
	draw_texture_rect(Chains.HOOK, Rect2(-5, -9, 10, 19), false)
	draw_set_transform(Vector2.ZERO)

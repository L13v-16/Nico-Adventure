extends StaticBody2D
## A pinned chain is a real counterattack target, even far from the guardian.
var boss: CharacterBody2D
const Chains = preload("res://world/Scripts/underworld_chain_art.gd")
func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = Vector2(28, 28)
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position.y = -14
	add_child(collider)
	hide()
func is_dead() -> bool:
	return not is_instance_valid(boss) or not boss.active or boss.phase != 1 or boss._vulnerable <= 0
func _physics_process(_delta: float) -> void:
	var hot := not is_dead()
	visible = hot
	collision_layer = 4 if hot else 0
	if hot:
		if not is_in_group("enemies"): add_to_group("enemies")
		global_position = Vector2(boss._target_x, 100)
	elif is_in_group("enemies"): remove_from_group("enemies")
	queue_redraw()
func take_damage(amount: float, source: Vector2) -> void:
	if not is_dead(): boss.take_damage(amount, source)
func take_element(element: String, source: Vector2) -> void:
	if not is_dead(): boss.take_element(element, source)
func _draw() -> void:
	if is_dead(): return
	draw_texture_rect(Chains.CLASP, Rect2(-9, -28, 18, 25), false)
	draw_arc(Vector2(0, -13), 19 + sin(boss._phase_time * 8), 0, TAU, 16, Color("ffe3a5"), 1)
	draw_string(ThemeDB.fallback_font, Vector2(-32, -36), "J / X", HORIZONTAL_ALIGNMENT_CENTER, 64, 9, Color("fff0c3"))

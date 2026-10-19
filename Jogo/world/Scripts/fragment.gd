extends Area2D
## Fragmento — item secreto escondido pela fase (GDD §15 e §74).
## Conta para "Segredos" no fim da fase. Todo o desenho é feito em código.

signal collected

var taken := false
var _time := 0.0


func _ready() -> void:
	z_index = -1
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 11.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if taken or not body.is_in_group("player"):
		return
	taken = true
	set_deferred("monitoring", false)
	Sfx.secret()
	Fx.burst(global_position, Color(1.0, 0.86, 0.42), 12, 140.0)
	Fx.popup(global_position + Vector2(0.0, -18.0), "Fragmento!", Color(1.0, 0.92, 0.62), 9)
	collected.emit()
	queue_free()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	var center := Vector2(0.0, sin(_time * 2.2) * 2.0)
	draw_circle(center, 10.0 + pulse * 2.5, Color(1.0, 0.86, 0.42, 0.14))
	draw_circle(center, 6.0 + pulse * 1.5, Color(1.0, 0.9, 0.55, 0.22))
	var shard := PackedVector2Array([
		center + Vector2(0.0, -8.0), center + Vector2(5.5, 0.0),
		center + Vector2(0.0, 8.0), center + Vector2(-5.5, 0.0),
	])
	draw_colored_polygon(shard, Color(1.0, 0.9, 0.55))
	draw_polyline(PackedVector2Array([shard[0], shard[1], shard[2], shard[3], shard[0]]), Color(1.0, 0.98, 0.82), 1.0)
	draw_line(center + Vector2(0.0, -6.0), center + Vector2(0.0, 6.0), Color(1.0, 0.99, 0.9, 0.85), 1.0)

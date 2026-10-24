extends RefCounted
## Original generated sprites, cropped by AtlasTexture without editing pixels.
const STRAIGHT = preload("res://world/Arte/Underworld/V43/chain_0.tres")
const VERTICAL = preload("res://world/Arte/Underworld/V43/chain_1.tres")
const FRONT = preload("res://world/Arte/Underworld/V43/chain_2.tres")
const BACK = preload("res://world/Arte/Underworld/V43/chain_3.tres")
const HOOK = preload("res://world/Arte/Underworld/V43/chain_4.tres")
const CLASP = preload("res://world/Arte/Underworld/V43/chain_5.tres")
const SLACK = preload("res://world/Arte/Underworld/V43/chain_6.tres")
const COIL = preload("res://world/Arte/Underworld/V43/chain_7.tres")

static func strand(canvas: CanvasItem, from: Vector2, to: Vector2, thickness := 5.0, sag := 0.0, tint := Color.WHITE) -> void:
	var count := maxi(1, int(ceilf(from.distance_to(to) / (thickness * 3))))
	for i in count:
		var t0 := float(i) / count
		var t1 := float(i + 1) / count
		var a := from.lerp(to, t0) + Vector2(0, sin(t0 * PI) * sag)
		var b := from.lerp(to, t1) + Vector2(0, sin(t1 * PI) * sag)
		canvas.draw_set_transform(a.round(), (b - a).angle())
		canvas.draw_texture_rect(STRAIGHT, Rect2(0, -thickness / 2, a.distance_to(b) + 1, thickness), false, tint)
	canvas.draw_set_transform(Vector2.ZERO)

static func vertical(canvas: CanvasItem, end: Vector2) -> void:
	var count := maxi(1, int(ceilf(end.length() / 24)))
	for i in count:
		canvas.draw_set_transform((end * float(i) / count).round(), end.angle() - PI / 2)
		canvas.draw_texture_rect(VERTICAL, Rect2(-3, 0, 6, end.length() / count + 1), false)
	canvas.draw_set_transform(Vector2.ZERO)
	canvas.draw_texture_rect(HOOK, Rect2(end - Vector2(5, 5), Vector2(10, 17)), false)

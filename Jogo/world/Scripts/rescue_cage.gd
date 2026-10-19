extends StaticBody2D

signal opened
var health := 3.0
var unlocked := false
var _flash := 0.0
var _lock_notice := 0.0
var _break := 0.0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("rescue_cage")

func _process(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	_lock_notice = maxf(_lock_notice - delta, 0.0)
	if health <= 0:
		_break = minf(_break + delta * 2.0, 1.0)
	queue_redraw()

func take_damage(amount: float, _source: Vector2) -> void:
	if health <= 0 or amount <= 0:
		return
	if not unlocked:
		if _lock_notice <= 0.0:
			Fx.popup(global_position + Vector2(0,-62), "DERROTE URUS", Color("ffd798"), 9)
			_lock_notice = 1.6
		return
	health = maxf(health - amount, 0.0)
	_flash = 0.2
	Fx.burst(global_position + Vector2(0,-24), Color("ffe1a3"), 8, 110)
	Sfx.hit()
	if health == 0:
		collision_layer = 0
		$CollisionShape2D.set_deferred("disabled", true)
		opened.emit()

func is_dead() -> bool:
	return health <= 0

func _draw() -> void:
	var dark := Color("243849")
	var steel := Color("83afb0") if _flash <= 0.0 else Color("fff2c4")
	var fade := 1.0 - _break
	steel.a = fade
	dark.a = fade
	draw_rect(Rect2(-36, -3, 72, 4), Color("6d5249"))
	if fade <= 0.0:
		return
	var top := -54.0 + _break * 14.0
	draw_rect(Rect2(-36, top, 72, 5), dark)
	draw_rect(Rect2(-34, top + 1, 68, 2), steel)
	for i in range(7):
		var x := -33.0 + float(i) * 11.0 + (-1.0 if i < 3 else 1.0) * _break * 20.0
		draw_rect(Rect2(x, top + 4, 3, -top), dark)
		draw_rect(Rect2(x + 1, top + 4, 1, -top - 2), steel)
	var lock := Color("f9cd75") if unlocked else Color("ec8d71")
	lock.a = fade
	draw_rect(Rect2(-5, -26, 11, 12), dark)
	draw_rect(Rect2(-4, -24, 9, 9), lock)
	if unlocked:
		draw_rect(Rect2(-1, -22, 2, 5), dark)

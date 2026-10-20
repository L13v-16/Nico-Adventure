extends StaticBody2D
signal activated(cannon: Node)
const FRAMES = [preload("res://world/Arte/Underworld/V42/cannon_0.tres"), preload("res://world/Arte/Underworld/V42/cannon_1.tres"), preload("res://world/Arte/Underworld/V42/cannon_2.tres"), preload("res://world/Arte/Underworld/V42/cannon_3.tres"), preload("res://world/Arte/Underworld/V42/cannon_4.tres"), preload("res://world/Arte/Underworld/V42/cannon_5.tres"), preload("res://world/Arte/Underworld/V42/cannon_6.tres"), preload("res://world/Arte/Underworld/V42/cannon_7.tres")]
var element := "fire"
var spent := false
var enabled := false
var _charge := 0.0
var _wrong := 0.0
var _clock := 0.0
var stage: Node2D

func _ready() -> void:
	collision_layer = 16
	collision_mask = 0
	z_index = 4
	add_to_group("warden_cannons")
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	var collider := CollisionShape2D.new()
	collider.position.y = -16
	collider.shape = shape
	add_child(collider)

func take_element(incoming: String, _source: Vector2) -> void:
	if spent or not enabled or _charge > 0 or not stage.boss.active: return
	if incoming != element:
		_wrong = 1.0
		Sfx.play("warden_fizzle", -8)
		Fx.popup(global_position + Vector2(0, -58), "USE " + ("FOGO" if element == "fire" else "GELO"), Color("ffe3ab"), 9)
		return
	_charge = 0.85
	Sfx.play("warden_fire_charge" if element == "fire" else "warden_ice_charge", -6)

func _physics_process(delta: float) -> void:
	_clock += delta
	_wrong = maxf(0, _wrong - delta)
	if _charge > 0:
		_charge = maxf(0, _charge - delta)
		if _charge == 0:
			spent = true
			activated.emit(self)
	queue_redraw()

func _draw() -> void:
	var frame := 0
	if _charge > 0: frame = 1
	elif spent: frame = 3 if _clock - float(get_meta("fired_at", -99.0)) > 0.35 else 2
	frame += 4 if element == "ice" else 0
	var texture: Texture2D = FRAMES[frame]
	# Preserve native size between recoil / muzzle frames; only the atlas varies.
	var ratio := 0.145
	var width := texture.get_width() * ratio
	var height := texture.get_height() * ratio
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1) if position.x > 0 else Vector2.ONE)
	draw_texture_rect(texture, Rect2(-width * 0.5, -height, width, height), false, Color("777585") if spent else (Color.WHITE if enabled else Color("777585")))
	draw_set_transform(Vector2.ZERO)
	var color := Color("ffbc6b") if element == "fire" else Color("a4edff")
	if enabled and not spent:
		draw_string(ThemeDB.fallback_font, Vector2(-38, -61), "FOGO" if element == "fire" else "GELO", HORIZONTAL_ALIGNMENT_CENTER, 76, 9, color)
		draw_arc(Vector2(0, -24), 29 + sin(_clock * 4) * 2, 0, TAU, 16, Color(color, 0.23), 1)
	elif spent:
		draw_string(ThemeDB.fallback_font, Vector2(-30, -52), "ATIVADO", HORIZONTAL_ALIGNMENT_CENTER, 60, 8, Color("b8ecbc"))

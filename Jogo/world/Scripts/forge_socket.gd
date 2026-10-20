extends StaticBody2D
var element:="fire"
var forge:Node2D
var _sprite:AnimatedSprite2D
var _label:Label
var _pulse:=0.0
func _ready() -> void:
	var shape:=RectangleShape2D.new()
	shape.size=Vector2(32,34)
	var collider:=CollisionShape2D.new()
	collider.shape=shape
	add_child(collider)
	_sprite=preload("res://world/Scripts/underworld_art.gd").actor("V35/valves",54)
	_sprite.position+=Vector2(0,20)
	add_child(_sprite)
	_label=Label.new()
	_label.position=Vector2(-28,-39)
	_label.size=Vector2(56,12)
	_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size",7)
	_label.add_theme_color_override("font_color",Color("ffbe74") if element=="fire" else Color("a4edff"))
	_label.add_theme_color_override("font_outline_color",Color("18131f"))
	_label.add_theme_constant_override("outline_size",2)
	add_child(_label)
	_update_sprite()
func take_element(value:String,_source:Vector2) -> void:
	if value==element:forge.activate(value)
	else:forge.activate("wrong")
	_pulse=0.4
	_update_sprite()
func _process(delta:float) -> void:
	_pulse=maxf(0,_pulse-delta)
	_update_sprite()
func _update_sprite() -> void:
	var expected:bool=forge.power_ready and not forge.complete and forge.PATTERN[forge.progress]==element
	var lit:bool=expected or forge.complete or _pulse>0
	_sprite.play(StringName(element+("_active" if lit else "_idle")))
	_sprite.modulate=Color.WHITE if lit else Color("a49aa6")
	_label.text=("▼ " if expected else "")+("FOGO" if element=="fire" else "GELO")

extends Area2D
@export var vine_paths: Array[NodePath] = []
const Art := preload("res://world/Scripts/magic_art.gd")
var opened := false
var _sprite: AnimatedSprite2D
var _cooldown := 0.0

func _ready() -> void:
	add_to_group("vine_plants")
	collision_layer = 0
	collision_mask = 2
	_sprite = Art.prop(&"closed",38)
	add_child(_sprite)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(34,32)
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position.y = -16
	add_child(collider)
	body_entered.connect(_touch)

func _process(delta: float) -> void:
	_cooldown = maxf(0,_cooldown-delta)

func _touch(body: Node2D) -> void:
	if not body.is_in_group("player") or _cooldown>0 or body.is_dead(): return
	_cooldown = 0.75
	opened = not opened
	_sprite.play(&"open" if opened else &"closed")
	for path in vine_paths:
		var vine := get_node_or_null(path)
		if vine != null: vine.toggle_plant()
	Fx.burst(global_position+Vector2(0,-20),Color("9cffe1"),12,90)
	Fx.popup(global_position+Vector2(0,-45),"O CIPÓ SE MOVEU",Color("c7ffec"),9)
	Sfx.secret()

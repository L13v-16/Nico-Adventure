extends AnimatableBody2D
signal settled
@export_enum("wall","pillar","block") var kind:="wall"
@export var push_offset:=Vector2(120,0)
var broken:=false
var pushing:=false
var _destination:=Vector2.ZERO
var _sprite:Sprite2D
var _collider:CollisionShape2D
const Art=preload("res://world/Scripts/underworld_art.gd")
func _ready() -> void:
	add_to_group("jose_targets")
	collision_layer=1
	collision_mask=0
	var size:=Vector2(34,108) if kind=="wall" else (Vector2(27,126) if kind=="pillar" else Vector2(52,48))
	_sprite=Art.prop(6 if kind=="wall" else (7 if kind=="pillar" else 5),size,Vector2(-size.x/2,-size.y))
	add_child(_sprite)
	var shape:=RectangleShape2D.new()
	shape.size=size
	_collider=CollisionShape2D.new()
	_collider.shape=shape
	_collider.position=Vector2(0,-size.y/2)
	add_child(_collider)
func can_jose_target() -> bool:return not broken
func jose_point() -> Vector2:return global_position
func receive_jose_hit() -> bool:
	if broken:return false
	broken=true
	Sfx.hit()
	Fx.burst(position+Vector2(0,-30),Color("bfa18d"),18,160)
	if kind=="block":
		pushing=true
		_destination=position+push_offset
	else:
		_collider.set_deferred("disabled",true)
		if kind=="pillar":
			# A coluna caída vira uma ponte com a mesma altura visual e física.
			var bridge:=preload("res://world/Scripts/underworld_terrain.gd").new()
			bridge.position=position+Vector2(0,-3)
			bridge.width=154
			bridge.depth=12
			bridge.platform=true
			get_parent().add_child(bridge)
		_sprite.hide()
	return true
func _physics_process(delta:float) -> void:
	if pushing:
		position=position.move_toward(_destination,85*delta)
		if position.is_equal_approx(_destination):
			pushing=false
			settled.emit()
	queue_redraw()
func _draw() -> void:
	if broken:return
	var player:=get_tree().get_first_node_in_group("player") as Node2D
	if player!=null and absf(player.position.x-position.x)<205:
		draw_circle(Vector2(0,-65),10,Color("ddaa65"),false,2)
		draw_line(Vector2(-5,-65),Vector2(5,-65),Color("fff0c4"),2)

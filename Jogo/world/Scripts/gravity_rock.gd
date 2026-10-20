extends AnimatableBody2D
@export_enum("follow","repel","shuttle") var behavior:="follow"
@export var travel:=80.0
@export var width:=88.0
@export var phase:=0.0
var _home:=Vector2.ZERO
var _clock:=0.0
var _sprite:Sprite2D
const Art=preload("res://world/Scripts/underworld_art.gd")
func _ready() -> void:
	add_to_group("gravity_rocks")
	collision_layer=1
	collision_mask=0
	_home=position
	var shape:=RectangleShape2D.new()
	shape.size=Vector2(width,44)
	var collider:=CollisionShape2D.new()
	collider.shape=shape
	collider.position=Vector2(0,22)
	add_child(collider)
	_sprite=Sprite2D.new()
	_sprite.centered=false
	_sprite.texture=load("res://world/Arte/Underworld/V36/terrain_%02d.tres"%(15 if behavior=="repel" else 14))
	_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale=Vector2(width,44)/_sprite.texture.get_size()
	_sprite.position=Vector2(-width/2,0)
	if behavior=="shuttle":_sprite.modulate=Color("ffe0a8")
	add_child(_sprite)
func _physics_process(delta:float) -> void:
	_clock+=delta
	var player:=get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player==null:return
	var aboard:bool=absf(player.position.x-position.x)<width/2+5 and absf(player.position.y+11-position.y)<5 and player.velocity.y>=-5
	var desired:=_home
	if behavior=="shuttle":desired.x+=sin(_clock*0.65+phase)*travel
	elif absf(player.position.x-position.x)<230:
		var side:float=signf(player.position.x-position.x)
		desired.x=clampf(player.position.x if behavior=="follow" else position.x-side*travel,_home.x-travel,_home.x+travel)
	if not aboard:position=position.move_toward(desired,52*delta)
	if has_meta("cherry"):
		var cherry:Node2D=get_meta("cherry").get_ref()
		if is_instance_valid(cherry) and not cherry.collected:cherry.global_position=global_position+Vector2(0,-28)
	queue_redraw()
func _draw() -> void:
	var color:=Color("9ed8f2") if behavior=="follow" else Color("d7a1f3")
	if behavior=="shuttle":color=Color("e7bb77")
	draw_rect(Rect2(-9,8,18,2),color)
	draw_rect(Rect2(-1,2,2,13),color)

extends Node2D
signal collected
var available:=false
var taken:=false
var _clock:=0.0
var _sprite:Sprite2D
func _ready() -> void:
	_sprite=preload("res://world/Scripts/underworld_art.gd").prop(11,Vector2(36,27),Vector2(-18,-27))
	add_child(_sprite)
	hide()
func reveal(at:Vector2) -> void:
	position=at
	available=true
	show()
func _physics_process(delta:float) -> void:
	if not available or taken:return
	_clock+=delta
	_sprite.position.y=-27+roundf(sin(_clock*3)*3)
	var player:=get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player!=null and not player.is_dead() and player.position.distance_to(position+Vector2(0,-16))<34:
		if not Save.set_story_flag("depth_key"):return
		taken=true
		hide()
		Sfx.checkpoint()
		collected.emit()

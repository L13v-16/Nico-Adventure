extends Node2D
var collected:=false
var _sprite:Sprite2D
var _clock:=0.0
func _ready() -> void:
	_sprite=preload("res://world/Scripts/underworld_art.gd").prop(14,Vector2(20,24),Vector2(-10,-24))
	add_child(_sprite)
func _physics_process(delta:float) -> void:
	if collected:return
	_clock+=delta
	_sprite.position.y=-24+roundf(sin(_clock*3)*2)
	var player:=get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player!=null and not player.is_dead() and player.position.distance_to(position+Vector2(0,-14))<25:
		collected=true
		player.elements.grant_fruit(20)
		Fx.popup(position+Vector2(0,-38),"FRUTA-DO-DRAGÃO · K: FOGO",Color("ffc48a"),10)
		Sfx.cherry()
		hide()

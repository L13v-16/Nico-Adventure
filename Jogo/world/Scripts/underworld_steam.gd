extends Node2D
@export var phase:=0.0
var cycle:=0.0
const PLUMES=[preload("res://world/Arte/Underworld/V35/forge_29.tres"),preload("res://world/Arte/Underworld/V35/forge_30.tres"),preload("res://world/Arte/Underworld/V35/forge_31.tres")]
var _base:Sprite2D
var _jet:Sprite2D
func _physics_process(delta:float) -> void:
	cycle=fposmod(cycle+delta,4.1)
	if cycle>2.9 and cycle<3.65:
		var player:=get_tree().get_first_node_in_group("player") as CharacterBody2D
		if player!=null and absf(player.position.x-position.x)<17 and player.position.y>position.y-95 and player.position.y<position.y+5:player.take_damage(1,position)
	_jet.visible=cycle>1.9
	if _jet.visible:
		var burst:=cycle>2.9 and cycle<3.65
		var cooling:=cycle>=3.65
		var size:=Vector2(32,57) if cooling else (Vector2(30,90) if burst else Vector2(15,18))
		_jet.texture=PLUMES[2 if cooling else (1 if burst else 0)]
		_jet.scale=size/_jet.texture.get_size()
		_jet.position=Vector2(-size.x/2,-size.y-4)
		_jet.modulate.a=clampf((4.1-cycle)/0.45,0,1) if cooling else 1
func _ready() -> void:
	cycle=phase
	_jet=Sprite2D.new()
	_jet.centered=false
	_jet.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_jet.hide()
	add_child(_jet)
	_base=Sprite2D.new()
	_base.centered=false
	_base.texture=preload("res://world/Arte/Underworld/V35/forge_28.tres")
	_base.scale=Vector2(28,13)/_base.texture.get_size()
	_base.position=Vector2(-14,-11)
	_base.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_base)

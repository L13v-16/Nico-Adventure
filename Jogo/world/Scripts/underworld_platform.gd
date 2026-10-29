extends "res://world/Scripts/moving_platform.gd"
const Tiles=preload("res://world/Scripts/underworld_tiles.gd")
@export var width:=86.0
func _ready() -> void:
	super._ready()
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	material=preload("res://world/Scripts/magic_art.gd").material()
	material.set_shader_parameter("alpha_cutoff",.94)
func _draw() -> void:
	Tiles.platform(self,Rect2(-width/2,0,width,16),1)
	for x in [-width/2+10,width/2-10]:
		preload("res://world/Scripts/underworld_chain_art.gd").strand(self,Vector2(x,-30),Vector2(x,1),4)

extends "res://world/Scripts/moving_platform.gd"
const Tiles=preload("res://world/Scripts/underworld_tiles.gd")
@export var width:=86.0
func _draw() -> void:
	Tiles.platform(self,Rect2(-width/2,0,width,16))
	for x in [-width/2+10,width/2-10]:
		for y in range(-30,0,7):
			draw_rect(Rect2(roundf(x)-2,y,4,6),Color("a38d91"),false,1)

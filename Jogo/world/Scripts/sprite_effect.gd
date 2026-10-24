extends Node2D
const Art=preload("res://world/Scripts/general_art.gd")
var row:=2
var duration:=.30
var width:=28.0
var clock:=0.0
func _ready() -> void:
	add_to_group("sprite_effects90");texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;material=Art.material()
func _process(delta:float) -> void:
	clock+=delta
	if clock>=duration:queue_free();return
	queue_redraw()
func _draw() -> void:
	var tex:=Art.cell("fx",row*4+mini(3,int(clock/duration*4)),true)
	var size:=Vector2(width,width*tex.get_height()/tex.get_width())
	var at:=-size/2
	if row==3:at.y=-float(tex.get_meta("ground_foot"))*width/tex.get_width()
	draw_texture_rect(tex,Rect2(at,size),false)

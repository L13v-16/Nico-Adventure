extends Control
const BACKGROUND=preload("res://world/Arte/Underworld/V36/background.png")
var _clock:=0.0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _process(delta:float) -> void:
	_clock+=delta
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(0,0,640,360),Color("211c2d"))
	var camera:=get_viewport().get_camera_2d()
	var world_x:float=camera.get_screen_center_position().x if camera!=null else 0
	var offset:=fposmod(world_x*0.08,640)
	for i in range(-1,2):draw_texture_rect(BACKGROUND,Rect2(i*640-offset,-36,640,427),false,Color("9f98af"))
	for i in 14:
		var x:=fposmod(i*79.7-world_x*0.18+sin(i+_clock)*10,640)
		var y:=fposmod(i*31.7-_clock*(9+i%4*3),360)
		draw_rect(Rect2(roundf(x),roundf(y),1+(i%2),2),Color(1,0.5+0.1*(i%3),0.25,0.25+0.4*absf(sin(_clock+i))))

extends Control
const BACKGROUND := preload("res://world/Arte/Magic/magic_background.png")
var _clock := 0.0
const FIREFLIES := [preload("res://world/Arte/Magic/V26/firefly_open.tres"),preload("res://world/Arte/Magic/V26/firefly_closed.tres")]
var _flies: Node2D

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_flies=Node2D.new()
	_flies.material=preload("res://world/Scripts/magic_art.gd").material()
	_flies.draw.connect(_draw_flies)
	add_child(_flies)

func _process(delta: float) -> void:
	_clock+=delta
	queue_redraw()
	_flies.queue_redraw()

func _draw_flies() -> void:
	# Rotas completas de uma borda à outra, independentes da câmera.
	for i in 12:
		var direction:=1.0 if i%2==0 else -1.0
		var speed:=18.0+float(i%4)*7
		var x:=fposmod(float(i)*63.7+_clock*speed*direction,700)-30
		var y:=64+float(i%6)*40+sin(_clock*1.1+i*0.8)*18
		var frame:=int(_clock*11+i)%2
		var size:=Vector2(7,6) if i%3!=0 else Vector2(10,8)
		_flies.draw_texture_rect(FIREFLIES[frame],Rect2(Vector2(roundf(x),roundf(y)),size),false,Color(1,1,0.85,0.7+0.3*absf(sin(_clock*2+i))))

func _draw() -> void:
	draw_rect(Rect2(0,0,640,360),Color("352956"))
	var camera:=get_viewport().get_camera_2d()
	var world_x:=camera.get_screen_center_position().x if camera!=null else 0.0
	var offset:=fposmod(world_x*0.1,640)
	for i in range(-1,2):
		draw_texture_rect(BACKGROUND,Rect2(i*640-offset,-28,640,426),false,Color(0.83,0.79,0.94))
	for i in 38:
		var x:=fposmod(i*79.1-world_x*0.21+sin(_clock*0.4+i)*12,640)
		var y:=fposmod(i*43.7-_clock*(2.0+i%3),330)
		draw_rect(Rect2(roundf(x),roundf(y),1,2),Color(0.65,1,0.9,0.2+0.45*absf(sin(_clock*1.3+i))))

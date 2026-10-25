extends Control
var _clock:=0.0
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(delta:float) -> void:_clock+=delta;queue_redraw()
func _draw() -> void:
	var level:=get_parent().get_parent()
	var tint:=Color("a3a6b4") if level.sector<4 else Color("7d889b")
	if level.sector==5:
		draw_texture_rect(preload("res://world/Arte/MemoriesV96/control_room.png"),Rect2(0,0,640,426),false)
		if level._plan_seen:draw_texture_rect(preload("res://world/Arte/MemoriesV96/circus_plan.png"),Rect2(233,88,174,116),false,Color(.7,1,.8,.8))
		return
	draw_texture_rect(preload("res://world/Arte/CorpV82/background.png"),Rect2(0,0,640,360),false,tint)
	draw_rect(Rect2(0,0,640,360),Color(0.025,.035,.065,.35))
	if level.lockdown or level.alert>=65:draw_rect(Rect2(0,0,640,360),Color(.5,.015,.03,.07+.04*sin(_clock*4)))
	if level.sector==4:
		for i in 25:
			var x:=fposmod(float(i*47)-_clock*32,680)-20
			draw_line(Vector2(x,i*17),Vector2(x+12,i*17-2),Color(.6,.7,.85,.2),1)

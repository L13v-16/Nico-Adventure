extends Node2D
## O santuário ilumina a caverna sem cobrir Nico nem a interface.
var _clock:=0.0
var _altar:AnimatedSprite2D
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	_altar=get_parent().get_node("Temple")
func _process(delta:float) -> void:
	_clock+=delta
	var awakened:bool=_altar.animation!=&"temple_dormant"
	_altar.modulate=Color.WHITE if awakened else Color("d9d5ce")
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(_altar):return
	var awakened:bool=_altar.animation!=&"temple_dormant"
	var strength:float=1.0 if awakened else 0.38
	for i in 5:
		var x:float=(i-2)*28
		var sway:float=sin(_clock*0.25+i)*6
		draw_colored_polygon(PackedVector2Array([Vector2(x-6,-232),Vector2(x+6,-232),Vector2(x+32+sway,0),Vector2(x-32+sway,0)]),Color(1,0.89,0.61,0.018*strength))
	for i in 24:
		var t:float=fposmod(_clock*0.11+float(i)/24,1)
		var at:=Vector2(sin(i*4.73)*126+sin(_clock+i)*3,-t*208)
		var alpha:float=sin(t*PI)*(0.25+0.15*sin(_clock*2+i))*strength
		draw_rect(Rect2(at.round(),Vector2.ONE*(2 if i%5==0 else 1)),Color(1,0.92,0.7,alpha))
	if awakened:
		for i in 3:
			var t:float=fposmod(_clock*0.3+float(i)/3,1)
			draw_set_transform(Vector2(0,-6),0,Vector2(1,0.18))
			draw_arc(Vector2.ZERO,24+t*36,0,TAU,48,Color(1,0.85,0.45,(1-t)*0.25),1)
			draw_set_transform(Vector2.ZERO)

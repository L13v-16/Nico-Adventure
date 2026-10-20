extends Node2D
signal solved
const PATTERN:=["fire","ice","fire","ice"]
const Art=preload("res://world/Scripts/underworld_art.gd")
var progress:=0
var complete:=false
var power_ready:=false
var gate:StaticBody2D
var _label:Label
var _flash:=0.0
func _ready() -> void:
	add_child(Art.prop(10,Vector2(128,110),Vector2(-64,-108)))
	for element in ["fire","ice"]:
		var socket:=StaticBody2D.new()
		socket.name="HotValve" if element=="fire" else "ColdValve"
		socket.collision_layer=16
		socket.collision_mask=0
		socket.position=Vector2(-103 if element=="fire" else 103,-20)
		socket.set_script(preload("res://world/Scripts/forge_socket.gd"))
		socket.element=element
		socket.forge=self
		add_child(socket)
	_label=Label.new()
	_label.position=Vector2(-84,8)
	_label.size=Vector2(168,20)
	_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size",8)
	_label.add_theme_color_override("font_color",Color("ffe0a6"))
	add_child(_label)
	_update()
func activate(element:String) -> bool:
	if complete:return false
	if not power_ready:
		_flash=0.7
		return false
	if element!=PATTERN[progress]:
		progress=0
		_flash=0.7
		Sfx.alert()
		_update()
		return false
	progress+=1
	Sfx.checkpoint()
	if progress==PATTERN.size():
		complete=true
		if is_instance_valid(gate):gate.queue_free()
		Fx.burst(position+Vector2(0,-70),Color("fff0ab"),24,180)
		solved.emit()
	_update()
	return true
func _update() -> void:
	_label.text="FORJA INVERTIDA · "+("ABERTA" if complete else ("%d / 4"%progress if power_ready else "C: BLOCO"))
	queue_redraw()
func _process(delta:float) -> void:
	_flash=maxf(0,_flash-delta)
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(-88,6,176,33),Color("1d1b28"))
	draw_rect(Rect2(-88,6,176,33),Color("8b6b56"),false,1)
	for i in 4:
		var color:=Color("ff9a50") if PATTERN[i]=="fire" else Color("a7edff")
		draw_rect(Rect2(-32+i*17,27,12,5),color if i<progress else Color("3a2c42"))
		if not complete and i==progress:draw_rect(Rect2(-34+i*17,25,16,9),Color("fff3d4"),false,1)
	if _flash>0:draw_rect(Rect2(-36,24,72,12),Color(1,0.3,0.15,_flash*0.4))

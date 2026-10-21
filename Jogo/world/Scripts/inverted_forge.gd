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
var _machine:AnimatedSprite2D
var hall:Node2D
func _ready() -> void:
	hall=preload("res://world/Scripts/forge_hall.gd").new()
	hall.name="ForgeHall";hall.forge=self;add_child(hall)
	_machine=Art.actor("V35/forge",112)
	_machine.name="ForgeSprite"
	add_child(_machine)
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
	_label.position=Vector2(-88,-135)
	_label.size=Vector2(176,14)
	_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size",8)
	_label.add_theme_color_override("font_color",Color("ffe0a6"))
	_label.add_theme_color_override("font_outline_color",Color("171321"))
	_label.add_theme_constant_override("outline_size",2)
	add_child(_label)
	_update()
func activate(element:String) -> bool:
	if complete:return false
	if not is_inside():return false
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
	_label.text="FORJA · "+("PRONTA" if complete else ("FOGO / GELO · %d / 4"%progress if power_ready else "DESPERTE NO SANTUÁRIO"))
	var pose:StringName=&"off" if not power_ready else &"ready"
	if complete:pose=&"working"
	elif progress>0:pose=[&"fire",&"ice",&"fire_strike"][progress-1]
	_machine.play(pose)
	queue_redraw()
func _process(delta:float) -> void:
	_flash=maxf(0,_flash-delta)
	_machine.modulate=Color(1,0.65,0.55) if _flash>0 else Color.WHITE
	queue_redraw()
func _draw() -> void:
	if not is_inside():return
	draw_texture_rect(preload("res://world/Arte/Underworld/V35/forge_pipe.tres"),Rect2(-103,-7,206,6),false)
	# Quatro cavidades no chão mostram a sequência mesmo antes da ativação.
	for i in 4:
		var at:=Vector2(-54+i*36,12)
		var fire:bool=PATTERN[i]=="fire"
		var base:=Color("ae494b") if fire else Color("386baf")
		var light:=Color("ff9b83") if fire else Color("8bd9ff")
		if i<progress:base=base.lightened(0.3)
		draw_circle(at,9,Color("151320"))
		draw_circle(at+Vector2(0,1),7,Color("4e3f52"))
		draw_circle(at,6,base)
		draw_rect(Rect2(at+Vector2(-3,-3),Vector2(4,2)),light)
		draw_rect(Rect2(at+Vector2(-3,3),Vector2(7,2)),base.darkened(0.35))
		if i<progress:draw_arc(at,8,0,TAU,24,light,1)

func is_inside() -> bool:
	return is_instance_valid(hall) and hall.inside

extends Node2D
var unlocked:=false
var _clock:=0.0
var _arch:AnimatedSprite2D
func _ready() -> void:
	_arch=preload("res://world/Scripts/underworld_art.gd").actor("scenery",128)
	add_child(_arch)
	_arch.play(&"temple_dormant")
	var title:=Label.new()
	title.text="SAÍDA · CORPORAÇÃO"
	title.position=Vector2(-66,-137)
	title.size=Vector2(132,20)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",8)
	title.add_theme_color_override("font_color",Color("f6cb8b"))
	add_child(title)
func _process(delta:float) -> void:
	_clock+=delta
	_arch.play(&"temple_ready" if unlocked else &"temple_dormant")
	queue_redraw()
func _draw() -> void:
	if unlocked:
		draw_rect(Rect2(-22,-76,44,76),Color("594275"))
		for i in 7:
			var y:=fposmod(i*17-_clock*13,88)
			draw_rect(Rect2(-17+i%3*12,-y-3,2,3),Color("f9c488"))

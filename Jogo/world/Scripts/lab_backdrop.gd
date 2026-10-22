extends Node2D
const Art=preload("res://world/Scripts/lab_art.gd")
func _ready() -> void:
	z_index=-20;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	for x in range(-512,7680,512):
		var section:=clampi(int(maxi(0,x)/1536),0,3)
		var panel:=Sprite2D.new();panel.texture=Art.texture("background_%02d"%section);panel.centered=false
		panel.modulate=Color(.75,.81,.86)
		panel.position=Vector2(x,-153.333);panel.scale=Vector2(513.0/768,256.0/384);add_child(panel)
func _draw() -> void:draw_rect(Rect2(-256,-800,7900,1300),Color("202a39"))

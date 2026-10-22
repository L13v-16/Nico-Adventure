extends Node2D
## One enclosed sector. Door travel changes rooms without reloading collectibles.
var sector:=0
var bounds:=Vector2(-128,1480)
var title:=""
const Art=preload("res://world/Scripts/lab_art.gd")
const ACCENTS:=[Color("e4b45c"),Color("7ed8bd"),Color("e0a06c"),Color("9baeee")]
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var soften:=ShaderMaterial.new();soften.shader=preload("res://world/Scripts/lab_background_soften.gdshader")
	for x in range(int(bounds.x),int(bounds.y),512):
		var panel:=Sprite2D.new();panel.texture=Art.texture("background_%02d"%sector);panel.centered=false
		panel.material=soften;panel.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;panel.z_index=-20
		panel.position=Vector2(x,-154);panel.scale=Vector2(513.0/768,256.0/384);add_child(panel)
	for x in [bounds.x+6,bounds.y-6]:
		var wall:=StaticBody2D.new();wall.collision_layer=1;wall.collision_mask=0;wall.position=Vector2(x,-220)
		var shape:=RectangleShape2D.new();shape.size=Vector2(12,900)
		var collider:=CollisionShape2D.new();collider.shape=shape;wall.add_child(collider);add_child(wall)
		var column:=Art.prop("column",44);column.position+=Vector2(x,100);column.z_index=-1;add_child(column)
	for x in [bounds.x+65,bounds.y-65]:
		var sign:=Label.new();sign.text=title.to_upper();sign.position=Vector2(x-90,18);sign.size=Vector2(180,20)
		sign.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;sign.add_theme_font_size_override("font_size",8)
		sign.modulate=ACCENTS[sector];sign.z_index=2;add_child(sign)
	queue_redraw()
func _draw() -> void:
	var accent:Color=ACCENTS[sector]
	draw_rect(Rect2(bounds.x,-650,bounds.y-bounds.x,495),Color("121a27"))
	draw_rect(Rect2(bounds.x,-160,bounds.y-bounds.x,10),Color("303f50"))
	draw_rect(Rect2(bounds.x,-151,bounds.y-bounds.x,2),accent.darkened(.6))
	for x in [bounds.x,bounds.y-20]:
		draw_rect(Rect2(x,-160,20,260),Color("17202d"))
		draw_rect(Rect2(x+2,-156,3,252),Color("536170"))
	for x in range(int(bounds.x)+110,int(bounds.y)-80,240):
		draw_rect(Rect2(x,-149,72,5),Color("182734"))
		draw_rect(Rect2(x+4,-148,64,2),accent)

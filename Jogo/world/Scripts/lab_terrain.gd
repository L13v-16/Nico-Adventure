extends StaticBody2D
@export var width:=320.0
@export var depth:=256.0
@export var variant:=0
@export var platform:=false
var _texture:Texture2D
const Art=preload("res://world/Scripts/lab_art.gd")
func _ready() -> void:
	_texture=Art.texture("platform" if platform else "floor_%02d"%variant)
	collision_layer=1;collision_mask=0;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var shape:=RectangleShape2D.new();shape.size=Vector2(width,depth)
	var collider:=CollisionShape2D.new();collider.shape=shape;collider.position=Vector2(width/2,depth/2)
	collider.one_way_collision=platform;collider.one_way_collision_margin=10;add_child(collider)
	material=Art.Art.material();material.set_shader_parameter("alpha_cutoff",.94)
func _draw() -> void:
	draw_rect(Rect2(0,0,width,depth),Color("272b3b"))
	if platform:
		var tex:=_texture;var ratio:=width/tex.get_width()
		draw_texture_rect(tex,Rect2(Vector2(0,-3*ratio),Vector2(width,tex.get_height()*ratio)),false);return
	var tex:=_texture
	for x in range(0,int(width),96):
		for y in range(0,int(depth),56):
			var ratio:=98.0/tex.get_width()
			draw_texture_rect(tex,Rect2(Vector2(x-1,y-3*ratio),Vector2(minf(98,width-x+1),58)),false)

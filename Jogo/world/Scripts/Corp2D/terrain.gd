extends StaticBody2D
var width:=320.0
var depth:=80.0
var platform:=false
var variant:=0
var _texture:Texture2D
func _ready() -> void:
	collision_layer=1;collision_mask=0;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_texture=preload("res://world/Scripts/Corp2D/art.gd").cell("props",variant)
	var shape:=RectangleShape2D.new();shape.size=Vector2(width,depth)
	var collider:=CollisionShape2D.new();collider.shape=shape;collider.position=Vector2(width/2,depth/2);collider.one_way_collision=platform;collider.one_way_collision_margin=10;add_child(collider)
func _draw() -> void:
	if not platform:draw_rect(Rect2(0,0,width,depth),Color("151b27"))
	for x in range(0,int(width),80):
		var w:=minf(80,width-x)
		draw_texture_rect_region(_texture,Rect2(x,0,w,24 if platform else 36),Rect2(0,0,_texture.get_width()*w/80,_texture.get_height()))
	if not platform:
		for x in range(0,int(width),80):
			for y in range(36,int(depth),56):draw_texture_rect(preload("res://world/Scripts/Corp2D/art.gd").cell("props",3),Rect2(x,y,minf(80,width-x),56),false,Color("657080"))

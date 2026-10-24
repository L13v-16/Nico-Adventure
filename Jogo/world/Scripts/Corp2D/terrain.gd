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
	var art:=preload("res://world/Scripts/Corp2D/polish_art.gd")
	if not platform:draw_rect(Rect2(0,0,width,depth),Color("151b27"))
	if not platform:
		var tile:Texture2D=art.cell(3)
		for x in range(0,int(width),64):
			for y in range(28,int(depth),64):
				var w:=minf(64,width-x);var h:=minf(64,depth-y)
				draw_texture_rect_region(tile,Rect2(x,y,w,h),Rect2(0,0,tile.get_width()*w/64,tile.get_height()*h/64))
	art.deck(self,width,28)

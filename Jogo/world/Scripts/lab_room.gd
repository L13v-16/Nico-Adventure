extends Node2D
## Tall shafts, with independent backgrounds and continuous supporting walls.
var sector:=0
var bounds:=Vector2(-128,1050)
var base_y:=100.0
var top_y:=-570.0
var title:=""
const Art=preload("res://world/Scripts/lab_art.gd")
const ACCENTS:=[Color("e4b45c"),Color("7ed8bd"),Color("e0a06c"),Color("9baeee")]
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var soften:=ShaderMaterial.new();soften.shader=preload("res://world/Scripts/lab_background_soften.gdshader")
	var backing:=Polygon2D.new();backing.z_index=-30;backing.color=Color("172431")
	backing.polygon=PackedVector2Array([Vector2(bounds.x,top_y-320),Vector2(bounds.y,top_y-320),Vector2(bounds.y,base_y+320),Vector2(bounds.x,base_y+320)]);add_child(backing)
	var source:AtlasTexture=Art.texture("background_%02d"%sector)
	var wall_texture:=AtlasTexture.new();wall_texture.atlas=source.atlas;wall_texture.region=source.region;wall_texture.filter_clip=true
	for x in range(int(bounds.x),int(bounds.y),512):
		for y in range(int(top_y)-256,int(base_y)+256,256):
			var panel:=Sprite2D.new();panel.texture=wall_texture;panel.centered=false
			panel.material=soften;panel.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;panel.z_index=-20
			panel.position=Vector2(x,y);panel.scale=Vector2(513.0/source.region.size.x,257.0/source.region.size.y);add_child(panel)
	for x in [bounds.x+6,bounds.y-6]:
		var wall:=StaticBody2D.new();wall.collision_layer=1;wall.collision_mask=0;wall.position=Vector2(x,(top_y+base_y)*.5)
		var shape:=RectangleShape2D.new();shape.size=Vector2(12,base_y-top_y+750)
		var collider:=CollisionShape2D.new();collider.shape=shape;wall.add_child(collider);add_child(wall)
	queue_redraw()
func _draw() -> void:
	var accent:Color=ACCENTS[sector]
	for x in [bounds.x,bounds.y-18]:
		draw_rect(Rect2(x,top_y-320,18,base_y-top_y+650),Color("17202d"))
		draw_rect(Rect2(x+3,top_y-320,3,base_y-top_y+650),Color("536170"))
		for y in range(int(top_y)-200,int(base_y)+280,96):
			draw_rect(Rect2(x,y,18,10),Color("324957"));draw_rect(Rect2(x+4,y+3,3,3),accent)

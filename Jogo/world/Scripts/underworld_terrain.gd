extends StaticBody2D
@export var width:=320.0
@export var depth:=440.0
@export var one_way:=false
@export var platform:=false
const Tiles=preload("res://world/Scripts/underworld_tiles.gd")
func _ready() -> void:
	collision_layer=1
	collision_mask=0
	var shape:=RectangleShape2D.new()
	shape.size=Vector2(width,depth)
	var collider:=CollisionShape2D.new()
	collider.shape=shape
	collider.position=Vector2(width/2,depth/2)
	collider.one_way_collision=one_way
	add_child(collider)
	queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(0,0,width,depth),Color("211e30"))
	if platform:
		Tiles.platform(self,Rect2(0,0,width,depth))
		return
	for x in range(0,int(width),32):
		for y in range(0,int(depth),32):
			var cell:=Rect2(x,y,minf(32,width-x),minf(32,depth-y))
			var left:=x==0
			var right:=x+32>=width
			var index:=12 if left else (13 if right else 4+(int(x/32)+int(y/32))%4)
			if y==0:index=int(x/32)%4
			Tiles.tile(self,cell,index)
	draw_rect(Rect2(0,0,width,1),Color("7b7189"))

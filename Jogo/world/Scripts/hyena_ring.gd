extends Node2D
const PATH := "res://world/Arte/Magic/V26/"
var locked := false
var spring_side := 0
var _art:Node2D
var _textures:Dictionary={}
func _ready() -> void:
	z_index=1
	_art=Node2D.new()
	_art.material=preload("res://world/Scripts/magic_art.gd").material()
	_art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_art.draw.connect(_paint)
	add_child(_art)
	for key in ["post_left","post_right","ropes","mat","crate"]:_textures[key]=load(PATH+key+".tres")
	_textures.ropes=load(PATH+"rope_middle.tres")
	queue_redraw()
func set_locked(value:bool) -> void:
	locked=value
	_art.queue_redraw()
func set_spring_side(value:int) -> void:
	spring_side=value
	_art.queue_redraw()
func _paint() -> void:
	for x in range(0,672,96):
		_art.draw_texture_rect(_textures.mat,Rect2(x,0,96,31),false)
		_art.draw_texture_rect(_textures.ropes,Rect2(x,-86,97,58),false,Color(1,1,1,1 if locked else 0.65))
	_art.draw_texture_rect(_textures.post_left,Rect2(-18,-106,53,106),false)
	_art.draw_texture_rect(_textures.post_right,Rect2(637,-106,53,106),false)
	_art.draw_texture_rect(_textures.crate,Rect2(706,-33,34,33),false)
	# Brackets physically support the mushroom springs on the side posts.
	for x in [26,646]:
		_art.draw_rect(Rect2(x-22,-52,44,5),Color("a46a45"))
		_art.draw_rect(Rect2(x-22,-52,44,2),Color("efc079"))
		_art.draw_line(Vector2(x,-49),Vector2(x-14 if x<100 else x+14,-23),Color("6c3b50"),5)
	# O limite superior visível do tablado coincide com o chão físico y=64.
	_art.draw_rect(Rect2(0,-1,672,2),Color("c7a0e4"))
	if spring_side!=0:
		var x:=26 if spring_side<0 else 646
		var gold:=Color("ffe2ac")
		_art.draw_rect(Rect2(x-3,-104,6,17),gold)
		_art.draw_line(Vector2(x-11,-92),Vector2(x,-81),gold,3)
		_art.draw_line(Vector2(x,-81),Vector2(x+11,-92),gold,3)
		_art.draw_rect(Rect2(x-24,-21,48,3),gold)

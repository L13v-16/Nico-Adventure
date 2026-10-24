extends RefCounted
## Blocos maiores e silhuetas de apoio recortadas nas dimensões reais do atlas.
const TILES=[preload("res://world/Arte/Underworld/V39/terrain_00.tres"),preload("res://world/Arte/Underworld/V39/terrain_01.tres"),preload("res://world/Arte/Underworld/V39/terrain_02.tres"),preload("res://world/Arte/Underworld/V39/terrain_03.tres"),preload("res://world/Arte/Underworld/V39/terrain_04.tres"),preload("res://world/Arte/Underworld/V39/terrain_05.tres"),preload("res://world/Arte/Underworld/V39/terrain_06.tres"),preload("res://world/Arte/Underworld/V39/terrain_07.tres"),preload("res://world/Arte/Underworld/V39/terrain_08.tres"),preload("res://world/Arte/Underworld/V39/terrain_09.tres"),preload("res://world/Arte/Underworld/V39/terrain_10.tres"),preload("res://world/Arte/Underworld/V39/terrain_11.tres"),preload("res://world/Arte/Underworld/V39/terrain_12.tres"),preload("res://world/Arte/Underworld/V39/terrain_13.tres"),preload("res://world/Arte/Underworld/V39/terrain_14.tres"),preload("res://world/Arte/Underworld/V39/terrain_15.tres")]
static func tile(canvas:CanvasItem,rect:Rect2,index:int) -> void:
	canvas.draw_texture_rect(TILES[index],rect,false)
static func cliff(canvas:CanvasItem,rect:Rect2,left:bool,top:bool) -> void:
	var textures:Array[Texture2D]=[preload("res://world/Arte/Underworld/V45/cliff_00.tres"),preload("res://world/Arte/Underworld/V45/cliff_01.tres"),preload("res://world/Arte/Underworld/V45/cliff_02.tres"),preload("res://world/Arte/Underworld/V45/cliff_03.tres")]
	canvas.draw_texture_rect(textures[(0 if left else 1)+(0 if top else 2)],rect,false)
static func platform(canvas:CanvasItem,rect:Rect2,variant:int=0) -> void:
	# Preserve each end's proportions; repeat the central stone face at native scale.
	# The walkable lip stays at rect.position.y even when the underside is deeper.
	var textures:Array[Texture2D]=[
		preload("res://world/Arte/Underworld/V94/ledge.tres"),
		preload("res://world/Arte/Underworld/V94/suspended.tres"),
		preload("res://world/Arte/Underworld/V94/rune.tres")]
	var texture:Texture2D=textures[clampi(variant,0,2)]
	var height:=minf(32,rect.size.x*.42)
	var ratio:=height/texture.get_height()
	var cap_source:=80.0
	var cap:=minf(cap_source*ratio,rect.size.x*.35)
	var at:=rect.position-Vector2(0,float(texture.get_meta("walk_top"))*ratio)
	canvas.draw_texture_rect_region(texture,Rect2(at,Vector2(cap,height)),Rect2(0,0,cap_source,texture.get_height()))
	var cursor:=cap
	var index:=0
	var middle:=texture.get_width()-cap_source*2
	while cursor<rect.size.x-cap-.001:
		var source_x:=fposmod(index*96,middle)
		var span:=minf(96,middle-source_x)
		var width:=minf(span*ratio,rect.size.x-cap-cursor)
		canvas.draw_texture_rect_region(texture,Rect2(at+Vector2(cursor,0),Vector2(width,height)),Rect2(cap_source+source_x,0,width/ratio,texture.get_height()))
		cursor+=width;index+=1
	canvas.draw_texture_rect_region(texture,Rect2(at+Vector2(rect.size.x-cap,0),Vector2(cap,height)),Rect2(texture.get_width()-cap_source,0,cap_source,texture.get_height()))

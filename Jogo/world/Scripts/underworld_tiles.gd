extends RefCounted
## Blocos maiores e silhuetas de apoio recortadas nas dimensões reais do atlas.
const TILES=[preload("res://world/Arte/Underworld/V39/terrain_00.tres"),preload("res://world/Arte/Underworld/V39/terrain_01.tres"),preload("res://world/Arte/Underworld/V39/terrain_02.tres"),preload("res://world/Arte/Underworld/V39/terrain_03.tres"),preload("res://world/Arte/Underworld/V39/terrain_04.tres"),preload("res://world/Arte/Underworld/V39/terrain_05.tres"),preload("res://world/Arte/Underworld/V39/terrain_06.tres"),preload("res://world/Arte/Underworld/V39/terrain_07.tres"),preload("res://world/Arte/Underworld/V39/terrain_08.tres"),preload("res://world/Arte/Underworld/V39/terrain_09.tres"),preload("res://world/Arte/Underworld/V39/terrain_10.tres"),preload("res://world/Arte/Underworld/V39/terrain_11.tres"),preload("res://world/Arte/Underworld/V39/terrain_12.tres"),preload("res://world/Arte/Underworld/V39/terrain_13.tres"),preload("res://world/Arte/Underworld/V39/terrain_14.tres"),preload("res://world/Arte/Underworld/V39/terrain_15.tres")]
static func tile(canvas:CanvasItem,rect:Rect2,index:int) -> void:
	canvas.draw_texture_rect(TILES[index],rect,false)
static func platform(canvas:CanvasItem,rect:Rect2) -> void:
	var count:=int(ceilf(rect.size.x/32))
	for i in count:
		var index:=8 if i==0 else (10 if i==count-1 else 9)
		tile(canvas,Rect2(rect.position+Vector2(i*32,0),Vector2(minf(32,rect.size.x-i*32),rect.size.y)),index)

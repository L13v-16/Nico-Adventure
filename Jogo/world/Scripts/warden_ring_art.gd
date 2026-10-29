extends RefCounted
## Atlas originals remain unchanged; native crops provide stable effect anchors.
const FRAMES:Array[Texture2D]=[
	preload("res://world/Arte/Underworld/V53/effects_00.tres"),preload("res://world/Arte/Underworld/V53/effects_01.tres"),
	preload("res://world/Arte/Underworld/V53/effects_02.tres"),preload("res://world/Arte/Underworld/V53/effects_03.tres"),
	preload("res://world/Arte/Underworld/V53/effects_04.tres"),preload("res://world/Arte/Underworld/V53/effects_05.tres"),
	preload("res://world/Arte/Underworld/V53/effects_06.tres"),preload("res://world/Arte/Underworld/V53/effects_07.tres"),
	preload("res://world/Arte/Underworld/V53/effects_08.tres"),preload("res://world/Arte/Underworld/V53/effects_09.tres"),
	preload("res://world/Arte/Underworld/V53/effects_10.tres"),preload("res://world/Arte/Underworld/V53/effects_11.tres"),
	preload("res://world/Arte/Underworld/V53/effects_12.tres"),preload("res://world/Arte/Underworld/V53/effects_13.tres"),
	preload("res://world/Arte/Underworld/V53/effects_14.tres"),preload("res://world/Arte/Underworld/V53/effects_15.tres")]
static func draw_sprite(canvas:CanvasItem,index:int,at:Vector2,width:float,flip:=false,tint:=Color.WHITE) -> void:
	var texture:=FRAMES[index]
	var ratio:=width/float(texture.get_width())
	var pivot:Vector2=texture.get_meta("pivot")
	canvas.draw_set_transform(at.round(),0,Vector2(-1 if flip else 1,1))
	canvas.draw_texture_rect(texture,Rect2(-pivot*ratio,texture.get_size()*ratio),false,tint)
	canvas.draw_set_transform(Vector2.ZERO)

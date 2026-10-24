extends RefCounted
## The gold shield and angular C continue the badge on the corporation's truck.
const GOLD:=Color("dfb65e")
const LIGHT:=Color("ffe7a0")
const INK:=Color("14242c")
static func mark(canvas:CanvasItem,area:Rect2) -> void:
	var outline:=[Vector2(6,2),Vector2(50,2),Vector2(54,6),Vector2(54,39),Vector2(48,49),Vector2(28,63),Vector2(8,49),Vector2(2,39),Vector2(2,6)]
	canvas.draw_colored_polygon(_points(outline,Rect2(area.position+Vector2(2,3),area.size)),Color("080f19"))
	canvas.draw_colored_polygon(_points(outline,area),GOLD)
	canvas.draw_colored_polygon(_points([Vector2(8,7),Vector2(48,7),Vector2(49,10),Vector2(49,37),Vector2(44,45),Vector2(28,56),Vector2(12,45),Vector2(7,37),Vector2(7,10)],area),INK)
	canvas.draw_colored_polygon(_points([Vector2(37,20),Vector2(31,14),Vector2(23,14),Vector2(16,21),Vector2(16,36),Vector2(23,43),Vector2(32,43),Vector2(38,37),Vector2(32,32),Vector2(28,36),Vector2(25,36),Vector2(22,32),Vector2(22,25),Vector2(26,21),Vector2(29,21),Vector2(32,25)],area),LIGHT)
	canvas.draw_rect(_box(area,8,3,40,2),LIGHT)
	canvas.draw_rect(_box(area,3,8,2,28),LIGHT)
	canvas.draw_rect(_box(area,25,49,6,3),GOLD)
static func _points(points:Array,area:Rect2) -> PackedVector2Array:
	var result:=PackedVector2Array()
	for point:Vector2 in points:result.append(area.position+point*area.size/Vector2(56,64))
	return result
static func _box(area:Rect2,x:float,y:float,w:float,h:float) -> Rect2:
	return Rect2(area.position+Vector2(x,y)*area.size/Vector2(56,64),Vector2(w,h)*area.size/Vector2(56,64))

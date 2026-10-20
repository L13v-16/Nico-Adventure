extends RefCounted
## Células de 16 pixels lógicos, sem ler pixels durante a jogabilidade.
const SHEET=preload("res://world/Arte/Underworld/terrain_tiles.png")
static func tile(canvas:CanvasItem,rect:Rect2,index:int) -> void:
	var cell:=SHEET.get_size()/4.0
	var origin:=Vector2(index%4,int(index/4))*cell
	var source:=Rect2(origin,cell)
	# Remove a folga desenhada acima da borda: arte e colisão começam no mesmo Y.
	if index<4:
		source=Rect2(320 if index%2==0 else 640,24,320,296)
	elif index>=12 and index<=14:
		source=Rect2(320,1000,300,220)
	elif index==4:source=Rect2(100,320,220,320)
	elif index==7:source=Rect2(960,320,240,320)
	canvas.draw_texture_rect_region(SHEET,rect,source)
static func platform(canvas:CanvasItem,rect:Rect2) -> void:
	var count:=int(ceilf(rect.size.x/16))
	for i in count:
		var index:=12 if i==0 else (14 if i==count-1 else 13)
		tile(canvas,Rect2(rect.position+Vector2(i*16,0),Vector2(minf(16,rect.size.x-i*16),rect.size.y)),index)

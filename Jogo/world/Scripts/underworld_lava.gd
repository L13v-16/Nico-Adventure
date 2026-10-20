extends RefCounted
## Lava desenhada com os atlas animados, recortada ao trecho visível da câmera.
const FRAMES=preload("res://world/Arte/Underworld/V35/lava.tres")
static func texture(animation:StringName,index:int) -> Texture2D:
	return FRAMES.get_frame_texture(animation,index%FRAMES.get_frame_count(animation))
static func draw_pool(canvas:CanvasItem,rect:Rect2,clock:float) -> void:
	var view:Rect2=canvas.get_global_transform_with_canvas().affine_inverse()*canvas.get_viewport_rect()
	var visible:=rect.intersection(view.grow(28))
	if not visible.has_area():return
	var tick:=int(clock*6)
	var body_tick:=int(clock*2)
	var first_x:=maxi(0,int(floorf((visible.position.x-rect.position.x)/64)))
	var last_x:=mini(int(ceilf(rect.size.x/64)),int(ceilf((visible.end.x-rect.position.x)/64)))
	var first_y:=maxi(0,int(floorf((visible.position.y-rect.position.y)/64)))
	var last_y:=mini(int(ceilf(rect.size.y/64)),int(ceilf((visible.end.y-rect.position.y)/64)))
	for x in range(first_x,last_x):
		for y in range(first_y,last_y):
			var at:=rect.position+Vector2(x*64,y*64)
			var size:=Vector2(minf(64,rect.end.x-at.x),minf(64,rect.end.y-at.y))
			canvas.draw_texture_rect(texture(&"body",body_tick+x+y*2),Rect2(at,size),false,Color("dec9bd"))
		canvas.draw_texture_rect(texture(&"surface",tick),Rect2(rect.position+Vector2(x*64,0),Vector2(minf(64,rect.size.x-x*64),22)),false)
	for i in range(maxi(0,int((visible.position.x-rect.position.x)/96)),int(ceilf((visible.end.x-rect.position.x)/96))):
		var t:=fposmod(clock*0.55+i*0.37,1)
		if t<0.52:
			var at:=rect.position+Vector2(i*96+23,-7)
			if at.x+14<rect.end.x:canvas.draw_texture_rect(texture(&"bubble",int(t*8)),Rect2(at,Vector2(14,12)),false)

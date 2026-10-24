extends RefCounted
const KIT := preload("res://world/Arte/CorpV86/industrial.png")
const WOLF := preload("res://world/Arte/CorpV86/wolf_combat.png")
const REGIONS := [Rect2(23,188,414,120),Rect2(500,170,255,143),Rect2(820,170,254,145),Rect2(1156,61,240,264),Rect2(22,572,432,117),Rect2(505,570,277,121),Rect2(815,570,265,120),Rect2(1128,350,280,362),Rect2(45,758,187,274),Rect2(257,784,394,247),Rect2(665,835,430,163),Rect2(1103,765,330,274)]
const WOLF_REGIONS := [Rect2(46,144,253,365),Rect2(399,180,338,334),Rect2(788,180,333,334),Rect2(1202,112,306,400),Rect2(22,610,393,346),Rect2(418,600,420,360),Rect2(844,603,292,357),Rect2(1180,597,334,368)]
const WOLF_CENTERS := [194,570,978,1360,210,575,995,1365]
const WOLF_FEET := [502,506,506,502,946,946,951,951]
static var cache: Dictionary = {}
static func cell(index: int) -> AtlasTexture:
	if cache.has(index):return cache[index]
	var box: Rect2 = REGIONS[index];var image:=KIT.get_image()
	var left:=int(box.end.x);var top:=int(box.end.y);var right:=int(box.position.x);var bottom:=int(box.position.y)
	for y in range(int(box.position.y),int(box.end.y)):
		for x in range(int(box.position.x),int(box.end.x)):
			if image.get_pixel(x,y).a>.8:left=mini(left,x);right=maxi(right,x);top=mini(top,y);bottom=maxi(bottom,y)
	var result:=AtlasTexture.new();result.atlas=KIT;result.region=Rect2(left,top,right-left+1,bottom-top+1);result.filter_clip=true
	cache[index]=result;return result
static func wolf_frames() -> SpriteFrames:
	if cache.has("wolf"):return cache.wolf
	var frames:=SpriteFrames.new();frames.remove_animation("default")
	for animation in ["idle","run","windup","dash","throw","hurt","board"]:
		frames.add_animation(animation);frames.set_animation_speed(animation,8 if animation=="run" else 5);frames.set_animation_loop(animation,animation in ["idle","run"])
		var indices:Array={"idle":[0],"run":[1,2],"windup":[3],"dash":[4],"throw":[5],"hurt":[6],"board":[7]}[animation]
		for index:int in indices:
			var texture:=AtlasTexture.new();texture.atlas=WOLF;texture.region=WOLF_REGIONS[index];texture.filter_clip=true
			texture.margin=Rect2(Vector2(240-(WOLF_CENTERS[index]-texture.region.position.x),480-(WOLF_FEET[index]-texture.region.position.y)),Vector2(480,512)-texture.region.size)
			frames.add_frame(animation,texture)
	cache.wolf=frames;return frames
static func deck(canvas:CanvasItem,width:float,height:float=28.0,conveyor:bool=false,reverse:bool=false) -> void:
	var center:Texture2D=cell(4 if conveyor else 0);var left:Texture2D=cell(5 if conveyor else 1);var right:Texture2D=cell(6 if conveyor else 2)
	var factor:=height/center.get_height();var cap:=14.0;var crop:=Rect2(55,0,center.get_width()-110,center.get_height());var tile_width:=crop.size.x*factor
	var x:=cap
	if conveyor and reverse:canvas.draw_set_transform(Vector2(width,0),0,Vector2(-1,1))
	while x<width-cap:
		var w:=minf(tile_width,width-cap-x);canvas.draw_texture_rect_region(center,Rect2(x,0,w,height),Rect2(crop.position,Vector2(w/factor,crop.size.y)));x+=w
	canvas.draw_set_transform(Vector2.ZERO)
	var overhang:=0.0 if conveyor else 4.0
	canvas.draw_texture_rect_region(left,Rect2(0,-overhang,cap,height+overhang),Rect2(0,0,50,left.get_height()))
	canvas.draw_texture_rect_region(right,Rect2(width-cap,-overhang,cap,height+overhang),Rect2(right.get_width()-50,0,50,right.get_height()))
static func press(canvas:CanvasItem,width:float,extension:float,tint:Color=Color.WHITE) -> void:
	var texture:=cell(7);var ratio:=width/texture.get_width();var height:=texture.get_height()*ratio;var origin:=Vector2(-width*.5,-height)
	canvas.draw_texture_rect(texture,Rect2(origin,Vector2(width,height)),false,tint)
	# Fixed uprights; only the silver piston and striking plate extend.
	canvas.draw_rect(Rect2(origin+Vector2(width*.25,height*.26),Vector2(width*.50,height*.56)),Color("111824"))
	var ram_y:=origin.y+height*(.48+extension*.24)
	canvas.draw_texture_rect_region(texture,Rect2(-width*.075,origin.y+height*.25,width*.15,ram_y-origin.y-height*.25),Rect2(texture.get_width()*.45,texture.get_height()*.29,texture.get_width()*.12,texture.get_height()*.24),tint)
	canvas.draw_texture_rect_region(texture,Rect2(-width*.25,ram_y,width*.50,height*.13),Rect2(texture.get_width()*.25,texture.get_height()*.55,texture.get_width()*.50,texture.get_height()*.13),tint)

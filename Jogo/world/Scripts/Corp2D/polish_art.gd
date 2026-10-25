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
	# Same 112x96 wolf used in the opening kidnapping, with a golden badge.
	var original:=preload("res://world/Arte/Corporacao/V22/wolf_motion_v22.tres")
	var frames:=SpriteFrames.new();frames.remove_animation("default")
	for action in ["idle","run","windup","dash","throw","hurt","board"]:
		var source:StringName={"idle":"idle","run":"walk","windup":"command","dash":"walk","throw":"reach","hurt":"lift","board":"pickup"}[action]
		frames.add_animation(action);frames.set_animation_loop(action,action in ["idle","run","dash"]);frames.set_animation_speed(action,10 if action in ["run","dash"] else 5)
		for i in original.get_frame_count(source):frames.add_frame(action,original.get_frame_texture(source,i))
	var extra:=preload("res://world/Scripts/polish99_art.gd")
	for entry in [["windup",[0],5,false],["dash",[1,2],11,true],["brake",[3],6,false],["throw",[4,5],9,false],["recover",[6],4,false],["hurt",[7],5,false]]:
		extra.append(frames,"wolf",entry[0],entry[1],entry[2],entry[3])
	frames.set_meta("mixed_wolf99",true)
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
static func steel_post(canvas:CanvasItem,box:Rect2,tint:Color=Color.WHITE) -> void:
	# Sample the vertical upright, excluding the red deck and horizontal rails.
	var tile:Texture2D=cell(1)
	var step:=box.size.x*44.0/30.0
	var y:=box.position.y
	while y<box.end.y:
		var h:=minf(step,box.end.y-y)
		canvas.draw_texture_rect_region(tile,Rect2(box.position.x,y,box.size.x,h),Rect2(8,38,30,44*h/step),tint)
		y+=h
static func wall_mount(canvas:CanvasItem,width:float) -> void:
	steel_post(canvas,Rect2(width*.36,-27,12,34),Color("a5afba"))
	canvas.draw_rect(Rect2(width*.17,-8,width*.33,6),Color("111923"))
	canvas.draw_rect(Rect2(width*.17,-8,width*.33,2),Color("9ba6b2"))
static func wall_brackets(canvas:CanvasItem,width:float) -> void:
	for x in [18.0,width-26.0]:
		steel_post(canvas,Rect2(x,27,8,23),Color("687483"))
		canvas.draw_set_transform(Vector2(x-11,28),-PI/4)
		steel_post(canvas,Rect2(0,0,5,25),Color("9aa6b4"))
		canvas.draw_set_transform(Vector2.ZERO)

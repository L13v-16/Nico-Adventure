extends RefCounted
## Atlases remain unmodified; crop and anchor by opaque bounds at runtime.
const ROOT := "res://world/Arte/CorpV82/"
static var _cache:Dictionary={}
static func cell(sheet:String,index:int,columns:int=4) -> AtlasTexture:
	var key:=sheet+str(index)
	if _cache.has(key):return _cache[key]
	var source:Texture2D=load(ROOT+sheet+".png")
	var size:=float(source.get_width())/columns
	var region:=Rect2((index%columns)*size,(index/columns)*size,size,size)
	# Generated rows have unequal padding. Explicit regions keep neighboring
	# props out of the frame and put each object's actual base on the floor.
	if sheet=="props":
		var boxes:=[Rect2(5,145,308,125),Rect2(322,155,310,115),Rect2(640,115,312,155),Rect2(955,45,290,225),Rect2(38,290,245,280),Rect2(357,290,235,280),Rect2(680,360,195,202),Rect2(1030,360,195,202),Rect2(30,605,274,260),Rect2(354,625,234,250),Rect2(637,575,310,305),Rect2(950,575,294,305),Rect2(60,892,210,325),Rect2(325,895,306,322),Rect2(679,935,236,282),Rect2(950,905,300,313)]
		region=boxes[index]
		region.position*=float(source.get_width())/1280;region.size*=float(source.get_width())/1280
	elif sheet=="actors":
		var row:=index/4
		var tops:=[40,360,590,955];var heights:=[275,225,325,275]
		region=Rect2((index%4)*size,tops[row],size,heights[row])
		region.position.y*=float(source.get_height())/1280;region.size.y*=float(source.get_height())/1280
	var image:=source.get_image()
	var left:=int(region.end.x);var right:=int(region.position.x);var top:=int(region.end.y);var bottom:=int(region.position.y)
	for y in range(int(region.position.y),int(region.end.y)):
		for x in range(int(region.position.x),int(region.end.x)):
			if image.get_pixel(x,y).a>.8:
				left=mini(left,x);right=maxi(right,x);top=mini(top,y);bottom=maxi(bottom,y)
	var texture:=AtlasTexture.new();texture.atlas=source;texture.region=Rect2(left,top,right-left+1,bottom-top+1);texture.filter_clip=true
	_cache[key]=texture;return texture
static func sprite(sheet:String,index:int,width:float,columns:int=4) -> Sprite2D:
	var node:=Sprite2D.new();node.texture=cell(sheet,index,columns);node.centered=false
	node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var ratio:=width/node.texture.get_width();node.scale=Vector2.ONE*ratio
	node.position=Vector2(-width/2,-node.texture.get_height()*ratio);return node
static func enemy_frames(row:int) -> SpriteFrames:
	var frames:=SpriteFrames.new();frames.remove_animation("default")
	for animation in ["walk","warning","attack","recovery","hurt"]:
		frames.add_animation(animation);frames.set_animation_speed(animation,5);frames.set_animation_loop(animation,animation=="walk")
		var indices:Array=[0,1] if animation=="walk" else ([2] if animation=="warning" else ([3] if animation=="attack" else [0]))
		for index in indices:frames.add_frame(animation,cell("actors",row*4+int(index)))
	return frames

extends RefCounted
## Native atlas regions; generated PNGs are preserved without raster edits.
const META=preload("res://world/Arte/GeneralV90/atlases.tres")
static var _cache:Dictionary={}
static func cell(sheet:String,index:int,padded:bool=false) -> AtlasTexture:
	var key:=sheet+str(index)+str(padded)
	if _cache.has(key):return _cache[key]
	var info:Dictionary=META.get_meta("sheets")[sheet]
	var frame:Dictionary=info.frames[index];var r:Array=frame.rect
	var tex:=AtlasTexture.new();tex.atlas=load("res://world/Arte/GeneralV90/"+sheet+".png");tex.region=Rect2(r[0],r[1],r[2],r[3]);tex.filter_clip=true
	if padded:
		tex.margin=Rect2(frame.offset[0],frame.offset[1],info.canvas[0]-r[2],info.canvas[1]-r[3]);tex.set_meta("ground_foot",float(frame.foot))
	_cache[key]=tex;return tex
static func material() -> ShaderMaterial:return preload("res://world/Scripts/magic_art.gd").material()
static func extend_enemy(sprite:AnimatedSprite2D,species:int) -> void:
	# Each species keeps its old world size. One fixed scale is shared by all
	# new poses, so a collapsed character becomes shorter, never inflated.
	var frames:SpriteFrames=sprite.sprite_frames
	var height:=frames.get_frame_texture("walk",0).get_height()
	var reference:=cell("enemies",species*4).region.size.y
	sprite.set_meta("general_base_scale",sprite.scale)
	sprite.set_meta("general_pose_ratio",float(height)/reference)
	for i in 4:
		var action:String=["warning","recovery","hurt","defeated"][i]
		if frames.has_animation(action):frames.remove_animation(action)
		frames.add_animation(action);frames.set_animation_loop(action,false)
		frames.add_frame(action,cell("enemies",species*4+i,true))
	sprite.material=material()
static func anchor_enemy(sprite:AnimatedSprite2D) -> void:
	var base:Vector2=sprite.get_meta("general_base_scale",sprite.scale)
	var custom:=sprite.animation in [&"warning",&"recovery",&"hurt",&"defeated"]
	sprite.scale=base*(float(sprite.get_meta("general_pose_ratio",1.0)) if custom else 1.0)
	var tex:Texture2D=sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	var foot:=float(tex.get_meta("ground_foot",tex.get_height()))
	sprite.position=Vector2(-tex.get_width()*sprite.scale.x/2,-foot*sprite.scale.y)

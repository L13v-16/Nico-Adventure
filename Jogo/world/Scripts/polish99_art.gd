extends RefCounted
## Original generated PNGs remain untouched. Opaque crops discard faint matte.
const ROOT:="res://world/Arte/PolishV99/"
static var cache:Dictionary={}
static func cell(sheet:String,index:int,padded:bool=false) -> AtlasTexture:
	var key:=sheet+str(index)+str(padded)
	if cache.has(key):return cache[key]
	var source:Texture2D=load(ROOT+sheet+".png")
	var data:Dictionary=preload("res://world/Arte/PolishV99/atlases.tres").get_meta("sheets")[sheet]
	var info:Dictionary=data.frames[index];var r:Array=info.rect
	var texture:=AtlasTexture.new();texture.atlas=source;texture.region=Rect2(r[0],r[1],r[2],r[3]);texture.filter_clip=true
	if padded:texture.margin=Rect2(info.offset[0],info.offset[1],data.canvas[0]-r[2],data.canvas[1]-r[3])
	texture.set_meta("ground_foot",float(info.foot) if padded else float(r[3]))
	texture.set_meta("ink_height",float(info.ink_height));cache[key]=texture;return texture

static func append(frames:SpriteFrames,sheet:String,action:StringName,indices:Array,speed:float=7,loop:bool=false) -> void:
	if frames.has_animation(action):frames.remove_animation(action)
	frames.add_animation(action);frames.set_animation_speed(action,speed);frames.set_animation_loop(action,loop)
	for index in indices:frames.add_frame(action,cell(sheet,index,true))
static func material() -> ShaderMaterial:
	var mat:=preload("res://world/Scripts/magic_art.gd").material();mat.set_shader_parameter("alpha_cutoff",.94);return mat
static func attach_wolf(sprite:AnimatedSprite2D,width:float) -> void:
	if not sprite.sprite_frames.get_meta("mixed_wolf99",false):return
	var anchor:=func():
		var texture:Texture2D=sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
		var new_pose:bool=texture is AtlasTexture and texture.atlas.resource_path.contains("PolishV99")
		sprite.scale=Vector2.ONE*((width*.78/float(cell("wolf",1,true).get_meta("ink_height"))) if new_pose else width/112.0)
		preload("res://world/Scripts/magic_art.gd").reanchor(sprite)
	sprite.material=material();sprite.animation_changed.connect(anchor);sprite.frame_changed.connect(anchor);anchor.call()

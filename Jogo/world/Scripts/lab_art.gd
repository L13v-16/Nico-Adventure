extends RefCounted
const ROOT:="res://world/Arte/Lab/V68/"
const Art=preload("res://world/Scripts/magic_art.gd")
static func texture(name:String) -> Texture2D:return load(ROOT+name+".tres")
static func actor(name:String,width:float) -> AnimatedSprite2D:
	var sprite:=Art.actor(load(ROOT+name+".tres"),width)
	var ink:=ShaderMaterial.new();ink.shader=preload("res://world/Scripts/lab_cutout.gdshader");sprite.material=ink
	sprite.frame_changed.connect(_sync_clip.bind(sprite));sprite.animation_changed.connect(_sync_clip.bind(sprite))
	_sync_clip(sprite);Art.reanchor(sprite);return sprite
static func _sync_clip(sprite:AnimatedSprite2D) -> void:
	var frame:Texture2D=sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	if frame!=null:sprite.material.set_shader_parameter("native_clip_box",frame.get_meta("native_clip_box",Vector4.ZERO))
static func prop(name:String,width:float,surface:bool=false) -> Sprite2D:
	var sprite:=Sprite2D.new();sprite.texture=texture(name);sprite.centered=false
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.material=Art.material();sprite.material.set_shader_parameter("alpha_cutoff",.94)
	var ratio:=width/sprite.texture.get_width();sprite.scale=Vector2.ONE*ratio
	var foot:float=3 if surface else float(sprite.texture.get_meta("ground_foot",sprite.texture.get_height()))
	sprite.position=Vector2(-width/2,-foot*ratio);return sprite

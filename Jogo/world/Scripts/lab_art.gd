extends RefCounted
const ROOT:="res://world/Arte/Lab/V68/"
const Art=preload("res://world/Scripts/magic_art.gd")
static func texture(name:String) -> Texture2D:
	return load("res://world/Arte/Lab/V69/device_%s.tres"%name.trim_prefix("state_")) if name.begins_with("state_") else load(ROOT+name+".tres")
static func enemy_frames(species:String) -> SpriteFrames:
	var frames:SpriteFrames=load(ROOT+species+".tres").duplicate()
	var row:int={"specimen":0,"drone":1,"technician":2,"lizard":3}[species]
	var actions:Dictionary={"warning":[0,1],"attack":[2,3],"recovery":[4],"hurt":[5]}
	if species=="drone":actions.warning=[1,2];actions.attack=[3]
	elif species=="technician":actions.warning=[0,1,2];actions.attack=[3]
	elif species=="lizard":actions.attack=[2,3,4];actions.recovery=[4]
	for animation in actions:
		if frames.has_animation(animation):frames.remove_animation(animation)
		frames.add_animation(animation);frames.set_animation_loop(animation,false);frames.set_animation_speed(animation,4 if animation=="warning" else 10)
		for index in actions[animation]:frames.add_frame(animation,load("res://world/Arte/Lab/V69/action_%02d.tres"%(row*6+int(index))))
	return frames
static func actor(name:String,width:float) -> AnimatedSprite2D:
	var sprite:=Art.actor(load(ROOT+name+".tres"),width)
	var ink:=ShaderMaterial.new();ink.shader=preload("res://world/Scripts/lab_cutout.gdshader");sprite.material=ink
	sprite.frame_changed.connect(_sync_clip.bind(sprite));sprite.animation_changed.connect(_sync_clip.bind(sprite))
	_sync_clip(sprite);Art.reanchor(sprite);return sprite
static func _sync_clip(sprite:AnimatedSprite2D) -> void:
	if sprite.sprite_frames==null or not sprite.sprite_frames.has_animation(sprite.animation):return
	var frame:Texture2D=sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	if frame!=null:
		sprite.material.set_shader_parameter("native_clip_box",frame.get_meta("native_clip_box",Vector4.ZERO))
		var clips:PackedVector4Array=frame.get_meta("native_clips",PackedVector4Array())
		sprite.material.set_shader_parameter("clip_count",clips.size());clips.resize(32);sprite.material.set_shader_parameter("clip_boxes",clips)
static func prop(name:String,width:float,surface:bool=false) -> Sprite2D:
	var sprite:=Sprite2D.new();sprite.texture=texture(name);sprite.centered=false
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.material=Art.material();sprite.material.set_shader_parameter("alpha_cutoff",.94)
	var ratio:=width/sprite.texture.get_width();sprite.scale=Vector2.ONE*ratio
	var foot:float=3 if surface else float(sprite.texture.get_meta("ground_foot",sprite.texture.get_height()))
	sprite.position=Vector2(-width/2,-foot*ratio);return sprite

extends RefCounted
## Additive decorative clips. The original shared SpriteFrames stay untouched.
const ATLAS=preload("res://world/Arte/Friends/V89/atlases.tres")
const Art=preload("res://world/Scripts/magic_art.gd")
const SHEETS={
	"nico":preload("res://world/Arte/Friends/V89/nico.png"),
	"arara":preload("res://world/Arte/Friends/V89/arara.png"),
	"turtle":preload("res://world/Arte/Friends/V89/turtle.png"),
	"oliver":preload("res://world/Arte/Friends/V89/oliver.png"),
	"jose":preload("res://world/Arte/Friends/V89/jose.png"),
	"urso":preload("res://world/Arte/Friends/V89/urso.png"),
	"remi":preload("res://world/Arte/Friends/V89/remi.png"),
	"mico":preload("res://world/Arte/Friends/V89/mico.png")
}

static func install(sprite:AnimatedSprite2D,id:String) -> void:
	var data:Dictionary=ATLAS.get_meta("actors")[id]
	var frames:=sprite.sprite_frames.duplicate() as SpriteFrames
	sprite.set_meta("ambient_base_scale",sprite.scale)
	sprite.set_meta("ambient_scale_factor",float(data.base_height)/float(data.height))
	for index in data.actions.size():
		var animation:StringName=StringName("ambient_"+str(data.actions[index]))
		frames.add_animation(animation);frames.set_animation_speed(animation,4);frames.set_animation_loop(animation,false)
		for pose in 2:
			var info:Dictionary=data.frames[index*2+pose]
			var rect:Array=info.rect;var texture:=AtlasTexture.new()
			texture.atlas=SHEETS[id];texture.region=Rect2(rect[0],rect[1],rect[2],rect[3]);texture.filter_clip=true
			texture.margin=Rect2(Vector2(info.offset[0],info.offset[1]),Vector2(data.canvas[0]-rect[2],data.canvas[1]-rect[3]))
			texture.set_meta("ground_foot",float(info.foot))
			frames.add_frame(animation,texture)
	sprite.sprite_frames=frames

static func display(sprite:AnimatedSprite2D,animation:StringName,elapsed:float) -> void:
	var base:Vector2=sprite.get_meta("ambient_base_scale")
	var special:=str(animation).begins_with("ambient_")
	sprite.scale=base*float(sprite.get_meta("ambient_scale_factor")) if special else base
	if special:
		sprite.animation=animation
		# Throws and catches have a real preparation/release beat, never a rapid loop.
		var one_shot:=animation in [&"ambient_throw",&"ambient_catch"]
		var frame:=clampi(int(elapsed/.6),0,1) if one_shot else int(maxf(0,elapsed)*3)%2
		sprite.set_frame_and_progress(frame,0);sprite.pause()
	else:sprite.play(animation)
	Art.reanchor(sprite)

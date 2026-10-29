extends RefCounted
## Os atlas originais são preservados; recortes nativos mantêm os pés no apoio.
const Base = preload("res://world/Scripts/magic_art.gd")
const ROOT := "res://world/Arte/Underworld/"
static func actor(sheet: String, width: float) -> AnimatedSprite2D:
	var frames:SpriteFrames=load(ROOT+sheet+".tres")
	var sprite:=Base.actor(frames,width)
	sprite.material.set_shader_parameter("alpha_cutoff",0.94)
	Base.reanchor(sprite)
	return sprite
static func prop(index: int, size: Vector2, at: Vector2=Vector2.ZERO) -> Sprite2D:
	var sprite:=Sprite2D.new()
	sprite.texture=load(ROOT+"prop_%02d.tres"%index)
	sprite.centered=false
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.material=Base.material()
	sprite.material.set_shader_parameter("alpha_cutoff",0.94)
	sprite.scale=size/sprite.texture.get_size()
	sprite.position=at
	return sprite

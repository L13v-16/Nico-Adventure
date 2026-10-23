extends AnimatedSprite2D
## Original V72 PNG atlases, with surface anchors independent of bubbles/glints.
var style:="poison"
var drawn_width:=100.0
var _life:=0.0
static var _frames:Dictionary={}
const ROWS:={"poison":0,"ice":1,"freeze":2,"splash":3}
func _ready() -> void:
	add_to_group("lab_effects")
	centered=false;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;z_index=2
	material=preload("res://world/Scripts/magic_art.gd").material();material.set_shader_parameter("alpha_cutoff",.94)
	frame_changed.connect(_anchor);set_style(style)
func set_style(value:String) -> void:
	style=value
	if not _frames.has(style):
		var sheet:=SpriteFrames.new();sheet.remove_animation(&"default");sheet.add_animation(&"effect")
		sheet.set_animation_speed(&"effect",7 if style in ["poison","ice"] else 10)
		sheet.set_animation_loop(&"effect",style in ["poison","ice"])
		for i in 4:sheet.add_frame(&"effect",load("res://world/Arte/Lab/V72/effect_%02d.tres"%(int(ROWS[style])*4+i)))
		_frames[style]=sheet
	sprite_frames=_frames[style];play(&"effect");_anchor()
func _anchor() -> void:
	if sprite_frames==null:return
	var tex:Texture2D=sprite_frames.get_frame_texture(&"effect",frame)
	var ratio:=drawn_width/float(tex.get_meta("visible_width",300))
	scale=Vector2.ONE*ratio
	position=Vector2(-tex.get_width()*.5*ratio,-float(tex.get_meta("surface_y",tex.get_height()*.5))*ratio)
func _process(delta:float) -> void:
	if style not in ["poison","ice"]:
		_life+=delta
		if _life>.45:get_parent().queue_free()

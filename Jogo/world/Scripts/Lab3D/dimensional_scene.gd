extends Node2D
## Original pixel-art actors bookend the 3D chapter.
const Art=preload("res://world/Scripts/lab_art.gd")
var arrival:Node2D
var nico:AnimatedSprite2D
var urso:AnimatedSprite2D
var ending:=false
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var prefab:Node=load("res://prefabs/nico.tscn").instantiate()
	var frames:SpriteFrames=prefab.get_node("anim").sprite_frames;prefab.free()
	if not ending:
		arrival=load("res://world/Scripts/lab_arrival_scene.gd").new();arrival.player_frames=frames;add_child(arrival)
	else:
		var sky:=Sprite2D.new();sky.texture=load("res://world/Arte/Beach/beach_background.png");sky.centered=false;sky.scale=Vector2(640.0/sky.texture.get_width(),247.0/sky.texture.get_height());sky.modulate=Color("b4c2d0");add_child(sky)
		for x in range(0,640,80):
			var floor_art:=Art.prop("floor_00",82,true);floor_art.position+=Vector2(x+40,247);add_child(floor_art)
		nico=Art.Art.actor(frames,55);add_child(nico)
		var bear:=SpriteFrames.new();bear.remove_animation("default");bear.add_animation("idle");bear.set_animation_speed("idle",3)
		for i in 2:bear.add_frame("idle",load("res://world/Arte/Friends/V47/urso_body_%02d.tres"%i))
		urso=Art.Art.actor(bear,67);urso.flip_h=true;add_child(urso)
		queue_redraw()
func update_scene(time:float) -> void:
	if arrival!=null:arrival.update_scene(minf(6.9,time*5.65/5.3))
	elif nico!=null:
		nico.position=Vector2(lerpf(230,275,smoothstep(.6,2.5,time)),247)+nico.get_meta("ground_art_offset",Vector2.ZERO);urso.position=Vector2(390,247)+urso.get_meta("ground_art_offset",Vector2.ZERO)
		var animation:StringName=&"run" if time<2.5 and nico.sprite_frames.has_animation("run") else &"idle"
		if not nico.sprite_frames.has_animation(animation):animation=nico.sprite_frames.get_animation_names()[0]
		nico.animation=animation;nico.frame=int(time*8)%nico.sprite_frames.get_frame_count(animation);nico.pause();Art.Art.reanchor(nico)
		urso.animation="idle";urso.frame=int(time*3)%2;urso.pause();Art.Art.reanchor(urso)
func _draw() -> void:
	if not ending:return
	draw_rect(Rect2(0,247,640,113),Color("304550"))
	for x in range(0,640,32):draw_rect(Rect2(x,251,30,8),Color("829ba2"))
	for x in [30,90,550,610]:
		draw_rect(Rect2(x,183,4,64),Color("d4d3b6"));draw_rect(Rect2(x-12,182,28,5),Color("e3bb6f"))
	draw_rect(Rect2(0,197,175,4),Color("738f9c"));draw_rect(Rect2(465,197,175,4),Color("738f9c"))

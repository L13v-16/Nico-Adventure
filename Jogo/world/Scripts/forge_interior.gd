extends Node2D
## An independent workshop room, separated vertically from the outdoor map.
const WALL=preload("res://world/Arte/Underworld/V65/forge_room.png")
const FLOOR:Array[Texture2D]=[
	preload("res://world/Arte/Underworld/V65/floor_00.tres"),
	preload("res://world/Arte/Underworld/V65/floor_01.tres"),
	preload("res://world/Arte/Underworld/V65/floor_02.tres"),
	preload("res://world/Arte/Underworld/V65/floor_03.tres")]
var camera:Camera2D
var _player:CharacterBody2D
var _exit:StaticBody2D
var _exit_open:=false
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_player=get_tree().get_first_node_in_group("player")
	camera=Camera2D.new();camera.name="WorkshopCamera";camera.enabled=false
	camera.zoom=Vector2.ONE*1.25;camera.position_smoothing_enabled=false
	camera.limit_smoothed=false;add_child(camera)
	var wall:=Sprite2D.new();wall.name="WorkshopWall";wall.texture=WALL
	wall.centered=false;wall.scale=Vector2.ONE*.5;wall.position=Vector2(-384,-338)
	wall.z_index=-4;add_child(wall)
	_body("Floor",Vector2(0,96),Vector2(768,192))
	_body("LeftWall",Vector2(-384,-200),Vector2(24,400))
	_body("RightWall",Vector2(384,-200),Vector2(24,400))
	_body("Ceiling",Vector2(0,-360),Vector2(768,20))
	_exit=_body("ExitGate",Vector2(334,-45),Vector2(14,90))
	var art:=Node2D.new();art.name="NewFloor";art.z_index=-1;add_child(art)
	art.material=preload("res://world/Scripts/magic_art.gd").material()
	art.material.set_shader_parameter("alpha_cutoff",.94)
	art.draw.connect(func():
		art.draw_rect(Rect2(-384,0,768,192),Color("14121e"))
		for x in 12:
			for y in 5:
				var tile:Texture2D=FLOOR[(x+y)%4]
				var ratio:=64.0/(tile.get_width()-6)
				art.draw_texture_rect(tile,Rect2(Vector2(-384+x*64-3*ratio,y*38-3*ratio),tile.get_size()*ratio),false))
	_prop("anvil",Vector2(-220,0),54)
	_prop("tools",Vector2(240,0),68)
	_prop("ingots",Vector2(190,0),74)
	_prop("column",Vector2(-362,0),34)
	_prop("column",Vector2(362,0),34)
func _body(label:String,at:Vector2,size:Vector2) -> StaticBody2D:
	var body:=StaticBody2D.new();body.name=label;body.position=at
	body.collision_layer=1;body.collision_mask=0
	var collider:=CollisionShape2D.new();var shape:=RectangleShape2D.new();shape.size=size
	collider.shape=shape;body.add_child(collider);add_child(body);return body
func _prop(label:String,at:Vector2,width:float) -> void:
	var texture:Texture2D=load("res://world/Arte/Underworld/V65/"+label+".tres")
	var sprite:=Sprite2D.new();sprite.name=label.capitalize();sprite.texture=texture;sprite.centered=false
	var ratio:=width/texture.get_width();sprite.scale=Vector2.ONE*ratio
	sprite.position=at+Vector2(-width*.5,-float(texture.get_meta("ground_foot"))*ratio)
	sprite.z_index=-2;sprite.material=preload("res://world/Scripts/magic_art.gd").material()
	sprite.material.set_shader_parameter("alpha_cutoff",.94);add_child(sprite)
func set_exit_open(value:bool) -> void:
	if not is_instance_valid(_exit) or _exit_open==value:return
	_exit_open=value;_exit.set_deferred("collision_layer",0 if value else 1)

func set_active(value:bool) -> void:
	camera.enabled=value
	if value:
		camera.limit_left=int(global_position.x-384);camera.limit_right=int(global_position.x+384)
		camera.limit_top=int(global_position.y-400);camera.limit_bottom=int(global_position.y+100)
		_follow_camera();camera.make_current();camera.reset_smoothing();camera.force_update_scroll()
func _follow_camera() -> void:
	camera.position=Vector2(clampf(_player.global_position.x-global_position.x+30,-115,115),-70)
func _process(_delta:float) -> void:
	if visible and camera.enabled:_follow_camera()

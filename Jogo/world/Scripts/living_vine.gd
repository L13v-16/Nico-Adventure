extends Node2D
## Pêndulo com impulso do jogador e velocidade tangencial ao soltar.
@export var length := 194.0
@export var automatic_travel := 0.0
@export var phase := -1.57
@export var plant_offset := Vector2.ZERO
var angle := -0.85
var angular_velocity := 0.0
var rider: CharacterBody2D
var shifted := false
var _home := Vector2.ZERO
var _shift := Vector2.ZERO
var _clock := 0.0
var _anchor_velocity := Vector2.ZERO
var _held := false
var _hint: Label
var _art: Node2D
var _cherries: Array[Dictionary] = []
const SEGMENTS := [preload("res://world/Arte/Magic/V26/vine_segment_0.tres"),preload("res://world/Arte/Magic/V26/vine_segment_1.tres"),preload("res://world/Arte/Magic/V26/vine_segment_2.tres"),preload("res://world/Arte/Magic/V26/vine_segment_3.tres")]
const ANCHOR := preload("res://world/Arte/Magic/V26/vine_anchor.tres")
const GRIP := preload("res://world/Arte/Magic/V26/vine_grip.tres")

func _ready() -> void:
	add_to_group("living_vines")
	process_physics_priority = -10
	_home = position
	_art=Node2D.new()
	_art.material=preload("res://world/Scripts/magic_art.gd").material()
	_art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_art.draw.connect(_paint)
	add_child(_art)
	_hint = Label.new()
	_hint.text = "E  agarrar"
	_hint.add_theme_font_size_override("font_size",9)
	_hint.add_theme_color_override("font_color",Color("c4fff0"))
	_hint.add_theme_color_override("font_shadow_color",Color("201638"))
	_hint.add_theme_constant_override("shadow_offset_x",1)
	_hint.add_theme_constant_override("shadow_offset_y",1)
	add_child(_hint)

func _physics_process(delta: float) -> void:
	_clock += delta
	var old := position
	_shift = _shift.move_toward(plant_offset if shifted else Vector2.ZERO,120*delta)
	position = _home + _shift + Vector2(sin(_clock*0.65+phase)*automatic_travel,0)
	_anchor_velocity = (position-old)/maxf(delta,0.001)
	if not is_instance_valid(rider):
		rider = null
		var previous := angle
		angle = sin(_clock*1.15+phase)*0.85
		angular_velocity = (angle-previous)/maxf(delta,0.001)
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	var near: bool = is_instance_valid(player) and not player.is_dead() and player.global_position.distance_to(get_grip()+Vector2(0,10))<48
	_hint.visible = near and rider == null
	_hint.position = to_local(get_grip())+Vector2(-22,14)
	var held := Input.is_physical_key_pressed(KEY_E)
	if near and rider == null and held and not _held and player.can_grab_vine():
		if player.grab_vine(self):
			rider = player
			angular_velocity = clampf(angular_velocity+player.velocity.x/length*0.6,-2.7,2.7)
	_held = held
	_update_cherries()
	_art.queue_redraw()

func swing(delta: float, direction: float) -> void:
	angular_velocity += (-1100.0/length*sin(angle)+direction*3.7)*delta
	angular_velocity *= exp(-0.24*delta)
	angular_velocity = clampf(angular_velocity,-2.25,2.25)
	angle = clampf(angle+angular_velocity*delta,-0.92,0.92)
	if absf(angle)>=0.919 and angular_velocity*angle>0:angular_velocity=0
	if is_instance_valid(_art):_art.queue_redraw()

func get_grip() -> Vector2:
	return global_position+Vector2(sin(angle),cos(angle))*length

func release_velocity() -> Vector2:
	var tangent:=Vector2(cos(angle),-sin(angle))*length*angular_velocity+_anchor_velocity
	return Vector2(clampf(tangent.x,-420,420),clampf(tangent.y,-205,300))

func add_path_cherry(item: Node2D, at_angle: float) -> void:
	_cherries.append({"item":weakref(item),"angle":at_angle})
	_update_cherries()

func _update_cherries() -> void:
	for entry in _cherries:
		var item:Node2D=entry.item.get_ref()
		if is_instance_valid(item) and not item.collected:
			var a:float=entry.angle
			item.global_position=global_position+Vector2(sin(a),cos(a))*length+Vector2(0,6)

func detach() -> void:
	rider = null

func toggle_plant() -> void:
	shifted = not shifted
	Fx.burst(global_position,Color("88ffe2"),8,70)

func _paint() -> void:
	var end := Vector2(sin(angle),cos(angle))*length
	_art.draw_texture_rect(ANCHOR,Rect2(-24,-19,48,30),false)
	var count:=int(ceil(length/30))
	var span:=length/count
	for i in count:
		var texture:Texture2D=SEGMENTS[i%4]
		var width:=texture.get_width()/float(texture.get_height())*(span+2)
		_art.draw_set_transform((end*float(i)/count).round(),-angle)
		_art.draw_texture_rect(texture,Rect2(-width/2,-1,width,span+2),false)
	_art.draw_set_transform(Vector2.ZERO)
	_art.draw_texture_rect(GRIP,Rect2(end.round()-Vector2(8,7),Vector2(16,16)),false)

extends Node2D
@export var launch_geyser:=false
@export var phase:=0.0
var cycle:=0.0
var state:="dormant"
var _launched:=0.0
var _jet:Sprite2D
var _terrain:Node2D
var _ground_frame:=0
var _jet_height:=0.0
var _launch_pad:AnimatedSprite2D
const GROUND_FRAMES: Array[Texture2D]=[
	preload("res://world/Arte/Underworld/V39/terrain_16.tres"),
	preload("res://world/Arte/Underworld/V39/terrain_17.tres"),
	preload("res://world/Arte/Underworld/V39/terrain_18.tres"),
	preload("res://world/Arte/Underworld/V39/terrain_19.tres")]
const JET_FRAMES: Array[Texture2D]=[
	preload("res://world/Arte/Underworld/V39/geyser_04.tres"),
	preload("res://world/Arte/Underworld/V39/geyser_05.tres"),
	preload("res://world/Arte/Underworld/V39/geyser_06.tres"),
	preload("res://world/Arte/Underworld/V39/geyser_07.tres")]

func _ready() -> void:
	add_to_group("lava_geysers")
	cycle=phase
	_bind_ground()
	_jet=_make_sprite()
	_jet.name="LavaJet"
	_jet.hide()
	if launch_geyser:
		var support:=StaticBody2D.new()
		support.collision_layer=1
		support.collision_mask=0
		var shape:=RectangleShape2D.new()
		shape.size=Vector2(44,6)
		var collider:=CollisionShape2D.new()
		collider.shape=shape
		collider.position=Vector2(0,-3)
		collider.one_way_collision=true
		support.add_child(collider)
		add_child(support)
		_launch_pad=AnimatedSprite2D.new()
		_launch_pad.sprite_frames=preload("res://world/Arte/Underworld/V45/launch_pad.tres")
		_launch_pad.centered=false
		_launch_pad.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		_launch_pad.material=preload("res://world/Scripts/magic_art.gd").material()
		_launch_pad.material.set_shader_parameter("alpha_cutoff",0.94)
		var texture:Texture2D=_launch_pad.sprite_frames.get_frame_texture(&"dormant",0)
		var ratio:float=50.0/float(texture.get_meta("core_width"))
		_launch_pad.scale=Vector2.ONE*ratio
		_launch_pad.position=Vector2(-texture.get_width()*0.5*ratio,12-500*ratio)
		add_child(_launch_pad)
	_update_art()

func _make_sprite(parent:Node=null) -> Sprite2D:
	var sprite:=Sprite2D.new()
	sprite.centered=false
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.material=preload("res://world/Scripts/magic_art.gd").material()
	sprite.material.set_shader_parameter("alpha_cutoff",0.94)
	if parent==null:add_child(sprite)
	else:parent.add_child(sprite)
	return sprite

func _bind_ground() -> void:
	var terrain:=get_parent().get_node_or_null("Level")
	if terrain!=null:
		for floor in terrain.get_children():
			if floor.get("width")==null or floor.get("platform")==true:continue
			if absf(floor.global_position.y-global_position.y)<1 and global_position.x>=floor.global_position.x and global_position.x<floor.global_position.x+floor.width:
				_terrain=floor
				floor.register_geyser(self)
				return

func ground_texture() -> Texture2D:return GROUND_FRAMES[_ground_frame]

func _physics_process(delta:float) -> void:
	cycle=fposmod(cycle+delta,4.8)
	_launched=maxf(0,_launched-delta)
	var next:="dormant" if cycle<2.2 else ("warning" if cycle<3.45 else ("erupting" if cycle<4.25 else "cooling"))
	if next!=state:
		state=next
		var nearby:=get_tree().get_first_node_in_group("player") as Node2D
		if state=="warning" and nearby!=null and nearby.global_position.distance_to(global_position)<360:Sfx.alert()
	_update_art()
	if state=="erupting" and _jet_height>1:
		var player:=get_tree().get_first_node_in_group("player") as CharacterBody2D
		if player!=null and not player.is_dead() and absf(player.global_position.x-global_position.x)<23 and player.global_position.y+11>global_position.y+2-_jet_height and player.global_position.y<global_position.y+9:
			if launch_geyser and _launched<=0:
				_launched=0.7
				player.launch_from_spring(650)
				Fx.burst(player.global_position,Color("ffd485"),10,100)
			elif not launch_geyser and player.elements.temporary_fire<=0:player.take_damage(1,global_position)
	queue_redraw()

func _update_art() -> void:
	if is_instance_valid(_launch_pad):_launch_pad.play(StringName(state))
	# A fenda nunca troca de tamanho nem abandona o piso; o jato é outra peça.
	var base_index:=0
	if state=="warning":base_index=1 if cycle<2.95 else 2
	elif state=="erupting":base_index=2
	elif state=="cooling":base_index=3
	if _ground_frame!=base_index:
		_ground_frame=base_index
		if is_instance_valid(_terrain):_terrain.queue_redraw()
	_jet_height=0
	_jet.visible=state=="erupting"
	if _jet.visible:
		var time:=cycle-3.45
		var growth:=smoothstep(0,0.12,time)
		var retreat:=1-smoothstep(0.58,0.8,time)
		_jet_height=roundf(112*minf(growth,retreat))
		_jet.texture=JET_FRAMES[int(time*10)%4]
		_jet.position=Vector2(-24,2-_jet_height)
		_jet.scale=Vector2(48,maxf(_jet_height,0.01))/_jet.texture.get_size()

func _draw() -> void:
	if state=="warning":
		var heat:=clampf((cycle-2.2)/1.25,0,1)
		for i in 6:
			var t:=fposmod(cycle*0.95+float(i)/6,1.0)
			draw_rect(Rect2(roundf(sin(i*2.3)*13),roundf(-5-t*(12+heat*16)),1+i%2,2),Color("e9a55c",(1-t)*0.85))
		for side in [-1,1]:
			draw_rect(Rect2(side*17-2,-5-roundf(absf(sin(cycle*36+side))*heat*2),3,2),Color("766a79"))

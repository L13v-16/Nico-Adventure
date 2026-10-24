extends AnimatableBody2D
signal settled
@export_enum("wall","pillar","block") var kind:="wall"
@export var push_offset:=Vector2(120,0)
var broken:=false
var pushing:=false
var _destination:=Vector2.ZERO
var _sprite:Sprite2D
var _collider:CollisionShape2D
var _prompt:Label
var _break_clock:=-1.0
var _rock_frames:Array[Texture2D]=[]
var _pillar_frames:Array[Texture2D]=[]
var _bridge:StaticBody2D
const Art=preload("res://world/Scripts/underworld_art.gd")
func _ready() -> void:
	add_to_group("jose_targets")
	collision_layer=1
	collision_mask=0
	var size:=Vector2(80,108) if kind=="wall" else (Vector2(48,100) if kind=="pillar" else Vector2(52,48))
	if kind=="wall":
		for i in 4:_rock_frames.append(load("res://world/Arte/Underworld/V38/rocks_%02d.tres"%i))
		_sprite=Sprite2D.new()
		_sprite.texture=_rock_frames[0]
		_sprite.centered=false
		_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		_sprite.material=preload("res://world/Scripts/magic_art.gd").material()
		_sprite.material.set_shader_parameter("alpha_cutoff",0.94)
		_sprite.scale=size/_sprite.texture.get_size()
		_sprite.position=Vector2(-size.x/2,-size.y)
	elif kind=="pillar":
		for i in 3:_pillar_frames.append(load("res://world/Arte/Underworld/V45/pillar_%02d.tres"%i))
		_sprite=Sprite2D.new()
		_sprite.texture=_pillar_frames[0]
		_sprite.centered=false
		_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		_sprite.material=preload("res://world/Scripts/magic_art.gd").material()
		_sprite.material.set_shader_parameter("alpha_cutoff",0.94)
		var ratio:float=100.0/float(_pillar_frames[0].get_meta("opaque_height"))
		_sprite.scale=Vector2.ONE*ratio
		_sprite.position=Vector2(-_pillar_frames[0].get_width()*0.5,-500)*ratio
		_sprite.position.y+=2
	else:_sprite=Art.prop(5,size,Vector2(-size.x/2,-size.y))
	add_child(_sprite)
	var shape:=RectangleShape2D.new()
	shape.size=size
	_collider=CollisionShape2D.new()
	_collider.shape=shape
	_collider.position=Vector2(0,-size.y/2)
	add_child(_collider)
	_prompt=Label.new()
	_prompt.text="C · JOSÉ"
	_prompt.position=Vector2(-27,-size.y-20)
	_prompt.size=Vector2(54,16)
	_prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size",8)
	_prompt.add_theme_color_override("font_color",Color("ffe1a0"))
	_prompt.add_theme_color_override("font_outline_color",Color("181522"))
	_prompt.add_theme_constant_override("outline_size",2)
	_prompt.z_index=8
	add_child(_prompt)
func can_jose_target() -> bool:return not broken
func jose_point() -> Vector2:return global_position
func jose_hit_range() -> float:return _collider.shape.size.x*0.5+18
func receive_jose_hit() -> bool:
	if broken:return false
	broken=true
	Sfx.hit()
	Fx.burst(position+Vector2(0,-30),Color("bfa18d"),18,160)
	if kind=="block":
		pushing=true
		_destination=position+push_offset
	else:
		_collider.set_deferred("disabled",true)
		if kind=="pillar":
			# A coluna caída vira uma ponte com a mesma altura visual e física.
			_bridge=preload("res://world/Scripts/fallen_pillar_bridge.gd").new()
			_bridge.position=position+Vector2(0,-3)
			get_parent().add_child(_bridge)
			_bridge.hide()
			_break_clock=0
			_sprite.texture=_pillar_frames[1]
		if kind=="wall":
			_break_clock=0
			_sprite.texture=_rock_frames[1]
		elif kind!="pillar":_sprite.hide()
	return true
func _physics_process(delta:float) -> void:
	if _break_clock>=0:
		_break_clock+=delta
		if kind=="pillar":
			_sprite.texture=_pillar_frames[2] if _break_clock>=0.12 else _pillar_frames[1]
			if _break_clock>=0.32:
				_sprite.hide()
				if is_instance_valid(_bridge):_bridge.show()
				_break_clock=-1
		else:
			_sprite.texture=_rock_frames[2] if _break_clock<0.26 and _break_clock>=0.12 else (_rock_frames[3] if _break_clock>=0.26 else _rock_frames[1])
		if kind=="wall" and _break_clock>=0.26:
			# O entulho assenta numa faixa baixa; não parece outra barreira sólida.
			var height:=roundf(lerpf(108,32,smoothstep(0.26,0.48,_break_clock)))
			_sprite.scale.y=height/_sprite.texture.get_height()
			_sprite.position.y=-height
		if kind=="wall" and _break_clock>=0.48:_break_clock=-1
	if pushing:
		position=position.move_toward(_destination,85*delta)
		if position.is_equal_approx(_destination):
			pushing=false
			settled.emit()
	_update_prompt()
func _update_prompt() -> void:
	var player:=get_tree().get_first_node_in_group("player") as Node2D
	_prompt.visible=not broken and player!=null and player.position.distance_to(position)<240

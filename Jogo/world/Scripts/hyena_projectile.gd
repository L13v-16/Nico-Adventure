extends CharacterBody2D
@export var kind:="barrel"
var flight:=Vector2.ZERO
var _life:=3.0
var _dead:=false
var _frozen:=0.0
var _sprite:Sprite2D
var thrower:WeakRef
var reflected:=false
func _ready() -> void:
	z_index=3
	add_to_group("enemies")
	add_to_group("hyena_projectiles")
	collision_layer=4
	collision_mask=1
	var shape:=CircleShape2D.new()
	shape.radius=10
	var collider:=CollisionShape2D.new()
	collider.shape=shape
	add_child(collider)
	_sprite=Sprite2D.new()
	_sprite.texture=load("res://world/Arte/Magic/V26/"+kind+".tres")
	_sprite.scale=Vector2.ONE*(24.0/_sprite.texture.get_width())
	_sprite.material=preload("res://world/Scripts/magic_art.gd").material()
	_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_sprite)
func _physics_process(delta:float) -> void:
	if _dead:return
	_life-=delta
	if _life<=0:_break();return
	if reflected:
		var boss=thrower.get_ref() if thrower!=null else null
		if not is_instance_valid(boss) or boss.is_dead() or not boss.active:_break();return
		var target:Vector2=boss.global_position+Vector2(0,-36)
		var step:=520.0*delta
		_sprite.modulate=Color("baffdd")
		_sprite.rotation+=delta*12
		if global_position.distance_to(target)<=step+26:
			boss.receive_reflected_barrel()
			_break()
		else:global_position=global_position.move_toward(target,step)
		return
	if _frozen>0:
		_frozen=maxf(0,_frozen-delta)
		_sprite.modulate=Color("9feaff")
		return
	_sprite.modulate=Color.WHITE
	flight.y+=620*delta
	_sprite.rotation+=delta*(4 if flight.x>0 else -4)
	if move_and_collide(flight*delta)!=null:_break();return
	var p:=get_tree().get_first_node_in_group("player") as CharacterBody2D
	if is_instance_valid(p) and not p.is_dead() and global_position.distance_to(p.global_position+Vector2(0,-6))<22:
		p.take_damage(1,global_position)
		_break()
func take_damage(amount:float,_source:Vector2) -> void:
	if amount<=0 or _dead or reflected:return
	if kind!="barrel":_break();return
	var boss=thrower.get_ref() if thrower!=null else null
	if not is_instance_valid(boss) or not boss.active:_break();return
	reflected=true
	_frozen=0
	_life=3
	# The player's attack query can hit each target once. Removing this layer
	# also prevents another swing from consuming an already returned barrel.
	set_deferred("collision_layer",0)
	remove_from_group("enemies")
	Sfx.swing()
	Fx.popup(global_position+Vector2(0,-20),"REBATEU!",Color("c6ffe5"),10)
func is_dead() -> bool:return _dead
func freeze_for(duration:float) -> void:
	if not reflected:_frozen=maxf(_frozen,minf(duration,0.8))
func _break() -> void:
	if _dead:return
	_dead=true
	Fx.burst(global_position,Color("ddc1ff"),10,110)
	Sfx.hit()
	queue_free()

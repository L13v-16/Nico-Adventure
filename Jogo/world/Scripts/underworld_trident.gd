extends Node2D
const Art=preload("res://world/Scripts/underworld_art.gd")
var flight:=Vector2(-210,0)
var life:=4.0
var _sprite:Sprite2D
func _ready() -> void:
	add_to_group("underworld_projectiles")
	_sprite=Art.prop(13,Vector2(29,10),Vector2(-14,-5))
	_sprite.texture=preload("res://world/Arte/Underworld/V48/imp_11.tres")
	_sprite.scale=Vector2(29,10)/_sprite.texture.get_size()
	_sprite.flip_h=flight.x>0
	add_child(_sprite)
func _physics_process(delta:float) -> void:
	life-=delta
	if life<=0:queue_free();return
	var next:=global_position+flight*delta
	# A pedra gravitacional usa camada de chão: o tridente para nela antes de Nico.
	var query:=PhysicsRayQueryParameters2D.create(global_position,next,1|2)
	var hit:=get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var body:Node=hit.collider
		if body.is_in_group("player"):body.take_damage(1,global_position-flight.normalized()*10)
		Fx.burst(hit.position,Color("ecb278"),5,60)
		queue_free()
		return
	global_position=next

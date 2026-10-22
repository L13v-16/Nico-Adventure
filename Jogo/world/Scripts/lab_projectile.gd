extends Node2D
var flight:=Vector2(-210,0)
var friendly:=false
var net:=false
var serum:=false
var life:=4.0
var owner_boss:Node2D
var _sprite:Sprite2D
func _ready() -> void:
	add_to_group("lab_projectiles");z_index=6
	_sprite=preload("res://world/Scripts/lab_art.gd").prop("net" if net else "syringe",28)
	_sprite.position.y=-5;add_child(_sprite)
func _physics_process(delta:float) -> void:
	life-=delta
	if life<=0:queue_free();return
	var next:=global_position+flight*delta
	var query:=PhysicsRayQueryParameters2D.create(global_position,next,1|2|4)
	if friendly:
		query.hit_from_inside=true
		var player:=get_tree().get_first_node_in_group("player") as CollisionObject2D
		if player!=null:query.exclude=[player.get_rid()]
	var hit:=get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var target:Node=hit.collider
		if friendly and target==owner_boss:
			owner_boss.receive_serum(self)
		elif not friendly and target.is_in_group("player"):
			target.take_damage(1,global_position)
			if net:target._hitstun_timer=maxf(target._hitstun_timer,.45)
		if not friendly and not net and hit.normal.y<-.5:
			var pool:Node2D=get_parent().spawn_pool(hit.position+Vector2(0,1),"toxic",6,70)
			if is_instance_valid(owner_boss):pool.set_meta("boss_owner_id",owner_boss.get_instance_id())
		queue_free();return
	global_position=next
	if not friendly and not net:flight.y+=75*delta
	_sprite.flip_h=flight.x<0

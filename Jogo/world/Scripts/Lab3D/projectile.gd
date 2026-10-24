extends Node3D
var flight:=Vector3.ZERO
var friendly:=false
var serum:=false
var element:="chemical"
var source:Node3D
var life:=4.0
var freeze_duration:=3.0
var spent:=false
func _ready() -> void:
	add_to_group("lab3d_projectiles")
	var art:Node3D
	if serum or element=="chemical":art=preload("res://world/Scripts/Lab3D/models.gd").instantiate("syringe");art.scale=Vector3.ONE*(.7 if serum else .5);art.rotation.x=PI/2
	else:
		art=Node3D.new();preload("res://world/Scripts/Lab3D/models.gd").ball(art,"Orb",Vector3.ZERO,Vector3(.4,.4,.4),"72dbea" if element=="ice" else "ffa55f",1)
	add_child(art)
func _physics_process(delta:float) -> void:
	life-=delta
	if life<=0:queue_free();return
	var next:=global_position+flight*delta
	var query:=PhysicsRayQueryParameters3D.create(global_position,next,1|2|4|16);query.hit_from_inside=true
	if is_instance_valid(source) and source is CollisionObject3D:query.exclude=[source.get_rid()]
	var hit:=get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var target:Node=hit.collider
		if target.has_meta("receiver"):target=target.get_meta("receiver")
		if friendly:
			if serum and target.has_method("receive_serum"):target.receive_serum(self)
			elif not serum and target.has_method("take_element"):target.take_element(element,global_position,freeze_duration)
		elif target.is_in_group("player"):target.take_damage(1,global_position)
		elif hit.normal.y>.6:get_parent().spawn_pool(hit.position+Vector3.UP*.025,1.5,3.0)
		get_parent().spark(hit.position,"74dbdf" if element=="ice" else "eda866")
		queue_free();return
	global_position=next
	if flight.length()>.01:look_at(global_position+flight.normalized(),Vector3.UP if absf(flight.normalized().y)<.95 else Vector3.FORWARD)

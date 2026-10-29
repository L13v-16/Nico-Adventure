extends StaticBody2D
const RingArt=preload("res://world/Scripts/warden_ring_art.gd")
## Gancho rebatível: usa a consulta de ataque normal, com alvo físico na camada 4.
var boss:CharacterBody2D
var flight:=Vector2.LEFT*190
var life:=6.5
var returned:=false
var _floor_y:=100.0
var _clock:=0.0
var _reflect_flash:=0.0
func _ready() -> void:
	add_to_group("underworld_projectiles");add_to_group("enemies")
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	z_index=5;collision_layer=4;collision_mask=0
	var shape:=CircleShape2D.new();shape.radius=13
	var collider:=CollisionShape2D.new();collider.shape=shape;add_child(collider)
	if is_instance_valid(boss):_floor_y=boss.arena_floor_y()
func is_dead() -> bool:return returned or not is_instance_valid(boss) or not boss.active or boss.phase!=2
func take_damage(amount:float,_source:Vector2) -> void:
	if amount>0 and not is_dead():
		returned=true;collision_layer=0;life=3.5
		_reflect_flash=.18
		flight=(boss.global_position+Vector2(0,-55)-global_position).normalized()*350
		Sfx.swing();Fx.burst(global_position,Color("d5ffac"),8,80)
func take_element(_element:String,_source:Vector2) -> void:pass # A instrução é rebater com o ataque básico.
func _physics_process(delta:float) -> void:
	if not is_instance_valid(boss) or not boss.active or boss.phase!=2:queue_free();return
	_clock+=delta
	_reflect_flash=maxf(0,_reflect_flash-delta)
	life-=delta
	if life<=0:queue_free();return
	if returned:
		var target:=boss.global_position+Vector2(0,-55)
		flight=(target-global_position).normalized()*350
		if global_position.distance_to(target)<350*delta+30:
			boss.receive_returned_chain();queue_free();return
	else:
		var floor_y:float=boss.arena_floor_y()
		global_position.y+=floor_y-_floor_y;_floor_y=floor_y
	var next:=global_position+flight*delta
	var query:=PhysicsRayQueryParameters2D.create(global_position,next,1 if returned else 1|2,[get_rid()])
	var hit:=get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		# A animação de ataque tem prioridade sobre o contato no mesmo quadro físico.
		var victim:Node=hit.collider
		if not returned and victim.is_in_group("player") and victim.is_attacking() and (global_position.x-victim.global_position.x)*victim._attack_facing>=0:
			take_damage(1,victim.global_position);return
		if victim.is_in_group("player"):victim.take_damage(1,global_position-flight.normalized()*10)
		Fx.burst(hit.position,Color("ddb982"),6,75);queue_free();return
	global_position=next;queue_redraw()
func _draw() -> void:
	RingArt.draw_sprite(self,8+int(_clock*10)%4,Vector2.ZERO,78,flight.x>0,Color("e2ffc6") if returned else Color.WHITE)
	if _reflect_flash>0:RingArt.draw_sprite(self,15,Vector2.ZERO,70,false,Color(1,1,1,_reflect_flash/.18))

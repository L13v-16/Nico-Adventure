extends CharacterBody3D
signal health_changed(current:int,maximum:int)
signal gem_collected(count:int)
signal cherry_balance_changed(balance:int)
signal died
signal respawned
const MAX_HEALTH:=3
var health:=3
var gems:=0
var cherries_spent:=0
var shop_shield_hits:=0
var _finished:=false
var _dead:=false
var _invulnerability_timer:=0.0
var _attack_cooldown:=0.0
var _attack_time:=0.0
var _hitstun:=0.0
var _coyote:=0.0
var _jump_buffer:=0.0
const RUN_SPEED:=7.2
const SPIN_DURATION:=.36
var _air_jump_used:=false
var _slide_left:=0.0
var _slide_cooldown:=0.0
var _slam_left:=0.0
var _slamming:=false
var _spin_angle:=0.0
var _spin_hits:Array[int]=[]
var _capsule:CapsuleShape3D
var _collider:CollisionShape3D
var _landing:Node3D
var _spin_ring:MeshInstance3D
var _land_squash:=0.0
var _cast_pose:=0.0
var _cast_element:="ice"
var forward:=Vector3.FORWARD
var respawn_position:=Vector3.ZERO
var acai_left:=0.0
var equipment:Node
var elements:Node
var model:Node3D
var _anim:AnimationPlayer
func _ready() -> void:
	add_to_group("player");collision_layer=2;collision_mask=1|4;floor_snap_length=.4
	var shape:=CapsuleShape3D.new();shape.radius=.36;shape.height=1.75
	_capsule=shape;_collider=CollisionShape3D.new();_collider.shape=shape;_collider.position.y=.88;add_child(_collider)
	model=preload("res://world/Scripts/Lab3D/models.gd").instantiate("nico");add_child(model);_anim=model.get_node("Animations")
	_carry_animations()
	equipment=preload("res://world/Scripts/equipment_model.gd").new();equipment.name="Equipment";add_child(equipment)
	elements=preload("res://world/Scripts/Lab3D/powers.gd").new();elements.name="Elements";add_child(elements)
	respawn_position=position
	for pair in [["lab3d_forward",KEY_W,KEY_UP],["lab3d_back",KEY_S,KEY_DOWN],["lab3d_left",KEY_A,KEY_LEFT],["lab3d_right",KEY_D,KEY_RIGHT],["lab3d_jump",KEY_SPACE,KEY_SPACE],["lab3d_boost",KEY_SHIFT,KEY_SHIFT],["lab3d_dodge",KEY_CTRL,KEY_CTRL],["element_cast",KEY_K,KEY_K],["element_swap",KEY_Q,KEY_Q],["lab_throw",KEY_F,KEY_F]]:
		if InputMap.has_action(pair[0]):continue
		InputMap.add_action(pair[0])
		for code in [pair[1],pair[2]]:
			var event:=InputEventKey.new();event.physical_keycode=code;InputMap.action_add_event(pair[0],event)
	_landing=Node3D.new();_landing.name="LandingMarker";add_child(_landing);_landing.top_level=true
	var shadow:=preload("res://world/Scripts/Lab3D/models.gd").ring(_landing,"Shadow",Vector3.ZERO,.40,"183344");shadow.scale.y=.04
	var rim:=preload("res://world/Scripts/Lab3D/models.gd").ring(_landing,"LandingRim",Vector3(0,.015,0),.46,"f3ce79",.35);rim.scale.y=.04
	_spin_ring=preload("res://world/Scripts/Lab3D/models.gd").ring(self,"SpinArc",Vector3(0,.85,0),1.2,"a5eee0",.5);_spin_ring.scale.y=.08;_spin_ring.hide()
func _physics_process(delta:float) -> void:
	if _dead or _finished or get_parent().intro_active:
		_landing.hide();_spin_ring.hide();return
	_invulnerability_timer=maxf(0,_invulnerability_timer-delta);_attack_cooldown=maxf(0,_attack_cooldown-delta);_hitstun=maxf(0,_hitstun-delta)
	_slide_cooldown=maxf(0,_slide_cooldown-delta);acai_left=maxf(0,acai_left-delta);_cast_pose=maxf(0,_cast_pose-delta)
	model.visible=_invulnerability_timer<=0 or fposmod(_invulnerability_timer,.13)>.035
	var grounded:=is_on_floor()
	if grounded:_air_jump_used=false
	_coyote=.12 if grounded else maxf(0,_coyote-delta)
	_jump_buffer=.14 if Input.is_action_just_pressed("lab3d_jump") else maxf(0,_jump_buffer-delta)
	var axis:=Input.get_vector("lab3d_left","lab3d_right","lab3d_forward","lab3d_back")
	var direction:=Vector3(axis.x,0,axis.y).rotated(Vector3.UP,get_parent().camera_yaw)
	var carrying:=is_instance_valid(get_parent().carried_cell)
	if _slide_left<=0 and _capsule.height<1.7:_set_low(false)
	if _hitstun<=0:
		if (Input.is_action_just_pressed("lab3d_dodge") or Input.is_action_just_pressed("lab3d_boost")) and not carrying and _slide_cooldown<=0 and not _slamming:
			if grounded and direction.length()>.1:
				_slide_left=.42;_slide_cooldown=.72;forward=direction.normalized();_set_low(true)
			elif not grounded:
				_slamming=true;_slam_left=.14;velocity=Vector3.ZERO;_cancel_attack()
		if _slide_left>0:
			_slide_left=maxf(0,_slide_left-delta);velocity.x=forward.x*10.6;velocity.z=forward.z*10.6
			if _slide_left<=0:_set_low(false)
		elif not _slamming:
			var speed:float=RUN_SPEED*equipment.get_speed_multiplier()*(.72 if carrying else 1.0)
			if _capsule.height<1.7:speed*=.6
			var acceleration:=58.0 if grounded else 28.0
			if direction.length()<.1:acceleration=76.0 if grounded else 20.0
			velocity.x=move_toward(velocity.x,direction.x*speed,acceleration*delta)
			velocity.z=move_toward(velocity.z,direction.z*speed,acceleration*delta)
			if direction.length()>.1:forward=direction.normalized()
		if _jump_buffer>0 and not _slamming:
			if _coyote>0:
				if _set_low(false):
					velocity.y=10.4*equipment.get_jump_multiplier();_jump_buffer=0;_coyote=0;_slide_left=0;Sfx.jump()
			elif Input.is_action_just_pressed("lab3d_jump") and not _air_jump_used and not carrying:
				_air_jump_used=true;velocity.y=9.0*equipment.get_jump_multiplier();_jump_buffer=0;Sfx.jump()
	if Input.is_action_just_released("lab3d_jump") and velocity.y>4.6 and not _slamming:velocity.y=4.6
	if _slamming:
		_slam_left=maxf(0,_slam_left-delta);velocity.y=0 if _slam_left>0 else -25.0
	elif not grounded:velocity.y=maxf(-30,velocity.y-28*delta)
	if Input.is_action_just_pressed("attack") and _attack_cooldown<=0 and _hitstun<=0 and not _slamming:attack()
	if _attack_time>0:
		_attack_time=maxf(0,_attack_time-delta);_spin_angle+=delta*TAU*5;_melee(2.15)
	else:_spin_angle=0
	var previous_y:=global_position.y
	var falling_speed:=velocity.y
	move_and_slide()
	if is_on_floor() and not grounded:
		_land_squash=.14
		if _slamming:
			_spin_hits.clear();_melee(2.65);get_parent().spark(global_position+Vector3.UP*.15,"f1ce8a");get_parent().shake(.09);Sfx.hit()
		_slamming=false;_air_jump_used=false
	elif falling_speed<-.5 and not _slamming:_try_stomp(previous_y)
	if _slide_left>0 and is_on_wall():_slide_left=0;_set_low(false)
	_update_visuals(delta,carrying)
	_update_landing()
	if position.y<get_parent().sector_floor()-8:fall_back()
func _update_visuals(delta:float,carrying:bool) -> void:
	_land_squash=maxf(0,_land_squash-delta)
	var yaw:=atan2(-forward.x,-forward.z)
	model.rotation.y=yaw+_spin_angle if _attack_time>0 else lerp_angle(model.rotation.y,yaw,1-exp(-delta*18))
	model.scale=Vector3(1.04,.58,1.08) if _capsule.height<1.7 else (Vector3(1.04,.94,1.04) if _land_squash>0 else Vector3.ONE)
	model.rotation.x=-.28 if _slamming else 0.0
	_spin_ring.visible=_attack_time>0
	var running:bool=is_on_floor() and Vector2(velocity.x,velocity.z).length()>.4
	var clip:="run" if running else "idle"
	if not is_on_floor():clip="fall" if velocity.y<0 else ("double_jump" if _air_jump_used else "jump")
	if _capsule.height<1.7:clip="slide"
	if carrying:clip="carry_run" if running else "carry_idle"
	if _cast_pose>0:clip="cast_"+_cast_element
	if _slamming:clip="slam"
	if _attack_time>0:clip="spin"
	if _hitstun>0:clip="hurt"
	_anim.play(clip)
	_anim.speed_scale=clampf(Vector2(velocity.x,velocity.z).length()/RUN_SPEED,.65,1.4) if clip in ["run","carry_run"] else 1.0
func play_element_cast(element:String) -> void:
	_cast_pose=.32;_cast_element=element
func _set_low(low:bool) -> bool:
	if not low and _capsule.height<1.7:
		var shape:=CapsuleShape3D.new();shape.radius=.36;shape.height=1.75
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform=Transform3D(Basis.IDENTITY,global_position+Vector3.UP*.91);query.collision_mask=1;query.exclude=[get_rid()]
		if not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():return false
	_capsule.height=.9 if low else 1.75;_collider.position.y=.46 if low else .88
	return true
func _update_landing() -> void:
	var query:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*.2,global_position+Vector3.DOWN*32,1);query.exclude=[get_rid()]
	var hit:=get_world_3d().direct_space_state.intersect_ray(query)
	_landing.visible=not hit.is_empty()
	if not hit.is_empty():_landing.global_position=hit.position+Vector3.UP*.045
func attack() -> void:
	if is_instance_valid(get_parent().carried_cell):get_parent().notice("Nico está com as mãos ocupadas. E para soltar a célula.");return
	_attack_cooldown=maxf(.48*equipment.get_attack_cooldown_multiplier(),get_attack_cooldown_floor());_attack_time=SPIN_DURATION;_spin_hits.clear();_spin_angle=0;Sfx.swing()
func _melee(radius:float=2.15) -> void:
	for group in ["lab3d_enemies","lab3d_crates","lab3d_puzzle_targets"]:
		for target in get_tree().get_nodes_in_group(group):
			if not target.is_inside_tree() or not target.is_visible_in_tree() or target.dead or target.get_instance_id() in _spin_hits:continue
			var gap:Vector3=target.global_position-global_position
			if Vector2(gap.x,gap.z).length()>radius or absf(gap.y)>(1.55 if group=="lab3d_enemies" else 1.2):continue
			var ray:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*.8,target.global_position+Vector3.UP*.8,1);ray.exclude=[get_rid()]
			var hit:=get_world_3d().direct_space_state.intersect_ray(ray)
			if not hit.is_empty() and hit.collider!=target:continue
			_spin_hits.append(target.get_instance_id());target.take_damage(equipment.get_damage_multiplier()*(2 if acai_left>0 else 1),global_position)
func bounce(strength:float=10.8) -> void:
	velocity.y=strength;_air_jump_used=false;_coyote=0;_slamming=false;_slam_left=0;Sfx.jump()
func _try_stomp(previous_y:float) -> void:
	for target in get_tree().get_nodes_in_group("lab3d_enemies"):
		if not target.is_visible_in_tree() or target.dead or not target.has_method("stomp"):continue
		var gap:Vector3=global_position-target.global_position
		if Vector2(gap.x,gap.z).length()<.95 and previous_y>=target.global_position.y+1.45 and gap.y<=1.95 and gap.y>=1.0:
			if target.stomp(global_position):bounce();return
func take_damage(amount:float,source:Vector3) -> void:
	if _dead or _finished or get_parent().intro_active or _invulnerability_timer>0:return
	if equipment.consume_leaf():_invulnerability_timer=1.0;Sfx.checkpoint();return
	if acai_left>0:acai_left=0;_invulnerability_timer=1.5;Sfx.checkpoint();return
	if shop_shield_hits>0:shop_shield_hits-=1;_invulnerability_timer=1.0;health_changed.emit(health,MAX_HEALTH);return
	health=maxi(0,health-int(amount));health_changed.emit(health,MAX_HEALTH);Sfx.hurt()
	_invulnerability_timer=1.5+equipment.get_invulnerability_bonus();_hitstun=.25;_cancel_attack();reset_traversal(false)
	var away:Vector3=(global_position-source);away.y=0;velocity=away.normalized()*6+Vector3.UP*4
	get_parent().shake(.18)
	if health<=0:
		_dead=true;model.visible=true;_anim.play("death");died.emit();await get_tree().create_timer(.65).timeout
		if is_inside_tree():respawn()
func fall_back() -> void:
	if _dead:return
	get_parent().deaths+=1;health=maxi(1,health-1);respawn(false)
func respawn(full_health:bool=true) -> void:
	_dead=false;position=respawn_position;velocity=Vector3.ZERO;_invulnerability_timer=2;_hitstun=0;acai_left=0;_cancel_attack();reset_traversal()
	if full_health:health=MAX_HEALTH
	model.visible=true;health_changed.emit(health,MAX_HEALTH);respawned.emit();get_parent().snap_camera()
func _cancel_attack() -> void:
	_attack_time=0;_spin_angle=0;_spin_hits.clear()
	if is_instance_valid(_spin_ring):_spin_ring.hide()
func reset_traversal(force_stand:bool=true) -> void:
	_slide_left=0;_slide_cooldown=0;_slamming=false;_slam_left=0;_air_jump_used=false;_jump_buffer=0;_coyote=0
	if force_stand:_capsule.height=1.75;_collider.position.y=.88
	else:_set_low(false)
	model.scale=Vector3(1.04,.58,1.08) if _capsule.height<1.7 else Vector3.ONE;model.rotation.x=0;_cast_pose=0
	_landing.hide()
func is_dead() -> bool:return _dead
func get_equipment() -> Node:return equipment
func get_attack_cooldown_floor() -> float:return .65 if get_parent().boss.active else 0.0
func get_cherry_balance() -> int:return Save.get_cherry_balance()
func try_spend_cherries(amount:int) -> bool:
	if not Save.try_spend_cherries(amount):return false
	cherries_spent+=amount;cherry_balance_changed.emit(get_cherry_balance());return true
func collect_item(id:String,level_id:String="fase_5") -> bool:
	if _dead or _finished:return false
	if Save.is_free_mode() and Save.has_collected_cherry(level_id,id):return false
	var recorded:=Save.has_collected_cherry(level_id,id)
	if not Save.collect_level_cherry(level_id,id):return false
	# Keep the original IDs and the campaign/free-play rules of the shared save.
	gems+=1;gem_collected.emit(gems);cherry_balance_changed.emit(get_cherry_balance())
	if not recorded:Sfx.cherry()
	return true
func heal_one() -> bool:
	if health>=MAX_HEALTH:return false
	health+=1;health_changed.emit(health,MAX_HEALTH);return true
func heal_full() -> void:health=MAX_HEALTH;health_changed.emit(health,MAX_HEALTH)
func _carry_animations() -> void:
	if model.has_meta("meshy_rig"):return
	# A private library keeps the shared editable model and other actors untouched.
	var library:AnimationLibrary=_anim.get_animation_library("").duplicate(true)
	_anim.remove_animation_library("");_anim.add_animation_library("",library)
	for pair in [["idle","carry_idle"],["run","carry_run"],["idle","spin"],["jump","slam"]]:
		var animation:Animation=library.get_animation(pair[0]).duplicate(true)
		for track in animation.get_track_count():
			var path:=str(animation.track_get_path(track))
			if path.begins_with("Rig/Arm"):
				var rotation:=Vector3(1.1,0,.25 if path.contains("ArmL") else -.25)
				if pair[1]=="spin":rotation=Vector3(0,0,-1.35 if path.contains("ArmL") else 1.35)
				elif pair[1]=="slam":rotation=Vector3(-1.3,0,-.3 if path.contains("ArmL") else .3)
				for key in animation.track_get_key_count(track):animation.track_set_key_value(track,key,rotation)
			elif pair[1]=="slam" and path.begins_with("Rig/Leg"):
				for key in animation.track_get_key_count(track):animation.track_set_key_value(track,key,Vector3(-1.25,0,0))
		library.add_animation(pair[1],animation)
func grant_shop_shield(hits:int) -> bool:
	if shop_shield_hits>0:return false
	shop_shield_hits=hits;health_changed.emit(health,MAX_HEALTH);return true
func finish_level() -> void:_finished=true;velocity=Vector3.ZERO;_cancel_attack();reset_traversal();equipment.clear_temporary();_anim.play("idle")

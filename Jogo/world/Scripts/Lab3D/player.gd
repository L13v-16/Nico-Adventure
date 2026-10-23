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
var _homing:Node3D
var _homing_left:=0.0
var forward:=Vector3.FORWARD
var respawn_position:=Vector3.ZERO
var boost:=100.0
var acai_left:=0.0
var equipment:Node
var elements:Node
var model:Node3D
var _anim:AnimationPlayer
func _ready() -> void:
	add_to_group("player");collision_layer=2;collision_mask=1|4;floor_snap_length=.4
	var shape:=CapsuleShape3D.new();shape.radius=.36;shape.height=1.75
	var collider:=CollisionShape3D.new();collider.shape=shape;collider.position.y=.88;add_child(collider)
	model=preload("res://world/Scripts/Lab3D/models.gd").instantiate("nico");add_child(model);_anim=model.get_node("Animations")
	equipment=preload("res://world/Scripts/equipment_model.gd").new();equipment.name="Equipment";add_child(equipment)
	elements=preload("res://world/Scripts/Lab3D/powers.gd").new();elements.name="Elements";add_child(elements)
	respawn_position=position
	for pair in [["lab3d_forward",KEY_W,KEY_UP],["lab3d_back",KEY_S,KEY_DOWN],["lab3d_left",KEY_A,KEY_LEFT],["lab3d_right",KEY_D,KEY_RIGHT],["lab3d_jump",KEY_SPACE,KEY_SPACE],["lab3d_boost",KEY_SHIFT,KEY_SHIFT],["lab3d_dodge",KEY_CTRL,KEY_CTRL],["element_cast",KEY_K,KEY_K],["element_swap",KEY_Q,KEY_Q],["lab_throw",KEY_F,KEY_F]]:
		if InputMap.has_action(pair[0]):continue
		InputMap.add_action(pair[0])
		for code in [pair[1],pair[2]]:
			var event:=InputEventKey.new();event.physical_keycode=code;InputMap.action_add_event(pair[0],event)
	var shadow:=preload("res://world/Scripts/Lab3D/models.gd").ring(model,"ContactRing",Vector3(0,.025,0),.45,"223849");shadow.scale.y=.05
func _physics_process(delta:float) -> void:
	if _dead or _finished or get_parent().intro_active:return
	_invulnerability_timer=maxf(0,_invulnerability_timer-delta);_attack_cooldown=maxf(0,_attack_cooldown-delta);_hitstun=maxf(0,_hitstun-delta)
	acai_left=maxf(0,acai_left-delta)
	model.visible=_invulnerability_timer<=0 or fposmod(_invulnerability_timer,.13)>.035
	_coyote=.13 if is_on_floor() else maxf(0,_coyote-delta)
	_jump_buffer=.15 if Input.is_action_just_pressed("lab3d_jump") else maxf(0,_jump_buffer-delta)
	var axis:=Input.get_vector("lab3d_left","lab3d_right","lab3d_forward","lab3d_back")
	var direction:=Vector3(axis.x,0,axis.y).rotated(Vector3.UP,get_parent().camera_yaw)
	var boosting:=Input.is_action_pressed("lab3d_boost") and direction.length()>.1 and boost>0 and is_on_floor()
	boost=clampf(boost+(-25 if boosting else 16)*delta,0,100)
	var speed:float=(15.0 if boosting else 8.0)*equipment.get_speed_multiplier()
	if _hitstun<=0:
		velocity.x=move_toward(velocity.x,direction.x*speed,(32 if direction.length()>.1 else 42)*delta)
		velocity.z=move_toward(velocity.z,direction.z*speed,(32 if direction.length()>.1 else 42)*delta)
		if direction.length()>.1:
			forward=direction.normalized();model.rotation.y=lerp_angle(model.rotation.y,atan2(-forward.x,-forward.z),1-exp(-delta*14))
	if _jump_buffer>0 and _coyote>0:
		velocity.y=10.5*equipment.get_jump_multiplier();_jump_buffer=0;_coyote=0;Sfx.jump()
	if Input.is_action_just_released("lab3d_jump") and velocity.y>4.8:velocity.y=4.8
	if not is_on_floor():velocity.y=maxf(-35,velocity.y-24*delta)
	if Input.is_action_just_pressed("attack") and _attack_cooldown<=0:attack()
	if _homing_left>0 and is_instance_valid(_homing):
		_homing_left-=delta;var to:=_homing.global_position+Vector3.UP*.9-global_position
		velocity=to.normalized()*24
		if to.length()<1.55:
			_homing.take_damage(equipment.get_damage_multiplier()*(2 if acai_left>0 else 1),global_position);_homing_left=0;velocity=Vector3(0,9,0);_invulnerability_timer=maxf(.35,_invulnerability_timer)
	if _attack_time>0:
		var old:=_attack_time;_attack_time=maxf(0,_attack_time-delta)
		if old>.24 and _attack_time<=.24 and _homing_left<=0:_melee()
	move_and_slide()
	if _homing_left>0 and is_on_wall():_homing_left=0
	_anim.play("attack" if _attack_time>0 else ("hurt" if _hitstun>0 else ("jump" if not is_on_floor() else ("run" if Vector2(velocity.x,velocity.z).length()>.4 else "idle"))))
	_anim.speed_scale=1.5 if boosting else 1.0
	if position.y<get_parent().sector_floor()-8:fall_back()
func attack() -> void:
	_attack_cooldown=maxf(.55*equipment.get_attack_cooldown_multiplier(),get_attack_cooldown_floor());_attack_time=.38;Sfx.swing()
	if not is_on_floor():
		_homing=get_parent().find_target(global_position+Vector3.UP,forward,11,false)
		if is_instance_valid(_homing):_homing_left=.55;_invulnerability_timer=maxf(.55,_invulnerability_timer)
func _melee() -> void:
	for target in get_tree().get_nodes_in_group("lab3d_enemies"):
		if not target.is_inside_tree() or not target.is_visible_in_tree() or target.dead:continue
		var gap:Vector3=target.global_position-global_position
		if gap.length()<3.0 and Vector3(gap.x,0,gap.z).normalized().dot(forward)>-.05:target.take_damage(equipment.get_damage_multiplier()*(2 if acai_left>0 else 1),global_position)
func take_damage(amount:float,source:Vector3) -> void:
	if _dead or _finished or get_parent().intro_active or _invulnerability_timer>0:return
	if equipment.consume_leaf():_invulnerability_timer=1.0;Sfx.checkpoint();return
	if acai_left>0:acai_left=0;_invulnerability_timer=1.5;Sfx.checkpoint();return
	if shop_shield_hits>0:shop_shield_hits-=1;_invulnerability_timer=1.0;health_changed.emit(health,MAX_HEALTH);return
	health=maxi(0,health-int(amount));health_changed.emit(health,MAX_HEALTH);Sfx.hurt()
	_invulnerability_timer=1.5+equipment.get_invulnerability_bonus();_hitstun=.25;_cancel_attack()
	var away:Vector3=(global_position-source);away.y=0;velocity=away.normalized()*6+Vector3.UP*4
	get_parent().shake(.18)
	if health<=0:
		_dead=true;died.emit();await get_tree().create_timer(.65).timeout
		if is_inside_tree():respawn()
func fall_back() -> void:
	if _dead:return
	get_parent().deaths+=1;health=maxi(1,health-1);respawn(false)
func respawn(full_health:bool=true) -> void:
	_dead=false;position=respawn_position;velocity=Vector3.ZERO;_invulnerability_timer=2;_hitstun=0;boost=100;acai_left=0;_cancel_attack()
	if full_health:health=MAX_HEALTH
	model.visible=true;health_changed.emit(health,MAX_HEALTH);respawned.emit();get_parent().snap_camera()
func _cancel_attack() -> void:_attack_time=0;_homing_left=0;_homing=null
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
func grant_shop_shield(hits:int) -> bool:
	if shop_shield_hits>0:return false
	shop_shield_hits=hits;health_changed.emit(health,MAX_HEALTH);return true
func finish_level() -> void:_finished=true;velocity=Vector3.ZERO;_cancel_attack();equipment.clear_temporary();_anim.play("idle")

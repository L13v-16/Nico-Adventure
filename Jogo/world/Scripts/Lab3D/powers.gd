extends Node
var selected:="ice"
var cooldown:=0.0
var temporary_fire:=0.0
func _process(delta:float) -> void:
	cooldown=maxf(0,cooldown-delta);temporary_fire=maxf(0,temporary_fire-delta)
	if not can_control():return
	if Input.is_action_just_pressed("element_swap"):selected="fire" if selected=="ice" else "ice";Sfx.select()
	if Input.is_action_pressed("element_cast"):cast()
func has_mastery() -> bool:return true
func has_fire() -> bool:return true
func has_ice() -> bool:return true
func has_any() -> bool:return true
func can_use(_element:String) -> bool:return true
func can_control() -> bool:
	var p:=get_parent();return not get_tree().paused and not p.is_dead() and not p._finished and not p.get_parent().intro_active
func grant_fruit(seconds:float=20) -> void:temporary_fire=seconds;selected="fire"
func refresh_available(preferred:String="") -> void:
	if preferred!="":selected=preferred
func cast() -> bool:
	if not can_control() or cooldown>0:return false
	var p:=get_parent();var level:=p.get_parent()
	var minimum:float=p.get_attack_cooldown_floor()
	if minimum>0 and p._attack_cooldown>0:return false
	cooldown=maxf(.5*p.equipment.get_element_cooldown_multiplier(),minimum);p._attack_cooldown=maxf(p._attack_cooldown,minimum)
	var target:Node3D=level.find_target(p.global_position+Vector3.UP,p.forward,23,true)
	var shot:=preload("res://world/Scripts/Lab3D/projectile.gd").new();shot.friendly=true;shot.element=selected;shot.source=p
	shot.position=p.global_position+Vector3.UP*1.15+p.forward*.7
	var to:Vector3=(target.aim_point() if is_instance_valid(target) and target.has_method("aim_point") else (target.global_position+Vector3.UP if is_instance_valid(target) else shot.position+p.forward*25))-shot.position
	shot.flight=to.normalized()*25;shot.freeze_duration=maxf(3,p.equipment.get_freeze_duration());level.add_child(shot);Sfx.swing();return true

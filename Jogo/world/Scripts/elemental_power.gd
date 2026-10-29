extends Node
## Frutas liberam disparos temporários; o altar libera os dois sem limite.
var selected:="fire"
var temporary_fire:=0.0
var cooldown:=0.0
var cooldown_duration:=.42
var _player:CharacterBody2D
var _hud:CanvasLayer
var _view:Control
func _ready() -> void:
	_player=get_parent()
	for pair in [["element_swap",KEY_Q],["element_cast",KEY_K],["jose_command",KEY_C]]:
		if not InputMap.has_action(pair[0]):
			InputMap.add_action(pair[0])
			var event:=InputEventKey.new()
			event.physical_keycode=pair[1]
			InputMap.action_add_event(pair[0],event)
	_hud=CanvasLayer.new()
	_hud.layer=23
	add_child(_hud)
	_view=preload("res://world/Scripts/elemental_hud.gd").new()
	_view.powers=self
	_hud.add_child(_view)
	_player.respawned.connect(func():temporary_fire=0;cooldown=0)
	_update_hud()
func has_mastery() -> bool:
	var level:=_player.get_parent()
	# No Submundo, o altar precisa ser ativado nesta passagem. Um save de
	# uma visita anterior não deve antecipar a aquisição mostrada na cena.
	if level.has_method("has_elemental_mastery"):return level.has_elemental_mastery()
	return Save.has_story_flag("elemental_mastery")
func has_fire() -> bool:return has_mastery() or temporary_fire>0
func ice_time_left() -> float:
	var acai:Node=_player._active_acai
	var regular:float=acai.get_time_left() if is_instance_valid(acai) else 0.0
	return maxf(regular,_player.equipment.get_frost_boost_left())
func has_ice() -> bool:return has_mastery() or ice_time_left()>0
func has_any() -> bool:return has_fire() or has_ice()
func can_use(element:String) -> bool:
	return has_ice() if element=="ice" else (has_fire() if element=="fire" else false)
func refresh_available(preferred:String="") -> void:
	if preferred!="" and can_use(preferred):selected=preferred
	if not can_use(selected):selected="ice" if has_ice() else "fire"
	_update_hud()
func grant_fruit(seconds:float=20.0) -> void:
	temporary_fire=maxf(temporary_fire,seconds)
	refresh_available("fire")
func _process(delta:float) -> void:
	cooldown=maxf(0,cooldown-delta)
	temporary_fire=maxf(0,temporary_fire-delta)
	refresh_available()
func _physics_process(_delta:float) -> void:
	if not can_control():return
	if Input.is_action_just_pressed("element_swap"):swap()
	if Input.is_action_pressed("element_cast"):cast()
func can_control() -> bool:
	var level:=_player.get_parent()
	return not get_tree().paused and _player.is_physics_processing() and not _player.is_dead() and not _player._finished and level.get("intro_active")!=true and level.get("completed")!=true
func swap() -> void:
	if not has_fire() or not has_ice():return
	selected="ice" if selected=="fire" else "fire"
	Sfx.select()
	_update_hud()
func cast() -> bool:
	refresh_available()
	if not can_control() or cooldown>0 or not can_use(selected):return false
	var minimum:float=_player.get_attack_cooldown_floor()
	if minimum>0 and _player._attack_cooldown>0:return false
	cooldown=maxf(.42*_player.equipment.get_element_cooldown_multiplier(),minimum)
	cooldown_duration=cooldown
	if minimum>0:_player._attack_cooldown=maxf(_player._attack_cooldown,minimum)
	var shot:=preload("res://world/Scripts/elemental_projectile.gd").new()
	shot.element=selected
	shot.freeze_duration=maxf(3.0,_player.equipment.get_freeze_duration())
	var side:float=_player._facing
	shot.position=_player.global_position+Vector2(side*18,-7)
	shot.flight=Vector2(side*430,0)
	shot.source=_player
	_player.get_parent().add_child(shot)
	Sfx.swing()
	return true
func _update_hud() -> void:
	if is_instance_valid(_view):_view.refresh()

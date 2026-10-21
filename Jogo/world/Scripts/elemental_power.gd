extends Node
## Frutas liberam disparos temporários; o altar libera os dois sem limite.
var selected:="fire"
var temporary_fire:=0.0
var cooldown:=0.0
var _player:CharacterBody2D
var _hud:CanvasLayer
var _label:Label
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
	_label=Label.new()
	_label.position=Vector2(12,102)
	_label.size=Vector2(225,29)
	_label.add_theme_font_size_override("font_size",9)
	_label.add_theme_color_override("font_color",Color("ffe4b5"))
	_label.add_theme_color_override("font_shadow_color",Color("171321"))
	_label.add_theme_constant_override("shadow_offset_x",1)
	_label.add_theme_constant_override("shadow_offset_y",1)
	_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_label)
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
	cooldown=0.42
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
	if _label==null:return
	_hud.visible=not _player._finished and has_any() and not get_tree().paused and _player.get_parent().get("intro_active")!=true
	var boss:=_player.get_parent().get_node_or_null("Boss")
	var in_boss:bool=is_instance_valid(boss) and boss.get("active")==true
	_label.position.y=(134 if in_boss else 100) if ice_time_left()>0 else (102 if in_boss else 91)
	var title:="FOGO" if selected=="fire" else "GELO"
	if has_mastery():_label.text="K: "+title+"   Q: alternar\nPoderes do altar · sem consumir itens"
	elif has_fire() and has_ice():_label.text="K: "+title+"   Q: alternar\nAçaí: %ds · Fruta-do-dragão: %ds"%[int(ceilf(ice_time_left())),int(ceilf(temporary_fire))]
	elif has_ice():_label.text="K: GELO · %ds\nPoder do açaí"%int(ceilf(ice_time_left()))
	else:_label.text="K: FOGO · %ds\nFruta-do-dragão"%int(ceilf(temporary_fire))

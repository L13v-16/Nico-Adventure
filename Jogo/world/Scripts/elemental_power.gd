extends Node
## O templo ensina os disparos permanentemente; a fruta ensina fogo temporário.
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
func has_mastery() -> bool:return Save.has_story_flag("elemental_mastery")
func has_fire() -> bool:return has_mastery() or temporary_fire>0
func grant_fruit(seconds:float=20.0) -> void:
	temporary_fire=maxf(temporary_fire,seconds)
	selected="fire"
	_update_hud()
func _process(delta:float) -> void:
	cooldown=maxf(0,cooldown-delta)
	temporary_fire=maxf(0,temporary_fire-delta)
	_update_hud()
func _physics_process(_delta:float) -> void:
	if not can_control():return
	if Input.is_action_just_pressed("element_swap") and has_mastery():swap()
	if Input.is_action_just_pressed("element_cast"):cast()
func can_control() -> bool:
	var level:=_player.get_parent()
	return not get_tree().paused and _player.is_physics_processing() and not _player.is_dead() and not _player._finished and level.get("intro_active")!=true and level.get("completed")!=true
func swap() -> void:
	if not has_mastery():return
	selected="ice" if selected=="fire" else "fire"
	Sfx.select()
	_update_hud()
func cast() -> bool:
	if not can_control() or cooldown>0 or not has_fire():return false
	if selected=="ice" and not has_mastery():return false
	cooldown=0.42
	var shot:=preload("res://world/Scripts/elemental_projectile.gd").new()
	shot.element=selected
	var side:float=_player._facing
	shot.position=_player.global_position+Vector2(side*18,-7)
	shot.flight=Vector2(side*430,0)
	shot.source=_player
	_player.get_parent().add_child(shot)
	Sfx.swing()
	return true
func _update_hud() -> void:
	if _label==null:return
	_hud.visible=not _player._finished and has_fire() and not get_tree().paused and _player.get_parent().get("intro_active")!=true
	var boss:=_player.get_parent().get_node_or_null("Boss")
	_label.position.y=102 if is_instance_valid(boss) and boss.get("active")==true else 91
	var title:="FOGO" if selected=="fire" else "GELO"
	_label.text=("K: "+title+"   Q: alternar\nPoderes do templo · sem consumir itens") if has_mastery() else "K: FOGO · %ds\nFruta-do-dragão"%int(ceilf(temporary_fire))

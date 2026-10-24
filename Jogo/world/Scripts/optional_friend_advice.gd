extends Node2D
## A proximity prompt only. Conversations start exclusively from an E press.
var kind:="beach"
var friend:Node2D
var anchor:=Vector2.ZERO
var dialogue:CanvasLayer
var _level:Node2D
var _player:CharacterBody2D
var _cooldown:=0.0
var _old_timing:=true
var _old_intro:=false
var _old_menu:=true
var _old_pause:=false
var _can_restore:=false
var _power_huds:Dictionary={}

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;z_index=20
	_level=get_parent();_player=_level.player
	add_to_group("friend_advice")
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST

func _point() -> Vector2:
	return friend.global_position if kind=="jose" else anchor

func can_talk() -> bool:
	if is_instance_valid(dialogue) or _cooldown>0 or not is_instance_valid(friend):return false
	if get_tree().paused or _level.intro_active or _level.completed or _player.is_dead() or _player._finished:return false
	if not friend.visible or not _player.is_on_floor():return false
	var boss:=_level.get_node_or_null("Boss")
	if boss!=null and boss.active:return false
	if kind=="jose" and (not friend.rescued or friend.state!="idle" or not friend.is_on_floor()):return false
	var gap:=_player.global_position+Vector2(0,11)-_point()
	if absf(gap.x)>76 or absf(gap.y)>40:return false
	# E keeps its shop and doorway actions wherever those prompts are available.
	for shop in get_tree().get_nodes_in_group("caravan_shops"):
		if shop.get_parent()==_level and shop._can_open():return false
	var forge:=_level.get_node_or_null("Forge")
	if forge!=null and is_instance_valid(forge.hall) and forge.hall._near_door()!=0:return false
	return true

func _process(delta:float) -> void:
	_cooldown=maxf(0,_cooldown-delta)
	if is_instance_valid(friend):global_position=_point()+Vector2(0,-78)
	queue_redraw()

func _unhandled_input(event:InputEvent) -> void:
	if event.is_echo() or not event.is_action_pressed("interagir") or not can_talk():return
	get_viewport().set_input_as_handled();open()

func open() -> void:
	if not can_talk():return
	_old_timing=_level._timing;_old_intro=_level.intro_active
	_old_menu=_level.pause_menu.can_open;_old_pause=get_tree().paused;_can_restore=true
	_level._timing=false;_level.intro_active=true;_level.pause_menu.can_open=false
	_player._cancel_attack();_player.velocity=Vector2.ZERO;_player.anim.play(&"idle")
	for hud in [_player.elements._hud,_player._freeze_hud]:
		_power_huds[hud]=hud.visible;hud.hide()
	get_tree().paused=true
	match kind:
		"beach":dialogue=preload("res://world/Scripts/beach_arrival.gd").new()
		"magic":dialogue=preload("res://world/Scripts/magic_dialogue.gd").new()
		"jose":
			dialogue=preload("res://world/Scripts/underworld_dialogue.gd").new()
			dialogue.mode="advice"
	dialogue.name="JoseAdvice" if kind=="jose" else "AraraAdvice"
	dialogue.auto_progress=false
	dialogue.finished.connect(_close,CONNECT_ONE_SHOT)
	_level.add_child(dialogue)

func _close() -> void:
	dialogue=null;_cooldown=.35;_restore()

func _restore() -> void:
	if not _can_restore:return
	_can_restore=false
	if get_tree()!=null:get_tree().paused=_old_pause
	if not is_instance_valid(_level) or not _level.is_inside_tree():return
	_level._timing=_old_timing;_level.intro_active=_old_intro;_level.pause_menu.can_open=_old_menu
	for hud in _power_huds:
		if is_instance_valid(hud):hud.visible=_power_huds[hud]
	_power_huds.clear()
	_player._invulnerability_timer=maxf(_player._invulnerability_timer,.3)

func _exit_tree() -> void:
	if is_instance_valid(dialogue):dialogue._finish()
	_restore()

func _draw() -> void:
	if not can_talk():return
	draw_style_box(preload("res://world/Scripts/ui_style.gd").panel_style(),Rect2(-59,-16,118,21))
	draw_string(ThemeDB.fallback_font,Vector2(-57,-2),"E · José" if kind=="jose" else "E · Arara Minas",HORIZONTAL_ALIGNMENT_CENTER,114,9,Color("fff0c9"))

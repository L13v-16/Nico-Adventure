extends Node2D
## The exterior doorway leads to an independent, enclosed workshop scene.
const LEFT_DOOR := -264.0
const RIGHT_DOOR := 274.0
const ROOM_OFFSET := Vector2(0,-1700)
const ROOM_LEFT := -334.0
const ROOM_RIGHT := 334.0
var forge:Node2D
var inside:=false
var _player:CharacterBody2D
var _jose:CharacterBody2D
var _building:AnimatedSprite2D
var _hint:Label
var _room:Node2D
var _room_nodes:Array[Node2D]=[]
var _outside_checkpoint:=Vector2.ZERO
var _door_cooldown:=0.0
var _fade_layer:CanvasLayer
var _fade:ColorRect
var _fade_tween:Tween

func _ready() -> void:
	var origin:=global_position
	set_as_top_level(true);global_position=origin
	_player=get_tree().get_first_node_in_group("player")
	_jose=forge.get_parent().get_node("Jose")
	_building=preload("res://world/Scripts/underworld_art.gd").actor("V59/forge_hall",800)
	_building.name="ForgeBuilding";_building.z_index=-2
	add_child(_building);_building.play(&"outside")
	var door:=StaticBody2D.new();door.name="EntranceDoor"
	door.collision_layer=1;door.collision_mask=0;door.position=Vector2(LEFT_DOOR,-110)
	var collider:=CollisionShape2D.new();var shape:=RectangleShape2D.new()
	shape.size=Vector2(12,420);collider.shape=shape;door.add_child(collider);add_child(door)
	_room=preload("res://world/forge_interior.tscn").instantiate()
	_room.name="ForgeInterior";_room.position=ROOM_OFFSET;add_child(_room);_room.hide()
	_hint=preload("res://world/Scripts/ui_style.gd").shadowed_label("",9,Color("ffe4b5"))
	_hint.size=Vector2(136,16);_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;add_child(_hint)
	_fade_layer=CanvasLayer.new();_fade_layer.layer=40;add_child(_fade_layer)
	_fade=ColorRect.new();_fade.color=Color("0e0d17");_fade.modulate.a=0
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter=Control.MOUSE_FILTER_IGNORE;_fade_layer.add_child(_fade)
	_player.respawned.connect(_on_respawn)
	_setup_room.call_deferred()

func _setup_room() -> void:
	# Cherries keep their stable IDs and move into the new room exactly once.
	var level:=forge.get_parent()
	for node in level.get_node("items").get_children():
		if not node is Node2D or node.is_queued_for_deletion():continue
		if node.global_position.x>global_position.x+LEFT_DOOR+20 and node.global_position.x<global_position.x+RIGHT_DOOR-16:
			node.position+=ROOM_OFFSET;_room_nodes.append(node)
	_refresh_presence()

func room_origin() -> Vector2:return global_position+ROOM_OFFSET
func _available() -> bool:
	var level:=forge.get_parent()
	return not get_tree().paused and not level.intro_active and not level.completed and not _player.is_dead() and not _player._finished
func _near_door() -> int:
	var origin:=room_origin() if inside else global_position
	if absf(_player.position.y+11-origin.y)>45:return 0
	if absf(_player.position.x-origin.x-(ROOM_LEFT if inside else LEFT_DOOR))<56:return -1
	if absf(_player.position.x-origin.x-(ROOM_RIGHT if inside else RIGHT_DOOR))<56:return 1
	return 0
func _unhandled_input(event:InputEvent) -> void:
	if not _available() or _door_cooldown>0 or not event.is_action_pressed("interagir"):return
	var side:=_near_door()
	if side==0:return
	get_viewport().set_input_as_handled()
	if inside:
		if side>0 and not forge.complete:forge.get_parent()._show_notice("Fogo, gelo, fogo e gelo: conclua a forja para destrancar esta porta.")
		else:leave(side)
	elif side<0 or forge.complete:enter(side)
func _place_pair(at:Vector2,facing:float) -> void:
	_player.release_vine(false);_player._cancel_attack()
	_player.position=at;_player.velocity=Vector2.ZERO;_player._hitstun_timer=0
	_player._spring_lock=0;_player._jump_buffer_timer=0;_player._facing=facing
	_player.anim.flip_h=facing<0;_player.anim.play(&"idle")
	_player._invulnerability_timer=maxf(_player._invulnerability_timer,.8)
	_jose.position=at+Vector2(-facing*36,11);_jose.velocity=Vector2.ZERO
	_jose.state="idle";_jose._target=null;_jose._safe_spot=_jose.position
	_jose._sprite.play(&"idle");_jose._sprite.flip_h=facing<0
func enter(side:int=-1) -> void:
	if inside or not _available() or (side>0 and not forge.complete):return
	_outside_checkpoint=_player.respawn_position
	inside=true;forge.global_position=room_origin()
	var at:=room_origin()+Vector2(ROOM_LEFT+58 if side<0 else ROOM_RIGHT-58,-11)
	_place_pair(at,1 if side<0 else -1);_player.respawn_position=at
	_refresh_presence();_change_view();Sfx.menu()
	forge.get_parent()._show_notice("FORJA INVERTIDA · Fogo na válvula laranja, gelo na azul. Siga as quatro marcas do piso.")
func leave(side:int=-1) -> void:
	if not inside or (side>0 and not forge.complete):return
	inside=false;forge.global_position=global_position
	var at:=global_position+Vector2(LEFT_DOOR-48 if side<0 else RIGHT_DOOR+64,-11)
	_place_pair(at,-1 if side<0 else 1)
	_player.respawn_position=_outside_checkpoint if side<0 else at
	_refresh_presence();_change_view();Sfx.menu()
	forge.get_parent()._show_notice("De volta ao Submundo. A passagem está aberta." if forge.complete else "Você saiu da forja. A sequência continuará de onde parou.")
func _on_respawn() -> void:
	inside=absf(_player.position.y+11-room_origin().y)<180
	forge.global_position=room_origin() if inside else global_position
	_refresh_presence();_snap_camera()
func _refresh_presence() -> void:
	_room.visible=inside;_room.set_active(inside)
	if not inside:_player.get_node("Camera2D").make_current()
	if is_instance_valid(forge._machine):forge._machine.visible=inside
	if is_instance_valid(forge._label):forge._label.visible=inside
	for name in ["HotValve","ColdValve"]:
		var valve:=forge.get_node_or_null(name)
		if valve!=null:valve.visible=inside;valve.set_deferred("collision_layer",16 if inside else 0)
	for node in _room_nodes:
		if not is_instance_valid(node) or node.is_queued_for_deletion():continue
		node.visible=inside
		if node is Area2D:node.set_deferred("monitoring",inside)
	for bank in forge.get_parent().get_node("Atmosphere").get_children():
		if bank is CanvasLayer:bank.visible=not inside
	_room.set_exit_open(forge.complete)
	forge.queue_redraw()
func _snap_camera() -> void:
	var camera:Camera2D=_player.get_node("Camera2D")
	camera.limit_left=int(global_position.x-384) if inside else -128
	camera.limit_right=int(global_position.x+384) if inside else 8032
	camera.limit_top=int(room_origin().y-400) if inside else -550
	camera.limit_bottom=int(room_origin().y+100) if inside else 310
	camera.zoom=Vector2.ONE*(1.25 if inside else 1.5)
	_player._camera_base_offset=camera_target()-_player.position if inside else Vector2(55,-38)
	camera.offset=_player._camera_base_offset
	camera.reset_smoothing();camera.force_update_scroll()
	if inside:_room.set_active(true)
func _change_view() -> void:
	_snap_camera();_door_cooldown=.4
	if _fade_tween!=null and _fade_tween.is_running():_fade_tween.kill()
	_fade.modulate.a=1;_fade_tween=create_tween()
	_fade_tween.tween_property(_fade,"modulate:a",0,.3)
func _process(delta:float) -> void:
	_door_cooldown=maxf(0,_door_cooldown-delta)
	_building.play(&"outside")
	_room.set_exit_open(forge.complete)
	var side:=_near_door() if _available() else 0
	_hint.visible=side!=0
	var x:float=(ROOM_LEFT if side<=0 else ROOM_RIGHT) if inside else (LEFT_DOOR if side<=0 else RIGHT_DOOR)
	_hint.position=Vector2(x-68,-68)+(ROOM_OFFSET if inside else Vector2.ZERO)
	_hint.text=("E · Sair da forja" if inside else "E · Entrar na forja") if side<0 or forge.complete else "Saída trancada"
func camera_target() -> Vector2:
	return room_origin()+Vector2(clampf(_player.position.x-global_position.x+30,-115,115),-70)

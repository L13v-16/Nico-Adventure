extends Node2D
## A real doorway stages both companions inside the forge's cutaway interior.
const LEFT_DOOR := -264.0
const RIGHT_DOOR := 274.0
var forge: Node2D
var inside := false
var _player: CharacterBody2D
var _jose: CharacterBody2D
var _building: AnimatedSprite2D
var _hint: Label
var _room_nodes: Array[Node2D] = []

func _ready() -> void:
	_player=get_tree().get_first_node_in_group("player")
	_jose=forge.get_parent().get_node("Jose")
	_building=preload("res://world/Scripts/underworld_art.gd").actor("V59/forge_hall",800)
	_building.name="ForgeBuilding";_building.z_index=-2
	add_child(_building);_building.play(&"outside")
	var door:=StaticBody2D.new();door.name="EntranceDoor"
	door.collision_layer=1;door.collision_mask=0;door.position=Vector2(LEFT_DOOR,-110)
	var collider:=CollisionShape2D.new();var shape:=RectangleShape2D.new()
	shape.size=Vector2(12,420);collider.shape=shape;door.add_child(collider);add_child(door)
	_hint=preload("res://world/Scripts/ui_style.gd").shadowed_label("",9,Color("ffe4b5"))
	_hint.position=Vector2(LEFT_DOOR-65,-64);_hint.size=Vector2(130,16)
	_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;add_child(_hint)
	_player.respawned.connect(_on_respawn)
	_setup_room.call_deferred()

func _setup_room() -> void:
	var level:=forge.get_parent()
	for node in level.get_children():
		if not node is Node2D or node==forge:continue
		if node.get_script()==preload("res://world/Scripts/underworld_steam.gd") or (node.is_in_group("enemies") and node.position.x>global_position.x+LEFT_DOOR and node.position.x<global_position.x+RIGHT_DOOR):_room_nodes.append(node)
	for parent_name in ["items","Checkpoints"]:
		for node in level.get_node(parent_name).get_children():
			if not node is Node2D or node.is_queued_for_deletion():continue
			if node.global_position.x>global_position.x+LEFT_DOOR+20 and node.global_position.x<global_position.x+RIGHT_DOOR-16:_room_nodes.append(node)
	_refresh_presence()

func _available() -> bool:
	var level:=forge.get_parent()
	return not get_tree().paused and not level.intro_active and not level.completed and not _player.is_dead() and not _player._finished

func _near_door() -> int:
	if absf(_player.position.y+11-global_position.y)>45:return 0
	if absf(_player.position.x-global_position.x-LEFT_DOOR)<64:return -1
	if absf(_player.position.x-global_position.x-RIGHT_DOOR)<64:return 1
	return 0

func _unhandled_input(event:InputEvent) -> void:
	if not _available() or not event.is_action_pressed("interagir"):return
	var side:=_near_door()
	if side==0:return
	get_viewport().set_input_as_handled()
	if inside:
		if side>0 and not forge.complete:
			forge.get_parent()._show_notice("Ative a forja com fogo, gelo, fogo e gelo para abrir a saída.")
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
	inside=true
	var at:=Vector2(global_position.x+(LEFT_DOOR+60 if side<0 else RIGHT_DOOR-60),global_position.y-11)
	_place_pair(at,1 if side<0 else -1)
	_refresh_presence();Sfx.menu()
	forge.get_parent()._show_notice("Forja Invertida · Fogo na válvula laranja, gelo na azul. Repita a sequência do chão.")

func leave(side:int=-1) -> void:
	if not inside or (side>0 and not forge.complete):return
	inside=false
	var at:=Vector2(global_position.x+(LEFT_DOOR-48 if side<0 else RIGHT_DOOR+64),global_position.y-11)
	_place_pair(at,-1 if side<0 else 1)
	_refresh_presence();Sfx.menu()

func _on_respawn() -> void:
	inside=_player.position.x>global_position.x+LEFT_DOOR+15 and _player.position.x<global_position.x+RIGHT_DOOR-15
	_refresh_presence()

func _refresh_presence() -> void:
	if is_instance_valid(forge._machine):forge._machine.visible=inside
	if is_instance_valid(forge._label):forge._label.visible=inside
	for name in ["HotValve","ColdValve"]:
		var valve:=forge.get_node_or_null(name)
		if valve!=null:valve.visible=inside;valve.set_deferred("collision_layer",16 if inside else 0)
	for node in _room_nodes:
		if not is_instance_valid(node) or node.is_queued_for_deletion():continue
		node.visible=inside
		if node is Area2D:node.set_deferred("monitoring",inside)
		else:node.set_physics_process(inside)
	forge.queue_redraw()

func _process(_delta:float) -> void:
	if _building==null:return
	_building.play(&"working" if inside and forge.complete else (&"inside" if inside else &"outside"))
	var side:=_near_door() if _available() else 0
	_hint.visible=side!=0
	_hint.position.x=(LEFT_DOOR if side<=0 else RIGHT_DOOR)-65
	_hint.text=("E · Sair da forja" if inside else "E · Entrar na forja") if side<0 or forge.complete else "Ative a forja"
	# Walking out through the unlocked far door also restores the exterior.
	if inside and forge.complete and _player.position.x>global_position.x+RIGHT_DOOR+35:leave(1)

func camera_target() -> Vector2:
	return Vector2(clampf(_player.position.x+40,global_position.x-140,global_position.x+140),global_position.y-155)

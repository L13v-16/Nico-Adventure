extends Node2D
## Persistent room instances: no scene reload, no duplicate enemies or rewards.
const BOUNDS:=[Vector2(-128,1480),Vector2(1500,3620),Vector2(3650,5440),Vector2(5480,7600)]
const TITLES:=["Recepção e segurança","Setor de experimentação","Fábrica de modificações","Pesquisa avançada"]
# Source door x: destination room, safe arrival x, facing, destination label.
const ROUTES:={1430:[1,1610,1],1550:[0,1365,-1],3570:[2,3765,1],3700:[1,3505,-1],5390:[3,5600,1],5530:[2,5325,-1]}
var current:=0
var transitioning:=false
var cooldown:=0.0
var rooms:Array[Node2D]=[]
var _fade:ColorRect
var _caption:Label
var _level:Node2D
func _ready() -> void:
	_level=get_parent()
	for i in 4:
		var room:=preload("res://world/lab_room.tscn").instantiate();room.sector=i;room.bounds=BOUNDS[i];room.title=TITLES[i]
		room.name="Sector%d"%(i+1);add_child(room);rooms.append(room)
	var overlay:=CanvasLayer.new();overlay.layer=35;add_child(overlay)
	_fade=ColorRect.new();_fade.size=Vector2(640,360);_fade.color=Color("101a26");_fade.modulate.a=0
	_fade.mouse_filter=Control.MOUSE_FILTER_IGNORE;overlay.add_child(_fade)
	_caption=Label.new();_caption.position=Vector2(100,162);_caption.size=Vector2(440,40);_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_caption.add_theme_font_size_override("font_size",16);_caption.modulate=Color("e4ebdb");_fade.add_child(_caption)
	_level.player.respawned.connect(_on_respawn)
	refresh_presence();apply_camera()
func sector_at(x:float) -> int:
	for i in 4:
		if x>=BOUNDS[i].x and x<=BOUNDS[i].y:return i
	return current
func door_label(x:int) -> String:
	if not ROUTES.has(x):return "entrar"
	return "voltar" if int(ROUTES[x][0])<current else "entrar"
func travel(door:Node2D) -> bool:
	var key:=roundi(door.position.x)
	if not ROUTES.has(key):return false
	if transitioning or cooldown>0 or _level.player.is_dead():return true
	if not _level.access_card:
		_level.show_lab_notice("Encontre o cartão laranja antes de entrar no setor de experimentação.");return true
	if _level.get_node("Boss").active:
		_level.show_lab_notice("O protocolo de contenção bloqueou as portas.");return true
	var route:Array=ROUTES[key]
	transitioning=true;_level.pause_menu.can_open=false
	var actor:CharacterBody2D=_level.player
	actor.release_vine(false);actor._cancel_attack();actor.velocity=Vector2.ZERO
	actor.set_physics_process(false);actor.process_mode=Node.PROCESS_MODE_DISABLED
	door.activated=true;door._sprite.texture=preload("res://world/Scripts/lab_art.gd").texture("door_open")
	_caption.text=TITLES[int(route[0])].to_upper();Sfx.play("lab_door",-8)
	var tween:=create_tween();tween.tween_property(_fade,"modulate:a",1,.18)
	await tween.finished
	current=int(route[0]);actor.position=Vector2(route[1],89);actor.respawn_position=actor.position
	# A checkpoint in an earlier room must not prevent a newly reached flag saving.
	_level.active_checkpoint=null
	actor._hitstun_timer=0;actor._spring_lock=0;actor._jump_buffer_timer=0;actor._facing=float(route[2]);actor._camera_look=0
	actor.anim.flip_h=actor._facing<0;actor.anim.play(&"idle");actor._invulnerability_timer=maxf(actor._invulnerability_timer,1.0)
	refresh_presence();apply_camera();_level.frame_camera(0,true)
	await get_tree().create_timer(.12).timeout
	tween=create_tween();tween.tween_property(_fade,"modulate:a",0,.26);await tween.finished
	actor.process_mode=Node.PROCESS_MODE_INHERIT;actor.set_physics_process(true);transitioning=false;cooldown=.5;_level.pause_menu.can_open=true
	_level.show_lab_notice(TITLES[current]+" · E na porta permite voltar ao setor anterior.",4)
	return true
func _process(delta:float) -> void:cooldown=maxf(0,cooldown-delta)
func _on_respawn() -> void:
	current=sector_at(_level.player.position.x);refresh_presence();apply_camera();_level.frame_camera(0,true)
func refresh_presence() -> void:
	for i in 4:rooms[i].visible=i==current
	for group in ["lab_devices","lab_enemies"]:
		for node in get_tree().get_nodes_in_group(group):
			if node.get_parent()!=_level:continue
			var present:bool=sector_at(node.position.x)==current
			node.visible=present;node.set_physics_process(present)
	var boss:Node2D=_level.get_node("Boss")
	boss.visible=current==3;boss.set_physics_process(current==3)
func apply_camera() -> void:
	var camera:Camera2D=_level.player.get_node("Camera2D")
	camera.limit_left=int(BOUNDS[current].x);camera.limit_right=int(BOUNDS[current].y)
	camera.limit_top=-300;camera.limit_bottom=220

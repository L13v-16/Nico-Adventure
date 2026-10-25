extends Node3D
## The public lab_05 scene remains the campaign entry point and save identity.
const Layout=preload("res://world/Scripts/Lab3D/layout.gd")
const Art=preload("res://world/Scripts/Lab3D/models.gd")
var level_id:="fase_5"
var level_name:="Fase 5 — Laboratório dos Executivos 3D"
var pause_on_focus_loss:=true
var intro_active:=true
var completed:=false
var access_card:=false
var room_puzzles:Dictionary={}
var _card_label:Label
var carried_cell:Node3D
var sector:=0
var checkpoint_sector:=0
var roof_y:=26.0
var sectors:Array[Node3D]=[]
var player:CharacterBody3D
var boss:CharacterBody3D
var hud:CanvasLayer
var game_hud:Control
var pause_menu:CanvasLayer
var shop:CanvasLayer
var wagon:Node3D
var rescue_chamber:Node3D
var front_door:Node3D
var camera:Camera3D
var camera_yaw:=0.0
var _pitch:=-.40
var _orbit_idle:=0.0
var _camera_rig:Node3D
var _pitch_rig:Node3D
var _arm:SpringArm3D
var _hint:Label
var _status:Label
var _notice:Label
var _sector_label:Label
var _fade:ColorRect
var _move_status:Label
var _boss_back:ColorRect
var _lg17_badge:TextureRect
var _target_ring:MeshInstance3D
var _notice_left:=0.0
var _shake:=0.0
var _time:=0.0
var _shop_met:=false
var _shop_gone:=false
var _transitioning:=false
var _cutscene:Node3D
var _results:CanvasLayer
var total_gems:=0
var total_enemies:=0
var cherry_ids:Array[String]=[]
var total_secrets:=6
var secrets_found:=0
var defeated:=0
var deaths:=0
func _ready() -> void:
	_world()
	player=preload("res://world/Scripts/Lab3D/player.gd").new();player.name="Player";player.position=Vector3(0,.05,5);add_child(player)
	player.health_changed.connect(_health);player.gem_collected.connect(func(_count):_wallet());player.cherry_balance_changed.connect(func(_balance):_wallet());player.died.connect(func():deaths+=1)
	player.respawned.connect(_respawned)
	Layout.build(self)
	preload("res://world/Scripts/general_details.gd").install_lab(self)
	for index in [1,4,5]:
		var puzzle:=preload("res://world/Scripts/Lab3D/room_puzzle.gd").new();puzzle.level=self;puzzle.sector=index;room_puzzles[index]=puzzle;sectors[index].add_child(puzzle)
	if Save.is_free_mode():
		for id in cherry_ids:
			if Save.has_collected_cherry(level_id,id):player.gems+=1
	boss=preload("res://world/Scripts/Lab3D/boss.gd").new();boss.name="Boss";boss.level=self;boss.position=Vector3(0,roof_y,-242);add_child(boss)
	_camera_setup();_hud_setup()
	pause_menu=preload("res://world/Scripts/pause_menu.gd").new();add_child(pause_menu);pause_menu.can_open=false;pause_menu.restart_requested.connect(restart)
	shop=preload("res://world/Scripts/Lab3D/shop.gd").new();shop.level=self;add_child(shop)
	var music:=preload("res://world/Scripts/Lab3D/music.gd").new();add_child(music)
	_target_ring=Art.ring(self,"TargetReticle",Vector3.ZERO,.65,"aee8e4",.6);_target_ring.hide()
	_refresh_sectors();snap_camera();_wallet();_health(3,3)
	_start_sequence.call_deferred()
func _world() -> void:
	var environment:=WorldEnvironment.new();var env:=Environment.new();environment.environment=env
	var sky:=Sky.new();var sky_mat:=ProceduralSkyMaterial.new();sky_mat.sky_top_color=Color("476e9e");sky_mat.sky_horizon_color=Color("b0c6c9");sky_mat.ground_horizon_color=Color("b0c6c9");sky_mat.ground_bottom_color=Color("496f83");sky.sky_material=sky_mat
	env.background_mode=Environment.BG_SKY;env.sky=sky;env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("b8d0d5");env.ambient_light_energy=.38
	env.fog_enabled=true;env.fog_density=.0015;env.fog_light_color=Color("a9bdcc");add_child(environment)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-32,0);sun.light_color=Color("ffedd2");sun.light_energy=.95;sun.shadow_enabled=true;sun.directional_shadow_max_distance=90;add_child(sun)
	Art.box(self,"Ocean",Vector3(0,-13,-120),Vector3(1000,.2,1000),"387d99",.25)
	for i in 22:
		var side:=-1 if i%2 else 1;var x:float=(145+i%4*12) if side>0 else -(45+i%4*12);var z:float=-25-i*14;var h:float=20+i%6*8
		var tower:=Art.box(self,"DistantBuilding",Vector3(x,h*.5-8,z),Vector3(12,h,15),"678292")
		var facade:=ShaderMaterial.new();facade.shader=preload("res://world/Scripts/Lab3D/city.gdshader");tower.material_override=facade
		Art.box(self,"TowerRoof",Vector3(x,h-7.5,z),Vector3(12.5,.7,15.5),"334e63",.3)
		Art.cylinder(self,"TowerMast",Vector3(x+2,h-5,z),.11,5,"8fa7ac",-1,.4)
func _camera_setup() -> void:
	_camera_rig=Node3D.new();add_child(_camera_rig)
	_pitch_rig=Node3D.new();_camera_rig.add_child(_pitch_rig)
	_arm=SpringArm3D.new();_arm.spring_length=8;_arm.margin=.3;_arm.collision_mask=1
	var sphere:=SphereShape3D.new();sphere.radius=.25;_arm.shape=sphere;_arm.add_excluded_object(player.get_rid());_pitch_rig.add_child(_arm)
	camera=Camera3D.new();camera.fov=67;camera.near=.08;camera.far=450;_arm.add_child(camera);camera.make_current()
func _hud_setup() -> void:
	hud=CanvasLayer.new();hud.layer=20;add_child(hud)
	game_hud=preload("res://prefabs/game_hud.tscn").instantiate();hud.add_child(game_hud);game_hud.configure_intro("LABORATÓRIO DOS EXECUTIVOS",5)
	_hint=_ui_label(Vector2(12,338),Vector2(616,20),9);_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_hint.z_index=2
	var footer:=ColorRect.new();footer.position=Vector2(0,333);footer.size=Vector2(640,27);footer.color=Color("101e2b",.88);footer.z_index=1;footer.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(footer)
	_sector_label=_ui_label(Vector2(168,60),Vector2(290,18),10)
	_card_label=_ui_label(Vector2(168,81),Vector2(430,16),8)
	_status=_ui_label(Vector2(178,60),Vector2(440,56),10);_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_status.z_index=2
	_boss_back=ColorRect.new();_boss_back.position=Vector2(174,57);_boss_back.size=Vector2(448,61);_boss_back.color=Color("101e2b",.92);_boss_back.z_index=1;_boss_back.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(_boss_back);_boss_back.hide()
	_lg17_badge=TextureRect.new();_lg17_badge.name="LG17SupplyHint";_lg17_badge.texture=preload("res://world/Scripts/polish99_art.gd").cell("presentation",15);_lg17_badge.material=preload("res://world/Scripts/polish99_art.gd").material();_lg17_badge.position=Vector2(575,242);_lg17_badge.size=Vector2(48,64);_lg17_badge.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;_lg17_badge.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;_lg17_badge.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(_lg17_badge);_lg17_badge.hide()
	var dose_text:=Label.new();dose_text.text="LG-17";dose_text.position=Vector2(0,64);dose_text.size=Vector2(48,14);dose_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;dose_text.add_theme_font_size_override("font_size",10);dose_text.add_theme_color_override("font_color",Color("9cf6bf"));_lg17_badge.add_child(dose_text)

	_notice=_ui_label(Vector2(168,133),Vector2(392,36),10);_notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;_notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_move_status=_ui_label(Vector2(13,302),Vector2(600,20),8)
	_move_status.text=Controls.hint("ESPAÇO ×2: PULO DUPLO · J: GIRO · SHIFT/CTRL: DESLIZE / QUEDA",true)
	var overlay:=CanvasLayer.new();overlay.layer=75;add_child(overlay);_fade=ColorRect.new();_fade.color=Color("101e2b",0);_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_fade.mouse_filter=Control.MOUSE_FILTER_IGNORE;overlay.add_child(_fade)
func _ui_label(at:Vector2,size:Vector2,font_size:int) -> Label:
	var label:=Label.new();label.add_theme_font_size_override("font_size",font_size);label.add_theme_color_override("font_color",Color("f4e7cb"));label.add_theme_color_override("font_shadow_color",Color("101b29"));label.add_theme_constant_override("shadow_offset_x",1);label.add_theme_constant_override("shadow_offset_y",1);label.add_theme_constant_override("line_spacing",2);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(label);label.position=at;label.size=size;return label
func _start_sequence() -> void:
	var skip:=Save.consume_skip_intro()
	if not skip or not Save.has_story_flag("lab_dimension_breach_seen"):
		var sequence:=play_cutscene("arrival");await sequence.finished
		Save.set_story_flag("lab_arrived");Save.set_story_flag("lab_entrance_breached");Save.set_story_flag("lab_3d_hatching_seen");Save.set_story_flag("lab_dimension_breach_seen")
	else:open_service_door()
	get_tree().paused=true;pause_menu.can_open=false;game_hud.start_intro();await game_hud.intro_finished
	intro_active=false;get_tree().paused=false;pause_menu.can_open=true;Sfx.start();notice("WASD ou setas: mover · Espaço: pular · Espaço de novo: pulo duplo · J: giro. E fala com Oliver.")
func play_cutscene(kind:String) -> Node3D:
	var sequence:=preload("res://world/Scripts/Lab3D/cutscene.gd").new();sequence.name="Lab3DCutscene";sequence.level=self;sequence.mode=kind;_cutscene=sequence
	if kind=="melt":sequence.finished.connect(_boss_melted,CONNECT_ONE_SHOT)
	add_child(sequence);return sequence
func open_service_door() -> void:
	if front_door==null:return
	front_door.set_meta("breached",true)
	var side:=-1.0
	for leaf in front_door.get_children():
		leaf.collision_layer=0;leaf.position=Vector3(side*5,.22,2.7);leaf.rotation=Vector3(PI/2,0,side*.4);side=1
func _process(delta:float) -> void:
	if intro_active or completed:return
	_time+=delta;_notice_left=maxf(0,_notice_left-delta);_notice.visible=_notice_left>0
	_update_camera(delta)
	_lg17_badge.visible=boss.active and boss.dose_unlocked and boss.syringe_ammo<=0
	_lg17_badge.modulate.a=.78+.22*sin(_time*4)
	_status.visible=boss.active;_boss_back.visible=boss.active;_sector_label.visible=not boss.active
	_status.text="LARGATO / ETAPA %d / VIDA %d\n%s"%[boss.phase,int(boss.health),boss.status()]
	_sector_label.text=Layout.NAMES[sector]
	_move_status.modulate=Color("9ae4db") if player._attack_time>0 else Color("f4e7cb")
	_card_label.visible=not boss.active;_card_label.text=access_summary()
	_hint.text=Controls.hint(hint_text(),true)
	pause_menu.set_summary("Laboratório 3D · %d corações · %d cerejas"%[player.health,Save.get_cherry_balance()])
	var target:=find_target(player.position+Vector3.UP,player.forward,20,true)
	_target_ring.visible=is_instance_valid(target) and Input.is_action_pressed("element_cast")
	if is_instance_valid(target):_target_ring.global_position=target.aim_point()+Vector3.UP*.4;_target_ring.look_at(camera.global_position,Vector3.UP);_target_ring.rotate_object_local(Vector3.RIGHT,PI/2)
	if is_instance_valid(wagon) and not _shop_gone:
		var distance:=player.global_position.distance_to(wagon.global_position)
		if distance<12:_shop_met=true
		if _shop_met and (distance>25 or sector!=0):_shop_gone=true;wagon.hide()
func _physics_process(_delta:float) -> void:
	if intro_active or completed or _transitioning:return
	if Input.is_action_just_pressed("lab_throw"):boss.throw_serum()
func _update_camera(delta:float) -> void:
	_orbit_idle+=delta;_shake=maxf(0,_shake-delta)
	var follow:Vector3=player.position+Vector3.UP*1.6+Vector3(clampf(player.velocity.x*.12,-.8,.8),0,-1.8)
	if boss.active:
		follow=follow.lerp(boss.position+Vector3.UP*1.3,.32)
		_arm.spring_length=lerpf(_arm.spring_length,clampf(player.position.distance_to(boss.position)*.4+8,9,16),1-exp(-delta*4))
	else:_arm.spring_length=lerpf(_arm.spring_length,9.5,1-exp(-delta*4))
	if _orbit_idle>1.5 and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		camera_yaw=lerp_angle(camera_yaw,0.0,1-exp(-delta*3));_pitch=lerpf(_pitch,-.40,1-exp(-delta*3))
	_camera_rig.position=_camera_rig.position.lerp(follow,1-exp(-delta*10));_camera_rig.rotation.y=camera_yaw;_pitch_rig.rotation.x=_pitch
	if _shake>0 and Save.is_camera_shake_enabled():camera.h_offset=sin(_time*80)*_shake*.12;camera.v_offset=cos(_time*70)*_shake*.08
	else:camera.h_offset=0;camera.v_offset=0
func snap_camera() -> void:
	if _camera_rig==null:return
	_camera_rig.position=player.position+Vector3.UP*1.65;_camera_rig.rotation.y=camera_yaw;_pitch_rig.rotation.x=_pitch
func _unhandled_input(event:InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not intro_active and not get_tree().paused:
		camera_yaw-=event.relative.x*.004;_pitch=clampf(_pitch-event.relative.y*.003,-.65,.15);_orbit_idle=0
	if intro_active or completed or get_tree().paused or not event.is_action_pressed("interagir"):return
	if sector==0 and not _shop_gone and player.position.distance_to(wagon.global_position)<4:shop.open();get_viewport().set_input_as_handled();return
	var closest:Node3D;var distance:=2.7
	# A held battery must not steal E from the socket immediately ahead of Nico.
	if is_instance_valid(carried_cell):
		for object in get_tree().get_nodes_in_group("lab3d_expansion"):
			if object.sector==sector and object.kind=="power_socket" and not object.active and player.position.distance_to(object.global_position)<3.0:
				if object.interact():get_viewport().set_input_as_handled();return
	for object in get_tree().get_nodes_in_group("lab3d_devices"):
		if object.sector!=sector or object.kind not in ["door","lever","injector","rescue","record"]:continue
		var gap:float=player.position.distance_to(object.global_position)
		if gap<distance:closest=object;distance=gap
	for object in get_tree().get_nodes_in_group("lab3d_expansion"):
		if object.sector!=sector or object==carried_cell or object.kind not in ["power_cell","power_socket","thermal_relay","archive_console","blast_gate"]:continue
		if object.kind=="power_cell" and object.active:continue
		var gap:float=player.position.distance_to(object.global_position)
		if gap<distance:closest=object;distance=gap
	if closest!=null and closest.interact():get_viewport().set_input_as_handled()
	elif is_instance_valid(carried_cell):_drop_carried(false);get_viewport().set_input_as_handled()
func _drop_carried(reset_to_home:bool) -> void:
	if is_instance_valid(carried_cell) and carried_cell.has_method("drop"):carried_cell.drop(reset_to_home)
	carried_cell=null
func enter_sector(index:int) -> void:
	if _transitioning or boss.active or index<0 or index>=Layout.ORIGINS.size() or index==sector:return
	_drop_carried(true)
	_transitioning=true;intro_active=true;player.velocity=Vector3.ZERO;player._cancel_attack();player.reset_traversal();Sfx.play("lab_door",-10)
	var tween:=create_tween();tween.tween_property(_fade,"color:a",1.0,.18);await tween.finished
	var backwards:=Layout.ROUTE.find(index)<Layout.ROUTE.find(sector)
	sector=index;checkpoint_sector=index;player.position=Layout.ORIGINS[index]+Layout.landing(index,backwards);player.respawn_position=player.position;player.forward=Vector3.FORWARD;camera_yaw=0
	_refresh_sectors();snap_camera();player._invulnerability_timer=1.2
	tween=create_tween();tween.tween_property(_fade,"color:a",0.0,.25);await tween.finished
	intro_active=false;_transitioning=false;notice(Layout.NAMES[sector])
func _refresh_sectors() -> void:
	for i in sectors.size():sectors[i].visible=i==sector
	boss.visible=sector==3
func sector_floor() -> float:return Layout.ORIGINS[sector].y
func find_target(from:Vector3,direction:Vector3,reach:float,elemental:bool) -> Node3D:
	var closest:Node3D;var score:=INF
	for node in get_tree().get_nodes_in_group("lab3d_targets" if elemental else "lab3d_enemies"):
		if not is_instance_valid(node) or not node.is_visible_in_tree():continue
		if node.has_method("accepts") and not node.accepts(player.elements.selected if elemental else "attack"):continue
		var at:Vector3=node.aim_point();var offset:=at-from;var flat:=Vector3(offset.x,0,offset.z)
		if offset.length()>reach or flat.length()<.05 or flat.normalized().dot(direction)<.45:continue
		var query:=PhysicsRayQueryParameters3D.create(from,at,1);query.exclude=[player.get_rid()]
		var hit:=get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.collider!=node and (not hit.collider.has_meta("receiver") or hit.collider.get_meta("receiver")!=node):continue
		var rank:=offset.length()*(1.3-flat.normalized().dot(direction))
		if rank<score:closest=node;score=rank
	return closest
func spawn_enemy(at:Vector3,species:String,zone:int) -> Node3D:
	var enemy:=preload("res://world/Scripts/Lab3D/enemy.gd").new();enemy.level=self;enemy.species=species;enemy.sector=zone;enemy.position=at-Layout.ORIGINS[zone];sectors[zone].add_child(enemy);total_enemies+=1;return enemy
func enemy_shot(at:Vector3,target:Vector3,speed:float,source:Node3D=null) -> void:
	var shot:=preload("res://world/Scripts/Lab3D/projectile.gd").new();shot.source=source;shot.position=at;shot.flight=(target-at).normalized()*speed;add_child(shot);Sfx.play("lab_dart",-12)
func spawn_pool(at:Vector3,radius:float,seconds:float) -> Node3D:
	return Layout.device(self,sector,"pool",at-Layout.ORIGINS[sector],{"width":radius*2,"depth":radius*2,"life":seconds})
func spark(at:Vector3,color:String) -> void:
	var effect:=Node3D.new();effect.position=at;add_child(effect)
	for i in 7:
		var piece:=Art.ball(effect,"Spark",Vector3.ZERO,Vector3(.1,.1,.1),color,.6)
		var tween:=create_tween();tween.tween_property(piece,"position",Vector3(sin(i*2.3),.6+float(i%3)*.3,cos(i*2.3))*.8,.35);tween.parallel().tween_property(piece,"scale",Vector3.ZERO,.35)
	get_tree().create_timer(.4).timeout.connect(effect.queue_free)
func shake(seconds:float) -> void:_shake=maxf(_shake,seconds)
func notice(text:String,seconds:float=4.0) -> void:_notice.text=text;_notice_left=seconds;_notice.show()
func _wallet() -> void:
	if game_hud!=null:game_hud.set_cherry_wallet(Save.get_cherry_balance(),player.gems,total_gems)
func _health(current:int,maximum:int) -> void:
	if game_hud!=null:game_hud.set_health(current,maximum);game_hud.set_shop_shield(player.shop_shield_hits)
func _respawned() -> void:
	_drop_carried(true)
	sector=checkpoint_sector;_refresh_sectors();boss.reset_encounter();snap_camera()
func hint_text() -> String:
	if boss.active:return "WASD / setas: mover · Espaço: pular · J: giro · K: poder · Q: alternar · F: dose"
	var nearby:Node3D;var nearest:=4.5
	for object in get_tree().get_nodes_in_group("lab3d_expansion"):
		if object.sector!=sector or object==carried_cell:continue
		var distance:float=player.position.distance_to(object.global_position)
		if distance<nearest and object.hint()!="":nearby=object;nearest=distance
	if nearby!=null:return nearby.hint()
	if is_instance_valid(carried_cell):return "Carregando bateria · E no encaixe para instalar · E longe de objetos para soltar."
	if sector==0:
		if not _shop_gone and player.position.distance_to(wagon.global_position)<4:return "E: conversar com Oliver Gancho · I: mochila"
		for crate in get_tree().get_nodes_in_group("lab3d_crates"):
			if crate.sector==sector and not crate.dead and player.position.distance_to(crate.global_position)<5:return crate.hint()
		return "Espaço ×2: pulo duplo · J: giro quebra caixas · pegue o cartão e suba no elevador."
	if room_puzzles.has(sector):return room_puzzles[sector].hint()
	if sector==1:return "K: GELO forma ponte no veneno · Pule nos inimigos ou use J: giro · E: porta"
	if sector==2:return "E: alavanca · GELO: prensa · a porta superior leva ao arquivo da corporação."
	if sector==4:return "Procure a bateria e instale-a no encaixe para abrir o arquivo. E examina registros."
	if sector==5:return "FOGO aquece o regulador; GELO estabiliza o circuito e ergue a ponte."
	if sector==6:return "Use as coberturas entre as varreduras. GELO pausa sensores e ventiladores."
	return "E junto de Urso para resgatá-lo." if boss.dead else "A cobertura é a arena de Largato. Siga para o centro."
func buy_acai_power() -> bool:player.elements.refresh_available("ice");player.acai_left=12;return true
func _boss_melted() -> void:
	boss.dying=false;boss.dead=true;boss.model.hide();Save.set_story_flag("lab_largato_defeated")
	for child in rescue_chamber._art.get_children():
		if String(child.name).begins_with("Bar"):child.hide()
	notice("Largato derrotado! Urso está livre na câmara ao fundo. E para resgatá-lo.",7)
func rescue_urso() -> void:
	if completed or not boss.dead:return
	completed=true;player.heal_full();player.finish_level();pause_menu.can_open=false;Save.set_story_flag("urso_rescued")
	var stats:=_build_stats();var previous:=Save.get_level_stats(level_id);var best:=Save.mark_level_complete(level_id,stats)
	var new_record:bool=previous.is_empty() or Save.rank_index(best.rank)>Save.rank_index(previous.get("rank","D"))
	player.position=rescue_chamber.global_position+Vector3(3,0,2);player.model.look_at(rescue_chamber.global_position,Vector3.UP)
	var finale:=play_cutscene("ending");await finale.finished
	hud.hide()
	get_tree().paused=true;_results=preload("res://world/Scripts/results_screen.gd").new();add_child(_results)
	_results.next_requested.connect(to_corporation);_results.setup("URSO RESGATADO!",level_name,stats,new_record,true);_results.replay_requested.connect(restart);_results.menu_requested.connect(to_menu);Sfx.finish()
func _build_stats() -> Dictionary:
	var ratio:=float(player.gems)/maxi(1,total_gems)
	return {"rank":Save.compute_rank((ratio+float(defeated)/maxi(1,total_enemies)+float(secrets_found)/total_secrets)/3,_time,720,deaths),"time":_time,"cherries":player.gems,"enemies":defeated,"secrets":secrets_found,"deaths":deaths,"total_cherries":total_gems,"total_enemies":total_enemies,"total_secrets":total_secrets,"perfect":player.gems>=total_gems}
func to_corporation() -> void:
	get_tree().paused=false
	preload("res://world/Scripts/island_routes.gd").travel(get_tree(),level_id,"res://world/corporation_06.tscn",false)
func restart() -> void:get_tree().paused=false;Save.request_play(true,Save.is_free_mode());get_tree().reload_current_scene()
func to_menu() -> void:get_tree().paused=false;get_tree().change_scene_to_file("res://world/main_menu.tscn")
func _notification(what:int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and pause_on_focus_loss and not intro_active and not completed and pause_menu!=null and pause_menu.can_open and not get_tree().paused:pause_menu.open()

func door_access(index:int,destination:int) -> bool:
	# Return routes always remain available; local cards only gate forward doors.
	if Layout.ROUTE.find(destination)<Layout.ROUTE.find(index):return true
	if room_puzzles.has(index):return room_puzzles[index].collected
	return access_card
func door_card_name(index:int,destination:int) -> String:
	if Layout.ROUTE.find(destination)<Layout.ROUTE.find(index):return "RETORNO"
	return room_puzzles[index].CODES[index] if room_puzzles.has(index) else "ACESSO"
func access_summary() -> String:
	var parts:PackedStringArray=[]
	for index in [1,4,5]:parts.append("%s %s"%[room_puzzles[index].CODES[index],"✓" if room_puzzles[index].collected else "—"])
	return "CARTÕES · "+"  /  ".join(parts)

func show_archive(title:String,text:String,images:Array) -> void:
	if intro_active or completed or get_tree().paused:return
	var reader:=preload("res://world/Scripts/Corp2D/archive_panel.gd").new()
	reader.name="LabArchiveReader";reader.level=self;reader.record_title=title;reader.record_text=text;reader.custom_images=images;add_child(reader)

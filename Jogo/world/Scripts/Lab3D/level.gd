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
var _pitch:=-.28
var _orbit_idle:=0.0
var _camera_rig:Node3D
var _pitch_rig:Node3D
var _arm:SpringArm3D
var _hint:Label
var _status:Label
var _notice:Label
var _sector_label:Label
var _fade:ColorRect
var _boost_bar:ColorRect
var _boss_back:ColorRect
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
var total_secrets:=3
var secrets_found:=0
var defeated:=0
var deaths:=0
func _ready() -> void:
	_world()
	player=preload("res://world/Scripts/Lab3D/player.gd").new();player.name="Player";player.position=Vector3(0,.05,5);add_child(player)
	player.health_changed.connect(_health);player.gem_collected.connect(func(_count):_wallet());player.cherry_balance_changed.connect(func(_balance):_wallet());player.died.connect(func():deaths+=1)
	player.respawned.connect(_respawned)
	Layout.build(self)
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
		var side:=-1 if i%2 else 1;var x:float=side*(45+i%4*12);var z:float=-25-i*14;var h:float=20+i%6*8
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
	_sector_label=_ui_label(Vector2(12,58),Vector2(430,18),10)
	_status=_ui_label(Vector2(100,60),Vector2(440,56),10);_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_status.z_index=2
	_boss_back=ColorRect.new();_boss_back.position=Vector2(96,57);_boss_back.size=Vector2(448,61);_boss_back.color=Color("101e2b",.92);_boss_back.z_index=1;_boss_back.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(_boss_back);_boss_back.hide()
	_notice=_ui_label(Vector2(80,133),Vector2(480,36),10);_notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;_notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var bg:=ColorRect.new();bg.position=Vector2(13,317);bg.size=Vector2(100,5);bg.color=Color("233c4a");hud.add_child(bg)
	_boost_bar=ColorRect.new();_boost_bar.position=bg.position;_boost_bar.size=bg.size;_boost_bar.color=Color("7edbcf");hud.add_child(_boost_bar)
	_ui_label(Vector2(13,302),Vector2(230,14),8).text="SHIFT: ACELERAR · BOTÃO DIR.: CÂMERA"
	var overlay:=CanvasLayer.new();overlay.layer=75;add_child(overlay);_fade=ColorRect.new();_fade.color=Color("101e2b",0);_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_fade.mouse_filter=Control.MOUSE_FILTER_IGNORE;overlay.add_child(_fade)
func _ui_label(at:Vector2,size:Vector2,font_size:int) -> Label:
	var label:=Label.new();label.add_theme_font_size_override("font_size",font_size);label.add_theme_color_override("font_color",Color("f4e7cb"));label.add_theme_color_override("font_shadow_color",Color("101b29"));label.add_theme_constant_override("shadow_offset_x",1);label.add_theme_constant_override("shadow_offset_y",1);label.add_theme_constant_override("line_spacing",2);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(label);label.position=at;label.size=size;return label
func _start_sequence() -> void:
	var skip:=Save.consume_skip_intro()
	if not skip or not Save.has_story_flag("lab_3d_hatching_seen"):
		var sequence:=play_cutscene("arrival");await sequence.finished
		Save.set_story_flag("lab_arrived");Save.set_story_flag("lab_entrance_breached");Save.set_story_flag("lab_3d_hatching_seen")
	else:open_service_door()
	get_tree().paused=true;pause_menu.can_open=false;game_hud.start_intro();await game_hud.intro_finished
	intro_active=false;get_tree().paused=false;pause_menu.can_open=true;Sfx.start();notice("WASD ou setas: mover · Espaço: pular · Shift: acelerar. E fala com Oliver.")
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
	_status.visible=boss.active;_boss_back.visible=boss.active;_sector_label.visible=not boss.active
	_status.text="LARGATO / ETAPA %d / VIDA %d\n%s"%[boss.phase,int(boss.health),boss.status()]
	_sector_label.text=Layout.NAMES[sector]+"\nK: "+("GELO" if player.elements.selected=="ice" else "FOGO")+" · Q: alternar"
	_boost_bar.size.x=player.boost
	_hint.text=hint_text()
	pause_menu.set_summary("Laboratório 3D · %d corações · %d cerejas"%[player.health,Save.get_cherry_balance()])
	var target:=find_target(player.position+Vector3.UP,player.forward,11 if not player.is_on_floor() else 20,player.is_on_floor())
	_target_ring.visible=is_instance_valid(target) and (not player.is_on_floor() or Input.is_action_pressed("element_cast"))
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
	var follow:Vector3=player.position+Vector3.UP*1.65
	if boss.active:
		follow=follow.lerp(boss.position+Vector3.UP*1.3,.32)
		_arm.spring_length=lerpf(_arm.spring_length,clampf(player.position.distance_to(boss.position)*.4+8,9,16),1-exp(-delta*4))
	else:_arm.spring_length=lerpf(_arm.spring_length,8.0,1-exp(-delta*4))
	if _orbit_idle>2 and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):camera_yaw=lerp_angle(camera_yaw,0.0,1-exp(-delta*1.5))
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
	for object in get_tree().get_nodes_in_group("lab3d_devices"):
		if object.sector!=sector or object.kind not in ["door","lever","injector","rescue","record"]:continue
		var gap:float=player.position.distance_to(object.global_position)
		if gap<distance:closest=object;distance=gap
	if closest!=null and closest.interact():get_viewport().set_input_as_handled()
func enter_sector(index:int) -> void:
	if _transitioning or boss.active or index<0 or index>3:return
	_transitioning=true;intro_active=true;player.velocity=Vector3.ZERO;player._cancel_attack();Sfx.play("lab_door",-10)
	var tween:=create_tween();tween.tween_property(_fade,"color:a",1.0,.18);await tween.finished
	var backwards:=index<sector
	sector=index;checkpoint_sector=index;player.position=Layout.ORIGINS[index]+(Vector3(0,[3.08,5.08,8.08,0.08][index],-39.6) if backwards else Vector3(0,.08,-3));player.respawn_position=player.position;player.forward=Vector3.FORWARD;camera_yaw=0
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
	sector=checkpoint_sector;_refresh_sectors();boss.reset_encounter();snap_camera()
func hint_text() -> String:
	if boss.active:return "WASD / setas: mover · Espaço: pular · J: atacar · K: poder · Q: alternar · F: dose"
	if sector==0:
		if not _shop_gone and player.position.distance_to(wagon.global_position)<4:return "E: conversar com Oliver Gancho · I: mochila"
		return "Pegue o cartão, embarque no elevador e use E na porta superior."
	if sector==1:return "K: GELO forma ponte no veneno · J no ar: investida no inimigo marcado · E: porta"
	if sector==2:return "E: alavanca · GELO: prensa · embarque na plataforma para cruzar e subir à cobertura."
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
	get_tree().paused=true;_results=preload("res://world/Scripts/results_screen.gd").new();add_child(_results)
	_results.setup("URSO RESGATADO!",level_name,stats,new_record,false);_results.replay_requested.connect(restart);_results.menu_requested.connect(to_menu);Sfx.finish()
func _build_stats() -> Dictionary:
	var ratio:=float(player.gems)/maxi(1,total_gems)
	return {"rank":Save.compute_rank((ratio+float(defeated)/maxi(1,total_enemies)+float(secrets_found)/total_secrets)/3,_time,360,deaths),"time":_time,"cherries":player.gems,"enemies":defeated,"secrets":secrets_found,"deaths":deaths,"total_cherries":total_gems,"total_enemies":total_enemies,"total_secrets":total_secrets,"perfect":player.gems>=total_gems}
func restart() -> void:get_tree().paused=false;Save.request_play(true,Save.is_free_mode());get_tree().reload_current_scene()
func to_menu() -> void:get_tree().paused=false;get_tree().change_scene_to_file("res://world/main_menu.tscn")
func _notification(what:int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and pause_on_focus_loss and not intro_active and not completed and pause_menu!=null and pause_menu.can_open and not get_tree().paused:pause_menu.open()

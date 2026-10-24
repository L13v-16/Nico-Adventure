extends "res://world/Scripts/level.gd"
const Layout=preload("res://world/Scripts/Corp2D/layout.gd")
var sector:=0
var alert:=0.0
var security_off:=0.0
var lockdown:=false
var machine_sabotaged:=false
var _heated:=false
var _cooled:=false
var _transitioning:=false
var _boss_seen:=false
var _reinforcements:Dictionary={}
var _last_detection:=0.0
var _electric_protection:=0.0
var emergency_battery_used:=false
var _fade:ColorRect
var _sector_label:Label
var _alert_label:Label
var _boss_label:Label
var _bar:ProgressBar
var _encounter:Node2D
func _ready() -> void:
	Layout.build(self);_encounter=$Boss;_encounter.defeated.connect(_boss_defeated)
	notice.position=Vector2(165,80);notice.size=Vector2(455,40);notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;notice.add_theme_font_size_override("font_size",10)
	_build_overlay();super._ready();frame_camera(true)
	player.respawned.connect(_reset_after_death)
func _polish_terrain() -> void:pass
func _spawn_fragments() -> void:total_secrets=6
func _setup_enemies() -> void:
	total_enemies=0
	for enemy in get_tree().get_nodes_in_group("corp_enemies"):
		total_enemies+=1;enemy.died.connect(_on_enemy_died)
func has_elemental_mastery() -> bool:return true
func nico_attack_cooldown_floor() -> float:return .7 if is_instance_valid(_encounter) and _encounter.active else 0.0
func sabotage_multiplier() -> float:return 1.6 if player.equipment.is_equipped("sabotage_chip") else 1.0
func _build_overlay() -> void:
	_sector_label=Label.new();_sector_label.position=Vector2(190,6);_sector_label.size=Vector2(240,17);_sector_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;_sector_label.add_theme_font_size_override("font_size",10);$HUD.add_child(_sector_label)
	_alert_label=Label.new();_alert_label.position=Vector2(200,25);_alert_label.size=Vector2(220,18);_alert_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;_alert_label.add_theme_font_size_override("font_size",10);$HUD.add_child(_alert_label)
	_boss_label=Label.new();_boss_label.position=Vector2(180,47);_boss_label.size=Vector2(280,20);_boss_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;_boss_label.add_theme_font_size_override("font_size",10);$HUD.add_child(_boss_label)
	_bar=ProgressBar.new();_bar.position=Vector2(190,67);_bar.size=Vector2(260,7);_bar.show_percentage=false;_bar.max_value=3;$HUD.add_child(_bar)
	var back:=StyleBoxFlat.new();back.bg_color=Color("242b3a");back.set_corner_radius_all(2)
	var fill:=StyleBoxFlat.new();fill.bg_color=Color("d9ad65");fill.set_corner_radius_all(2)
	_bar.add_theme_stylebox_override("background",back);_bar.add_theme_stylebox_override("fill",fill);_bar.size=Vector2(260,7)
	var overlay:=CanvasLayer.new();overlay.layer=80;add_child(overlay)
	_fade=ColorRect.new();_fade.size=Vector2(640,360);_fade.color=Color("080f1c");_fade.modulate.a=0;_fade.mouse_filter=Control.MOUSE_FILTER_IGNORE;overlay.add_child(_fade)
func _start_sequence() -> void:
	if not Save.consume_skip_intro():
		var scene:=play_scene("arrival");await scene.finished
	_begin_intro()
func _process(delta:float) -> void:
	_update_notice(delta)
	if completed:return
	if _timing:_elapsed+=delta
	_last_detection=maxf(0,_last_detection-delta);security_off=maxf(0,security_off-delta);_electric_protection=maxf(0,_electric_protection-delta)
	if _last_detection<=0:alert=maxf(0,alert-10*delta)
	frame_camera(false)
	_sector_label.text=Layout.NAMES[sector].to_upper()
	_alert_label.text=("VIGILÂNCIA DESLIGADA" if security_off>0 else "ALERTA %02d%%"%int(alert)) if sector<4 else "LOBO · PRESIDENTE EXECUTIVO"
	_alert_label.modulate=Color("ff9e8b") if alert>=65 else Color("d4c8ab")
	_bar.visible=_encounter.active;_boss_label.visible=_encounter.active
	if _encounter.active:_bar.max_value=4 if _encounter.phase==0 else 3;_bar.value=_encounter.health;_boss_label.text=_encounter.status()
	hint.text=context_hint()
	if not intro_active and not _transitioning and not player.is_dead():
		if sector==4 and player.position.x>8420 and not _encounter.active and not _encounter.dead:_start_boss()
		if player.position.y>160 and sector==1:player.take_damage(3,player.position+Vector2(0,-20))
func _physics_process(delta:float) -> void:
	if intro_active or completed or _transitioning:return
	# Keep the entire character inside the fixed arena camera during all phases.
	if sector==4 and _encounter.active:player.position.x=clampf(player.position.x,8490,9250)
	if sector==1 and player.position.y<0:
		var wind:=sin(Time.get_ticks_msec()*.0005)*18
		player.velocity.x+=wind*delta*(.15 if player.equipment.is_equipped("magnetic_boots") else 1)
func frame_camera(snap:bool=false) -> void:
	var camera:Camera2D=player.get_node("Camera2D")
	var bounds:Rect2=Layout.BOUNDS[sector]
	camera.limit_left=int(bounds.position.x);camera.limit_right=int(bounds.end.x);camera.limit_top=int(bounds.position.y);camera.limit_bottom=int(bounds.end.y)
	camera.zoom=Vector2.ONE*(1.55 if sector!=4 else (.8 if _encounter.active else 1.25))
	player._camera_base_offset=Vector2(65,-55 if sector!=4 else -65)
	if _encounter.active:
		player._camera_base_offset=Vector2(8870-player.position.x-player._camera_look,-95-player.position.y)
	if snap:camera.reset_smoothing()
func context_hint() -> String:
	if _encounter.active:
		if _encounter.phase==0:return "Salte a investida · desvie da caneta · contra-ataque quando o Lobo recuperar o fôlego"
		return "Pule as ondas · espere a luz do núcleo · J: atacar · K: poder · Q: trocar" if _encounter.phase==1 else ("FOGO no regulador vermelho + GELO no azul · depois acerte o núcleo" if _encounter.phase==2 else "Suba pelos braços travados · acerte a cabine iluminada no alto")
	var nearest:=nearby_device()
	if nearest!=null:return nearest.hint()
	return ["E: interagir · J: atacar · K: poder · Q: fogo / gelo · I: mochila", "Pise nos elevadores e espere · J quebra vidro · siga as cerejas para subir", "GELO pausa prensas · FOGO no vermelho e GELO no azul sabotam o circuito", "Volte ao elevador da entrada! O lockdown acelerou as máquinas." if lockdown else "Procure as provas no terminal à direita. E examina arquivos.", "Encontre o Lobo na cobertura. Seus amigos estão a caminho."][sector]
func nearby_device() -> Node2D:
	var closest:Node2D;var distance:=58.0
	for device in get_tree().get_nodes_in_group("corp_devices"):
		if device.sector!=sector or device.hint().is_empty():continue
		var gap:float=player.position.distance_to(device.position+Vector2(0,-11))
		if gap<distance:distance=gap;closest=device
	return closest
func _unhandled_input(event:InputEvent) -> void:
	if intro_active or completed or get_tree().paused or _transitioning or event.is_echo():return
	if event.is_action_pressed("interagir"):
		for shop in get_tree().get_nodes_in_group("caravan_shops"):
			if is_instance_valid(shop) and player.position.distance_to(shop.position)<70:return
		var device:=nearby_device()
		if device!=null:device.interact();get_viewport().set_input_as_handled()
func tell(text:String) -> void:_show_notice(text)
func detect(amount:float) -> void:
	if intro_active or security_off>0 or player.is_dead():return
	alert=minf(100,alert+amount);_last_detection=1.5
	if alert>=65 and not _reinforcements.has(sector):
		_reinforcements[sector]=true
		var enemy:Node2D=Layout.enemy(self,sector,1,player.position+Vector2(160,-65));enemy.died.connect(_on_enemy_died);total_enemies+=1
		tell("ALERTA · Drone de reforço. GELO o imobiliza; o terminal desliga as câmeras.");Sfx.play("lab_scan",-12)
func travel(door:Node2D) -> void:
	if _transitioning or player.is_dead() or _encounter.active:return
	var destination:int=door.destination
	if sector==0 and alert>=65:tell("Alerta bloqueou a porta. Use o terminal ao lado ou espere fora da visão.");return
	if sector==2 and not machine_sabotaged:tell("A porta precisa de choque térmico: FOGO no vermelho e GELO no azul.");return
	if sector==3 and lockdown:destination=4
	_transitioning=true;intro_active=true;pause_menu.can_open=false;player.velocity=Vector2.ZERO;player._cancel_attack();player.set_physics_process(false)
	door._art.texture=preload("res://world/Scripts/Corp2D/art.gd").cell("props",5);Sfx.play("lab_door",-10)
	var tween:=create_tween();tween.tween_property(_fade,"modulate:a",1,.18);await tween.finished
	sector=destination;player.position=Layout.LANDINGS[sector];player.set_checkpoint(player.position);active_checkpoint=null;player.heal_full();player._invulnerability_timer=1.3;alert=0;clear_shots();frame_camera(true)
	tween=create_tween();tween.tween_property(_fade,"modulate:a",0,.25);await tween.finished
	player.set_physics_process(true);intro_active=false;_transitioning=false;pause_menu.can_open=true;tell(Layout.NAMES[sector])
func reverse_circuit(link:String,on:bool) -> void:
	for device in get_tree().get_nodes_in_group("corp_devices"):
		if device.link==link and device.kind=="conveyor":device.activated=on;device._art.flip_h=on
	if on:
		for enemy in get_tree().get_nodes_in_group("corp_enemies"):
			if enemy.sector==sector and enemy.species==2:enemy.freeze_for(5);enemy.take_damage(2,player.position,true)
	tell("Esteira invertida · braço mecânico atingiu a unidade de contenção." if on else "Esteira restaurada.")
func power_relay(link:String,element:String) -> void:
	if link=="boss":_encounter.relay(element);return
	if element=="fire":_heated=true
	else:_cooled=true
	if _heated and _cooled:
		machine_sabotaged=true;tell("Choque térmico! Máquinas desligadas; acesso ao centro de controle liberado.")
		for device in get_tree().get_nodes_in_group("corp_devices"):
			if device.sector==2 and device.kind in ["press","turret"]:device.disabled_left=25*sabotage_multiplier()
	else:tell("Agora use "+("GELO no regulador azul." if _heated else "FOGO no regulador vermelho."))
func start_lockdown() -> void:
	lockdown=true;security_off=0;alert=75;tell("PROVAS COPIADAS · LOCKDOWN! Volte pela sala ao elevador de entrada.")
	for at in [Vector2(6530,100),Vector2(6910,-30)]:
		var enemy:Node2D=Layout.enemy(self,3,1 if at.y<0 else 0,at);enemy.died.connect(_on_enemy_died);total_enemies+=1
	Sfx.play("lab_scan",-6)
func shoot(at:Vector2,flight:Vector2,wave:bool=false,electrical:bool=true,style:String="energy") -> void:
	var shot:=preload("res://world/Scripts/Corp2D/projectile.gd").new();shot.position=at;shot.flight=flight;shot.wave=wave;shot.electrical=electrical and not wave;shot.style=style;shot.add_to_group("corp_shots");add_child(shot);Sfx.play("lab_dart",-17)
func clear_shots() -> void:
	for shot in get_tree().get_nodes_in_group("corp_shots"):shot.queue_free()
func electric_hit(source:Vector2) -> void:
	if player.equipment.is_equipped("industrial_insulator"):
		if _electric_protection>0:return
		_electric_protection=2.5
		if player.health>1:player.take_damage(1,source)
		else:tell("Isolante absorveu a descarga crítica.")
	else:player.take_damage(1,source)
func can_use_emergency_battery() -> bool:return not emergency_battery_used and player.health<player.MAX_HEALTH
func use_emergency_battery() -> void:emergency_battery_used=true;player.heal_one()
func buy_acai_power() -> bool:
	if completed or intro_active or player.is_dead():return false
	var power:=preload("res://world/Scripts/acai_power.gd").new();add_child(power)
	if not power.activate_for(player):power.queue_free();return false
	return true
func _on_finish_entered(_body:Node2D) -> void:pass
func _reset_after_death() -> void:
	for i in 5:
		if Layout.BOUNDS[i].has_point(player.position):sector=i;break
	alert=0;security_off=2;_encounter.reset_encounter();frame_camera(true);clear_shots()
func _start_boss() -> void:
	if not _boss_seen:
		_boss_seen=true;var scene:=play_scene("boss");await scene.finished
	_encounter.begin()
func play_friends_turn() -> void:
	var scene:=play_scene("friends");await scene.finished
	_encounter.enable_final_phase();frame_camera(true)
func play_robot_boarding() -> void:
	var scene:=play_scene("boarding");await scene.finished
	_encounter.enter_robot();frame_camera(true)
func _boss_defeated() -> void:_complete_level()
func _start_finale(stats:Dictionary,new_record:bool) -> void:
	Save.set_story_flag("corporation_defeated")
	var scene:=play_scene("ending");await scene.finished
	$HUD.hide();get_tree().paused=true;_show_results(stats,new_record)
func play_scene(mode:String) -> CanvasLayer:
	var script:GDScript=preload("res://world/Scripts/Corp2D/ending.gd") if mode=="ending" else preload("res://world/Scripts/Corp2D/cutscene.gd")
	var scene:CanvasLayer=script.new();scene.level=self;scene.mode=mode;add_child(scene);return scene
func show_record(id:String,kind:String) -> void:
	var records:Dictionary={"forest":["PROJETO COPA","Extração mágica da floresta. Animais tratados como recursos. Nico interrompeu a operação."],"underworld":["PROJETO PROFUNDEZA","Correntes e energia do Submundo. O guardião foi enganado por contratos falsos."],"lab":["RELATÓRIO LARGATO","Testes de resistência em Urso. Diretor indisponível após falha no próprio composto."],"office":["GABINETE DO PRESIDENTE","Metas: controlar as ilhas. Riscos não previstos: amizade, cabeçadas e um guaxinim persistente."],"prototype":["ROBÔ · ENSAIO DE IMPACTO","O punho trava depois do golpe. Salte a onda e ataque o núcleo aceso. A armadura reserva usa reguladores de fogo e gelo."]}
	var data:Array=records.get(id,["ARQUIVO RESERVADO","As provas confirmam quem ordenou os sequestros."])
	var scene:=preload("res://world/Scripts/Corp2D/archive_panel.gd").new();scene.level=self;scene.record_id=id;scene.record_title=data[0];scene.record_text=data[1];add_child(scene)
func unlock_secret(device:Node2D) -> void:
	show_record("office","secret")
	for i in 5:
		var item:=preload("res://prefabs/item.tscn").instantiate();item.cherry_id="corp:secret:%d"%i;item.position=device.position+Vector2(i*18-36,-17);$items.add_child(item);total_gems+=1

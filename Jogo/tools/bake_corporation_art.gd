extends SceneTree
## Rebuild the three localized sign sprites and actual in-game security photos.
const OUT:="res://world/Arte/CorpV86/"
const SLOGANS:=["SUA SEGURANÇA É NOSSA 17ª PRIORIDADE","INOVAÇÃO EXIGE VÍTIMAS · DIGO, METAS","A FAMÍLIA CORPORATIVA VEM PRIMEIRO"]
func _initialize() -> void:run.call_deferred()
func frames(n:int) -> void:
	for i in n:await process_frame;await physics_frame
func run() -> void:
	AudioServer.set_bus_mute(0,true)
	if "photos" in OS.get_cmdline_user_args():await photos()
	else:await signs()
	print("CORP_V86_ART_BAKED");quit()
func signs() -> void:
	for index in 3:
		var viewport:=SubViewport.new();viewport.size=Vector2i(640,104);viewport.transparent_bg=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
		var panel:=NinePatchRect.new();panel.texture=preload("res://world/Scripts/Corp2D/polish_art.gd").cell(10);panel.size=Vector2(640,104);panel.patch_margin_left=32;panel.patch_margin_right=32;panel.patch_margin_top=27;panel.patch_margin_bottom=27;panel.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;viewport.add_child(panel)
		var label:=Label.new();label.text=SLOGANS[index];label.position=Vector2(25,29);label.size=Vector2(590,48);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",23);label.add_theme_color_override("font_color",Color("f4d28c"));label.add_theme_color_override("font_shadow_color",Color("121b25"));label.add_theme_constant_override("shadow_offset_y",2);viewport.add_child(label)
		await frames(3);await RenderingServer.frame_post_draw
		var error:=viewport.get_texture().get_image().save_png(OUT+"sign_%d.png"%index)
		if error!=OK:push_error("Cannot save corporate sign");quit(1);return
		viewport.queue_free();await frames(2)
func photos() -> void:
	var save:=root.get_node("Save");save.set_seen_intro()
	for index in 3:
		save.request_play(true)
		var level:Node2D=load("res://world/corporation_06.tscn").instantiate();level.pause_on_focus_loss=false;root.add_child(level);current_scene=level;await frames(8)
		for item in level.get_node("items").get_children():item.queue_free()
		await frames(2)
		if level.game_hud._intro_tween!=null:level.game_hud._intro_tween.kill();level.game_hud._finish_intro()
		level.intro_active=false;level.sector=[0,2,3][index];level.player.position=[Vector2(842,89),Vector2(5075,89),Vector2(6982,89)][index];level.player.velocity=Vector2.ZERO
		for enemy in get_nodes_in_group("corp_enemies"):enemy.set_physics_process(false)
		level.frame_camera(true);level.set_process(false);level.set_physics_process(false);level.player.set_physics_process(false)
		level.player._start_attack();level.player._attack_elapsed=.16;level.player._attack_facing=1;level.player.anim.play("run");level.player.anim.frame=2;level.player._update_combat_visuals()
		for layer in level.find_children("*","CanvasLayer",true,false):
			if layer.layer>=0:layer.hide()
		var camera:Camera2D=level.player.get_node("Camera2D");camera.zoom=Vector2.ONE*4.0;camera.offset=Vector2(35,-25);camera.position_smoothing_enabled=false;camera.force_update_scroll()
		await frames(4);await RenderingServer.frame_post_draw
		var image:=root.get_texture().get_image();image.save_png(OUT+"evidence_%d.png"%index)
		level.queue_free();await frames(6)

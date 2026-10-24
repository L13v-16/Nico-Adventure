extends Control
## Illustrated map: campaign intermission and mouse/keyboard free-mode travel.
signal back_requested
const Routes := preload("res://world/Scripts/island_routes.gd")
const Ui := preload("res://world/Scripts/ui_style.gd")
const FriendArt := preload("res://world/Scripts/friend_art.gd")
const BACKGROUND := preload("res://world/Arte/Map/V85/ocean_cavern.png")
const ATLAS := preload("res://world/Arte/Map/V85/islands.png")
const REGIONS := [Rect2(12,5,486,488),Rect2(530,16,506,476),Rect2(1065,3,465,487),Rect2(10,498,492,514),Rect2(535,507,507,503),Rect2(1064,487,463,523)]
const BIRD := preload("res://world/Arte/Amigos/arara_minas.tres")
const RIDER := [preload("res://world/Arte/Nico/idle_1.png"),preload("res://world/Arte/Nico/idle_2.png"),preload("res://world/Arte/Nico/idle_3.png"),preload("res://world/Arte/Nico/idle_4.png")]

var selection_mode := false
var source_index := 0
var target_index := 1
var planned_index := 1
var intercepted := false
var flying := false
var duration := 5.4
var elapsed := 0.0
var hovered := -1
var buttons: Array[Button] = []
var _free_travel := false
var _skip_intro := true
var _departing := false
var _clock := 0.0
var _canvas: Control
var _art: Control
var _heading: Label
var _subtitle: Label
var _detail: Label
var _hint: Label
var _back: Button
var _continue: Button
var _veil: ColorRect
var _textures: Array[AtlasTexture] = []
var _rider_feet: Array[Vector2] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if selection_mode:
		if not Save.is_game_completed():
			_back_out.call_deferred()
			return
		source_index = clampi(Save.last_map_island,0,5)
	else:
		var trip: Dictionary = Save.pending_island_trip.duplicate()
		Save.pending_island_trip.clear()
		if not _valid_trip(trip):
			_back_out.call_deferred()
			return
		source_index = int(trip.source)
		target_index = int(trip.target)
		planned_index = int(trip.planned)
		_free_travel = bool(trip.free)
		_skip_intro = bool(trip.skip_intro)
		intercepted = bool(trip.intercepted)
		flying = true
	_build()
	resized.connect(_layout)
	_layout()
	if selection_mode:
		_focus_island(source_index)
		buttons[source_index].grab_focus.call_deferred()
	else:
		_show_route()
		_continue.grab_focus.call_deferred()

func _valid_trip(trip: Dictionary) -> bool:
	for key in ["source","target","planned","free","skip_intro","intercepted"]:
		if not trip.has(key):return false
	var source := int(trip.source)
	var target := int(trip.target)
	var planned := int(trip.planned)
	var attack := bool(trip.intercepted)
	return source >= 0 and source < 5 and target == source+1 and planned == (4 if attack else target) and (not attack or (source == 2 and not bool(trip.free))) and (not bool(trip.free) or Save.is_game_completed())

func _build() -> void:
	for rider: Texture2D in RIDER:
		_rider_feet.append(Vector2(rider.get_width()*.5,rider.get_image().get_used_rect().end.y))
	_canvas = Control.new()
	_canvas.size = Vector2(640,360)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)
	_art = Control.new()
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.draw.connect(_draw_map)
	_canvas.add_child(_art)
	for index in 6:
		var texture := AtlasTexture.new()
		texture.atlas = ATLAS
		texture.region = REGIONS[index]
		texture.filter_clip = true
		_textures.append(texture)
	_heading = _label("AS ILHAS DE NICO",17,Rect2(22,10,490,25),Ui.TEXT_COLOR)
	_subtitle = _label("",10,Rect2(23,36,550,20),Color("b7e5e3"))
	for index in 6:
		var data: Dictionary = Routes.ISLANDS[index]
		var rect: Rect2 = data.rect
		var button := Button.new()
		button.name = "Island%d" % (index+1)
		button.position = rect.position-Vector2(3,3)
		button.size = rect.size+Vector2(6,20)
		button.flat = true
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.tooltip_text = "%s · %s" % [data.full,data.friend]
		button.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover",StyleBoxEmpty.new())
		button.add_theme_stylebox_override("pressed",StyleBoxEmpty.new())
		button.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
		button.pressed.connect(_choose.bind(index))
		button.mouse_entered.connect(_focus_island.bind(index))
		button.focus_entered.connect(_focus_island.bind(index))
		button.disabled = not selection_mode
		_canvas.add_child(button)
		buttons.append(button)
		var title := _label(data.name,10,Rect2(rect.position.x-12,rect.end.y-1,rect.size.x+24,18),Color("e8f3ee"),HORIZONTAL_ALIGNMENT_CENTER)
		title.name = "IslandLabel%d" % (index+1)
		var badge := _label(str(index+1),10,Rect2(rect.position.x+2,rect.position.y+5,15,16),Color("ffdc82"),HORIZONTAL_ALIGNMENT_CENTER)
		badge.name = "IslandNumber%d" % (index+1)
	for index in 6:
		var previous := (index+5)%6
		var following := (index+1)%6
		buttons[index].focus_neighbor_left = buttons[previous].get_path()
		buttons[index].focus_neighbor_right = buttons[following].get_path()
		buttons[index].focus_neighbor_top = buttons[previous].get_path()
		buttons[index].focus_neighbor_bottom = buttons[following].get_path()
	_detail = _label("",11,Rect2(22,334,470,20),Color("ffe4aa"))
	_hint = _label("",9,Rect2(22,354,470,15),Color("c5dadb"))
	# Bottom text occupies one line so the underground island keeps its space.
	_hint.position = Vector2(23,56)
	_back = Ui.button("Voltar" if selection_mode else "Menu",11)
	_back.position = Vector2(544,12)
	_back.size = Vector2(74,25)
	_back.pressed.connect(_back_out)
	_canvas.add_child(_back)
	_continue = Ui.button("Continuar  ›",11)
	_continue.position = Vector2(508,329)
	_continue.size = Vector2(110,25)
	_continue.pressed.connect(_continue_trip)
	_continue.visible = flying
	_canvas.add_child(_continue)
	_veil = ColorRect.new()
	_veil.size = Vector2(640,360)
	_veil.color = Color(0.01,0.03,0.07,0)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(_veil)

func _label(text: String, font_size: int, rect: Rect2, color: Color, align: int=HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Ui.shadowed_label(text,font_size,color,align)
	label.position = rect.position
	label.size = rect.size
	_canvas.add_child(label)
	return label

func _layout() -> void:
	if _canvas == null:return
	var factor := minf(size.x/640.0,size.y/360.0)
	_canvas.scale = Vector2.ONE*factor
	_canvas.position = (size-Vector2(640,360)*factor)*.5
	queue_redraw()

func _focus_island(index: int) -> void:
	if flying or _departing:return
	hovered = index
	if _subtitle != null:
		_subtitle.text = "%s · %s" % [Routes.ISLANDS[index].full,Routes.ISLANDS[index].friend]
		_detail.text = "Cerejas: %d  ·  As cerejas coletadas não reaparecem." % Save.get_cherry_balance()
		_hint.text = "Clique numa ilha para viajar · Setas e Enter também funcionam"

func _choose(index: int) -> void:
	if not selection_mode or flying or _departing or not Save.is_game_completed():return
	Sfx.select()
	target_index = index
	planned_index = index
	intercepted = false
	_free_travel = true
	_skip_intro = true
	duration = 3.2
	elapsed = 0
	flying = true
	for button in buttons:button.disabled = true
	_continue.show()
	_continue.grab_focus()
	_back.text = "Cancelar"
	_show_route()

func _show_route() -> void:
	_heading.text = "ENTRE ILHAS"
	_subtitle.text = "Rumo ao laboratório" if intercepted else "Destino: %s" % Routes.ISLANDS[target_index].full
	_detail.text = "Nico e Arara Minas · próxima parada: %s" % Routes.ISLANDS[planned_index].name
	if source_index == 3:_detail.text = "De volta à superfície · Arara Minas retoma a rota."
	_hint.text = "Aperte Enter ou Continuar para abreviar a viagem"

func _process(delta: float) -> void:
	_clock += delta
	if flying and not _departing:
		elapsed += delta
		if intercepted and elapsed > duration-1.3:
			_detail.text = "Um disparo da corporação se aproxima..."
			_detail.modulate = Color("ffbd9b")
		if elapsed >= duration:_launch()
	if _art != null:_art.queue_redraw()

func flight_point(progress: float) -> Vector2:
	var a := Routes.point(source_index)-Vector2(0,12)
	var b := Routes.point(planned_index)-Vector2(0,16)
	if source_index == planned_index:
		return a+Vector2(sin(progress*TAU)*32,-sin(progress*PI)*33)
	var point := a.lerp(b,progress)
	point.y -= sin(progress*PI)*40
	point.y = maxf(108,point.y)
	return point

func _continue_trip() -> void:
	if not flying or _departing or elapsed < .4:return
	elapsed = maxf(elapsed,duration-.55)

func _launch() -> void:
	if _departing or (_free_travel and not Save.is_game_completed()):return
	_departing = true
	_continue.disabled = true
	_back.disabled = true
	var fade := create_tween()
	fade.tween_property(_veil,"color:a",1.0,.3)
	await fade.finished
	Fx.cancel_hitstop()
	get_tree().paused = false
	Save.last_map_island = target_index
	Save.request_play(false if intercepted else _skip_intro,_free_travel)
	var error := get_tree().change_scene_to_file(Routes.ISLANDS[target_index].scene)
	if error != OK:
		_departing = false
		flying = false
		_veil.color.a = 0
		_detail.text = "Não foi possível abrir a ilha. Volte e tente novamente."
		_back.disabled = false

func _back_out() -> void:
	if _departing:return
	if selection_mode and flying:
		flying = false
		elapsed = 0
		_continue.hide()
		_back.text = "Voltar"
		_heading.text = "AS ILHAS DE NICO"
		_detail.modulate = Color.WHITE
		for button in buttons:button.disabled = false
		_focus_island(target_index)
		buttons[target_index].grab_focus()
		return
	Save.pending_island_trip.clear()
	if back_requested.has_connections():back_requested.emit()
	else:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://world/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_back_out()
	elif flying and event.is_action_pressed("ui_accept"):
		_continue_trip()
		get_viewport().set_input_as_handled()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("051424"))

func _draw_map() -> void:
	_art.draw_texture_rect(BACKGROUND,Rect2(0,0,640,360),false)
	_art.draw_rect(Rect2(0,0,640,76),Color(.015,.06,.10,.55))
	_art.draw_rect(Rect2(0,330,640,30),Color(.015,.035,.07,.88))
	# Only the surface route is charted; the plunge is an accident, not a stop.
	for pair in [[0,1],[1,2],[2,4],[4,5]]:
		_draw_route(int(pair[0]),int(pair[1]),Color(.67,.87,.88,.22),1.0)
	if selection_mode and hovered == 3 and not flying:
		_draw_route(source_index,3,Color(.99,.62,.33,.5),1.0)
	if flying:
		_draw_route(source_index,planned_index,Color("ffda83"),clampf(elapsed/duration,0,1))
	for index in 6:
		var data: Dictionary = Routes.ISLANDS[index]
		var rect: Rect2 = data.rect
		var chosen: bool = (selection_mode and not flying and hovered == index) or (flying and planned_index == index)
		var known: bool = selection_mode or Save.is_level_completed(data.id) or index in [source_index,planned_index]
		if chosen:
			var beacon := Vector2(rect.get_center().x,rect.end.y-8)
			_art.draw_set_transform(beacon,0,Vector2(1,.24))
			_art.draw_arc(Vector2.ZERO,rect.size.x*.49+sin(_clock*3)*2,0,TAU,40,Color(1,.83,.43,.55),1)
			_art.draw_set_transform(Vector2.ZERO)
			rect.position.y -= 3
		var tint := Color.WHITE if known else Color(.43,.58,.65,.8)
		_art.draw_texture_rect(_textures[index],rect,false,tint)
	if flying:
		var progress := smoothstep(0.0,1.0,clampf((elapsed-.35)/(duration-.7),0,1))
		_draw_flyer(flight_point(progress),source_index == planned_index or Routes.point(planned_index).x >= Routes.point(source_index).x)
	elif selection_mode:
		_draw_flyer(Routes.point(source_index)+Vector2(-18,-25+sin(_clock*2)*2),true)

func _draw_route(source: int, target: int, color: Color, fraction: float) -> void:
	if source == target:return
	var a := Routes.point(source)
	var b := Routes.point(target)
	var count := maxi(2,int(a.distance_to(b)/8))
	for step in count+1:
		var t := float(step)/count
		if t > fraction:break
		var point := a.lerp(b,t)-Vector2(0,sin(t*PI)*19)
		_art.draw_rect(Rect2(point.floor(),Vector2(2,2)),color)

func _draw_flyer(at: Vector2, facing_right: bool) -> void:
	var frame := int(_clock*8)%BIRD.get_frame_count(&"fly")
	var bird: Texture2D = BIRD.get_frame_texture(&"fly",frame)
	var bird_size := Vector2(64,64)
	var bird_origin := Vector2(-32,-40)
	_art.draw_set_transform(at.round(),0,Vector2(1 if facing_right else -1,1))
	_art.draw_texture_rect(bird,Rect2(bird_origin,bird_size),false)
	var rider_frame := int(_clock*3)%RIDER.size()
	var rider: Texture2D = RIDER[rider_frame]
	var ride := bird_origin+FriendArt.ride_point(bird,bird_size)
	var feet := _rider_feet[rider_frame]
	_art.draw_texture_rect(rider,Rect2(ride-feet*.78,rider.get_size()*.78),false)
	_art.draw_set_transform(Vector2.ZERO)

extends CanvasLayer
const FriendArt = preload("res://world/Scripts/friend_art.gd")
## Sete planos animados; o relógio da narrativa continua com o mundo pausado.
signal finished
const UiStyle := preload("res://world/Scripts/ui_style.gd")
const GROUND := 235.0
const WOLF_CELL := Vector2(112, 96)
const WOLF_FEET := Vector2(56, 92)
## Coordenadas do vidro no quadro 224x128 do caminhão.
const DRIVER_WINDOW := Rect2(139, 32, 19, 17)
const PICKUP_HOLD_OFFSETS := [Vector2(25, 0), Vector2(25, -14), Vector2(25, -22), Vector2(25, -26)]
const FRIEND_SPRITES := [
	{"name":"Arara Minas", "file":"arara_idle_1", "second":"arara_idle_2"},
	{"name":"Remi", "file":"remi", "second":"remi_2"},
	{"name":"José", "file":"jose", "second":"jose_2"},
	{"name":"Urso", "file":"urso", "second":"urso_2"},
	{"name":"Mico-leão-dourado", "file":"mico_leao_dourado", "second":"mico_leao_dourado_2"},
	{"name":"Tartaruga", "file":"turtle99", "second":"turtle99_2"},
]
const PANELS := [
	{"text":"Nico vive numa mata tranquila, onde os animais convivem em paz.", "title":"UM LAR ENTRE AS FOLHAS", "stage":0, "duration":5.0},
	{"text":"Entre seus amigos estão Arara Minas, a tartaruga, Remi, José, Urso e o mico-leão-dourado.", "title":"AMIGOS PARA TODA A VIDA", "stage":0, "duration":6.0},
	{"text":"O Lobo Lázaro da corporação invade a mata. Seu crachá dourado revela quem comanda o sequestro.", "title":"O LOBO DO CRACHÁ DOURADO", "stage":1, "duration":6.2},
	{"text":"O lobo leva os amigos até a jaula. Nico tenta ajudar, enquanto Arara Minas escapa pelo alto.", "title":"A ORDEM DO LOBO", "stage":1, "duration":7.2},
	{"text":"O lobo parte com os prisioneiros. Nico jamais esquecerá aquele crachá dourado.", "title":"SEPARADOS", "stage":2, "duration":5.8},
	{"text":"Nico faz uma promessa: vai reunir seus amigos e enfrentar o chefe da corporação.", "title":"UMA PROMESSA", "stage":2, "duration":5.2},
	{"text":"Agora, Nico vai atrás.", "title":"A AVENTURA COMEÇA", "stage":3, "duration":4.0},
]
var _index := 0
var _stage := 0
var _elapsed := 0.0
var _clock := 0.0
var _redraw_clock := 0.0
var _backdrop: Control
var _vehicle_canvas: Control
var _driver_window: Control
var _driver_art: TextureRect
var _actor_canvas: Control
var _actor_names: Control
var _text: Label
var _hint: Label
var _timer: Timer
var _finished := false
var _revealed := false
var _cue:=-1
var _textures: Dictionary = {}
var _bounds: Dictionary = {}
var _wolf_frames: SpriteFrames

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_load_art()
	_build()
	Sfx.begin_dialogue_music(self)
	get_tree().paused = true
	_show(0)

func _load_art() -> void:
	for file in ["fundo", "fundo_meio", "Props/arvore", "Tiles/forest_terrain_v2"]:
		_load_texture(file)
	for friend in FRIEND_SPRITES:
		_load_texture("Amigos/" + String(friend.file))
		_load_texture("Amigos/" + String(friend.second))
	for pair in [["scene_idle",0],["scene_wave",6],["scene_think",4]]:
		var image:Texture2D=preload("res://world/Scripts/polish99_art.gd").cell("presentation",pair[1]);var key:String="Nico/"+pair[0];_textures[key]=image;_bounds[key]=FriendArt.bounds(image)
	for i in range(1, 5):
		_load_texture("Nico/idle_%d" % i)
	for i in range(1, 7):
		_load_texture("Nico/run_%d" % i)
	_load_texture("Nico/jump")
	for i in range(1, 5):
		_load_texture("Amigos/arara_fly_%d" % i)
	_wolf_frames = load("res://world/Arte/Corporacao/V22/wolf_motion_v22.tres") as SpriteFrames
	for i in range(1, 5):
		_load_texture("Corporacao/truck_drive_%d" % i)

func _load_texture(file: String) -> void:
	var path := "res://world/Arte/" + file + ".png"
	if file == "Amigos/remi": path = "res://world/Arte/Magic/remi_idle.tres"
	if file == "Amigos/remi_2": path = "res://world/Arte/Magic/remi_blink.tres"
	if file == "Amigos/jose": path = "res://world/Arte/Underworld/jose_idle.tres"
	if file == "Amigos/jose_2": path = "res://world/Arte/Underworld/jose_blink.tres"
	if file=="Amigos/turtle99":path="res://world/Arte/Friends/V47/turtle_body_00.tres"
	if file=="Amigos/turtle99_2":path="res://world/Arte/Friends/V47/turtle_body_01.tres"
	var texture := FriendArt.texture(path)
	_textures[file] = texture
	_bounds[file] = FriendArt.bounds(texture)

func _canvas(canvas_name: String, callback: Callable) -> Control:
	var canvas := Control.new()
	canvas.name = canvas_name
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	canvas.draw.connect(callback)
	add_child(canvas)
	return canvas

func _build() -> void:
	_backdrop = _canvas("ForestAndVehicles", _draw_backdrop)
	_vehicle_canvas = _canvas("CorporationTransport", _draw_vehicle)
	_actor_canvas = _canvas("AnimatedCharacters", _draw_actors)
	var material := ShaderMaterial.new()
	material.shader = load("res://world/Scripts/characters_cutout.gdshader") as Shader
	_actor_canvas.material = material
	_vehicle_canvas.material = material
	_build_driver_window()
	_actor_names = _canvas("CinematicFrame", _draw_frame)
	_text = UiStyle.shadowed_label("", 16, Color("ecf0df"), HORIZONTAL_ALIGNMENT_LEFT)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_text)
	_hint = UiStyle.label("ENTER / ESPAÇO  revelar / avançar     •     ESC  pular", 10, Color("819d99"), HORIZONTAL_ALIGNMENT_LEFT)
	add_child(_hint)
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_timer.timeout.connect(_advance)
	add_child(_timer)

func _process(delta: float) -> void:
	if _finished:
		return
	_elapsed += delta
	_clock += delta
	if _index==2 and _elapsed>2.8 and _cue<0:_cue=0;Sfx.play("lab_clink",-17)
	if _index==3:
		if _elapsed>.8 and _cue<0:_cue=0;Sfx.play("lab_clink",-17)
		if _elapsed>4.25 and _cue<1:_cue=1;Sfx.play("lab_door",-14)
	_text.visible_characters = -1 if _revealed else mini(_text.text.length(), int(maxf(0.0, _elapsed - 0.25) * 48.0))
	var scale_ui := get_viewport().get_visible_rect().size / Vector2(640, 360)
	_text.position = Vector2(36, 278) * scale_ui
	_text.size = Vector2(568, 54) * scale_ui
	_text.add_theme_font_size_override("font_size", int(16 * scale_ui.y))
	_hint.position = Vector2(36, 337) * scale_ui
	_hint.size = Vector2(570, 18) * scale_ui
	_hint.add_theme_font_size_override("font_size", int(10 * scale_ui.y))
	_redraw_clock += delta
	if _redraw_clock >= 1.0 / 30.0:
		_redraw_clock = 0.0
		_backdrop.queue_redraw()
		_vehicle_canvas.queue_redraw()
		_actor_canvas.queue_redraw()
		_actor_names.queue_redraw()

func _show(index: int) -> void:
	_index = index
	_stage = int(PANELS[index].stage)
	_elapsed = 0.0
	_revealed = false;_cue=-1
	_text.text = String(PANELS[index].text)
	_text.visible_characters = 0
	_timer.start(float(PANELS[index].duration))
	_backdrop.queue_redraw()
	_vehicle_canvas.queue_redraw()
	_actor_canvas.queue_redraw()
	_actor_names.queue_redraw()

func _advance() -> void:
	if _finished:
		return
	if _index + 1 == PANELS.size():
		_finish()
	else:
		_show(_index + 1)

func _finish() -> void:
	if _finished:
		return
	_finished = true
	_timer.stop()
	Sfx.end_dialogue_music(self)
	get_tree().paused = false
	finished.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if _finished or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		_finish()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		# O primeiro toque revela a fala, o próximo avança a tomada.
		if not _revealed and _text.visible_characters < _text.text.length():
			_revealed = true
		else:
			_advance()
		get_viewport().set_input_as_handled()

func _begin_draw(canvas: Control) -> void:
	canvas.draw_set_transform(Vector2.ZERO, 0.0, canvas.size / Vector2(640, 360))

func _progress() -> float:
	return clampf(_elapsed / float(PANELS[_index].duration), 0.0, 1.0)

func _draw_backdrop() -> void:
	_begin_draw(_backdrop)
	var c := _backdrop
	var pan := _progress() * (18.0 if _stage == 0 else 9.0)
	var tint := Color.WHITE if _stage == 0 else Color("8b9fba")
	c.draw_texture_rect(_textures.fundo, Rect2(-pan * 0.2, 20, 800, 250), false, tint)
	for i in range(-1, 3):
		c.draw_texture_rect(_textures.fundo_meio, Rect2(i * 352 - pan, -98, 352, 368), false, tint.darkened(0.12))
	for i in 4:
		var x := float(i) * 230.0 - 70.0 - pan * 1.5
		c.draw_texture_rect(_textures["Props/arvore"], Rect2(x, 55, 193, 180), false, tint.darkened(0.12))
	c.draw_rect(Rect2(0, GROUND, 640, 30), Color("293b31"))
	for x in range(0, 640, 16):
		c.draw_texture_rect_region(_textures["Tiles/forest_terrain_v2"], Rect2(x, GROUND, 16, 16), Rect2(16, 0, 16, 16), tint)
	if _stage == 0:
		for i in 3:
			var x := 100.0 + i * 190.0 + sin(_clock * 0.13) * 14.0
			c.draw_colored_polygon(PackedVector2Array([Vector2(x, 24), Vector2(x + 20, 24), Vector2(x + 100, 235), Vector2(x + 30, 235)]), Color(1, 0.91, 0.63, 0.055))
	for i in 16:
		var x := fposmod(i * 47.0 - _clock * (9.0 if _stage == 0 else 25.0), 670.0) - 15.0
		var y := 40.0 + fposmod(i * 23.0 + _clock * 10.0, 190.0)
		c.draw_rect(Rect2(Vector2(x, y).round(), Vector2(3, 2)), Color("c2b86f") if _stage == 0 else Color("7b8a80"))
	if _index >= 2 and _index <= 4:
		_draw_truck_dust()
	if _stage >= 2:
		c.draw_rect(Rect2(0, 24, 640, 241), Color(0.02, 0.05, 0.10, 0.16))

func _truck_x() -> float:
	if _index == 2:
		return lerpf(-180.0, 370.0, ease(clampf(_elapsed / 3.0, 0, 1), 0.65))
	if _index == 3:
		return 370.0
	return lerpf(370.0, 800.0, ease(_progress(), 1.6))

func _truck_is_moving() -> bool:
	return (_index == 2 and _elapsed < 3.0) or _index == 4

func _truck_bob() -> float:
	return roundf(sin(_clock * 14.0)) if _truck_is_moving() else 0.0

func _truck_frame_index() -> int:
	if not _truck_is_moving():
		return 1
	# A roda avança com a distância percorrida, acompanhando a aceleração.
	var distance := _truck_x() + 180.0 if _index == 2 else _truck_x() - 370.0
	return 1 + int(maxf(0, distance) / 8.0) % 4

func _draw_vehicle() -> void:
	_begin_draw(_vehicle_canvas)
	_sync_driver_window()
	if _index < 2 or _index > 4:
		return
	_vehicle_canvas.draw_texture_rect(_textures["Corporacao/truck_drive_%d" % _truck_frame_index()], Rect2(roundf(_truck_x()) - 13, GROUND - 116 + _truck_bob(), 224, 128), false)
	# Apoio de carga: coincide com a altura dos pés ao colocar José na jaula.
	var step := Vector2(roundf(_truck_x()) + 14, GROUND - 28 + _truck_bob())
	_vehicle_canvas.draw_rect(Rect2(step, Vector2(22, 3)), Color("26373c"))
	_vehicle_canvas.draw_rect(Rect2(step, Vector2(22, 1)), Color("82918a"))
	_vehicle_canvas.draw_line(step + Vector2(4, 3), step + Vector2(8, 12), Color("3e5358"), 2)

func _build_driver_window() -> void:
	_driver_window = Control.new()
	_driver_window.name = "DriverWindow"
	_driver_window.clip_contents = true
	_driver_window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vehicle_canvas.add_child(_driver_window)
	var portrait := AtlasTexture.new()
	portrait.atlas = _wolf_frames.get_frame_texture(&"idle", 0)
	portrait.region = Rect2(29, 12, 36, 27)
	_driver_art = TextureRect.new()
	_driver_art.name = "WolfDriver"
	_driver_art.texture = portrait
	_driver_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_driver_art.stretch_mode = TextureRect.STRETCH_SCALE
	_driver_art.flip_h = true
	_driver_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_driver_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_driver_art.material = _vehicle_canvas.material
	_driver_window.add_child(_driver_art)
	_driver_window.hide()

func _driver_visibility() -> float:
	if _index == 4:
		return 1.0
	return smoothstep(5.95, 6.25, _elapsed) if _index == 3 else 0.0

func _sync_driver_window() -> void:
	var opacity := _driver_visibility()
	_driver_window.visible = opacity > 0.0
	if not _driver_window.visible:
		return
	# Mesmo quadro, origem arredondada e balanço usados pela carroceria.
	var draw_scale := _vehicle_canvas.size / Vector2(640, 360)
	var origin := Vector2(roundf(_truck_x()) - 13, GROUND - 116 + _truck_bob())
	_driver_window.position = (origin + DRIVER_WINDOW.position) * draw_scale
	_driver_window.size = DRIVER_WINDOW.size * draw_scale
	_driver_art.position = Vector2(1, 3) * draw_scale
	_driver_art.size = Vector2(16, 12) * draw_scale
	_driver_art.modulate = Color(0.76, 0.84, 0.88, opacity)

func _draw_truck_dust() -> void:
	var x := roundf(_truck_x())
	var c := _backdrop
	c.draw_colored_polygon(PackedVector2Array([Vector2(x + 5, GROUND), Vector2(x + 30, GROUND - 4), Vector2(x + 160, GROUND - 4), Vector2(x + 189, GROUND), Vector2(x + 160, GROUND + 3), Vector2(x + 30, GROUND + 3)]), Color(0.02, 0.04, 0.04, 0.32))
	if not _truck_is_moving():
		return
	for i in 8:
		var age := fposmod(_clock * 1.8 + i * 0.15, 1.0)
		c.draw_rect(Rect2(Vector2(x - age * 42, GROUND - 5 - age * 12).round(), Vector2(5 + age * 10, 3 + age * 6)), Color(0.62, 0.58, 0.42, (1.0 - age) * 0.3))

func _friend_file(i: int) -> String:
	var second := int(_clock * 3.0 + i * 0.7) % 2 == 1
	return "Amigos/" + String(FRIEND_SPRITES[i].second if second else FRIEND_SPRITES[i].file)

func _draw_actors() -> void:
	_begin_draw(_actor_canvas)
	var idle := "Nico/scene_wave" if _index==1 and int(_clock*.7)%2==1 else ("Nico/scene_think" if _index==5 else "Nico/scene_idle")
	var run := "Nico/run_%d" % (1 + int(_clock * 10) % 6)
	if _stage == 0:
		var nico_x := 84.0 if _index == 1 else lerpf(75, 130, minf(_elapsed / 2.0, 1))
		_draw_actor(run if _index == 0 and _elapsed < 2.0 else idle, Vector2(nico_x, GROUND), 60)
		for i in FRIEND_SPRITES.size():
			var x := 170.0 + i * 78.0 if _index == 1 else 255.0 + i * 70.0
			var hop: float = maxf(0, sin(_clock * 3.0 + i * 1.2)) * (4 if i == 0 else 0.0)
			if i == 0 and _index == 0 and _elapsed < 2.2:
				var flight := clampf(_elapsed / 2.2, 0, 1)
				_draw_actor("Amigos/arara_fly_%d" % (1 + int(_clock * 8) % 4), Vector2(lerpf(190, x, flight), GROUND - sin(flight * PI) * 48), 55)
			else:
				_draw_actor(_friend_file(i), Vector2(x, GROUND - hop), 55 if i != 3 else 65)
	elif _index == 2:
		_draw_actor(idle, Vector2(115, GROUND), 60)
		for i in FRIEND_SPRITES.size():
			_draw_actor(_friend_file(i), Vector2(200 + i * 29, GROUND), 42)
		_draw_wolf_motion(_arrival_wolf_motion(_elapsed))
	elif _index == 3:
		var x := lerpf(90, 207, minf(_elapsed / 2.0, 1))
		var jump := sin(clampf((_elapsed - 2.0) / 1.1, 0, 1) * PI) * 45
		_draw_actor("Nico/jump" if jump > 0 else run, Vector2(x, GROUND - jump), 60)
		var motion := _capture_wolf_motion(_elapsed)
		_draw_captured_friends(motion.loaded)
		if not motion.loaded:
			# O amigo é desenhado antes das mãos e das grades, sem flutuar à frente.
			_draw_actor(_friend_file(2), motion.jose_feet, motion.jose_height)
		_draw_cage_bars()
		_draw_wolf_motion(motion)
		# Arara escapa antes de a porta da jaula se fechar.
		if _elapsed < 4.5:
			_draw_actor("Amigos/arara_fly_%d" % (1 + int(_clock * 8) % 4), Vector2(200 + _elapsed * 110, GROUND - 65 - _elapsed * 15), 44)
	elif _index == 4:
		_draw_captured_friends()
		_draw_cage_bars()
		_draw_actor("Nico/jump" if _elapsed < 1 else idle, Vector2(165 - minf(_elapsed, 1.0) * 20, GROUND - maxf(0, 1 - _elapsed) * 35), 60, true)
	elif _index == 5:
		_draw_actor(idle, Vector2(240, GROUND), 68)
	else:
		var depart := maxf(0.0, _elapsed - 1.3)
		_draw_actor(run if depart > 0 else idle, Vector2(235 + depart * 150, GROUND), 68)

func _draw_actor(file: String, feet: Vector2, height: float, flip: bool = false) -> void:
	var source: Rect2i = _bounds[file]
	var ratio := height / float(source.size.y)
	var size := Vector2(source.size) * ratio
	var rect := Rect2((feet - Vector2(size.x * 0.5, size.y)).round(), size)
	if flip:
		rect.size.x *= -1
	_actor_canvas.draw_texture_rect_region(_textures[file], rect, source)

func _kidnap_progress() -> float:
	return clampf((_elapsed - 1.25) / 3.0, 0.0, 1.0)

func _draw_captured_friends(include_jose: bool = true) -> void:
	for i in range(1, FRIEND_SPRITES.size()):
		if i == 2 and not include_jose:
			continue
		_draw_actor(_friend_file(i), Vector2(roundf(_truck_x()) + 22 + (i - 1) * 14, GROUND - 57 + _truck_bob()), 22)

func _wolf_walk_frame(distance: float) -> int:
	return int(maxf(0, distance) / 64.0 * 8.0) % 8

func _arrival_wolf_motion(time: float) -> Dictionary:
	var progress := smoothstep(0.0, 2.8, time)
	var distance := progress * 200.0
	return {"pose": &"walk" if time < 2.8 else &"command", "frame": _wolf_walk_frame(distance) if time < 2.8 else 0, "feet": Vector2(565.0 - distance, GROUND), "flip": false, "opacity": 1.0}

func _capture_wolf_motion(time: float) -> Dictionary:
	var pickup_frame := clampi(int(maxf(0.0, time - 0.25) / 0.6 * 4.0), 0, 3)
	var carry_progress := clampf((time - 1.25) / 2.4, 0.0, 1.0)
	var distance := carry_progress * 82.0
	var step_height := smoothstep(3.15, 3.65, time) * 28.0
	var feet := Vector2(310.0 + distance, GROUND - step_height)
	var pose := &"pickup" if time < 1.25 else &"carry"
	var frame := pickup_frame if time < 1.25 else int(distance / 32.0 * 4.0) % 4
	var offset: Vector2 = PICKUP_HOLD_OFFSETS[pickup_frame] if time < 1.25 else Vector2(25, -26)
	var held := feet + offset
	var place := smoothstep(3.65, 4.25, time)
	var cage := Vector2(417, GROUND - 57)
	var opacity := 1.0
	if time >= 3.65 and time < 4.25:
		pose = &"lift"
		frame = 0
	if time >= 4.25:
		# Desce do apoio traseiro e anda até a porta da cabine com passos próprios.
		var boarding := clampf((time - 4.25) / 1.9, 0.0, 1.0)
		var boarding_distance := boarding * 128.0
		feet = Vector2(392.0 + boarding_distance, GROUND - 28.0 * (1.0 - smoothstep(4.25, 4.8, time)))
		pose = &"walk"
		frame = _wolf_walk_frame(boarding_distance)
		opacity = 1.0 - smoothstep(5.65, 6.15, time)
	return {"pose": pose, "frame": frame, "feet": feet, "flip": true, "opacity": opacity, "loaded": time >= 4.25, "jose_feet": held.lerp(cage, place), "jose_height": lerpf(26.0, 22.0, place)}

func _draw_wolf_motion(motion: Dictionary) -> void:
	if motion.opacity <= 0.0:
		return
	# Célula e apoio fixos: sem respirar por escala ou reamostrar o corpo a 1,075x.
	var rect := Rect2((Vector2(motion.feet) - WOLF_FEET).round(), WOLF_CELL)
	if motion.flip:
		rect.size.x *= -1
	_actor_canvas.draw_texture_rect(_wolf_frames.get_frame_texture(motion.pose, motion.frame), rect, false, Color(1, 1, 1, motion.opacity))

func _draw_cage_bars() -> void:
	# Os prisioneiros ficam atrás das grades; o sequestrador fica à frente.
	var origin := Vector2(roundf(_truck_x()) + 17, GROUND - 91 + _truck_bob())
	for i in 7:
		_actor_canvas.draw_rect(Rect2(origin + Vector2(i * 13, 0), Vector2(2, 38)), Color("1b2c36"))
		_actor_canvas.draw_rect(Rect2(origin + Vector2(i * 13, 0), Vector2(1, 38)), Color("8c9f9a"))
	_actor_canvas.draw_rect(Rect2(origin + Vector2(0, 18), Vector2(80, 2)), Color("526966"))

func _draw_frame() -> void:
	_begin_draw(_actor_names)
	var c := _actor_names
	c.draw_rect(Rect2(0, 0, 640, 26), Color("0c1d24"))
	c.draw_rect(Rect2(0, 262, 640, 98), Color("0c1d24"))
	c.draw_rect(Rect2(36, 262, 24, 2), Color("d7bc76"))
	c.draw_string(ThemeDB.fallback_font, Vector2(36, 18), "NICO  /  PRÓLOGO", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("d7bc76"))
	c.draw_string(ThemeDB.fallback_font, Vector2(36, 49), String(PANELS[_index].title), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("edf1da"))
	if _index == 1:
		for i in FRIEND_SPRITES.size():
			var name_text := String(FRIEND_SPRITES[i].name)
			if i == 4:
				name_text = "Mico-leão"
			c.draw_string(ThemeDB.fallback_font, Vector2(131 + i * 78, 253), name_text, HORIZONTAL_ALIGNMENT_CENTER, 78, 9, Color("e0d5b3"))
	if _index == 2 or _index == 4:
		c.draw_string(ThemeDB.fallback_font, Vector2(36, 69), "CHEFE DA CORPORAÇÃO  /  O LÍDER DO SEQUESTRO", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("d7bc76"))
	if _index == 6:
		var reveal := clampf(_elapsed / 0.6, 0, 1)
		c.draw_string(ThemeDB.fallback_font, Vector2(344 + (1 - reveal) * 50, 132), "PELOS SEUS", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.91, 0.95, 0.84, reveal))
		c.draw_string(ThemeDB.fallback_font, Vector2(344 + (1 - reveal) * 50, 162), "AMIGOS.", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0.88, 0.77, 0.46, reveal))
	for i in PANELS.size():
		var x := 536.0 + i * 10
		c.draw_rect(Rect2(x, 14, 6, 3), Color("42615c"))
		if i <= _index:
			c.draw_rect(Rect2(x, 14, 6 * (_progress() if i == _index else 1.0), 3), Color("d7bc76"))
	var fade := maxf(0, 1 - _elapsed / 0.3)
	if fade > 0:
		c.draw_rect(Rect2(0, 26, 640, 236), Color(0.04, 0.08, 0.1, fade))

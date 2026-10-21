extends Control
## Screen-space finale: the original actors and their physics stay untouched.
const DURATION := 19.2
const BEATS := [0.0, 3.2, 6.2, 9.5, 11.7, 15.3, DURATION]
const Art = preload("res://world/Scripts/underworld_art.gd")
const ChainArt = preload("res://world/Scripts/underworld_chain_art.gd")
const Ui = preload("res://world/Scripts/ui_style.gd")
const CAVE = preload("res://world/Arte/Underworld/V36/background.png")
const SHORE = preload("res://world/Arte/Beach/beach_background.png")
const FLOOR = preload("res://world/Arte/Underworld/V39/terrain_00.tres")
const ROCK = preload("res://world/Arte/Underworld/V39/terrain_04.tres")
const LINES := [
	["Nico", "José... o que você está fazendo?"],
	["José", "Vou tentar domar esse grandão! Estas correntes vão servir de rédeas."],
	["José", "Sobe, Nico! Eu seguro as correntes."],
	["Nico", "Segura firme, José!"],
	["José", "Próxima ilha! Ainda temos amigos para encontrar."],
	["Nico", "Vamos, grandão!"],
]
var player: CharacterBody2D
var clock := 0.0
var stage := "approach"
var monster: AnimatedSprite2D
var jose: AnimatedSprite2D
var jose_rider: Node2D
var rider: Node2D
var anim: AnimatedSprite2D
var rig: Node2D
var _front: Control
var _portrait: TextureRect
var _speaker: Label
var _line: Label
var _originals: Array[CanvasItem] = []
var _visibility: Array[bool] = []
var _restored := false
var _cues: Dictionary = {}
var _beat := -1
var _throw := 0.0
var _bound := false
var _mounted_nico := false
var _mounted_jose := false
var _seat_cache: Dictionary = {}

func _seat(x: float, foot_x := 0.0, foot_y := 0.0) -> Vector2:
	# Use the current frame's opaque back, rather than letting riders hover
	# over the sloping shoulder when the guardian changes pose.
	var texture: Texture2D = monster.sprite_frames.get_frame_texture(monster.animation, monster.frame)
	var key := texture.resource_path + str(x)
	if not _seat_cache.has(key):
		var image := texture.get_image()
		var margin: Vector2 = texture.margin.position if texture is AtlasTexture else Vector2.ZERO
		var u: float = (x + foot_x - monster.position.x) / monster.scale.x
		if monster.flip_h: u = texture.get_width() - 1 - u
		var column := clampi(int(u - margin.x), 0, image.get_width() - 1)
		var height := -135.0
		for y in image.get_height():
			if image.get_pixel(column, y).a >= 0.94:
				height = monster.position.y + (y + margin.y) * monster.scale.y - foot_y
				break
		_seat_cache[key] = height
	return Vector2(x, _seat_cache[key])

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(640, 360)
	for actor: CanvasItem in [player, player.get_parent().get_node("Jose"), player.get_parent().get_node("Boss")]:
		_originals.append(actor)
		_visibility.append(actor.visible)
		actor.hide()
	rig = Node2D.new()
	rig.name = "MountedParty"
	add_child(rig)
	monster = Art.actor("boss", 225)
	monster.name = "Carcereiro"
	monster.flip_h = true
	rig.add_child(monster)
	jose = Art.actor("jose", 37)
	jose.name = "JoseRider"
	jose_rider = Node2D.new()
	add_child(jose_rider)
	jose_rider.add_child(jose)
	rider = Node2D.new()
	rider.name = "NicoRider"
	rider.scale = Vector2.ONE * 1.2
	anim = AnimatedSprite2D.new()
	anim.name = "anim"
	anim.sprite_frames = player.anim.sprite_frames
	anim.centered = false
	anim.position = Vector2(-16.5, -30)
	rider.add_child(anim)
	add_child(rider)
	_front = Control.new()
	_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_front.draw.connect(_draw_front)
	add_child(_front)
	_portrait = TextureRect.new()
	_portrait.position = Vector2(22, 292)
	_portrait.size = Vector2(56, 55)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.material = preload("res://world/Scripts/magic_art.gd").material()
	add_child(_portrait)
	_speaker = Ui.label("", 12, Color("ffd296"), HORIZONTAL_ALIGNMENT_LEFT)
	_speaker.position = Vector2(93, 289)
	_speaker.size = Vector2(510, 19)
	add_child(_speaker)
	_line = Ui.label("", 12, Color("f6e9e0"), HORIZONTAL_ALIGNMENT_LEFT)
	_line.position = Vector2(93, 310)
	_line.size = Vector2(520, 33)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_line)
	update_scene(0)

func next_beat(time: float) -> float:
	for at: float in BEATS:
		if at > time + 0.1: return at
	return DURATION

func update_scene(time: float) -> void:
	if _restored: return
	var last := clock
	clock = clampf(time, 0, DURATION)
	stage = "approach" if time < 2.2 else ("taming" if time < 6.2 else ("mounting" if time < 9.5 else ("departure" if time < 13.3 else "crossing")))
	_throw = smoothstep(2.2, 3.1, time)
	_bound = time >= 3.1
	_mounted_nico = time >= 8.25
	_mounted_jose = time >= 9.35
	var outside := time >= 11.25
	var wide := 0.72 if outside else 1.0
	rig.scale = Vector2.ONE * wide
	rider.scale = Vector2.ONE * 1.2 * wide
	jose_rider.scale = Vector2.ONE * wide
	var run := smoothstep(11.6, 13.3, time)
	var leap := clampf((time - 13.3) / 4.6, 0, 1)
	if outside:
		rig.position = Vector2(230 + run * 70 + leap * 400, 246 - leap * 34 - sin(leap * PI) * 46).round()
	else:
		rig.position = Vector2(382 + maxf(time - 9.5, 0) * 17, 246 + (sin(time * 13) * 2 if time > 3.1 and time < 5.8 else 0)).round()
	rig.rotation = sin(leap * TAU) * -0.07 if leap > 0 and leap < 1 else 0.0
	monster.play(&"freed" if time < 5.8 else (&"idle" if time < 9.5 else &"walk"))
	var breathing := Vector2(0, roundf(sin(time * 3) * 1.0))
	var nico_support := _seat(-42, 5.4, 1.2)
	var jose_support := _seat(3)
	var nico_seat := rig.position + nico_support + breathing
	var jose_seat := rig.position + jose_support + breathing
	# Both riders share the mount's transform during the departure and leap.
	if outside:
		nico_seat = rig.to_global(nico_support + breathing)
		jose_seat = rig.to_global(jose_support + breathing)
	var nico_climb := smoothstep(6.25, 8.25, time)
	var jose_climb := smoothstep(7.15, 9.35, time)
	rider.position = Vector2(157, 244).lerp(nico_seat, nico_climb) + Vector2(0, -sin(nico_climb * PI) * 29)
	jose_rider.position = Vector2(220 + smoothstep(0.6, 2.1, time) * 34, 246).lerp(jose_seat, jose_climb) + Vector2(0, -sin(jose_climb * PI) * 35)
	rider.rotation = rig.rotation if _mounted_nico else 0.0
	jose_rider.rotation = rig.rotation if _mounted_jose else 0.0
	anim.play(&"jump" if nico_climb > 0 and nico_climb < 1 else &"idle")
	jose.play(&"walk" if time < 2.1 else (&"windup" if time < 6.2 else (&"jump" if jose_climb < 1 else &"idle")))
	var beat := 0
	for i in range(1, LINES.size()):
		if time >= BEATS[i]: beat = i
	if beat != _beat:
		_beat = beat
		_speaker.text = LINES[beat][0]
		_line.text = LINES[beat][1]
	_portrait.texture = load("res://world/Arte/Nico/hud_1.png") if _speaker.text == "Nico" else load("res://world/Arte/Underworld/jose_portrait_talk.tres" if int(time * 5) % 2 == 0 else "res://world/Arte/Underworld/jose_portrait_neutral.tres")
	for event in [[2.2, "chain", "warden_chain"], [3.15, "catch", "warden_break"], [5.0, "resist", "warden_roar"], [9.5, "mounted", "land"], [13.3, "leap", "jump"]]:
		if time >= event[0] and not _cues.has(event[1]):
			_cues[event[1]] = true
			if time - last < 0.25: Sfx.play(event[2], -8)
	queue_redraw()
	_front.queue_redraw()

func _draw() -> void:
	if clock < 11.25:
		draw_texture_rect(CAVE, Rect2(0, -22, 640, 360), false, Color("c1adbd"))
		for i in 20:
			draw_texture_rect(FLOOR, Rect2(i * 32, 246, 32, 32), false)
			draw_texture_rect(ROCK, Rect2(i * 32, 278, 32, 32), false)
	else:
		draw_texture_rect(SHORE, Rect2(0, -22, 640, 360), false, Color("d8bed8"))
		# The existing pixel-art islands on the horizon are the destination.
		for i in 10:
			draw_texture_rect(FLOOR, Rect2(i * 32, 246, 32, 32), false)
			draw_texture_rect(ROCK, Rect2(i * 32, 278, 32, 32), false)
		for i in 11:
			var x := fposmod(i * 73 - clock * 10, 640)
			draw_rect(Rect2(roundf(x), 218 + i % 4 * 14, 12 + i % 3 * 8, 2), Color(0.8, 0.85, 0.92, 0.3))
	if _bound:
		draw_set_transform(rig.position, rig.rotation, rig.scale)
		draw_texture_rect(ChainArt.BACK, Rect2(-34, -80, 76, 18), false)
		draw_set_transform(Vector2.ZERO)
	elif clock < 2.2:
		draw_texture_rect(ChainArt.COIL, Rect2(267, 236, 22, 10), false)

func _chain(from: Vector2, to: Vector2, sag: float) -> void:
	ChainArt.strand(_front, from, to, 4, sag)

func _draw_front() -> void:
	if _throw > 0:
		var hand := jose_rider.to_global(Vector2(12, -20))
		var neck := rig.to_global(Vector2(43, -97))
		_chain(hand, hand.lerp(neck, _throw), -36 if not _bound else 17)
		if _bound:
			_front.draw_set_transform(rig.position, rig.rotation, rig.scale)
			_front.draw_texture_rect(ChainArt.FRONT, Rect2(-34, -77, 76, 21), false)
			_front.draw_texture_rect(ChainArt.CLASP, Rect2(36, -104, 12, 16), false)
			_front.draw_set_transform(Vector2.ZERO)
		else:
			var hook := hand.lerp(neck, _throw) + Vector2(0, -sin(_throw * PI) * 36)
			_front.draw_texture_rect(ChainArt.HOOK, Rect2(hook - Vector2(5, 6), Vector2(10, 17)), false)
	_front.draw_rect(Rect2(0, 0, 640, 27), Color("151221"))
	_front.draw_string(ThemeDB.fallback_font, Vector2(20, 18), "UM TRANSPORTE IMPROVÁVEL", HORIZONTAL_ALIGNMENT_LEFT, 450, 11, Color("f8c690"))
	_front.draw_string(ThemeDB.fallback_font, Vector2(470, 18), "E / Enter: avançar · Esc: pular", HORIZONTAL_ALIGNMENT_RIGHT, 152, 8, Color("c5b5c9"))
	_front.draw_rect(Rect2(0, 284, 640, 76), Color("181423"))
	_front.draw_rect(Rect2(18, 284, 604, 1), Color("a78573"))
	var transition := maxf(0, 1 - absf(clock - 11.25) / 0.45)
	if transition > 0: _front.draw_rect(Rect2(0, 27, 640, 257), Color(0.06, 0.04, 0.1, transition))
	var end_fade := smoothstep(18.35, DURATION, clock)
	if end_fade > 0: _front.draw_rect(Rect2(0, 27, 640, 257), Color(0.06, 0.04, 0.1, end_fade))

func restore() -> void:
	if _restored: return
	_restored = true
	for i in _originals.size():
		if is_instance_valid(_originals[i]): _originals[i].visible = _visibility[i]

func _exit_tree() -> void: restore()

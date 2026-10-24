extends Node2D
## Peças articuladas sobre os 33 × 32 pixels de cada quadro de Nico.
## Filho do AnimatedSprite2D: squash, golpes e dano são herdados uma só vez.

const IDS: Array[String] = ["claws", "sneakers", "leaf", "lasting_ice", "straw_hat", "sunglasses", "cape", "pajamas", "winter", "rainbow_tail", "swift_gloves", "jump_brooch", "sailor_bandana", "aviator_goggles"]
const PARTS := ["sneakers_far", "sneakers_near", "claws_far", "claws_near", "swift_gloves_far", "swift_gloves_near", "pajamas_torso", "pajamas_sleeve_far", "pajamas_sleeve_near", "pajamas_leg_far", "pajamas_leg_near", "winter_torso", "winter_sleeve_far", "winter_sleeve_near", "winter_leg_far", "winter_leg_near"]
const ART_PATH := "res://world/Arte/Equipment/V56/"
const RAINBOW: Array[Color] = [Color("ff5867"), Color("ffb44b"), Color("f7e86a"), Color("6bd98b"), Color("62c9ef"), Color("bb8aee")]
# Coordenadas nas texturas originais, antes de centered, offset e flip.
# cabeça, olhos, peito, mão próxima/distante, pé próximo/distante, raiz/ponta da cauda.
const POINT_NAMES: Array[String] = ["head", "eyes", "body", "hand_near", "hand_far", "foot_near", "foot_far", "tail_base", "tail_tip"]
const FRAME_POINTS := {
	&"idle": [
		[Vector2(19,13), Vector2(22,16), Vector2(18,23), Vector2(21,25), Vector2(16,24), Vector2(21,30), Vector2(15,30), Vector2(12,26), Vector2(5,24)],
		[Vector2(19,12), Vector2(22,15), Vector2(18,22), Vector2(21,25), Vector2(16,23), Vector2(21,30), Vector2(15,30), Vector2(12,25), Vector2(6,24)],
		[Vector2(19,14), Vector2(22,17), Vector2(18,23), Vector2(21,26), Vector2(16,24), Vector2(21,30), Vector2(15,30), Vector2(12,26), Vector2(5,23)],
		[Vector2(19,16), Vector2(22,19), Vector2(18,25), Vector2(21,28), Vector2(16,26), Vector2(21,31), Vector2(16,31), Vector2(12,27), Vector2(5,25)],
	],
	&"run": [
		[Vector2(20,15), Vector2(23,18), Vector2(18,25), Vector2(22,24), Vector2(17,26), Vector2(20,30), Vector2(11,30), Vector2(10,24), Vector2(5,21)],
		[Vector2(20,14), Vector2(22,17), Vector2(18,24), Vector2(19,26), Vector2(15,24), Vector2(20,28), Vector2(12,30), Vector2(11,26), Vector2(5,24)],
		[Vector2(21,15), Vector2(24,18), Vector2(18,25), Vector2(20,27), Vector2(16,25), Vector2(23,30), Vector2(10,29), Vector2(10,26), Vector2(4,24)],
		[Vector2(20,15), Vector2(23,18), Vector2(18,25), Vector2(20,26), Vector2(15,24), Vector2(19,30), Vector2(14,28), Vector2(9,25), Vector2(4,25)],
		[Vector2(19,14), Vector2(22,17), Vector2(17,25), Vector2(19,25), Vector2(15,24), Vector2(15,30), Vector2(21,24), Vector2(9,25), Vector2(4,23)],
		[Vector2(20,14), Vector2(23,17), Vector2(18,25), Vector2(22,24), Vector2(17,26), Vector2(21,30), Vector2(11,30), Vector2(11,27), Vector2(5,25)],
	],
	&"jump": [[Vector2(20,11), Vector2(22,13), Vector2(18,22), Vector2(20,24), Vector2(14,18), Vector2(19,29), Vector2(14,30), Vector2(11,26), Vector2(5,27)]],
	&"fall": [[Vector2(18,13), Vector2(21,16), Vector2(18,24), Vector2(23,23), Vector2(10,19), Vector2(22,28), Vector2(14,29), Vector2(13,27), Vector2(6,27)]],
	&"hurt": [[Vector2(14,15), Vector2(17,18), Vector2(15,25), Vector2(21,22), Vector2(11,22), Vector2(18,27), Vector2(11,30), Vector2(9,27), Vector2(9,28)]],
	&"die": [
		[Vector2(21,27), Vector2(23,29), Vector2(15,29), Vector2(18,30), Vector2(13,29), Vector2(16,34), Vector2(11,33), Vector2(11,28), Vector2(4,26)],
		[Vector2(21,27), Vector2(23,29), Vector2(15,29), Vector2(18,30), Vector2(13,29), Vector2(16,34), Vector2(11,33), Vector2(10,28), Vector2(4,25)],
	],
}

var model: Node
var _player: Node2D
var _anim: AnimatedSprite2D
var _back: Node2D
var _front: Node2D
var _trail: Node2D
var _art: Dictionary = {}
var _clock := 0.0
var _trail_timer := 0.0
var _tail_points: Array[Vector3] = []
var _last_tail_at := Vector2.INF


func _ready() -> void:
	name = "EquipmentVisual"
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_player = get_parent() as Node2D
	if _player == null:
		set_process(false)
		return
	_anim = _player.get_node_or_null("anim") as AnimatedSprite2D
	if not is_instance_valid(_anim):
		visible = false
		set_process(false)
		return
	for id in IDS + PARTS:
		_art[id] = load(ART_PATH + id + ".tres") as Texture2D
	var ink := ShaderMaterial.new()
	ink.shader = preload("res://world/Scripts/characters_cutout.gdshader")
	ink.set_shader_parameter("alpha_cutoff", 0.94)
	_back = Node2D.new()
	_back.name = "CapeAndAura"
	_back.z_index = -1
	_back.material = ink
	_back.draw.connect(_draw_back)
	add_child(_back)
	_front = Node2D.new()
	_front.name = "WornAccessories"
	_front.z_index = 1
	_front.material = ink
	_front.draw.connect(_draw_front)
	add_child(_front)
	_trail = Node2D.new()
	_trail.name = "RainbowTrail"
	_trail.z_as_relative = false
	_trail.draw.connect(_draw_trail)
	add_child(_trail)
	_trail.set_as_top_level(true)
	_trail.global_transform = Transform2D.IDENTITY
	_anim.frame_changed.connect(_queue_redraw)
	_anim.animation_changed.connect(_queue_redraw)
	if is_instance_valid(model) and model.has_signal("changed"):
		model.connect("changed", _on_model_changed)
	# Não se remove um filho enquanto o pai ainda está montando sua árvore.
	_attach_to_sprite.call_deferred()


func _attach_to_sprite() -> void:
	if not is_instance_valid(_anim) or is_queued_for_deletion():
		return
	reparent(_anim, false)
	transform = Transform2D.IDENTITY
	modulate = Color.WHITE
	_queue_redraw()


func _has(id: String) -> bool:
	return is_instance_valid(model) and model.has_method("is_equipped") and bool(model.call("is_equipped", id))


func _frost_active() -> bool:
	if is_instance_valid(model) and model.has_method("get_frost_boost_left"):
		if float(model.call("get_frost_boost_left")) > 0.0:
			return true
	return is_instance_valid(_player) and "attack_damage" in _player and int(_player.get("attack_damage")) > 1


func _process(delta: float) -> void:
	if not is_instance_valid(_anim):
		visible = false
		return
	# Pausar a árvore ou parar o sprite também congela os efeitos.
	var elapsed := delta if _anim.is_playing() else 0.0
	_clock += elapsed
	_trail.z_index = _player.z_index + _anim.z_index - 1
	_update_tail(elapsed)
	_queue_redraw()


func _on_model_changed() -> void:
	if not _has("rainbow_tail"):
		_tail_points.clear()
	_queue_redraw()


func _queue_redraw() -> void:
	if is_instance_valid(_back):
		_back.queue_redraw()
		_front.queue_redraw()
		_trail.queue_redraw()


func _pose() -> Dictionary:
	var animation: StringName = _anim.animation if FRAME_POINTS.has(_anim.animation) else &"idle"
	var frames: Array = FRAME_POINTS[animation]
	var points: Array = frames[_anim.frame % frames.size()]
	var pose := {}
	for index: int in POINT_NAMES.size():
		pose[POINT_NAMES[index]] = points[index]
	var chest: Vector2 = pose["body"]
	pose["neck"] = chest + Vector2(-1, -4)
	pose["hip_far"] = chest + Vector2(-2, 2)
	pose["hip_near"] = chest + Vector2(1.5, 2)
	pose["shoulder_far"] = chest + Vector2(-2, -2)
	pose["shoulder_near"] = chest + Vector2(2, -2)
	pose["knee_far"] = (pose["hip_far"] as Vector2).lerp(pose["foot_far"], 0.5)
	pose["knee_near"] = (pose["hip_near"] as Vector2).lerp(pose["foot_near"], 0.5)
	# Hands move only within their cuffs during the real attack pulse.
	if "_attack_elapsed" in _player and float(_player.get("_attack_elapsed")) >= 0.0:
		var pulse := sin(clampf(float(_player.get("_attack_elapsed")) / 0.32, 0, 1) * PI)
		pose["hand_near"] += Vector2(roundf(pulse * 2), 0)
	return pose


func _sprite_basis() -> Transform2D:
	var texture := _anim.sprite_frames.get_frame_texture(_anim.animation, _anim.frame)
	var sprite_size := texture.get_size() if texture != null else Vector2(33, 32)
	var origin := _anim.offset - (sprite_size * 0.5 if _anim.centered else Vector2.ZERO)
	var facing := Vector2(-1.0 if _anim.flip_h else 1.0, -1.0 if _anim.flip_v else 1.0)
	if _anim.flip_h:
		origin.x += sprite_size.x
	if _anim.flip_v:
		origin.y += sprite_size.y
	return Transform2D(0.0, facing, 0.0, origin)


func _part_transform(surface: Node2D, at: Vector2 = Vector2.ZERO, angle: float = 0.0, part_scale: Vector2 = Vector2.ONE) -> void:
	surface.draw_set_transform_matrix(_sprite_basis() * Transform2D(angle, part_scale, 0.0, at.round()))


func _draw_back() -> void:
	if not is_instance_valid(_anim):
		return
	var pose := _pose()
	if _has("cape") and _anim.animation != &"die":
		_draw_cape(pose)
	if _frost_active() and _anim.animation != &"die":
		_part_transform(_back)
		var pulse := 0.5 + 0.5 * sin(_clock * 5.0)
		var center: Vector2 = pose["body"]
		_back.draw_circle(center, 18.0 + pulse, Color(0.35, 0.85, 1.0, 0.08))
		for index: int in 7:
			var angle := _clock * 0.75 + float(index) * TAU / 7.0
			var at := center + Vector2(roundf(cos(angle) * 17.0), roundf(sin(angle) * 17.0))
			_back.draw_rect(Rect2(at, Vector2(2, 2)), Color(0.64, 0.94, 1.0, 0.55 + pulse * 0.25))
	_back.draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_cape(pose: Dictionary) -> void:
	var running := _anim.animation == &"run"
	var anchor: Vector2 = pose["neck"] + Vector2(-3, -1)
	var texture: Texture2D = _art["cape"]
	var source_size := texture.get_size()
	for strip in 4:
		var x := strip * 3
		var width := 2 if strip == 3 else 3
		var flutter := float((_anim.frame + strip) % 3 - 1) if running and strip < 2 else 0.0
		_part_transform(_back, anchor)
		_back.draw_texture_rect_region(texture, Rect2(x-10, flutter, width, 14), Rect2(source_size.x*x/11, 0, source_size.x*width/11, source_size.y))


func _draw_front() -> void:
	if not is_instance_valid(_anim):return
	var pose := _pose()
	var dying := _anim.animation == &"die"
	if not dying:
		if _has("rainbow_tail"):_draw_tail(pose)
		if _has("claws"):_draw_claw(pose["hand_far"], true)
		if _has("swift_gloves"):_draw_glove(pose["hand_far"], true)
		var outfit := "pajamas" if _has("pajamas") else ("winter" if _has("winter") else "")
		if not outfit.is_empty():_draw_outfit(outfit, pose)
		if _has("sneakers"):
			_draw_shoe(pose["foot_far"], true)
			_draw_shoe(pose["foot_near"], false)
		if _has("leaf"):_draw_art_at(_front, "leaf", pose["body"]+Vector2(-1,0), Vector2(-2,-2), Vector2(4,4))
		if _has("lasting_ice"):_draw_art_at(_front, "lasting_ice", pose["body"]+Vector2(2,-2), Vector2(-1,-2), Vector2(3,5))
		if _has("jump_brooch"):_draw_art_at(_front, "jump_brooch", pose["body"]+Vector2(2,-1), Vector2(-2,-2), Vector2(4,4))
		if _has("claws"):_draw_claw(pose["hand_near"], false)
		if _has("swift_gloves"):_draw_glove(pose["hand_near"], false)
	# Head pieces retain exact native pixel alignment, including hurt/death poses.
	if _has("straw_hat"):_draw_art_at(_front, "straw_hat", pose["head"], Vector2(-10,-8), Vector2(20,10))
	if _has("sailor_bandana"):_draw_art_at(_front, "sailor_bandana", pose["head"], Vector2(-10,-4), Vector2(17,11))
	if _has("sunglasses"):_draw_art_at(_front, "sunglasses", pose["eyes"], Vector2(-5,-2), Vector2(9,4))
	if _has("aviator_goggles"):_draw_art_at(_front, "aviator_goggles", pose["eyes"], Vector2(-6,-2), Vector2(10,4))
	_front.draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_glove(hand: Vector2, far_hand: bool) -> void:
	_draw_art_at(_front, "swift_gloves_far" if far_hand else "swift_gloves_near", hand, Vector2(-2,-2), Vector2(3,3) if far_hand else Vector2(4,4))


func _draw_claw(hand: Vector2, far_hand: bool) -> void:
	# The atlas fingers point down; an exact quarter turn points them forward.
	_draw_art_at(_front, "claws_far" if far_hand else "claws_near", hand, Vector2(-2,-2), Vector2(3,5) if far_hand else Vector2(4,6), -PI/2)


func _draw_outfit(id: String, pose: Dictionary) -> void:
	_draw_limb(id+"_leg_far", pose["hip_far"], pose["foot_far"]-Vector2(0,1), 3)
	_draw_limb(id+"_leg_near", pose["hip_near"], pose["foot_near"]-Vector2(0,1), 3)
	_draw_limb(id+"_sleeve_far", pose["shoulder_far"], pose["hand_far"]-Vector2(0,1), 2)
	_draw_art_at(_front, id+"_torso", pose["body"], Vector2(-3,-4), Vector2(6,8))
	_draw_limb(id+"_sleeve_near", pose["shoulder_near"], pose["hand_near"]-Vector2(0,1), 3)


func _draw_limb(id: String, start: Vector2, end: Vector2, width: int) -> void:
	# One-pixel rows articulate the source sleeve/trouser without subpixel rotation.
	var texture: Texture2D = _art[id]
	var size := texture.get_size()
	var segment := end-start
	var horizontal := absf(segment.x)>absf(segment.y)
	var rows := maxi(2, roundi(maxf(absf(segment.x),absf(segment.y)))+1)
	for row in rows:
		var t := float(row)/maxi(1,rows-1)
		var at := start.lerp(end,t).round()
		_part_transform(_front, at, -PI/2 if horizontal and segment.x>0 else (PI/2 if horizontal else 0.0))
		_front.draw_texture_rect_region(texture, Rect2(-floorf(width*.5),0,width,1), Rect2(0,size.y*float(row)/rows,size.x,size.y/rows))


func _draw_shoe(foot: Vector2, far_foot: bool) -> void:
	_draw_art_at(_front, "sneakers_far" if far_foot else "sneakers_near", foot, Vector2(-2,-2), Vector2(4,3) if far_foot else Vector2(5,3))


func _draw_tail(pose: Dictionary) -> void:
	var tip: Vector2 = pose["tail_tip"]
	var base: Vector2 = pose["tail_base"]
	var width := clampf(absf(base.x-tip.x)+4,9,12)
	_draw_art_at(_front, "rainbow_tail", tip, Vector2(-2,-3), Vector2(width,7))


func _draw_art_at(surface: Node2D, id: String, at: Vector2, offset: Vector2, size: Vector2, angle: float = 0.0) -> void:
	var texture: Texture2D = _art.get(id) as Texture2D
	if texture == null:return
	_part_transform(surface, at, angle)
	surface.draw_texture_rect_region(texture, Rect2(offset, size), Rect2(Vector2.ZERO, texture.get_size()))


func _update_tail(delta: float) -> void:
	if not _anim.is_visible_in_tree():
		_tail_points.clear()
		_last_tail_at = Vector2.INF
		_trail.visible = false
		return
	_trail_timer -= delta
	var running := _anim.animation in [&"run", &"jump", &"fall"]
	var pose := _pose()
	var at := _anim.to_global(_sprite_basis() * (pose["tail_tip"] as Vector2))
	if _last_tail_at != Vector2.INF and _last_tail_at.distance_to(at)>96:
		_tail_points.clear()
		_last_tail_at=Vector2.INF
		_trail_timer=0
	if _has("rainbow_tail") and running and _anim.is_playing() and _trail_timer <= 0.0:
		if _last_tail_at == Vector2.INF or _last_tail_at.distance_squared_to(at) >= 1.0:
			_tail_points.append(Vector3(at.x, at.y, _clock))
			_last_tail_at = at
			_trail_timer = 0.035
	while not _tail_points.is_empty() and _clock - _tail_points[0].z > 0.32:
		_tail_points.pop_front()
	if not _has("rainbow_tail") or _anim.animation == &"die":
		_tail_points.clear()
		_last_tail_at = Vector2.INF
	_trail.visible = not _tail_points.is_empty()


func _draw_trail() -> void:
	if not is_instance_valid(_anim):
		return
	for point: Vector3 in _tail_points:
		var fade := clampf(1.0 - (_clock - point.z) / 0.32, 0.0, 1.0) * 0.55
		var pixel_scale := _anim.global_scale.abs()
		for index: int in RAINBOW.size():
			var ink: Color = RAINBOW[index]
			ink.a = fade
			_trail.draw_rect(Rect2(Vector2(roundf(point.x), roundf(point.y) + (-3 + index) * pixel_scale.y), Vector2(3, 1) * pixel_scale), ink)
